--!native
--!optimize 2
--!strict

local Error = require(script.Parent.Parent.Parent.Error)
local GreenTea = require(script.Parent.Parent.Parent.GreenTea)

local Types = require(script.Parent.Types)

export type SimpleTrie = Types.BasicTrie

type Static = {
	ClassName: "SimpleTrie",
	new: () -> SimpleTrie,
	Is: (value: any) -> boolean,
	instanceof: (value: any) -> boolean,
}
type PrivateStatic = Static & {__tostring: (self: SimpleTrie) -> string}

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
	The `SimpleTrie` class implements a basic trie (prefix tree) data structure
	for efficient storage and retrieval of strings. It allows you to insert
	words, search for exact matches, and check if any words in the trie start
	with a given prefix. If you need utf8 support, use the [Utf8Trie] class.

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
	local trie = DataStructures.SimpleTrie.new()

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

	-- Check if an object is a SimpleTrie
	print(DataStructures.SimpleTrie.Is(trie))     -- Output: true
	print(DataStructures.SimpleTrie.Is({}))       -- Output: false

	-- String representation
	print(tostring(trie))          -- Output: "SimpleTrie"
	```

	### Methods:

	- **`SimpleTrie.new(): SimpleTrie`**
		- Creates a new `SimpleTrie` instance.
		- **Returns:** A new `SimpleTrie` object.

	- **`SimpleTrie:Insert(word: string): void`**
		- Inserts a word into the trie.
		- **Parameters:**
			- `word` (string): The word to insert into the trie.
		- **Errors:**
			- **`DebugTypeError`**: Thrown when debug mode is enabled and
			  `word` is not a string.

	- **`SimpleTrie:Search(word: string): boolean`**
		- Searches for an exact word in the trie.
		- **Parameters:**
			- `word` (string): The word to search for.
		- **Returns:** `true` if the word exists in the trie, `false`
		  otherwise.
		- **Errors:**
			- **`DebugTypeError`**: Thrown when debug mode is enabled and
			  `word` is not a string.

	- **`SimpleTrie:StartsWith(prefix: string): boolean`**
		- Checks if any word in the trie starts with the given prefix.
		- **Parameters:**
			- `prefix` (string): The prefix to check.
		- **Returns:** `true` if any word starts with the prefix, `false` otherwise.
		- **Errors:**
			- **`DebugTypeError`**: Thrown when debug mode is enabled and
			  `prefix` is not a string.

	- **`SimpleTrie.Is(value: any): boolean`**
		- Checks if the given value is an instance of `SimpleTrie`.
		- **Parameters:**
			- `value` (any): The value to check.
		- **Returns:** `true` if `value` is a `SimpleTrie` instance, `false`
		  otherwise.

	- **`SimpleTrie.instanceof(value: any): boolean`**
		- Alias for `SimpleTrie.Is`.

	### Tags:

	- `Supports Debug Mode`: You can set `_G.__DEV__` to `true` to enable
	  debug mode. This has to be done BEFORE requiring the module.
	- `Supports __tostring`: You can call `tostring` on the trie.

	@tag Supports Debug Mode
	@tag Supports __tostring
	@class SimpleTrie
]=]
local SimpleTrie = {} :: SimpleTrie & Static
local Private = SimpleTrie :: SimpleTrie & PrivateStatic
SimpleTrie.ClassName = "SimpleTrie";
(SimpleTrie :: any).__index = SimpleTrie

--[=[
	Creates a new SimpleTrie.
	@return SimpleTrie
]=]
function SimpleTrie.new()
	return setmetatable({
		Root = {
			Children = {};
			IsEnding = false;
		};
	}, SimpleTrie) :: never
end

--[=[
	Checks if `value` is literally a `SimpleTrie`.

	```lua
	SimpleTrie.Is(SimpleTrie.new()) -- true
	SimpleTrie.Is(SimpleTrie) -- false
	SimpleTrie.Is({}) -- false
	SimpleTrie.Is(nil) -- false
	SimpleTrie.Is(1) -- false
	```

	@param value unknown
	@return boolean
]=]
function SimpleTrie.Is(value)
	return type(value) == "table" and getmetatable(value) == SimpleTrie
end
--[=[
	An alias for [SimpleTrie.Is].

	@function instanceof
	@within SimpleTrie

	@param value unknown
	@return boolean
]=]
SimpleTrie.instanceof = SimpleTrie.Is

--[=[
	Inserts a word into the trie.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.
	@param word string -- The word to insert.
]=]
function SimpleTrie:Insert(word)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsString:matches(word)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, SimpleTrie.Insert)
			error(exception)
		end
	end

	local current = self.Root
	for index = 1, #word do
		local byte = string.byte(word, index)
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
function SimpleTrie:Search(word)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsString:matches(word)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, SimpleTrie.Search)
			error(exception)
		end
	end

	local current = self.Root
	for index = 1, #word do
		local nextInLine = current.Children[string.byte(word, index)]
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
function SimpleTrie:StartsWith(prefix)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsString:matches(prefix)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, SimpleTrie.StartsWith)
			error(exception)
		end
	end

	local current = self.Root
	for index = 1, #prefix do
		local nextInLine = current.Children[string.byte(prefix, index)]
		if not nextInLine then
			return false
		end
		current = nextInLine
	end

	return true
end

function Private:__tostring()
	return "SimpleTrie"
end

return table.freeze(SimpleTrie :: Static)
