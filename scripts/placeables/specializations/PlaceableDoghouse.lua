source("dataS/scripts/placeables/specializations/events/PlaceableDoghouseFoodBowlStateEvent.lua")
source("dataS/scripts/placeables/specializations/activatables/DoghouseActivatable.lua")
PlaceableDoghouse = {}

function PlaceableDoghouse.prerequisitesPresent(specializations)
	return true
end
function PlaceableDoghouse.initSpecialization()
	g_placeableConfigurationManager:addConfigurationType("dogHouse", g_i18n:getText("configuration_doghouse"), "dogHouse", PlaceableConfigurationItem)
end

function PlaceableDoghouse.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "dogInteractionTriggerCallback", PlaceableDoghouse.dogInteractionTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "isDoghouseRegistered", PlaceableDoghouse.isDoghouseRegistered)
	SpecializationUtil.registerFunction(placeableType, "registerDoghouseToMission", PlaceableDoghouse.registerDoghouseToMission)
	SpecializationUtil.registerFunction(placeableType, "unregisterDoghouseToMission", PlaceableDoghouse.unregisterDoghouseToMission)
	SpecializationUtil.registerFunction(placeableType, "setFoodBowlState", PlaceableDoghouse.setFoodBowlState)
	SpecializationUtil.registerFunction(placeableType, "getDog", PlaceableDoghouse.getDog)
	SpecializationUtil.registerFunction(placeableType, "getSpawnNode", PlaceableDoghouse.getSpawnNode)
	SpecializationUtil.registerFunction(placeableType, "onPreviewDogLoaded", PlaceableDoghouse.onPreviewDogLoaded)
end

function PlaceableDoghouse.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableDoghouse.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableDoghouse.canBuy)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableDoghouse.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableDoghouse.getNeedHourChanged)
end

function PlaceableDoghouse.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDoghouse)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDoghouse)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDoghouse)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableDoghouse)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableDoghouse)
	SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableDoghouse)
end

-- Local values: addDogSchema
function PlaceableDoghouse.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Doghouse")
	local function v7_(p6_)
		-- upvalues: (copy) schema
		schema:register(XMLValueType.NODE_INDEX, p6_ .. ".dog#node", "Dog link node")
		schema:register(XMLValueType.NODE_INDEX, p6_ .. ".dog#previewNode", "Dog preview link node")
		schema:register(XMLValueType.INT, p6_ .. ".dog#tileUIndex", "Dog tile index U")
		schema:register(XMLValueType.INT, p6_ .. ".dog#tileVIndex", "Dog tile index V")
		schema:register(XMLValueType.STRING, p6_ .. ".dog#xmlFilename", "Dog xml filename")
		schema:register(XMLValueType.NODE_INDEX, p6_ .. ".nameplate#node", "Name plate node")
		schema:register(XMLValueType.NODE_INDEX, p6_ .. ".ball#node", "Ball node")
		schema:register(XMLValueType.STRING, p6_ .. ".ball#filename", "Ball 3d file")
		schema:register(XMLValueType.NODE_INDEX, p6_ .. ".playerInteractionTrigger#node", "Interaction trigger node")
		schema:register(XMLValueType.NODE_INDEX, p6_ .. ".bowl#foodNode", "Food node in bowl")
		SoundManager.registerSampleXMLPaths(schema, p6_ .. ".bowl", "fillSound")
	end
	v7_(basePath .. ".dogHouse")
	v7_(basePath .. ".dogHouse.dogHouseConfigurations.dogHouseConfiguration(?)")
	schema:setXMLSpecializationType()
end

function PlaceableDoghouse.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Doghouse")
	Dog.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, isValid, dogHouseConfigurationId, configKey, isConstructionPreview, tileUIndex, tileVIndex, posX, posY, posZ, xmlFilename, dog, dogBallFilename, x, y, z, rx, ry, rz, xmlFilename, dogXML, dogI3DFilename, numTilesU, numTilesV, loadingTask, arguments
