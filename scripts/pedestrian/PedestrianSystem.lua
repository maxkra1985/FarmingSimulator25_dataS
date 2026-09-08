-- Local values: PedestrianSystem_mt
PedestrianSystem = {}
local PedestrianSystem_mt = Class(PedestrianSystem)
g_xmlManager:addCreateSchemaFunction(function()
	PedestrianSystem.xmlSchema = XMLSchema.new("pedestrianSystem")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = PedestrianSystem.xmlSchema
	PlayerStyle.registerSavegameXMLPaths(v2_, "pedestrianSystem.pedestrians.pedestrian(?).style")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?)#variation", "Name of the variation", nil, false, { "male", "female", "unisex" })
	v2_:register(XMLValueType.DAY_TIME, "pedestrianSystem.pedestrians.pedestrian(?)#timeFrom", "Start day time of pedestrian visibility")
	v2_:register(XMLValueType.DAY_TIME, "pedestrianSystem.pedestrians.pedestrian(?)#timeTo", "End day time of pedestrian visibility")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).groups.group(?)#name", "Name of the pedestrian group")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).idleAnimation#animationName", "Name of the idle animation")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).staticIdleAnimation(?)#animationName", "Name of the static idle animation")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#animationName", "Name of the walk animation")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#blendWithAnimationName", "Name of the blend animation")
	v2_:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#distance", "Animatio distance")
	v2_:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#speedScaleMin", "Min speed scale of the animation")
	v2_:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation#speedScaleMax", "Max speed scale of the animation")
	v2_:register(XMLValueType.FLOAT, "pedestrianSystem.pedestrians.pedestrian(?).walkAnimation.stepSoundTrigger(?)#time", "Time of the step sound trigger")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.groups.group(?)#name", "Name of the group")
	v2_:register(XMLValueType.FLOAT, "pedestrianSystem.groups.group(?)#spawnWeight", "Weight of the group")
	v2_:register(XMLValueType.BOOL, "pedestrianSystem.groups.group(?)#allowHeadTurn", "If the pedestrian can turn the head to the player")
	v2_:register(XMLValueType.DAY_TIME, "pedestrianSystem.groups.group(?)#timeFrom", "Start day time of pedestrian visibility")
	v2_:register(XMLValueType.DAY_TIME, "pedestrianSystem.groups.group(?)#timeTo", "End day time of pedestrian visibility")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.groups.group(?).sounds.sound(?)#name", "Name of the sound")
	v2_:register(XMLValueType.STRING, "pedestrianSystem.groups.group(?).sounds.sound(?)#filename", "Filename of the sound")
	v2_:register(XMLValueType.FLOAT, "pedestrianSystem.groups.group(?).sounds.sound(?)#volume", "Volume of the sound")
	v2_:register(XMLValueType.FLOAT, "pedestrianSystem.groups.group(?).sounds.sound(?)#indoorVolume", "Indoor volume of the sound")
	v2_:register(XMLValueType.BOOL, "pedestrianSystem.groups.group(?).sounds.sound(?)#isWalkSound", "If sound is a walking sound")
end)

-- Local values: xmlFilename, mission
function PedestrianSystem:onCreate(transformId)
	if g_dedicatedServer == nil then
		local v4_ = getUserAttribute(transformId, "xmlFile")
		if v4_ == nil then
			Logging.error("Missing \'xmlFile\' user-attribute for pedestrian system in \'%s\'", I3DUtil.getNodePath(transformId))
		else
			local v5_ = g_currentMission
			local v6_ = Utils.getFilename(v4_, v5_.loadedMapBaseDirectory)
			PedestrianSystem.createFromXmlAndNode(v6_, transformId)
		end
	else
		Logging.devInfo("PedestrianSystem not available on Dedicated Server Host")
		return
	end
end

