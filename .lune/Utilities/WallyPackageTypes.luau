--!optimize 2
--!strict
--[[
	Wraps `wally install` with type exports in link files.

	Roughly equivalent to wally-package-types, but with support for generics
	with defaults and some support for WaitForChild require paths.
--]]

local Option = require("@classes/Option")

local LuauLexer = require("@packages/LuauLexer")
local LuauPolyfill = require("@packages/LuauPolyfill")
local PathFileSystem = require("@packages/PathFileSystem")

local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Path = PathFileSystem.Path
local console = LuauPolyfill.console

type Path = PathFileSystem.Path
type Option<T> = Option.Option<T>

local GENERIC_EQUAL_TYPES = {
	"^(%b()%s*,)";
	"^(%b{}%s*,)";
	"^(%S+%b<>%s*,)";
	"^(%S+%s*,)";
}

local function ParseGenerics(generics: string): {string}
	generics = `{generics},`
	local results = {}
	local length = 0
	local cursor = 1

	while true do
		local preTrim = string.match(generics, "^%s*", cursor)
		assert(preTrim, "Failed to pre-trim?")
		cursor += #preTrim

		if #generics - cursor <= 0 then
			break
		end

		local nameWithEquals, equals = string.match(generics, "^(%S+)(%s*=%s*)", cursor)
		if nameWithEquals and equals then
			length += 1
			results[length] = nameWithEquals
			cursor += #nameWithEquals + #equals

			local matched = false
			for _, genericEquals in GENERIC_EQUAL_TYPES do
				local match = string.match(generics, genericEquals, cursor)
				if match then
					cursor += #match
					matched = true
					-- print("matched", generics, "with", match)
					break
				end
			end

			if matched then
				continue
			end
		end

		local name, comma = string.match(generics, "^(%S+)(%s*,)", cursor)
		if name and comma then
			length += 1
			results[length] = name
			cursor += #name + #comma
			continue
		end

		console.warn("Cannot match generics for the following generics:")
		console.warn(`  {generics}`)
		console.warn("Value at cursor:")
		console.warn(`  {string.sub(generics, cursor)}`)
		process.exit(1)
	end

	return results
end

local function RemoveComments(contents: string)
	local newContents = {}
	local length = 0

	for tokenType: LuauLexer.TokenType, substring in LuauLexer.Scan(contents) do
		if tokenType == "comment" then
			continue
		end
		length += 1
		newContents[length] = substring
	end

	return table.concat(newContents)
end

local function CollectTypes(path: Path): {string}
	local result = {}
	local length = 0

	for match in string.gmatch(RemoveComments(PathFileSystem.ReadFile(path)), "export%stype%s([^\n]*)") do
		local name, generics = string.match(match, "^(%S+)(%b<>)")
		if name and generics then
			local genericsInner = string.match(generics, "<(.*)>")
			assert(genericsInner, "Failed to parse generics")

			length += 1
			result[length] = `{name}<{table.concat(ParseGenerics(genericsInner), ", ")}>`
		else
			length += 1
			result[length] = string.match(match, "^(%S+)") :: string
		end
	end

	return result
end

type PathResolver = typeof(setmetatable(
	{} :: {
		FindFirstChild: (self: PathResolver, childName: string, recursive: boolean?) -> PathResolver,
		WaitForChild: (self: PathResolver, childName: string) -> PathResolver,
		[string]: PathResolver,
	},
	{} :: {__call: (self: PathResolver) -> string}
))

local PARENT_PATH_VALUE = utf8.char(128331, 9832)

local PathResolverMetatable = {}
function PathResolverMetatable:__call()
	local components = table.clone(self.__components)
	local root = table.remove(components, 1) :: string
	if not root then
		error("Cannot get root of empty path?")
	end

	local path = Path.new(root)
	for _, component in components do
		if component == PARENT_PATH_VALUE then
			local parentPath = path:parent()
			if not parentPath then
				error(`Couldn't get parent of {path}?`)
			end

			path = parentPath
		else
			path = path:join(component)
		end
	end

	return path:toString()
