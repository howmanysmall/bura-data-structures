--!optimize 2
--!strict
--[=[ lunar
	about = "Builds and runs the unit tests place file."
	args = "[-d, --debug] [rojo-path]"
]=]

local LuauPolyfill = require("@packages/LuauPolyfill")
local PathFileSystem = require("@packages/PathFileSystem")
local ReducedInstance = require("@utilities/ReducedInstance")
local Runtime = require("@utilities/Runtime")

local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local DateTime = require("@contexts/DateTime")
local Debug = require("@contexts/Debug")
local Random = require("@contexts/Random")

local Path = PathFileSystem.Path
local console = LuauPolyfill.console

type Path = PathFileSystem.Path
type RojoProject = {
	name: string,
	tree: any,
}

local DEFAULT_PROJECT_FILE_PATH = Path.new("test.project.json")

local function ReadRojoProject(filePath: PathFileSystem.Path): RojoProject
	assert(
		PathFileSystem.IsFile(filePath),
		`Rojo project file {filePath} not found. Please create it or specify a different file as an argument.`
	)

	local success, value = pcall(serde.decode, "json" :: "json", PathFileSystem.ReadFile(filePath))
	assert(success, `Failed to read Rojo project file {filePath}: {value}`)
	assert(value.name, "Rojo project name is required in the project file")
	return value
end
local function BuildProject(rojoProjectFilePath: PathFileSystem.Path)
	local rojoProject = ReadRojoProject(rojoProjectFilePath)
	local builtProjectFilePath = `{rojoProject.name}.rbxl`
	local root = process.env.HOME or process.env.USERPROFILE

	local rojoPath = Path.new(root):join(".rokit"):join("bin"):join("rojo")

	console.log(`Building project {rojoProjectFilePath} into {builtProjectFilePath} with Rojo...\n`)
	local spawnResult =
		process.spawn(rojoPath:toString(), {"build", rojoProjectFilePath:toString(), "--output", builtProjectFilePath})
	assert(spawnResult.ok, `Failed to build project [{builtProjectFilePath}]: {spawnResult.stderr}`)

	console.log(`Deserializing {builtProjectFilePath}...`)
	local success, result = pcall(roblox.deserializePlace, PathFileSystem.ReadFile(builtProjectFilePath))
	assert(success, `Failed to deserialize built project [{builtProjectFilePath}]: {result}`)

	return result
end

local function ImplementRobloxMethods()
	roblox.implementMethod("Instance", "WaitForChild", function(self, ...)
		local child = self:FindFirstChild(...)
		assert(
			child,
			`WaitForChild is not implemented in Lune, so FindFirstChild was substituted but {self:GetFullName()} does not contain child {(...)} at the time of calling.`
		)
		return child
	end)

	roblox.implementMethod("Instance", "isA", function(self, className: string)
		return self:IsA(className)
	end)

	roblox.implementProperty("RunService", "Heartbeat", function()
		return {
			Connect = Runtime.Connect;
			Wait = function()
				local thread = coroutine.running()
				local connection: Runtime.Connection = nil
				connection = Runtime:Connect(function(deltaTime)
					connection:Disconnect()
					coroutine.resume(thread, deltaTime)
				end)
				return coroutine.yield()
			end;
		}
	end)
end

local arguments = table.clone(process.args)

local forceDebugMode = (function()
	local index = table.find(arguments, "-d") or table.find(arguments, "--debug")
	if index then
		table.remove(arguments, index)
	end
	return index ~= nil
end)()

local rojoProjectFilePath = (function()
	local firstIndex: number? = nil

	for index, argument in arguments do
		if string.byte(argument) ~= 45 and string.sub(argument, -13) == ".project.json" then
			firstIndex = index
			break
		end
	end

	if firstIndex == nil then
		return DEFAULT_PROJECT_FILE_PATH
	end

	local success, pathObject = pcall(function()
		return Path.from(arguments[firstIndex])
	end)

	if not success then
		return DEFAULT_PROJECT_FILE_PATH
	end

	return if PathFileSystem.IsFileSafe(pathObject) then pathObject else DEFAULT_PROJECT_FILE_PATH
end)()

if forceDebugMode then
	_G.__DEV__ = true
end

local game = BuildProject(rojoProjectFilePath)
ImplementRobloxMethods()

-- Declaring because it's needed by `loadScript`, but `loadScript` is also needed in `requireModule`. Defined later.
local RequireModule

-- DEPENDENTS: [TestService/Source/run.server.luau]
-- ProcessService isn't implemented in Lune, so this creates a workable implementation of it by mapping it to process.exit
local gameWithContext = setmetatable({
	GetService = function(_self, serviceName: string)
		if serviceName == "ProcessService" then
			return {
				ExitAsync = function(_, code: number)
					process.exit(code)
				end;
			} :: any
		end

		return game:GetService(serviceName)
	end;
}, {__index = game})

local function LoadScript(script: roblox.Instance): (((...any) -> ...any)?, string?)
	script = ReducedInstance.Once(script)
	if not script:IsA("LuaSourceContainer") then
		return nil, "Attempt to load a non LuaSourceContainer"
	end

	local bytecodeSuccess, bytecode = pcall(luau.compile, (script :: any).Source)
	if not bytecodeSuccess then
		return nil, bytecode
	end

	local callableFunction = luau.load(bytecode, {
		debugName = script:GetFullName();
		environment = setmetatable({
			DateTime = DateTime;
			debug = Debug;
			game = gameWithContext;
			Random = Random;
			require = RequireModule;
			script = script;
			task = task;
			tick = os.clock;
		}, {__index = roblox}) :: any;
	})

	return callableFunction
end

-- Override the unimplemented _loader function with the above implementation
Debug._loader = LoadScript

local MODULE_REGISTRY = {}

function RequireModule(moduleScript: roblox.Instance)
	if not moduleScript then
		error("Attempt to require an undefined ModuleScript!")
	end
	if not moduleScript:IsA("ModuleScript") then
		error(`Attempt to require a non-ModuleScript {moduleScript}!`)
	end

	local cached = MODULE_REGISTRY[moduleScript]
	if cached then
		return cached
	end

	local callback, exception = LoadScript(moduleScript)
	assert(callback, exception)

	local result = callback()
	MODULE_REGISTRY[moduleScript] = result
	return result
end

console.log("Starting main...\n")
local TestService = game:GetService("TestService")

local unitTesting = TestService:FindFirstChild("UnitTesting")
assert(unitTesting, "game.TestService.UnitTesting not found")

local execute = unitTesting:FindFirstChild("Execute")
assert(execute, "game.TestService.UnitTesting.Execute not found")

local callback, exception = LoadScript(ReducedInstance.Once(execute))
assert(callback, exception)

console.log("Running tests from game.TestService.UnitTesting.Execute...\n")
callback()