-- Local values: mission, existingPedestrianSystem, pedestrianSystem
function PedestrianSystem.createFromXmlAndNode(xmlFilename, transformId)
	local v9_ = g_currentMission
	local v10_ = v9_:getPedestrianSystem()
	if v10_ ~= nil and v10_.pedestrianSystemId ~= nil then
		Logging.error("Pedestrian system already present")
		return false
	end
	local v11_ = PedestrianSystem.new()
	if not v11_:load(xmlFilename, transformId) then
		v11_:delete()
		return false
	end
	if not v9_:setPedestrianSystem(v11_) then
		v11_:delete()
		return false
	end
	v9_:addUpdateable(v11_)
	g_messageCenter:publish(MessageType.PEDESTRIAN_SYSTEM_LOADED, v11_)
	return true
end
function PedestrianSystem.new()
	-- upvalues: (copy) PedestrianSystem_mt
	local v12_ = PedestrianSystem_mt
	local v13_ = setmetatable({}, v12_)
	local v14_ = g_currentMission
	v13_.pedestrianSystemId = nil
	v13_.isEnabled = false
	v13_.xmlFilename = nil
	v13_.transformId = nil
	v13_.baseDirectory = v14_.loadingMapBaseDirectory
	return v13_
end

-- Local values: obstaclesCollisionMask, groundMask, pedestrianSystemId, xmlFile, _, soundKey, soundName, filename, volume, indoorVolume, isWalkSound, soundId, maxTime, _, groupKey, groupName, spawnWeight, allowHeadTurn, timeFrom, timeTo, requiredFlags, preventFlags, groupId, _, groupSoundKey, soundName, filename, volume, indoorVolume, isWalkSound, soundId, _, pedestrianKey, graphics, requiredFlags, preventFlags, timeFrom, timeTo, args, idleAnimationName, _, staticIdleKey, staticIdleAnimationName, staticIdleAnimationId, animationName, blendWithAnimationName, distance, speedScaleMin, speedScaleMax, stepSoundTriggers, _, stepSoundTriggerKey, trigger, _, groupKey, groupName, group, playerStyle
function PedestrianSystem:load(xmlFilename, transformId)
	local v18_ = CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.TRAFFIC_VEHICLE
	local v19_ = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD
	local v20_ = createPedestrianSystem(xmlFilename, transformId, v19_, v18_, AudioGroup.ENVIRONMENT)
	if v20_ == 0 then
		Logging.error("Unable to create PedestrianSystem from \'%s\' and \'%s\'", xmlFilename, I3DUtil.getNodePath(transformId))
		return false
	end
	local v21_ = XMLFile.load("pedestrianSystem", xmlFilename, PedestrianSystem.xmlSchema)
	if v21_ == nil then
		return false
	end
	self.pedestrianSystemId = v20_
	self.xmlFilename = xmlFilename
	self.transformId = transformId
	self.conditionFlags = ConditionFlags.new()
	self.conditionFlags:registerModifier("sun", nil)
	self.conditionFlags:registerModifier("rain", nil)
	self.conditionFlags:registerModifier("cloudy", nil)
	self.conditionFlags:registerModifier("snow", nil)
	self.conditionFlags:registerModifier("spring", nil)
	self.conditionFlags:registerModifier("summer", nil)
	self.conditionFlags:registerModifier("autumn", nil)
	self.conditionFlags:registerModifier("winter", nil)
	self.conditionFlags:registerXMLPaths(PedestrianSystem.xmlSchema, "pedestrianSystem.groups.group(?)")
	self.conditionFlags:registerXMLPaths(PedestrianSystem.xmlSchema, "pedestrianSystem.pedestrians.pedestrian(?)")
	self.groupNameToGroup = {}
	self.soundNameToId = {}
	for _, v22_ in v21_:iterator("pedestrianSystem.sounds.sound") do
		local v23_ = v21_:getValue(v22_ .. "#name")
		local v24_ = v21_:getValue(v22_ .. "#filename")
		if v24_ == nil then
			Logging.xmlWarning(v21_, "Missing \'filename\' for pedestrian sound \'%s\'", v22_)
		elseif v23_ == nil then
			Logging.xmlWarning(v21_, "Missing \'name\' for pedestrian sound \'%s\'", v22_)
		elseif self.soundNameToId[v23_] == nil then
			local v25_ = v21_:getValue(v22_ .. "#volume", 1)
			local v26_ = v21_:getValue(v22_ .. "#indoorVolume", 1)
			local v27_ = v21_:getValue(v22_ .. "#isWalkSound", true)
			local v28_ = addPedestrianSound(v20_, v24_, v23_, v25_, v26_, v27_)
			self.soundNameToId[v23_] = v28_
		else
			Logging.xmlWarning(v21_, "Pedestrian sound name \'%s\' already used in \'%s\'", v23_, v22_)
		end
	end
	local v29_ = 86400000
	for _, v30_ in v21_:iterator("pedestrianSystem.groups.group") do
		local v31_ = v21_:getValue(v30_ .. "#name")
		if v31_ == nil then
			Logging.xmlWarning(v21_, "Missing \'name\' for pedestrian group \'%s\'", v30_)
		elseif self.groupNameToGroup[v31_] == nil then
			local v32_ = v21_:getValue(v30_ .. "#spawnWeight", 1)
			local v33_ = v21_:getValue(v30_ .. "#allowHeadTurn", true)
			local v34_ = v21_:getValue(v30_ .. "#timeFrom") or 0
			local v35_ = v21_:getValue(v30_ .. "#timeTo") or v29_
			local v36_, v37_ = self.conditionFlags:loadFlagsFromXMLFile(v21_, v30_)
			local v38_ = addPedestrianGroup(v20_, v31_, v32_, v33_, v36_, v37_, v34_, v35_)
			self.groupNameToGroup[v31_] = {
				["groupId"] = v38_,
				["timeFrom"] = v34_,
				["timeTo"] = v35_,
				["requiredFlags"] = v36_,
				["preventFlags"] = v37_
			}
			for _, v39_ in v21_:iterator(v30_ .. ".sounds.sound") do
				local v40_ = v21_:getValue(v39_ .. "#name")
				local v41_ = v21_:getValue(v39_ .. "#filename")
				if v41_ == nil then
					Logging.xmlWarning(v21_, "Missing \'filename\' for pedestrian sound \'%s\'", v39_)
				elseif v40_ == nil then
					Logging.xmlWarning(v21_, "Missing \'name\' for pedestrian sound \'%s\'", v39_)
				elseif self.soundNameToId[v40_] == nil then
					local v42_ = Utils.getFilename(v41_, self.baseDirectory)
					local v43_ = v21_:getValue(v39_ .. "#volume", 1)
					local v44_ = v21_:getValue(v39_ .. "#indoorVolume", 1)
					local v45_ = v21_:getValue(v39_ .. "#isWalkSound", true)
					local v46_ = addPedestrianSound(v20_, v42_, v40_, v43_, v44_, v45_)
					assignSoundToPedestrianGroup(v20_, v38_, v46_)
				else
					Logging.xmlWarning(v21_, "Pedestrian sound name \'%s\' already used in \'%s\'", v40_, v39_)
				end
			end
		else
			Logging.xmlWarning(v21_, "Pedestrian group name \'%s\' already used in \'%s\'", v31_, v30_)
		end
	end
	self.pedestrians = {}
	self.pedestrianNodes = {}
	self.pendingPedestrians = {}
	for _, v47_ in v21_:iterator("pedestrianSystem.pedestrians.pedestrian") do
		local v48_ = HumanGraphicsComponent.new()
		v48_:initialize()
		v48_.model.initIKChains = false
		link(getRootNode(), v48_.graphicsRootNode)
		local v49_, v50_ = self.conditionFlags:loadFlagsFromXMLFile(v21_, v47_)
		local v51_ = v21_:getValue(v47_ .. "#timeFrom") or 0
		local v52_ = v21_:getValue(v47_ .. "#timeTo") or v29_
		local v53_ = {
			["graphics"] = v48_,
			["variationName"] = v21_:getValue(v47_ .. "#variation", "male"),
			["requiredFlags"] = v49_,
			["preventFlags"] = v50_,
			["timeFrom"] = v51_,
			["timeTo"] = v52_,
			["groups"] = {},
			["idleAnimationId"] = 0,
			["staticIdleAnimationIds"] = {},
			["walkAnimationId"] = 0
		}
		local v54_ = v21_:getValue(v47_ .. ".idleAnimation#animationName")
		if v54_ ~= nil then
			v53_.idleAnimationId = addPedestrianIdleAnimation(v20_, v54_)
		end
		for _, v55_ in v21_:iterator(v47_ .. ".staticIdleAnimation") do
			local v56_ = v21_:getValue(v55_ .. "#animationName")
			if v56_ ~= nil then
				local v57_ = addPedestrianIdleAnimation(v20_, v56_)
				local v58_ = v53_.staticIdleAnimationIds
				table.insert(v58_, v57_)
			end
		end
		local v59_ = v21_:getValue(v47_ .. ".walkAnimation#animationName")
		local v60_ = v21_:getValue(v47_ .. ".walkAnimation#blendWithAnimationName")
		local v61_ = v21_:getValue(v47_ .. ".walkAnimation#distance")
		local v62_ = v21_:getValue(v47_ .. ".walkAnimation#speedScaleMin")
		local v63_ = v21_:getValue(v47_ .. ".walkAnimation#speedScaleMax")
		local v64_ = {}
		for _, v65_ in v21_:iterator(v47_ .. ".walkAnimation.stepSoundTrigger") do
			local v66_ = v21_:getValue(v65_ .. "#time")
			table.insert(v64_, v66_)
		end
		v53_.walkAnimationId = addPedestrianWalkAnimation(v20_, v59_, v60_, v61_, v62_, v63_, v64_)
		for _, v67_ in v21_:iterator(v47_ .. ".groups.group") do
			local v68_ = v21_:getValue(v67_ .. "#name")
			if v68_ == nil then
				Logging.xmlWarning(v21_, "Missing \'name\' for pedestrian group \'%s\'", v67_)
			else
				local v69_ = self.groupNameToGroup[v68_]
				if v69_ == nil then
					Logging.xmlWarning(v21_, "Pedestrian group name \'%s\' is not defined in \'%s\'", v68_, v67_)
				else
					local v70_ = v53_.groups
					local v71_ = v69_.groupId
					table.insert(v70_, v71_)
				end
			end
		end
		local v72_ = PlayerStyle.new()
		v72_:loadFromXMLFile(v21_, v47_ .. ".style")
		v48_:setStyleAsync(v72_, self.loadCharacterFinished, self, v53_)
		self.pendingPedestrians[v48_] = true
	end
	v21_:delete()
	addConsoleCommand("gsPedestrianSystemToggle", "Toggle pedestrian system", "consoleCommandPedestrianSystemToggle", self)
	addConsoleCommand("gsPedestrianSystemReload", "Reload pedestrian system xml", "consoleCommandPedestrianSystemReload", self)
	addConsoleCommand("gsPedestrianSystemDebug", "Debug pedestrian system", "consoleCommandPedestrianSystemDebug", self)
	g_soundManager:addIndoorStateChangedListener(self)
	setPedestrianSystemUseOutdoorAudioSetup(self.pedestrianSystemId, not g_soundManager:getIsIndoor())
	return true
