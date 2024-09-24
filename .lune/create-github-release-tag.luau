--!optimize 2
--!strict
--[=[ lunar
	about = "Creates a GitHub release tag."
	args = "[version] [--prerelease]"
]=]

local Execute = require("@utilities/Execute")
local LuauPolyfill = require("@packages/LuauPolyfill")
local SemanticVersion = require("@packages/SemanticVersion")
local process = require("@lune/process")

local console = LuauPolyfill.console

local arguments = table.clone(process.args)
local isPreRelease = false

do
	local index = table.find(arguments, "--prerelease")
	if index then
		isPreRelease = true
		table.remove(arguments, index)
	end
end

local semanticVersion: SemanticVersion.SemanticVersion? = nil

if #arguments == 0 then
	semanticVersion = SemanticVersion.FromWally()
else
	local success, version = pcall(SemanticVersion.new, arguments[1])
	if not success then
		console.warn(`Invalid version argument "{arguments[1]}" - {version}`)
		process.exit(1)
	end
	semanticVersion = version
end

if not semanticVersion then
	console.warn("Failed to get version from wally.toml")
	process.exit(1)
	return
end

console.log(`Creating {if isPreRelease then "pre" else ""}release for v{semanticVersion}...`)

local array = {
	"gh";
	"release";
	"create";
	`v{semanticVersion}`;
	"--generate-notes";
	`-t "Release v{semanticVersion}{if isPreRelease then " (pre-release)" else ""}"`;
}

if isPreRelease then
	table.insert(array, "--prerelease")
end

Execute(array):Assert()
