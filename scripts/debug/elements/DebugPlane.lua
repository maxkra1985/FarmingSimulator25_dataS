-- Local values: DebugPlane_mt
DebugPlane = {}
local DebugPlane_mt = Class(DebugPlane, DebugElement)
DebugPlane.STATIC_CALL_POSITIONS_TABLE = {
	{ -1, 0, -1 },
	{ 1, 0, -1 },
	{ 1, 0, 1 },
	{ -1, 0, 1 }
}

-- Upvalues: DebugPlane_mt
-- Local values: self
function DebugPlane.new(customMt)
	-- upvalues: (copy) DebugPlane_mt
	local v3_ = DebugPlane:superClass().new(customMt or DebugPlane_mt)
	v3_.alignToTerrain = false
	v3_.filled = false
	v3_.doubleSided = true
	v3_.solid = false
	v3_.cornerPositions = {
		{ -1, 0, -1 },
		{ 1, 0, -1 },
		{ 1, 0, 1 },
		{ -1, 0, 1 }
	}
	return v3_
end

-- Local values: self
function DebugPlane.newSimple(filled, doubleSided, color, alignToTerrain)
	local v8_ = DebugPlane.new()
	if color ~= nil then
		v8_:setColor(color)
	end
	v8_.filled = Utils.getNoNil(filled, v8_.filled)
	v8_.alignToTerrain = Utils.getNoNil(alignToTerrain, v8_.alignToTerrain)
	v8_.doubleSided = Utils.getNoNil(doubleSided, v8_.doubleSided)
	return v8_
end

