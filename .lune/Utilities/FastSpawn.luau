--!native
--!optimize 2
--!strict

local task = require("@lune/task")

local freeThreads: {thread} = table.create(500)
local freeAmount = 0

local function Execute<Arguments...>(callback: (Arguments...) -> (), thread: thread, ...: Arguments...)
	callback(...)
	freeAmount += 1
	freeThreads[freeAmount] = thread
end

local function Yield()
	while true do
		Execute(coroutine.yield())
	end
end

local function FastSpawn<Arguments...>(callback: (Arguments...) -> (), ...: Arguments...)
	local thread: thread = nil
	if freeAmount > 0 then
		thread = freeThreads[freeAmount]
		freeThreads[freeAmount] = nil
		freeAmount -= 1
	else
		thread = coroutine.create(Yield)
		coroutine.resume(thread)
	end

	return task.spawn(thread, callback, thread, ...)
end

return FastSpawn
