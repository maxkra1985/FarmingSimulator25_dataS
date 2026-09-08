-- Local values: Ship_mt
ShipMover = {}
local Ship_mt = Class(ShipMover, Object)
InitStaticObjectClass(ShipMover, "ShipMover")
g_xmlManager:addInitSchemaFunction(function()
	OnCreateObjectSystem.xmlSchemaSavegame:register(XMLValueType.FLOAT, "onCreateLoadedObjects.object(?)#time", "Current spline time")
end)

-- Local values: ship
function ShipMover:onCreate(node)
	local v3_ = ShipMover.new(g_server ~= nil, g_client ~= nil)
	if v3_:load(node) then
		v3_:register(true)
	else
		v3_:delete()
	end
end

-- Upvalues: Ship_mt
-- Local values: self
function ShipMover.new(isServer, isClient, customMt)
	-- upvalues: (copy) Ship_mt
	local v7_ = Object.new(isServer, isClient, customMt or Ship_mt)
	v7_.dirtyFlag = v7_:getNextDirtyFlag()
	return v7_
end

-- Local values: maxSpeedMps, splineLength, safetyOffsetMeters, i, shipNode, x, y, z, _, _, _, t, length, ship
function ShipMover:load(splineNode)
	if not I3DUtil.getIsSpline(splineNode) then
		Logging.warning("Given node \'%s\' is not a spline for ShipMover", getName(splineNode))
		return false
	end
	self.splineNode = splineNode
	self.currentSplineTime = 0
	self.currentSplineTimeSent = 0
	self.saveId = getName(splineNode)
	local v10_ = MathUtil.kmhToMps(getUserAttribute(splineNode, "speedKmh") or 5)
	local v11_ = getSplineLength(splineNode)
	self.deltaSplineTimePerMs = v10_ / v11_ / 1000
	self.ships = {}
	for v12_ = 0, getNumOfChildren(splineNode) - 1 do
		local v13_ = getChildAt(splineNode, v12_)
		local v14_, v15_, v16_ = getWorldTranslation(v13_)
		local _, _, _, v17_ = getClosestSplinePosition(splineNode, v14_, v15_, v16_, 1)
		local v18_ = getUserAttribute(v13_, "length") or 10
		local v19_ = {
			["node"] = v13_,
			["offset"] = v17_,
			["safetyOffset"] = 20 / v11_,
			["length"] = v18_,
			["currentTime"] = v17_,
			["currentTimeFront"] = v17_
		}
		local v20_ = self.ships
		table.insert(v20_, v19_)
	end
	if self.isServer then
		self.dirtyFlag = self:getNextDirtyFlag()
		self.updateThreshold = 0.05 / v11_
	else
		self.networkTimeInterpolator = InterpolationTime.new(1.2)
		self.networkSplineTimeInterpolator = InterpolatorSplineTime.new(0, true)
	end
	g_currentMission.shipSystem:addSpline(self.splineNode, self)
	g_currentMission.onCreateObjectSystem:add(self, true)
	return true
end

function ShipMover:delete()
	g_currentMission.shipSystem:removeSpline(self.splineNode, self)
	ShipMover:superClass().delete(self)
end

-- Local values: time
function ShipMover:loadFromXMLFile(xmlFile, key)
	local v25_ = xmlFile:getValue(key .. "#time")
	if v25_ ~= nil then
		self.currentSplineTime = v25_
		self.currentSplineTimeSent = v25_
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

-- Local values: time
function ShipMover:readUpdateStream(streamId, timestamp, connection)
	ShipMover:superClass().readUpdateStream(self, streamId, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v38_ = streamReadFloat32(streamId)
		self.networkSplineTimeInterpolator:setTargetValue(v38_, 1)
		self.networkTimeInterpolator:startNewPhaseNetwork()
	end
end

function ShipMover:writeUpdateStream(streamId, connection, dirtyMask)
	ShipMover:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v43_ = streamWriteBool
		local v44_ = self.dirtyFlag
		if v43_(streamId, bit32.band(dirtyMask, v44_) ~= 0) then
			streamWriteFloat32(streamId, self.currentSplineTimeSent)
		end
	end
end

-- Local values: deltaTime, interpolationAlpha
function ShipMover:update(dt)
	ShipMover:superClass().update(self, dt)
	if self.isServer then
		local v47_ = self.deltaSplineTimePerMs * dt
		self.currentSplineTime = (self.currentSplineTime + v47_) % 1
		local v48_ = self.currentSplineTime - self.currentSplineTimeSent
		if math.abs(v48_) > self.updateThreshold then
			self.currentSplineTimeSent = self.currentSplineTime
			self:raiseDirtyFlags(self.dirtyFlag)
		end
		self:raiseActive()
	else
		self.networkTimeInterpolator:update(dt)
		local v49_ = self.networkTimeInterpolator:getAlpha()
		self.currentSplineTime = self.networkSplineTimeInterpolator:getInterpolatedValue(v49_)
		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	self:updatePosition()
end

-- Local values: splineTime, _, ship, node, offset, shipTime, x, y, z, _, _, _, frontTime, xFront, yFront, zFront, dirX, dirY, dirZ
function ShipMover:updatePosition()
	local v51_ = self.currentSplineTime
	for _, v52_ in ipairs(self.ships) do
		local v53_ = v52_.node
		local v54_ = (v51_ + v52_.offset) % 1
		local v55_, v56_, v57_ = getSplinePosition(self.splineNode, v54_)
		setWorldTranslation(v53_, v55_, v56_, v57_)
		local _, _, _, v58_ = getSplinePositionWithDistance(self.splineNode, v54_, v52_.length, true, 0.1)
		local v59_, v60_, v61_ = getSplinePosition(self.splineNode, v58_)
		local v62_ = v59_ - v55_
		local v63_ = v60_ - v56_
		local v64_ = v61_ - v57_
		if MathUtil.vector3Length(v62_, v63_, v64_) < 0.001 then
			v62_, v63_, v64_ = getSplineDirection(self.splineNode, v54_)
		end
		setWorldDirection(v53_, v62_, v63_, v64_, 0, 1, 0)
		v52_.currentTime = v54_
		v52_.currentTimeFront = v58_
	end
end

-- Local values: _, ship, movement, sectionStart, sectionEnd
function ShipMover:getIsShipCrossingPoint(spline, time, durationMs)
	for _, v68_ in ipairs(self.ships) do
		local v69_ = time - self.deltaSplineTimePerMs * durationMs - v68_.safetyOffset
		local v70_ = time + v68_.safetyOffset
		if v69_ < v68_.currentTimeFront and v68_.currentTime < v70_ then
			return true
		end
	end
	return false
end
