--!native
--!optimize 2
--!strict

local Error = require(script.Parent.Parent.Parent.Error)
local GreenTea = require(script.Parent.Parent.Parent.GreenTea)

local Types = require(script.Parent.Parent.Types)

export type MaxPriorityQueue<T> = typeof(setmetatable(
	{} :: {
		Array: {Types.HeapEntry<T>},
		Length: number,

		InsertWithPriority: (self: MaxPriorityQueue<T>, value: T, priority: number) -> number,
		Insert: (self: MaxPriorityQueue<T>, value: T, priority: number) -> number,

		ChangePriority: (self: MaxPriorityQueue<T>, value: T, newPriority: number) -> number,

		RemovePriority: (self: MaxPriorityQueue<T>, priority: number) -> (),
		RemoveValue: (self: MaxPriorityQueue<T>, value: T) -> (),

		GetFirstPriority: (self: MaxPriorityQueue<T>) -> number?,
		GetLastPriority: (self: MaxPriorityQueue<T>) -> number?,

		PopElement: ((self: MaxPriorityQueue<T>, onlyValue: true) -> T?)
			& ((self: MaxPriorityQueue<T>, onlyValue: false?) -> Types.HeapEntry<T>?)
			& ((self: MaxPriorityQueue<T>, onlyValue: nil) -> Types.HeapEntry<T>?),

		Clear: (self: MaxPriorityQueue<T>) -> MaxPriorityQueue<T>,

		Contains: (self: MaxPriorityQueue<T>, value: T) -> boolean,
	},
	{} :: {
		__len: (self: MaxPriorityQueue<T>) -> number,
		__tostring: (self: MaxPriorityQueue<T>) -> string,
	}
))

type Static = {
	ClassName: "MaxPriorityQueue",
	new: <T>() -> MaxPriorityQueue<T>,
	Is: (value: any) -> boolean,
	instanceof: (value: any) -> boolean,
}
type PrivateStatic = Static & {
	__len: (self: MaxPriorityQueue<any>) -> number,
	__tostring: (self: MaxPriorityQueue<any>) -> string,
}

local cached: boolean = nil
local function IsUltraStrictMode(): boolean
	if cached ~= nil then
		return cached
	end

	local isUltraStrictMode = not not _G.__DEV__
	cached = isUltraStrictMode
	return isUltraStrictMode
end

local IsInteger = GreenTea.build(GreenTea.number({integer = true}))
local IsMaybeBoolean = GreenTea.build(GreenTea.optional(GreenTea.boolean()))
local IsNumber = GreenTea.build(GreenTea.number())
local IsUnknown = GreenTea.build(GreenTea.unknown())

--[=[
	TODO: Documentation

	@tag Supports Debug Mode
	@tag Supports __len
	@tag Supports __tostring
	@class MaxPriorityQueue
]=]
local MaxPriorityQueue = {} :: MaxPriorityQueue<any> & Static
local Private = MaxPriorityQueue :: MaxPriorityQueue<any> & PrivateStatic
MaxPriorityQueue.ClassName = "MaxPriorityQueue";
(MaxPriorityQueue :: any).__index = MaxPriorityQueue

--[=[
	The data structure that represents an element in a `MaxPriorityQueue`.

	@interface HeapEntry
	@field Priority number -- The priority of the element.
	@field Value T -- The value of the element.
	@within MaxPriorityQueue
]=]

type HeapEntry<T> = Types.HeapEntry<T>

local function FindClosest<T>(array: {HeapEntry<T>}, priority: number, low: number, high: number)
	local middle = math.floor((low + high) / 2)
	if middle == 0 then
		return -1
	end

	local element = array[middle]
	while middle ~= high do
		local priority2 = element.Priority
		if priority == priority2 then
			return middle
		end

		if priority < priority2 then
			high = middle - 1
		else
			low = middle + 1
		end

		middle = math.floor((low + high) / 2)
		element = array[middle]
	end

	return middle
end

--[=[
	Creates a new MaxPriorityQueue.
	@return MaxPriorityQueue<T>
]=]
function MaxPriorityQueue.new<T>(): MaxPriorityQueue<T>
	return setmetatable({
		Array = {};
		Length = 0;
	}, MaxPriorityQueue) :: never
end

--[=[
	Checks if `value` is literally a MaxPriorityQueue.

	```lua
	MaxPriorityQueue.Is(MaxPriorityQueue.new()) -- true
	MaxPriorityQueue.Is(MaxPriorityQueue) -- false
	MaxPriorityQueue.Is({}) -- false
	MaxPriorityQueue.Is(nil) -- false
	MaxPriorityQueue.Is(1) -- false
	```

	@param value unknown
	@return boolean
]=]
function MaxPriorityQueue.Is(value)
	return type(value) == "table" and getmetatable(value) == MaxPriorityQueue
end
--[=[
	An alias for [MaxPriorityQueue.Is].

	@function instanceof
	@within MaxPriorityQueue

	@param value unknown
	@return boolean
]=]
MaxPriorityQueue.instanceof = MaxPriorityQueue.Is

local function Insert<T>(self: MaxPriorityQueue<T>, value: T, priority: number)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.Insert)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsNumber:matches(priority)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.Insert)
			error(exception)
		end
	end

	local array = self.Array
	local length = self.Length
	local position = FindClosest(array, priority, 1, length)

	if position == -1 then
		table.insert(array, {Priority = priority, Value = value})
		self.Length = length + 1
		return 1
	end

	local element = array[position]
	if element then
		position = if priority < element.Priority then position else position + 1
	else
		position = 1
	end

	table.insert(array, position, {Priority = priority, Value = value})
	self.Length = length + 1
	return position
end

--[=[
	Adds an element to the `MaxPriorityQueue` with an associated priority.

	@method Insert
	@within MaxPriorityQueue

	@param value T -- The value to insert.
	@param priority number -- The priority of the value.
	@return integer -- The index of the element in the `MaxPriorityQueue`.
]=]
MaxPriorityQueue.Insert = Insert
--[=[
	An alias for [MaxPriorityQueue.Insert].

	@method InsertWithPriority
	@within MaxPriorityQueue

	@param value T -- The value to insert.
	@param priority number -- The priority of the value.
	@return integer -- The index of the element in the `MaxPriorityQueue`.
]=]
MaxPriorityQueue.InsertWithPriority = Insert

return table.freeze(MaxPriorityQueue :: Static)
