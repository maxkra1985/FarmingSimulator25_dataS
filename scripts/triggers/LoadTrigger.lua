-- Local values: LoadTrigger_mt, LoadTriggerActivatable_mt
LoadTrigger = {}
local LoadTrigger_mt = Class(LoadTrigger, Object)
InitStaticObjectClass(LoadTrigger, "LoadTrigger")

function LoadTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLitersPerSecond", "Fill liters per second")
	schema:register(XMLValueType.BOOL, basePath .. "#useTimeScale", "If fillLitersPerSecond should be multiplied with timescale", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#dischargeNode", "Discharge node")
	schema:register(XMLValueType.FLOAT, basePath .. "#dischargeWidth", "Discharge width", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. "#dischargeLength", "Discharge length", 0.5)
	schema:register(XMLValueType.STRING, basePath .. "#fillSoundIdentifier", "Fill sound identifier in map sound xml")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#fillSoundNode", "Fill sound link node")
	EffectManager.registerEffectXMLPaths(schema, basePath)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "loading")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#scrollerNode", "Scroller node")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Scroller shader parameter name", "uvScrollSpeed")
	schema:register(XMLValueType.VECTOR_2, basePath .. "#scrollerScrollSpeed", "Scroller speed scale", "0 -0.75")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported fill type categories")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported fill types")
	schema:register(XMLValueType.BOOL, basePath .. "#autoStart", "Auto start loading", false)
	schema:register(XMLValueType.BOOL, basePath .. "#infiniteCapacity", "Has infinite capacity", false)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresExactFillRootNode", "Only checks for exactfillrootnode", true)
	schema:register(XMLValueType.STRING, basePath .. "#startFillText", "Start fill text")
	schema:register(XMLValueType.STRING, basePath .. "#stopFillText", "Stop fill text")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#aiNode", "AI target node, required for the station to support AI. AI drives to the node in positive Z direction. Height is not relevant.")
end

-- Upvalues: LoadTrigger_mt
-- Local values: self
function LoadTrigger.new(isServer, isClient, customMt)
	-- upvalues: (copy) LoadTrigger_mt
	local v7_ = Object.new(isServer, isClient, customMt or LoadTrigger_mt)
	v7_.fillableObjects = {}
	return v7_
end

