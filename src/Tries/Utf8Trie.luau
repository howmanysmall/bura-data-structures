--!native
--!optimize 2
--!strict

local Error = require(script.Parent.Parent.Parent.Error)
local GreenTea = require(script.Parent.Parent.Parent.GreenTea)

local Types = require(script.Parent.Types)

export type Utf8Trie = Types.BasicTrie

type Static = {
	ClassName: "Utf8Trie",
	new: () -> Utf8Trie,
	Is: (value: any) -> boolean,
	instanceof: (value: any) -> boolean,
}
type PrivateStatic = Static & {__tostring: (self: Utf8Trie) -> string}

local cached: boolean = nil
local function IsUltraStrictMode(): boolean
	if cached ~= nil then
		return cached
	end

	local isUltraStrictMode = not not _G.__DEV__
	cached = isUltraStrictMode
	return isUltraStrictMode
end
local IsString = GreenTea.build(GreenTea.string())

--[=[
	The `Utf8Trie` class implements a basic trie (prefix tree) data structure
	for efficient storage and retrieval of strings. It allows you to insert
	words, search for exact matches, and check if any words in the trie start
	with a given prefix. If you need performance, use the [SimpleTrie] class.

	### Features:

	- **Efficient String Storage:** Stores strings in a hierarchical structure
	  for fast retrieval and minimal redundancy.
	- **Word Insertion:** Add words to the trie using the `Insert` method.
	- **Exact Word Search:** Determine if a word exists in the trie with the
	  `Search` method.
	- **Prefix Matching:** Use the `StartsWith` method to check if any words
	  start with a given prefix.
	- **Supports Debug Mode:** Enable debug mode by setting `_G.__DEV__ = true`
	  before requiring the module to enforce type checks and provide detailed
	  error messages.

	### Example Usage:

	```lua
	_G.__DEV__ = RunService:IsStudio()
	local DataStructures = require("DataStructures")

	-- Create a new trie
	local trie = DataStructures.Utf8Trie.new()

	-- Insert words
	trie:Insert("apple")
	trie:Insert("app")
	trie:Insert("banana")

	-- Search for exact words
	print(trie:Search("apple"))   -- Output: true
	print(trie:Search("app"))     -- Output: true
	print(trie:Search("apples"))  -- Output: false

	-- Check for prefixes
	print(trie:StartsWith("app"))   -- Output: true
	print(trie:StartsWith("ban"))   -- Output: true
	print(trie:StartsWith("bat"))   -- Output: false

	-- Check if an object is a Utf8Trie
	print(DataStructures.Utf8Trie.Is(trie))     -- Output: true
	print(DataStructures.Utf8Trie.Is({}))       -- Output: false

	-- String representation
	print(tostring(trie))          -- Output: "Utf8Trie"
	```

	### Methods:

	- **`Utf8Trie.new(): Utf8Trie`**
		- Creates a new `Utf8Trie` instance.
		- **Returns:** A new `Utf8Trie` object.

	- **`Utf8Trie:Insert(word: string): void`**
		- Inserts a word into the trie.
		- **Parameters:**
			- `word` (string): The word to insert into the trie.
		- **Errors:**
			- **`DebugTypeError`**: Thrown when debug mode is enabled and
			  `word` is not a string.

	- **`Utf8Trie:Search(word: string): boolean`**
		- Searches for an exact word in the trie.
		- **Parameters:**
			- `word` (string): The word to search for.
		- **Returns:** `true` if the word exists in the trie, `false`
		  otherwise.
		- **Errors:**
			- **`DebugTypeError`**: Thrown when debug mode is enabled and
			  `word` is not a string.

	- **`Utf8Trie:StartsWith(prefix: string): boolean`**
		- Checks if any word in the trie starts with the given prefix.
		- **Parameters:**
			- `prefix` (string): The prefix to check.
		- **Returns:** `true` if any word starts with the prefix, `false` otherwise.
		- **Errors:**
			- **`DebugTypeError`**: Thrown when debug mode is enabled and
			  `prefix` is not a string.

	- **`Utf8Trie.Is(value: any): boolean`**
		- Checks if the given value is an instance of `Utf8Trie`.
		- **Parameters:**
			- `value` (any): The value to check.
		- **Returns:** `true` if `value` is a `Utf8Trie` instance, `false`
		  otherwise.

	- **`Utf8Trie.instanceof(value: any): boolean`**
		- Alias for `Utf8Trie.Is`.

	### Tags:

	- `Supports Debug Mode`: You can set `_G.__DEV__` to `true` to enable
	  debug mode. This has to be done BEFORE requiring the module.
	- `Supports __tostring`: You can call `tostring` on the trie.

	@tag Supports Debug Mode
	@tag Supports __tostring
	@class Utf8Trie
]=]
local Utf8Trie = {} :: Utf8Trie & Static
local Private = Utf8Trie :: Utf8Trie & PrivateStatic
Utf8Trie.ClassName = "Utf8Trie";
(Utf8Trie :: any).__index = Utf8Trie

