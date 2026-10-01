Placeholders = {}
function Placeholders:onCreate(node)
	for i = getNumOfChildren(node) - 1, 0, -1 do
		delete(getChildAt(node, i))
	end
end
