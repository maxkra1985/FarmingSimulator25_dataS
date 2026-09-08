-- Local values: BoatyardStateMoving_mt
BoatyardStateMoving = {}
local BoatyardStateMoving_mt = Class(BoatyardStateMoving, BoatyardState)

function BoatyardStateMoving.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".spline#startTime", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".spline#endTime", "")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spline#endPosNode", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".spline#maxSpeed", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".spline#acceleration", "")
end

-- Upvalues: BoatyardStateMoving_mt
-- Local values: self
function BoatyardStateMoving.new(boatyard, customMt)
	-- upvalues: (copy) BoatyardStateMoving_mt
	return BoatyardState.new(boatyard, customMt or BoatyardStateMoving_mt)
end

-- Local values: splineEndPosNode, x, y, z, _, _, _, splineTime
function BoatyardStateMoving:load(xmlFile, key)
	BoatyardStateMoving:superClass().load(self, xmlFile, key)
	self.splineStartTime = xmlFile:getValue(key .. ".spline#startTime")
	self.splineEndTime = xmlFile:getValue(key .. ".spline#endTime")
	local v9_ = xmlFile:getValue(key .. ".spline#endPosNode", nil, self.boatyard.components, self.boatyard.i3dMappings)
	if v9_ ~= nil then
		local v10_, v11_, v12_ = getWorldTranslation(v9_)
		local _, _, _, v13_ = getClosestSplinePosition(self.spline, v10_, v11_, v12_, 0.3)
		self.splineEndTime = v13_
	end
	self.speed = 0
	self.maxSpeed = xmlFile:getValue(key .. ".spline#maxSpeed", 2)
	self.acc = xmlFile:getValue(key .. ".spline#acceleration", 1)
end

function BoatyardStateMoving:isDone()
	return self.boatyard:getSplineTime() >= self.splineEndTime
end

-- Local values: splineTime, remainingDistance
function BoatyardStateMoving:update(dt)
	if self.boatyard.isServer then
		local v17_ = self.boatyard:addSplineDistanceDelta(self.speed / 1000 * dt)
		local v18_ = self.splineLength * (self.splineEndTime - v17_)
		if v18_ < 3 then
			self.deaccSpeed = self.deaccSpeed or self.speed
			self.speed = MathUtil.lerp(self.deaccSpeed, 0.1, 1 - v18_ / 3)
		else
			local v19_ = self.speed + self.acc * dt / 1000
			local v20_ = self.maxSpeed
			self.speed = math.clamp(v19_, 0.01, v20_)
		end
	end
	BoatyardStateMoving:superClass().update(self, dt)
end

function BoatyardStateMoving:activate()
	self.speed = 0
	if self.splineStartTime ~= nil then
		self.boatyard:setSplineTime(self.splineStartTime)
	end
	BoatyardStateMoving:superClass().activate(self)
end

function BoatyardStateMoving:getMovingSpeedSoundModifier()
	return self.speed / self.maxSpeed
end
g_soundManager:registerModifierType("BOATYARD_MOVING_SPEED", BoatyardStateMoving.getMovingSpeedSoundModifier)
