--!optimize 2
--!strict

--[[
MIT License

Copyright (c) 2024 BusyCityGuy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")
local Jest = require(TestService.UnitTesting.DevPackages.Jest)

print("Checking for ProcessService...")
local processServiceExists, ProcessService = pcall(function()
	local processServiceName = "ProcessService"
	return game:GetService(processServiceName)
end)
print(`ProcessService {processServiceExists and "exists" or "does not exist"}`)

print("Running jest tests cli...")
local status, result = Jest.runCLI(ReplicatedStorage.Packages.DataStructures, {
	all = true;
	ci = false;
	verbose = true;
}, {ReplicatedStorage.Packages.DataStructures}):awaitStatus()
print(`Jest tests completed with status {status}`)

if status == "Rejected" then
	print(result)
end

if status == "Resolved" and result.results.numFailedTestSuites == 0 and result.results.numFailedTests == 0 then
	if processServiceExists then
		ProcessService:ExitAsync(0)
	end
end

if processServiceExists then
	ProcessService:ExitAsync(1)
end

return false
