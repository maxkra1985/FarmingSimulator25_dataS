-- Local values: DebugBox_mt
DebugBox = {}
local DebugBox_mt = Class(DebugBox, DebugElement)
DebugBox.STATIC_CALL_POSITIONS_TABLE = {
	{ -1, -1, -1 },
	{ 1, -1, -1 },
	{ 1, -1, 1 },
	{ -1, -1, 1 },
	{ -1, 1, -1 },
	{ 1, 1, -1 },
	{ 1, 1, 1 },
	{ -1, 1, 1 }
}

-- Upvalues: DebugBox_mt
-- Local values: self
function DebugBox.new(customMt)
	-- upvalues: (copy) DebugBox_mt
	local v3_ = DebugBox:superClass().new(customMt or DebugBox_mt)
	v3_.upX = 0
	v3_.upY = 1
	v3_.upZ = 0
	v3_.dirX = 0
	v3_.dirY = 0
	v3_.dirZ = 1
	v3_.sizeX = 1
	v3_.sizeY = 1
	v3_.sizeZ = 1
	v3_.solid = true
	v3_.text = nil
	v3_.drawFaces = false
	v3_.cornerPositions = {
		{ -1, -1, -1 },
		{ 1, -1, -1 },
		{ 1, -1, 1 },
		{ -1, -1, 1 },
		{ -1, 1, -1 },
		{ 1, 1, -1 },
		{ 1, 1, 1 },
		{ -1, 1, 1 }
	}
	return v3_
end

function DebugBox:delete() end

function DebugBox:update(dt) end

function DebugBox:draw()
	DebugBox.renderAtPosition(self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ, self.color, self.solid, self.text, self.textSize, self.drawFaces, self.cornerPositions)
end

