--!optimize 2
--!strict
--[=[ lunar
	about = "Creates a built release of the project."
	args = "[-s --skip-confirmation] [-i --include-packages] [-b --bad-package-types] [package-name]"
]=]

local FileInstance = require("@classes/FileInstance")
local LuauPolyfill = require("@packages/LuauPolyfill")
local PathFileSystem = require("@packages/PathFileSystem")
local PathUtilities = require("@utilities/PathUtilities")
local ReadWallyToml = require("@utilities/ReadWallyToml")
local StringUtilities = require("@utilities/StringUtilities")
local WallyPackageTypes = require("@utilities/WallyPackageTypes")

local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local console = LuauPolyfill.console

local SKIP_CONFIRMATION = table.find(process.args, "-s") or table.find(process.args, "--skip-confirmation")
local INCLUDE_PACKAGES = table.find(process.args, "-i") or table.find(process.args, "--include-packages")
local USE_BAD_WALLY_PACKAGE_TYPES = table.find(process.args, "-b") or table.find(process.args, "--bad-package-types")

local PROJECT_NAME = (function()
	for _, argument in process.args do
		if string.byte(argument) == 45 then
			continue
		end

		return argument
	end

	local result = ReadWallyToml()
	if result.Success then
		local packageName = string.match(result.Value.package.name, "^.*/(.*)$")
		if not packageName then
			console.warn("Failed to get package name from wally.toml")
			process.exit(1)
			return "FAILURE"
		end

		return StringUtilities.ToPascalCase(packageName)
	end

	console.warn(result.Error)
	process.exit(1)
	return "FAILURE"
end)()

local ROJO_PROJECT_PATH = "built-release.project.json"
local SOURCEMAP_NAME = "built-sourcemap.json"

local BUILT_PROJECT = "built-project"
local PACKAGES = "Packages"

type Cleanup = () -> ()

local function CreateBuildProject(): Cleanup
	if PathFileSystem.IsDirectory(BUILT_PROJECT) then
		PathFileSystem.RemoveDirectory(BUILT_PROJECT)
	end

	PathFileSystem.Copy("src", BUILT_PROJECT, true)
	local builtProject = FileInstance.Mark(BUILT_PROJECT)
	if PathFileSystem.IsDirectory(PACKAGES) then
		PathFileSystem.RemoveDirectory(PACKAGES)
	end

	local installResult = process.spawn("wally", {"install"})
	if not installResult.ok then
		console.warn(`wally install failed: {installResult.stderr} ({installResult.code})`)
		process.exit(installResult.code)
		return function()
			builtProject:Destroy()
		end
	end

	if not PathFileSystem.IsDirectory(PACKAGES) then
		PathFileSystem.WriteDirectory(PACKAGES)
	end

	local packages = FileInstance.Mark(PACKAGES)

	local tests = builtProject:FindFirstDirectory("__tests__")
	if tests then
		tests:Destroy()
	end

	local stories = builtProject:FindFirstDirectory("Stories")
	if stories then
		stories:Destroy()
	end

	local configuration = builtProject:FindFirstFile("jest.config.luau")
	if configuration then
		configuration:Destroy()
	end

	local descendants = builtProject:GetDescendants()
	for _, child in builtProject:GetChildren() do
		if child.IsDirectory and #child:GetChildren() == 0 then
			child:Destroy()
		end
	end

	if not PathFileSystem.IsFile(ROJO_PROJECT_PATH) then
		local json = serde.encode("json", {
			globIgnorePaths = {
				"**/*.spec.luau";
				"**/*.spec.lua";
				"**/*.story.luau";
				"**/*.story.lua";
				"**/__tests__";
				"**/*.test.luau";
				"**/*.test.lua";
			};
			name = PROJECT_NAME;
			tree = {
				["$path"] = "built-project";
				Packages = if INCLUDE_PACKAGES then {["$path"] = PACKAGES} else nil;
			};
		}, false)
		PathFileSystem.WriteFile(ROJO_PROJECT_PATH, json)
	end

	local sourcemapResult = process.spawn("rojo", {"sourcemap", "--output", SOURCEMAP_NAME, ROJO_PROJECT_PATH})
	if not sourcemapResult.ok then
		console.warn(`rojo sourcemap failed: {sourcemapResult.stderr} ({sourcemapResult.code})`)
		process.exit(sourcemapResult.code)
		return function()
			if PathFileSystem.IsFile(ROJO_PROJECT_PATH) then
				PathFileSystem.RemoveFile(ROJO_PROJECT_PATH)
			end

			builtProject:Destroy()
		end
	end

	if USE_BAD_WALLY_PACKAGE_TYPES then
		local packageTypesResult = process.spawn("wally-package-types", {"--sourcemap", SOURCEMAP_NAME, "Packages/"})
		if not packageTypesResult.ok then
			console.warn(`wally-package-types failed: {packageTypesResult.stderr} ({packageTypesResult.code})`)
			process.exit(packageTypesResult.code)

			return function()
				if PathFileSystem.IsFile(ROJO_PROJECT_PATH) then
					PathFileSystem.RemoveFile(ROJO_PROJECT_PATH)
				end
				if PathFileSystem.IsFile(SOURCEMAP_NAME) then
					PathFileSystem.RemoveFile(SOURCEMAP_NAME)
				end

				builtProject:Destroy()
			end
		end
	else
		local success, value = pcall(function()
			WallyPackageTypes()
		end)

		if not success then
			console.warn(`wally-package-types failed: {value}`)
			process.exit(1)

			return function()
				if PathFileSystem.IsFile(ROJO_PROJECT_PATH) then
					PathFileSystem.RemoveFile(ROJO_PROJECT_PATH)
				end
				if PathFileSystem.IsFile(SOURCEMAP_NAME) then
					PathFileSystem.RemoveFile(SOURCEMAP_NAME)
				end

				builtProject:Destroy()
			end
		end
	end

	if INCLUDE_PACKAGES then
		local packageNames: {[string]: string} = {}
		for _, child in packages:GetChildren() do
			if child.IsDirectory then
				continue
			end

			local packageName = PathUtilities.FileNameNoExtension(child.Name)
			if not packageName or packageNames[packageName] then
				continue
			end

			packageNames[packageName] = `local {packageName} = require%(script.(.*).{packageName}%)`
			console.log(`Adding {packageName}`)
		end

		for _, descendant in descendants do
			if descendant.IsDirectory or descendant.Name == "README.luau" then
				continue
			end

			local extension = PathUtilities.ExtensionName(descendant.Name)
			if not extension then
				console.warn(`No extension found for {descendant:GetFullName()}`)
				continue
			end

			if extension ~= ".lua" and extension ~= ".luau" then
				continue
			end

			local fileSource = descendant:Read()
			if not fileSource then
				console.warn(`Failed to read {descendant:GetFullName()}`)
				continue
			end

			local splitByNewline = string.split(fileSource, "\n")
			local wasModified = false
			if descendant.Name == "init.luau" then
				for index, line in splitByNewline do
					for packageName, pattern in packageNames do
						local parentPath = string.match(line, pattern)
						if not parentPath then
							continue
						end

						if parentPath == "Parent" then
							splitByNewline[index] = `local {packageName} = require(script.Packages.{packageName})`
							wasModified = true
						end
					end
				end
			else
				for index, line in splitByNewline do
					for packageName, pattern in packageNames do
						local parentPath = string.match(line, pattern)
						if not parentPath then
							continue
						end

						local requirePath = {"script"}
						local length = 1

						local wasFound = false

						local object = descendant
						while true do
							local parent = object.Parent

							length += 1
							requirePath[length] = "Parent"

							if parent == builtProject then
								requirePath[length + 1] = "Packages"
								requirePath[length + 2] = packageName
								wasFound = true
								break
							end

							if not parent then
								console.warn(`Failed to find parent for {object:GetFullName()}`)
								break
							end

							object = parent
						end

						if wasFound then
							local newLine = `local {packageName} = require({table.concat(requirePath, ".")})`
							splitByNewline[index] = newLine
							wasModified = true
						end
					end
				end
			end

			if wasModified then
				descendant:Write(table.concat(splitByNewline, "\n"))
			end
		end
	end

	return function()
		if PathFileSystem.IsFile(ROJO_PROJECT_PATH) then
			PathFileSystem.RemoveFile(ROJO_PROJECT_PATH)
		end
		if PathFileSystem.IsFile(SOURCEMAP_NAME) then
			PathFileSystem.RemoveFile(SOURCEMAP_NAME)
		end

		builtProject:Destroy()
	end