-- Local values: triggerNode, dischargeNode, width, length, directory, modName, baseDirectory, fillSoundIdentifier, fillSoundNode, xmlSoundFile, fillTypeCategories, fillTypeNames, fillTypes, _, fillType
function LoadTrigger:load(components, xmlFile, xmlNode, i3dMappings, rootNode)
	self.rootNode = rootNode or xmlFile:getValue(xmlNode .. "#node", nil, components, i3dMappings)
	if self.rootNode == nil then
		Logging.xmlError(xmlFile, "Missing node \'%s#node\'", xmlNode)
		return false
	end
	self.objectsInTriggers = {}
	XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlNode .. "#scrollerIndex", xmlNode .. "#scrollerNode")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "triggerNode", xmlFile, xmlNode .. "#triggerNode")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "triggerIndex", xmlFile, xmlNode .. "#triggerNode")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillLitersPerSecond", xmlFile, xmlNode .. "#fillLitersPerSecond")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "dischargeNode", xmlFile, xmlNode .. "#dischargeNode")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillSoundIdentifier", xmlFile, xmlNode .. "#fillSoundIdentifier")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillSoundNode", xmlFile, xmlNode .. "#fillSoundNode")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "scrollerIndex", xmlFile, xmlNode .. "#scrollerNode")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "shaderParameterName", xmlFile, xmlNode .. "#shaderParameterName")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "scrollerScrollSpeed", xmlFile, xmlNode .. "#scrollerScrollSpeed")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillTypeCategories", xmlFile, xmlNode .. "#fillTypeCategories")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillTypes", xmlFile, xmlNode .. "#fillTypes")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "autoStart", xmlFile, xmlNode .. "#autoStart")
	XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "infiniteCapacity", xmlFile, xmlNode .. "#infiniteCapacity")
	local v14_ = xmlFile:getValue(xmlNode .. "#triggerNode", nil, components, i3dMappings)
	if v14_ == nil then
		Logging.xmlError(xmlFile, "Missing triggerNode defined in \'%s\'", xmlNode)
		return false
	end
	self.triggerNode = v14_
	addTrigger(v14_, "loadTriggerCallback", self)
	g_currentMission:addNodeObject(v14_, self)
	self.fillLitersPerMS = xmlFile:getValue(xmlNode .. "#fillLitersPerSecond", 1000) / 1000
	self.useTimeScale = xmlFile:getValue(xmlNode .. "#useTimeScale", false)
	self.aiNode = xmlFile:getValue(xmlNode .. "#aiNode", nil, components, i3dMappings)
	self.supportsAILoading = self.aiNode ~= nil
	local v15_ = xmlFile:getValue(xmlNode .. "#dischargeNode", nil, components, i3dMappings)
	if v15_ ~= nil then
		XMLUtil.checkDeprecatedUserAttribute(v15_, "width", xmlFile, xmlNode .. "#dischargeWidth")
		XMLUtil.checkDeprecatedUserAttribute(v15_, "length", xmlFile, xmlNode .. "#dischargeLength")
		self.dischargeInfo = {}
		self.dischargeInfo.name = "fillVolumeDischargeInfo"
		self.dischargeInfo.nodes = {}
		local v16_ = xmlFile:getValue(xmlNode .. "#dischargeWidth", 0.5)
		local v17_ = xmlFile:getValue(xmlNode .. "#dischargeLength", 0.5)
		local v18_ = self.dischargeInfo.nodes
		table.insert(v18_, {
			["node"] = v15_,
			["width"] = v16_,
			["length"] = v17_,
			["priority"] = 1
		})
	end
	self.soundNode = createTransformGroup("loadTriggerSoundNode")
	link(v15_ or self.triggerNode, self.soundNode)
	if self.isClient then
		self.effects = g_effectManager:loadEffect(xmlFile, xmlNode, components, self, i3dMappings)
		local v19_ = g_currentMission.baseDirectory
		local v20_, v21_ = Utils.getModNameAndBaseDirectory(g_currentMission.missionInfo.mapSoundXmlFilename)
		if v20_ ~= nil then
			v19_ = v21_ .. v20_
		end
		self.samples = {}
		self.samples.loading = g_soundManager:loadSampleFromXML(xmlFile, xmlNode .. ".sounds", "loading", v19_, components, 1, AudioGroup.VEHICLE, i3dMappings, self)
		local v22_ = xmlFile:getValue(xmlNode .. "#fillSoundIdentifier")
		local v23_ = xmlFile:getValue(xmlNode .. "#fillSoundNode", nil, components, i3dMappings)
		if v23_ == nil then
			v23_ = self.rootNode
		end
		local v24_ = loadXMLFile("mapXML", g_currentMission.missionInfo.mapSoundXmlFilename)
		if v24_ ~= nil and v24_ ~= 0 then
			if v22_ ~= nil then
				self.samples.load = g_soundManager:loadSampleFromXML(v24_, "sound.object", v22_, v19_, getRootNode(), 0, AudioGroup.ENVIRONMENT, nil, nil)
				if self.samples.load ~= nil then
					link(v23_, self.samples.load.soundNode)
					setTranslation(self.samples.load.soundNode, 0, 0, 0)
				end
			end
			delete(v24_)
		end
		self.scroller = xmlFile:getValue(xmlNode .. "#scrollerNode", nil, components, i3dMappings)
		if self.scroller ~= nil then
			self.scrollerShaderParameterName = xmlFile:getValue(xmlNode .. "#shaderParameterName", "uvScrollSpeed")
			local v25_, v26_ = xmlFile:getValue(xmlNode .. "#scrollerScrollSpeed", "0 -0.75")
			self.scrollerSpeedX = v25_
			self.scrollerSpeedY = v26_
			setShaderParameter(self.scroller, self.scrollerShaderParameterName, 0, 0, 0, 0, false)
		end
	end
	self.fillTypes = {}
	local v27_ = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypeCategories", self.rootNode)
	local v28_ = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypes", self.rootNode)
	local v29_ = nil
	if v27_ == nil or v28_ ~= nil then
		if v27_ == nil and v28_ ~= nil then
			v29_ = g_fillTypeManager:getFillTypesByNames(v28_, "Warning: UnloadTrigger has invalid fillType \'%s\'.")
		end
	else
		v29_ = g_fillTypeManager:getFillTypesByCategoryNames(v27_, "Warning: UnloadTrigger has invalid fillTypeCategory \'%s\'.")
	end
	if v29_ == nil then
		self.fillTypes = nil
	else
		for _, v30_ in pairs(v29_) do
			self.fillTypes[v30_] = true
		end
	end
	self.autoStart = xmlFile:getValue(xmlNode .. "#autoStart", false)
	self.hasInfiniteCapacity = xmlFile:getValue(xmlNode .. "#infiniteCapacity", false)
	self.requiresExactFillRootNode = xmlFile:getValue(xmlNode .. "#requiresExactFillRootNode", true)
	self.startFillText = g_i18n:convertText(xmlFile:getValue(xmlNode .. "#startFillText", "$l10n_action_siloStartFilling"))
	self.stopFillText = g_i18n:convertText(xmlFile:getValue(xmlNode .. "#stopFillText", "$l10n_action_siloStopFilling"))
	self.activatable = LoadTriggerActivatable.new(self)
	self.activatable:setText(self.startFillText)
	self.isLoading = false
	self.selectedFillType = FillType.UNKNOWN
	self.automaticFilling = Platform.gameplay.automaticFilling
	self.requiresActiveVehicle = not self.automaticFilling
	self.automaticFillingTimer = 0
	return true
