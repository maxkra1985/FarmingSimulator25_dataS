Windrower = {}
Windrower.CLIENT_DM_UPDATE_RADIUS = 50
function Windrower.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("windrower", false, true, true)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Windrower")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.windrower.effects.effect(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.windrower.effects.effect(?).sounds", "work")
	v1_:register(XMLValueType.INT, "vehicle.windrower.effects.effect(?)#workAreaIndex", "Work area index", 1)
	v1_:register(XMLValueType.INT, "vehicle.windrower.effects.effect(?)#dropAreaIndex", "Drop area index (if defined the effect is only active if this drop area is set on workArea)")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.windrower.animationNodes")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.windrower.sounds", "work")
	v1_:register(XMLValueType.BOOL, "vehicle.windrower#limitToLineHeight", "Limit pickup to work area line height", false)
	v1_:register(XMLValueType.STRING, "vehicle.windrower#fillTypeCategories", "Fill type categories")
	v1_:register(XMLValueType.STRING, "vehicle.windrower#fillTypes", "List of supported fill types")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".windrower#particleSystemIndex", "Particle system index")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".windrower#dropWindrowWorkAreaIndex", "Drop work area index", 1)
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".windrower#particleSystemIndex", "Particle system index")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".windrower#dropWindrowWorkAreaIndex", "Drop work area index", 1)
	v1_:setXMLSpecializationType()
end

function Windrower.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function Windrower.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processWindrowerArea", Windrower.processWindrowerArea)
	SpecializationUtil.registerFunction(vehicleType, "processDropArea", Windrower.processDropArea)
end

function Windrower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Windrower.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Windrower.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Windrower.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Windrower.getWearMultiplier)
end

function Windrower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Windrower)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Windrower)
end

-- Local values: spec, i, key, effects, effect, j, _, fillTypeIndex
function Windrower:onLoad(savegame)
	local v7_ = self.spec_windrower
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.animation", "vehicle.windrowers.windrower")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.windrowerParticleSystems", "vehicle.windrower.effects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.windrower.animationNodes.animationNode", "windrower")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.windrowerSound", "vehicle.windrower.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.windrower.rakes.rake", "vehicle.windrower.animationNodes.animationNode with type \'RotationAnimationSpikes\'")
	if self.isClient then
		v7_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.windrower.animationNodes", self.components, self, self.i3dMappings)
		v7_.effects = {}
		v7_.workAreaToEffects = {}
		local v8_ = 0
		while true do
			local v9_ = string.format("vehicle.windrower.effects.effect(%d)", v8_)
			if not self.xmlFile:hasProperty(v9_) then
				break
			end
			local v10_ = g_effectManager:loadEffect(self.xmlFile, v9_, self.components, self, self.i3dMappings)
			if v10_ ~= nil then
				local v11_ = {
					["effects"] = v10_,
					["workAreaIndex"] = self.xmlFile:getValue(v9_ .. "#workAreaIndex", 1),
					["dropAreaIndex"] = self.xmlFile:getValue(v9_ .. "#dropAreaIndex"),
					["activeTime"] = -1,
					["activeTimeDuration"] = 250,
					["isActive"] = false,
					["isActiveSent"] = false,
					["samples"] = {}
				}
				v11_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, v9_ .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
				local v12_ = v7_.effects
				table.insert(v12_, v11_)
				for v13_ = 1, #v10_ do
					if v10_[v13_].setWorkAreaIndex ~= nil then
						v10_[v13_]:setWorkAreaIndex(v11_.workAreaIndex)
					end
				end
			end
			v8_ = v8_ + 1
		end
		v7_.samples = {}
		v7_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.windrower.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v7_.isWorking = false
	v7_.limitToLineHeight = self.xmlFile:getValue("vehicle.windrower#limitToLineHeight", false)
	v7_.stoneLastState = 0
	v7_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("WINDROWER")
	v7_.supportedFillTypes = g_fillTypeManager:getFillTypesFromXML(self.xmlFile, "vehicle.windrower#fillTypeCategories", "vehicle.windrower#fillTypes", true)
	v7_.fillTypesDirtyFlag = self:getNextDirtyFlag()
	v7_.effectDirtyFlag = self:getNextDirtyFlag()
	if self.addAIDensityHeightTypeRequirement ~= nil then
		for _, v14_ in ipairs(v7_.supportedFillTypes) do
			self:addAIDensityHeightTypeRequirement(v14_)
		end
	end
