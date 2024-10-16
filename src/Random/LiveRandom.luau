--!native
--!optimize 2
--!strict

local Error = require(script.Parent.Parent.Parent.Error)
local GreenTea = require(script.Parent.Parent.Parent.GreenTea)

export type LiveRandom = {
	Get: (self: LiveRandom) -> number,
	Peek: (self: LiveRandom) -> number,
	Rig: (self: LiveRandom, value: number) -> LiveRandom,
}
type Private = {
	Last: number,
	Offset: number,
	Prime: number,
	Range: number,
	Rigged: {number},

	Get: (self: Private) -> number,
	Peek: (self: Private) -> number,
	Rig: (self: Private, value: number) -> Private,
}

type Static = {
	ClassName: "LiveRandom",
	new: (minimum: number, maximum: number?, seed: number?) -> LiveRandom,
	Is: (value: any) -> boolean,
	instanceof: (value: any) -> boolean,
}
type PrivateStatic = Static & {__tostring: (self: LiveRandom) -> string}

local cached: boolean = nil
local function IsUltraStrictMode(): boolean
	if cached ~= nil then
		return cached
	end

	local isUltraStrictMode = not not _G.__DEV__
	cached = isUltraStrictMode
	return isUltraStrictMode
end

local IsIntegerRaw = GreenTea.number({integer = true})
local IsInteger = GreenTea.build(IsIntegerRaw)
local IsMaybeInteger = GreenTea.build(GreenTea.optional(IsIntegerRaw))
local IsMaybeNumber = GreenTea.build(GreenTea.optional(GreenTea.number()))

local function Gcd(a: number, b: number)
	while b > 0 do
		a, b = b, a % b
	end
	return a
end

-- cheese it
local NextInteger = Random.new().NextInteger

local function GetRandomRelativePrime(value: number, randomLibrary: Random)
	if value == 1 then
		return 1
	end

	local newValue = NextInteger(randomLibrary, 1, value - 1)
	if Gcd(value, newValue) == 1 then
		return newValue
	end

	repeat
		newValue = NextInteger(randomLibrary, 1, value - 1)
	until Gcd(newValue, value) == 1

	return newValue
end

--[=[
	## LiveRandom

	Will loop through all of the numbers in range before repeating. Does not
	use any table nor any messy bash, just math. B)

	It first finds a co-prime integer to n between 1 and (n - 1) and constantly increments a running sum.

	- This is guaranteed to touch all of the integers.

	### Complexity

	- **Storage:** `O(1)`
	- **Construction:** `O(log(n))`
	- **Get:** `O(1)`

	@tag Supports Debug Mode
	@tag Supports __tostring
	@class LiveRandom
]=]
local LiveRandom = {} :: LiveRandom & Static
local Private = LiveRandom :: Private & PrivateStatic
LiveRandom.ClassName = "LiveRandom";
(LiveRandom :: any).__index = LiveRandom

--[=[
	Creates a new `LiveRandom` instance.

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	:::info Default Values
	Like `math.random`, if you do not provide a maximum, the maximum becomes
	the minimum and the minimum becomes 1.
	:::

	@param minimum integer -- The minimum value the random number can be.
	@param maximum? integer -- The maximum value the random number can be.
	@param seed? number -- The seed to use for the random number generator. Defaults to `os.clock()%1 * 1E7`.
	@return LiveRandom
]=]
function LiveRandom.new(minimum, maximum, seed)
	if IsUltraStrictMode() then
		local typeSuccess0, typeError0 = IsInteger:matches(minimum)
		if not typeSuccess0 then
			local exception = Error.new(tostring(typeError0))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, LiveRandom.new)
			error(exception)
		end
		local typeSuccess1, typeError1 = IsMaybeInteger:matches(maximum)
		if not typeSuccess1 then
			local exception = Error.new(tostring(typeError1))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, LiveRandom.new)
			error(exception)
		end
		local typeSuccess2, typeError2 = IsMaybeNumber:matches(seed)
		if not typeSuccess2 then
			local exception = Error.new(tostring(typeError2))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, LiveRandom.new)
			error(exception)
		end
	end

	local trueMaximum = maximum or 1
	local trueMinimum = minimum
	if not maximum then
		trueMaximum = minimum
		trueMinimum = 1
	end

	local range = trueMaximum - trueMinimum + 1
	local randomLibrary = Random.new(seed or os.clock() % 1 * 1E7)

	return setmetatable({
		Last = NextInteger(randomLibrary, 1, range);
		Offset = trueMinimum - 1;
		Prime = GetRandomRelativePrime(range, randomLibrary);
		Range = range;
		Rigged = {};
	}, LiveRandom) :: never
end

--[=[
	Checks if `value` is literally a `LiveRandom`.

	```lua
	LiveRandom.Is(LiveRandom.new(100)) -- true
	LiveRandom.Is(LiveRandom) -- false
	LiveRandom.Is({}) -- false
	LiveRandom.Is(nil) -- false
	LiveRandom.Is(1) -- false
	```

	@param value unknown
	@return boolean
]=]
function LiveRandom.Is(value)
	return type(value) == "table" and getmetatable(value) == LiveRandom
end
--[=[
	An alias for [LiveRandom.Is].

	@function instanceof
	@within LiveRandom

	@param value unknown
	@return boolean
]=]
LiveRandom.instanceof = LiveRandom.Is

--[=[
	Gets a random value.

	@method Get
	@within LiveRandom

	@return integer
]=]
function Private:Get()
	local range = self.Range
	local rigged = self.Rigged

	local length = #rigged
	local riggedValue = rigged[length]
	if riggedValue then
		rigged[length] = nil
		return riggedValue
	end

	local value = self.Last + self.Prime
	local last = if value > range then value - range else value
	self.Last = last
	return last + self.Offset
end

--[=[
	Peeks at the next value. This does not cause it to roll a new value.

	@method Peek
	@within LiveRandom

	@return integer
]=]
function Private:Peek()
	local rigged = self.Rigged
	local top = rigged[#rigged]
	if top then
		return top
	end

	local value = self.Last + self.Prime
	local range = self.Range
	return (if value > range then value - range else value) + self.Offset
end

--[=[
	Rigs the random number generator, which forces the next value to be the
	given value.

	@method Rig
	@within LiveRandom

	@error DebugTypeError -- Thrown when you are using debug mode and you pass an incorrect type.

	@param value integer -- The value to rig the random number generator to.
	@return LiveRandom
]=]
function Private:Rig(value)
	if IsUltraStrictMode() then
		local typeSuccess, typeError = IsInteger:matches(value)
		if not typeSuccess then
			local exception = Error.new(tostring(typeError))
			exception.name = "DebugTypeError"
			Error.captureStackTrace(exception, LiveRandom.Rig)
			error(exception)
		end
	end

	table.insert(self.Rigged, value)
	return self
end

function Private:__tostring()
	return "LiveRandom"
end

return table.freeze(LiveRandom :: Static)
