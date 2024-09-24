--!optimize 2
--!strict

local GreenTea = require("../GreenTea")

type IntersectionType =
	(<T1, T2>(T1, T2) -> T1 & T2)
	& (<T1, T2, T3>(T1, T2, T3) -> T1 & T2 & T3)
	& (<T1, T2, T3, T4>(T1, T2, T3, T4) -> T1 & T2 & T3 & T4)
	& (<T1, T2, T3, T4, T5>(T1, T2, T3, T4, T5) -> T1 & T2 & T3 & T4 & T5)
	& (<T1, T2, T3, T4, T5, T6>(T1, T2, T3, T4, T5, T6) -> T1 & T2 & T3 & T4 & T5 & T6)
	& (<T1, T2, T3, T4, T5, T6, T7>(T1, T2, T3, T4, T5, T6, T7) -> T1 & T2 & T3 & T4 & T5 & T6 & T7)
	& (<T1, T2, T3, T4, T5, T6, T7, T8>(T1, T2, T3, T4, T5, T6, T7, T8) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8)
	& (<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
		T1,
		T2,
		T3,
		T4,
		T5,
		T6,
		T7,
		T8,
		T9
	) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8 & T9)
	& (<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(
		T1,
		T2,
		T3,
		T4,
		T5,
		T6,
		T7,
		T8,
		T9,
		T10
	) -> T1 & T2 & T3 & T4 & T5 & T6 & T7 & T8 & T9 & T10)
	& (<T>(...T) -> T)

local IntersectionPlus = GreenTea.intersection :: IntersectionType
return IntersectionPlus
