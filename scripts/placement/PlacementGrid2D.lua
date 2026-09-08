-- Local values: PlacementGrid2D_mt
PlacementGrid2D = {}
PlacementGrid2D.MODE_SIDES = 0
PlacementGrid2D.MODE_FILL = 1
PlacementGrid2D.EPSILON = 0.01
local PlacementGrid2D_mt = Class(PlacementGrid2D)

-- Upvalues: PlacementGrid2D_mt
-- Local values: self
function PlacementGrid2D.new(node, width, length, spacing, mode)
	-- upvalues: (copy) PlacementGrid2D_mt
	local v7_ = PlacementGrid2D_mt
	local v8_ = setmetatable({}, v7_)
	v8_.node = node
	v8_.width = width
	v8_.length = length
	v8_.spacing = spacing
	v8_.placementMode = mode or PlacementGrid2D.MODE_SIDES
	v8_.blockedAreas = {}
	v8_.lowerPos = {
		["x"] = 0,
		["z"] = 0,
		["isValid"] = false
	}
	v8_.upperPos = {
		["x"] = 0,
		["z"] = 0,
		["isValid"] = false
	}
	return v8_
end

function PlacementGrid2D:delete() end

function PlacementGrid2D:reset()
	self.blockedAreas = {}
end

-- Local values: foundPosX, foundPosZ, steps, i, blockedArea, offsetZ, minX, maxX, lowerSpace, upperSpace, size, size
function PlacementGrid2D:getFreePosition(width, length)
	self.lowerPos.isValid = false
	self.upperPos.isValid = false
	local v13_ = self.length / self.spacing
	local v14_ = nil
	local v15_ = nil
	for v16_ = 0, math.floor(v13_) do
		local v17_ = self.blockedAreas[v16_]
		local v18_ = v16_ * self.spacing
		local v19_ = self.width
		local v20_ = self.width
		local v21_ = self.width
		local v22_
		if v17_ == nil then
			v22_ = 0
		else
			v19_ = v17_.minX
			v22_ = v17_.maxX
			v20_ = v17_.minX
			v21_ = self.width - v17_.maxX
		end
		if self.lowerPos.isValid then
			if width - v20_ < PlacementGrid2D.EPSILON then
				if self.placementMode == PlacementGrid2D.MODE_FILL then
					local v23_ = self.lowerPos
					local v24_ = self.lowerPos.x
					local v25_ = v19_ - width
					v23_.x = math.min(v24_, v25_)
				end
				if length <= v18_ + self.spacing - self.lowerPos.z then
					v14_ = self.lowerPos.x
					v15_ = self.lowerPos.z
					break
				end
			else
				self.lowerPos.isValid = false
			end
		elseif width - v20_ < 0.01 then
			self.lowerPos.isValid = true
			self.lowerPos.z = v18_
			if self.placementMode == PlacementGrid2D.MODE_SIDES then
				self.lowerPos.x = 0
			else
				self.lowerPos.x = v19_ - width
			end
		end
		if self.upperPos.isValid then
			if width - v21_ < 0.01 then
				if self.placementMode == PlacementGrid2D.MODE_FILL then
					local v26_ = self.upperPos
					local v27_ = self.upperPos.x
					v26_.x = math.max(v27_, v22_)
				end
				if length <= v18_ + self.spacing - self.upperPos.z then
					v14_ = self.upperPos.x
					v15_ = self.upperPos.z
					break
				end
			else
				self.upperPos.isValid = false
			end
		elseif width - v21_ < PlacementGrid2D.EPSILON then
			self.upperPos.isValid = true
			self.upperPos.z = v18_
			if self.placementMode == PlacementGrid2D.MODE_SIDES then
				self.upperPos.x = self.width - width
			else
				self.upperPos.x = v22_
			end
		end
	end
	if v14_ == nil then
		return nil, nil
	else
		return v14_, v15_
	end
end
function PlacementGrid2D.blockAreaLocal(p28_, p29_, p30_, p31_, p32_)
	p28_:updateBlockedArea(p29_, p29_ + p31_, p30_, p30_ + p32_)
end

