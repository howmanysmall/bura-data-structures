--!strict

--[=[
	All the types related to this library.
	@class Types
]=]
local Types = {}

-- Luau really, really, really needs strict arrays.
export type Tuple<K, V> = {K | V}

--[=[
	The data structure that represents an element in a [MaxPriorityQueue] or
	[MinPriorityQueue].

	@interface HeapEntry
	@field Priority number -- The priority of the element.
	@field Value T -- The value of the element.
	@within Types
]=]
export type HeapEntry<T> = {
	Priority: number,
	Value: T,
}

--[=[
	A function that compares two values.

	@type ComparisonFunction <T>(a: T, b: T) -> boolean
	@within Types
]=]
export type ComparisonFunction<T> = (a: T, b: T) -> boolean

return table.freeze(Types)
