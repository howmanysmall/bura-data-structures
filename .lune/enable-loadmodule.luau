--!optimize 2
--!strict
--[=[ lunar
	about = "Enables FFlagEnableLoadModule in ClientAppSettings.json for Jest tests on Windows."
]=]

local LuauPolyfill = require("@packages/LuauPolyfill")
local PathFileSystem = require("@packages/PathFileSystem")
local process = require("@lune/process")
local serde = require("@lune/serde")

local console = LuauPolyfill.console

if process.env.windir ~= nil then
	local appDataPath = process.env.LOCALAPPDATA
	local robloxVersionsPath = PathFileSystem.Path.from(appDataPath):join("Roblox"):join("Versions")

	if not PathFileSystem.IsDirectory(robloxVersionsPath) then
		error(`Roblox versions folder not found. Please install Roblox. Checked here: {robloxVersionsPath}`)
	end

	local mostRecentStudioVersionPath
	for _, versionDirectoryName in PathFileSystem.ReadDirectory(robloxVersionsPath) do
		local versionDirectoryPath = robloxVersionsPath:join(versionDirectoryName)
		if not PathFileSystem.IsDirectory(versionDirectoryPath) or not PathFileSystem.IsFile(versionDirectoryPath) then
			continue
		end

		mostRecentStudioVersionPath = versionDirectoryPath
		break
	end

	if mostRecentStudioVersionPath == nil then
		error(`Roblox Studio not found. Please install Roblox. Checked here: {robloxVersionsPath}`)
	end

	local clientSettingsDirectory = mostRecentStudioVersionPath:join("ClientSettings")
	if not PathFileSystem.IsDirectory(clientSettingsDirectory) then
		PathFileSystem.WriteDirectory(clientSettingsDirectory)
	end

	local clientAppSettingsPath = clientSettingsDirectory:join("ClientAppSettings.json")
	local clientAppSettings

	if PathFileSystem.IsFile(clientAppSettingsPath) then
		clientAppSettings = serde.decode("json", PathFileSystem.ReadFile(clientAppSettingsPath))

		local metadata = PathFileSystem.Metadata(clientAppSettingsPath)
		if metadata.permissions and metadata.permissions.readOnly then
			local result = process.spawn("attrib", {"-r", clientAppSettingsPath:toString()})
			assert(result.ok, `Failed to remove read-only attribute:\n{result.stderr}`)
		end
	else
		clientAppSettings = {}
	end

	clientAppSettings.FFlagEnableLoadModule = true
	PathFileSystem.WriteFile(clientAppSettingsPath, serde.encode("json", clientAppSettings))

	local result = process.spawn("attrib", {"+r", clientAppSettingsPath:toString()})
	assert(result.ok, `Failed to add read-only attribute:\n{result.stderr}`)

	console.log(`Wrote FFlagEnableLoadModule to ClientAppSettings.json at {clientAppSettingsPath}`)
	process.exit(0)
end

-- TODO: Get the old iMac and figure out Mac
console.warn(`No support for {process.os} yet. ):`, 2)
process.exit(1)