end

-- Local values: objectId, data
function LoadTrigger:delete()
	if self.fillableObjects ~= nil then
		for _, v32_ in pairs(self.fillableObjects) do
			if v32_.object.removeDeleteListener ~= nil then
				v32_.object:removeDeleteListener(self)
			end
		end
		table.clear(self.fillableObjects)
	end
	if self.triggerNode ~= nil then
		removeTrigger(self.triggerNode)
		g_currentMission:removeNodeObject(self.triggerNode)
		self.triggerNode = nil
	end
	if self.samples ~= nil then
		g_soundManager:deleteSamples(self.samples)
		table.clear(self.samples)
	end
	if self.effects ~= nil then
		g_effectManager:deleteEffects(self.effects)
		table.clear(self.effects)
	end
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	LoadTrigger:superClass().delete(self)
end

function LoadTrigger:setSource(object)
	local v35_ = object.getSupportedFillTypes ~= nil
	assert(v35_)
	local v36_ = object.getAllFillLevels ~= nil
	assert(v36_)
	local v37_ = object.addFillLevelToFillableObject ~= nil
	assert(v37_)
	local v38_ = object.getIsFillAllowedToFarm ~= nil
	assert(v38_)
	self.source = object
end

function LoadTrigger:raiseActive()
	LoadTrigger:superClass().raiseActive(self)
	if self.source ~= nil and self.source.raiseActive ~= nil then
		self.source:raiseActive()
	end
end