end

local function Install(lastCleanup: Cleanup?): Cleanup
	local rbxmResult = process.spawn("rojo", {"build", "--output", `{PROJECT_NAME}.rbxm`, ROJO_PROJECT_PATH})
	if not rbxmResult.ok then
		console.warn(`rojo build rbxm failed: {rbxmResult.stderr} ({rbxmResult.code})`)
		process.exit(rbxmResult.code)

		return function()
			if lastCleanup then
				lastCleanup()
			end
		end
	end

	local rbxmxResult = process.spawn("rojo", {"build", "--output", `{PROJECT_NAME}.rbxmx`, ROJO_PROJECT_PATH})
	if not rbxmxResult.ok then
		console.warn(`rojo build rbxmx failed: {rbxmxResult.stderr} ({rbxmxResult.code})`)
		process.exit(rbxmxResult.code)

		return function()
			if lastCleanup then
				lastCleanup()
			end
		end
	end

	return function()
		if lastCleanup then
			lastCleanup()
		end
	end
end

local cleanup = Install(CreateBuildProject())
if not SKIP_CONFIRMATION then
	stdio.prompt("confirm", "Press enter to continue and cleanup", true)
end
cleanup()

if not PathFileSystem.IsDirectory(PACKAGES) then
	PathFileSystem.WriteDirectory(PACKAGES)
end
if not PathFileSystem.IsDirectory("DevPackages") then
	PathFileSystem.WriteDirectory("DevPackages")
end

-- local sourcemapResult = process.spawn("rojo", {"sourcemap", "--output", "sourcemap.json", "place.project.json"})
-- if not sourcemapResult.ok then
-- 	console.warn(`rojo sourcemap failed: {sourcemapResult.stderr} ({sourcemapResult.code})`)
-- 	process.exit(1)
-- end

-- local packageTypesResult = process.spawn("wally-package-types", {"--sourcemap", "sourcemap.json", "Packages/"})
-- if not packageTypesResult.ok then
-- 	console.warn(`wally-package-types failed: {packageTypesResult.stderr} ({packageTypesResult.code})`)
-- 	process.exit(1)
-- end

-- local devPackageTypesResult = process.spawn("wally-package-types", {"--sourcemap", "sourcemap.json", "DevPackages/"})
-- if not devPackageTypesResult.ok then
-- 	console.warn(`wally-package-types failed: {devPackageTypesResult.stderr} ({devPackageTypesResult.code})`)
-- 	process.exit(1)
-- end
