--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local SimpleTrie = require(script.Parent.Parent.SimpleTrie)

local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("SimpleTrie", function()
	local trie: SimpleTrie.SimpleTrie = nil
	beforeEach(function()
		trie = SimpleTrie.new()
	end)

	it("should insert and search for words correctly", function()
		trie:Insert("apple")
		expect(trie:Search("apple")).toBe(true)
		expect(trie:Search("app")).toBe(false)
		expect(trie:StartsWith("app")).toBe(true)
	end)

	it("should handle insertion of multiple words with common prefixes", function()
		trie:Insert("app")
		trie:Insert("application")
		trie:Insert("apex")
		expect(trie:Search("app")).toBe(true)
		expect(trie:Search("application")).toBe(true)
		expect(trie:Search("apex")).toBe(true)
		expect(trie:Search("apple")).toBe(false)
		expect(trie:StartsWith("ap")).toBe(true)
	end)

	it("should return false for searching non-existent words", function()
		expect(trie:Search("banana")).toBe(false)
		expect(trie:StartsWith("ban")).toBe(false)
	end)

	it("should return true for startsWith on existing prefixes", function()
		trie:Insert("banana")
		expect(trie:StartsWith("ban")).toBe(true)
		expect(trie:StartsWith("bana")).toBe(true)
		expect(trie:StartsWith("band")).toBe(false)
	end)

	it("should handle empty string insertion and search", function()
		trie:Insert("")
		expect(trie:Search("")).toBe(true)
		expect(trie:StartsWith("")).toBe(true)
	end)

	it("should handle case sensitivity correctly", function()
		trie:Insert("Apple")
		expect(trie:Search("apple")).toBe(false)
		expect(trie:Search("Apple")).toBe(true)
		expect(trie:StartsWith("App")).toBe(true)
		expect(trie:StartsWith("app")).toBe(false)
	end)
end)

return false
