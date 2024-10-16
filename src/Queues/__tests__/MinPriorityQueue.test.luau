--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local MinPriorityQueue = require(script.Parent.Parent.MinPriorityQueue)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type MinPriorityQueue<T> = MinPriorityQueue.MinPriorityQueue<T>

-- _G.__DEV__ = true
local itDebug = (if _G.__DEV__ then it else it.skip) :: typeof(it)

describe("MinPriorityQueue", function()
	describe("constructor", function()
		it("should return a MinPriorityQueue", function()
			expect(MinPriorityQueue.Is(MinPriorityQueue.new())).toBe(true)
			expect(MinPriorityQueue.new()).toEqual(expect.any(MinPriorityQueue))
		end)
	end)

	describe("MinPriorityQueue.Insert", function()
		it("should return a number", function()
			local maxPriorityQueue: MinPriorityQueue<string> = MinPriorityQueue.new()
			expect(maxPriorityQueue:Insert("1", 1)).toEqual(expect.any("number"))
		end)

		it("should insert into the proper location", function()
			local maxPriorityQueue: MinPriorityQueue<string> = MinPriorityQueue.new()
			maxPriorityQueue:Insert("2", 2)
			maxPriorityQueue:Insert("3", 3)
			expect(maxPriorityQueue:Insert("1", 1)).toBe(3)
		end)

		itDebug("should throw an error if passed incorrect types on debug mode", function()
			local maxPriorityQueue: MinPriorityQueue<string> = MinPriorityQueue.new()

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

	describe("MinPriorityQueue.ChangePriority", function()
		it("should return a number", function()
			local maxPriorityQueue: MinPriorityQueue<string> = MinPriorityQueue.new()
			maxPriorityQueue:Insert("1", 4)
			maxPriorityQueue:Insert("2", 2)
			maxPriorityQueue:Insert("3", 3)
			expect(maxPriorityQueue:ChangePriority("1", 1)).toEqual(expect.any("number"))
		end)

		it("should return adjusted location", function()
			local maxPriorityQueue: MinPriorityQueue<string> = MinPriorityQueue.new()
			maxPriorityQueue:Insert("1", 4)
			maxPriorityQueue:Insert("2", 2)
			maxPriorityQueue:Insert("3", 3)
			expect(maxPriorityQueue:ChangePriority("1", 1)).toEqual(3)
		end)

		it("should throw if the passed value does not exist already", function()
			expect(function()
				MinPriorityQueue.new():ChangePriority("1", 1)
			end).toThrow()
		end)
	end)
end)

return false