-- Local values: fillableObject, fillTypes, foundFillUnitIndex, found, fillTypeIndex, state, fillTypeIndex, state, fillUnits, fillUnitIndex, fillUnit
function LoadTrigger:loadTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local v44_ = g_currentMission:getNodeObject(otherId)
	if v44_ == nil then
		return
	end
	if not entityExists(otherId) then
		return
	end
	if self.requiresExactFillRootNode and not CollisionFlag.getHasGroupFlagSet(otherId, CollisionFlag.FILLABLE) then
		return
	end
	if v44_ == self.source then
		return
	end
	if v44_.getRootVehicle ~= nil and v44_.getFillUnitIndexFromNode ~= nil then
		local v45_ = self.source:getSupportedFillTypes()
		if v45_ ~= nil then
			local v46_ = v44_:getFillUnitIndexFromNode(otherId)
			if v46_ ~= nil then
				local v47_ = false
				for v48_, v49_ in pairs(v45_) do
					if v49_ and (self.fillTypes == nil or self.fillTypes[v48_]) and (v44_:getFillUnitSupportsFillType(v46_, v48_) and v44_:getFillUnitAllowsFillType(v46_, v48_)) then
						v47_ = true
						break
					end
				end
				if not v47_ then
					v46_ = nil
				end
			end
			if v46_ == nil then
				for v50_, v51_ in pairs(v45_) do
					if v51_ and (self.fillTypes == nil or self.fillTypes[v50_]) then
						local v52_ = v44_:getFillUnits()
						for v53_, v54_ in ipairs(v52_) do
							if v54_.exactFillRootNode == nil and (v44_:getFillUnitSupportsFillType(v53_, v50_) and v44_:getFillUnitAllowsFillType(v53_, v50_)) then
								v46_ = v53_
								break
							end
						end
					end
				end
			end
			if v46_ ~= nil then
				if onEnter then
					self.fillableObjects[otherId] = {
						["object"] = v44_,
						["fillUnitIndex"] = v46_
					}
					v44_:addDeleteListener(self)
					v44_:setFillUnitInTriggerRange(v46_, true)
					self:raiseActive()
				elseif onLeave then
					self.fillableObjects[otherId] = nil
					v44_:removeDeleteListener(self)
					v44_:setFillUnitInTriggerRange(v46_, false)
					if self.isLoading and self.currentFillableObject == v44_ then
						self:setIsLoading(false)
					end
					if v44_ == self.validFillableObject then
						self.validFillableObject = nil
						self.validFillableFillUnitIndex = nil
					end
				end
				if self.automaticFilling then
					if not self.isLoading and (next(self.fillableObjects) ~= nil and self:getIsFillableObjectAvailable()) then
						self:toggleLoading()
						return
					end
				else
					if next(self.fillableObjects) ~= nil then
						g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
						return
					end
					g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
				end
			end
		end
	end
end

-- Local values: objectFarmId
function LoadTrigger:farmIdForFillableObject(fillableObject)
	local v56_ = fillableObject:getOwnerFarmId()
	if fillableObject.getActiveFarm ~= nil then
		v56_ = fillableObject:getActiveFarm()
	end
	if v56_ == nil then
		v56_ = FarmManager.SPECTATOR_FARM_ID
	end
	return v56_
end

-- Local values: hasLowPrioObject, numOfObjects, _, fillableObject, _, fillableObject
function LoadTrigger:getIsFillableObjectAvailable()
	if next(self.fillableObjects) == nil then
		return false
	end
	if self.isLoading then
		if self.currentFillableObject ~= nil and self:getAllowsActivation(self.currentFillableObject) then
			return true
		end
	else
		self.validFillableObject = nil
		self.validFillableFillUnitIndex = nil
		local v58_ = 0
		local v59_ = false
		for _, v60_ in pairs(self.fillableObjects) do
			v59_ = v60_.lastWasFilled and true or v59_
			v58_ = v58_ + 1
		end
		if v59_ then
			v59_ = v58_ > 1
		end
		for _, v61_ in pairs(self.fillableObjects) do
			if not (v61_.lastWasFilled and v59_) and (self:getAllowsActivation(v61_.object) and (v61_.object:getFillUnitSupportsToolType(v61_.fillUnitIndex, ToolType.TRIGGER) and (v61_.object:getFillUnitFreeCapacity(v61_.fillUnitIndex, nil, nil) > 0 and self.source:getIsFillAllowedToFarm(self:farmIdForFillableObject(v61_.object))))) then
				self.validFillableObject = v61_.object
				self.validFillableFillUnitIndex = v61_.fillUnitIndex
				return true
			end
		end
	end
	return false
end

