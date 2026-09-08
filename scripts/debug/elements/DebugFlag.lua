-- Local values: DebugFlag_mt
DebugFlag = {}
local DebugFlag_mt = Class(DebugFlag, DebugElement)

-- Upvalues: DebugFlag_mt
-- Local values: self
function DebugFlag.new(customMt)
	-- upvalues: (copy) DebugFlag_mt
	local v3_ = DebugFlag:superClass().new(customMt or DebugFlag_mt)
	v3_.dirX = 0
	v3_.dirZ = 1
	v3_.postHeight = 4
	v3_.flagHeight = 0.7
	v3_.flagLength = 1
	v3_.numSectionsY = 4
	v3_.numSectionsZ = 6
	v3_.text = nil
	return v3_
end

function DebugFlag:create(x, y, z, dirX, dirZ)
	self.x = x
	self.y = y
	self.z = z
	self.dirX = dirX
	self.dirZ = dirZ
	return self
end

-- Local values: x, y, z, dirX, _, dirZ
function DebugFlag:createWithNode(node, alignToGround)
	local v13_, v14_, v15_ = getWorldTranslation(node)
	if alignToGround and g_terrainNode ~= nil then
		v14_ = getTerrainHeightAtWorldPos(g_terrainNode, v13_, v14_, v15_)
	end
	local v16_, _, v17_ = localDirectionToWorld(node, 0, 0, 1)
	self:create(v13_, v14_, v15_, v16_, v17_)
	return self
end

function DebugFlag:draw()
	DebugFlag.renderAtPosition(self.x, self.y, self.z, self.dirX, self.dirZ, self.color, self.text, self.postHeight, self.flagHeight, self.flagLength, self.numSectionsY, self.numSectionsZ)
end

-- Local values: x, y, z, _
function DebugFlag.renderAtNode(node, dirX, dirZ, color, text, postHeight, flagHeight, flagLength, numSectionsY, numSectionsZ)
	local v29_, v30_, v31_ = getWorldTranslation(node)
	if dirX == nil or dirZ == nil then
		local v32_
		dirX, v32_, dirZ = localDirectionToWorld(node, 1, 0, 0)
	end
	DebugFlag.renderAtPosition(v29_, v30_, v31_, dirX, dirZ, color, text, postHeight, flagHeight, flagLength, numSectionsY, numSectionsZ)
end

-- Local values: r, g, b, a, tx, tz, posYStart, posYEnd, i, offset, lx, lz, i, offset, ly
function DebugFlag.renderAtPosition(x, y, z, dirX, dirZ, color, text, postHeight, flagHeight, flagLength, numSectionsY, numSectionsZ)
	local v45_ = dirX or 0
	local v46_ = dirZ or 1
	local v47_, v48_, v49_, v50_ = (color or Color.PRESETS.WHITE):unpack()
	local v51_ = postHeight or 4
	local v52_ = flagHeight or 0.7
	local v53_ = flagLength or 1
	local v54_ = numSectionsZ or 6
	local v55_ = x + v45_ * v53_
	local v56_ = z + v46_ * v53_
	drawDebugLine(x, y, z, v47_, v48_, v49_, x, y + v51_, z, v47_, v48_, v49_)
	local v57_ = y + v51_ - v52_
	local v58_ = y + v51_
	local v59_ = numSectionsY or 4
	for v60_ = 1, v54_ do
		local v61_ = v53_ * (v60_ / v54_)
		local v62_ = x + v45_ * v61_
		local v63_ = z + v46_ * v61_
		drawDebugLine(v62_, v57_, v63_, v47_, v48_, v49_, v62_, v58_, v63_, v47_, v48_, v49_)
	end
	for v64_ = 0, v59_ do
		local v65_ = v57_ + v52_ * (v64_ / v59_)
		drawDebugLine(x, v65_, z, v47_, v48_, v49_, v55_, v65_, v56_, v47_, v48_, v49_)
	end
	if text ~= nil then
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
		Utils.renderTextAtWorldPosition(x, y + v51_ * 1.05, z, text, 0.02, 0, v47_, v48_, v49_, v50_)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	end
end
