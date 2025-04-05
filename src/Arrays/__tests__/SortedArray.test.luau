--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local SortedArray = require(script.Parent.Parent.SortedArray)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("SortedArray", function()
	it("should insert values and keep the array sorted", function()
		local sortedArray = SortedArray.new({} :: {number}, function(a, b)
			return a < b
		end)
		sortedArray:Insert(5)
		sortedArray:Insert(1)
		sortedArray:Insert(3)
		sortedArray:Insert(2)
		sortedArray:Insert(4)
		for index = 1, #sortedArray - 1 do
			expect(sortedArray.Array[index] <= sortedArray.Array[index + 1]).toBe(true)
		end
		expect(#sortedArray).toBe(5)
	end)

	it("should find values correctly using Find (and IndexOf)", function()
		local sortedArray = SortedArray.new({10, 20, 30, 40, 50})
		local index = sortedArray:Find(30, nil, nil)
		expect(index).toBe(3)
		index = sortedArray:IndexOf(40, nil, nil)
		expect(index).toBe(4)
		expect(sortedArray:Find(99, nil, nil)).toBeNil()
	end)

	it("should remove element by value and update sorted order", function()
		local sortedArray = SortedArray.new({15, 25, 35, 45})
		local removed = sortedArray:RemoveElement(35, nil, nil)
		expect(removed).toBe(35)
		expect(sortedArray:Find(35, nil, nil)).toBeNil()
		expect(#sortedArray).toBe(3)
	end)

	it("should remove element by index and update array correctly", function()
		local sortedArray = SortedArray.new({5, 10, 15, 20})
		local removed = sortedArray:RemoveIndex(2)
		expect(removed).toBe(10)
		expect(#sortedArray).toBe(3)
		for index = 1, #sortedArray - 1 do
			expect(sortedArray.Array[index] <= sortedArray.Array[index + 1]).toBe(true)
		end
	end)

	it("should pop and shift elements correctly", function()
		local sortedArray = SortedArray.new({100, 200, 300})
		local popped = sortedArray:Pop()
		expect(popped).toBe(300)
		expect(#sortedArray).toBe(2)
		local shifted = sortedArray:Shift()
		expect(shifted).toBe(100)
		expect(#sortedArray).toBe(1)
		expect(sortedArray.Array[1]).toBe(200)
	end)

	it("should support Copy, Clone, and CloneDeep", function()
		local original = SortedArray.new({7, 3, 5, 1}, function(a, b)
			return a < b
		end)
		local copyData = original:Copy()
		expect(#copyData).toBe(#original)
		local clone = original:Clone()
		for index = 1, #clone - 1 do
			expect(clone.Array[index] <= clone.Array[index + 1]).toBe(true)
		end
		local cloneDeep = original:CloneDeep()
		expect(#cloneDeep).toBe(#original)
		original:Clear()
		expect(#original).toBe(0)
		expect(#cloneDeep).toBeGreaterThan(0)
	end)

	it("should perform SortIndex and SortElement correctly", function()
		local sortedArray = SortedArray.new({50, 30, 40, 20, 10}, function(a, b)
			return a < b
		end)
		local newIndex = sortedArray:SortIndex(3)
		expect(newIndex).toBeGreaterThanOrEqual(1)
		expect(newIndex).toBeLessThanOrEqual(#sortedArray)
		newIndex = sortedArray:SortElement(20, nil, nil)
		expect(newIndex).toBeGreaterThanOrEqual(1)
		expect(newIndex).toBeLessThanOrEqual(#sortedArray)
	end)

	it("should get intersection of two SortedArrays", function()
		local sortedArray0 = SortedArray.new({1, 2, 3, 4, 5})
		local sortedArray1 = SortedArray.new({3, 5, 7, 9})
		local intersection = sortedArray0:GetIntersection(sortedArray1, nil, nil)
		expect(#intersection).toBe(2)
		expect(intersection.Array[1]).toBe(3)
		expect(intersection.Array[2]).toBe(5)
	end)

	it("should return a proper string representation and length", function()
		local sortedArray = SortedArray.new({8, 6, 4, 2}, function(a, b)
			return a < b
		end)

		expect((string.find(tostring(sortedArray), "SortedArray"))).never.toBeNil()
		expect(#sortedArray).toBe(#sortedArray.Array)
	end)
end)

return false