-- Local values: fillLevels, fillableObject, fillUnitIndex, firstFillType, validFillLevels, numFillTypes, fillTypeIndex, fillLevel, startAllowed, controlledVehicle, title, rootVehicle
function LoadTrigger:toggleLoading()
	if self.isLoading then
		self:setIsLoading(false)
	else
		local v63_ = self.source:getAllFillLevels(g_currentMission:getFarmId())
		local v64_ = self.validFillableObject
		local v65_ = self.validFillableFillUnitIndex
		local v66_ = {}
		local v67_ = nil
		local v68_ = 0
		for v71_, v70_ in pairs(v63_) do
			if (self.fillTypes == nil or self.fillTypes[v71_]) and v64_:getFillUnitAllowsFillType(v65_, v71_) then
				v66_[v71_] = v70_
				if v67_ ~= nil then
					local v71_ = v67_
				end
				v68_ = v68_ + 1
				v67_ = v71_
			end
		end
		if self.autoStart or v68_ <= 0 then
			self:onFillTypeSelection(v67_)
			return
		end
		local v72_ = g_localPlayer:getCurrentVehicle()
		if v72_.getIsActiveForInput == nil and true or v72_:getIsActiveForInput(true) then
			local v73_ = string.format("%s", self.source:getName())
			SiloDialog.show(self.onFillTypeSelection, self, v73_, v66_, self.hasInfiniteCapacity)
			if self.automaticFilling then
				local v74_ = v64_.rootVehicle
				if v74_.brakeToStop ~= nil then
					v74_:brakeToStop()
					return
				end
			end
		end
	end
end

-- Local values: validFillableObject, fillUnitIndex
function LoadTrigger:onFillTypeSelection(fillType)
	if fillType ~= nil and fillType ~= FillType.UNKNOWN then
		local v77_ = self.validFillableObject
		if v77_ ~= nil and self:getAllowsActivation(v77_) then
			self:setIsLoading(true, v77_, self.validFillableFillUnitIndex, fillType)
		end
	end
end

function LoadTrigger:setIsLoading(isLoading, targetObject, fillUnitIndex, fillType, noEventSend)
	LoadTriggerSetIsLoadingEvent.sendEvent(self, isLoading, targetObject, fillUnitIndex, fillType, noEventSend)
	if isLoading then
		self:startLoading(fillType, targetObject, fillUnitIndex)
		self:setFillSoundIsPlaying(true)
	else
		self:setFillSoundIsPlaying(false)
		self:stopLoading()
	end
end

function LoadTrigger:getAllowsActivation(fillableObject)
	return not self.requiresActiveVehicle and true or (fillableObject.getAllowLoadTriggerActivation ~= nil and fillableObject:getAllowLoadTriggerActivation(fillableObject) and true or false)
end

function LoadTrigger:startLoading(fillType, fillableObject, fillUnitIndex)
	if not self.isLoading then
		self:raiseActive()
		self.isLoading = true
		self.selectedFillType = fillType
		self.currentFillableObject = fillableObject
		self.fillUnitIndex = fillUnitIndex
		self.activatable:setText(self.stopFillText)
		if self.isClient then
			g_effectManager:setEffectTypeInfo(self.effects, self.selectedFillType)
			g_effectManager:startEffects(self.effects)
			g_soundManager:playSample(self.samples.load)
			g_soundManager:playSample(self.samples.loading)
			if self.scroller ~= nil then
				setShaderParameter(self.scroller, self.scrollerShaderParameterName, self.scrollerSpeedX, self.scrollerSpeedY, 0, 0, false)
			end
		end
	end
end

-- Local values: _, fillableObject
function LoadTrigger:stopLoading()
	if self.isLoading then
		self:raiseActive()
		self.isLoading = false
		self.selectedFillType = FillType.UNKNOWN
		self.activatable:setText(self.startFillText)
		if self.currentFillableObject.aiStoppedLoadingFromTrigger ~= nil then
			self.currentFillableObject:aiStoppedLoadingFromTrigger()
		end
		self.currentFillableObject = nil
		for _, v91_ in pairs(self.fillableObjects) do
			local v92_
			if v91_.object == self.validFillableObject then
				v92_ = v91_.fillUnitIndex == self.fillUnitIndex
			else
				v92_ = false
			end
			v91_.lastWasFilled = v92_
		end
		if self.isClient then
			g_effectManager:stopEffects(self.effects)
			g_soundManager:stopSample(self.samples.load)
			g_soundManager:stopSample(self.samples.loading)
			if self.scroller ~= nil then
				setShaderParameter(self.scroller, self.scrollerShaderParameterName, 0, 0, 0, 0, false)
			end
		end
	end
