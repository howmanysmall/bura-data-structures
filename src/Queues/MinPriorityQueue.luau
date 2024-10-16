--!native
--!optimize 2
--!strict

local Error = require(script.Parent.Parent.Parent.Error)
local GreenTea = require(script.Parent.Parent.Parent.GreenTea)

local Types = require(script.Parent.Parent.Types)

type ComparisonFunction<T> = Types.ComparisonFunction<T>
type HeapEntry<T> = Types.HeapEntry<T>

export type MinPriorityQueue<T> = typeof(setmetatable(
	{} :: {
		Array: {HeapEntry<T>},
		Length: number,

		InsertWithPriority: (self: MinPriorityQueue<T>, value: T, priority: number) -> number,
		Insert: (self: MinPriorityQueue<T>, value: T, priority: number) -> number,

		ChangePriority: (
			self: MinPriorityQueue<T>,
			value: T,
			newPriority: number,
			equalityCheck: ComparisonFunction<T>?
		) -> number,

		RemovePriority: (self: MinPriorityQueue<T>, priority: number) -> (),
		RemoveValue: (self: MinPriorityQueue<T>, value: T, equalityCheck: ComparisonFunction<T>?) -> (),

		GetFirstPriority: (self: MinPriorityQueue<T>) -> number?,
		GetLastPriority: (self: MinPriorityQueue<T>) -> number?,

		PopElement: ((self: MinPriorityQueue<T>, onlyValue: true) -> T?)
			& ((self: MinPriorityQueue<T>, onlyValue: false?) -> HeapEntry<T>?)
			& ((self: MinPriorityQueue<T>, onlyValue: nil) -> HeapEntry<T>?),

		Clear: (self: MinPriorityQueue<T>) -> MinPriorityQueue<T>,

		Contains: (self: MinPriorityQueue<T>, value: T, equalityCheck: ComparisonFunction<T>?) -> boolean,
	},
	{} :: {
		__len: (self: MinPriorityQueue<T>) -> number,
		__tostring: (self: MinPriorityQueue<T>) -> string,
	}
))

type Static = {
	ClassName: "MinPriorityQueue",
	new: <T>() -> MinPriorityQueue<T>,
	Is: (value: any) -> boolean,
	instanceof: (value: any) -> boolean,
}
type PrivateStatic = Static & {
	__len: (self: MinPriorityQueue<any>) -> number,
	__tostring: (self: MinPriorityQueue<any>) -> string,
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

local IsMaybeBoolean = GreenTea.build(GreenTea.optional(GreenTea.boolean()))
local IsMaybeFunction = GreenTea.build(GreenTea.optional(GreenTea.anyfn()))
local IsNumber = GreenTea.build(GreenTea.number())
local IsUnknown = GreenTea.build(GreenTea.unknown())

--[=[
	In a min priority queue, elements are inserted by the priority in
	descending order and the maximum value is always removed first from the
	queue.

	This uses a sorted array internally for the maximum speed possible when
	inserting, popping, and removing by priority.

	@tag Supports Debug Mode
	@tag Supports __len
	@tag Supports __tostring
	@class MinPriorityQueue
]=]
local MinPriorityQueue = {} :: MinPriorityQueue<any> & Static
local Private = MinPriorityQueue :: MinPriorityQueue<any> & PrivateStatic
MinPriorityQueue.ClassName = "MinPriorityQueue";
(MinPriorityQueue :: any).__index = MinPriorityQueue

--[=[
	An element with all your elements. This is technically a sorted array.

	@readonly
	@prop Array ReadonlyArray<HeapEntry<T>>
	@within MinPriorityQueue
]=]

--[=[
	The length of the `MinPriorityQueue`.

	@readonly
	@prop Length integer
	@within MinPriorityQueue
]=]

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

		if priority > priority2 then
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
	Creates a new MinPriorityQueue.
	@return MinPriorityQueue<T>
]=]
function MinPriorityQueue.new<T>(): MinPriorityQueue<T>
	return setmetatable({
		Array = {};
		Length = 0;
	}, MinPriorityQueue) :: never
