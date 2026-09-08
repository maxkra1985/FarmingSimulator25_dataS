source("dataS/scripts/vehicles/specializations/events/AnimatedVehicleStartEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AnimatedVehicleStopEvent.lua")
source("dataS/scripts/vehicles/AnimationValueFloat.lua")
source("dataS/scripts/vehicles/AnimationValueBool.lua")
AnimatedVehicle = {}
AnimatedVehicle.ANIMATION_PART_XML_KEY = "vehicle.animations.animation(?).part(?)"

function AnimatedVehicle.prerequisitesPresent(specializations)
	return true
end
function AnimatedVehicle.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("animation", g_i18n:getText("shop_configuration"), "animations", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("AnimatedVehicle")
	AnimatedVehicle.registerAnimationXMLPaths(v1_, "vehicle.animations.animation(?)")
	AnimatedVehicle.registerAnimationXMLPaths(v1_, "vehicle.animations.animationConfigurations.animationConfiguration(?).animation(?)")
	v1_:register(XMLValueType.STRING, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animName", "Animation name")
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animOuterRange", "Anim limit outer range", false)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animMinLimit", "Min. anim limit", 0)
	v1_:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#animMaxLimit", "Max. anim limit", 1)
	v1_:register(XMLValueType.STRING, WorkArea.WORK_AREA_XML_KEY .. "#animName", "Animation name")
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. "#animMinLimit", "Min. anim limit", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. "#animMaxLimit", "Max. anim limit", 1)
	v1_:register(XMLValueType.STRING, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#animName", "Animation name")
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#animMinLimit", "Min. anim limit", 0)
	v1_:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#animMaxLimit", "Max. anim limit", 1)
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p2_, p3_)
		p2_:register(XMLValueType.STRING, p3_ .. "#requiredAnimation", "Name of the animation that needs to be in a certain range")
		p2_:register(XMLValueType.FLOAT, p3_ .. "#requiredAnimationMinTime", "Min. time of the animation that is allowed for the movingTool update [0-1]", 0)
		p2_:register(XMLValueType.FLOAT, p3_ .. "#requiredAnimationMaxTime", "Max. time of the animation that is allowed for the movingTool update [0-1]", 1)
	end)
	v1_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p4_, p5_)
		p4_:register(XMLValueType.STRING, p5_ .. "#requiredAnimation", "Name of the animation that needs to be in a certain range")
		p4_:register(XMLValueType.FLOAT, p5_ .. "#requiredAnimationMinTime", "Min. time of the animation that is allowed for the movingPart update [0-1]", 0)
		p4_:register(XMLValueType.FLOAT, p5_ .. "#requiredAnimationMaxTime", "Max. time of the animation that is allowed for the movingPart update [0-1]", 1)
	end)
	v1_:setXMLSpecializationType()
end

function AnimatedVehicle.registerAnimationXMLPaths(schema, basePath)
	schema:addDelayedRegistrationPath(basePath, "AnimatedVehicle:animation")
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of animation")
	schema:register(XMLValueType.BOOL, basePath .. "#looping", "Animation is looping", false)
	schema:register(XMLValueType.BOOL, basePath .. "#resetOnStart", "Animation is reset while loading the vehicle", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#startAnimTime", "Animation is set to this time if resetOnStart is set", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#soundVolumeFactor", "Sound volume factor that is applied for all sounds in this animation", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#isKeyframe", "Is static keyframe animation instead of dynamically interpolating animation (Keyframe animations only support trans/rot/scale!)", false)
	schema:addDelayedRegistrationPath(basePath .. ".part(?)", "AnimatedVehicle:part")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".part(?)#node", "Part node")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startTime", "Start time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#duration", "Duration")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endTime", "End time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#time", "Keyframe time (only for keyframe animations)")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#direction", "Part direction", 0)
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#tangentType", "Type of tangent to be used (linear, spline, step)", "linear")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRot", "Start rotation")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRot", "End rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTrans", "Start translation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTrans", "End translation")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".part(?)#startScale", "Start scale")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".part(?)#endScale", "End scale")
	schema:register(XMLValueType.BOOL, basePath .. ".part(?)#visibility", "Visibility")
	schema:register(XMLValueType.BOOL, basePath .. ".part(?)#startVisibility", "Visibility at start time (switched in the middle)")
	schema:register(XMLValueType.BOOL, basePath .. ".part(?)#endVisibility", "Visibility at end time (switched in the middle)")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#componentJointIndex", "Component joint index")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#rotation", "Rotation  (only for keyframe animations)")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#translation", "Translation  (only for keyframe animations)")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".part(?)#scale", "Scale  (only for keyframe animations)")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#requiredAnimation", "Required animation needs to be in a specific range to play part")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".part(?)#requiredAnimationRange", "Animation range of required animation")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#requiredConfigurationName", "This configuration needs to bet set to #requiredConfigurationIndex")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#requiredConfigurationIndex", "Required configuration needs to be in this state to activate the animation part")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRotLimit", "Start rotation limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRotMinLimit", "Start rotation min limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#startRotMaxLimit", "Start rotation max limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRotLimit", "End rotation limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRotMinLimit", "End rotation min limit")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".part(?)#endRotMaxLimit", "End rotation max limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTransLimit", "Start translation limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTransMinLimit", "Start translation min limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startTransMaxLimit", "Start translation max limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTransLimit", "End translation limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTransMinLimit", "End translation min limit")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endTransMaxLimit", "End translation max limit")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".part(?)#startRotLimitSpring", "Start rot limit spring")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".part(?)#startRotLimitDamping", "Start rot limit damping")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".part(?)#endRotLimitSpring", "End rot limit spring")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".part(?)#endRotLimitDamping", "End rot limit damping")
	schema:register(XMLValueType.INT, basePath .. ".part(?)#componentIndex", "Component index")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startMass", "Start mass of component")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#startCenterOfMass", "Start center of mass")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endMass", "End mass of component")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".part(?)#endCenterOfMass", "End center of mass")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startFrictionVelocity", "Start friction velocity applied to node")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endFrictionVelocity", "End friction velocity applied to node")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#shaderParameter", "Shader parameter")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#shaderParameterPrev", "Shader parameter (prev)")
	schema:register(XMLValueType.STRING_LIST, basePath .. ".part(?)#shaderStartValues", "Start shader values")
	schema:register(XMLValueType.STRING_LIST, basePath .. ".part(?)#shaderEndValues", "End shader values")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#animationClip", "Animation clip name")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#clipStartTime", "Animation clip start time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#clipEndTime", "Animation clip end time")
	schema:register(XMLValueType.STRING, basePath .. ".part(?)#dependentAnimation", "Dependent animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#dependentAnimationStartTime", "Dependent animation start time")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#dependentAnimationEndTime", "Dependent animation end time")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".part(?)#spline", "Spline node")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startSplinePos", "Start spline position")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endSplinePos", "End spline position")
	RollingGateAnimation.registerXMLPaths(schema, basePath .. ".part(?).rollingGateAnimation")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#startGatePos", "Start rolling gate position")
	schema:register(XMLValueType.FLOAT, basePath .. ".part(?)#endGatePos", "End rolling gate position")
	SoundManager.registerSampleXMLPaths(schema, basePath, "sound(?)")
	schema:register(XMLValueType.TIME, basePath .. ".sound(?)#startTime", "Start play time", 0)
	schema:register(XMLValueType.TIME, basePath .. ".sound(?)#endTime", "End play time for loops or used on opposite direction")
	schema:register(XMLValueType.INT, basePath .. ".sound(?)#direction", "Direction to play the sound (0 = any direction)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".sound(?)#startPitchScale", "Pitch scale at the start time")
	schema:register(XMLValueType.FLOAT, basePath .. ".sound(?)#endPitchScale", "Pitch scale at the end time")
	SoundManager.registerSampleXMLPaths(schema, basePath, "stopTimePosSound(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath, "stopTimeNegSound(?)")
end

function AnimatedVehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onRegisterAnimationValueTypes")
	SpecializationUtil.registerEvent(vehicleType, "onPlayAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onStartAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onFinishAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onStopAnimation")
	SpecializationUtil.registerEvent(vehicleType, "onAnimationPartChanged")
end

function AnimatedVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "registerAnimationValueType", AnimatedVehicle.registerAnimationValueType)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimation", AnimatedVehicle.loadAnimation)
	SpecializationUtil.registerFunction(vehicleType, "loadAnimationPart", AnimatedVehicle.loadAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "loadStaticAnimationPart", AnimatedVehicle.loadStaticAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "loadStaticAnimationPartValues", AnimatedVehicle.loadStaticAnimationPartValues)
	SpecializationUtil.registerFunction(vehicleType, "initializeAnimationParts", AnimatedVehicle.initializeAnimationParts)
	SpecializationUtil.registerFunction(vehicleType, "initializeAnimationPart", AnimatedVehicle.initializeAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "postInitializeAnimationPart", AnimatedVehicle.postInitializeAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "playAnimation", AnimatedVehicle.playAnimation)
	SpecializationUtil.registerFunction(vehicleType, "stopAnimation", AnimatedVehicle.stopAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationExists", AnimatedVehicle.getAnimationExists)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationByName", AnimatedVehicle.getAnimationByName)
	SpecializationUtil.registerFunction(vehicleType, "getIsAnimationPlaying", AnimatedVehicle.getIsAnimationPlaying)
	SpecializationUtil.registerFunction(vehicleType, "getRealAnimationTime", AnimatedVehicle.getRealAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "setRealAnimationTime", AnimatedVehicle.setRealAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationTime", AnimatedVehicle.getAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationTime", AnimatedVehicle.setAnimationTime)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationDuration", AnimatedVehicle.getAnimationDuration)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationSpeed", AnimatedVehicle.setAnimationSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getAnimationSpeed", AnimatedVehicle.getAnimationSpeed)
	SpecializationUtil.registerFunction(vehicleType, "setAnimationStopTime", AnimatedVehicle.setAnimationStopTime)
	SpecializationUtil.registerFunction(vehicleType, "resetAnimationValues", AnimatedVehicle.resetAnimationValues)
	SpecializationUtil.registerFunction(vehicleType, "resetAnimationPartValues", AnimatedVehicle.resetAnimationPartValues)
	SpecializationUtil.registerFunction(vehicleType, "updateAnimationPart", AnimatedVehicle.updateAnimationPart)
	SpecializationUtil.registerFunction(vehicleType, "getNumOfActiveAnimations", AnimatedVehicle.getNumOfActiveAnimations)
end

function AnimatedVehicle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", AnimatedVehicle.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", AnimatedVehicle.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", AnimatedVehicle.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", AnimatedVehicle.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", AnimatedVehicle.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", AnimatedVehicle.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingPartFromXML", AnimatedVehicle.loadMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingPartActive", AnimatedVehicle.getIsMovingPartActive)
end

function AnimatedVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AnimatedVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", AnimatedVehicle)
end

-- Local values: spec
function AnimatedVehicle:onPreLoad(savegame)
	self.spec_animatedVehicle.animationValueTypes = {}
	SpecializationUtil.raiseEvent(self, "onRegisterAnimationValueTypes")
end

-- Local values: spec, _, key, animation, configurationId, configKey, _, key, animation
function AnimatedVehicle:onLoad(savegame)
	local v14_ = self.spec_animatedVehicle
	v14_.animations = {}
	for _, v15_ in self.xmlFile:iterator("vehicle.animations.animation") do
		local v16_ = {}
		if self:loadAnimation(self.xmlFile, v15_, v16_) then
			v14_.animations[v16_.name] = v16_
		end
	end
	local v17_ = self.configurations.animation or 1
	local v18_ = string.format("vehicle.animations.animationConfigurations.animationConfiguration(%d)", v17_ - 1)
	if self.xmlFile:hasProperty(v18_) then
		for _, v19_ in self.xmlFile:iterator(v18_ .. ".animation") do
			local v20_ = {}
			if self:loadAnimation(self.xmlFile, v19_, v20_) then
				v14_.animations[v20_.name] = v20_
			end
		end
	end
	v14_.activeAnimations = {}
	v14_.numActiveAnimations = 0
	v14_.fixedTimeSamplesDirtyDelay = 0
end

-- Local values: spec, name, animation
function AnimatedVehicle:onPostLoad(savegame)
	local v22_ = self.spec_animatedVehicle
	for v23_, v24_ in pairs(v22_.animations) do
		if v24_.resetOnStart then
			self:setAnimationTime(v23_, 1, true, false)
			self:setAnimationStopTime(v23_, v24_.startTime)
			self:playAnimation(v23_, -1, 1, true, false)
			AnimatedVehicle.updateAnimationByName(self, v23_, 9999999, true)
		end
	end
	if next(v22_.animations) == nil then
		SpecializationUtil.removeEventListener(self, "onUpdate", AnimatedVehicle)
	end
end

-- Local values: spec, _, animation
function AnimatedVehicle:onDelete()
	local v26_ = self.spec_animatedVehicle
	if self.isClient and v26_.animations ~= nil then
		for _, v27_ in pairs(v26_.animations) do
			g_soundManager:deleteSamples(v27_.samples)
			if v27_.eventSamples ~= nil then
				g_soundManager:deleteSamples(v27_.eventSamples.stopTimePos)
				g_soundManager:deleteSamples(v27_.eventSamples.stopTimeNeg)
			end
		end
	end
end

-- Local values: spec, _, animation, i, sample
function AnimatedVehicle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	AnimatedVehicle.updateAnimations(self, dt)
	local v30_ = self.spec_animatedVehicle
	if v30_.fixedTimeSamplesDirtyDelay > 0 then
		v30_.fixedTimeSamplesDirtyDelay = v30_.fixedTimeSamplesDirtyDelay - 1
		if v30_.fixedTimeSamplesDirtyDelay <= 0 then
			for _, v31_ in pairs(v30_.animations) do
				if not table.hasElement(v30_.activeAnimations, v31_) and self.isClient then
					for v32_ = 1, #v31_.samples do
						local v33_ = v31_.samples[v32_]
						if g_soundManager:getIsSamplePlaying(v33_) and v33_.loops == 0 then
							g_soundManager:stopSample(v33_)
						end
					end
				end
			end
			v30_.fixedTimeSamplesDirtyDelay = 0
		end
	end
	if v30_.numActiveAnimations > 0 then
		self:raiseActive()
	end
end

-- Local values: spec, animationValueType
function AnimatedVehicle:registerAnimationValueType(name, startName, endName, initialUpdate, classObject, load, get, set)
	local v43_ = self.spec_animatedVehicle
	if v43_.animationValueTypes[name] == nil then
		v43_.animationValueTypes[name] = {
			["classObject"] = classObject,
			["name"] = name,
			["startName"] = startName,
			["endName"] = endName,
			["initialUpdate"] = initialUpdate,
			["load"] = load,
			["get"] = get,
			["set"] = set
		}
	end
end

