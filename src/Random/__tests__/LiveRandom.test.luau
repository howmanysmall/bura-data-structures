--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local LiveRandom = require(script.Parent.Parent.LiveRandom)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

local SEED_TO_USE = 8949857.9991050064563751220703125

describe("LiveRandom", function()
	describe("constructor", function()
		it("should return a LiveRandom", function()
			local liveRandom = LiveRandom.new(1, 10)
			expect(tostring(liveRandom)).toBe("LiveRandom")
			expect(liveRandom).toEqual(expect.any(LiveRandom))
			expect(LiveRandom.Is(liveRandom)).toBe(true)
		end)
	end)

	describe("LiveRandom.Get", function()
		it("should return a unique value in the range only once until we're out, then we repeat", function()
			local liveRandom = LiveRandom.new(1, 10)
			local first = liveRandom:Peek()
			local hasSeen: {[number]: true} = {}

			for _ = 1, 10 do
				local index = liveRandom:Get()
				expect(hasSeen[index]).toBeUndefined()
				hasSeen[index] = true
			end

			expect(liveRandom:Get()).toBe(first)
		end)
	end)

	describe("LiveRandom.Peek", function()
		it("should return the correct value every time", function()
			for _ = 1, 10 do
				expect(LiveRandom.new(1, 10, SEED_TO_USE):Peek()).toBe(10)
			end
		end)

		it("should return the correct value every time, even with a constant random seed", function()
			local randomSeed = os.clock() % 1 * 1E7
			local value = LiveRandom.new(1, 10, randomSeed):Peek()
			for _ = 1, 10 do
				expect(LiveRandom.new(1, 10, randomSeed):Peek()).toBe(value)
			end
		end)

		it("should not regenerate", function()
			local liveRandom = LiveRandom.new(1, 10)
			expect(liveRandom:Peek()).toBe(liveRandom:Peek())
		end)
	end)

	describe("LiveRandom.Rig", function()
		it("should return the same LiveRandom", function()
			local liveRandom = LiveRandom.new(1, 10)
			expect(liveRandom:Rig(11)).toBe(liveRandom)
		end)

		it("should return the rigged value on next get/peek", function()
			expect(LiveRandom.new(1, 10, SEED_TO_USE):Rig(11):Peek()).toBe(11)
		end)
	end)
end)

return false