function PlaceableDoghouse:onLoad(savegame)
	local v11_ = self.spec_doghouse
	local v12_ = self.xmlFile
	local v13_ = Utils.getNoNil(self.configurations.dogHouse, 1)
	local v14_ = string.format("placeable.dogHouse.dogHouseConfigurations.dogHouseConfiguration(%d)", v13_ - 1)
	local v15_ = not v12_:hasProperty(v14_) and "placeable.dogHouse" or v14_
	v11_.spawnNode = v12_:getValue(v15_ .. ".dog#node", nil, self.components, self.i3dMappings)
	local v16_
	if v11_.spawnNode == nil then
		Logging.xmlError(v12_, "Could not load dog spawn node!")
		v16_ = false
	else
		v16_ = true
	end
	local v17_ = self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW
	local v18_ = v12_:getInt(v15_ .. ".dog#tileUIndex", 0)
	local v19_ = v12_:getInt(v15_ .. ".dog#tileVIndex", 0)
	if self.isServer and (v16_ and not v17_) then
		local v20_, v21_, v22_ = getWorldTranslation(v11_.spawnNode)
		local v23_ = Utils.getFilename(v12_:getValue(v15_ .. ".dog#xmlFilename"), self.baseDirectory)
		local v24_ = Dog.new(self.isServer, self.isClient)
		v24_:setOwnerFarmId(self:getOwnerFarmId(), true)
		if v24_:load(self, v23_, v20_, v21_, v22_) then
			v24_:setTextureTileIndices(v18_, v19_)
			v24_:register()
			v11_.dog = v24_
		else
			Logging.xmlWarning(v12_, "Could not load dog!")
			v16_ = false
		end
	end
	if v16_ then
		v11_.namePlateNode = v12_:getValue(v15_ .. ".nameplate#node", nil, self.components, self.i3dMappings)
		v11_.ballSpawnNode = v12_:getValue(v15_ .. ".ball#node", nil, self.components, self.i3dMappings)
		if self.isServer and not v17_ then
			local v25_ = Utils.getFilename(v12_:getValue(v15_ .. ".ball#filename"), self.baseDirectory)
			local v26_, v27_, v28_ = getWorldTranslation(v11_.ballSpawnNode)
			local v29_, v30_, v31_ = getWorldRotation(v11_.ballSpawnNode)
			v11_.dogBall = DogBall.new(self.isServer, self.isClient)
			v11_.dogBall:setOwnerFarmId(self:getOwnerFarmId(), true)
			v11_.dogBall:load(v25_, v26_, v27_, v28_, v29_, v30_, v31_, self)
			v11_.dogBall:register()
		end
		if v17_ then
			v11_.dogPreviewLinkNode = v12_:getValue(v15_ .. ".dog#previewNode", nil, self.components, self.i3dMappings)
			local v32_ = Utils.getFilename(v12_:getValue(v15_ .. ".dog#xmlFilename"), self.baseDirectory)
			local v33_ = XMLFile.load("dog", v32_)
			local v34_ = Utils.getFilename(v33_:getString("dog.asset#filename"), self.baseDirectory)
			local v35_ = v33_:getInt("dog.asset.texture#numTilesU", 1)
			local v36_ = v33_:getInt("dog.asset.texture#numTilesV", 1)
			v33_:delete()
			local v37_ = {
				["loadingTask"] = self:createLoadingTask(v11_),
				["tileUIndex"] = v18_,
				["tileVIndex"] = v19_,
				["numTilesU"] = v35_,
				["numTilesV"] = v36_
			}
			v11_.dogPreviewSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v34_, true, false, self.onPreviewDogLoaded, self, v37_)
		end
		v11_.triggerNode = v12_:getValue(v15_ .. ".playerInteractionTrigger#node", nil, self.components, self.i3dMappings)
		if v11_.triggerNode ~= nil then
			addTrigger(v11_.triggerNode, "dogInteractionTriggerCallback", self)
		end
		v11_.foodNode = v12_:getValue(v15_ .. ".bowl#foodNode", nil, self.components, self.i3dMappings)
		if v11_.foodNode == nil then
			Logging.xmlWarning(v12_, "Missing bowl food node in \'placeable.dogHouse.bowl#foodNode\'!")
		else
			setVisibility(v11_.foodNode, false)
			if g_client ~= nil then
				v11_.foodFillSample = g_soundManager:loadSampleFromXML(v12_, v15_ .. ".bowl", "fillSound", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings)
			end
		end
		v11_.activatable = DoghouseActivatable.new(self)
	else
		SpecializationUtil.removeEventListener(self, "onDelete", PlaceableDoghouse)
		SpecializationUtil.removeEventListener(self, "onFinalizePlacement", PlaceableDoghouse)
		SpecializationUtil.removeEventListener(self, "onWriteStream", PlaceableDoghouse)
		SpecializationUtil.removeEventListener(self, "onReadStream", PlaceableDoghouse)
		SpecializationUtil.removeEventListener(self, "onHourChanged", PlaceableDoghouse)
	end
end

-- Local values: spec
function PlaceableDoghouse:onDelete()
	local v39_ = self.spec_doghouse
	g_currentMission.activatableObjectsSystem:removeActivatable(v39_.activatable)
	self:unregisterDoghouseToMission()
	if self.isServer then
		if v39_.dogBall ~= nil and not v39_.dogBall.isDeleted then
			v39_.dogBall:delete()
			v39_.dogBall = nil
		end
		if v39_.dog ~= nil and not v39_.dog.isDeleted then
			v39_.dog:delete()
			v39_.dog = nil
		end
	end
	if v39_.triggerNode ~= nil then
		removeTrigger(v39_.triggerNode)
	end
	if v39_.foodFillSample ~= nil then
		g_soundManager:deleteSample(v39_.foodFillSample)
		v39_.foodFillSample = nil
	end
	if v39_.dogPreviewSharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v39_.dogPreviewSharedLoadRequestId)
	end
end