end

--[=[
	Checks if `value` is literally a `MinPriorityQueue`.

	```lua
	MinPriorityQueue.Is(MinPriorityQueue.new()) -- true
	MinPriorityQueue.Is(MinPriorityQueue) -- false
	MinPriorityQueue.Is({}) -- false
	MinPriorityQueue.Is(nil) -- false
	MinPriorityQueue.Is(1) -- false
	```

	@param value unknown
	@return boolean
]=]
function MinPriorityQueue.Is(value)
	return type(value) == "table" and getmetatable(value) == MinPriorityQueue
end
--[=[
	An alias for [MinPriorityQueue.Is].

	@function instanceof
	@within MinPriorityQueue

	@param value unknown
	@return boolean
]=]
MinPriorityQueue.instanceof = MinPriorityQueue.Is

local function Insert<T>(self: MinPriorityQueue<T>, value: T, priority: number)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.Insert)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsNumber:matches(priority)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.Insert)
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
		position = if priority > element.Priority then position else position + 1
	else
		position = 1
	end

	table.insert(array, position, {Priority = priority, Value = value})
	self.Length = length + 1
	return position
end

--[=[
	Adds an element to the `MinPriorityQueue` with an associated priority.

	@method Insert
	@within MinPriorityQueue

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@param value T -- The value to insert.
	@param priority number -- The priority of the value.
	@return integer -- The index of the element in the `MinPriorityQueue`.
]=]
MinPriorityQueue.Insert = Insert
--[=[
	An alias for [MinPriorityQueue.Insert].

	@method InsertWithPriority
	@within MinPriorityQueue

	@param value T -- The value to insert.
	@param priority number -- The priority of the value.
	@return integer -- The index of the element in the `MinPriorityQueue`.
]=]
MinPriorityQueue.InsertWithPriority = Insert

--[=[
	Allows you to change the priority of an element in the `MinPriorityQueue`.

	:::info Time Complexity
	This function has kind of a funky time complexity on account of it treating
	your entries as immutable.
	:::

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.
	@error ValueNotFoundError -- Thrown when you try to change the priority of an element that doesn't exist.

	@param value T -- The value to change the priority of.
	@param newPriority number -- The new priority of the value.
	@param equalityCheck? ComparisonFunction<T> -- The function used to check if two values are equal. If unprovided, we'll default to `==`.
	@return integer -- The index of the element in the `MinPriorityQueue`.
]=]
function MinPriorityQueue:ChangePriority<T>(value: T, newPriority, equalityCheck: ComparisonFunction<T>?)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.ChangePriority)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsNumber:matches(newPriority)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.ChangePriority)
			error(exception)
		end
		local typeSuccess2, typeError2 = IsMaybeFunction:matches(equalityCheck)
		if not typeSuccess2 then
			local exception = Error.new(tostring(typeError2))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.ChangePriority)
			error(exception)
		end
	end

	local array = self.Array
	if equalityCheck then
		for index, element in array do
			if equalityCheck(element.Value, value) then
				table.remove(array, index)
				self.Length -= 1
				return Insert(self, value, newPriority)
			end
		end
	else
		for index, element in array do
			if element.Value == value then
				table.remove(array, index)
				self.Length -= 1
				return Insert(self, value, newPriority)
			end
		end
	end

	local exception = Error.new("Couldn't find value in the queue?")
	exception.name = "ValueNotFoundError"
	Error.captureStackTrace(exception, MinPriorityQueue.ChangePriority)
	error(exception)
end

--[=[
	Gets the priority of the first value in the `MinPriorityQueue`. This is the
	value that will be removed last.
	@return number?
]=]
function MinPriorityQueue:GetFirstPriority()
	return if self.Length == 0 then nil else self.Array[1].Priority
