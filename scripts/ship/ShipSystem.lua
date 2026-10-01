ShipSystem = {}
local ShipSystem_mt = Class(ShipSystem)
function ShipSystem.new(customMt)
	local self = setmetatable({}, customMt or ShipSystem_mt)
	self.splines = {}
	self.crossingNodes = {}
	return self
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
function ShipSystem:updateSplineCrossing(owner, node)
	local splines = self.crossingNodes[node]
	if splines ~= nil then
		splines = {}
		local wx, wy, wz = getWorldTranslation(node)
		for _, data in ipairs(self.splines) do
			if data.owner == owner then
				continue
			end
			local x, y, z, time = getClosestSplinePosition(data.spline, wx, wy, wz, 0.01)
			local distance = MathUtil.vector3Length(x - wx, y - wy, z - wz)
			local isValid = distance < 1
			if isValid then
				table.insert(splines, { time = time, owner = data.owner, spline = data.spline })
			end
		end
		self.crossingNodes[node] = splines
	end
end
function ShipSystem:getIsShipCrossingPoint(node, duration)
	local splines = self.crossingNodes[node]
	if splines == nil then
		return false
	else
		for _, data in ipairs(splines) do
			if data.owner:getIsShipCrossingPoint(data.spline, data.time, duration) then
				return true
			end
		end
		return false
	end
end
function ShipSystem:addSpline(splineNode, owner)
	if splineNode == nil then
		Logging.warning("No spline node given")
	elseif not getHasClassId(getGeometry(splineNode), ClassIds.SPLINE) then
		Logging.warning("Given node '%s' is not a spline", getName(splineNode))
	else
		local splineData = { spline = splineNode, owner = owner }
		table.addElement(self.splines, splineData)
		for node, _ in pairs(self.crossingNodes) do
			self:updateSplineCrossing(node)
		end
	end
end
function ShipSystem:removeSpline(splineNode, owner)
	if splineNode == nil then
		Logging.warning("No spline node given")
	elseif not getHasClassId(getGeometry(splineNode), ClassIds.SPLINE) then
		Logging.warning("Given node '%s' is not a spline", getName(splineNode))
	else
		for k, data in ipairs(self.splines) do
			if data.spline == splineNode then
				table.remove(self.splines, k)
				break
			end
		end
		for node, _ in pairs(self.crossingNodes) do
			self:updateSplineCrossing(node)
		end
	end
end
