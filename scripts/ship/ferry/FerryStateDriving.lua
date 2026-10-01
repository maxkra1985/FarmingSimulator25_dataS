FerryStateDriving = {}
local FerryStateDriving_mt = Class(FerryStateDriving, FerryState)
function FerryStateDriving.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#drivingDirection", "Driving direction of the vessel", 1, false)
end
function FerryStateDriving.new(ferry, customMt)
	local self = FerryState.new(ferry, customMt or FerryStateDriving_mt)
	self.drivingDirection = 1
	return self
end
function FerryStateDriving:load(xmlFile, key)
	if not FerryStateDriving:superClass().load(self, xmlFile, key) then
		return false
	else
		self.drivingDirection = xmlFile:getValue(key .. "#drivingDirection", 1)
		return true
	end
end
function FerryStateDriving:isDone()
	if not FerryStateDriving:superClass().isDone(self) then
		return false
	end
	local direction = self.drivingDirection
	local time = self.ferry:getSplineTime()
	if direction == 1 and time == 1 then
		return true
	end
	if direction == -1 and time == 0 then
		return true
	end
	if direction == 0 then
		return false
	else
		return false
	end
end
function FerryStateDriving:update(dt)
	FerryStateDriving:superClass().update(self, dt)
	if self.ferry.isServer then
		local ferry = self.ferry
		local splineTimePerMs = ferry:getSplineTimeDeltaPerMs()
		local delta = self.drivingDirection * splineTimePerMs * dt
		ferry:addSplineTimeDelta(delta)
	end
end
function FerryStateDriving:activate()
	FerryStateDriving:superClass().activate(self)
	self.ferry:startMotor()
end
function FerryStateDriving:deactivate()
	FerryStateDriving:superClass().deactivate(self)
	self.ferry:stopMotor()
end