-- Local values: dirX, dirY, dirZ, normX, normY, normZ, offsetX, offsetY, offsetZ
function DebugPlane.calculateCornerPositions(positions, startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
	local v19_ = widthX - startX
	local v20_ = widthY - startY
	local v21_ = widthZ - startZ
	local v22_ = heightX - startX
	local v23_ = heightY - startY
	local v24_ = heightZ - startZ
	local v25_ = v19_ + v22_
	local v26_ = v20_ + v23_
	local v27_ = v21_ + v24_
	local v28_ = positions[1]
	local v29_ = positions[1]
	local v30_ = positions[1]
	v28_[1] = startX
	v29_[2] = startY
	v30_[3] = startZ
	local v31_ = positions[2]
	local v32_ = positions[2]
	local v33_ = positions[2]
	v31_[1] = widthX
	v32_[2] = widthY
	v33_[3] = widthZ
	local v34_ = positions[3]
	local v35_ = positions[3]
	local v36_ = positions[3]
	local v37_ = startX + v25_
	local v38_ = startY + v26_
	local v39_ = startZ + v27_
	v34_[1] = v37_
	v35_[2] = v38_
	v36_[3] = v39_
	local v40_ = positions[4]
	local v41_ = positions[4]
	local v42_ = positions[4]
	v40_[1] = heightX
	v41_[2] = heightY
	v42_[3] = heightZ
	return positions
end

function DebugPlane:draw()
	DebugPlane.renderWithPositions(nil, nil, nil, nil, nil, nil, nil, nil, nil, self.color, self.alignToTerrain, self.filled, self.doubleSided, self.solid, self.text, self.cornerPositions)
end

-- Local values: startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ
function DebugPlane.renderWithNodes(startNode, widthNode, heightNode, color, alignToTerrain, filled, doubleSided, solid, text)
	local v53_, v54_, v55_ = getWorldTranslation(startNode)
	local v56_, v57_, v58_ = getWorldTranslation(widthNode)
	local v59_, v60_, v61_ = getWorldTranslation(heightNode)
	DebugPlane.renderWithPositions(v53_, v54_, v55_, v56_, v57_, v58_, v59_, v60_, v61_, color, alignToTerrain, filled, doubleSided, solid, text)
end

-- Local values: x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, r, g, b, a, x, y, z
function DebugPlane.renderWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ, color, alignToTerrain, filled, doubleSided, solid, text, positions)
	local v78_ = positions or DebugPlane.calculateCornerPositions(DebugPlane.STATIC_CALL_POSITIONS_TABLE, startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
	local v79_ = v78_[1][1]
	local v80_ = v78_[1][2]
	local v81_ = v78_[1][3]
	local v82_ = v78_[2][1]
	local v83_ = v78_[2][2]
	local v84_ = v78_[2][3]
	local v85_ = v78_[3][1]
	local v86_ = v78_[3][2]
	local v87_ = v78_[3][3]
	local v88_ = v78_[4][1]
	local v89_ = v78_[4][2]
	local v90_ = v78_[4][3]
	local v91_, v92_, v93_, v94_ = (color or Color.PRESETS.WHITE):unpack()
	local v95_ = Utils.getNoNil(alignToTerrain, true)
	local v96_ = Utils.getNoNil(filled, false)
	local v97_ = Utils.getNoNil(doubleSided, false)
	local v98_ = Utils.getNoNil(solid, false)
	if v95_ and g_terrainNode then
		v80_ = getTerrainHeightAtWorldPos(g_terrainNode, v79_, 0, v81_) + 0.01
		v83_ = getTerrainHeightAtWorldPos(g_terrainNode, v82_, 0, v84_) + 0.01
		v86_ = getTerrainHeightAtWorldPos(g_terrainNode, v85_, 0, v87_) + 0.01
		v89_ = getTerrainHeightAtWorldPos(g_terrainNode, v88_, 0, v90_) + 0.01
	end
	if v96_ then
		drawDebugTriangle(v79_, v80_, v81_, v82_, v83_, v84_, v85_, v86_, v87_, v91_, v92_, v93_, v94_, v98_)
		drawDebugTriangle(v79_, v80_, v81_, v85_, v86_, v87_, v88_, v89_, v90_, v91_, v92_, v93_, v94_, v98_)
		if v97_ then
			drawDebugTriangle(v85_, v86_, v87_, v82_, v83_, v84_, v79_, v80_, v81_, v91_, v92_, v93_, v94_, v98_)
			drawDebugTriangle(v88_, v89_, v90_, v85_, v86_, v87_, v79_, v80_, v81_, v91_, v92_, v93_, v94_, v98_)
		end
	else
		drawDebugLine(v79_, v80_, v81_, v91_, v92_, v93_, v82_, v83_, v84_, v91_, v92_, v93_, v98_)
		drawDebugLine(v82_, v83_, v84_, v91_, v92_, v93_, v85_, v86_, v87_, v91_, v92_, v93_, v98_)
		drawDebugLine(v85_, v86_, v87_, v91_, v92_, v93_, v88_, v89_, v90_, v91_, v92_, v93_, v98_)
		drawDebugLine(v88_, v89_, v90_, v91_, v92_, v93_, v79_, v80_, v81_, v91_, v92_, v93_, v98_)
	end
	if text ~= nil then
		local v99_ = (v79_ + v82_ + v85_ + v88_) / 4
		local v100_ = (v80_ + v83_ + v86_ + v89_) / 4
		local v101_ = (v81_ + v84_ + v87_ + v90_) / 4
		Utils.renderTextAtWorldPosition(v99_, v100_, v101_, text, 0.02, 0, v91_, v92_, v93_, v94_)
	end
end

-- Local values: startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ
function DebugPlane:createWithNodes(startNode, widthNode, heightNode)
	local v106_, v107_, v108_ = getWorldTranslation(startNode)
	local v109_, v110_, v111_ = getWorldTranslation(widthNode)
	local v112_, v113_, v114_ = getWorldTranslation(heightNode)
	self:createWithPositions(v106_, v107_, v108_, v109_, v110_, v111_, v112_, v113_, v114_)
	return self
end

-- Local values: dirX, dirY, dirZ, normX, normY, normZ, offsetX, offsetY, offsetZ, pos
function DebugPlane:createWithPositions(startX, startY, startZ, widthX, widthY, widthZ, heightX, heightY, heightZ)
	local v125_ = widthX - startX
	local v126_ = widthY - startY
	local v127_ = widthZ - startZ
	local v128_ = heightX - startX
	local v129_ = heightY - startY
	local v130_ = heightZ - startZ
	local v131_ = v125_ + v128_
	local v132_ = v126_ + v129_
	local v133_ = v127_ + v130_
	local v134_ = self.cornerPositions
	local v135_ = v134_[1]
	local v136_ = v134_[1]
	local v137_ = v134_[1]
	v135_[1] = startX
	v136_[2] = startY
	v137_[3] = startZ
	local v138_ = v134_[2]
	local v139_ = v134_[2]
	local v140_ = v134_[2]
	v138_[1] = widthX
	v139_[2] = widthY
	v140_[3] = widthZ
	local v141_ = v134_[3]
	local v142_ = v134_[3]
	local v143_ = v134_[3]
	local v144_ = startX + v131_
	local v145_ = startY + v132_
	local v146_ = startZ + v133_
	v141_[1] = v144_
	v142_[2] = v145_
	v143_[3] = v146_
	local v147_ = v134_[4]
	local v148_ = v134_[4]
	local v149_ = v134_[4]
	v147_[1] = heightX
	v148_[2] = heightY
	v149_[3] = heightZ
	return self
end

-- Local values: offsetX, offsetY, offsetZ, pos
function DebugPlane:createWithPositionsOffset(startX, startY, startZ, widthXOffset, widthYOffset, widthZOffset, heightXOffset, heightYOffset, heightZOffset)
	local v160_ = widthXOffset + heightXOffset
	local v161_ = widthYOffset + heightYOffset
	local v162_ = widthZOffset + heightZOffset
	local v163_ = self.cornerPositions
	local v164_ = v163_[1]
	local v165_ = v163_[1]
	local v166_ = v163_[1]
	v164_[1] = startX
	v165_[2] = startY
	v166_[3] = startZ
	local v167_ = v163_[2]
	local v168_ = v163_[2]
	local v169_ = v163_[2]
	local v170_ = startX + widthXOffset
	local v171_ = startY + widthYOffset
	local v172_ = startZ + widthZOffset
	v167_[1] = v170_
	v168_[2] = v171_
	v169_[3] = v172_
	local v173_ = v163_[3]
	local v174_ = v163_[3]
	local v175_ = v163_[3]
	local v176_ = startX + v160_
	local v177_ = startY + v161_
	local v178_ = startZ + v162_
	v173_[1] = v176_
	v174_[2] = v177_
	v175_[3] = v178_
	local v179_ = v163_[4]
	local v180_ = v163_[4]
	local v181_ = v163_[4]
	local v182_ = startX + heightXOffset
	local v183_ = startY + heightYOffset
	local v184_ = startZ + heightZOffset
	v179_[1] = v182_
	v180_[2] = v183_
	v181_[3] = v184_
	return self
end

-- Local values: offsetX, offsetY, offsetZ, x, y, z, sizeX, sizeZ, dirX, _, dirZ
function DebugPlane:createWithStartEnd(startNode, endNode)
	local v188_, v189_, v190_ = localToLocal(endNode, startNode, 0, 0, 0)
	local v191_, v192_, v193_ = localToWorld(startNode, v188_ * 0.5, v189_ * 0.5, v190_ * 0.5)
	local v194_ = math.abs(v188_)
	local v195_ = math.abs(v190_)
	local v196_, _, v197_ = localDirectionToWorld(startNode, 0, 0, 1)
	self:createFromPosAndDir(v191_, v192_, v193_, v196_, 0, v197_, 0, 1, 0, v194_, v195_)
	return self
end

function DebugPlane:createSimple(x, y, z, size)
	self:createFromPosAndDir(x, y, z, 0, 0, 1, 0, 1, 0, size, size)
	return self
end

-- Local values: dirX, dirY, dirZ, upX, upY, upZ, x, y, z
function DebugPlane:createWithSizeAndOffset(node, width, length, widthOffset, lengthOffset)
	local v209_, v210_, v211_ = localDirectionToWorld(node, 0, 0, 1)
	local v212_, v213_, v214_ = localDirectionToWorld(node, 0, 1, 0)
	local v215_, v216_, v217_ = getWorldTranslation(node)
	local v218_, v219_, v220_ = MathUtil.transform(v215_, v216_, v217_, v209_, v210_, v211_, v212_, v213_, v214_, widthOffset, 0, lengthOffset)
	self:createFromPosAndDir(v218_, v219_, v220_, v209_, v210_, v211_, v212_, v213_, v214_, width, length)
	return self
end

-- Local values: halfWidth, halfLength, pos
function DebugPlane:createFromPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, width, length)
	local v233_ = width * 0.5
	local v234_ = length * 0.5
	local v235_ = self.cornerPositions
	v235_[1] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -v233_, 0, -v234_) }
	v235_[2] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -v233_, 0, v234_) }
	v235_[3] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, v233_, 0, v234_) }
	v235_[4] = { MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, v233_, 0, -v234_) }
	return self
end

-- Local values: sizeXHalf, sizeZHalf, pos
function DebugPlane:createWithNode(node, sizeX, sizeZ)
	local v240_ = sizeX * 0.5
	local v241_ = sizeZ * 0.5
	local v242_ = self.cornerPositions
	v242_[1] = { localToWorld(node, -v240_, 0, -v241_) }
	v242_[2] = { localToWorld(node, -v240_, 0, v241_) }
	v242_[3] = { localToWorld(node, v240_, 0, v241_) }
	v242_[4] = { localToWorld(node, v240_, 0, -v241_) }
	return self
end

function DebugPlane:setIsFilled(isFilled)
	self.filled = isFilled
	return self
end
