-- Local values: VehicleShopBase_mt
VehicleShopBase = {}
local VehicleShopBase_mt = Class(VehicleShopBase)

function VehicleShopBase:onCreate(id)
	g_currentMission:addUpdateable(VehicleShopBase.new(id))
end

-- Upvalues: VehicleShopBase_mt
-- Local values: self, dayMinutes
function VehicleShopBase.new(name)
	-- upvalues: (copy) VehicleShopBase_mt
	local v4_ = VehicleShopBase_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = name
	v5_.balloons = getChildAt(v5_.id, 1)
	v5_.alphaBadWeather = 0.4
	v5_.timer = 0
	v5_.updateDelay = 2000
	v5_.alphaCurve = AnimCurve.new(linearInterpolator1)
	v5_.alphaCurve:addKeyframe({
		0.3,
		["time"] = 0
	})
	v5_.alphaCurve:addKeyframe({
		0.3,
		["time"] = 330
	})
	v5_.alphaCurve:addKeyframe({
		0.6,
		["time"] = 360
	})
	v5_.alphaCurve:addKeyframe({
		1,
		["time"] = 420
	})
	v5_.alphaCurve:addKeyframe({
		1,
		["time"] = 1200
	})
	v5_.alphaCurve:addKeyframe({
		0.3,
		["time"] = 1320
	})
	v5_.alphaCurve:addKeyframe({
		0.3,
		["time"] = 1440
	})
	if g_currentMission ~= nil then
		g_currentMission.vehicleShopBase = v5_
		if g_currentMission.environment ~= nil then
			local v6_ = g_currentMission.environment.dayTime / 60000
			setShaderParameter(v5_.balloons, "alpha", v5_.alphaCurve:get(v6_), 0, 0, 0, true)
		end
	end
	setVisibility(v5_.id, false)
	return v5_
end

function VehicleShopBase:delete() end

function VehicleShopBase:update(dt)
	if g_currentMission ~= nil and (g_currentMission.environment ~= nil and getVisibility(self.id)) then
		self.timer = self.timer + dt
		if self.timer > self.updateDelay then
			self.timer = 0
		end
	end
end
