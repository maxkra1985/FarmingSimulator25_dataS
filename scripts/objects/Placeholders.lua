Placeholders = {}

-- Local values: i
function Placeholders:onCreate(node)
	for v2_ = getNumOfChildren(node) - 1, 0, -1 do
		delete(getChildAt(node, v2_))
	end
end