end

-- Local values: graphics, pedestrianSystemId, rootNode, skeletonNode, headNode, skeletonPathIndices, headPathIndices, pedestrianNode, pedestrianId, _, groupId, _, id
function PedestrianSystem:loadCharacterFinished(loadingState, loadedNewModel, arguments)
	local v76_ = arguments.graphics
	if loadingState == HumanModelLoadingState.OK then
		local v77_ = self.pedestrianSystemId
		local v78_ = v76_.model:getRootNode()
		local v79_ = v76_.model:getSkeletonNode()
		local v80_ = v76_.model.i3dMappings.head.nodeId
		local v81_ = I3DUtil.getRelativeNodePathIndices(v79_, v78_)
		local v82_ = I3DUtil.getRelativeNodePathIndices(v80_, v78_)
		local v83_ = clone(v78_, false, false, false)
		link(getRootNode(), v83_)
		setName(v83_, getName(v83_) .. "_pedestrian")
		setVisibility(v83_, false)
		local v84_ = addPedestrian(v77_, v83_, v81_, v82_, arguments.variationName, arguments.requiredFlags, arguments.preventFlags, arguments.timeFrom, arguments.timeTo)
		assignWalkAnimationToPedestrian(v77_, v84_, arguments.walkAnimationId, arguments.idleAnimationId or 0)
		for _, v85_ in ipairs(arguments.groups) do
			assignPedestrianToPedestrianGroup(v77_, v85_, v84_)
		end
		for _, v86_ in ipairs(arguments.staticIdleAnimationIds) do
			assignIdleAnimationToPedestrian(v77_, v84_, v86_)
		end
		local v87_ = self.pedestrians
		table.insert(v87_, v84_)
		local v88_ = self.pedestrianNodes
		table.insert(v88_, v83_)
		v76_:delete()
	end
	self.pendingPedestrians[v76_] = nil
