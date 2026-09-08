-- Local values: NightGlower_mt
NightGlower = {}
local NightGlower_mt = Class(NightGlower)

function NightGlower:onCreate(id)
	g_currentMission:addUpdateable(NightGlower.new(id))
end

-- Upvalues: NightGlower_mt
-- Local values: self
function NightGlower.new(id)
	-- upvalues: (copy) NightGlower_mt
	local v4_ = NightGlower_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = id
	v5_.isSunOn = true
	v5_.maxGlow = { 1, 6, 3 }
	v5_.minGlow = { 1, 3, 1 }
	v5_.timer = 0
	setShaderParameter(v5_.id, "colorTint", 1, 1, 1, 1, false)
	g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, v5_.onWeatherChanged, v5_)
	return v5_
end

function NightGlower:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: glowValue, currentGlow
function NightGlower:update(dt)
	if not self.isSunOn then
		self.timer = (self.timer + dt * 0.001) % 6.283185307179586
		local v9_ = self.timer
		local v10_ = (math.sin(v9_) + 1) / 2
		local v11_ = {
			0,
			0,
			0,
			v10_ * self.maxGlow[1] + (1 - v10_) * self.minGlow[1],
			v10_ * self.maxGlow[2] + (1 - v10_) * self.minGlow[2],
			v10_ * self.maxGlow[3] + (1 - v10_) * self.minGlow[3]
		}
		setShaderParameter(self.id, "colorTint", v11_[1], v11_[2], v11_[3], 1, false)
	end
end

function NightGlower:onWeatherChanged()
	self.isSunOn = g_currentMission.environment.isSunOn
	if self.isSunOn then
		setShaderParameter(self.id, "colorTint", 1, 1, 1, 1, false)
	end
end
