-- Local values: AIDebugVehicle_mt
AIDebugVehicle = {}
local AIDebugVehicle_mt = Class(AIDebugVehicle)

-- Upvalues: AIDebugVehicle_mt
-- Local values: self
function AIDebugVehicle.new(vehicle, color, customMt)
	-- upvalues: (copy) AIDebugVehicle_mt
	local v5_ = customMt or AIDebugVehicle_mt
	local v6_ = setmetatable({}, v5_)
	v6_.vehicle = vehicle
	v6_.agentInfo = vehicle.spec_aiDrivable.agentInfo
	v6_.color = color
	v6_.targetFlag = DebugFlag.new():setColorRGBA(color[1], color[2], color[3])
	v6_.paths = {}
	return v6_
end

function AIDebugVehicle:delete() end

-- Local values: path, factor
function AIDebugVehicle:setTarget(x, y, z, dirX, dirY, dirZ)
	local v13_ = DebugPath.newSimple(Color.PRESETS.RED, true, 1, false)
	local v14_ = 0.5 + #self.paths % 2 * 0.5
	v13_:setColorRGBA(self.color[1] * v14_, self.color[2] * v14_, self.color[3] * v14_)
	local v15_ = self.paths
	table.insert(v15_, v13_)
	self.targetFlag:create(x, y, z, dirX or 1, dirZ or 0)
	self:addCurrentPosition()
end

function AIDebugVehicle:update(dt)
	self:addCurrentPosition()
end

-- Local values: aiRootNode, x, y, z
function AIDebugVehicle:addCurrentPosition()
	local v18_ = self.vehicle:getAIRootNode()
	local v19_, v20_, v21_ = getWorldTranslation(v18_)
	self.paths[#self.paths]:addPoint(v19_, v20_, v21_)
end

function AIDebugVehicle:setForcedY(forcedWorldY)
	self.forcedY = forcedWorldY
end

-- Local values: _, path
function AIDebugVehicle:draw()
	for _, v25_ in ipairs(self.paths) do
		v25_:draw(self.forcedY)
	end
	self.targetFlag:draw()
end

-- Local values: _, path
function AIDebugVehicle:clear()
	for _, v27_ in ipairs(self.paths) do
		v27_:clear()
	end
end
