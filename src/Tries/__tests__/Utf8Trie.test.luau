--!optimize 2
--!strict

local TestService = game:GetService("TestService")
local JestGlobals = require(TestService.UnitTesting.DevPackages.JestGlobals)

local Utf8Trie = require(script.Parent.Parent.Utf8Trie)

local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("Utf8Trie", function()
	local trie: Utf8Trie.Utf8Trie = nil
	beforeEach(function()
		trie = Utf8Trie.new()
	end)

	it("should insert and search for words with UTF-8 characters", function()
		trie:Insert("こんにちは") -- Japanese for "Hello"
		expect(trie:Search("こんにちは")).toBe(true)
		expect(trie:Search("こん")).toBe(false)
		expect(trie:StartsWith("こん")).toBe(true)
	end)

	it("should handle emojis correctly", function()
		trie:Insert("😀")
		trie:Insert("😁😂")
		expect(trie:Search("😀")).toBe(true)
		expect(trie:Search("😁")).toBe(false)
		expect(trie:Search("😁😂")).toBe(true)
		expect(trie:StartsWith("😁")).toBe(true)
		expect(trie:StartsWith("😂")).toBe(false)
	end)

	it("should handle words with mixed ASCII and UTF-8 characters", function()
		trie:Insert("hello😀")
		trie:Insert("hello")
		expect(trie:Search("hello")).toBe(true)
		expect(trie:Search("hello😀")).toBe(true)
		expect(trie:Search("hello😁")).toBe(false)
		expect(trie:StartsWith("hell")).toBe(true)
		expect(trie:StartsWith("hello😀")).toBe(true)
	end)

	it("should return false for searching non-existent UTF-8 words", function()
		expect(trie:Search("世界")).toBe(false) -- Chinese for "World"
		expect(trie:StartsWith("世")).toBe(false)
	end)

	it("should handle insertion of multiple UTF-8 words with common prefixes", function()
		trie:Insert("😀😃😄")
		trie:Insert("😀😃")
		trie:Insert("😀")
		expect(trie:Search("😀")).toBe(true)
		expect(trie:Search("😀😃")).toBe(true)
		expect(trie:Search("😀😃😄")).toBe(true)
		expect(trie:Search("😀😄")).toBe(false)
		expect(trie:StartsWith("😀")).toBe(true)
	end)

	it("should handle complex scripts correctly", function()
		trie:Insert("हैलो") -- Hindi for "Hello"
		expect(trie:Search("हैलो")).toBe(true)
		expect(trie:StartsWith("है")).toBe(true)
		expect(trie:Search("है")).toBe(false)
	end)

	it("should handle accents and diacritics", function()
		trie:Insert("café")
		trie:Insert("cafe")
		expect(trie:Search("café")).toBe(true)
		expect(trie:Search("cafe")).toBe(true)
		expect(trie:StartsWith("caf")).toBe(true)
	end)
end)

return false