end

-- Local values: mission, _, pedestrian, graphics, _, _, node
function PedestrianSystem:delete()
	local v90_ = g_currentMission
	if self.pedestrianSystemId ~= nil then
		for _, v91_ in ipairs(self.pedestrians) do
			removePedestrian(self.pedestrianSystemId, v91_)
		end
		for v92_, _ in pairs(self.pendingPedestrians) do
			v92_:delete()
		end
		setPedestrianSystemEnabled(self.pedestrianSystemId, false)
		if v90_:getHasUpdateable(self) then
			v90_:removeUpdateable(self)
		end
		v90_:setPedestrianSystem(nil)
		delete(self.pedestrianSystemId)
		self.pedestrianSystemId = nil
		for _, v93_ in ipairs(self.pedestrianNodes) do
			delete(v93_)
		end
		self.conditionFlags:delete()
	end
	g_messageCenter:unsubscribeAll(self)
	g_soundManager:removeIndoorStateChangedListener(self)
	v90_:removeDrawable(self)
	removeConsoleCommand("gsPedestrianSystemToggle")
	removeConsoleCommand("gsPedestrianSystemReload")
	removeConsoleCommand("gsPedestrianSystemDebug")
end

-- Local values: mission, environment, mask
function PedestrianSystem:update(dt)
	if self.pedestrianSystemId ~= nil then
		local v95_ = g_currentMission.environment
		self:updateMask()
		local v96_ = self.conditionFlags:getMask()
		setPedestrianSystemMask(self.pedestrianSystemId, v96_)
		setPedestrianSystemDaytime(self.pedestrianSystemId, v95_.dayTime)
	end
