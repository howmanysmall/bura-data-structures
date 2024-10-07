--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local LRUCache = require(script.Parent.Parent.LRUCache)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type LRUCache<K, V> = LRUCache.LRUCache<K, V>

-- _G.__DEV__ = true
local itDebug = (if _G.__DEV__ then it else it.skip) :: typeof(it)

describe("LRUCache", function()
	it("should store and retrieve values correctly", function()
		local lruCache: LRUCache<number, string> = LRUCache.new(2)
		lruCache:Set(1, "one")
		lruCache:Set(2, "two")

		expect(lruCache:Get(1)).toBe("one")
		expect(lruCache:Get(2)).toBe("two")
		expect(lruCache.Size).toBe(2)
		expect(#lruCache).toBe(2)
	end)

	it("should evict the least recently used item when capacity is exceeded", function()
		local lruCache: LRUCache<number, string> = LRUCache.new(2)
		lruCache:Set(1, "one")
		lruCache:Set(2, "two")
		lruCache:Set(3, "three")

		expect(lruCache:Get(1)).toBeUndefined()
		expect(lruCache:Get(2)).toBe("two")
		expect(lruCache:Get(3)).toBe("three")
		expect(lruCache.Size).toBe(2)
		expect(#lruCache).toBe(2)
	end)

	it("should update recently used item on Get", function()
		local lruCache: LRUCache<number, string> = LRUCache.new(2)
		lruCache:Set(1, "one")
		lruCache:Set(2, "two")
		lruCache:Get(1)
		lruCache:Set(3, "three")

		expect(lruCache:Get(1)).toBe("one")
		expect(lruCache:Get(2)).toBeUndefined()
		expect(lruCache:Get(3)).toBe("three")
		expect(lruCache.Size).toBe(2)
		expect(#lruCache).toBe(2)
	end)

	it("should overwrite value if key already exists", function()
		local lruCache: LRUCache<number, string> = LRUCache.new(2)
		lruCache:Set(1, "one")
		lruCache:Set(1, "uno")

		expect(lruCache:Get(1)).toBe("uno")
		expect(lruCache.Size).toBe(1)
		expect(#lruCache).toBe(1)
	end)

	it("should handle Clear correctly", function()
		local lruCache: LRUCache<number, string> = LRUCache.new(2)
		lruCache:Set(1, "one")
		lruCache:Set(2, "two")
		lruCache:Clear()

		expect(lruCache:Get(1)).toBeUndefined()
		expect(lruCache:Get(2)).toBeUndefined()
		expect(lruCache.Size).toBe(0)
		expect(#lruCache).toBe(0)
	end)

	itDebug("should throw with invalid data", function()
		expect(function()
			LRUCache.new(0)
		end).toThrow()

		local lruCache: LRUCache<number, string> = LRUCache.new(2)
		expect(function()
			lruCache:Set(nil :: never, "nil")
		end).toThrow()

		expect(function()
			lruCache:Set(1, nil :: never)
		end).toThrow()
	end)
end)

return false