end

--[=[
	Gets the priority of the last value in the `MinPriorityQueue`. This is the
	value that will be removed first.
	@return number?
]=]
function MinPriorityQueue:GetLastPriority()
	local length = self.Length
	return if length == 0 then nil else self.Array[length].Priority
end

--[=[
	Pops an element from the `MinPriorityQueue`. This removes the last element
	in the array.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@param onlyValue? boolean -- Whether or not to return the value of the element.
	@return HeapEntry<T> | T | nil
]=]
function MinPriorityQueue:PopElement(onlyValue: boolean?)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsMaybeBoolean:matches(onlyValue)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.PopElement)
			error(exception)
		end
	end

	local length = self.Length
	if length == 0 then
		return nil
	end

	local array = self.Array
	local element = array[length]
	if element then
		array[length] = nil
		self.Length = length - 1
		return if onlyValue then element.Value else element
	end

	return nil
end

--[=[
	Removes an element from the `MinPriorityQueue` with a specific priority.
	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.
	@param priority number -- The priority of the element to remove.
]=]
function MinPriorityQueue:RemovePriority(priority)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsNumber:matches(priority)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.RemovePriority)
			error(exception)
		end
	end

	local array = self.Array
	local length = self.Length

	local index = FindClosest(array, priority, 1, length)
	if index == -1 then
		return
	end

	table.remove(array, index)
	self.Length = length - 1
end

--[=[
	Removes an element from the `MinPriorityQueue` with a specific value.

	:::warning Time Complexity
	This function does _NOT_ use the binary search algorithm. It is uses a
	linear search (may change in the future) so it has the O(n) time
	complexity.
	:::

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@param value T -- The value of the element to remove.
	@param equalityCheck? ComparisonFunction<T> -- The function used to check if two values are equal. If unprovided, we'll default to `==`.
]=]
function MinPriorityQueue:RemoveValue(value, equalityCheck)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.RemoveValue)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsMaybeFunction:matches(equalityCheck)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.RemoveValue)
			error(exception)
		end
	end

	local array = self.Array
	if equalityCheck then
		for index, element in array do
			if equalityCheck(element.Value, value) then
				table.remove(array, index)
				self.Length -= 1
				break
			end
		end
	else
		for index, element in array do
			if element.Value == value then
				table.remove(array, index)
				self.Length -= 1
				break
			end
		end
	end
end

--[=[
	Clears the entire `MinPriorityQueue`.
	@return MinPriorityQueue<T>
]=]
function MinPriorityQueue:Clear()
	table.clear(self.Array)
	self.Length = 0
	return self
end

--[=[
	Checks if the `MinPriorityQueue` contains a specific value.

	:::warning Time Complexity
	This function does _NOT_ use the binary search algorithm. It is uses a
	linear search (may change in the future) so it has the O(n) time
	complexity.
	:::

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@param value T -- The value of the element to remove.
	@param equalityCheck? ComparisonFunction<T> -- The function used to check if two values are equal. If unprovided, we'll default to `==`.
	@return boolean
]=]
function MinPriorityQueue:Contains(value, equalityCheck)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.Contains)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsMaybeFunction:matches(equalityCheck)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MinPriorityQueue.Contains)
			error(exception)
		end
	end

	if equalityCheck then
		for _, element in self.Array do
			if equalityCheck(element.Value, value) then
				return true
			end
		end
	else
		for _, element in self.Array do
			if element.Value == value then
				return true
			end
		end
	end

	return false
end

function Private:__len()
	return self.Length
end

function Private:__tostring()
	local array = self.Array
	local stringBuilder = table.create(#array)
	for index, value in array do
		stringBuilder[index] = `\t\{Priority: {value.Priority}, Value = {value.Value}};`
	end
	return `MinPriorityQueue<[\n{table.concat(stringBuilder, "\n")}\n]>`
end

return table.freeze(MinPriorityQueue :: Static)