-- Local values: name, partI, partKey, animationPart, _, part, _, part, node, curve, i, soundKey, baseKey, sample
function AnimatedVehicle:loadAnimation(xmlFile, key, animation, components)
	local v49_ = xmlFile:getValue(key .. "#name")
	if v49_ == nil then
		return false
	end
	animation.name = v49_
	animation.parts = {}
	animation.currentTime = 0
	animation.previousTime = 0
	animation.currentSpeed = 1
	animation.looping = xmlFile:getValue(key .. "#looping", false)
	animation.resetOnStart = xmlFile:getValue(key .. "#resetOnStart", true)
	animation.soundVolumeFactor = xmlFile:getValue(key .. "#soundVolumeFactor", 1)
	animation.isKeyframe = xmlFile:getValue(key .. "#isKeyframe", false)
	local v50_
	if animation.isKeyframe then
		animation.curvesByNode = {}
		v50_ = 0
	else
		v50_ = 0
	end
	while true do
		local v51_ = key .. string.format(".part(%d)", v50_)
		if not xmlFile:hasProperty(v51_) then
			break
		end
		local v52_ = {}
		if animation.isKeyframe then
			self:loadStaticAnimationPart(xmlFile, v51_, v52_, animation, components)
		elseif self:loadAnimationPart(xmlFile, v51_, v52_, animation, components) then
			local v53_ = animation.parts
			table.insert(v53_, v52_)
		end
		v50_ = v50_ + 1
	end
	animation.partsReverse = {}
	for _, v54_ in ipairs(animation.parts) do
		local v55_ = animation.partsReverse
		table.insert(v55_, v54_)
	end
	table.sort(animation.parts, AnimatedVehicle.animPartSorter)
	table.sort(animation.partsReverse, AnimatedVehicle.animPartSorterReverse)
	self:initializeAnimationParts(animation)
	animation.currentPartIndex = 1
	animation.duration = 0
	for _, v56_ in ipairs(animation.parts) do
		local v57_ = animation.duration
		local v58_ = v56_.startTime + v56_.duration
		animation.duration = math.max(v57_, v58_)
	end
	if animation.isKeyframe then
		for _, v59_ in pairs(animation.curvesByNode) do
			local v60_ = animation.duration
			local v61_ = v59_.maxTime
			animation.duration = math.max(v60_, v61_)
		end
	end
	animation.startTime = xmlFile:getValue(key .. "#startAnimTime", 0)
	animation.currentTime = animation.startTime * animation.duration
	if self.isClient then
		animation.samples = {}
		local v62_ = 0
		while true do
			local v63_ = string.format("sound(%d)", v62_)
			local v64_ = key .. "." .. v63_
			if not xmlFile:hasProperty(v64_) then
				break
			end
			local v65_ = g_soundManager:loadSampleFromXML(xmlFile, key, v63_, self.baseDirectory, components or self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
			if v65_ ~= nil then
				v65_.startTime = xmlFile:getValue(v64_ .. "#startTime", 0)
				v65_.endTime = xmlFile:getValue(v64_ .. "#endTime")
				v65_.direction = xmlFile:getValue(v64_ .. "#direction", 0)
				v65_.startPitchScale = xmlFile:getValue(v64_ .. "#startPitchScale")
				v65_.endPitchScale = xmlFile:getValue(v64_ .. "#endPitchScale")
				if v65_.startPitchScale ~= nil and v65_.endPitchScale == nil or v65_.startPitchScale == nil and v65_.endPitchScale ~= nil then
					v65_.startPitchScale = nil
					v65_.endPitchScale = nil
					Logging.xmlWarning(xmlFile, "Animation sound requires both, startPitchScale and endPitchScale, not only one. (%s)", v64_)
				end
				if v65_.endTime == nil and v65_.loops == 0 then
					v65_.loops = 1
				end
				g_soundManager:setSampleVolumeScale(v65_, g_soundManager:getSampleVolumeScale(v65_) * animation.soundVolumeFactor)
				local v66_ = animation.samples
				table.insert(v66_, v65_)
			end
			v62_ = v62_ + 1
		end
		xmlFile:iterate(key .. ".stopTimePosSound", function(p67_, _)
			-- upvalues: (copy) xmlFile, (copy) key, (copy) self, (copy) components, (copy) animation
			local v68_ = g_soundManager:loadSampleFromXML(xmlFile, key, string.format("stopTimePosSound(%d)", p67_ - 1), self.baseDirectory, components or self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
			if v68_ ~= nil then
				animation.eventSamples = animation.eventSamples or {}
				animation.eventSamples.stopTimePos = animation.eventSamples.stopTimePos or {}
				local v69_ = animation.eventSamples.stopTimePos
				table.insert(v69_, v68_)
			end
		end)
		xmlFile:iterate(key .. ".stopTimeNegSound", function(p70_, _)
			-- upvalues: (copy) xmlFile, (copy) key, (copy) self, (copy) components, (copy) animation
			local v71_ = g_soundManager:loadSampleFromXML(xmlFile, key, string.format("stopTimeNegSound(%d)", p70_ - 1), self.baseDirectory, components or self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
			if v71_ ~= nil then
				animation.eventSamples = animation.eventSamples or {}
				animation.eventSamples.stopTimeNeg = animation.eventSamples.stopTimeNeg or {}
				local v72_ = animation.eventSamples.stopTimeNeg
				table.insert(v72_, v71_)
			end
		end)
	end
	return true
end

-- Local values: startTime, duration, endTime, direction, spec, _, animationValueType, animationValueObject, requiredAnimation, requiredAnimationRange, requiredConfigurationName, requiredConfigurationIndex, i
function AnimatedVehicle:loadAnimationPart(xmlFile, partKey, part, animation, components)
	local v79_ = xmlFile:getValue(partKey .. "#startTime")
	local v80_ = xmlFile:getValue(partKey .. "#duration")
	local v81_ = xmlFile:getValue(partKey .. "#endTime")
	local v82_ = xmlFile:getValue(partKey .. "#direction", 0)
	local v83_ = math.sign(v82_)
	part.components = components or self.components
	part.i3dMappings = self.i3dMappings
	part.animationValues = {}
	local v84_ = self.spec_animatedVehicle
	for _, v85_ in pairs(v84_.animationValueTypes) do
		local v86_ = v85_.classObject.new(self, animation, part, v85_.startName, v85_.endName, v85_.name, v85_.initialUpdate, v85_.get, v85_.set, v85_.load)
		if v86_:load(xmlFile, partKey) then
			local v87_ = part.animationValues
			table.insert(v87_, v86_)
		end
	end
	local v88_ = xmlFile:getValue(partKey .. "#requiredAnimation")
	local v89_ = xmlFile:getValue(partKey .. "#requiredAnimationRange", nil, true)
	local v90_ = xmlFile:getValue(partKey .. "#requiredConfigurationName")
	local v91_ = xmlFile:getValue(partKey .. "#requiredConfigurationIndex")
	for v92_ = 1, #part.animationValues do
		part.animationValues[v92_].requiredAnimation = v88_
		part.animationValues[v92_]:addCompareParameters("requiredAnimation")
		if v89_ ~= nil then
			part.animationValues[v92_].requiredAnimationRange = string.format("%.2f %.2f", v89_[1], v89_[2])
			part.animationValues[v92_]:addCompareParameters("requiredAnimationRange")
		end
		part.animationValues[v92_].requiredConfigurationName = v90_
		part.animationValues[v92_]:addCompareParameters("requiredConfigurationName")
		part.animationValues[v92_].requiredConfigurationIndex = v91_
		part.animationValues[v92_]:addCompareParameters("requiredConfigurationIndex")
	end
	if #part.animationValues == 0 then
		return false
	end
	if v79_ == nil or v80_ == nil and v81_ == nil then
		return false
	end
	if v81_ ~= nil then
		v80_ = v81_ - v79_
	end
	part.startTime = v79_ * 1000
	part.duration = v80_ * 1000
	part.direction = v83_
	part.requiredAnimation = v88_
	part.requiredAnimationRange = v89_
	part.requiredConfigurationName = v90_
	part.requiredConfigurationIndex = v91_
	return true
end

-- Local values: node, time, startTime, endTime, curve
function AnimatedVehicle:loadStaticAnimationPart(xmlFile, partKey, part, animation, components)
	local v97_ = xmlFile:getValue(partKey .. "#node", nil, self.components, self.i3dMappings)
	if v97_ == nil then
		return false
	end
	local v98_ = xmlFile:getValue(partKey .. "#time")
	local v99_ = xmlFile:getValue(partKey .. "#startTime")
	local v100_ = xmlFile:getValue(partKey .. "#endTime")
	if animation.curvesByNode[v97_] == nil then
		animation.curvesByNode[v97_] = AnimCurve.new(linearInterpolatorTransRotScale)
	end
	local v101_ = animation.curvesByNode[v97_]
	if v98_ == nil then
		if v99_ ~= nil or v100_ ~= nil then
			if v99_ ~= nil then
				local v102_ = v99_ * 1000
				if v101_.maxTime == 0 or v101_.maxTime ~= v102_ then
					self:loadStaticAnimationPartValues(xmlFile, partKey, v101_, v97_, "startTrans", "startRot", "startScale", v102_, animation)
				end
			end
			if v100_ ~= nil then
				local v103_ = v100_ * 1000
				if v101_.maxTime == 0 or v101_.maxTime ~= v103_ then
					self:loadStaticAnimationPartValues(xmlFile, partKey, v101_, v97_, "endTrans", "endRot", "endScale", v103_, animation)
				end
			end
		end
	else
		self:loadStaticAnimationPartValues(xmlFile, partKey, v101_, v97_, "translation", "rotation", "scale", v98_ * 1000, animation)
	end
	return true
end

-- Local values: hasTranslation, hasRotation, hasScale, x, y, z, rx, ry, rz, sx, sy, sz
function AnimatedVehicle:loadStaticAnimationPartValues(xmlFile, partKey, curve, node, transName, rotName, scaleName, time, animation)
	local v113_ = false
	local v114_ = false
	local v115_ = false
	local v116_, v117_, v118_ = xmlFile:getValue(partKey .. "#" .. transName)
	if v116_ == nil then
		v116_, v117_, v118_ = getTranslation(node)
	else
		v113_ = true
	end
	local v119_, v120_, v121_ = xmlFile:getValue(partKey .. "#" .. rotName)
	if v119_ == nil then
		v119_, v120_, v121_ = getRotation(node)
	else
		v114_ = true
	end
	local v122_, v123_, v124_ = xmlFile:getValue(partKey .. "#" .. scaleName)
	if v122_ == nil then
		v122_, v123_, v124_ = getScale(node)
	else
		v115_ = true
	end
	if v113_ or (v114_ or v115_) then
		if curve.hasTranslation == nil or (curve.hasRotation == nil or curve.hasScale == nil) then
			curve.hasTranslation = v113_
			curve.hasRotation = v114_
			curve.hasScale = v115_
		elseif curve.hasTranslation ~= v113_ or (curve.hasRotation ~= v114_ or curve.hasScale ~= v115_) then
			Logging.xmlWarning(xmlFile, "All animation parts for node \'%s\' require the same attributes (translation/rotation/scale) in animation \'%s\'! \'%s\'", getName(node), animation.name, partKey)
		end
	end
	curve:addKeyframe({
		["x"] = v116_,
		["y"] = v117_,
		["z"] = v118_,
		["rx"] = v119_,
		["ry"] = v120_,
		["rz"] = v121_,
		["sx"] = v122_,
		["sy"] = v123_,
		["sz"] = v124_,
		["time"] = time
	})
end

-- Local values: numParts, i, part, i, part
function AnimatedVehicle:initializeAnimationParts(animation)
	local v127_ = #animation.parts
	for v128_, v129_ in ipairs(animation.parts) do
		self:initializeAnimationPart(animation, v129_, v128_, v127_)
	end
	for v130_, v131_ in ipairs(animation.parts) do
		self:postInitializeAnimationPart(animation, v131_, v130_, v127_)
	end
end

-- Local values: index
function AnimatedVehicle:initializeAnimationPart(animation, part, i, numParts)
	for v135_ = 1, #part.animationValues do
		part.animationValues[v135_]:init(i, numParts)
	end
end

-- Local values: index
function AnimatedVehicle:postInitializeAnimationPart(animation, part, i, numParts)
	for v137_ = 1, #part.animationValues do
		part.animationValues[v137_]:postInit()
	end
end

-- Local values: spec, animation
function AnimatedVehicle:playAnimation(name, speed, animTime, noEventSend, allowSounds)
	local v143_ = self.spec_animatedVehicle
	local v144_ = v143_.animations[name]
	if v144_ ~= nil then
		SpecializationUtil.raiseEvent(self, "onPlayAnimation", name)
		if speed == nil then
			speed = v144_.currentSpeed
		end
		if speed == nil or speed == 0 then
			return
		end
		if animTime == nil then
			if self:getIsAnimationPlaying(name) then
				animTime = self:getAnimationTime(name)
			else
				animTime = speed > 0 and 0 or 1
			end
		end
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(AnimatedVehicleStartEvent.new(self, name, speed, animTime))
			else
				g_server:broadcastEvent(AnimatedVehicleStartEvent.new(self, name, speed, animTime), nil, nil, self)
			end
		end
		if not table.hasElement(v143_.activeAnimations, v144_) then
			table.addElement(v143_.activeAnimations, v144_)
			v143_.numActiveAnimations = v143_.numActiveAnimations + 1
			SpecializationUtil.raiseEvent(self, "onStartAnimation", name, speed)
		end
		v144_.currentSpeed = speed
		v144_.currentTime = animTime * v144_.duration
		self:resetAnimationValues(v144_)
		self:raiseActive()
	end
end

-- Local values: spec, animation, i, sample
function AnimatedVehicle:stopAnimation(name, noEventSend)
	local v148_ = self.spec_animatedVehicle
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(AnimatedVehicleStopEvent.new(self, name))
		else
			g_server:broadcastEvent(AnimatedVehicleStopEvent.new(self, name), nil, nil, self)
		end
	end
	local v149_ = v148_.animations[name]
	if v149_ ~= nil then
		SpecializationUtil.raiseEvent(self, "onStopAnimation", name)
		v149_.stopTime = nil
		if self.isClient then
			for v150_ = 1, #v149_.samples do
				local v151_ = v149_.samples[v150_]
				if v151_.loops == 0 then
					g_soundManager:stopSample(v151_)
				end
			end
		end
	end
	if table.hasElement(v148_.activeAnimations, v149_) then
		table.removeElement(v148_.activeAnimations, v149_)
		v148_.numActiveAnimations = v148_.numActiveAnimations - 1
		SpecializationUtil.raiseEvent(self, "onFinishAnimation", name)
	end
end

-- Local values: spec
function AnimatedVehicle:getAnimationExists(name)
	return self.spec_animatedVehicle.animations[name] ~= nil
end

function AnimatedVehicle:getAnimationByName(name)
	return self.spec_animatedVehicle.animations[name]
end

-- Local values: spec, animation
function AnimatedVehicle:getIsAnimationPlaying(name)
	local v158_ = self.spec_animatedVehicle
	local v159_ = v158_.animations[name]
	return table.hasElement(v158_.activeAnimations, v159_)
end

-- Local values: spec, animation
function AnimatedVehicle:getRealAnimationTime(name)
	local v162_ = self.spec_animatedVehicle.animations[name]
	return v162_ == nil and 0 or v162_.currentTime
end

-- Local values: spec, animation, currentSpeed, dtToUse, _
function AnimatedVehicle:setRealAnimationTime(name, animTime, update, playSounds)
	local v168_ = self.spec_animatedVehicle.animations[name]
	if v168_ ~= nil then
		if update == nil or update then
			local v169_ = v168_.currentSpeed
			v168_.currentSpeed = 1
			if animTime < v168_.currentTime then
				v168_.currentSpeed = -1
			end
			self:resetAnimationValues(v168_)
			local v170_, _ = AnimatedVehicle.updateAnimationCurrentTime(self, v168_, 99999999, animTime)
			AnimatedVehicle.updateAnimation(self, v168_, v170_, true, true, playSounds)
			v168_.currentSpeed = v169_
			return
		end
		v168_.currentTime = animTime
	end
end

-- Local values: spec, animation
function AnimatedVehicle:getAnimationTime(name)
	local v173_ = self.spec_animatedVehicle.animations[name]
	return (v173_ == nil or v173_.duration <= 0) and 0 or v173_.currentTime / v173_.duration
end

-- Local values: spec, animation
function AnimatedVehicle:setAnimationTime(name, animTime, update, playSounds)
	local v179_ = self.spec_animatedVehicle
	if v179_.animations == nil then
		printCallstack()
	end
	local v180_ = v179_.animations[name]
	if v180_ ~= nil then
		self:setRealAnimationTime(name, animTime * v180_.duration, update, playSounds)
	end
end

-- Local values: spec, animation
function AnimatedVehicle:getAnimationDuration(name)
	local v183_ = self.spec_animatedVehicle.animations[name]
	return v183_ == nil and 1 or v183_.duration
end

-- Local values: spec, animation, speedReversed
function AnimatedVehicle:setAnimationSpeed(name, speed)
	local v187_ = self.spec_animatedVehicle.animations[name]
	if v187_ ~= nil then
		local v188_ = v187_.currentSpeed > 0 ~= (speed > 0) and true or false
		v187_.currentSpeed = speed
		if self:getIsAnimationPlaying(name) and v188_ then
			self:resetAnimationValues(v187_)
		end
	end
end

-- Local values: spec, animation
function AnimatedVehicle:getAnimationSpeed(name)
	local v191_ = self.spec_animatedVehicle.animations[name]
	return v191_ == nil and 0 or v191_.currentSpeed
end

-- Local values: spec, animation
function AnimatedVehicle:setAnimationStopTime(name, stopTime)
	local v195_ = self.spec_animatedVehicle.animations[name]
	if v195_ ~= nil then
		v195_.stopTime = stopTime * v195_.duration
	end
end

-- Local values: _, part
function AnimatedVehicle:resetAnimationValues(animation)
	AnimatedVehicle.findCurrentPartIndex(animation)
	for _, v198_ in ipairs(animation.parts) do
		self:resetAnimationPartValues(v198_)
	end
end

-- Local values: index
function AnimatedVehicle:resetAnimationPartValues(part)
	for v200_ = 1, #part.animationValues do
		part.animationValues[v200_]:reset()
	end
end

function AnimatedVehicle:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	speedRotatingPart.animName = xmlFile:getValue(key .. "#animName")
	speedRotatingPart.animOuterRange = xmlFile:getValue(key .. "#animOuterRange", false)
	speedRotatingPart.animMinLimit = xmlFile:getValue(key .. "#animMinLimit", 0)
	speedRotatingPart.animMaxLimit = xmlFile:getValue(key .. "#animMaxLimit", 1)
	return true
end

-- Local values: animTime
function AnimatedVehicle:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.animName ~= nil then
		local v209_ = self:getAnimationTime(speedRotatingPart.animName)
		if speedRotatingPart.animOuterRange then
			if speedRotatingPart.animMinLimit < v209_ or v209_ < speedRotatingPart.animMaxLimit then
				return false
			end
		elseif speedRotatingPart.animMaxLimit < v209_ or v209_ < speedRotatingPart.animMinLimit then
			return false
		end
	end
	return superFunc(self, speedRotatingPart)
end

function AnimatedVehicle:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	workArea.animName = xmlFile:getValue(key .. "#animName")
	workArea.animMinLimit = xmlFile:getValue(key .. "#animMinLimit", 0)
	workArea.animMaxLimit = xmlFile:getValue(key .. "#animMaxLimit", 1)
	return superFunc(self, workArea, xmlFile, key)
end

-- Local values: animTime
function AnimatedVehicle:getIsWorkAreaActive(superFunc, workArea)
	if workArea.animName ~= nil then
		local v218_ = self:getAnimationTime(workArea.animName)
		if workArea.animMaxLimit < v218_ or v218_ < workArea.animMinLimit then
			return false
		end
	end
	return superFunc(self, workArea)
end

function AnimatedVehicle:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.requiredAnimation = xmlFile:getValue(key .. "#requiredAnimation")
	if entry.requiredAnimation ~= nil then
		entry.requiredAnimationMin = xmlFile:getValue(key .. "#requiredAnimationMinTime", 0)
		entry.requiredAnimationMax = xmlFile:getValue(key .. "#requiredAnimationMaxTime", 1)
	end
	return true
end

-- Local values: animationTime
function AnimatedVehicle:getIsMovingToolActive(superFunc, movingTool)
	if movingTool.requiredAnimation ~= nil then
		local v227_ = self:getAnimationTime(movingTool.requiredAnimation)
		if v227_ < movingTool.requiredAnimationMin or movingTool.requiredAnimationMax < v227_ then
			return false
		end
	end
	return superFunc(self, movingTool)
end

function AnimatedVehicle:loadMovingPartFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.requiredAnimation = xmlFile:getValue(key .. "#requiredAnimation")
	if entry.requiredAnimation ~= nil then
		entry.requiredAnimationMin = xmlFile:getValue(key .. "#requiredAnimationMinTime", 0)
		entry.requiredAnimationMax = xmlFile:getValue(key .. "#requiredAnimationMaxTime", 1)
	end
	return true
end

-- Local values: animationTime
function AnimatedVehicle:getIsMovingPartActive(superFunc, movingPart)
	if movingPart.requiredAnimation ~= nil then
		local v236_ = self:getAnimationTime(movingPart.requiredAnimation)
		if v236_ < movingPart.requiredAnimationMin or movingPart.requiredAnimationMax < v236_ then
			return false
		end
	end
	return superFunc(self, movingPart)
end

-- Local values: j, part2, additionalCompare, sameRequiredRange, n, v, sameConfiguration
function AnimatedVehicle:initializeAnimationPartAttribute(animation, part, i, numParts, nextName, prevName, startName, endName, warningName, startName2, endName2, additionalCompareParam)
	if part[endName] ~= nil then
		for v250_ = i + 1, numParts do
			local v251_ = animation.parts[v250_]
			local v252_ = additionalCompareParam == nil or part[additionalCompareParam] == v251_[additionalCompareParam]
			local v253_ = true
			if part.requiredAnimation ~= nil and part.requiredAnimation == v251_.requiredAnimation then
				for v254_, v255_ in ipairs(part.requiredAnimationRange) do
					if v251_.requiredAnimationRange[v254_] ~= v255_ then
						v253_ = false
					end
				end
			end
			local v256_ = part.requiredConfigurationName == nil or (part.requiredConfigurationName ~= v251_.requiredConfigurationName or part.requiredConfigurationIndex == v251_.requiredConfigurationIndex)
			if part.direction == v251_.direction and (part.node == v251_.node and (v251_[endName] ~= nil and (v252_ and (v253_ and v256_)))) then
				if part.direction == v251_.direction and part.startTime + part.duration > v251_.startTime + 0.001 then
					Logging.xmlWarning(self.xmlFile, "Overlapping %s parts for node \'%s\' in animation \'%s\'", warningName, getName(part.node), animation.name)
				end
				part[nextName] = v251_
				v251_[prevName] = part
				if v251_[startName] == nil then
					local v257_ = {}
					local v258_ = part[endName]
					__set_list(v257_, 1, {unpack(v258_)})
					v251_[startName] = v257_
				end
				if startName2 ~= nil and (endName2 ~= nil and v251_[startName2] == nil) then
					local v259_ = {}
					local v260_ = part[endName2]
					__set_list(v259_, 1, {unpack(v260_)})
					v251_[startName2] = v259_
					return
				end
				break
			end
		end
	end
end

function AnimatedVehicle.animPartSorter(a, b)
	if a.startTime < b.startTime then
		return true
	elseif a.startTime == b.startTime then
		return a.duration < b.duration
	else
		return false
	end
end

-- Local values: endTimeA, endTimeB
function AnimatedVehicle.animPartSorterReverse(a, b)
	local v265_ = a.startTime + a.duration
	local v266_ = b.startTime + b.duration
	if v266_ < v265_ then
		return true
	elseif v265_ == v266_ then
		return a.startTime > b.startTime
	else
		return false
	end
end

-- Local values: limitF
function AnimatedVehicle.getMovedLimitedValue(currentValue, destValue, speed, dt)
	if destValue == currentValue then
		return currentValue
	else
		return (destValue < currentValue and math.max or math.min)(currentValue + speed * dt, destValue)
	end
end

-- Local values: hasChanged, i, newValue
function AnimatedVehicle.setMovedLimitedValuesN(n, currentValues, destValues, speeds, dt)
	local v276_ = false
	for v277_ = 1, n do
		local v278_ = AnimatedVehicle.getMovedLimitedValue(currentValues[v277_], destValues[v277_], speeds[v277_], dt)
		if currentValues[v277_] ~= v278_ then
			currentValues[v277_] = v278_
			v276_ = true
		end
	end
	return v276_
end

function AnimatedVehicle.setMovedLimitedValues3(currentValues, destValues, speeds, dt)
	return AnimatedVehicle.setMovedLimitedValuesN(3, currentValues, destValues, speeds, dt)
end

function AnimatedVehicle.setMovedLimitedValues4(currentValues, destValues, speeds, dt)
	return AnimatedVehicle.setMovedLimitedValuesN(4, currentValues, destValues, speeds, dt)
end

-- Local values: i, part, i, part
function AnimatedVehicle.findCurrentPartIndex(animation)
	if animation.currentSpeed > 0 then
		animation.currentPartIndex = #animation.parts + 1
		for v288_, v289_ in ipairs(animation.parts) do
			if v289_.startTime + v289_.duration >= animation.currentTime then
				animation.currentPartIndex = v288_
				return
			end
		end
	else
		animation.currentPartIndex = #animation.partsReverse + 1
		for v290_, v291_ in ipairs(animation.partsReverse) do
			if v291_.startTime <= animation.currentTime then
				animation.currentPartIndex = v290_
				return
			end
		end
	end
end

function AnimatedVehicle.getDurationToEndOfPart(part, anim)
	if anim.currentSpeed > 0 then
		return part.startTime + part.duration - anim.currentTime
	else
		return anim.currentTime - part.startTime
	end
end

function AnimatedVehicle.getNextPartIsPlaying(nextPart, prevPart, anim, default)
	if anim.currentSpeed > 0 then
		if nextPart ~= nil then
			return nextPart.startTime > anim.currentTime
		end
	elseif prevPart ~= nil then
		return prevPart.startTime + prevPart.duration < anim.currentTime
	end
	return default
end

-- Local values: spec, i, animation, dtToUse, stopAnim
function AnimatedVehicle:updateAnimations(dt, fixedTimeUpdate)
	local v301_ = self.spec_animatedVehicle
	for v302_ = #v301_.activeAnimations, 1, -1 do
		local v303_ = v301_.activeAnimations[v302_]
		local v304_, v305_ = AnimatedVehicle.updateAnimationCurrentTime(self, v303_, dt, v303_.stopTime)
		AnimatedVehicle.updateAnimation(self, v303_, v304_, v305_, fixedTimeUpdate)
	end
end

-- Local values: spec, anim, dtToUse, stopAnim
function AnimatedVehicle:updateAnimationByName(animName, dt, fixedTimeUpdate)
	local v310_ = self.spec_animatedVehicle.animations[animName]
	if v310_ ~= nil then
		local v311_, v312_ = AnimatedVehicle.updateAnimationCurrentTime(self, v310_, dt, v310_.stopTime)
		AnimatedVehicle.updateAnimation(self, v310_, v311_, v312_, fixedTimeUpdate)
	end
end

-- Local values: absSpeed, dtToUse, stopAnim
function AnimatedVehicle:updateAnimationCurrentTime(anim, dt, stopTime)
	anim.previousTime = anim.currentTime
	anim.currentTime = anim.currentTime + dt * anim.currentSpeed
	local v316_ = anim.currentSpeed
	local v317_ = dt * math.abs(v316_)
	local v318_ = false
	if stopTime ~= nil then
		if anim.currentSpeed > 0 then
			if stopTime <= anim.currentTime then
				local v319_ = v317_ - (anim.currentTime - stopTime)
				anim.currentTime = stopTime
				return v319_, true
			end
		elseif anim.currentTime <= stopTime then
			v317_ = v317_ - (stopTime - anim.currentTime)
			anim.currentTime = stopTime
			v318_ = true
		end
	end
	return v317_, v318_
end

-- Local values: spec, isStopTimeStop, numParts, parts, hasChanged, nothingToChangeYet, partI, part, isInRange, time, sameConfiguration, durationToEnd, realDt, startT, startT, endTime, node, curve, x, y, z, rx, ry, rz, sx, sy, sz, i, sample, alpha, inRange, allowLooping, i, sample, i, i
function AnimatedVehicle:updateAnimation(anim, dtToUse, stopAnim, fixedTimeUpdate, playSounds)
	local v326_ = self.spec_animatedVehicle
	local v327_ = #anim.parts
	local v328_ = anim.parts
	if anim.currentSpeed < 0 then
		v328_ = anim.partsReverse
	end
	local v329_
	if dtToUse > 0 then
		local v330_ = false
		local v331_ = false
		if anim.isKeyframe then
			for v332_, v333_ in pairs(anim.curvesByNode) do
				local v334_, v335_, v336_, v337_, v338_, v339_, v340_, v341_, v342_ = v333_:get(anim.currentTime)
				if v333_.hasTranslation then
					setTranslation(v332_, v334_, v335_, v336_)
				end
				if v333_.hasRotation then
					setRotation(v332_, v337_, v338_, v339_)
				end
				if v333_.hasScale then
					setScale(v332_, v340_, v341_, v342_)
				end
				SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", v332_)
			end
			v329_ = anim.currentTime <= 0 and true or anim.currentTime >= anim.duration
		else
			local v343_ = stopAnim
			for v344_ = anim.currentPartIndex, v327_ do
				local v345_ = v328_[v344_]
				local v346_ = true
				if v345_.requiredAnimation ~= nil then
					local v347_ = self:getAnimationTime(v345_.requiredAnimation)
					if v347_ < v345_.requiredAnimationRange[1] or v345_.requiredAnimationRange[2] < v347_ then
						v346_ = false
					end
				end
				local v348_ = v345_.requiredConfigurationName == nil or (self.configurations[v345_.requiredConfigurationName] == nil or self.configurations[v345_.requiredConfigurationName] == v345_.requiredConfigurationIndex)
				if (v345_.direction == 0 or v345_.direction > 0 == (anim.currentSpeed >= 0)) and (v346_ and v348_) then
					local v349_ = AnimatedVehicle.getDurationToEndOfPart(v345_, anim)
					if v345_.duration < v349_ then
						v331_ = true
						break
					end
					local v350_
					if anim.currentSpeed > 0 then
						local v351_ = anim.currentTime - dtToUse
						if v351_ < v345_.startTime then
							v350_ = dtToUse - v345_.startTime + v351_
						else
							v350_ = dtToUse
						end
					else
						local v352_ = anim.currentTime + dtToUse
						local v353_ = v345_.startTime + v345_.duration
						if v353_ < v352_ then
							v350_ = dtToUse - (v352_ - v353_)
						else
							v350_ = dtToUse
						end
					end
					v330_ = self:updateAnimationPart(anim, v345_, v349_ + v350_, dtToUse, v350_, fixedTimeUpdate) and true or v330_
				end
				if v344_ == anim.currentPartIndex and (anim.currentSpeed > 0 and v345_.startTime + v345_.duration < anim.currentTime or anim.currentSpeed <= 0 and v345_.startTime > anim.currentTime) then
					self:resetAnimationPartValues(v345_)
					anim.currentPartIndex = anim.currentPartIndex + 1
				end
			end
			if v331_ or (v330_ or v327_ > anim.currentPartIndex) then
				v329_ = stopAnim
				stopAnim = v343_
			else
				anim.previousTime = anim.currentTime
				if anim.currentSpeed > 0 then
					anim.currentTime = anim.duration
					stopAnim = v343_
					v329_ = true
				else
					anim.currentTime = 0
					stopAnim = v343_
					v329_ = true
				end
			end
		end
		if table.hasElement(v326_.activeAnimations, anim) or playSounds == true then
			if fixedTimeUpdate ~= true or playSounds == true then
				for v354_ = 1, #anim.samples do
					local v355_ = anim.samples[v354_]
					if g_soundManager:getIsSamplePlaying(v355_) then
						if v355_.endTime ~= nil then
							if v355_.startPitchScale ~= nil then
								local v356_ = MathUtil.inverseLerp(v355_.startTime, v355_.endTime, anim.currentTime)
								v355_.pitchScale = (v355_.endPitchScale - v355_.startPitchScale) * v356_ + v355_.startPitchScale
							end
							if anim.currentSpeed > 0 then
								if anim.currentTime > v355_.endTime then
									g_soundManager:stopSample(v355_)
								end
							elseif anim.currentTime < v355_.startTime then
								g_soundManager:stopSample(v355_)
							end
							if v355_.direction ~= 0 and v355_.direction >= 0 ~= (anim.currentSpeed >= 0) then
								g_soundManager:stopSample(v355_)
							end
						end
					elseif v355_.direction == 0 or v355_.direction >= 0 == (anim.currentSpeed >= 0) then
						if v355_.loops == 0 then
							v355_.readyToStart = true
						elseif v355_.endTime == nil then
							if anim.currentSpeed < 0 then
								v355_.readyToStart = anim.previousTime > v355_.startTime
							else
								v355_.readyToStart = anim.previousTime < v355_.startTime
							end
						else
							v355_.readyToStart = anim.previousTime < v355_.startTime and true or anim.previousTime > v355_.endTime
						end
						local v357_ = anim.currentTime >= v355_.startTime
						if v355_.endTime == nil then
							if anim.currentSpeed < 0 then
								v357_ = anim.currentTime <= v355_.startTime
							end
						elseif anim.currentTime >= v355_.startTime then
							v357_ = anim.currentTime <= v355_.endTime
						else
							v357_ = false
						end
						if v355_.readyToStart and v357_ then
							g_soundManager:playSample(v355_)
						end
					end
				end
			end
			SpecializationUtil.raiseEvent(self, "onUpdateAnimation", anim.name)
			if not table.hasElement(v326_.activeAnimations, anim) then
				v326_.fixedTimeSamplesDirtyDelay = 2
			end
		end
	else
		v329_ = stopAnim
	end
	if v329_ or v327_ > 0 and (v327_ < anim.currentPartIndex or anim.currentPartIndex < 1) then
		anim.previousTime = anim.currentTime
		if not v329_ then
			if anim.currentSpeed > 0 then
				anim.currentTime = anim.duration
			else
				anim.currentTime = 0
			end
		end
		local v358_ = anim.currentTime
		local v359_ = math.max(v358_, 0)
		local v360_ = anim.duration
		anim.currentTime = math.min(v359_, v360_)
		local v361_ = anim.stopTime ~= anim.currentTime
		anim.stopTime = nil
		if table.hasElement(v326_.activeAnimations, anim) then
			if self.isClient then
				for v362_ = 1, #anim.samples do
					local v363_ = anim.samples[v362_]
					if v363_.loops == 0 then
						g_soundManager:stopSample(v363_)
					end
				end
				if stopAnim and anim.eventSamples ~= nil then
					if anim.currentSpeed > 0 then
						if anim.eventSamples.stopTimePos ~= nil then
							for v364_ = 1, #anim.eventSamples.stopTimePos do
								g_soundManager:playSample(anim.eventSamples.stopTimePos[v364_])
							end
						end
					elseif anim.eventSamples.stopTimeNeg ~= nil then
						for v365_ = 1, #anim.eventSamples.stopTimeNeg do
							g_soundManager:playSample(anim.eventSamples.stopTimeNeg[v365_])
						end
					end
				end
			end
			table.removeElement(v326_.activeAnimations, anim)
			v326_.numActiveAnimations = v326_.numActiveAnimations - 1
			SpecializationUtil.raiseEvent(self, "onFinishAnimation", anim.name)
		end
		if v361_ and (fixedTimeUpdate ~= true and anim.looping) then
			local v366_ = anim.name
			local v367_ = anim.currentTime
			local v368_ = anim.duration
			local v369_ = v367_ / math.max(v368_, 0.0001) - 1
			self:setAnimationTime(v366_, math.abs(v369_), true)
			self:playAnimation(anim.name, anim.currentSpeed, nil, true)
		end
	end
end

-- Local values: hasPartChanged, index, valueChanged
function AnimatedVehicle:updateAnimationPart(animation, part, durationToEnd, dtToUse, realDt, fixedTimeUpdate)
	local v375_ = false
	for v376_ = 1, #part.animationValues do
		v375_ = v375_ or part.animationValues[v376_]:update(durationToEnd, dtToUse, realDt, fixedTimeUpdate)
	end
	return v375_
end

function AnimatedVehicle:getNumOfActiveAnimations()
	return self.spec_animatedVehicle.numActiveAnimations
end

-- Local values: loadNodeFunction, updateShaderParameterMask
function AnimatedVehicle:onRegisterAnimationValueTypes()
	local function v382_(p379_, p380_, p381_)
		p379_.node = p380_:getValue(p381_ .. "#node", nil, p379_.part.components, p379_.part.i3dMappings)
		if p379_.node == nil then
			return false
		end
		p379_:setWarningInformation("node: " .. getName(p379_.node))
		p379_:addCompareParameters("node")
		return true
	end
	self:registerAnimationValueType("rotation", "startRot", "endRot", false, AnimationValueFloat, v382_, function(p383_)
		return getRotation(p383_.node)
	end, function(p384_, ...)
		-- upvalues: (copy) self
		setRotation(p384_.node, ...)
		SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", p384_.node)
	end)
	self:registerAnimationValueType("translation", "startTrans", "endTrans", false, AnimationValueFloat, v382_, function(p385_)
		return getTranslation(p385_.node)
	end, function(p386_, ...)
		-- upvalues: (copy) self
		setTranslation(p386_.node, ...)
		SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", p386_.node)
	end)
	self:registerAnimationValueType("scale", "startScale", "endScale", false, AnimationValueFloat, v382_, function(p387_)
		return getScale(p387_.node)
	end, function(p388_, ...)
		-- upvalues: (copy) self
		setScale(p388_.node, ...)
		SpecializationUtil.raiseEvent(self, "onAnimationPartChanged", p388_.node)
	end)
	self:registerAnimationValueType("shaderParameter", "shaderStartValues", "shaderEndValues", false, AnimationValueFloat, function(p389_, p390_, p391_)
		p389_.node = p390_:getValue(p391_ .. "#node", nil, p389_.part.components, p389_.part.i3dMappings)
		p389_.shaderParameter = p390_:getValue(p391_ .. "#shaderParameter")
		p389_.shaderParameterPrev = p390_:getValue(p391_ .. "#shaderParameterPrev")
		if p389_.node ~= nil and p389_.shaderParameter ~= nil then
			if getHasClassId(p389_.node, ClassIds.SHAPE) and getHasShaderParameter(p389_.node, p389_.shaderParameter) then
				p389_:setWarningInformation("node: " .. getName(p389_.node) .. "with shaderParam: " .. p389_.shaderParameter)
				p389_:addCompareParameters("node", "shaderParameter")
				p389_.shaderParameterMask = {
					1,
					1,
					1,
					1
				}
				local v392_ = p391_ .. "#shaderStartValues"
				local v393_ = p389_.shaderParameterMask
				local v394_ = false
				local v395_ = p390_:getValue(v392_)
				if v395_ ~= nil then
					for v396_ = 1, #v395_ do
						if v395_[v396_] == "-" then
							v393_[v396_] = 0
							v394_ = true
						end
					end
				end
				p389_.customShaderParameterMask = v394_
				local v397_ = p391_ .. "#shaderEndValues"
				local v398_ = p389_.shaderParameterMask
				local v399_ = false
				local v400_ = p390_:getValue(v397_)
				if v400_ ~= nil then
					for v401_ = 1, #v400_ do
						if v400_[v401_] == "-" then
							v398_[v401_] = 0
							v399_ = true
						end
					end
				end
				p389_.customShaderParameterMask = v399_ or p389_.customShaderParameterMask
				if p389_.shaderParameterPrev == nil then
					local v402_ = string.upper
					local v403_ = p389_.shaderParameter
					local v404_ = v402_((string.sub(v403_, 1, 1)))
					local v405_ = p389_.shaderParameter
					local v406_ = "prev" .. v404_ .. string.sub(v405_, 2)
					if getHasShaderParameter(p389_.node, v406_) then
						p389_.shaderParameterPrev = v406_
					end
				elseif not getHasShaderParameter(p389_.node, p389_.shaderParameterPrev) then
					Logging.xmlWarning(p390_, "Node \'%s\' has no shaderParameterPrev \'%s\' for animation part \'%s\'!", getName(p389_.node), p389_.shaderParameterPrev, p391_)
					return false
				end
				return true
			end
			Logging.xmlWarning(p390_, "Node \'%s\' has no shaderParameter \'%s\' for animation part \'%s\'!", getName(p389_.node), p389_.shaderParameter, p391_)
		end
		return false
	end, function(p407_)
		return getShaderParameter(p407_.node, p407_.shaderParameter)
	end, function(p408_, p409_, p410_, p411_, p412_)
		if p408_.customShaderParameterMask then
			if p408_.shaderParameterMask[1] == 0 then
				p409_ = nil
			end
			if p408_.shaderParameterMask[2] == 0 then
				p410_ = nil
			end
			if p408_.shaderParameterMask[3] == 0 then
				p411_ = nil
			end
			if p408_.shaderParameterMask[4] == 0 then
				p412_ = nil
			end
		end
		if p408_.shaderParameterPrev == nil then
			setShaderParameter(p408_.node, p408_.shaderParameter, p409_, p410_, p411_, p412_, false)
		else
			g_animationManager:setPrevShaderParameter(p408_.node, p408_.shaderParameter, p409_, p410_, p411_, p412_, false, p408_.shaderParameterPrev)
		end
	end)
	self:registerAnimationValueType("visibility", "visibility", "", false, AnimationValueBool, v382_, function(p413_)
		return getVisibility(p413_.node)
	end, function(p414_, ...)
		setVisibility(p414_.node, ...)
	end)
	self:registerAnimationValueType("visibilityInter", "startVisibility", "endVisibility", false, AnimationValueFloat, function(p415_, p416_, p417_)
		p415_.node = p416_:getValue(p417_ .. "#node", nil, p415_.part.components, p415_.part.i3dMappings)
		if p415_.node == nil or (p415_.startValue == nil or p415_.endValue == nil) then
			return false
		end
		p415_:setWarningInformation("node: " .. getName(p415_.node))
		p415_:addCompareParameters("node")
		return true
	end, function(p418_)
		return p418_.lastVisibilityValue == nil and (getVisibility(p418_.node) and 1 or 0) or p418_.lastVisibilityValue
	end, function(p419_, p420_)
		p419_.lastVisibilityValue = p420_
		setVisibility(p419_.node, p420_ >= 0.5)
	end)
	self:registerAnimationValueType("animationClip", "clipStartTime", "clipEndTime", true, AnimationValueFloat, function(p421_, p422_, p423_)
		p421_.node = p422_:getValue(p423_ .. "#node", nil, p421_.part.components, p421_.part.i3dMappings)
		p421_.animationClip = p422_:getValue(p423_ .. "#animationClip")
		if p421_.node ~= nil and p421_.animationClip ~= nil then
			p421_.animationCharSet = getAnimCharacterSet(p421_.node)
			if p421_.animationCharSet ~= 0 then
				p421_.animationClipIndex = getAnimClipIndex(p421_.animationCharSet, p421_.animationClip)
				p421_:setWarningInformation("node: " .. getName(p421_.node) .. "with animationClip: " .. p421_.animationClip)
				p421_:addCompareParameters("node", "animationClip")
				return true
			end
			Logging.xmlWarning(p422_, "Unable to find animation clip \'%s\' on node \'%s\' in \'%s\'", p421_.animationClip, getName(p421_.node), p423_)
		end
		return false
	end, function(p424_)
		local v425_ = getAnimTrackAssignedClip(p424_.animationCharSet, 0)
		clearAnimTrackClip(p424_.animationCharSet, 0)
		assignAnimTrackClip(p424_.animationCharSet, 0, p424_.animationClipIndex)
		if v425_ == p424_.animationClipIndex then
			return getAnimTrackTime(p424_.animationCharSet, 0)
		end
		local v426_ = p424_.startValue or p424_.endValue
		if p424_.animation.currentSpeed < 0 then
			v426_ = p424_.endValue or p424_.startValue
		end
		return v426_[1]
	end, function(p427_, p428_)
		if getAnimTrackAssignedClip(p427_.animationCharSet, 0) ~= p427_.animationClipIndex then
			clearAnimTrackClip(p427_.animationCharSet, 0)
			assignAnimTrackClip(p427_.animationCharSet, 0, p427_.animationClipIndex)
		end
		enableAnimTrack(p427_.animationCharSet, 0)
		setAnimTrackTime(p427_.animationCharSet, 0, p428_, true)
		disableAnimTrack(p427_.animationCharSet, 0)
	end)
	self:registerAnimationValueType("dependentAnimation", "dependentAnimationStartTime", "dependentAnimationEndTime", true, AnimationValueFloat, function(p429_, p430_, p431_)
		p429_.dependentAnimation = p430_:getValue(p431_ .. "#dependentAnimation")
		if p429_.dependentAnimation == nil then
			return false
		end
		p429_:setWarningInformation("dependentAnimation: " .. p429_.dependentAnimation)
		p429_:addCompareParameters("dependentAnimation")
		return true
	end, function(p432_)
		return p432_.vehicle:getAnimationTime(p432_.dependentAnimation)
	end, function(p433_, p434_)
		p433_.vehicle:setAnimationTime(p433_.dependentAnimation, p434_, true)
	end)
	if self.isServer then
		self:registerAnimationValueType("rotLimit", "", "", false, AnimationValueFloat, function(p435_, p436_, p437_)
			p435_.startRotLimit = p436_:getValue(p437_ .. "#startRotLimit", nil, true)
			p435_.startRotMinLimit = p436_:getValue(p437_ .. "#startRotMinLimit", nil, true)
			p435_.startRotMaxLimit = p436_:getValue(p437_ .. "#startRotMaxLimit", nil, true)
			if p435_.startRotLimit ~= nil then
				if p435_.startRotMinLimit ~= nil then
					Logging.xmlWarning(p436_, "Invalid rotLimit definition. \'startRotMinLimit\' defined but overwritten by defined \'startRotLimit\'! (%s)", p437_)
				end
				if p435_.startRotMaxLimit ~= nil then
					Logging.xmlWarning(p436_, "Invalid rotLimit definition. \'startRotMaxLimit\' defined but overwritten by defined \'startRotLimit\'! (%s)", p437_)
				end
				p435_.startRotMinLimit = { -p435_.startRotLimit[1], -p435_.startRotLimit[2], -p435_.startRotLimit[3] }
				p435_.startRotMaxLimit = { p435_.startRotLimit[1], p435_.startRotLimit[2], p435_.startRotLimit[3] }
			end
			p435_.endRotLimit = p436_:getValue(p437_ .. "#endRotLimit", nil, true)
			p435_.endRotMinLimit = p436_:getValue(p437_ .. "#endRotMinLimit", nil, true)
			p435_.endRotMaxLimit = p436_:getValue(p437_ .. "#endRotMaxLimit", nil, true)
			if p435_.endRotLimit ~= nil then
				if p435_.endRotMinLimit ~= nil then
					Logging.xmlWarning(p436_, "Invalid rotLimit definition. \'endRotMinLimit\' defined but overwritten by defined \'endRotLimit\'! (%s)", p437_)
				end
				if p435_.endRotMaxLimit ~= nil then
					Logging.xmlWarning(p436_, "Invalid rotLimit definition. \'endRotMaxLimit\' defined but overwritten by defined \'endRotLimit\'! (%s)", p437_)
				end
				p435_.endRotMinLimit = { -p435_.endRotLimit[1], -p435_.endRotLimit[2], -p435_.endRotLimit[3] }
				p435_.endRotMaxLimit = { p435_.endRotLimit[1], p435_.endRotLimit[2], p435_.endRotLimit[3] }
			end
			local v438_ = p436_:getValue(p437_ .. "#componentJointIndex")
			if v438_ ~= nil then
				if v438_ >= 1 then
					p435_.componentJoint = p435_.vehicle.componentJoints[v438_]
				end
				if p435_.componentJoint == nil then
					Logging.xmlWarning(p436_, "Invalid componentJointIndex for animation part \'%s\'. Indexing starts with 1!", p437_)
					return false
				end
			end
			if p435_.endRotMinLimit ~= nil and p435_.endRotMaxLimit == nil or p435_.endRotMinLimit == nil and p435_.endRotMaxLimit ~= nil then
				Logging.xmlWarning(p436_, "Incomplete end trans limit for animation part \'%s\'.", p437_)
				return false
			end
			if p435_.componentJoint == nil or (p435_.endRotMinLimit == nil or p435_.endRotMaxLimit == nil) then
				return false
			end
			if p435_.startRotMinLimit ~= nil and p435_.startRotMaxLimit ~= nil then
				p435_.startValue = {
					p435_.startRotMinLimit[1],
					p435_.startRotMinLimit[2],
					p435_.startRotMinLimit[3],
					p435_.startRotMaxLimit[1],
					p435_.startRotMaxLimit[2],
					p435_.startRotMaxLimit[3]
				}
			end
			if p435_.endRotMinLimit ~= nil and p435_.endRotMaxLimit ~= nil then
				p435_.endValue = {
					p435_.endRotMinLimit[1],
					p435_.endRotMinLimit[2],
					p435_.endRotMinLimit[3],
					p435_.endRotMaxLimit[1],
					p435_.endRotMaxLimit[2],
					p435_.endRotMaxLimit[3]
				}
			end
			if p435_.endValue == nil then
				Logging.xmlWarning(p436_, "Missing end rot limit for animation part \'%s\'.", p437_)
				return false
			end
			p435_.endName = "rotLimit"
			p435_:setWarningInformation("componentJointIndex: " .. v438_)
			p435_:addCompareParameters("componentJoint")
			return true
		end, function(p439_)
			return p439_.componentJoint.rotMinLimit[1], p439_.componentJoint.rotMinLimit[2], p439_.componentJoint.rotMinLimit[3], p439_.componentJoint.rotLimit[1], p439_.componentJoint.rotLimit[2], p439_.componentJoint.rotLimit[3]
		end, function(p440_, p441_, p442_, p443_, p444_, p445_, p446_)
			p440_.vehicle:setComponentJointRotLimit(p440_.componentJoint, 1, p441_, p444_)
			p440_.vehicle:setComponentJointRotLimit(p440_.componentJoint, 2, p442_, p445_)
			p440_.vehicle:setComponentJointRotLimit(p440_.componentJoint, 3, p443_, p446_)
		end)
		self:registerAnimationValueType("transLimit", "", "", false, AnimationValueFloat, function(p447_, p448_, p449_)
			p447_.startTransLimit = p448_:getValue(p449_ .. "#startTransLimit", nil, true)
			p447_.startTransMinLimit = p448_:getValue(p449_ .. "#startTransMinLimit", nil, true)
			p447_.startTransMaxLimit = p448_:getValue(p449_ .. "#startTransMaxLimit", nil, true)
			if p447_.startTransLimit ~= nil then
				if p447_.startTransMinLimit ~= nil then
					Logging.xmlWarning(p448_, "Invalid transLimit definition. \'startTransMinLimit\' defined but overwritten by defined \'startTransLimit\'! (%s)", p449_)
				end
				if p447_.startTransMaxLimit ~= nil then
					Logging.xmlWarning(p448_, "Invalid transLimit definition. \'startTransMaxLimit\' defined but overwritten by defined \'startTransLimit\'! (%s)", p449_)
				end
				p447_.startTransMinLimit = { -p447_.startTransLimit[1], -p447_.startTransLimit[2], -p447_.startTransLimit[3] }
				p447_.startTransMaxLimit = { p447_.startTransLimit[1], p447_.startTransLimit[2], p447_.startTransLimit[3] }
			end
			p447_.endTransLimit = p448_:getValue(p449_ .. "#endTransLimit", nil, true)
			p447_.endTransMinLimit = p448_:getValue(p449_ .. "#endTransMinLimit", nil, true)
			p447_.endTransMaxLimit = p448_:getValue(p449_ .. "#endTransMaxLimit", nil, true)
			if p447_.endTransLimit ~= nil then
				if p447_.endTransMinLimit ~= nil then
					Logging.xmlWarning(p448_, "Invalid transLimit definition. \'endTransMinLimit\' defined but overwritten by defined \'endTransLimit\'! (%s)", p449_)
				end
				if p447_.endTransMaxLimit ~= nil then
					Logging.xmlWarning(p448_, "Invalid transLimit definition. \'endTransMaxLimit\' defined but overwritten by defined \'endTransLimit\'! (%s)", p449_)
				end
				p447_.endTransMinLimit = { -p447_.endTransLimit[1], -p447_.endTransLimit[2], -p447_.endTransLimit[3] }
				p447_.endTransMaxLimit = { p447_.endTransLimit[1], p447_.endTransLimit[2], p447_.endTransLimit[3] }
			end
			local v450_ = p448_:getValue(p449_ .. "#componentJointIndex")
			if v450_ ~= nil then
				if v450_ >= 1 then
					p447_.componentJoint = p447_.vehicle.componentJoints[v450_]
				end
				if p447_.componentJoint == nil then
					Logging.xmlWarning(p448_, "Invalid componentJointIndex for animation part \'%s\'. Indexing starts with 1!", p449_)
					return false
				end
			end
			if p447_.endTransMinLimit ~= nil and p447_.endTransMaxLimit == nil or p447_.endTransMinLimit == nil and p447_.endTransMaxLimit ~= nil then
				Logging.xmlWarning(p448_, "Incomplete end trans limit for animation part \'%s\'.", p449_)
				return false
			end
			if p447_.componentJoint == nil or (p447_.endTransMinLimit == nil or p447_.endTransMaxLimit == nil) then
				return false
			end
			if p447_.startTransMinLimit ~= nil and p447_.startTransMaxLimit ~= nil then
				p447_.startValue = {
					p447_.startTransMinLimit[1],
					p447_.startTransMinLimit[2],
					p447_.startTransMinLimit[3],
					p447_.startTransMaxLimit[1],
					p447_.startTransMaxLimit[2],
					p447_.startTransMaxLimit[3]
				}
			end
			if p447_.endTransMinLimit ~= nil and p447_.endTransMaxLimit ~= nil then
				p447_.endValue = {
					p447_.endTransMinLimit[1],
					p447_.endTransMinLimit[2],
					p447_.endTransMinLimit[3],
					p447_.endTransMaxLimit[1],
					p447_.endTransMaxLimit[2],
					p447_.endTransMaxLimit[3]
				}
			end
			if p447_.endValue == nil then
				Logging.xmlWarning(p448_, "Missing end trans limit for animation part \'%s\'.", p449_)
				return false
			end
			p447_.endName = "transLimit"
			p447_:setWarningInformation("componentJointIndex: " .. v450_)
			p447_:addCompareParameters("componentJoint")
			return true
		end, function(p451_)
			return p451_.componentJoint.transMinLimit[1], p451_.componentJoint.transMinLimit[2], p451_.componentJoint.transMinLimit[3], p451_.componentJoint.transLimit[1], p451_.componentJoint.transLimit[2], p451_.componentJoint.transLimit[3]
		end, function(p452_, p453_, p454_, p455_, p456_, p457_, p458_)
			p452_.vehicle:setComponentJointTransLimit(p452_.componentJoint, 1, p453_, p456_)
			p452_.vehicle:setComponentJointTransLimit(p452_.componentJoint, 2, p454_, p457_)
			p452_.vehicle:setComponentJointTransLimit(p452_.componentJoint, 3, p455_, p458_)
		end)
		self:registerAnimationValueType("rotationLimitSpring", "", "", false, AnimationValueFloat, function(p459_, p460_, p461_)
			p459_.startRotLimitSpring = p460_:getValue(p461_ .. "#startRotLimitSpring", nil, true)
			p459_.startRotLimitDamping = p460_:getValue(p461_ .. "#startRotLimitDamping", nil, true)
			p459_.endRotLimitSpring = p460_:getValue(p461_ .. "#endRotLimitSpring", nil, true)
			p459_.endRotLimitDamping = p460_:getValue(p461_ .. "#endRotLimitDamping", nil, true)
			local v462_ = p460_:getValue(p461_ .. "#componentJointIndex")
			if v462_ ~= nil then
				if v462_ >= 1 then
					p459_.componentJoint = p459_.vehicle.componentJoints[v462_]
				end
				if p459_.componentJoint == nil then
					Logging.xmlWarning(p460_, "Invalid componentJointIndex for animation part \'%s\'. Indexing starts with 1!", p461_)
					return false
				end
			end
			if p459_.componentJoint == nil or p459_.endRotLimitSpring == nil and p459_.startRotLimitDamping == nil then
				return false
			end
			if p459_.startRotLimitSpring ~= nil and p459_.startRotLimitDamping ~= nil then
				p459_.startValue = {
					p459_.startRotLimitSpring[1],
					p459_.startRotLimitSpring[2],
					p459_.startRotLimitSpring[3],
					p459_.startRotLimitDamping[1],
					p459_.startRotLimitDamping[2],
					p459_.startRotLimitDamping[3]
				}
			end
			if p459_.endRotLimitSpring ~= nil and p459_.endRotLimitDamping ~= nil then
				p459_.endValue = {
					p459_.endRotLimitSpring[1],
					p459_.endRotLimitSpring[2],
					p459_.endRotLimitSpring[3],
					p459_.endRotLimitDamping[1],
					p459_.endRotLimitDamping[2],
					p459_.endRotLimitDamping[3]
				}
			end
			if p459_.endValue == nil then
				Logging.xmlWarning(p460_, "Missing \'endRotLimitSpring\' or \'endRotLimitDamping\' for animation part \'%s\'.", p461_)
				return false
			end
			p459_.endName = "rotationLimitSpring"
			p459_:setWarningInformation("componentJointIndex: " .. v462_)
			p459_:addCompareParameters("componentJoint")
			return true
		end, function(p463_)
			return p463_.componentJoint.rotLimitSpring[1], p463_.componentJoint.rotLimitSpring[2], p463_.componentJoint.rotLimitSpring[3], p463_.componentJoint.rotLimitDamping[1], p463_.componentJoint.rotLimitDamping[2], p463_.componentJoint.rotLimitDamping[3]
		end, function(p464_, p465_, p466_, p467_, p468_, p469_, p470_)
			local v471_ = p464_.componentJoint.rotLimitSpring
			local v472_ = p464_.componentJoint.rotLimitSpring
			local v473_ = p464_.componentJoint.rotLimitSpring
			v471_[1] = p465_
			v472_[2] = p466_
			v473_[3] = p467_
			local v474_ = p464_.componentJoint.rotLimitDamping
			local v475_ = p464_.componentJoint.rotLimitDamping
			local v476_ = p464_.componentJoint.rotLimitDamping
			v474_[1] = p468_
			v475_[2] = p469_
			v476_[3] = p470_
			if p464_.componentJoint.jointIndex ~= nil then
				for v477_ = 1, 3 do
					setJointRotationLimitSpring(p464_.componentJoint.jointIndex, v477_ - 1, p464_.componentJoint.rotLimitSpring[v477_], p464_.componentJoint.rotLimitDamping[v477_])
				end
			end
		end)
		self:registerAnimationValueType("componentMass", "startMass", "endMass", false, AnimationValueFloat, function(p478_, p479_, p480_)
			local v481_ = p479_:getValue(p480_ .. "#componentIndex")
			if v481_ ~= nil then
				if v481_ >= 1 then
					p478_.component = p478_.vehicle.components[v481_]
				end
				if p478_.component == nil then
					Logging.xmlWarning(p479_, "Invalid component for animation part \'%s\'. Indexing starts with 1!", p480_)
					return false
				end
			end
			if p478_.component == nil then
				return false
			end
			p478_:setWarningInformation("componentIndex: " .. v481_)
			p478_:addCompareParameters("component")
			return true
		end, function(p482_)
			return (p482_.component.defaultMass or getMass(p482_.component.node)) * 1000
		end, function(p483_, p484_)
			-- upvalues: (copy) self
			p483_.component.defaultMass = p484_ * 0.001
			self:setMassDirty()
		end)
		self:registerAnimationValueType("centerOfMass", "startCenterOfMass", "endCenterOfMass", false, AnimationValueFloat, function(p485_, p486_, p487_)
			local v488_ = p486_:getValue(p487_ .. "#componentIndex")
			if v488_ ~= nil then
				if v488_ >= 1 then
					p485_.component = p485_.vehicle.components[v488_]
				end
				if p485_.component == nil then
					Logging.xmlWarning(p486_, "Invalid component for animation part \'%s\'. Indexing starts with 1!", p487_)
					return false
				end
			end
			if p485_.component == nil then
				return false
			end
			p485_:setWarningInformation("componentIndex: " .. v488_)
			p485_:addCompareParameters("component")
			return true
		end, function(p489_)
			return getCenterOfMass(p489_.component.node)
		end, function(p490_, p491_, p492_, p493_)
			setCenterOfMass(p490_.component.node, p491_, p492_, p493_)
		end)
		self:registerAnimationValueType("frictionVelocity", "startFrictionVelocity", "endFrictionVelocity", false, AnimationValueFloat, v382_, function(p494_)
			return p494_.lastFrictionVelocity or 0
		end, function(p495_, p496_)
			setFrictionVelocity(p495_.node, p496_)
			p495_.lastFrictionVelocity = p496_
			if p495_.origTransX == nil then
				local v497_, v498_, v499_ = getTranslation(p495_.node)
				p495_.origTransX = v497_
				p495_.origTransY = v498_
				p495_.origTransZ = v499_
			end
			setTranslation(p495_.node, p495_.origTransX + math.random() * 0.001, p495_.origTransY, p495_.origTransZ)
		end)
	end
	self:registerAnimationValueType("spline", "startSplinePos", "endSplinePos", false, AnimationValueFloat, function(p500_, p501_, p502_)
		p500_.node = p501_:getValue(p502_ .. "#node", nil, p500_.part.components, p500_.part.i3dMappings)
		p500_.spline = p501_:getValue(p502_ .. "#spline", nil, p500_.part.components, p500_.part.i3dMappings)
		if p500_.node == nil or p500_.spline == nil then
			return false
		end
		p500_:setWarningInformation("node:" .. getName(p500_.node) .. " with spline: " .. getName(p500_.spline))
		p500_:addCompareParameters("node", "spline")
		return true
	end, function(p503_)
		if p503_.lastSplineTime ~= nil then
			return p503_.lastSplineTime
		end
		local v504_ = p503_.startValue or p503_.endValue
		if p503_.animation.currentSpeed < 0 then
			v504_ = p503_.endValue or p503_.startValue
		end
		return v504_[1]
	end, function(p505_, p506_)
		local v507_, v508_, v509_ = getSplinePosition(p505_.spline, p506_ % 1)
		local v510_, v511_, v512_ = worldToLocal(getParent(p505_.node), v507_, v508_, v509_)
		setTranslation(p505_.node, v510_, v511_, v512_)
		p505_.lastSplineTime = p506_
		for _, v513_ in ipairs(p505_.animation.parts) do
			for v514_ = 1, #v513_.animationValues do
				local v515_ = v513_.animationValues[v514_]
				if v515_.node == p505_.node and v515_.name == p505_.name then
					v515_.lastSplineTime = p506_
				end
			end
		end
	end)
	self:registerAnimationValueType("rollingGate", "startGatePos", "endGatePos", false, AnimationValueFloat, function(p516_, p517_, p518_)
		if p517_:hasProperty(p518_ .. ".rollingGateAnimation") then
			local v519_ = RollingGateAnimation.new()
			if v519_:load(p517_, p518_ .. ".rollingGateAnimation", p516_.part.components, p516_.part.i3dMappings) then
				p516_:setWarningInformation("rollingGateAnimation:" .. getName(v519_.splineNode))
				p516_.rollingGate = v519_
				return true
			end
		end
		return false
	end, function(p520_)
		return p520_.rollingGate.state
	end, function(p521_, p522_)
		p521_.rollingGate:setState(p522_)
	end)
end
