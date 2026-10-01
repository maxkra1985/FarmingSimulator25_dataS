FieldUtil = {}
function FieldUtil.onCreate(_, id)
	for i = 0, getNumOfChildren(id) - 1 do
		local fieldId = getChildAt(id, i)
		local field = Field.new()
		if field:load(fieldId) then
			g_fieldManager:addField(field)
		else
			field:delete()
		end
	end
end
