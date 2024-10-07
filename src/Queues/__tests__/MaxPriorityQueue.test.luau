--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local MaxPriorityQueue = require(script.Parent.Parent.MaxPriorityQueue)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type MaxPriorityQueue<T> = MaxPriorityQueue.MaxPriorityQueue<T>

-- _G.__DEV__ = true
local itDebug = (if _G.__DEV__ then it else it.skip) :: typeof(it)

describe("MaxPriorityQueue", function()
	describe("constructor", function()
		it("should return a MaxPriorityQueue", function()
			expect(MaxPriorityQueue.Is(MaxPriorityQueue.new())).toBe(true)
			expect(MaxPriorityQueue.new()).toEqual(expect.any(MaxPriorityQueue))
		end)
	end)

	describe("MaxPriorityQueue.Insert", function()
		it("should return a number", function()
			local maxPriorityQueue: MaxPriorityQueue<string> = MaxPriorityQueue.new()
			expect(maxPriorityQueue:Insert("1", 1)).toEqual(expect.any("number"))
		end)

		it("should insert into the proper location", function()
			local maxPriorityQueue: MaxPriorityQueue<string> = MaxPriorityQueue.new()
			maxPriorityQueue:Insert("2", 2)
			maxPriorityQueue:Insert("3", 3)
			expect(maxPriorityQueue:Insert("1", 1)).toBe(1)
		end)

		itDebug("should throw an error if passed incorrect types on debug mode", function()
			local maxPriorityQueue: MaxPriorityQueue<string> = MaxPriorityQueue.new()

			expect(function()
				maxPriorityQueue:Insert("1", 1)
			end).never.toThrow()

			expect(function()
				maxPriorityQueue:Insert(nil :: never, 2)
			end).toThrow()

			expect(function()
				maxPriorityQueue:Insert("2", "2" :: never)
			end).toThrow()
		end)
	end)
end)

return false
