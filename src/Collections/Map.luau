--!optimize 2
--!strict

local Error = require(script.Parent.Parent.Parent.Error)
local GreenTea = require(script.Parent.Parent.Parent.GreenTea)
local GreenTeaUtilities = require(script.Parent.Parent.Parent.GreenTeaUtilities)

local Types = require(script.Parent.Parent.Types)

export type Map<K, V> = typeof(setmetatable(
	{} :: {
		Size: number,

		Clear: (self: Map<K, V>) -> (),
		Delete: (self: Map<K, V>, key: K) -> boolean,
		Get: (self: Map<K, V>, key: K) -> V?,
		Has: (self: Map<K, V>, key: K) -> boolean,
		IsEmpty: (self: Map<K, V>) -> boolean,
		Set: (self: Map<K, V>, key: K, value: V) -> Map<K, V>,

		Keys: (self: Map<K, V>) -> {K},
		Values: (self: Map<K, V>) -> {V},
		Entries: (self: Map<K, V>) -> {Types.Tuple<K, V>},
	},
	{} :: {
		__iter: (self: Map<K, V>) -> () -> (K, V),
		__len: (self: Map<K, V>) -> number,
		__tostring: (self: Map<K, V>) -> string,
	}
))
type Private<K, V> = typeof(setmetatable(
	{} :: {
		Size: number,

		Clear: (self: Private<K, V>) -> (),
		Delete: (self: Private<K, V>, key: K) -> boolean,
		Get: (self: Private<K, V>, key: K) -> V?,
		Has: (self: Private<K, V>, key: K) -> boolean,
		IsEmpty: (self: Private<K, V>) -> boolean,
		Set: (self: Private<K, V>, key: K, value: V) -> Private<K, V>,

		Keys: (self: Private<K, V>) -> {K},
		Values: (self: Private<K, V>) -> {V},
		Entries: (self: Private<K, V>) -> {Types.Tuple<K, V>},

		Map: {[K]: V},
	},
	{} :: {
		__iter: (self: Private<K, V>) -> () -> (K, V),
		__len: (self: Private<K, V>) -> number,
		__tostring: (self: Private<K, V>) -> string,
	}
))

type Static = {
	ClassName: "Map",
	new: <K, V>(iterable: {Types.Tuple<K, V>} | Map<K, V> | nil) -> Map<K, V>,
	ToIterableArray: <K, V>(map: {[K]: V}) -> {Types.Tuple<K, V>},
	Is: (value: any) -> boolean,
	instanceof: (value: any) -> boolean,
}
type PrivateStatic = Static & {
	__iter: (self: Map<any, any>) -> () -> (any, any),
	__len: (self: Map<any, any>) -> number,
	__tostring: (self: Map<any, any>) -> string,
}

--[=[
	This is a map data structure that simply behaves like a dictionary would.
	There are a few differences from a regular dictionary though, being:

	- You can get the length of the map with `#map` in constant time.
	- There is a `Size` property.
	- You mutate it with methods.

	@tag Supports Debug Mode
	@tag Supports __iter
	@tag Supports __len
	@tag Supports __tostring
	@class Map
]=]
local Map = {} :: Map<any, any> & Static
local Private = Map :: Private<any, any> & PrivateStatic
Map.ClassName = "Map";
(Map :: any).__index = Map

local cached: boolean = nil
local function IsUltraStrictMode(): boolean
	if cached ~= nil then
		return cached
	end

	local isUltraStrictMode = not not _G.__DEV__
	cached = isUltraStrictMode
	return isUltraStrictMode
end

local IsIterable = GreenTea.build(GreenTea.optional(GreenTea.union(
	GreenTea.array(GreenTea.table({
		[1] = GreenTea.unknown();
		[2] = GreenTea.unknown();
		[GreenTea.any()] = GreenTea.never();
	}, {
		count = {min = 0, max = 2};
		raw = true;
	})),
	GreenTeaUtilities.IsInstanceOfLuauClassFromTable(Map, "Map")
)))
local IsUnknown = GreenTea.build(GreenTea.unknown())

--[=[
	Creates a new map.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.
	@error TypeError -- Thrown when you pass an incorrect type.

	@param iterable? Array<[K, V]> | Map<K, V> -- The iterable object to create a map from.
	@return Map<K, V>
]=]
function Map.new<K, V>(iterable: {Types.Tuple<K, V>} | Map<K, V> | nil): Map<K, V>
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsIterable:matches(iterable)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Map.new)
			error(exception)
		end
	end

	local self: Private<K, V> = setmetatable({}, Map) :: never

	if iterable == nil then
		self.Map = {}
		self.Size = 0
	elseif type(iterable) == "table" then
		if Map.Is(iterable) then
			local cast = iterable :: Private<K, V>
			self.Map = table.clone(cast.Map)
			self.Size = cast.Size
		else
			local map: {[K]: V} = {}
			local length = 0
			for _, entry: Types.Tuple<K, V> in iterable :: {Types.Tuple<K, V>} do
				local key = entry[1] :: K
				if map[key] == nil then
					length += 1
				end

				map[key] = entry[2] :: V
			end
			self.Map = map
			self.Size = length
		end
	else
		local exception = Error.new(
			string.format("`%*` `%*` is not iterable, cannot make Map using it", typeof(iterable), tostring(iterable))
		)
		exception.name = "TypeError"
		Error.captureStackTrace(exception, Map.new)
		error(exception)
	end

	return self
