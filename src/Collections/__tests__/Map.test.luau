--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local Map = require(script.Parent.Parent.Map)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type Map<K, V> = Map.Map<K, V>

local AN_ITEM = "bar" :: string
local ANOTHER_ITEM = "baz" :: string

local function Sort<T>(array: {T}, callback: nil | (a: T, b: T) -> boolean): {T}
	table.sort(array, callback)
	return array
end

describe("Map", function()
	describe("constructors", function()
		it("creates an empty map", function()
			expect(#Map.new()).toBe(0)
		end)

		it("creates a Map from an array", function()
			local foo: Map<string, string> = Map.new({
				{AN_ITEM, "foo"};
				{ANOTHER_ITEM, "val"};
			})
			expect(foo.Size).toEqual(2)
			expect(foo:Has(AN_ITEM)).toEqual(true)
			expect(foo:Has(ANOTHER_ITEM)).toEqual(true)
		end)

		it("creates a Map from a Map", function()
			local originalMap: Map<string, string> = Map.new({
				{AN_ITEM, "foo"};
				{ANOTHER_ITEM, "val"};
			})
			local foo = Map.new(originalMap)
			expect(foo.Size).toEqual(2)
			expect(foo:Has(AN_ITEM)).toEqual(true)
			expect(foo:Has(ANOTHER_ITEM)).toEqual(true)
		end)

		it("creates a Map from an array with duplicate keys", function()
			local foo = Map.new({
				{AN_ITEM, "foo1"};
				{AN_ITEM, "foo2"};
			})
			expect(foo.Size).toEqual(1)
			expect(foo:Get(AN_ITEM)).toEqual("foo2")

			expect(foo:Keys()).toEqual({AN_ITEM})
			expect(foo:Values()).toEqual({"foo2"})
			expect(foo:Entries()).toEqual({{AN_ITEM, "foo2"}})
		end)
	end)
end)

return false