end
function PathResolverMetatable:__index(path: string): any
	if path == "Parent" then
		table.insert(self.__components, PARENT_PATH_VALUE)
	elseif path == "WaitForChild" then
		return function(_, childName)
			table.insert(self.__components, childName)
			return self
		end
	elseif path == "FindFirstChild" then
		return function(_, childName, recursive)
			if recursive then
				error("recursive not supported yet!")
			end

			table.insert(self.__components, childName)
			return self
		end
	else
		table.insert(self.__components, path)
	end

	return self
end

local function NewPathResolver(base: string): PathResolver
	local pathResolver = setmetatable({__components = {base}}, PathResolverMetatable) :: never
	return pathResolver
end

local function Pathify(value: string): Option<Path>
	return Option.Some(Path.new(value))
end

local function ResolveLinkTargetPath(linkPath: Path): Option<Path>
	local contents = PathFileSystem.ReadFile(linkPath)
	return Option.Wrap(string.match(contents, "return require%((.+)%)")):AndThen(function(requireInner)
		local resolveFunction = luau.load(`local script = ...; return {requireInner}()`, {
			debugName = `resolve {linkPath}`;
		})
		return Option.Wrap(resolveFunction(NewPathResolver(linkPath:toString()))):AndThen(Pathify)
	end)
end

local POTENTIAL_LUAU_INITS = {
	"init.luau";
	"init.server.luau";
	"init.client.luau";
	"init.lua";
	"init.server.lua";
	"init.client.lua";
}

local function GetMainLuauPath(path: Path): Option<Path>
	if PathFileSystem.IsFile(path) then
		return Option.Some(path)
	end

	local projectFile = path:join("default.project.json")
	if PathFileSystem.IsFile(projectFile) then
		local project = serde.decode("json", PathFileSystem.ReadFile(projectFile))
		local tree = project.tree
		if tree then
			local treePath = tree["$path"]
			if treePath then
				return GetMainLuauPath(path:join(treePath))
			end
		end
	end

	for _, luaSourceContainer in POTENTIAL_LUAU_INITS do
		local luauPath = path:join(luaSourceContainer)
		if PathFileSystem.IsFile(luauPath) then
			return Option.Some(luauPath)
		end
	end

	return Option.None
end

local function RewriteLink(path: Path)
	local contents = PathFileSystem.ReadFile(path)
	if string.find(contents, "-- fixed types", 1, true) then
		return
	end

	ResolveLinkTargetPath(path):FastMatchVoid(function(linkTargetPath)
		GetMainLuauPath(linkTargetPath):FastMatchVoid(function(mainLuauPath)
			local types = CollectTypes(mainLuauPath)
			local requireExpression = string.match(contents, "return%s+(require[^\n]+)")

			local newContentsBuilder = {
				"-- fixed types";
				`local LINK = {requireExpression}`;
			}
			local length = 2

			for _, item in types do
				length += 1
				newContentsBuilder[length] = `export type {item} = LINK.{item}`
			end
			newContentsBuilder[length + 1] = "return LINK"
			PathFileSystem.WriteFile(path, table.concat(newContentsBuilder, "\n"))
		end, function()
			console.warn(`No main luau file found for {path}'s link target {linkTargetPath}`)
		end)
	end, function()
		console.warn(`No link target found for {path}`)
	end)
end

local VALID_EXTENSIONS = {
	luau = true;
	lua = true;
}

local function WallyPackageTypes()
	console.log("Fixing package types...")

	local packages = Path.new("Packages")
	for _, name in PathFileSystem.ReadDirectory(packages) do
		local path = packages:join(name)
		if VALID_EXTENSIONS[path:extension()] and PathFileSystem.IsFile(path) then
			RewriteLink(path)
		end
	end

	local index = packages:join("_Index")
	for _, nameOuter in PathFileSystem.ReadDirectory(index) do
		local outerPath = index:join(nameOuter)
		for _, nameInner in PathFileSystem.ReadDirectory(outerPath) do
			local path = outerPath:join(nameInner)
			if VALID_EXTENSIONS[path:extension()] and PathFileSystem.IsFile(path) then
				RewriteLink(path)
			end
		end
	end

	console.log("  fixed package types")
end

return WallyPackageTypes
