--!native
--!optimize 2
--!strict

local Error = require(script.Parent.Parent.Parent.Error)
local GreenTea = require(script.Parent.Parent.Parent.GreenTea)

local Types = require(script.Parent.Parent.Types)

type ComparisonFunction<T> = Types.ComparisonFunction<T>
type HeapEntry<T> = Types.HeapEntry<T>

export type MaxPriorityQueue<T> = typeof(setmetatable(
	{} :: {
		Array: {HeapEntry<T>},
		Length: number,

		InsertWithPriority: (self: MaxPriorityQueue<T>, value: T, priority: number) -> number,
		Insert: (self: MaxPriorityQueue<T>, value: T, priority: number) -> number,

		ChangePriority: (
			self: MaxPriorityQueue<T>,
			value: T,
			newPriority: number,
			equalityCheck: ComparisonFunction<T>?
		) -> number,

		RemovePriority: (self: MaxPriorityQueue<T>, priority: number) -> (),
		RemoveValue: (self: MaxPriorityQueue<T>, value: T, equalityCheck: ComparisonFunction<T>?) -> (),

		GetFirstPriority: (self: MaxPriorityQueue<T>) -> number?,
		GetLastPriority: (self: MaxPriorityQueue<T>) -> number?,

		PopElement: ((self: MaxPriorityQueue<T>, onlyValue: true) -> T?)
			& ((self: MaxPriorityQueue<T>, onlyValue: false?) -> HeapEntry<T>?)
			& ((self: MaxPriorityQueue<T>, onlyValue: nil) -> HeapEntry<T>?),

		Clear: (self: MaxPriorityQueue<T>) -> MaxPriorityQueue<T>,

		Contains: (self: MaxPriorityQueue<T>, value: T, equalityCheck: ComparisonFunction<T>?) -> boolean,
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

local IsMaybeBoolean = GreenTea.build(GreenTea.optional(GreenTea.boolean()))
local IsMaybeFunction = GreenTea.build(GreenTea.optional(GreenTea.anyfn()))
local IsNumber = GreenTea.build(GreenTea.number())
local IsUnknown = GreenTea.build(GreenTea.unknown())

--[=[
	In a max priority queue, elements are inserted by the priority in ascending
	order and the maximum value is always removed first from the queue.

	This uses a sorted array internally for the maximum speed possible when
	inserting, popping, and removing by priority.

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
	An element with all your elements. This is technically a sorted array.

	@readonly
	@prop Array ReadonlyArray<HeapEntry<T>>
	@within MaxPriorityQueue
]=]

--[=[
	The length of the `MaxPriorityQueue`.

	@readonly
	@prop Length integer
	@within MaxPriorityQueue
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
	Checks if `value` is literally a `MaxPriorityQueue`.

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

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

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

--[=[
	Allows you to change the priority of an element in the `MaxPriorityQueue`.

	:::info Time Complexity
	This function has kind of a funky time complexity on account of it treating
	your entries as immutable.
	:::

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.
	@error ValueNotFoundError -- Thrown when you try to change the priority of an element that doesn't exist.

	@param value T -- The value to change the priority of.
	@param newPriority number -- The new priority of the value.
	@param equalityCheck? ComparisonFunction<T> -- The function used to check if two values are equal. If unprovided, we'll default to `==`.
	@return integer -- The index of the element in the `MaxPriorityQueue`.
]=]
function MaxPriorityQueue:ChangePriority<T>(value: T, newPriority, equalityCheck: ComparisonFunction<T>?)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.ChangePriority)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsNumber:matches(newPriority)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.ChangePriority)
			error(exception)
		end
		local typeSuccess2, typeError2 = IsMaybeFunction:matches(equalityCheck)
		if not typeSuccess2 then
			local exception = Error.new(tostring(typeError2))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.ChangePriority)
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
	Error.captureStackTrace(exception, MaxPriorityQueue.ChangePriority)
	error(exception)
end

--[=[
	Gets the priority of the first value in the `MaxPriorityQueue`. This is the
	value that will be removed last.
	@return number?
]=]
function MaxPriorityQueue:GetFirstPriority()
	return if self.Length == 0 then nil else self.Array[1].Priority
end

--[=[
	Gets the priority of the last value in the `MaxPriorityQueue`. This is the
	value that will be removed first.
	@return number?
]=]
function MaxPriorityQueue:GetLastPriority()
	local length = self.Length
	return if length == 0 then nil else self.Array[length].Priority
end

--[=[
	Pops an element from the `MaxPriorityQueue`. This removes the last element
	in the array.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@param onlyValue? boolean -- Whether or not to return the value of the element.
	@return HeapEntry<T> | T | nil
]=]
function MaxPriorityQueue:PopElement(onlyValue: boolean?)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsMaybeBoolean:matches(onlyValue)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.PopElement)
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
	Removes an element from the `MaxPriorityQueue` with a specific priority.
	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.
	@param priority number -- The priority of the element to remove.
]=]
function MaxPriorityQueue:RemovePriority(priority)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsNumber:matches(priority)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.RemovePriority)
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
	Removes an element from the `MaxPriorityQueue` with a specific value.

	:::warning Time Complexity
	This function does _NOT_ use the binary search algorithm. It is uses a
	linear search (may change in the future) so it has the O(n) time
	complexity.
	:::

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@param value T -- The value of the element to remove.
	@param equalityCheck? ComparisonFunction<T> -- The function used to check if two values are equal. If unprovided, we'll default to `==`.
]=]
function MaxPriorityQueue:RemoveValue(value, equalityCheck)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.RemoveValue)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsMaybeFunction:matches(equalityCheck)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.RemoveValue)
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
	Clears the entire `MaxPriorityQueue`.
	@return MaxPriorityQueue<T>
]=]
function MaxPriorityQueue:Clear()
	table.clear(self.Array)
	self.Length = 0
	return self
end

--[=[
	Checks if the `MaxPriorityQueue` contains a specific value.

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
function MaxPriorityQueue:Contains(value, equalityCheck)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsUnknown:matches(value)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.Contains)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsMaybeFunction:matches(equalityCheck)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, MaxPriorityQueue.Contains)
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
	return `MaxPriorityQueue<[\n{table.concat(stringBuilder, "\n")}\n]>`
end

return table.freeze(MaxPriorityQueue :: Static)
