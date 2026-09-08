-- Local values: BoatyardStateLaunching_mt
BoatyardStateLaunching = {}
local BoatyardStateLaunching_mt = Class(BoatyardStateLaunching, BoatyardState)

function BoatyardStateLaunching.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#friction", "")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxSpeed", "")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "splash")
end

-- Upvalues: BoatyardStateLaunching_mt
-- Local values: self
function BoatyardStateLaunching.new(boatyard, customMt)
	-- upvalues: (copy) BoatyardStateLaunching_mt
	local v6_ = BoatyardState.new(boatyard, customMt or BoatyardStateLaunching_mt)
	v6_.speed = 0
	v6_.maxSpeed = 8
	v6_.waterY = -2000
	v6_.friction = 0.0017
	v6_.launchHour = 14
	v6_.launchDayTimeMs = v6_.launchHour * 60 * 60 * 1000
	return v6_
end

-- Local values: baseDirecory, components, i3dMappings
function BoatyardStateLaunching:load(xmlFile, key)
	BoatyardStateLaunching:superClass().load(self, xmlFile, key)
	self.friction = xmlFile:getValue(key .. "#friction", self.friction)
	self.maxSpeed = xmlFile:getValue(key .. "#maxSpeed", self.maxSpeed)
	local v10_ = self.boatyard.baseDirectory
	local v11_ = self.boatyard.components
	local v12_ = self.boatyard.i3dMappings
	self.samples.splash = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "splash", v10_, v11_, 0, AudioGroup.ENVIRONMENT, v12_, self)
end

function BoatyardStateLaunching:isDone()
	return self.done
end

function BoatyardStateLaunching:activate()
	self.done = false
	self.speed = 0
	self.startTime = 0
	self.launching = false
	self.playedSplash = false
	if self.boatyard.isServer then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	end
	self.infoBoxText = g_i18n:getText("infohub_launchingIn")
	self.infoBoxElement = {
		["title"] = "",
		["accentuate"] = true
	}
	BoatyardStateLaunching:superClass().activate(self)
end

function BoatyardStateLaunching:deactivate()
	if self.boatyard.isServer then
		g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
	end
	BoatyardStateLaunching:superClass().deactivate(self)
end

function BoatyardStateLaunching:hourChanged(hour)
	if hour == self.launchHour then
		self.boatyard:raiseActive()
		self.launching = true
		self.startTimeCooldown = g_time + 5000
		g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
	end
end

function BoatyardStateLaunching:raiseActive()
	return self.launching
end

function BoatyardStateLaunching:getPlaySound()
	local v20_ = self.launching
	if v20_ then
		v20_ = not self.playedSplash
	end
	return v20_
end

-- Local values: splineTime, x, y, z, waterDepth, acc, friction, angle
function BoatyardStateLaunching:update(dt)
	if self.launching then
		local v23_ = self.boatyard:getSplineTime()
		if v23_ >= 1 or self.speed < 0.001 and g_time > self.startTimeCooldown then
			self.done = true
		end
		local v24_, v25_, v26_ = getSplinePosition(self.spline, v23_)
		g_currentMission.environmentAreaSystem:getWaterYAtWorldPositionAsync(v24_, v25_, v26_, function(p27_)
			-- upvalues: (copy) self
			self.waterY = p27_ or -2000
		end, nil, nil)
		local v28_ = self.waterY - v25_
		local v29_ = 0
		local v30_ = 0
		local v31_
		if v28_ < 0.1 then
			local v32_ = SplineUtil.getSlopeAngle(self.spline, v23_)
			v29_ = 9.81 * (0.6 * math.sin(v32_)) * dt / 1000
			v31_ = self.friction
		else
			if not self.playedSplash and self.samples.splash ~= nil then
				g_soundManager:playSample(self.samples.splash)
				self.playedSplash = true
			end
			v31_ = v30_ + v28_ / 250
		end
		local v33_ = self.speed + v29_
		local v34_ = self.speed
		self.speed = v33_ - math.sign(v34_) * v31_
		local v35_ = self.speed
		local v36_ = self.maxSpeed * (1 - v23_ ^ 4)
		self.speed = math.clamp(v35_, 0, v36_)
		self.boatyard:addSplineDistanceDelta(self.speed / 1000 * dt)
	end
	BoatyardStateLaunching:superClass().update(self, dt)
end

-- Local values: timeUntilLaunch
function BoatyardStateLaunching:updateInfo(infoTable)
	if not self.launching then
		local v39_
		if self.launchDayTimeMs < g_currentMission.environment.dayTime then
			v39_ = self.launchDayTimeMs + 86400000 - g_currentMission.environment.dayTime
		else
			v39_ = self.launchDayTimeMs - g_currentMission.environment.dayTime
		end
		self.infoBoxElement.title = string.format(self.infoBoxText, g_i18n:formatMinutes(v39_ / 60 / 1000))
		local v40_ = self.infoBoxElement
		table.insert(infoTable, v40_)
	end
end

function BoatyardStateLaunching:getLaunchingSpeedSoundModifier()
	return self.speed / self.maxSpeed
end
g_soundManager:registerModifierType("BOATYARD_LAUNCHING_SPEED", BoatyardStateLaunching.getLaunchingSpeedSoundModifier)