-- Local values: x1, _, z1, x2, _, z2, x3, _, z3, x4, _, z4, x5, _, z5, x6, _, z6, x7, _, z7, x8, _, z8, minX, maxX, minZ, maxZ
function PlacementGrid2D:blockAreaByBoundingBox(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ)
	local v46_, _, v47_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, -extendY, -extendZ))
	local v48_, _, v49_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, -extendY, -extendZ))
	local v50_, _, v51_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, -extendY, extendZ))
	local v52_, _, v53_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, -extendY, extendZ))
	local v54_, _, v55_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, extendY, -extendZ))
	local v56_, _, v57_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, -extendZ))
	local v58_, _, v59_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ))
	local v60_, _, v61_ = worldToLocal(self.node, MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, -extendX, extendY, extendZ))
	local v62_ = math.min(v46_, v48_, v50_, v52_, v54_, v56_, v58_, v60_)
	local v63_ = math.max(0, v62_)
	local v64_ = self.width
	local v65_ = math.max(v46_, v48_, v50_, v52_, v54_, v56_, v58_, v60_)
	local v66_ = math.min(v64_, v65_)
	local v67_ = math.min(v47_, v49_, v51_, v53_, v55_, v57_, v59_, v61_)
	local v68_ = math.max(0, v67_)
	local v69_ = self.length
	local v70_ = math.max(v47_, v49_, v51_, v53_, v55_, v57_, v59_, v61_)
	self:updateBlockedArea(v63_, v66_, v68_, (math.min(v69_, v70_)))
end

-- Local values: startIndex, endIndex, i, blockedArea, zStart, zEnd, offsetZ
function PlacementGrid2D:updateBlockedArea(minX, maxX, minZ, maxZ)
	local v76_ = minZ / self.spacing
	local v77_ = math.ceil(v76_)
	local v78_ = math.max(1, v77_)
	local v79_ = maxZ / self.spacing
	local v80_ = math.ceil(v79_)
	for v81_ = v78_, math.max(0, v80_) do
		local v82_ = self.blockedAreas[v81_]
		if v82_ == nil then
			local v83_ = (v81_ - 1) * self.spacing
			local v84_ = v81_ * self.spacing
			local v85_ = (v83_ + v84_) * 0.5
			v82_ = {
				["minX"] = self.width,
				["maxX"] = 0,
				["zStart"] = v83_,
				["zEnd"] = v84_,
				["offsetZ"] = v85_
			}
			self.blockedAreas[v81_] = v82_
		end
		local v86_ = v82_.minX
		v82_.minX = math.min(v86_, minX)
		local v87_ = v82_.maxX
		v82_.maxX = math.max(v87_, maxX)
	end
end

-- Local values: x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, _, blockedArea, sx1, sy1, sz1, sx2, sy2, sz2, csx1, csy1, csz1, csx2, csy2, csz2, cex1, cey1, cez1, cex2, cey2, cez2
function PlacementGrid2D:drawDebug()
	local v89_, v90_, v91_ = localToWorld(self.node, 0, 0, 0)
	local v92_, v93_, v94_ = localToWorld(self.node, self.width, 0, 0)
	local v95_, v96_, v97_ = localToWorld(self.node, self.width, 0, self.length)
	local v98_, v99_, v100_ = localToWorld(self.node, 0, 0, self.length)
	drawDebugLine(v89_, v90_, v91_, 1, 1, 1, v92_, v93_, v94_, 1, 1, 1)
	drawDebugLine(v92_, v93_, v94_, 1, 1, 1, v95_, v96_, v97_, 1, 1, 1)
	drawDebugLine(v95_, v96_, v97_, 1, 1, 1, v98_, v99_, v100_, 1, 1, 1)
	drawDebugLine(v98_, v99_, v100_, 1, 1, 1, v89_, v90_, v91_, 1, 1, 1)
	for _, v101_ in pairs(self.blockedAreas) do
		local v102_, v103_, v104_ = localToWorld(self.node, v101_.minX, 0, v101_.offsetZ)
		local v105_, v106_, v107_ = localToWorld(self.node, v101_.maxX, 0, v101_.offsetZ)
		if v101_.maxX > v101_.minX then
			local v108_, v109_, v110_ = localToWorld(self.node, v101_.minX, 0, v101_.zStart)
			local v111_, v112_, v113_ = localToWorld(self.node, v101_.maxX, 0, v101_.zStart)
			drawDebugLine(v108_, v109_, v110_, 1, 1, 1, v111_, v112_, v113_, 1, 1, 1)
			local v114_, v115_, v116_ = localToWorld(self.node, v101_.minX, 0, v101_.zEnd)
			local v117_, v118_, v119_ = localToWorld(self.node, v101_.maxX, 0, v101_.zEnd)
			drawDebugLine(v114_, v115_, v116_, 1, 1, 1, v117_, v118_, v119_, 1, 1, 1)
			drawDebugLine(v102_, v103_, v104_, 1, 0, 0, v105_, v106_, v107_, 1, 0, 0)
		end
	end
end
