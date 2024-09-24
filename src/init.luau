--!optimize 2
--!strict

--[=[
	An automatically building project.
	@class Project
]=]
local Project = {}

--[=[
	Prints a message to the console.
	@param ... ...unknown -- The message to print.
]=]
function Project.Print(...: unknown)
	print("[PROJECT] -", ...)
end

return table.freeze(Project)
