--!optimize 2
--!strict

local LRUCache = require(script.Caches.LRUCache)
local LiveRandom = require(script.Random.LiveRandom)
local MaxPriorityQueue = require(script.Queues.MaxPriorityQueue)
local MinPriorityQueue = require(script.Queues.MinPriorityQueue)
local SimpleTrie = require(script.Tries.SimpleTrie)
local SortedArray = require(script.Arrays.SortedArray)
local Types = require(script.Types)
local Utf8Trie = require(script.Tries.Utf8Trie)

local DataStructures = table.freeze({
	LiveRandom = LiveRandom;
	LRUCache = LRUCache;
	MaxPriorityQueue = MaxPriorityQueue;
	MinPriorityQueue = MinPriorityQueue;
	SimpleTrie = SimpleTrie;
	SortedArray = SortedArray;
	Utf8Trie = Utf8Trie;
})

export type ComparisonFunction<T> = Types.ComparisonFunction<T>
export type HeapEntry<T> = Types.HeapEntry<T>

export type LiveRandom = LiveRandom.LiveRandom
export type LRUCache<K, V> = LRUCache.LRUCache<K, V>
export type MaxPriorityQueue<T> = MaxPriorityQueue.MaxPriorityQueue<T>
export type MinPriorityQueue<T> = MinPriorityQueue.MinPriorityQueue<T>
export type SimpleTrie = SimpleTrie.SimpleTrie
export type SortedArray<T> = SortedArray.SortedArray<T>
export type Utf8Trie = Utf8Trie.Utf8Trie

return DataStructures
