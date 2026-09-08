-- Local values: DebugCamera_mt
DebugCamera = {}
local DebugCamera_mt = Class(DebugCamera, DebugElement)

-- Upvalues: DebugCamera_mt
-- Local values: self
function DebugCamera.new(customMt)
	-- upvalues: (copy) DebugCamera_mt
	local v3_ = DebugCamera:superClass().new(customMt or DebugCamera_mt)
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
	return v3_
end

function DebugCamera:draw()
	DebugCamera.renderAtPosition(self.x, self.y, self.z, self.upX, self.upY, self.upZ, self.dirX, self.dirY, self.dirZ, self.sizeX, self.sizeY, self.sizeZ, self.color, self.solid, self.text, self.textSize, self.drawFaces)
end

-- Local values: sx, sy, sz, bodyShift, bodyCenterX, bodyCenterY, bodyCenterZ, lensOffset, lensX, lensY, lensZ, reelRadius, reelHeight, reelStackOffset, reelAlongDir, stackX, stackY, stackZ, frontReelX, frontReelY, frontReelZ, backReelX, backReelY, backReelZ
function DebugCamera.renderAtPosition(x, y, z, upX, upY, upZ, dirX, dirY, dirZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
	local v22_ = (sizeX == nil or not sizeX) and 1 or sizeX
	local v23_ = (sizeY == nil or not sizeY) and 1 or sizeY
	local v24_ = (sizeZ == nil or not sizeZ) and 1 or sizeZ
	local v25_ = -v23_ * 0.5
	local v26_ = x + dirX * v25_
	local v27_ = y + dirY * v25_
	local v28_ = z + dirZ * v25_
	DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0)
	DebugBox.renderAtPosition(v26_, v27_, v28_, upX, upY, upZ, dirX, dirY, dirZ, v22_, v23_, v24_, color, solid, text, textSize, drawFaces)
	local v29_ = v24_ * 0.5
	local v30_ = x + dirX * v29_
	local v31_ = y + dirY * v29_
	local v32_ = z + dirZ * v29_
	DebugPyramid.renderAtPosition(v30_, v31_, v32_, -dirX, -dirY, -dirZ, upX, upY, upZ, v22_, v23_, v24_, color, solid, text, textSize, drawFaces)
	local v33_ = v23_ * 0.3
	local v34_ = v22_ * 0.4
	local v35_ = v23_ * 0.5 + v33_
	local v36_ = v24_ * 0.25
	local v37_ = upX * v35_
	local v38_ = upY * v35_
	local v39_ = upZ * v35_
	local v40_ = v26_ + v37_ + dirX * v36_
	local v41_ = v27_ + v38_ + dirY * v36_
	local v42_ = v28_ + v39_ + dirZ * v36_
	local v43_ = v26_ + v37_ - dirX * v36_
	local v44_ = v27_ + v38_ - dirY * v36_
	local v45_ = v28_ + v39_ - dirZ * v36_
	DebugCylinder.renderAtPosition(v40_, v41_, v42_, v33_, v34_, Axis.X, color)
	DebugCylinder.renderAtPosition(v43_, v44_, v45_, v33_, v34_, Axis.X, color)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugCamera.renderAtNode(node, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
	local v55_, v56_, v57_ = getWorldTranslation(node)
	local v58_, v59_, v60_ = localDirectionToWorld(node, 0, 1, 0)
	local v61_, v62_, v63_ = localDirectionToWorld(node, 0, 0, 1)
	DebugCamera.renderAtPosition(v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugCamera.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
	local v76_, v77_, v78_ = localToWorld(node, offsetX, offsetY, offsetZ)
	local v79_, v80_, v81_ = localDirectionToWorld(node, 0, 1, 0)
	local v82_, v83_, v84_ = localDirectionToWorld(node, 0, 0, 1)
	DebugCamera.renderAtPosition(v76_, v77_, v78_, v79_, v80_, v81_, v82_, v83_, v84_, sizeX, sizeY, sizeZ, color, solid, text, textSize, drawFaces)
end

-- Local values: offsetX, offsetY, offsetZ, x, y, z, sizeX, sizeY, sizeZ, dirX, dirY, dirZ, upX, upY, upZ
function DebugCamera.renderWithStartAndEndNode(nodeStart, nodeEnd, color, solid, text, textSize, drawFaces)
	local v92_, v93_, v94_ = localToLocal(nodeEnd, nodeStart, 0, 0, 0)
	local v95_, v96_, v97_ = localToWorld(nodeStart, v92_ * 0.5, v93_ * 0.5, v94_ * 0.5)
	local v98_ = math.abs(v92_)
	local v99_ = math.abs(v93_)
	local v100_ = math.abs(v94_)
	local v101_, v102_, v103_ = localDirectionToWorld(nodeStart, 0, 0, 1)
	local v104_, v105_, v106_ = localDirectionToWorld(nodeStart, 0, 1, 0)
	DebugCamera.renderAtPosition(v95_, v96_, v97_, v104_, v105_, v106_, v101_, v102_, v103_, v98_ / 2, v99_ / 2, v100_ / 2, color, solid, text, textSize, drawFaces)
end
