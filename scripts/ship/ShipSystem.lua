-- Local values: ShipSystem_mt
ShipSystem = {}
local ShipSystem_mt = Class(ShipSystem)

-- Upvalues: ShipSystem_mt
-- Local values: self
function ShipSystem.new(customMt)
	-- upvalues: (copy) ShipSystem_mt
	local v3_ = customMt or ShipSystem_mt
	local v4_ = setmetatable({}, v3_)
	v4_.splines = {}
	v4_.crossingNodes = {}
	return v4_
end

function ShipSystem:delete() end

function ShipSystem:addCrossingNode(owner, node)
	if self.crossingNodes[node] == nil then
		self.crossingNodes[node] = {}
		self:updateSplineCrossing(owner, node)
	end
end

function ShipSystem:removeCrossingNode(owner, node)
	self.crossingNodes[node] = nil
end

-- Local values: splines, wx, wy, wz, _, data, x, y, z, time, distance, isValid
function ShipSystem:updateSplineCrossing(owner, node)
	if self.crossingNodes[node] ~= nil then
		local v13_, v14_, v15_ = getWorldTranslation(node)
		local v16_ = {}
		for _, v17_ in ipairs(self.splines) do
			if v17_.owner ~= owner then
				local v18_, v19_, v20_, v21_ = getClosestSplinePosition(v17_.spline, v13_, v14_, v15_, 0.01)
				if MathUtil.vector3Length(v18_ - v13_, v19_ - v14_, v20_ - v15_) < 1 then
					local v22_ = {
						["owner"] = v17_.owner,
						["spline"] = v17_.spline,
						["time"] = v21_
					}
					table.insert(v16_, v22_)
				end
			end
		end
		self.crossingNodes[node] = v16_
	end
end

-- Local values: splines, _, data
function ShipSystem:getIsShipCrossingPoint(node, duration)
	local v26_ = self.crossingNodes[node]
	if v26_ == nil then
		return false
	end
	for _, v27_ in ipairs(v26_) do
		if v27_.owner:getIsShipCrossingPoint(v27_.spline, v27_.time, duration) then
			return true
		end
	end
	return false
end

-- Local values: splineData, node, _
function ShipSystem:addSpline(splineNode, owner)
	if splineNode == nil then
		Logging.warning("No spline node given")
		return
	elseif getHasClassId(getGeometry(splineNode), ClassIds.SPLINE) then
		table.addElement(self.splines, {
			["spline"] = splineNode,
			["owner"] = owner
		})
		for v31_, _ in pairs(self.crossingNodes) do
			self:updateSplineCrossing(v31_)
		end
	else
		Logging.warning("Given node \'%s\' is not a spline", getName(splineNode))
	end
end

-- Local values: k, data, node, _
function ShipSystem:removeSpline(splineNode, owner)
	if splineNode == nil then
		Logging.warning("No spline node given")
		return
	end
	if not getHasClassId(getGeometry(splineNode), ClassIds.SPLINE) then
		Logging.warning("Given node \'%s\' is not a spline", getName(splineNode))
		return
	end
	for v34_, v35_ in ipairs(self.splines) do
		if v35_.spline == splineNode then
			table.remove(self.splines, v34_)
			break
		end
	end
	for v36_, _ in pairs(self.crossingNodes) do
		self:updateSplineCrossing(v36_)
	end
end
