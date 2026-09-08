EnumUtil = {}

-- Local values: k, v
function EnumUtil.getName(enum, enumValue)
	for v3_, v4_ in pairs(enum) do
		if v4_ == enumValue and v3_ ~= "NUM" then
			return v3_
		end
	end
	return nil
end

function EnumUtil.getNumEntries(enum)
	return enum.NUM or table.size(enum)
end

-- Local values: keys, k, v
function EnumUtil.getKeys(enum)
	local v7_ = {}
	for v8_, _ in pairs(enum) do
		if v8_ ~= "NUM" then
			table.insert(v7_, v8_)
		end
	end
	return v7_
end