end

-- Local values: posY, textSize, textOffset, name, group
function PedestrianSystem:draw()
	if self.debugEnabled then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		renderText(0.1, 0.72, getCorrectTextSize(0.014), "Groups:")
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v98_ = getCorrectTextSize(0.012)
		local v99_ = getCorrectTextSize(0.001)
		local v100_ = 0.7
		for v101_, v102_ in pairs(self.groupNameToGroup) do
			renderText(0.1, v100_, v98_, v101_)
			renderText(0.2, v100_, v98_, (tostring(self:isGroupPossible(v102_))))
			v100_ = v100_ - v98_ - v99_
		end
		self.conditionFlags:drawDebug(0.7, 0.72)
	end
end

-- Local values: conditionFlags, mission, environment, weather, typeIndex, rainFallScale, snowFallScale
function PedestrianSystem:updateMask()
	local v104_ = self.conditionFlags
	local v105_ = g_currentMission.environment
	local v106_ = v105_.weather
	local v107_ = v106_:getCurrentWeatherType()
	local v108_ = v106_:getRainFallScale()
	local v109_ = v106_:getSnowFallScale()
	v104_:setModifierValue("spring", v105_.currentVisualSeason == Season.SPRING)
	v104_:setModifierValue("summer", v105_.currentVisualSeason == Season.SUMMER)
	v104_:setModifierValue("autumn", v105_.currentVisualSeason == Season.AUTUMN)
	v104_:setModifierValue("winter", v105_.currentVisualSeason == Season.WINTER)
	v104_:setModifierValue("sun", v107_ == WeatherType.SUN)
	v104_:setModifierValue("cloudy", v107_ == WeatherType.CLOUDY)
	v104_:setModifierValue("rain", v108_ > 0)
	v104_:setModifierValue("snow", v109_ > 0)
