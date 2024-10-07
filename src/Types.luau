--!strict

local Types = {}

-- Luau really, really, really needs strict arrays.
export type Tuple<K, V> = {K | V}

export type HeapEntry<T> = {
	Priority: number,
	Value: T,
}

return table.freeze(Types)
