-- Local values: DebugGizmo_mt
DebugGizmo = {}
DebugGizmo.SCALE_DEFAULT = 0.5
local DebugGizmo_mt = Class(DebugGizmo, DebugElement)

-- Upvalues: DebugGizmo_mt
-- Local values: self
function DebugGizmo.new(customMt)
	-- upvalues: (copy) DebugGizmo_mt
	local v3_ = DebugGizmo:superClass().new(customMt or DebugGizmo_mt)
	v3_.dirX = 0
	v3_.dirY = 0
	v3_.dirZ = 1
	v3_.upX = 0
	v3_.upY = 1
	v3_.upZ = 0
	v3_.scale = DebugGizmo.SCALE_DEFAULT
	v3_.solid = true
	v3_.textOffsets = nil
	v3_.textColor = nil
	v3_.textSize = getCorrectTextSize(0.012)
	v3_.alignToGround = false
	v3_.hideWhenGuiIsOpen = false
	return v3_
end

function DebugGizmo:delete() end

function DebugGizmo:update(dt) end

function DebugGizmo:getShouldBeDrawn()
	if self.hideWhenGuiIsOpen and g_gui:getIsGuiVisible() then
		return false
	else
		return (not self.clipDistance or DebugUtil.isPositionInCameraRange(self.x, self.y, self.z, self.clipDistance)) and true or false
	end
end

function DebugGizmo:draw()
	DebugGizmo.renderAtPosition(self.x, self.y, self.z, self.dirX, self.dirY, self.dirZ, self.upX, self.upY, self.upZ, self.text, self.solid, self.scale, self.textSize, self.textColor, self.textOffsets)
end

-- Local values: normX, normY, normZ
function DebugGizmo.renderAtPosition(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, solid, scale, textSize, textColor, textOffsets)
	local v21_, v22_, v23_ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	local v24_ = scale or DebugGizmo.SCALE_DEFAULT
	if y == nil then
		if g_terrainNode == nil then
			return
		end
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
	end
	drawDebugLine(x, y, z, 1, 0, 0, x + v24_ * v21_, y + v24_ * v22_, z + v24_ * v23_, 1, 0, 0, solid)
	drawDebugLine(x, y, z, 0, 1, 0, x + v24_ * upX, y + v24_ * upY, z + v24_ * upZ, 0, 1, 0, solid)
	drawDebugLine(x, y, z, 0, 0, 1, x + v24_ * dirX, y + v24_ * dirY, z + v24_ * dirZ, 0, 0, 1, solid)
	if text ~= nil then
		local v25_ = textSize or getCorrectTextSize(0.012)
		local v26_ = textColor or Color.PRESETS.WHITE
		if textOffsets ~= nil then
			x = x + textOffsets[1]
			y = y + textOffsets[2]
			z = z + textOffsets[3]
		end
		Utils.renderTextAtWorldPosition(x, y, z, text, v25_, 0, v26_:unpack())
	end
end

-- Local values: dirX, dirY, dirZ, upX, upY, upZ
function DebugGizmo.renderAtPositionSimple(x, y, z, text, solid, scale, textSize, textColor, textOffsets)
	DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0, text, solid, scale, textSize, textColor, textOffsets)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugGizmo.renderAtNode(node, text, solid, scale, alignToGround, textSize, textColor, textOffsets)
	local v44_, v45_, v46_ = getWorldTranslation(node)
	if alignToGround and g_terrainNode ~= nil then
		v45_ = getTerrainHeightAtWorldPos(g_terrainNode, v44_, 0, v46_) + 0.01
	end
	local v47_, v48_, v49_ = localDirectionToWorld(node, 0, 1, 0)
	local v50_, v51_, v52_ = localDirectionToWorld(node, 0, 0, 1)
	DebugGizmo.renderAtPosition(v44_, v45_, v46_, v50_, v51_, v52_, v47_, v48_, v49_, text, solid, scale, textSize, textColor, textOffsets)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugGizmo.renderAtNodeWithOffset(node, offsetX, offsetY, offsetZ, text, solid, scale, alignToGround, textSize, textColor, textOffsets)
	local v64_, v65_, v66_ = getWorldTranslation(node)
	local v67_ = v64_ + (offsetX or 0)
	local v68_ = v65_ + (offsetY or 0)
	local v69_ = v66_ + (offsetZ or 0)
	if alignToGround and g_terrainNode ~= nil then
		v68_ = getTerrainHeightAtWorldPos(g_terrainNode, v67_, 0, v69_) + 0.01
	end
	local v70_, v71_, v72_ = localDirectionToWorld(node, 0, 1, 0)
	local v73_, v74_, v75_ = localDirectionToWorld(node, 0, 0, 1)
	DebugGizmo.renderAtPosition(v67_, v68_, v69_, v73_, v74_, v75_, v70_, v71_, v72_, text, solid, scale, textSize, textColor, textOffsets)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugGizmo.renderAtNodeWithLocalOffset(node, offsetX, offsetY, offsetZ, text, solid, scale, alignToGround, textSize, textColor, textOffsets)
	local v87_, v88_, v89_ = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
	if alignToGround and g_terrainNode ~= nil then
		v88_ = getTerrainHeightAtWorldPos(g_terrainNode, v87_, 0, v89_) + 0.01
	end
	local v90_, v91_, v92_ = localDirectionToWorld(node, 0, 1, 0)
	local v93_, v94_, v95_ = localDirectionToWorld(node, 0, 0, 1)
	DebugGizmo.renderAtPosition(v87_, v88_, v89_, v90_, v91_, v92_, v93_, v94_, v95_, text, solid, scale, textSize, textColor, textOffsets)
end

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugGizmo:createWithNode(node, text, alignToGround, textOffsets, scale, solid)
	local v103_, v104_, v105_ = getWorldTranslation(node)
	local v106_, v107_, v108_ = localDirectionToWorld(node, 0, 1, 0)
	local v109_, v110_, v111_ = localDirectionToWorld(node, 0, 0, 1)
	self:createWithWorldPosAndDir(v103_, v104_, v105_, v109_, v110_, v111_, v106_, v107_, v108_, text, alignToGround, textOffsets, scale, solid)
	return self
end

function DebugGizmo:createWithWorldPosAndDir(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround, textOffsets, scale, solid)
	if alignToGround and g_terrainNode ~= nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
	end
	self.x = x
	self.y = y
	self.z = z
	self.dirX = dirX
	self.dirY = dirY
	self.dirZ = dirZ
	self.upX = upX
	self.upY = upY
	self.upZ = upZ
	self.text = text and tostring(text) or nil
	self.scale = scale or self.scale
	self.solid = Utils.getNoNil(solid, self.solid)
	if textOffsets ~= nil then
		self.textOffsets = textOffsets
	end
	self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
	return self
end
