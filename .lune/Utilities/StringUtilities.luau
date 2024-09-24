--!optimize 2
--!strict

local StringUtilities = {}

function StringUtilities.ToPascalCase(value: string)
	return (
		string.gsub(
			string.gsub(string.gsub(string.lower(value), "[ _-](%a)", string.upper), "^%a", string.upper),
			"%p",
			""
		)
	)
end

return table.freeze(StringUtilities)
