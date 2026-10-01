ShipMover = {}
local Ship_mt = Class(ShipMover, Object)
InitStaticObjectClass(ShipMover, "ShipMover")
g_xmlManager:addInitSchemaFunction(function()
	local savegameSchema = OnCreateObjectSystem.xmlSchemaSavegame
	savegameSchema:register(XMLValueType.FLOAT, "onCreateLoadedObjects.object(?)#time", "Current spline time")
end)
function ShipMover:onCreate(node)
	local ship = ShipMover.new(g_server ~= nil, g_client ~= nil)
	if ship:load(node) then
		ship:register(true)
	else
		ship:delete()
	end
end
function ShipMover.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or Ship_mt)
	self.dirtyFlag = self:getNextDirtyFlag()
	return self
end
function ShipMover:load(splineNode)
	if not I3DUtil.getIsSpline(splineNode) then
		Logging.warning("Given node '%s' is not a spline for ShipMover", getName(splineNode))
		return false
	else
		self.splineNode = splineNode
		self.currentSplineTime = 0
		self.currentSplineTimeSent = 0
		self.saveId = getName(splineNode)
		local maxSpeedMps = MathUtil.kmhToMps(getUserAttribute(splineNode, "speedKmh") or 5)
		local splineLength = getSplineLength(splineNode)
		self.deltaSplineTimePerMs = maxSpeedMps / splineLength / 1000
		self.ships = {}
		local safetyOffsetMeters = 20
		for i = 0, getNumOfChildren(splineNode) - 1 do
			local shipNode = getChildAt(splineNode, i)
			local x, y, z = getWorldTranslation(shipNode)
			local _, _, _, t = getClosestSplinePosition(splineNode, x, y, z, 1)
			local length = getUserAttribute(shipNode, "length") or 10
			local ship = { node = shipNode, offset = t, length = length, currentTime = t, currentTimeFront = t }
			ship.safetyOffset = 20 / splineLength
			table.insert(self.ships, ship)
		end
		if self.isServer then
			self.dirtyFlag = self:getNextDirtyFlag()
			self.updateThreshold = 0.05 / splineLength
		else
			self.networkTimeInterpolator = InterpolationTime.new(1.2)
			self.networkSplineTimeInterpolator = InterpolatorSplineTime.new(0, true)
		end
		g_currentMission.shipSystem:addSpline(self.splineNode, self)
		g_currentMission.onCreateObjectSystem:add(self, true)
		return true
	end
end
function ShipMover:delete()
	g_currentMission.shipSystem:removeSpline(self.splineNode, self)
	ShipMover:superClass().delete(self)
end
function ShipMover:loadFromXMLFile(xmlFile, key)
	local time = xmlFile:getValue(key .. "#time")
	if time ~= nil then
		self.currentSplineTime = time
		self.currentSplineTimeSent = time
		self:updatePosition()
	end
	return true
end
function ShipMover:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#time", self.currentSplineTime)
end
function ShipMover:readStream(streamId, connection, objectId)
	if connection:getIsServer() then
		self.currentSplineTime = streamReadFloat32(streamId)
		self.networkTimeInterpolator:reset()
	end
end
function ShipMover:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteFloat32(streamId, self.currentSplineTimeSent)
	end
end
function ShipMover:readUpdateStream(streamId, timestamp, connection)
	ShipMover:superClass().readUpdateStream(self, streamId, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local time = streamReadFloat32(streamId)
		self.networkSplineTimeInterpolator:setTargetValue(time, 1)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end
function ShipMover:writeUpdateStream(streamId, connection, dirtyMask)
	ShipMover:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() and streamWriteBool(streamId, bit32.band(dirtyMask, self.dirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.currentSplineTimeSent)
	end
end
function ShipMover:update(dt)
	ShipMover:superClass().update(self, dt)
	if self.isServer then
		local deltaTime = self.deltaSplineTimePerMs * dt
		self.currentSplineTime = (self.currentSplineTime + deltaTime) % 1
		if self.updateThreshold < math.abs(self.currentSplineTime - self.currentSplineTimeSent) then
			self.currentSplineTimeSent = self.currentSplineTime
			self:raiseDirtyFlags(self.dirtyFlag)
		end
		self:raiseActive()
	else
		self.networkTimeInterpolator:update(dt)
		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
		self.currentSplineTime = self.networkSplineTimeInterpolator:getInterpolatedValue(interpolationAlpha)
		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	self:updatePosition()
end
function ShipMover:updatePosition()
	local splineTime = self.currentSplineTime
	for _, ship in ipairs(self.ships) do
		local node = ship.node
		local offset = ship.offset
		local shipTime = (splineTime + offset) % 1
		local x, y, z = getSplinePosition(self.splineNode, shipTime)
		setWorldTranslation(node, x, y, z)
		local _, _, _, frontTime = getSplinePositionWithDistance(self.splineNode, shipTime, ship.length, true, 0.1)
		local xFront, yFront, zFront = getSplinePosition(self.splineNode, frontTime)
		local dirX = xFront - x
		local dirY = yFront - y
		local dirZ = zFront - z
		if MathUtil.vector3Length(dirX, dirY, dirZ) < 0.001 then
			dirX, dirY, dirZ = getSplineDirection(self.splineNode, shipTime)
		end
		setWorldDirection(node, dirX, dirY, dirZ, 0, 1, 0)
		ship.currentTime = shipTime
		ship.currentTimeFront = frontTime
	end
end
function ShipMover:getIsShipCrossingPoint(spline, time, durationMs)
	for _, ship in ipairs(self.ships) do
		local movement = self.deltaSplineTimePerMs * durationMs
		local sectionStart = time - movement - ship.safetyOffset
		local sectionEnd = time + ship.safetyOffset
		if sectionStart < ship.currentTimeFront and ship.currentTime < sectionEnd then
			return true
		end
	end
	return false
end