end

function PedestrianSystem:setEnabled(state)
	if self.pedestrianSystemId ~= nil then
		setPedestrianSystemEnabled(self.pedestrianSystemId, state)
		self.isEnabled = state
	end
end

-- Local values: mask, match, mission, dayTime, timeFrom, timeTo
function PedestrianSystem:isGroupPossible(group)
	local v114_ = self.conditionFlags:getMask()
	local v115_ = group.preventFlags
	local v116_
	if bit32.band(v114_, v115_) == 0 then
		local v117_ = group.requiredFlags
		v116_ = bit32.band(v114_, v117_) == group.requiredFlags
	else
		v116_ = false
	end
	if not v116_ then
		return false
	end
	local v118_ = g_currentMission.environment.dayTime
	local v119_ = group.timeFrom
	local v120_ = group.timeTo
	return not MathUtil.getIsOutOfBounds(v118_, v119_, v120_)
end

-- Local values: mission, pedestrianSystem
function PedestrianSystem:consoleCommandPedestrianSystemToggle(state)
	local v122_ = g_currentMission:getPedestrianSystem()
	if v122_ == nil or v122_.pedestrianSystemId == nil then
		return "Error: No pedestrian system available"
	end
	local v123_ = Utils.stringToBoolean(state) or not v122_.isEnabled
	v122_:setEnabled(v123_)
	return "setPedestrianSystemEnabled=" .. tostring(v123_)
end

-- Local values: mission, oldPedestrianSystem, xmlFilename, transformId, isEnabled
function PedestrianSystem:consoleCommandPedestrianSystemReload()
	local v124_ = g_currentMission
	local v125_ = v124_:getPedestrianSystem()
	if v125_ == nil or v125_.pedestrianSystemId == nil then
		return "Error: No pedestrian system to reload"
	end
	local v126_ = v125_.xmlFilename
	local v127_ = v125_.transformId
	local v128_ = v125_.isEnabled
	v125_:delete()
	if not PedestrianSystem.createFromXmlAndNode(v126_, v127_) then
		return "Error while reloading pedestrian system"
	end
	v124_:getPedestrianSystem():setEnabled(v128_)
	return string.format("Reloaded pedestrian system from \'%s\'", v126_)
end

-- Local values: mission, pedestrianSystem
function PedestrianSystem:consoleCommandPedestrianSystemDebug()
	local v130_ = g_currentMission
	local v131_ = v130_:getPedestrianSystem()
	if v131_ == nil or v131_.pedestrianSystemId == nil then
		return "Error: No pedestrian system available"
	end
	self.debugEnabled = not self.debugEnabled
	if self.debugEnabled then
		v130_:addDrawable(self)
		I3DUtil.iterateRecursively(self.transformId, function(p132_)
			if I3DUtil.getIsSpline(p132_) then
				g_debugManager:addElement(DebugSpline.new():createWithNode(p132_), "pedestrianSystem")
			end
		end)
	else
		v130_:removeDrawable(self)
		g_debugManager:removeGroup("pedestrianSystem")
	end
	local v133_ = string.format
	local v134_ = self.debugEnabled
	return v133_("PedestrianSystem debugEnabled=%s", (tostring(v134_)))
end

function PedestrianSystem:onIndoorStateChanged(isIndoor)
	setPedestrianSystemUseOutdoorAudioSetup(self.pedestrianSystemId, not g_soundManager:getIsIndoor())
end
