
-- Local values: x, y, z
function translate(name, dx, dy, dz)
	local v5_, v6_, v7_ = getTranslation(name)
	setTranslation(name, v5_ + dx, v6_ + dy, v7_ + dz)
end

-- Local values: x, y, z
function rotate(name, dx, dy, dz)
	local v12_, v13_, v14_ = getRotation(name)
	setRotation(name, (v12_ + dx) % 6.283185307179586, (v13_ + dy) % 6.283185307179586, (v14_ + dz) % 6.283185307179586)
end

-- Local values: state
function toggleVisibility(name)
	local v16_ = getVisibility(name)
	setVisibility(name, not v16_)
end

function printScenegraph(node, visibleOnly)
	printScenegraphRec(node, 0, visibleOnly)
end

-- Local values: ident, i, num, i
function printScenegraphRec(node, level, visibleOnly)
	local v22_ = ""
	for _ = 1, level do
		v22_ = v22_ .. "    "
	end
	if visibleOnly == nil or (not visibleOnly or visibleOnly and getVisibility(node)) then
		local v23_ = print
		local v24_ = string.format
		local v25_ = getName(node)
		local v26_ = getVisibility
		v23_(v24_("%s%s(%d) | %s", v22_, v25_, node, (tostring(v26_(node)))))
		for v27_ = 0, getNumOfChildren(node) - 1 do
			printScenegraphRec(getChildAt(node, v27_), level + 1)
		end
	end
end

-- Local values: className, classNameToCheck, classId
function getNodeClassNamesString(node)
	local v29_ = nil
	for v30_, v31_ in pairs(ClassIds) do
		if getHasClassId(node, v31_) then
			if v29_ == nil then
				v29_ = v30_
			else
				v29_ = v29_ .. " + " .. v30_
			end
		end
	end
	return v29_
end

-- Local values: classNames, transX, transY, transZ, worldTransX, worldTransY, worldTransZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, visibility, effectiveVisibility
function printNodeInfo(node)
	if node == nil or (node == 0 or not entityExists(node)) then
		print("printNodeInfo: invalid node")
		return
	else
		local v33_ = getNodeClassNamesString(node)
		if v33_ == nil then
			print("printNodeInfo: invalid node")
		else
			local v34_, v35_, v36_ = getTranslation(node)
			local v37_, v38_, v39_ = getWorldTranslation(node)
			local v40_, v41_, v42_ = getRotation(node)
			local v43_ = math.deg(v40_)
			local v44_ = math.deg(v41_)
			local v45_ = math.deg(v42_)
			local v46_, v47_, v48_ = getScale(node)
			local v49_ = getVisibility(node)
			local v50_ = getEffectiveVisibility(node)
			print(string.format("Node info for \'%s\' (%d):", getName(node), node))
			print(string.format("  Type(s):             %s", v33_))
			print(string.format("  Path:                %s", getNodeFullPath(node)))
			if getParent(node) == getRootNode() then
				print(string.format("  Translation (world): %.4f %.4f %.4f", v37_, v38_, v39_))
			else
				print(string.format("  Translation:         %.4f %.4f %.4f", v34_, v35_, v36_))
				print(string.format("  Translation (world): %.4f %.4f %.4f", v37_, v38_, v39_))
			end
			print(string.format("  Rotation (deg):      %.4f %.4f %.4f", v43_, v44_, v45_))
			print(string.format("  Scale:               %.4f %.4f %.4f", v46_, v47_, v48_))
			print(string.format("  Visibility:          %s%s", tostring(v49_), v49_ and not v50_ and " (overall: false)" or ""))
		end
	end
end

-- Local values: classNames, transX, transY, transZ, worldTransX, worldTransY, worldTransZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, visibility, effectiveVisibility, path, info
function printNodeInfoShort(node)
	if node == nil or (node == 0 or not entityExists(node)) then
		print("NODEINFO|invalid")
		return
	else
		local v52_ = getNodeClassNamesString(node)
		if v52_ == nil then
			print("NODEINFO|invalid")
		else
			local v53_, v54_, v55_ = getTranslation(node)
			local v56_, v57_, v58_ = getWorldTranslation(node)
			local v59_, v60_, v61_ = getRotation(node)
			local v62_ = math.deg(v59_)
			local v63_ = math.deg(v60_)
			local v64_ = math.deg(v61_)
			local v65_, v66_, v67_ = getScale(node)
			local v68_ = getVisibility(node)
			local v69_ = getEffectiveVisibility(node)
			local v70_ = string.gsub(getNodeFullPath(node), "|", ",")
			local v71_ = ((((("NODEINFO" .. string.format("|id=%d", node)) .. string.format("|name=%s", getName(node))) .. string.format("|type=%s", v52_)) .. string.format("|path=%s", v70_)) .. string.format("|translation=%.4f,%.4f,%.4f", v53_, v54_, v55_)) .. string.format("|worldTranslation=%.4f,%.4f,%.4f", v56_, v57_, v58_)
			local v72_ = string.format
			local v73_ = getParent(node) == getRootNode()
			local v74_ = ((((v71_ .. v72_("|parentToWorld=%s", (tostring(v73_)))) .. string.format("|rotation=%.4f,%.4f,%.4f", v62_, v63_, v64_)) .. string.format("|scale=%.4f,%.4f,%.4f", v65_, v66_, v67_)) .. string.format("|visibility=%s", (tostring(v68_)))) .. string.format("|effectiveVisibility=%s", (tostring(v69_)))
			print(v74_)
		end
	end
end

function printFullPath(node, str)
	local v77_ = string.format("|%s%s", getName(node), getVisibility(node) and "" or "(hidden)") .. (str or "")
	if getParent(node) == 0 then
		print(v77_)
	else
		printFullPath(getParent(node), v77_)
	end
end

-- Local values: parent
function getNodeFullPath(node, str)
	local v80_ = "|" .. getName(node) .. (str or "")
	local v81_ = getParent(node)
	if v81_ == 0 then
		return v80_
	else
		return getNodeFullPath(v81_, v80_)
	end
end

-- Local values: fileId, result
function exportScenegraphToGraphviz(node, filename)
	if node ~= nil and node ~= 0 then
		if filename == nil then
			filename = string.format("%s_output.gv", getName(node))
		end
		local v84_ = createFile(filename, FileAccess.WRITE)
		local v85_ = string.format("%s// Start Node is \'%s_(%d)\'\n", "// Scenegraph export for Graphviz\n", getName(node), node)
		local v86_ = string.format("%sdigraph G {\n", v85_)
		local v87_ = string.format("%s%s_%d  [shape=box,color=red,style=filled]\n", v86_, getName(node), node)
		local v88_ = exportScenegraphToGraphvizRec(node, v87_)
		local v89_ = string.format("%s\n}", v88_)
		fileWrite(v84_, v89_)
		delete(v84_)
	end
end

-- Local values: num, i, child
function exportScenegraphToGraphvizRec(node, result)
	for v92_ = 0, getNumOfChildren(node) - 1 do
		local v93_ = getChildAt(node, v92_)
		local v94_ = string.format("%s %s_%d -> %s_%d\n", result, string.gsub(getName(node), "[%(%)]", "_"), node, string.gsub(getName(v93_), "[%(%)]", "_"), v93_)
		result = exportScenegraphToGraphvizRec(getChildAt(node, v92_), v94_)
	end
	return result
end
