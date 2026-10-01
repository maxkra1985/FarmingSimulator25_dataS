function translate(name, dx, dy, dz)
	local x, y, z = getTranslation(name)
	setTranslation(name, x + dx, y + dy, z + dz)
end
function rotate(name, dx, dy, dz)
	local x, y, z = getRotation(name)
	setRotation(name, (x + dx) % 6.283185307179586, (y + dy) % 6.283185307179586, (z + dz) % 6.283185307179586)
end
function toggleVisibility(name)
	local state = getVisibility(name)
	setVisibility(name, not state)
end
function printScenegraph(node, visibleOnly)
	printScenegraphRec(node, 0, visibleOnly)
end
function printScenegraphRec(node, level, visibleOnly)
	local ident = ""
	for i = 1, level do
		ident = ident .. "    "
	end
	if visibleOnly == nil or not visibleOnly or visibleOnly and getVisibility(node) then
		print(string.format("%s%s(%d) | %s", ident, getName(node), node, tostring(getVisibility(node))))
		local num = getNumOfChildren(node)
		for i = 0, num - 1 do
			printScenegraphRec(getChildAt(node, i), level + 1)
		end
	end
end
function getNodeClassNamesString(node)
	local className = nil
	for classNameToCheck, classId in pairs(ClassIds) do
		if getHasClassId(node, classId) then
			if className == nil then
				className = classNameToCheck
			else
				className = className .. " + " .. classNameToCheck
			end
		end
	end
	return className
end
function printNodeInfo(node)
	if node == nil or node == 0 or not entityExists(node) then
		print("printNodeInfo: invalid node")
		return
	end
	local classNames = getNodeClassNamesString(node)
	if classNames == nil then
		print("printNodeInfo: invalid node")
	else
		local transX, transY, transZ = getTranslation(node)
		local worldTransX, worldTransY, worldTransZ = getWorldTranslation(node)
		local rotX, rotY, rotZ = getRotation(node)
		rotX = math.deg(rotX)
		rotY = math.deg(rotY)
		rotZ = math.deg(rotZ)
		local scaleX, scaleY, scaleZ = getScale(node)
		local visibility = getVisibility(node)
		local effectiveVisibility = getEffectiveVisibility(node)
		print(string.format("Node info for '%s' (%d):", getName(node), node))
		print(string.format("  Type(s):             %s", classNames))
		print(string.format("  Path:                %s", getNodeFullPath(node)))
		if getParent(node) == getRootNode() then
			print(string.format("  Translation (world): %.4f %.4f %.4f", worldTransX, worldTransY, worldTransZ))
		else
			print(string.format("  Translation:         %.4f %.4f %.4f", transX, transY, transZ))
			print(string.format("  Translation (world): %.4f %.4f %.4f", worldTransX, worldTransY, worldTransZ))
		end
		print(string.format("  Rotation (deg):      %.4f %.4f %.4f", rotX, rotY, rotZ))
		print(string.format("  Scale:               %.4f %.4f %.4f", scaleX, scaleY, scaleZ))
		local _v52 = visibility
		print(string.format("  Visibility:          %s%s", tostring(_v52), _v52))
	end
end
function printNodeInfoShort(node)
	if node == nil or node == 0 or not entityExists(node) then
		print("NODEINFO|invalid")
		return
	end
	local classNames = getNodeClassNamesString(node)
	if classNames == nil then
		print("NODEINFO|invalid")
	else
		local transX, transY, transZ = getTranslation(node)
		local worldTransX, worldTransY, worldTransZ = getWorldTranslation(node)
		local rotX, rotY, rotZ = getRotation(node)
		rotX = math.deg(rotX)
		rotY = math.deg(rotY)
		rotZ = math.deg(rotZ)
		local scaleX, scaleY, scaleZ = getScale(node)
		local visibility = getVisibility(node)
		local effectiveVisibility = getEffectiveVisibility(node)
		local path = string.gsub(getNodeFullPath(node), "|", ",")
		local info = "NODEINFO"
		info = info .. string.format("|id=%d", node)
		info = info .. string.format("|name=%s", getName(node))
		info = info .. string.format("|type=%s", classNames)
		info = info .. string.format("|path=%s", path)
		info = info .. string.format("|translation=%.4f,%.4f,%.4f", transX, transY, transZ)
		info = info .. string.format("|worldTranslation=%.4f,%.4f,%.4f", worldTransX, worldTransY, worldTransZ)
		info = info .. string.format("|parentToWorld=%s", tostring(getParent(node) == getRootNode()))
		info = info .. string.format("|rotation=%.4f,%.4f,%.4f", rotX, rotY, rotZ)
		info = info .. string.format("|scale=%.4f,%.4f,%.4f", scaleX, scaleY, scaleZ)
		info = info .. string.format("|visibility=%s", tostring(visibility))
		info = info .. string.format("|effectiveVisibility=%s", tostring(effectiveVisibility))
		print(info)
	end
end
function printFullPath(node, str)
	str = string.format("|%s%s", getName(node), getVisibility(node) and "" or "(hidden)") .. (str or "")
	if getParent(node) ~= 0 then
		printFullPath(getParent(node), str)
	else
		print(str)
	end
end
function getNodeFullPath(node, str)
	str = "|" .. getName(node) .. (str or "")
	local parent = getParent(node)
	if parent ~= 0 then
		return getNodeFullPath(parent, str)
	else
		return str
	end
end
function exportScenegraphToGraphviz(node, filename)
	if node ~= nil and node ~= 0 then
		if filename == nil then
			filename = string.format("%s_output.gv", getName(node))
		end
		local fileId = createFile(filename, FileAccess.WRITE)
		local result = "// Scenegraph export for Graphviz\n"
		result = string.format("%s// Start Node is '%s_(%d)'\n", result, getName(node), node)
		result = string.format("%sdigraph G {\n", result)
		result = string.format("%s%s_%d  [shape=box,color=red,style=filled]\n", result, getName(node), node)
		result = exportScenegraphToGraphvizRec(node, result)
		result = string.format("%s\n}", result)
		fileWrite(fileId, result)
		delete(fileId)
	end
end
function exportScenegraphToGraphvizRec(node, result)
	local num = getNumOfChildren(node)
	for i = 0, num - 1 do
		local child = getChildAt(node, i)
		result = string.format("%s %s_%d -> %s_%d\n", result, string.gsub(getName(node), "[%(%)]", "_"), node, string.gsub(getName(child), "[%(%)]", "_"), child)
		result = exportScenegraphToGraphvizRec(getChildAt(node, i), result)
	end
	return result
end
