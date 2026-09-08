HighPressureWasher = {}

function HighPressureWasher.prerequisitesPresent(specializations)
	return true
end
function HighPressureWasher.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("HighPressureWasher")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.highPressureWasher.animationNodes")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.highPressureWasher.effects")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.highPressureWasher.sounds", "start(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.highPressureWasher.sounds", "stop(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.highPressureWasher.sounds", "work(?)")
	v1_:setXMLSpecializationType()
end

function HighPressureWasher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HighPressureWasher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", HighPressureWasher)
	SpecializationUtil.registerEventListener(vehicleType, "onHandToolStoredInHolder", HighPressureWasher)
	SpecializationUtil.registerEventListener(vehicleType, "onHandToolTakenFromHolder", HighPressureWasher)
end

-- Local values: spec
function HighPressureWasher:onLoad(savegame)
	local v4_ = self.spec_highPressureWasher
	if self.isClient then
		v4_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.highPressureWasher.animationNodes", self.components, self, self.i3dMappings)
		v4_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.highPressureWasher.effects", self.components, self, self.i3dMappings)
		v4_.samples = {}
		v4_.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v4_.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v4_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onDelete", HighPressureWasher)
		SpecializationUtil.removeEventListener(self, "onUpdate", HighPressureWasher)
	end
end

-- Local values: spec
function HighPressureWasher:onDelete()
	local v6_ = self.spec_highPressureWasher
	if self.isClient then
		g_soundManager:deleteSamples(v6_.samples)
		g_animationManager:deleteAnimations(v6_.animationNodes)
		g_effectManager:deleteEffects(v6_.effects)
	end
end

-- Local values: spec
function HighPressureWasher:onHandToolStoredInHolder(handTool, handToolHolder)
	if self.isClient then
		local v8_ = self.spec_highPressureWasher
		g_soundManager:stopSample(v8_.samples.start)
		g_soundManager:stopSample(v8_.samples.work)
		g_soundManager:stopSample(v8_.samples.stop)
		g_soundManager:playSample(v8_.samples.stop)
		g_animationManager:stopAnimations(v8_.animationNodes)
		g_effectManager:stopEffects(v8_.effects)
	end
end

-- Local values: spec
function HighPressureWasher:onHandToolTakenFromHolder(handTool, handToolHolder)
	if self.isClient then
		local v10_ = self.spec_highPressureWasher
		g_soundManager:stopSample(v10_.samples.start)
		g_soundManager:stopSample(v10_.samples.work)
		g_soundManager:stopSample(v10_.samples.stop)
		g_soundManager:playSample(v10_.samples.start)
		g_soundManager:playSample(v10_.samples.work, 0, v10_.samples.start)
		g_animationManager:startAnimations(v10_.animationNodes)
		g_effectManager:startEffects(v10_.effects)
	end
end