-- Local values: spec
function PlaceableDoghouse:onFinalizePlacement()
	local v41_ = self.spec_doghouse
	if self.isServer and v41_.dog ~= nil then
		v41_.dog:finalizePlacement()
	end
	self:registerDoghouseToMission()
end

-- Local values: spec
function PlaceableDoghouse:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v45_ = self.spec_doghouse
		v45_.dog = NetworkUtil.readNodeObject(streamId)
		if v45_.dog ~= nil then
			v45_.dog.spawner = self
		end
		if v45_.foodNode ~= nil then
			setVisibility(v45_.foodNode, streamReadBool(streamId))
		end
	end
end

-- Local values: spec
function PlaceableDoghouse:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v49_ = self.spec_doghouse
		NetworkUtil.writeNodeObject(streamId, v49_.dog)
		if v49_.foodNode ~= nil then
			streamWriteBool(streamId, getVisibility(v49_.foodNode))
		end
	end
end

-- Local values: spec
function PlaceableDoghouse:loadFromXMLFile(xmlFile, key)
	local v53_ = self.spec_doghouse
	if v53_.dog ~= nil then
		v53_.dog:loadFromXMLFile(xmlFile, key)
	end
end

-- Local values: spec
function PlaceableDoghouse:saveToXMLFile(xmlFile, key, usedModNames)
	local v58_ = self.spec_doghouse
	if v58_.dog ~= nil then
		v58_.dog:saveToXMLFile(xmlFile, key, usedModNames)
	end
end

-- Local values: spec, loadingTask, tileU, tileV
function PlaceableDoghouse:onPreviewDogLoaded(node, failedReason, args)
	local v62_ = self.spec_doghouse
	local v63_ = args.loadingTask
	if node == 0 or node == nil then
		self:finishLoadingTask(v63_)
	else
		link(v62_.dogPreviewLinkNode or self.rootNode, node)
		local v64_ = args.tileUIndex / args.numTilesU
		local v65_ = args.tileVIndex / args.numTilesV
		setShaderParameterRecursive(node, "atlasInvSizeAndOffsetUV", 1 / args.numTilesU, 1 / args.numTilesV, v64_, v65_, false)
		self:finishLoadingTask(v63_)
	end
end

-- Local values: spec
function PlaceableDoghouse:dogInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v70_ = self.spec_doghouse
	if v70_.dog ~= nil and (g_localPlayer ~= nil and (otherId == g_localPlayer.rootNode and g_localPlayer.farmId == self:getOwnerFarmId())) then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(v70_.activatable)
			return
		end
		if onLeave then
			g_currentMission.activatableObjectsSystem:removeActivatable(v70_.activatable)
		end
	end
end

-- Local values: dogHouse
function PlaceableDoghouse:isDoghouseRegistered()
	return g_currentMission:getDoghouse(self:getOwnerFarmId()) ~= nil
end

function PlaceableDoghouse:registerDoghouseToMission()
	if self:isDoghouseRegistered() then
		return false
	end
	g_currentMission.doghouses[self] = self
	return true
end

function PlaceableDoghouse:unregisterDoghouseToMission()
	g_currentMission.doghouses[self] = nil
	return true
end

-- Local values: spec
function PlaceableDoghouse:setOwnerFarmId(superFunc, farmId, noEventSend)
	superFunc(self, farmId, noEventSend)
	if self.isServer then
		local v78_ = self.spec_doghouse
		if v78_.dog ~= nil then
			v78_.dog:setOwnerFarmId(farmId, noEventSend)
		end
		if v78_.dogBall ~= nil then
			v78_.dogBall:setOwnerFarmId(farmId, noEventSend)
		end
	end
end

-- Local values: spec
function PlaceableDoghouse:setFoodBowlState(isFilled, noEventSend)
	local v82_ = self.spec_doghouse
	if v82_.foodNode ~= nil then
		PlaceableDoghouseFoodBowlStateEvent.sendEvent(self, isFilled, noEventSend)
		setVisibility(v82_.foodNode, isFilled)
		if isFilled and v82_.dog ~= nil then
			v82_.dog:onFoodBowlFilled(v82_.foodNode)
			if v82_.foodFillSample ~= nil then
				g_soundManager:playSample(v82_.foodFillSample)
			end
		end
	end
end

function PlaceableDoghouse:getDog()
	return self.spec_doghouse.dog
end

function PlaceableDoghouse:getSpawnNode()
	return self.spec_doghouse.spawnNode
end

function PlaceableDoghouse:getCanBePlacedAt(superFunc, x, y, z, farmId)
	if self:isDoghouseRegistered() then
		return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
	else
		return superFunc(self, x, y, z, farmId)
	end
end

-- Local values: canBuy, warning
function PlaceableDoghouse:canBuy(superFunc)
	local v93_, v94_ = superFunc(self)
	if v93_ then
		if self:isDoghouseRegistered() then
			return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
		else
			return true, nil
		end
	else
		return false, v94_
	end
end

function PlaceableDoghouse:getNeedHourChanged(superFunc)
	return true
end

function PlaceableDoghouse:onHourChanged()
	self:setFoodBowlState(false, true)
end