end

-- Local values: spec, i, effect, workArea
function Windrower:onPostLoad(savegame)
	local v16_ = self.spec_windrower
	for v17_ = #v16_.effects, 1, -1 do
		local v18_ = v16_.effects[v17_]
		local v19_ = self:getWorkAreaByIndex(v18_.workAreaIndex)
		if v19_ == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid workAreaIndex \'%d\' for effect \'vehicle.windrower.effects.effect(%d)\'!", v18_.workAreaIndex, v17_)
			local v20_ = v16_.effects
			table.insert(v20_, v17_)
		else
			v18_.windrowerWorkAreaFillTypeIndex = v19_.windrowerWorkAreaIndex
			if v16_.workAreaToEffects[v19_.index] == nil then
				v16_.workAreaToEffects[v19_.index] = {}
			end
			local v21_ = v16_.workAreaToEffects[v19_.index]
			table.insert(v21_, v18_)
		end
	end
end

-- Local values: spec, _, effect
function Windrower:onDelete()
	local v23_ = self.spec_windrower
	g_soundManager:deleteSamples(v23_.samples)
	g_animationManager:deleteAnimations(v23_.animationNodes)
	if v23_.effects ~= nil then
		for _, v24_ in ipairs(v23_.effects) do
			g_effectManager:deleteEffects(v24_.effects)
			g_soundManager:deleteSamples(v24_.samples)
		end
	end
end

-- Local values: spec, index, _, fillType, _, effect, fillType
function Windrower:onReadStream(streamId, connection)
	local v27_ = self.spec_windrower
	for v28_, _ in ipairs(v27_.windrowerWorkAreaFillTypes) do
		local v29_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		v27_.windrowerWorkAreaFillTypes[v28_] = v29_
	end
	for _, v30_ in ipairs(v27_.effects) do
		if streamReadBool(streamId) then
			local v31_ = v27_.windrowerWorkAreaFillTypes[v30_.windrowerWorkAreaFillTypeIndex]
			g_effectManager:setEffectTypeInfo(v30_.effects, v31_)
			g_effectManager:startEffects(v30_.effects)
			if not g_soundManager:getIsSamplePlaying(v30_.samples.work) then
				g_soundManager:playSample(v30_.samples.work)
			end
		else
			g_effectManager:stopEffects(v30_.effects)
			g_soundManager:stopSample(v30_.samples.work)
		end
	end
end

-- Local values: spec, _, fillTypeIndex, _, effect
function Windrower:onWriteStream(streamId, connection)
	local v34_ = self.spec_windrower
	for _, v35_ in ipairs(v34_.windrowerWorkAreaFillTypes) do
		streamWriteUIntN(streamId, v35_, FillTypeManager.SEND_NUM_BITS)
	end
	for _, v36_ in ipairs(v34_.effects) do
		streamWriteBool(streamId, v36_.isActiveSent)
	end
end