--[=[
	Creates a new Utf8Trie.
	@return Utf8Trie
]=]
function Utf8Trie.new()
	return setmetatable({
		Root = {
			Children = {};
			IsEnding = false;
		};
	}, Utf8Trie) :: never
end

--[=[
	Checks if `value` is literally a `Utf8Trie`.

	```lua
	Utf8Trie.Is(Utf8Trie.new()) -- true
	Utf8Trie.Is(Utf8Trie) -- false
	Utf8Trie.Is({}) -- false
	Utf8Trie.Is(nil) -- false
	Utf8Trie.Is(1) -- false
	```

	@param value unknown
	@return boolean
]=]
function Utf8Trie.Is(value)
	return type(value) == "table" and getmetatable(value) == Utf8Trie
end
--[=[
	An alias for [Utf8Trie.Is].

	@function instanceof
	@within Utf8Trie

	@param value unknown
	@return boolean
]=]
Utf8Trie.instanceof = Utf8Trie.Is

--[=[
	Inserts a word into the trie.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.
	@param word string -- The word to insert.
]=]
function Utf8Trie:Insert(word)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsString:matches(word)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Utf8Trie.Insert)
			error(exception)
		end
	end

	local current = self.Root
	for start, finish in utf8.graphemes(word) do
		local byte = utf8.codepoint(word, start, finish)
		local children = current.Children

		local nextInLine = children[byte]
		if not nextInLine then
			nextInLine = {
				Children = {};
				IsEnding = false;
			}
			children[byte] = nextInLine
		end

		current = nextInLine
	end

	current.IsEnding = true
end

--[=[
	Searches for an exact word in the trie.

	@error DebugTypeError -- Thrown when debug mode is enabled and `word` is not a string.

	@param word string -- The word to search for.
	@return boolean -- `true` if the word exists in the trie, `false` otherwise.
]=]
function Utf8Trie:Search(word)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsString:matches(word)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Utf8Trie.Search)
			error(exception)
		end
	end

	local current = self.Root
	for start, finish in utf8.graphemes(word) do
		local nextInLine = current.Children[utf8.codepoint(word, start, finish)]
		if not nextInLine then
			return false
		end
		current = nextInLine
	end

	return current.IsEnding
end

--[=[
	Checks if any word in the trie starts with the given prefix.

	@error DebugTypeError -- Thrown when debug mode is enabled and `prefix` is not a string.

	@param prefix string -- The prefix to check.
	@return boolean -- `true` if any word starts with the prefix, `false` otherwise.
]=]
function Utf8Trie:StartsWith(prefix)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsString:matches(prefix)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Utf8Trie.StartsWith)
			error(exception)
		end
	end

	local current = self.Root
	for start, finish in utf8.graphemes(prefix) do
		local nextInLine = current.Children[utf8.codepoint(prefix, start, finish)]
		if not nextInLine then
			return false
		end
		current = nextInLine
	end

	return true
end

function Private:__tostring()
	return "Utf8Trie"
end

return table.freeze(Utf8Trie :: Static)