end

--[=[
	Converts a standard Luau map object to the iterable array format.
	@param map {[K]: V} -- The map to convert.
	@return Array<[K, V]> -- The iterable array.
]=]
function Map.ToIterableArray<K, V>(map: {[K]: V}): {Types.Tuple<K, V>}
	local array: {Types.Tuple<K, V>} = {}
	local length = 0
	for key, value in map do
		length += 1
		array[length] = {key, value} :: Types.Tuple<K, V>
	end
	return array
end

--[=[
	Checks if `value` is literally a Map.

	```lua
	Map.Is(Map.new()) -- true
	Map.Is(Map) -- false
	Map.Is({}) -- false
	Map.Is(nil) -- false
	Map.Is(1) -- false
	```

	@param value unknown
	@return boolean
]=]
function Map.Is(value: any)
	return type(value) == "table" and getmetatable(value) == Map
end
--[=[
	An alias for [Map.Is].

	@function instanceof
	@within Map

	@param value unknown
	@return boolean
]=]
Map.instanceof = Map.Is

--[=[
	Clears the map.

	@method Clear
	@within Map
]=]
function Private:Clear()
	self.Size = 0
	table.clear(self.Map)
end

--[=[
	Deletes the key from the map.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@method Delete
	@within Map

	@param key K -- The key to delete from the map.
	@return boolean -- Whether or not the key was deleted.
]=]
function Private:Delete(key)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsUnknown:matches(key)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Map.Delete)
			error(exception)
		end
	end

	local map = self.Map
	if map[key] == nil then
		return false
	end

	self.Size -= 1
	map[key] = nil
	return true
end

--[=[
	Gets the value of the key from the map.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@method Get
	@within Map

	@param key K -- The key to get the value of.
	@return V? -- The value of the key, or nil if it doesn't exist.
]=]
function Private:Get(key)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsUnknown:matches(key)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Map.Get)
			error(exception)
		end
	end

	return self.Map[key]
end

--[=[
	Checks if the value exists in the map. You probably can just use [Map.Get]
	instead. Here's an example of what I mean:

	If your code looks like this:

	```lua
	local cache: Map<string, number> = Map.new()

	local function GetValue(key: string)
		if cache:Has(key) then
			return cache:Get(key)
		end

		local value = DoSomething(key)
		cache:Set(key, value)
		return value
	end
	```

	You should instead do this:

	```lua
	local cache: Map<string, number> = Map.new()

	local function GetValue(key: string)
		local cached = cache:Get(key)
		if cached ~= nil then
			return cached
		end

		local value = DoSomething(key)
		cache:Set(key, value)
		return value
	end
	```

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@method Has
	@within Map

	@param key K -- The key to get the value of.
	@return boolean -- Whether or not the key exists in the map.
]=]
function Private:Has(key)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsUnknown:matches(key)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Map.Has)
			error(exception)
		end
	end

	return self.Map[key] ~= nil
end

--[=[
	Checks if the map is empty.

	@method IsEmpty
	@within Map

	@return boolean -- Whether or not the map is empty.
]=]
function Private:IsEmpty()
	return self.Size == 0
end

--[=[
	Sets the value of the key in the map.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@method Set
	@within Map

	@param key K -- The key to set the value of.
	@param value V -- The value to set.
	@return Map<K, V>
]=]
function Private:Set(key, value)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(key)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Map.Set)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsUnknown:matches(value)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, Map.Set)
			error(exception)
		end
	end

	local map = self.Map
	if map[key] == nil then
		self.Size += 1
	end

	map[key] = value
	return self
end

--[=[
	Gets an array of all the keys in the map.

	@method Keys
	@within Map

	@return {K} -- The array of keys.
]=]
function Private:Keys()
	local keys = table.create(self.Size)
	local length = 0
	for key in self.Map do
		length += 1
		keys[length] = key
	end
	return keys
end

--[=[
	Gets an array of all the values in the map.

	@method Values
	@within Map

	@return {V} -- The array of values.
]=]
function Private:Values()
	local values = table.create(self.Size)
	local length = 0
	for _, value in self.Map do
		length += 1
		values[length] = value
	end
	return values
end
--[=[
	Gets an array of all the entries in the map.

	@method Entries
	@within Map

	@return Array<[K, V]> -- The array of entries.
]=]
function Private:Entries()
	return Map.ToIterableArray(self.Map)
end

local function __iter<K, V>(self: Private<K, V>)
	return next, self.Map :: {[K]: V}
end
Private.__iter = __iter :: never

function Private:__len()
	return self.Size
end

function Private:__tostring()
	-- TODO: Mirror actual Map tostring
	-- Run this in your browser's console to see what I mean.
	--[==[
		{
			const map = new Map([["A", 1], ["B", 2], ["C", 3], ["D", 4], ["E", 2], ["F", 2], ["G", 2], ["H", 2], ["I", 2], ["J", 2], ["K", 2], ["L", 2]])
			console.log(map);
		}
	]==]

	return "Map"
end

return table.freeze(Map :: Static)