-- Local values: spec, index, _, fillType, _, effect, fillType
function Windrower:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v40_ = self.spec_windrower
		if streamReadBool(streamId) then
			for v41_, _ in ipairs(v40_.windrowerWorkAreaFillTypes) do
				local v42_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
				v40_.windrowerWorkAreaFillTypes[v41_] = v42_
			end
		end
		if streamReadBool(streamId) then
			for _, v43_ in ipairs(v40_.effects) do
				if streamReadBool(streamId) then
					local v44_ = v40_.windrowerWorkAreaFillTypes[v43_.windrowerWorkAreaFillTypeIndex]
					g_effectManager:setEffectTypeInfo(v43_.effects, v44_)
					g_effectManager:startEffects(v43_.effects)
					if not g_soundManager:getIsSamplePlaying(v43_.samples.work) then
						g_soundManager:playSample(v43_.samples.work)
					end
				else
					g_effectManager:stopEffects(v43_.effects)
					g_soundManager:stopSample(v43_.samples.work)
				end
			end
		end
	end
end

-- Local values: spec, _, fillTypeIndex, _, effect
function Windrower:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v49_ = self.spec_windrower
		local v50_ = streamWriteBool
		local v51_ = v49_.fillTypesDirtyFlag
		if v50_(streamId, bit32.band(dirtyMask, v51_) ~= 0) then
			for _, v52_ in ipairs(v49_.windrowerWorkAreaFillTypes) do
				streamWriteUIntN(streamId, v52_, FillTypeManager.SEND_NUM_BITS)
			end
		end
		local v53_ = streamWriteBool
		local v54_ = v49_.effectDirtyFlag
		if v53_(streamId, bit32.band(dirtyMask, v54_) ~= 0) then
			for _, v55_ in ipairs(v49_.effects) do
				streamWriteBool(streamId, v55_.isActiveSent)
			end
		end
	end
end

-- Local values: spec, _, effect
function Windrower:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v57_ = self.spec_windrower
	if self.isServer then
		for _, v58_ in ipairs(v57_.effects) do
			if v58_.isActive and g_currentMission.time > v58_.activeTime then
				v58_.isActive = false
				if v58_.isActiveSent then
					v58_.isActiveSent = false
					self:raiseDirtyFlags(v57_.effectDirtyFlag)
				end
				g_effectManager:stopEffects(v58_.effects)
				g_soundManager:stopSample(v58_.samples.work)
			end
		end
	end
end

-- Local values: spec
function Windrower:onTurnedOn()
	local v60_ = self.spec_windrower
	if self.isClient then
		g_soundManager:playSample(v60_.samples.work)
		g_animationManager:startAnimations(v60_.animationNodes)
	end
end

-- Local values: spec, _, effect
function Windrower:onTurnedOff()
	local v62_ = self.spec_windrower
	g_soundManager:stopSamples(v62_.samples)
	for _, v63_ in ipairs(v62_.effects) do
		g_effectManager:stopEffects(v63_.effects)
		g_soundManager:stopSample(v63_.samples.work)
	end
	g_animationManager:stopAnimations(v62_.animationNodes)
end

-- Local values: turnOn
function Windrower:doCheckSpeedLimit(superFunc)
	local v66_ = self.getIsTurnedOn == nil and true or self:getIsTurnedOn()
	local v67_ = superFunc(self)
	if v67_ then
		v66_ = v67_
	elseif self.getIsImplementChainLowered == nil then
		v66_ = false
	else
		local v68_ = self:getIsImplementChainLowered()
		if not v68_ then
			v66_ = v68_
		end
	end
	return v66_
end
function Windrower.getDefaultSpeedLimit()
	return 15
end

-- Local values: retValue, spec
function Windrower:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v74_ = superFunc(self, workArea, xmlFile, key)
	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.WINDROWER
	end
	if workArea.type == WorkAreaType.WINDROWER then
		workArea.particleSystemIndex = xmlFile:getValue(key .. ".windrower#particleSystemIndex")
		workArea.dropWindrowWorkAreaIndex = xmlFile:getValue(key .. ".windrower#dropWindrowWorkAreaIndex", 1)
		workArea.lastValidPickupFillType = FillType.UNKNOWN
		workArea.lastPickupLiters = 0
		workArea.lastDroppedLiters = 0
		workArea.litersToDrop = 0
		local v75_ = self.spec_windrower
		if v75_.windrowerWorkAreaFillTypes == nil then
			v75_.windrowerWorkAreaFillTypes = {}
		end
		local v76_ = v75_.windrowerWorkAreaFillTypes
		local v77_ = FillType.UNKNOWN
		table.insert(v76_, v77_)
		workArea.windrowerWorkAreaIndex = #v75_.windrowerWorkAreaFillTypes
	end
	return v74_
