-- Local values: FerryStateDriving_mt
FerryStateDriving = {}
local FerryStateDriving_mt = Class(FerryStateDriving, FerryState)

function FerryStateDriving.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#drivingDirection", "Driving direction of the vessel", 1, false)
end

-- Upvalues: FerryStateDriving_mt
-- Local values: self
function FerryStateDriving.new(ferry, customMt)
	-- upvalues: (copy) FerryStateDriving_mt
	local v6_ = FerryState.new(ferry, customMt or FerryStateDriving_mt)
	v6_.drivingDirection = 1
	return v6_
end

function FerryStateDriving:load(xmlFile, key)
	if not FerryStateDriving:superClass().load(self, xmlFile, key) then
		return false
	end
	self.drivingDirection = xmlFile:getValue(key .. "#drivingDirection", 1)
	return true
end

-- Local values: direction, time
function FerryStateDriving:isDone()
	if FerryStateDriving:superClass().isDone(self) then
		local v11_ = self.drivingDirection
		local v12_ = self.ferry:getSplineTime()
		if v11_ == 1 and v12_ == 1 then
			return true
		elseif v11_ == -1 and v12_ == 0 then
			return true
		elseif v11_ == 0 then
			return false
		else
			return false
		end
	else
		return false
	end
end

-- Local values: ferry, splineTimePerMs, delta
function FerryStateDriving:update(dt)
	FerryStateDriving:superClass().update(self, dt)
	if self.ferry.isServer then
		local v15_ = self.ferry
		local v16_ = v15_:getSplineTimeDeltaPerMs()
		v15_:addSplineTimeDelta(self.drivingDirection * v16_ * dt)
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
