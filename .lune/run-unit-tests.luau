--!optimize 2
--!strict
--[=[ lunar
	about = "Builds and runs the unit tests place file."
	args = ""
]=]

error("This is not to be used. Just use the local version.")

local Execute = require("@utilities/Execute")
local PathFileSystem = require("@packages/PathFileSystem")

if not PathFileSystem.IsFile("test-place.rbxl") then
	Execute({"rojo", "build", "--output", "test-place.rbxl", "place.project.json"}):Assert()
end

Execute({"run-in-roblox", "--place", "test-place.rbxl", "--script", "luau/run-package-tests.lua"}, {
	stdio = "inherit";
}):Assert()

if PathFileSystem.IsFile("test-place.rbxl") then
	PathFileSystem.RemoveFile("test-place.rbxl")
end