end

-- Local values: spec, multiplier
function Windrower:getDirtMultiplier(superFunc)
	local v80_ = self.spec_windrower
	local v81_ = superFunc(self)
	if v80_.isWorking then
		v81_ = v81_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v81_
end

-- Local values: spec, multiplier, stoneMultiplier
function Windrower:getWearMultiplier(superFunc)
	local v84_ = self.spec_windrower
	local v85_ = superFunc(self)
	if v84_.isWorking then
		local v86_ = (v84_.stoneLastState == 0 or v84_.stoneWearMultiplierData == nil) and 1 or (v84_.stoneWearMultiplierData[v84_.stoneLastState] or 1)
		v85_ = v85_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * v86_
	end
	return v85_
end

-- Local values: spec, _, workArea
function Windrower:onStartWorkAreaProcessing(dt, workAreas)
	local v89_ = self.spec_windrower
	for _, v90_ in pairs(workAreas) do
		v90_.lastValidPickupFillType = FillType.UNKNOWN
		v90_.lastPickupLiters = 0
		v90_.lastDroppedLiters = 0
	end
	v89_.isWorking = false
end

-- Local values: spec
function Windrower:onEndWorkAreaProcessing(dt, workAreas)
	local v92_ = self.spec_windrower
	if self.isClient and self.getIsTurnedOn == nil then
		if v92_.isWorking then
			if not g_soundManager:getIsSamplePlaying(v92_.samples.work) then
				g_soundManager:playSample(v92_.samples.work)
				return
			end
		elseif g_soundManager:getIsSamplePlaying(v92_.samples.work) then
			g_soundManager:stopSample(v92_.samples.work)
		end
	end
end

function Windrower:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.headlandsFirst = true
	fieldCourseSettings.workInitialSegment = true
end

