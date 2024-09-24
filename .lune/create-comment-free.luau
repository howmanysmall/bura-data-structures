--!optimize 2
--!strict
--[=[ lunar
	about = "Creates a comment-free version of Luau files."
	args = "<files...>"
]=]

local LuauLexer = require("@packages/LuauLexer")
local LuauPolyfill = require("@packages/LuauPolyfill")
local PathFileSystem = require("@packages/PathFileSystem")

local process = require("@lune/process")

local Path = PathFileSystem.Path
local Set = LuauPolyfill.Set
local console = LuauPolyfill.console
type Set<T> = LuauPolyfill.Set<T>

local arguments = process.args
if #arguments == 0 then
	console.warn("You must pass in at least one file.")
	process.exit(1)
end

-- This is literally the simplest way to do this. Pretty fast though!
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

local ACCEPTED_EXTENSIONS = {luau = true, lua = true}

local COMMENT_FREE_PATH = Path.new("comment-free")
if not PathFileSystem.IsDirectorySafe(COMMENT_FREE_PATH) then
	PathFileSystem.WriteDirectory(COMMENT_FREE_PATH)
end

local filesPathData: {
	{
		ClonedPath: PathFileSystem.Path,
		Path: PathFileSystem.Path,
	}
} =
	table.create(#arguments)
local existingFilePaths: Set<string> = Set.new()
local length = 0

for _, possibleFilePath in arguments do
	if existingFilePaths:has(possibleFilePath) then
		continue
	end

	local success, path = pcall(Path.from, possibleFilePath)
	if not success then
		console.warn(`Failed to create Path from '{possibleFilePath}' - {path}`)
		continue
	end

	if not PathFileSystem.IsFileSafe(path) then
		console.warn(`File '{path}' is not a file.`)
		continue
	end

	if not ACCEPTED_EXTENSIONS[path:extension()] then
		console.warn(`File '{path}' has an invalid extension.`)
		continue
	end

	local fileName = path:fileName()
	if not fileName then
		console.warn(`...Somehow we failed to extract the file name from '{path}'?`)
		continue
	end

	length += 1
	filesPathData[length] = {
		ClonedPath = COMMENT_FREE_PATH:join(fileName);
		Path = path;
	}
	existingFilePaths:add(possibleFilePath)
end

console.log(`Creating comment-free version of {length} file{if length == 1 then "" else "s"}...`)

for _, data in filesPathData do
	local fileContents = RemoveComments(PathFileSystem.ReadFile(data.Path))
	PathFileSystem.WriteFile(data.ClonedPath, fileContents)
end

console.log("All done!")
