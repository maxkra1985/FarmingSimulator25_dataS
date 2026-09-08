-- Local values: AIDriveStrategyConveyor_mt
AIDriveStrategyConveyor = {}
local AIDriveStrategyConveyor_mt = Class(AIDriveStrategyConveyor, AIDriveStrategy)

-- Upvalues: AIDriveStrategyConveyor_mt
-- Local values: self
function AIDriveStrategyConveyor.new(reconstructionData, customMt)
	-- upvalues: (copy) AIDriveStrategyConveyor_mt
	return AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyConveyor_mt)
end

-- Local values: _, y, z, x1, y1, z1, x2, y2, z2, length, width, length2
function AIDriveStrategyConveyor:setAIVehicle(vehicle)
	AIDriveStrategyConveyor:superClass().setAIVehicle(self, vehicle)
	local _, v6_, v7_ = localToLocal(self.vehicle.wheels[self.vehicle.aiConveyorBelt.backWheelIndex].repr, self.vehicle.components[1].node, 0, 0, 0)
	local v8_, v9_, v10_ = localToWorld(self.vehicle.components[1].node, 0, v6_, v7_)
	local v11_, v12_, v13_ = getWorldTranslation(self.vehicle.wheels[self.vehicle.aiConveyorBelt.centerWheelIndex].repr)
	local v14_ = MathUtil.vector3Length(v8_ - v11_, v9_ - v12_, v10_ - v13_)
	local v15_ = self.vehicle.aiConveyorBelt.currentAngle / 2
	local v16_ = math.rad(v15_)
	local v17_ = v14_ * math.sin(v16_)
	local v18_ = math.pow(v14_, 2) - math.pow(v17_, 2)
	local v19_ = math.sqrt(v18_)
	local v20_ = self.vehicle.aiConveyorBelt.currentAngle
	self.distanceToMove = math.rad(v20_) * v14_ / 2
	self.currentTarget = 1
	self.worldTarget = {}
	self.worldTarget[1] = { localToWorld(self.vehicle.wheels[self.vehicle.aiConveyorBelt.centerWheelIndex].repr, v17_, 0, -v19_) }
	self.worldTarget[2] = { localToWorld(self.vehicle.wheels[self.vehicle.aiConveyorBelt.centerWheelIndex].repr, -v17_, 0, -v19_) }
	self.lastPos = { v8_, v9_, v10_ }
	self.distanceMoved = 0
	self.fistTimeChange = true
end

function AIDriveStrategyConveyor:update(dt) end

-- Local values: _, y, z, worldCX, worldCY, worldCZ, distanceMoved, speedFactor, dir
function AIDriveStrategyConveyor:getDriveData(dt, vX, vY, vZ)
	local _, v22_, v23_ = localToLocal(self.vehicle.wheels[self.vehicle.aiConveyorBelt.backWheelIndex].repr, self.vehicle.components[1].node, 0, 0, 0)
	local v24_, v25_, v26_ = localToWorld(self.vehicle.components[1].node, 0, v22_, v23_)
	local v27_ = MathUtil.vector2Length(v24_ - self.lastPos[1], v26_ - self.lastPos[3])
	self.distanceMoved = self.distanceMoved + v27_
	self.lastPos = { v24_, v25_, v26_ }
	if self.distanceMoved >= self.distanceToMove then
		if self.fistTimeChange then
			self.distanceToMove = self.distanceToMove * 2
			self.fistTimeChange = false
		end
		self.distanceMoved = 0
		if self.currentTarget == 1 then
			self.currentTarget = 2
		else
			self.currentTarget = 1
		end
	end
	local v28_ = self.distanceMoved / self.distanceToMove * 3.14
	local v29_ = math.sin(v28_)
	local v30_ = math.clamp(v29_, 0.1, 0.5) * 2
	local v31_ = true
	if self.currentTarget == 2 then
		v31_ = not v31_
	end
	return self.worldTarget[self.currentTarget][1], self.worldTarget[self.currentTarget][3], v31_, self.vehicle.aiConveyorBelt.speed * v30_, 100
end
