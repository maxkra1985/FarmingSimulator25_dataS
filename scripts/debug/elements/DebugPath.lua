-- Local values: DebugPath_mt
DebugPath = {}
local DebugPath_mt = Class(DebugPath, DebugElement)

-- Upvalues: DebugPath_mt
-- Local values: self
function DebugPath.new(customMt)
	-- upvalues: (copy) DebugPath_mt
	local v3_ = DebugPath:superClass().new(customMt or DebugPath_mt)
	v3_.points = {}
	v3_.alignToGround = false
	v3_.minimumDistanceBetweenPoints = nil
	v3_.solid = true
	return v3_
end

-- Local values: self
function DebugPath.newSimple(color, alignToGround, minimumDistanceBetweenPoints, solid, text)
	local v9_ = DebugPath.new()
	v9_:setColorRGBA(unpack(color))
	v9_.alignToGround = Utils.getNoNil(alignToGround, v9_.alignToGround)
	v9_.minimumDistanceBetweenPoints = minimumDistanceBetweenPoints
	v9_.solid = Utils.getNoNil(solid, v9_.solid)
	v9_:setText(text)
	return v9_
end

function DebugPath:getShouldBeDrawn()
	return true
end

function DebugPath:draw()
	DebugPath.renderPath(self.points, self.color, self.alignToGround, self.forcedY, self.solid, self.clipDistance, self.text)
end

-- Local values: r, g, b, cameraX, cameraY, cameraZ, firstPoint, lastPoint, minimalDistance, closestPoint, pointIndex, point, nextPoint, drawSection, distanceToCam, px, py, pz, npx, npy, npz, point
function DebugPath.renderPath(points, color, alignToGround, forcedY, solid, clipDistance, text)
	if #points < 2 then
		return
	end
	local v18_, v19_, v20_ = (color or Color.PRESETS.WHITE):unpack()
	local v21_, v22_, v23_
	if clipDistance == nil then
		v21_ = nil
		v22_ = nil
		v23_ = nil
	else
		v21_, v22_, v23_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	end
	local v24_ = points[1]
	local v25_ = points[#points]
	if clipDistance == nil or MathUtil.vector3Length(v24_[1] - v21_, v24_[2] - v22_, v24_[3] - v23_) < clipDistance then
		drawDebugPoint(v24_[1], v24_[2], v24_[3], 0, 1, 0, 1, false)
	end
	if clipDistance == nil or MathUtil.vector3Length(v25_[1] - v21_, v25_[2] - v22_, v25_[3] - v23_) < clipDistance then
		drawDebugPoint(v25_[1], v25_[2], v25_[3], 1, 0, 0, 1, false)
	end
	local v26_ = math.huge
	local v27_ = nil
	for v32_, v29_ in ipairs(points) do
		local v30_ = points[v32_ + 1]
		if v30_ == nil then
			break
		end
		local v31_ = true
		local v32_, v33_
		if clipDistance == nil then
			v32_ = v27_
			v33_ = v26_
		else
			v33_ = MathUtil.vector3Length(v29_[1] - v21_, v29_[2] - v22_, v29_[3] - v23_)
			if clipDistance < v33_ then
				v32_ = v27_
				v33_ = v26_
				v31_ = false
			elseif v33_ >= v26_ then
				v32_ = v27_
				v33_ = v26_
			end
		end
		if v31_ then
			local v34_ = v29_[1]
			local v35_ = v29_[2]
			local v36_ = v29_[3]
			local v37_ = v30_[1]
			local v38_ = v30_[2]
			local v39_ = v30_[3]
			if forcedY == nil and (alignToGround and g_terrainNode ~= nil) then
				v35_ = getTerrainHeightAtWorldPos(g_terrainNode, v34_, 0, v36_) + 0.025
				v38_ = getTerrainHeightAtWorldPos(g_terrainNode, v37_, 0, v39_) + 0.025
			end
			drawDebugLine(v34_, forcedY or v35_, v36_, v18_, v19_, v20_, v37_, forcedY or v38_, v39_, v18_, v19_, v20_, solid)
			v27_ = v32_
			v26_ = v33_
		else
			v27_ = v32_
			v26_ = v33_
		end
	end
	if text ~= nil and v27_ ~= nil then
		local v40_ = points[v27_]
		Utils.renderTextAtWorldPosition(v40_[1], v40_[2], v40_[3], text, 0.02, 0.01, color:unpack())
	end
end

-- Local values: p, distance
function DebugPath:addPoint(x, y, z)
	if self.minimumDistanceBetweenPoints ~= nil then
		local v45_ = self.points[#self.points]
		if v45_ ~= nil and MathUtil.vector3Length(v45_[1] - x, v45_[2] - y, v45_[3] - z) < self.minimumDistanceBetweenPoints then
			return self
		end
	end
	local v46_ = self.points
	table.insert(v46_, { x, y, z })
	return self
end

function DebugPath:clear()
	self.points = {}
	return self
end

function DebugPath:setForcedY(forcedY)
	self.forcedY = forcedY
	return self
end
