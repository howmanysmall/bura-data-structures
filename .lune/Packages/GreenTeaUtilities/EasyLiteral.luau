--!optimize 2
--!strict

local GreenTea = require("../GreenTea")

local function EasyLiteral<T>(...: any)
	local count = select("#", ...)
	local array = table.create(count)

	for index = 1, count do
		local value = select(index, ...)
		array[index] = GreenTea.literal(value)
	end

	return GreenTea.union(table.unpack(array)) :: T
end

return EasyLiteral
