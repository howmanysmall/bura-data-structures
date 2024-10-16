--!optimize 2
--!strict

export type BasicTrie = {
	Root: Node,

	Insert: (self: BasicTrie, word: string) -> (),
	Search: (self: BasicTrie, word: string) -> boolean,
	StartsWith: (self: BasicTrie, prefix: string) -> boolean,
}
export type Node = {
	Children: {[number]: Node},
	IsEnding: boolean,
}

return false