end

-- Local values: fillSpeed, delta, fillDelta
function LoadTrigger:update(dt)
	if self.isServer then
		if self.isLoading then
			if self.currentFillableObject == nil then
				if self.isLoading then
					self:setIsLoading(false)
				end
			else
				local v95_ = self.fillLitersPerMS
				if self.currentFillableObject.getLoadTriggerMaxFillSpeed ~= nil then
					local v96_ = self.currentFillableObject
					v95_ = math.min(v95_, v96_:getLoadTriggerMaxFillSpeed())
				end
				local v97_ = v95_ * dt
				if self.useTimeScale then
					v97_ = v97_ * g_currentMission:getEffectiveTimeScale()
				end
				local v98_ = self.source:addFillLevelToFillableObject(self.currentFillableObject, self.fillUnitIndex, self.selectedFillType, v97_, self.dischargeInfo, ToolType.TRIGGER)
				if v98_ == nil or math.abs(v98_) < 0.0001 then
					self:setIsLoading(false)
				end
			end
			self:raiseActive()
			return
		end
		if self.automaticFilling and next(self.fillableObjects) ~= nil then
			local v99_ = self.automaticFillingTimer - dt
			self.automaticFillingTimer = math.max(v99_, 0)
			if self.automaticFillingTimer == 0 and self:getIsFillableObjectAvailable() then
				self:toggleLoading()
				self.automaticFillingTimer = 10000
			end
			self:raiseActive()
		end
	end
end

function LoadTrigger:getCurrentFillType()
	return self.selectedFillType
end

function LoadTrigger:getFillTargetNode()
	if self.currentFillableObject == nil then
		return nil
	else
		return self.currentFillableObject:getFillUnitRootNode(self.fillUnitIndex)
	end
end

-- Local values: target, x, y, z
function LoadTrigger:setFillSoundIsPlaying(state)
	if self.dischargeInfo == nil and state then
		local v104_ = self:getFillTargetNode()
		if v104_ ~= nil then
			local v105_, v106_, v107_ = getWorldTranslation(v104_)
			setWorldTranslation(self.soundNode, v105_, v106_, v107_)
		end
	end
	if self.samples.load == nil then
		FillTrigger.setFillSoundIsPlaying(self, state)
	end
	if self.currentFillableObject ~= nil and self.currentFillableObject.setFillSoundIsPlaying ~= nil then
		self.currentFillableObject:setFillSoundIsPlaying(state)
	end
end

-- Local values: k, fillableObject
function LoadTrigger:onDeleteObject(vehicle)
	for v110_, v111_ in pairs(self.fillableObjects) do
		if v111_.object == vehicle then
			self.fillableObjects[v110_] = nil
			if self.isLoading and self.currentFillableObject == vehicle then
				self:stopLoading()
			end
		end
	end
end

function LoadTrigger:getIsFillTypeSupported(fillType)
	return self.fillTypes[fillType] ~= nil
end

function LoadTrigger:getSupportAILoading()
	return self.supportsAILoading
end

-- Local values: x, _, z, xDir, _, zDir
function LoadTrigger:getAITargetPositionAndDirection()
	local v116_, _, v117_ = getWorldTranslation(self.aiNode)
	local v118_, _, v119_ = localDirectionToWorld(self.aiNode, 0, 0, 1)
	return v116_, v117_, v118_, v119_
end
LoadTriggerActivatable = {}
local v_u_120_ = Class(LoadTriggerActivatable)
function LoadTriggerActivatable.new(p121_)
	-- upvalues: (copy) v_u_120_
	local v122_ = v_u_120_
	local v123_ = setmetatable({}, v122_)
	v123_.loadTrigger = p121_
	v123_.activateText = ""
	return v123_
end

function LoadTriggerActivatable:setText(text)
	self.activateText = text
end

function LoadTriggerActivatable:getIsActivatable()
	return self.loadTrigger:getIsFillableObjectAvailable()
end

function LoadTriggerActivatable:run()
	self.loadTrigger:toggleLoading()
end
