-- Local values: PlaceableLightsActivatable_mt
PlaceableLights = {}
source("dataS/scripts/placeables/specializations/events/PlaceableLightsStateEvent.lua")
PlaceableLights.MAX_NUM_BITS = 5
PlaceableLights.MAX_NUM_GROUPS = 2 ^ PlaceableLights.MAX_NUM_BITS

function PlaceableLights.prerequisitesPresent(self)
	return true
end

function PlaceableLights.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "lightSetupChanged", PlaceableLights.lightSetupChanged)
	SpecializationUtil.registerFunction(placeableType, "getUseHighProfile", PlaceableLights.getUseHighProfile)
	SpecializationUtil.registerFunction(placeableType, "setGroupIsActive", PlaceableLights.setGroupIsActive)
	SpecializationUtil.registerFunction(placeableType, "lightsTriggerCallback", PlaceableLights.lightsTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "sharedLightLoaded", PlaceableLights.sharedLightLoaded)
	SpecializationUtil.registerFunction(placeableType, "updateLightState", PlaceableLights.updateLightState)
end

function PlaceableLights.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableLights)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableLights)
end

function PlaceableLights.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Lights")
	schema:register(XMLValueType.STRING, basePath .. ".lights.sharedLight(?)#filename", "Path to shared light xml file")
	schema:register(XMLValueType.INT, basePath .. ".lights.sharedLight(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.sharedLight(?)#linkNode", "Link node")
	schema:register(XMLValueType.COLOR, basePath .. ".lights.sharedLight(?)#color", "Light color")
	schema:register(XMLValueType.STRING, basePath .. ".lights.sharedLight(?).rotationNode(?)#name", "Rotation node name")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".lights.sharedLight(?).rotationNode(?)#rotation", "Rotation to set")
	schema:register(XMLValueType.INT, basePath .. ".lights.lightShape(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.lightShape(?)#node", "Light shape / self-illum-mesh node. Always visible, only shader is set")
	schema:register(XMLValueType.FLOAT, basePath .. ".lights.lightShape(?)#intensity", "Intensity for the shader if active", 5)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.realLights.low.light(?)#node", "Real light node used on low performance profile. Visibility is toggled based on settings")
	schema:register(XMLValueType.INT, basePath .. ".lights.realLights.low.light(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.realLights.high.light(?)#node", "Real light node used on high performance profile. Visibility is toggled based on settings")
	schema:register(XMLValueType.INT, basePath .. ".lights.realLights.high.light(?)#groupIndex", "Parent group", 1)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".lights.group(?)#triggerNode", "Activation Trigger for manual control")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#inputAction", "Input Action name", "INTERACT")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".lights.group(?)#name", "Group name for display", "action_placeableLightShed")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".lights.group(?)#activateText", "Activate text to display in help menu", "action_placeableLightPos")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".lights.group(?)#deactivateText", "Deactivate text to display in help menu", "action_placeableLightNeg")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#activateTime", "If defined, light will be turned on at this time of day. Format hh:mm")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#deactivateTime", "If defined, light will be turned off at this time of day. Format hh:mm")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#weatherRequiredFlags", "Space separated list of environment flag names to be used as required mask")
	schema:register(XMLValueType.STRING, basePath .. ".lights.group(?)#weatherPreventFlags", "Space separated list of environment flag names to be used as prevent mask")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".lights.group(?).sounds", "toggle")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, environmentMaskSystem, getNodeShaderLightIntensity, loadRealLight
