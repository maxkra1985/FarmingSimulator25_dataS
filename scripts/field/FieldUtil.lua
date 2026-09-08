FieldUtil = {}

-- Local values: i, fieldId, field
function FieldUtil.onCreate(_, id)
	for v2_ = 0, getNumOfChildren(id) - 1 do
		local v3_ = getChildAt(id, v2_)
		local v4_ = Field.new()
		if v4_:load(v3_) then
			g_fieldManager:addField(v4_)
		else
			v4_:delete()
		end
	end
end