-- Local values: spec, workAreaSpec, sx, sy, sz, wx, wy, wz, hx, hy, hz, lsx, lsy, lsz, lex, ley, lez, radius, pickupLiters, pickupFillType, _, fillTypeIndex, areaWidth, area, dropArea, dropType, dropped, changedFillType, effects, _, effect
function Windrower:processWindrowerArea(workArea, dt)
	local v96_ = self.spec_windrower
	local v97_ = self.spec_workArea
	if not self.isServer and self.currentUpdateDistance > Windrower.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	v96_.isWorking = self:getLastSpeed() > 0.5
	local v98_, v99_, v100_ = getWorldTranslation(workArea.start)
	local v101_, v102_, v103_ = getWorldTranslation(workArea.width)
	local v104_, v105_, v106_ = getWorldTranslation(workArea.height)
	if v96_.isWorking then
		v96_.stoneLastState = FSDensityMapUtil.getStoneArea(v98_, v100_, v101_, v103_, v104_, v106_)
	else
		v96_.stoneLastState = 0
	end
	local v107_, v108_, v109_, v110_, v111_, v112_, v113_ = DensityMapHeightUtil.getLineByAreaDimensions(v98_, v99_, v100_, v101_, v102_, v103_, v104_, v105_, v106_)
	local v114_ = 0
	local v115_ = FillType.UNKNOWN
	if workArea.lastPickupLiters == 0 and (workArea.lastValidPickupFillType == FillType.UNKNOWN or workArea.litersToDrop < g_densityMapHeightManager:getMinValidLiterValue(workArea.lastValidPickupFillType)) then
		for _, v116_ in ipairs(v96_.supportedFillTypes) do
			v114_ = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, v116_, v107_, v108_, v109_, v110_, v111_, v112_, v113_, nil, nil, v96_.limitToLineHeight, nil)
			if v114_ > 0 then
				v115_ = v116_
				break
			end
		end
	else
		v114_ = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, workArea.lastValidPickupFillType, v107_, v108_, v109_, v110_, v111_, v112_, v113_, nil, nil, false, nil)
		if workArea.lastValidPickupFillType == FillType.GRASS_WINDROW then
			v114_ = v114_ - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, FillType.DRYGRASS_WINDROW, v107_, v108_, v109_, v110_, v111_, v112_, v113_, nil, nil, false, nil)
		elseif workArea.lastValidPickupFillType == FillType.DRYGRASS_WINDROW then
			v114_ = v114_ - DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, FillType.GRASS_WINDROW, v107_, v108_, v109_, v110_, v111_, v112_, v113_, nil, nil, false, nil)
		end
		if v114_ > 0 then
			v115_ = workArea.lastValidPickupFillType
		end
	end
	if v115_ ~= FillType.UNKNOWN then
		workArea.lastValidPickupFillType = v115_
		self:setTestAreaRequirements(nil, v115_, nil)
	end
	workArea.lastPickupLiters = v114_
	workArea.litersToDrop = workArea.litersToDrop + v114_
	local v117_ = MathUtil.vector3Length(v107_ - v110_, v108_ - v111_, v109_ - v112_) * self.lastMovedDistance
	if workArea.lastPickupLiters > 0 then
		local v118_ = v97_.workAreas[workArea.dropWindrowWorkAreaIndex]
		if v118_ ~= nil then
			local v119_ = workArea.lastValidPickupFillType
			local v120_ = self:processDropArea(v118_, workArea.lastPickupLiters, v119_)
			workArea.lastDroppedLiters = v120_
			workArea.litersToDrop = workArea.litersToDrop - v120_
			if self.isServer and (self:getLastSpeed(true) > 0.5 and v120_ > 0) then
				local v121_
				if v96_.windrowerWorkAreaFillTypes[workArea.windrowerWorkAreaIndex] == v119_ then
					v121_ = false
				else
					v96_.windrowerWorkAreaFillTypes[workArea.windrowerWorkAreaIndex] = v119_
					self:raiseDirtyFlags(v96_.fillTypesDirtyFlag)
					v121_ = true
				end
				local v122_ = v96_.workAreaToEffects[workArea.index]
				if v122_ ~= nil then
					for _, v123_ in ipairs(v122_) do
						if v123_.dropAreaIndex == nil or v123_.dropAreaIndex == workArea.dropWindrowWorkAreaIndex then
							v123_.activeTime = g_currentMission.time + v123_.activeTimeDuration
							if not v123_.isActiveSent then
								v123_.isActiveSent = true
								self:raiseDirtyFlags(v96_.effectDirtyFlag)
							end
							if v121_ then
								g_effectManager:setEffectTypeInfo(v123_.effects, v119_)
							end
							if not v123_.isActive then
								g_effectManager:setEffectTypeInfo(v123_.effects, v119_)
								g_effectManager:startEffects(v123_.effects)
								g_soundManager:playSample(v123_.samples.work)
							end
							v123_.isActive = true
						end
					end
				end
			end
		end
	end
	return workArea.lastDroppedLiters, v117_
end

-- Local values: lsx, lsy, lsz, lex, ley, lez, radius, dropped, lineOffset
function Windrower:processDropArea(dropArea, litersToDrop, fillType)
	local v128_, v129_, v130_, v131_, v132_, v133_, v134_ = DensityMapHeightUtil.getLineByArea(dropArea.start, dropArea.width, dropArea.height)
	local v135_, v136_ = DensityMapHeightUtil.tipToGroundAroundLine(self, litersToDrop, fillType, v128_, v129_, v130_, v131_, v132_, v133_, v134_, nil, dropArea.lineOffset, false, nil, false)
	dropArea.lineOffset = v136_
	return v135_
end