function PlaceableLights:onLoad(savegame)
	local v_u_6_ = self.spec_lights
	local v_u_7_ = self.xmlFile
	local v_u_8_ = g_currentMission.environment.environmentMaskSystem
	v_u_6_.sharedLights = {}
	v_u_6_.groups = {}
	v_u_6_.triggerToGroup = {}
	v_u_6_.activatable = PlaceableLightsActivatable.new(self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED.lightsProfile, self.lightSetupChanged, self)
	v_u_7_:iterate("placeable.lights.group", function(_, p9_)
		-- upvalues: (copy) v_u_7_, (copy) self, (copy) v_u_6_, (copy) v_u_8_
		local v10_ = {
			["triggerNode"] = v_u_7_:getValue(p9_ .. "#triggerNode", nil, self.components, self.i3dMappings)
		}
		if v10_.triggerNode ~= nil then
			addTrigger(v10_.triggerNode, "lightsTriggerCallback", self)
			v_u_6_.triggerToGroup[v10_.triggerNode] = v10_
		end
		local v11_ = v_u_7_:getValue(p9_ .. "#inputAction", "INTERACT")
		v10_.inputAction = InputAction[v11_] or InputAction.INTERACT
		v10_.name = v_u_7_:getValue(p9_ .. "#name", "action_placeableLightShed", self.customEnvironment)
		v10_.activateText = v_u_7_:getValue(p9_ .. "#activateText", "action_placeableLightPos", self.customEnvironment)
		v10_.deactivateText = v_u_7_:getValue(p9_ .. "#deactivateText", "action_placeableLightNeg", self.customEnvironment)
		local v12_ = v_u_7_:getValue(p9_ .. "#activateTime", nil)
		if v12_ ~= nil then
			v10_.activateMinute = Utils.getMinuteOfDayFromTime(v12_)
			if v10_.activateMinute == nil then
				Logging.xmlWarning(v_u_7_, "Invalid activateTime string \'%s\' given for group \'%s\'. Use \'hh:mm\' format", v12_, p9_)
			else
				local v13_ = v10_.activateMinute
				v10_.activateMinute = math.max(1, v13_)
			end
		end
		local v14_ = v_u_7_:getValue(p9_ .. "#deactivateTime", nil)
		if v14_ ~= nil then
			v10_.deactivateMinute = Utils.getMinuteOfDayFromTime(v14_)
			if v10_.deactivateMinute == nil then
				Logging.xmlWarning(v_u_7_, "Invalid deactivateTime string \'%s\' given for group \'%s\'. Use \'hh:mm\' format", v14_, p9_)
			else
				local v15_ = v10_.deactivateMinute
				v10_.deactivateMinute = math.max(1, v15_)
			end
		end
		v10_.weatherRequiredMask = v_u_8_:getWeatherMaskFromFlagNames(v_u_7_:getValue(p9_ .. "#weatherRequiredFlags", nil))
		v10_.weatherPreventMask = v_u_8_:getWeatherMaskFromFlagNames(v_u_7_:getValue(p9_ .. "#weatherPreventFlags", nil))
		if self.isClient then
			v10_.samples = {}
			v10_.samples.toggle = g_soundManager:loadSampleFromXML(v_u_7_, p9_ .. ".sounds", "toggle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
		end
		local v16_
		if v10_.activateMinute == nil then
			v16_ = false
		else
			v16_ = v10_.deactivateMinute
		end
		if v16_ == nil or v10_.deactivateMinute == nil and v10_.activateMinute ~= nil then
			Logging.xmlWarning(v_u_7_, "Incomplete automatic toggle time in \'%s\'", p9_)
			return
		else
			v10_.hasManualLights = v10_.triggerNode ~= nil
			v10_.isActive = false
			v10_.playerInRange = false
			if #v_u_6_.groups < PlaceableLights.MAX_NUM_GROUPS then
				local v17_ = v_u_6_.groups
				table.insert(v17_, v10_)
				v10_.index = #v_u_6_.groups
			else
				Logging.xmlWarning(v_u_7_, "Too many light groups registered. Max. %d are allowed", PlaceableLights.MAX_NUM_GROUPS)
			end
		end
	end)
	v_u_7_:iterate("placeable.lights.sharedLight", function(_, p18_)
		-- upvalues: (copy) v_u_7_, (copy) self, (copy) v_u_6_
		local v_u_19_ = {}
		local v20_ = v_u_7_:getValue(p18_ .. "#filename")
		if v20_ ~= nil then
			v_u_19_.xmlFilename = Utils.getFilename(v20_, self.baseDirectory)
			v_u_19_.groupIndex = v_u_7_:getValue(p18_ .. "#groupIndex", 1)
			v_u_19_.color = v_u_7_:getValue(p18_ .. "#color", nil, true)
			v_u_19_.linkNode = v_u_7_:getValue(p18_ .. "#linkNode", "0>", self.components, self.i3dMappings)
			local v21_ = v_u_6_.groups[v_u_19_.groupIndex]
			if v21_ == nil then
				Logging.xmlError(v_u_7_, "Group index \'%d\' in \'%s\' does not exist", v_u_19_.groupIndex, p18_)
				return
			end
			if v_u_19_.linkNode ~= nil then
				v_u_7_:iterate(p18_ .. ".rotationNode", function(_, p22_)
					-- upvalues: (ref) v_u_7_, (copy) v_u_19_
					local v23_ = v_u_7_:getValue(p22_ .. "#name")
					local v24_ = v_u_7_:getValue(p22_ .. "#rotation", nil, true)
					if v23_ ~= nil and v24_ ~= nil then
						v_u_19_.rotations = v_u_19_.rotations or {}
						v_u_19_.rotations[v23_] = v24_
					end
				end)
				local v25_ = XMLFile.load("placeableSharedLight", v_u_19_.xmlFilename, SharedLight.xmlSchema)
				if v25_ ~= nil then
					local v26_ = v25_:getValue("light.filename")
					if v26_ ~= nil then
						local v27_ = self:createLoadingTask(v_u_6_)
						local v28_ = Utils.getFilename(v26_, self.baseDirectory)
						v_u_19_.lightXMLFile = v25_
						v_u_19_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v28_, false, false, self.sharedLightLoaded, self, {
							["sharedLight"] = v_u_19_,
							["lightXMLFile"] = v25_,
							["loadingTask"] = v27_,
							["group"] = v21_,
							["filename"] = v28_
						})
						local v29_ = v_u_6_.sharedLights
						table.insert(v29_, v_u_19_)
						return
					end
					Logging.xmlWarning(v25_, "Missing light i3d filename!")
					v25_:delete()
				end
			end
		end
	end)
	v_u_6_.lightShapes = {}
	v_u_7_:iterate("placeable.lights.lightShape", function(_, p30_)
		-- upvalues: (copy) v_u_7_, (copy) self, (copy) v_u_6_
		local v31_ = {
			["groupIndex"] = v_u_7_:getValue(p30_ .. "#groupIndex", 1),
			["node"] = v_u_7_:getValue(p30_ .. "#node", "0>", self.components, self.i3dMappings)
		}
		if v31_.node ~= nil then
			local v32_ = v_u_7_
			local v33_ = p30_ .. "#intensity"
			local v34_ = v31_.node
			v31_.intensity = v32_:getValue(v33_, not (getHasClassId(v34_, ClassIds.SHAPE) and getHasShaderParameter(v34_, "lightControl")) and 1 or getShaderParameter(v34_, "lightControl"))
			local v35_ = v_u_6_.groups[v31_.groupIndex]
			if v35_ == nil then
				Logging.xmlError(v_u_7_, "Group index \'%d\' in \'%s\' does not exist", v31_.groupIndex, p30_)
			elseif not v35_.hasManualLights then
				if v35_.activateMinute ~= nil then
					setVisibilityConditionMinuteOfDay(v31_.node, v35_.activateMinute, v35_.deactivateMinute)
				end
				if v35_.weatherRequiredMask ~= nil or v35_.weatherPreventMask ~= nil then
					setVisibilityConditionWeatherMask(v31_.node, v35_.weatherRequiredMask or 0, v35_.weatherPreventMask or 0)
				end
				setVisibilityConditionRenderInvisible(v31_.node, true)
				setVisibilityConditionVisibleShaderParameter(v31_.node, v31_.intensity)
			end
			local v36_ = v_u_6_.lightShapes
			table.insert(v36_, v31_)
		end
	end)
	v_u_6_.realLights = {
		["low"] = {},
		["high"] = {}
	}
	local function v_u_41_(p37_, p38_)
		-- upvalues: (copy) v_u_7_, (copy) self, (copy) v_u_6_
		local v39_ = {
			["node"] = v_u_7_:getValue(p37_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v39_.node ~= nil then
			v39_.groupIndex = v_u_7_:getValue(p37_ .. "#groupIndex", 1)
			local v40_ = v_u_6_.groups[v39_.groupIndex]
			if v40_ == nil then
				Logging.xmlError(v_u_7_, "Group index \'%d\' in \'%s\' does not exist", v39_.groupIndex, p37_)
				return
			end
			if v40_.activateMinute ~= nil then
				setVisibilityConditionMinuteOfDay(v39_.node, v40_.activateMinute, v40_.deactivateMinute)
			end
			if v40_.weatherRequiredMask ~= nil or v40_.weatherPreventMask ~= nil then
				setVisibilityConditionWeatherMask(v39_.node, v40_.weatherRequiredMask or 0, v40_.weatherPreventMask or 0)
			end
			table.insert(p38_, v39_)
		end
	end
	v_u_7_:iterate("placeable.lights.realLights.low.light", function(_, p42_)
		-- upvalues: (copy) v_u_41_, (copy) v_u_6_
		v_u_41_(p42_, v_u_6_.realLights.low)
	end)
	v_u_7_:iterate("placeable.lights.realLights.high.light", function(_, p43_)
		-- upvalues: (copy) v_u_41_, (copy) v_u_6_
		v_u_41_(p43_, v_u_6_.realLights.high)
	end)
end

function PlaceableLights:onFinalizePlacement()
	self:lightSetupChanged()
end

-- Local values: sharedLight, lightXMLFile, loadingTask, lightGroup, i3dFilename
function PlaceableLights:sharedLightLoaded(i3dNode, failedReason, args)
	local v_u_48_ = args.sharedLight
	local v_u_49_ = args.lightXMLFile
	local v50_ = args.loadingTask
	local v_u_51_ = args.group
	local v52_ = args.filename
	if i3dNode ~= nil and i3dNode ~= 0 then
		if self.loadingState == PlaceableLoadingState.OK then
			v_u_48_.node = v_u_49_:getValue("light.rootNode#node", "0", i3dNode)
			v_u_48_.i3dFilename = v52_
			v_u_48_.lightShapes = {}
			v_u_49_:iterate("light.defaultLight", function(_, p53_)
				-- upvalues: (copy) v_u_49_, (copy) i3dNode, (copy) v_u_51_, (copy) v_u_48_
				local v54_ = {
					["node"] = v_u_49_:getValue(p53_ .. "#node", nil, i3dNode)
				}
				if v54_.node == nil then
					Logging.xmlWarning(v_u_49_, "Could not find node for \'%s\'!", p53_)
				else
					if getHasShaderParameter(v54_.node, "lightControl") then
						v54_.intensity = v_u_49_:getValue(p53_ .. "#intensity", 5)
						if v_u_51_.hasManualLights then
							setShaderParameter(v54_.node, "lightControl", 0, 0, 0, 0, false)
						else
							if v_u_51_.activateMinute ~= nil then
								setVisibilityConditionMinuteOfDay(v54_.node, v_u_51_.activateMinute, v_u_51_.deactivateMinute)
							end
							if v_u_51_.weatherRequiredMask ~= nil or v_u_51_.weatherPreventMask ~= nil then
								setVisibilityConditionWeatherMask(v54_.node, v_u_51_.weatherRequiredMask or 0, v_u_51_.weatherPreventMask or 0)
							end
							setVisibilityConditionRenderInvisible(v54_.node, true)
							setVisibilityConditionVisibleShaderParameter(v54_.node, v54_.intensity)
						end
						local v55_ = v_u_48_.lightShapes
						table.insert(v55_, v54_)
					else
						Logging.xmlWarning(v_u_49_, "Node \'%s\' has no shaderparameter \'lightControl\'. Ignoring node!", getName(v54_.node))
					end
					if v_u_48_.color ~= nil and getHasShaderParameter(v54_.node, "colorScale") then
						setShaderParameter(v54_.node, "colorScale", v_u_48_.color[1], v_u_48_.color[2], v_u_48_.color[3], 0, false)
						return
					end
				end
			end)
			v_u_49_:iterate("light.rotationNode", function(_, p56_)
				-- upvalues: (copy) v_u_49_, (copy) i3dNode, (copy) v_u_48_
				local v57_ = v_u_49_:getValue(p56_ .. "#name")
				if v57_ ~= nil then
					local v58_ = v_u_49_:getValue(p56_ .. "#node", nil, i3dNode)
					if v_u_48_.rotations ~= nil and v_u_48_.rotations[v57_] ~= nil then
						local v59_ = setRotation
						local v60_ = v_u_48_.rotations[v57_]
						v59_(v58_, unpack(v60_))
					end
				end
			end)
			v_u_48_.rotations = nil
			link(v_u_48_.linkNode, v_u_48_.node)
		end
		delete(i3dNode)
	end
	v_u_49_:delete()
	v_u_48_.lightXMLFile = nil
	self:finishLoadingTask(v50_)
end

-- Local values: spec, _, light, _, group
function PlaceableLights:onDelete()
	local v62_ = self.spec_lights
	if v62_.sharedLights ~= nil then
		for _, v63_ in ipairs(v62_.sharedLights) do
			if v63_.lightXMLFile ~= nil then
				v63_.lightXMLFile:delete()
				v63_.lightXMLFile = nil
			end
			if v63_.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v63_.sharedLoadRequestId)
				v63_.sharedLoadRequestId = nil
			end
		end
		v62_.sharedLights = {}
	end
	g_messageCenter:unsubscribeAll(self)
	g_currentMission.activatableObjectsSystem:removeActivatable(v62_.activatable)
	if v62_.groups ~= nil then
		for _, v64_ in ipairs(v62_.groups) do
			if v64_.triggerNode ~= nil then
				removeTrigger(v64_.triggerNode)
			end
			g_soundManager:deleteSamples(v64_.samples)
		end
		v62_.groups = {}
	end
end

-- Local values: spec, k, group
function PlaceableLights:onReadStream(streamId, connection)
	local v67_ = self.spec_lights
	for v68_, v69_ in ipairs(v67_.groups) do
		if v69_.hasManualLights then
			self:setGroupIsActive(v68_, streamReadBool(streamId), true)
		end
	end
end

-- Local values: spec, _, group
function PlaceableLights:onWriteStream(streamId, connection)
	local v72_ = self.spec_lights
	for _, v73_ in ipairs(v72_.groups) do
		if v73_.hasManualLights then
			streamWriteBool(streamId, v73_.isActive)
		end
	end
end

function Pl-- Local values: lightsProfile
aceableLights.getUseHighProfile(self)
	local v74_ = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	return Utils.getNoNil(Platform.gameplay.lightsProfile, v74_) >= GS_PROFILE_HIGH
end

-- Local values: spec, group
function PlaceableLights:setGroupIsActive(groupIndex, isActive, noEventSend)
	local v79_ = self.spec_lights.groups[groupIndex]
	if v79_ ~= nil then
		v79_.isActive = Utils.getNoNil(isActive, not v79_.isActive)
		self:updateLightState(groupIndex, v79_.isActive)
		PlaceableLightsStateEvent.sendEvent(self, groupIndex, v79_.isActive, noEventSend)
		if self.isClient then
			g_soundManager:playSample(v79_.samples.toggle, 1)
		end
	end
end

-- Local values: spec, group, _, sharedLight, j, lightShape, _, lightShape, activeLightSetup, inactiveLightSetup, _, realLight, _, realLight
function PlaceableLights:updateLightState(groupIndex, isActive)
	local v83_ = self.spec_lights
	local v84_ = v83_.groups[groupIndex]
	if v84_.hasManualLights then
		for _, v85_ in ipairs(v83_.sharedLights) do
			if v85_.groupIndex == groupIndex then
				for v86_ = 1, #v85_.lightShapes do
					local v87_ = v85_.lightShapes[v86_]
					setShaderParameter(v87_.node, "lightControl", isActive and v87_.intensity or 0, 0, 0, 0, false)
				end
			end
		end
		for _, v88_ in ipairs(v83_.lightShapes) do
			if v88_.groupIndex == groupIndex then
				setShaderParameter(v88_.node, "lightControl", isActive and v88_.intensity or 0, 0, 0, 0, false)
			end
		end
	end
	local v89_ = v83_.realLights.low
	local v90_ = v83_.realLights.high
	if self:getUseHighProfile() then
		v89_ = v83_.realLights.high
		v90_ = v83_.realLights.low
	end
	for _, v91_ in ipairs(v89_) do
		if v91_.groupIndex == groupIndex then
			setVisibility(v91_.node, not v84_.hasManualLights or isActive)
		end
	end
	for _, v92_ in ipairs(v90_) do
		if v92_.groupIndex == groupIndex then
			setVisibility(v92_.node, false)
		end
	end
end

-- Local values: spec, group, player, inRangeOfOtherGroups, _, otherGroup
function PlaceableLights:lightsTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v98_ = self.spec_lights
	local v99_ = v98_.triggerToGroup[triggerId]
	if v99_ ~= nil and (onEnter or onLeave) then
		local v100_ = g_localPlayer
		if v100_ ~= nil and otherId == v100_.rootNode then
			if onEnter then
				v99_.playerInRange = true
				g_currentMission.activatableObjectsSystem:addActivatable(v98_.activatable)
				v98_.activatable:setGroupIndex(v99_.index)
				return
			end
			v99_.playerInRange = false
			local v101_ = false
			for _, v102_ in ipairs(v98_.groups) do
				v101_ = v101_ or v102_.playerInRange
			end
			if not v101_ then
				g_currentMission.activatableObjectsSystem:removeActivatable(v98_.activatable)
			end
		end
	end
end

-- Local values: spec, k, group
function PlaceableLights:lightSetupChanged()
	local v104_ = self.spec_lights
	for v105_, v106_ in ipairs(v104_.groups) do
		self:updateLightState(v105_, v106_.isActive)
	end
end
PlaceableLightsActivatable = {}
local v_u_107_ = Class(PlaceableLightsActivatable)

-- Upvalues: PlaceableLightsActivatable_mt
-- Local values: self
function PlaceableLightsActivatable.new(placeable)
	-- upvalues: (copy) v_u_107_
	local v109_ = v_u_107_
	local v110_ = setmetatable({}, v109_)
	v110_.placeable = placeable
	v110_.groupIndex = 1
	v110_.activateText = ""
	return v110_
end

function PlaceableLightsActivatable:setGroupIndex(groupIndex)
	self.groupIndex = groupIndex or 1
	self:updateActivateText()
end

function PlaceableLightsActivatable:run()
	self.placeable:setGroupIsActive(self.groupIndex)
	self:updateActivateText()
end

-- Local values: group
function PlaceableLightsActivatable:updateActivateText()
	local v115_ = self.placeable.spec_lights.groups[self.groupIndex]
	if v115_.triggerNode ~= nil then
		if v115_.isActive then
			self.activateText = string.format(v115_.deactivateText, v115_.name)
			return
		end
		self.activateText = string.format(v115_.activateText, v115_.name)
	end
end

-- Local values: group, tx, ty, tz
function PlaceableLightsActivatable:getDistance(x, y, z)
	local v120_ = self.placeable.spec_lights.groups[self.groupIndex]
	if v120_.triggerNode == nil then
		return math.huge
	end
	local v121_, v122_, v123_ = getWorldTranslation(v120_.triggerNode)
	return MathUtil.vector3Length(x - v121_, y - v122_, z - v123_)
end
