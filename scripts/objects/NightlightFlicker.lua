-- Local values: NightlightFlicker_mt
NightlightFlicker = {}
local NightlightFlicker_mt = Class(NightlightFlicker)

function NightlightFlicker:onCreate(id)
	g_currentMission:addUpdateable(NightlightFlicker.new(id))
end

-- Upvalues: NightlightFlicker_mt
-- Local values: self
function NightlightFlicker.new(id)
	-- upvalues: (copy) NightlightFlicker_mt
	local v4_ = NightlightFlicker_mt
	local v5_ = setmetatable({}, v4_)
	v5_.id = id
	v5_.isVisible = false
	v5_.isFlickerActive = false
	v5_.nextFlicker = 0
	v5_.flickerDuration = 100
	setVisibility(v5_.id, v5_.isVisible)
	g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, v5_.oNWeatherChanged, v5_)
	return v5_
end

function NightlightFlicker:delete()
	g_messageCenter:unsubscribeAll(self)
end

function NightlightFlicker:update(dt)
	if self.isVisible then
		self.nextFlicker = self.nextFlicker - dt
		if self.nextFlicker <= 0 then
			self.isFlickerActive = true
			setVisibility(self.id, false)
			local v9_ = math.random() * 1500 + self.flickerDuration + 10
			self.nextFlicker = math.floor(v9_)
		end
		if self.isFlickerActive then
			self.flickerDuration = self.flickerDuration - dt
			if self.flickerDuration <= 0 then
				self.isFlickerActive = false
				local v10_ = math.random() * 200
				self.flickerDuration = math.floor(v10_)
				setVisibility(self.id, true)
			end
		end
	end
end

function NightlightFlicker:onWeatherChanged()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		local v12_ = g_currentMission.environment.isSunOn
		if v12_ then
			v12_ = not g_currentMission.environment.weather:getIsRaining()
		end
		self.isVisible = not v12_
		setVisibility(self.id, self.isVisible)
	end
end