-- Local values: r, g, b, a, pos, normX, normY, normZ
function DebugBox.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces, positions)
	local v23_, v24_, v25_, v26_
	if color == nil then
		v23_ = 1
		v24_ = 1
		v25_ = 1
		v26_ = 1
	else
		v23_, v25_, v26_, v24_ = color:unpack()
	end
	local v27_ = positions or DebugBox.calculateCornerPositions(DebugBox.STATIC_CALL_POSITIONS_TABLE, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ)
	drawDebugLine(v27_[1][1], v27_[1][2], v27_[1][3], v23_, v25_, v26_, v27_[2][1], v27_[2][2], v27_[2][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[2][1], v27_[2][2], v27_[2][3], v23_, v25_, v26_, v27_[3][1], v27_[3][2], v27_[3][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[3][1], v27_[3][2], v27_[3][3], v23_, v25_, v26_, v27_[4][1], v27_[4][2], v27_[4][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[4][1], v27_[4][2], v27_[4][3], v23_, v25_, v26_, v27_[1][1], v27_[1][2], v27_[1][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[5][1], v27_[5][2], v27_[5][3], v23_, v25_, v26_, v27_[6][1], v27_[6][2], v27_[6][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[6][1], v27_[6][2], v27_[6][3], v23_, v25_, v26_, v27_[7][1], v27_[7][2], v27_[7][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[7][1], v27_[7][2], v27_[7][3], v23_, v25_, v26_, v27_[8][1], v27_[8][2], v27_[8][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[8][1], v27_[8][2], v27_[8][3], v23_, v25_, v26_, v27_[5][1], v27_[5][2], v27_[5][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[1][1], v27_[1][2], v27_[1][3], v23_, v25_, v26_, v27_[5][1], v27_[5][2], v27_[5][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[2][1], v27_[2][2], v27_[2][3], v23_, v25_, v26_, v27_[6][1], v27_[6][2], v27_[6][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[3][1], v27_[3][2], v27_[3][3], v23_, v25_, v26_, v27_[7][1], v27_[7][2], v27_[7][3], v23_, v25_, v26_, solid)
	drawDebugLine(v27_[4][1], v27_[4][2], v27_[4][3], v23_, v25_, v26_, v27_[8][1], v27_[8][2], v27_[8][3], v23_, v25_, v26_, solid)
	if drawFaces then
		drawDebugTriangle(v27_[1][1], v27_[1][2], v27_[1][3], v27_[2][1], v27_[2][2], v27_[2][3], v27_[3][1], v27_[3][2], v27_[3][3], v23_, v25_, v26_, 0.1, solid)
		drawDebugTriangle(v27_[1][1], v27_[1][2], v27_[1][3], v27_[3][1], v27_[3][2], v27_[3][3], v27_[4][1], v27_[4][2], v27_[4][3], v23_, v25_, v26_, 0.1, solid)
		drawDebugTriangle(v27_[7][1], v27_[7][2], v27_[7][3], v27_[6][1], v27_[6][2], v27_[6][3], v27_[5][1], v27_[5][2], v27_[5][3], v23_, v25_, v26_, 0.2, solid)
		drawDebugTriangle(v27_[7][1], v27_[7][2], v27_[7][3], v27_[5][1], v27_[5][2], v27_[5][3], v27_[8][1], v27_[8][2], v27_[8][3], v23_, v25_, v26_, 0.2, solid)
		drawDebugTriangle(v27_[1][1], v27_[1][2], v27_[1][3], v27_[5][1], v27_[5][2], v27_[5][3], v27_[2][1], v27_[2][2], v27_[2][3], v23_, v25_, v26_, 0.3, solid)
		drawDebugTriangle(v27_[2][1], v27_[2][2], v27_[2][3], v27_[5][1], v27_[5][2], v27_[5][3], v27_[6][1], v27_[6][2], v27_[6][3], v23_, v25_, v26_, 0.3, solid)
		drawDebugTriangle(v27_[3][1], v27_[3][2], v27_[3][3], v27_[8][1], v27_[8][2], v27_[8][3], v27_[4][1], v27_[4][2], v27_[4][3], v23_, v25_, v26_, 0.4, solid)
		drawDebugTriangle(v27_[3][1], v27_[3][2], v27_[3][3], v27_[7][1], v27_[7][2], v27_[7][3], v27_[8][1], v27_[8][2], v27_[8][3], v23_, v25_, v26_, 0.4, solid)
		drawDebugTriangle(v27_[1][1], v27_[1][2], v27_[1][3], v27_[4][1], v27_[4][2], v27_[4][3], v27_[8][1], v27_[8][2], v27_[8][3], v23_, v25_, v26_, 0.5, solid)
		drawDebugTriangle(v27_[1][1], v27_[1][2], v27_[1][3], v27_[8][1], v27_[8][2], v27_[8][3], v27_[5][1], v27_[5][2], v27_[5][3], v23_, v25_, v26_, 0.5, solid)
		drawDebugTriangle(v27_[2][1], v27_[2][2], v27_[2][3], v27_[6][1], v27_[6][2], v27_[6][3], v27_[7][1], v27_[7][2], v27_[7][3], v23_, v25_, v26_, 0.6, solid)
		drawDebugTriangle(v27_[2][1], v27_[2][2], v27_[2][3], v27_[7][1], v27_[7][2], v27_[7][3], v27_[3][1], v27_[3][2], v27_[3][3], v23_, v25_, v26_, 0.6, solid)
	end
	local v28_, v29_, v30_ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	drawDebugLine(x, y, z, 1, 0, 0, x + v28_, y + v29_, z + v30_, 1, 0, 0, solid)
	drawDebugLine(x, y, z, 0, 1, 0, x + upX, y + upY, z + upZ, 0, 1, 0, solid)
	drawDebugLine(x, y, z, 0, 0, 1, x + dirX, y + dirY, z + dirZ, 0, 0, 1, solid)
	if text ~= nil then
		Utils.renderTextAtWorldPosition(x + 0.5 * upX, y + 0.5 * upY, z + 0.5 * upZ, text, textSize or 0.016, nil, v23_, v25_, v26_, v24_)
	end
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugBox.renderAtNode(node, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
	local v40_, v41_, v42_ = getWorldTranslation(node)
	local v43_, v44_, v45_ = localDirectionToWorld(node, 0, 1, 0)
	local v46_, v47_, v48_ = localDirectionToWorld(node, 0, 0, 1)
	DebugBox.renderAtPosition(v40_, v41_, v42_, v43_, v44_, v45_, v46_, v47_, v48_, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugBox.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
	local v61_, v62_, v63_ = localToWorld(node, offsetX, offsetY, offsetZ)
	local v64_, v65_, v66_ = localDirectionToWorld(node, 0, 1, 0)
	local v67_, v68_, v69_ = localDirectionToWorld(node, 0, 0, 1)
	DebugBox.renderAtPosition(v61_, v62_, v63_, v64_, v65_, v66_, v67_, v68_, v69_, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end

-- Local values: offsetX, offsetY, offsetZ, x, y, z, sizeX, sizeY, sizeZ, dirX, dirY, dirZ, upX, upY, upZ
function DebugBox.renderWithStartAndEndNode(nodeStart, nodeEnd, color, solid, text, textSize, drawFaces)
	local v77_, v78_, v79_ = localToLocal(nodeEnd, nodeStart, 0, 0, 0)
	local v80_, v81_, v82_ = localToWorld(nodeStart, v77_ * 0.5, v78_ * 0.5, v79_ * 0.5)
	local v83_ = math.abs(v77_)
	local v84_ = math.abs(v78_)
	local v85_ = math.abs(v79_)
	local v86_, v87_, v88_ = localDirectionToWorld(nodeStart, 0, 0, 1)
	local v89_, v90_, v91_ = localDirectionToWorld(nodeStart, 0, 1, 0)
	DebugBox.renderAtPosition(v80_, v81_, v82_, v89_, v90_, v91_, v86_, v87_, v88_, v83_ / 2, v84_ / 2, v85_ / 2, color, solid, text, textSize, drawFaces)
end

-- Local values: normX, normY, normZ
function DebugBox.calculateCornerPositions(positions, x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ)
	local v105_, v106_, v107_ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	local v108_ = (sizeX or 1) / 2
	local v109_ = (sizeY or 1) / 2
	local v110_ = (sizeZ or 1) / 2
	if v108_ ~= nil then
		upX = upX * v109_
		upY = upY * v109_
		upZ = upZ * v109_
		dirX = dirX * v110_
		dirY = dirY * v110_
		dirZ = dirZ * v110_
		v105_ = v105_ * v108_
		v106_ = v106_ * v108_
		v107_ = v107_ * v108_
	end
	positions[1][1] = x - v105_ - upX - dirX
	positions[1][2] = y - v106_ - upY - dirY
	positions[1][3] = z - v107_ - upZ - dirZ
	positions[2][1] = x + v105_ - upX - dirX
	positions[2][2] = y + v106_ - upY - dirY
	positions[2][3] = z + v107_ - upZ - dirZ
	positions[3][1] = x + v105_ - upX + dirX
	positions[3][2] = y + v106_ - upY + dirY
	positions[3][3] = z + v107_ - upZ + dirZ
	positions[4][1] = x - v105_ - upX + dirX
	positions[4][2] = y - v106_ - upY + dirY
	positions[4][3] = z - v107_ - upZ + dirZ
	positions[5][1] = x - v105_ + upX - dirX
	positions[5][2] = y - v106_ + upY - dirY
	positions[5][3] = z - v107_ + upZ - dirZ
	positions[6][1] = x + v105_ + upX - dirX
	positions[6][2] = y + v106_ + upY - dirY
	positions[6][3] = z + v107_ + upZ - dirZ
	positions[7][1] = x + v105_ + upX + dirX
	positions[7][2] = y + v106_ + upY + dirY
	positions[7][3] = z + v107_ + upZ + dirZ
	positions[8][1] = x - v105_ + upX + dirX
	positions[8][2] = y - v106_ + upY + dirY
	positions[8][3] = z - v107_ + upZ + dirZ
	return positions
end

function DebugBox:createWithWorldPos(x, y, z, size)
	self:createWithWorldPosAndRot(x, y, z, 0, 0, 0, size, size, size)
	return self
end

-- Local values: offsetX, offsetY, offsetZ, x, y, z, sizeX, sizeY, sizeZ, dirX, _, dirZ, rotY
function DebugBox:createWithStartEnd(startNode, endNode)
	local v119_, v120_, v121_ = localToLocal(endNode, startNode, 0, 0, 0)
	local v122_, v123_, v124_ = localToWorld(startNode, v119_ * 0.5, v120_ * 0.5, v121_ * 0.5)
	local v125_ = math.abs(v119_)
	local v126_ = math.abs(v120_)
	local v127_ = math.abs(v121_)
	local v128_, _, v129_ = localDirectionToWorld(startNode, 0, 0, 1)
	self:createWithWorldPosAndRot(v122_, v123_, v124_, 0, MathUtil.getYRotationFromDirection(v128_, v129_), 0, v125_ * 0.5, v126_ * 0.5, v127_ * 0.5)
	return self
end

-- Local values: x, y, z
function DebugBox:createWithNode(node, sizeX, sizeY, sizeZ, offsetX, offsetY, offsetZ)
	local v138_, v139_, v140_ = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
	self.x = v138_
	self.y = v139_
	self.z = v140_
	local v141_ = sizeX or self.sizeX
	local v142_ = sizeY or self.sizeY
	local v143_ = sizeZ or self.sizeZ
	self.sizeX = v141_
	self.sizeY = v142_
	self.sizeZ = v143_
	local v144_, v145_, v146_ = localDirectionToWorld(node, 0, 1, 0)
	self.upX = v144_
	self.upY = v145_
	self.upZ = v146_
	local v147_, v148_, v149_ = localDirectionToWorld(node, 0, 0, 1)
	self.dirX = v147_
	self.dirY = v148_
	self.dirZ = v149_
	DebugBox.calculateCornerPositions(self.cornerPositions, v138_, v139_, v140_, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ)
	return self
end

function DebugBox:createWithPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, sizeX, sizeY, sizeZ)
	self.x = x
	self.y = y
	self.z = z
	local v163_, v164_, v165_ = MathUtil.vector3Normalize(dirX, dirY, dirZ)
	self.dirX = v163_
	self.dirY = v164_
	self.dirZ = v165_
	local v166_, v167_, v168_ = MathUtil.vector3Normalize(upX, upY, upZ)
	self.upX = v166_
	self.upY = v167_
	self.upZ = v168_
	local v169_ = sizeX or self.sizeX
	local v170_ = sizeY or self.sizeY
	local v171_ = sizeZ or self.sizeZ
	self.sizeX = v169_
	self.sizeY = v170_
	self.sizeZ = v171_
	DebugBox.calculateCornerPositions(self.cornerPositions, x, y, z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ)
	return self
end

-- Local values: temp
function DebugBox:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, sizeX, sizeY, sizeZ)
	local v182_ = createTransformGroup("temp_drawDebugBoxAtWorldPos")
	link(getRootNode(), v182_)
	setTranslation(v182_, x, y, z)
	setRotation(v182_, rotX, rotY, rotZ)
	self:createWithNode(v182_, sizeX, sizeY, sizeZ)
	delete(v182_)
	return self
end

-- Local values: temp
function DebugBox:createFromOverlapBoxParameters(x, y, z, rotX, rotY, rotZ, extentX, extentY, extentZ)
	local v193_ = createTransformGroup("temp_drawDebugBoxAtWorldPos")
	link(getRootNode(), v193_)
	setTranslation(v193_, x, y, z)
	setRotation(v193_, rotX, rotY, rotZ)
	self:createWithNode(v193_, extentX * 2, extentY * 2, extentZ * 2)
	delete(v193_)
	return self
end

function DebugBox:setSize(sizeX, sizeY, sizeZ)
	self.sizeX = sizeX or self.sizeX
	self.sizeY = sizeY or self.sizeY
	self.sizeZ = sizeZ or self.sizeZ
	DebugBox.calculateCornerPositions(self.cornerPositions, self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ)
	return self
end

function DebugBox:setDrawFaces(drawFaces)
	self.drawFaces = drawFaces
	return self
end
