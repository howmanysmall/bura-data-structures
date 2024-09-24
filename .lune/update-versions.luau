--!optimize 2
--!strict
--[=[ lunar
	about = "Updates the versions in the Wally configuration as well as the documentation."
	args = "[next-version]"
]=]

local LuauPolyfill = require("@packages/LuauPolyfill")
local PathFileSystem = require("@packages/PathFileSystem")
local SemanticVersion = require("@packages/SemanticVersion")

local process = require("@lune/process")
local serde = require("@lune/serde")

local console = LuauPolyfill.console

local wally = serde.decode("toml", PathFileSystem.ReadFile(PathFileSystem.CWD:join("wally.toml")))
local lastVersion = wally.package.version

local lastVersionSemantic = SemanticVersion.new(lastVersion)

local nextVersionArgument = process.args[1] or tostring(lastVersionSemantic:NextMinor())

local success, nextVersionSemantic = pcall(SemanticVersion.new, nextVersionArgument)
if not success then
	console.warn(`Invalid version argument "{nextVersionArgument}" - {nextVersionSemantic}`)
	process.exit(1)
end

local function SanitizePattern(value: string)
	return (string.gsub(value, "([%.%-%*%+%?%%])", "%%%1"))
end

local function ReplaceVersion(file: string, from: string, to: string)
	local filePath = PathFileSystem.CWD:join(file)
	PathFileSystem.WriteFile(filePath, (string.gsub(PathFileSystem.ReadFile(filePath), SanitizePattern(from), to)))
end

do
	ReplaceVersion("docs/installation.md", `@{lastVersionSemantic}`, `@{nextVersionSemantic}`)
	ReplaceVersion("docs/intro.md", `@{lastVersionSemantic}`, `@{nextVersionSemantic}`)
	ReplaceVersion("README.md", `@{lastVersionSemantic}`, `@{nextVersionSemantic}`)
end
do
	ReplaceVersion("docs/installation.md", `@^{lastVersionSemantic}`, `@^{nextVersionSemantic}`)
	ReplaceVersion("docs/intro.md", `@^{lastVersionSemantic}`, `@^{nextVersionSemantic}`)
	ReplaceVersion("README.md", `@^{lastVersionSemantic}`, `@^{nextVersionSemantic}`)
end
ReplaceVersion("wally.toml", `version = "{lastVersionSemantic}"`, `version = "{nextVersionSemantic}"`)
