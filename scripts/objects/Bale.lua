-- Local values: Bale_mt, BaleActivatable_mt
Bale = {}
Bale.INTERACTION_RADIUS = 3
Bale.NUM_BITS_VARIATION = 4
Bale.MAX_NUM_VARIATIONS = 2 ^ Bale.NUM_BITS_VARIATION
source("dataS/scripts/events/BaleOpenEvent.lua")
local Bale_mt = Class(Bale, MountableObject)
InitStaticObjectClass(Bale, "Bale")
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = ItemSystem.xmlSchemaSavegame
	Bale.registerSavegameXMLPaths(v2_, "items.item(?)")
end)

function Bale.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id")
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Path to bale xml file")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Bale position")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Bale rotation")
	schema:register(XMLValueType.FLOAT, basePath .. "#fillLevel", "Current bale fill level")
	schema:register(XMLValueType.STRING, basePath .. "#fillType", "Current bale fill type")
	schema:register(XMLValueType.INT, basePath .. "#variationIndex", "Current variation index")
	schema:register(XMLValueType.INT, basePath .. "#farmId", "Id of owner farm")
	schema:register(XMLValueType.STRING, basePath .. ".textures#wrapDiffuse", "Current wrap diffuse file")
	schema:register(XMLValueType.STRING, basePath .. ".textures#wrapNormal", "Current wrap normal file")
	schema:register(XMLValueType.BOOL, basePath .. ".fermentation#isFermenting", "Bale is fermenting")
	schema:register(XMLValueType.FLOAT, basePath .. ".fermentation#time", "Current fermentation time")
	schema:register(XMLValueType.FLOAT, basePath .. "#wrappingState", "Current wrapping state")
	schema:register(XMLValueType.VECTOR_3, basePath .. "#wrappingColor", "Wrapping color")
	schema:register(XMLValueType.FLOAT, basePath .. "#valueScale", "Bale value scale")
	schema:register(XMLValueType.BOOL, basePath .. "#isMissionBale", "Bale was produced in mission context", false)
end

-- Upvalues: Bale_mt
-- Local values: self
function Bale.new(isServer, isClient, customMt)
	-- upvalues: (copy) Bale_mt
	local v8_ = MountableObject.new(isServer, isClient, customMt or Bale_mt)
	v8_.forcedClipDistance = 300
	registerObjectClassName(v8_, "Bale")
	v8_.fillType = FillType.STRAW
	v8_.fillLevel = 0
	v8_.needsSaving = true
	v8_.variationIndex = 1
	v8_.supportsWrapping = false
	v8_.wrappingState = 0
	v8_.wrappingColor = { 1, 1, 1 }
	v8_.defaultMass = 0.25
	v8_.isFermenting = false
	v8_.fermentingPercentage = 0
	v8_.canBeSold = true
	v8_.allowPickup = true
	v8_.isMissionBale = false
	v8_.activatable = BaleActivatable.new(v8_)
	v8_.fillTypeDirtyFlag = v8_:getNextDirtyFlag()
	v8_.fillLevelDirtyFlag = v8_:getNextDirtyFlag()
	v8_.variationDirtyFlag = v8_:getNextDirtyFlag()
	v8_.texturesDirtyFlag = v8_:getNextDirtyFlag()
	v8_.wrapStateDirtyFlag = v8_:getNextDirtyFlag()
	v8_.wrapColorDirtyFlag = v8_:getNextDirtyFlag()
	v8_.fermentingDirtyFlag = v8_:getNextDirtyFlag()
	v8_.obstacleNodeId = nil
	v8_.sharedLoadRequestId = nil
	v8_.uniqueId = nil
	g_currentMission.slotSystem:addLimitedObject(SlotSystem.LIMITED_OBJECT_BALE, v8_)
	return v8_
end

function Bale:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	self.meshes = {}
	self.tensionBeltMeshes = {}
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	if self.isFermenting then
		g_baleManager:removeFermentation(self)
	end
	self:setBaleAIObstacle(false)
	g_currentMission.slotSystem:removeLimitedObject(SlotSystem.LIMITED_OBJECT_BALE, self)
	unregisterObjectClassName(self)
	g_currentMission.itemSystem:removeItem(self)
	Bale:superClass().delete(self)
end

-- Local values: fillType, wrapDiffuse, wrapNormal, r, g, b
function Bale:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			self:setFillType((streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
		end
		if streamReadBool(streamId) then
			self:setFillLevel(streamReadFloat32(streamId))
		end
		if streamReadBool(streamId) then
			self:setVariationIndex(streamReadUIntN(streamId, Bale.NUM_BITS_VARIATION) + 1)
		end
		if streamReadBool(streamId) then
			if streamReadBool(streamId) then
				self:setWrapTextures(NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)), nil)
			end
			if streamReadBool(streamId) then
				self:setWrapTextures(nil, (NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))))
			end
		end
		if streamReadBool(streamId) then
			self:setWrappingState(streamReadUInt8(streamId) / 255, false)
		end
		if streamReadBool(streamId) then
			local v14_, v15_, v16_ = Color.readStreamRGB(streamId)
			self:setColor(v14_, v15_, v16_)
		end
		if streamReadBool(streamId) then
			self.isFermenting = streamReadBool(streamId)
			self.fermentingPercentage = streamReadUInt8(streamId) / 255
		end
	end
	Bale:superClass().readUpdateStream(self, streamId, timestamp, connection)
end

function Bale:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v21_ = streamWriteBool
		local v22_ = self.fillTypeDirtyFlag
		if v21_(streamId, bit32.band(dirtyMask, v22_) ~= 0) then
			streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
		end
		local v23_ = streamWriteBool
		local v24_ = self.fillLevelDirtyFlag
		if v23_(streamId, bit32.band(dirtyMask, v24_) ~= 0) then
			streamWriteFloat32(streamId, self.fillLevel)
		end
		local v25_ = streamWriteBool
		local v26_ = self.variationDirtyFlag
		if v25_(streamId, bit32.band(dirtyMask, v26_) ~= 0) then
			streamWriteUIntN(streamId, self.variationIndex - 1, Bale.NUM_BITS_VARIATION)
		end
		local v27_ = streamWriteBool
		local v28_ = self.texturesDirtyFlag
		if v27_(streamId, bit32.band(dirtyMask, v28_) ~= 0) then
			if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
				streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
			end
			if streamWriteBool(streamId, self.wrapNormal ~= nil) then
				streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
			end
		end
		local v29_ = streamWriteBool
		local v30_ = self.wrapStateDirtyFlag
		if v29_(streamId, bit32.band(dirtyMask, v30_) ~= 0) then
			local v31_ = streamWriteUInt8
			local v32_ = self.wrappingState * 255
			v31_(streamId, (math.clamp(v32_, 0, 255)))
		end
		local v33_ = streamWriteBool
		local v34_ = self.wrapColorDirtyFlag
		if v33_(streamId, bit32.band(dirtyMask, v34_) ~= 0) then
			Color.writeStreamRGB(streamId, self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])
		end
		local v35_ = streamWriteBool
		local v36_ = self.fermentingDirtyFlag
		if v35_(streamId, bit32.band(dirtyMask, v36_) ~= 0) then
			streamWriteBool(streamId, self.isFermenting)
			local v37_ = streamWriteUInt8
			local v38_ = self.fermentingPercentage * 255
			v37_(streamId, (math.clamp(v38_, 0, 255)))
		end
	end
	Bale:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end

-- Local values: baleTypeIndex, xmlFilename, fillLevel, fillType, variationIndex, wrapDiffuse, wrapNormal, r, g, b
function Bale:readStream(streamId, connection)
	local v42_ = streamReadUIntN(streamId, BaleManager.SEND_NUM_BITS)
	local v43_ = g_baleManager:getBaleXMLFilenameByIndex(v42_)
	if self.nodeId == 0 then
		self:loadFromConfigXML(v43_)
	end
	self:setFillLevel((streamReadFloat32(streamId)))
	self:setFillType((streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)))
	self:setVariationIndex(streamReadUIntN(streamId, Bale.NUM_BITS_VARIATION) + 1)
	if streamReadBool(streamId) then
		self:setWrapTextures(NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)), nil)
	end
	if streamReadBool(streamId) then
		self:setWrapTextures(nil, (NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))))
	end
	Bale:superClass().readStream(self, streamId, connection)
	g_currentMission.itemSystem:addItem(self)
	self:setWrappingState(streamReadUInt8(streamId) / 255, false)
	local v44_, v45_, v46_ = Color.readStreamRGB(streamId)
	self:setColor(v44_, v45_, v46_)
	self.isFermenting = streamReadBool(streamId)
	if self.isFermenting then
		self.fermentingPercentage = streamReadUInt8(streamId) / 255
	else
		self.fermentingPercentage = 0
	end
end

-- Local values: baleTypeIndex
function Bale:writeStream(streamId, connection)
	local v50_ = g_baleManager:getBaleTypeIndexByXMLFilename(self.xmlFilename) or 1
	streamWriteUIntN(streamId, v50_, BaleManager.SEND_NUM_BITS)
	streamWriteFloat32(streamId, self.fillLevel)
	streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.variationIndex - 1, Bale.NUM_BITS_VARIATION)
	if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
	end
	if streamWriteBool(streamId, self.wrapNormal ~= nil) then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
	end
	Bale:superClass().writeStream(self, streamId, connection)
	local v51_ = streamWriteUInt8
	local v52_ = self.wrappingState * 255
	v51_(streamId, (math.clamp(v52_, 0, 255)))
	Color.writeStreamRGB(streamId, self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])
	if streamWriteBool(streamId, self.isFermenting) then
		local v53_ = streamWriteUInt8
		local v54_ = self.fermentingPercentage * 255
		v53_(streamId, (math.clamp(v54_, 0, 255)))
	end
end

function Bale:mount(object, node, x, y, z, rx, ry, rz)
	Bale:superClass().mount(self, object, node, x, y, z, rx, ry, rz)
	self:setBaleAIObstacle(false)
end

function Bale:unmount()
	if not Bale:superClass().unmount(self) then
		return false
	end
	self:setReducedComponentMass(false)
	self:setBaleAIObstacle(true)
	return true
end

function Bale:mountKinematic(object, node, x, y, z, rx, ry, rz)
	Bale:superClass().mountKinematic(self, object, node, x, y, z, rx, ry, rz)
	self:setBaleAIObstacle(false)
end

function Bale:unmountKinematic()
	if not Bale:superClass().unmountKinematic(self) then
		return false
	end
	self:setReducedComponentMass(false)
	self:setBaleAIObstacle(true)
	return true
end

function Bale:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	if not Bale:superClass().mountDynamic(self, object, objectActorId, jointNode, mountType, forceAcceleration) then
		return false
	end
	self:setBaleAIObstacle(false)
	return true
end

function Bale:unmountDynamic(isDelete)
	Bale:superClass().unmountDynamic(self, isDelete)
	self:setReducedComponentMass(false)
	self:setBaleAIObstacle(true)
end

function Bale:setBaleAIObstacle(isActive)
	if isActive and self.obstacleNodeId == nil then
		g_currentMission.aiSystem:addObstacle(self.nodeId, nil, nil, nil, nil, nil, nil, nil)
		self.obstacleNodeId = self.nodeId
	elseif not isActive and self.obstacleNodeId ~= nil then
		g_currentMission.aiSystem:removeObstacle(self.obstacleNodeId)
		self.obstacleNodeId = nil
	end
end

-- Local values: baleRoot, sharedLoadRequestId, baleId
function Bale:createNode(i3dFilename)
	self.i3dFilename = i3dFilename
	local v87_, v88_ = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
	self.sharedLoadRequestId = v88_
	local v89_ = getChildAt(v87_, 0)
	link(getRootNode(), v89_)
	delete(v87_)
	self:setNodeId(v89_)
end

-- Local values: xmlFile
function Bale:loadFromConfigXML(xmlFilename, x, y, z, rx, ry, rz, uniqueId)
	if xmlFilename == nil or not fileExists(xmlFilename) then
		Logging.error("Failed to load bale. XML file could not be found! (%s)", xmlFilename)
		return false
	end
	if g_baleManager:getBaleTypeIndexByXMLFilename(xmlFilename) == nil and g_iconGenerator == nil then
		Logging.error("Failed to load bale. Bale not correctly registered! (%s)", xmlFilename)
		return false
	end
	local v99_ = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)
	self.xmlFilename = xmlFilename
	local v100_, v101_ = Utils.getModNameAndBaseDirectory(self.xmlFilename)
	self.customEnvironment = v100_
	self.baseDirectory = v101_
	self.i3dFilename = v99_:getValue("bale.filename")
	if self.i3dFilename ~= nil then
		self.i3dFilename = Utils.getFilename(self.i3dFilename, self.baseDirectory)
		self:createNode(self.i3dFilename)
		if x ~= nil and (y ~= nil and (z ~= nil and (rx ~= nil and (ry ~= nil and rz ~= nil)))) then
			setTranslation(self.nodeId, x, y, z)
			setRotation(self.nodeId, rx, ry, rz)
		end
		if not self:loadBaleAttributesFromXML(v99_) then
			Logging.error("Failed to load bale. Attributes could not be loaded. (%s)", xmlFilename)
			return false
		end
	end
	v99_:delete()
	if uniqueId ~= nil then
		self:setUniqueId(uniqueId)
	end
	g_currentMission.itemSystem:addItem(self)
	self:setBaleAIObstacle(true)
	return true
end

-- Local values: triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX
function Bale:loadBaleAttributesFromXML(xmlFile)
	self:setMountableObjectAttributes(xmlFile:getValue("bale.mountableObject#triggerNode", nil, self.nodeId), xmlFile:getValue("bale.mountableObject#forceAcceleration", 4), xmlFile:getValue("bale.mountableObject#forceLimitScale", 1), xmlFile:getValue("bale.mountableObject#axisFreeY", false), (xmlFile:getValue("bale.mountableObject#axisFreeX", false)))
	self.fillTypes = {}
	Bale.loadFillTypesFromXML(self.fillTypes, xmlFile, self.baseDirectory)
	self.variations = {}
	Bale.loadVariationsFromXML(self.variations, xmlFile, self.baseDirectory)
	self.isRoundbale = xmlFile:getValue("bale.size#isRoundbale", true)
	self.width = MathUtil.round(xmlFile:getValue("bale.size#width", 0), 2)
	self.height = MathUtil.round(xmlFile:getValue("bale.size#height", 0), 2)
	self.length = MathUtil.round(xmlFile:getValue("bale.size#length", 0), 2)
	self.diameter = MathUtil.round(xmlFile:getValue("bale.size#diameter", 0), 2)
	self.centerOffsetX = 0
	self.centerOffsetY = 0
	self.centerOffsetZ = 0
	self.uvId = xmlFile:getValue("bale.uvId", "DEFAULT")
	local v104_, v105_ = Bale.loadVisualMeshesFromXML(self.nodeId, xmlFile, self.baseDirectory)
	self.meshes = v104_
	self.tensionBeltMeshes = v105_
	return true
end

function Bale:getBaleMatchesSize(diameter, width, height, length)
	if self.isRoundbale then
		local v111_
		if diameter == self.diameter then
			v111_ = width == self.width
		else
			v111_ = false
		end
		return v111_
	else
		local v112_
		if width == self.width and height == self.height then
			v112_ = length == self.length
		else
			v112_ = false
		end
		return v112_
	end
end

function Bale:getSupportsWrapping()
	return self.supportsWrapping
end

-- Local values: x, y, z, rx, ry, rz, xmlFilename, attributes
function Bale:loadFromXMLFile(xmlFile, key, resetVehicles)
	local v118_, v119_, v120_ = xmlFile:getValue(key .. "#position")
	local v121_, v122_, v123_ = xmlFile:getValue(key .. "#rotation")
	if v118_ == nil or (v119_ == nil or (v120_ == nil or (v121_ == nil or (v122_ == nil or v123_ == nil)))) then
		return false
	end
	local v124_ = xmlFile:getValue(key .. "#filename")
	if v124_ == nil then
		return false
	end
	local v125_ = NetworkUtil.convertFromNetworkFilename(v124_)
	if not fileExists(v125_) then
		return false
	end
	local v126_ = {}
	Bale.loadBaleAttributesFromXMLFile(v126_, xmlFile, key, resetVehicles)
	if not self:loadFromConfigXML(v125_, v118_, v119_, v120_, v121_, v122_, v123_, v126_.uniqueId) then
		return false
	end
	self:applyBaleAttributes(v126_)
	return true
end

-- Local values: wrapDiffuse, wrapNormal
function Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)
	attributes.xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFile:getValue(key .. "#filename"))
	attributes.farmId = xmlFile:getValue(key .. "#farmId", AccessHandler.EVERYONE)
	attributes.fillLevel = xmlFile:getValue(key .. "#fillLevel")
	attributes.fillTypeName = xmlFile:getValue(key .. "#fillType")
	attributes.variationIndex = xmlFile:getValue(key .. "#variationIndex")
	attributes.fillType = g_fillTypeManager:getFillTypeIndexByName(attributes.fillTypeName)
	local v130_ = xmlFile:getValue(key .. ".textures#wrapDiffuse")
	if v130_ ~= nil then
		attributes.wrapDiffuse = NetworkUtil.convertFromNetworkFilename(v130_)
	end
	local v131_ = xmlFile:getValue(key .. ".textures#wrapNormal")
	if v131_ ~= nil then
		attributes.wrapNormal = NetworkUtil.convertFromNetworkFilename(v131_)
	end
	attributes.isFermenting = xmlFile:getValue(key .. ".fermentation#isFermenting", false)
	attributes.fermentationTime = xmlFile:getValue(key .. ".fermentation#time", 0)
	attributes.wrappingState = xmlFile:getValue(key .. "#wrappingState", 0)
	attributes.wrappingColor = xmlFile:getValue(key .. "#wrappingColor", nil, true) or { 1, 1, 1 }
	attributes.isMissionBale = xmlFile:getValue(key .. "#isMissionBale", false)
	attributes.uniqueId = xmlFile:getValue(key .. "#uniqueId", nil)
	return true
end

-- Local values: attributes
function Bale:getBaleAttributes()
	local v133_ = {
		["xmlFilename"] = self.xmlFilename,
		["farmId"] = self:getOwnerFarmId(),
		["fillLevel"] = self.fillLevel,
		["fillType"] = self.fillType,
		["variationIndex"] = self.variationIndex,
		["wrapDiffuse"] = self.wrapDiffuse,
		["wrapNormal"] = self.wrapNormal,
		["supportsWrapping"] = self.supportsWrapping,
		["wrappingState"] = self.wrappingState,
		["wrappingColor"] = self.wrappingColor,
		["isMissionBale"] = self.isMissionBale,
		["isFermenting"] = self.isFermenting
	}
	if self.isFermenting then
		v133_.fermentationTime = g_baleManager:getFermentationTime(self) or 0
	end
	return v133_
end

function Bale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.xmlFilename)))
	xmlFile:setValue(key .. "#fillLevel", attributes.fillLevel)
	xmlFile:setValue(key .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(attributes.fillType))
	xmlFile:setValue(key .. "#variationIndex", attributes.variationIndex)
	xmlFile:setValue(key .. "#farmId", attributes.farmId)
	xmlFile:setValue(key .. "#isMissionBale", attributes.isMissionBale)
	xmlFile:setValue(key .. "#wrappingState", attributes.wrappingState)
	xmlFile:setValue(key .. "#wrappingColor", attributes.wrappingColor[1], attributes.wrappingColor[2], attributes.wrappingColor[3])
	if attributes.wrapDiffuse ~= nil then
		xmlFile:setValue(key .. ".textures#wrapDiffuse", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.wrapDiffuse)))
	end
	if attributes.wrapNormal ~= nil then
		xmlFile:setValue(key .. ".textures#wrapNormal", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.wrapNormal)))
	end
	if attributes.isFermenting then
		xmlFile:setValue(key .. ".fermentation#isFermenting", true)
		xmlFile:setValue(key .. ".fermentation#time", attributes.fermentationTime)
	end
end

-- Local values: fillTypeIndex, fillTypeInfo, maxTime
function Bale:applyBaleAttributes(attributes)
	self:setOwnerFarmId(attributes.farmId or AccessHandler.EVERYONE)
	self:setFillLevel(attributes.fillLevel or self.fillLevel)
	if attributes.fillTypeName == nil then
		if attributes.fillType ~= nil then
			self:setFillType(attributes.fillType)
		end
	else
		self:setFillType(g_fillTypeManager:getFillTypeIndexByName(attributes.fillTypeName) or self.fillType)
	end
	self:setVariationIndex(attributes.variationIndex or self.variationIndex)
	self:setWrapTextures(attributes.wrapDiffuse, attributes.wrapNormal)
	self:setWrappingState(attributes.wrappingState, false)
	local v139_ = attributes.wrappingColor
	self:setColor(unpack(v139_))
	self.isMissionBale = Utils.getNoNil(attributes.isMissionBale, self.isMissionBale)
	if self.isServer and attributes.isFermenting then
		local v140_ = self:getFillTypeInfo(self.fillType)
		if v140_ ~= nil and v140_.fermenting ~= nil then
			local v141_ = v140_.fermenting.time * 86400000
			local v142_ = self.isMissionBale and 0 or v141_
			g_baleManager:registerFermentation(self, attributes.fermentationTime, v142_)
			self.isFermenting = true
			self:raiseDirtyFlags(self.fermentingDirtyFlag)
		end
	end
	return true
end

-- Local values: x, y, z, xRot, yRot, zRot
function Bale:saveToXMLFile(xmlFile, key)
	local v146_, v147_, v148_ = getTranslation(self.nodeId)
	local v149_, v150_, v151_ = getRotation(self.nodeId)
	xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.xmlFilename)))
	xmlFile:setValue(key .. "#position", v146_, v147_, v148_)
	xmlFile:setValue(key .. "#rotation", v149_, v150_, v151_)
	xmlFile:setValue(key .. "#fillLevel", self.fillLevel)
	xmlFile:setValue(key .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
	xmlFile:setValue(key .. "#variationIndex", self.variationIndex)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
	xmlFile:setValue(key .. "#isMissionBale", self.isMissionBale)
	xmlFile:setValue(key .. "#wrappingState", self.wrappingState)
	xmlFile:setValue(key .. "#wrappingColor", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])
	if self.wrapDiffuse ~= nil then
		xmlFile:setValue(key .. ".textures#wrapDiffuse", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapDiffuse)))
	end
	if self.wrapNormal ~= nil then
		xmlFile:setValue(key .. ".textures#wrapNormal", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapNormal)))
	end
	if self.isFermenting then
		xmlFile:setValue(key .. ".fermentation#isFermenting", true)
		xmlFile:setValue(key .. ".fermentation#time", g_baleManager:getFermentationTime(self))
	end
end

function Bale:setNeedsSaving(needsSaving)
	self.needsSaving = needsSaving
end

-- Local values: _, y, _
function Bale:getNeedsSaving()
	if not self.needsSaving then
		return false
	end
	local _, v155_, _ = getTranslation(self.nodeId)
	return v155_ > -90
end

function Bale:getAutoLoadIsSupported()
	return true
end

function Bale:getAutoLoadIsAllowed()
	return self:getAllowPickup()
end

-- Local values: sizeX, sizeY, sizeZ
function Bale:getAutoLoadSize()
	return self.width, self.isRoundbale and self.diameter or self.height, self.isRoundbale and self.diameter or self.length
end

-- Local values: mountPosX, mountPosY, mountPosZ, mountRotX, mountRotY, mountRotZ
function Bale:autoLoad(autoLoader, node, posX, posZ, sizeX, sizeZ)
	local v165_ = posX + sizeX * 0.5
	local v166_ = self.isRoundbale and self.diameter * 0.5 or self.height * 0.5
	local v167_ = posZ + sizeZ * 0.5
	local v168_ = self.isRoundbale and 1.5707963267948966 or 0
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		self:unmountKinematic()
	end
	self:mountKinematic(autoLoader, node, v165_, v166_, v167_, 0, v168_, 0)
	return true
end

-- Local values: x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ
function Bale:getAutoLoadBoundingBox()
	local v170_, v171_, v172_ = getWorldTranslation(self.nodeId)
	local v173_, v174_, v175_ = localDirectionToWorld(self.nodeId, 0, 0, 1)
	local v176_, v177_, v178_ = localDirectionToWorld(self.nodeId, 0, 1, 0)
	return v170_, v171_, v172_, v173_, v174_, v175_, v176_, v177_, v178_, self.width * 0.5, self.isRoundbale and self.diameter * 0.5 or self.height * 0.5, self.isRoundbale and self.diameter * 0.5 or self.length * 0.5
end

-- Local values: pricePerLiter
function Bale:getValue()
	local v180_ = g_currentMission.economyManager:getPricePerLiter(self.fillType)
	return self.fillLevel * v180_
end

function Bale:getMass()
	return entityExists(self.nodeId or 0) and getMass(self.nodeId) or 0
end

function Bale:getDefaultMass()
	return self.defaultMass
end

function Bale:getFillType()
	return self.fillType
end

function Bale:setReducedComponentMass(state)
	if state then
		setMass(self.nodeId, 0.1)
	else
		setMass(self.nodeId, self.defaultMass)
	end
end

function Bale:getAllowComponentMassReduction()
	return self.defaultMass > 0.1
end

-- Local values: fillTypeInfo, maxTime
function Bale:setFillType(fillTypeIndex, fillBale)
	Bale.setFillTypeTextures(self.meshes, self.fillTypes, fillTypeIndex)
	self.fillType = fillTypeIndex
	self.supportsWrapping = false
	local v190_ = self:getFillTypeInfo(self.fillType)
	if v190_ ~= nil then
		self.supportsWrapping = v190_.supportsWrapping
		setMass(self.nodeId, v190_.mass)
		self.defaultMass = v190_.mass
		if self.isServer then
			if v190_.forceAcceleration ~= nil then
				self:setMountableObjectAttributes(nil, v190_.forceAcceleration, self.dynamicMountForceLimitScale, self.dynamicMountSingleAxisFreeY, self.dynamicMountSingleAxisFreeX)
			end
			if v190_.fermenting ~= nil and not v190_.fermenting.requiresWrapping then
				if self.isFermenting then
					g_baleManager:removeFermentation(self)
				end
				local v191_ = v190_.fermenting.time * 86400000
				g_baleManager:registerFermentation(self, 0, v191_)
				self.isFermenting = true
				self:raiseDirtyFlags(self.fermentingDirtyFlag)
			end
		end
		if fillBale == true then
			self:setFillLevel(v190_.capacity)
		end
	end
	Bale.updateVisualMeshVisibility(self.meshes, self.fillType, self.wrappingState ~= 0)
	Bale.updateVisualMeshWrappingState(self.meshes, self.wrappingState, self.wrappingColor)
	if self.isServer then
		self:raiseDirtyFlags(self.fillTypeDirtyFlag)
	end
end

-- Local values: variation
function Bale:setVariationIndex(variationIndex)
	local v194_ = self.variations[variationIndex or 1]
	if v194_ ~= nil then
		self.variationIndex = variationIndex
		Bale.setVariationTextures(self.meshes, self.variations, v194_.id)
		if self.isServer then
			self:raiseDirtyFlags(self.variationDirtyFlag)
		end
	end
end

-- Local values: variationIndex, variation
function Bale:setVariationId(variationId)
	if variationId == nil then
		self:setVariationIndex(1)
		return true
	else
		for v197_, v198_ in ipairs(self.variations) do
			if string.lower(v198_.id) == string.lower(variationId) then
				self:setVariationIndex(v197_)
				return true
			end
		end
		return false
	end
end

-- Local values: variation
function Bale:getVariationId()
	if #self.variations == 0 then
		return "NONE"
	end
	local v200_ = self.variations[self.variationIndex]
	return v200_ == nil and "NONE" or v200_.id
end

-- Local values: fillTypeInfo
function Bale:getCapacity()
	local v202_ = self:getFillTypeInfo(self.fillType)
	return v202_ == nil and 0 or v202_.capacity
end

function Bale:getFillLevel()
	return self.fillLevel
end

function Bale:setFillLevel(fillLevel)
	self.fillLevel = fillLevel
	if self.isServer then
		self:raiseDirtyFlags(self.fillLevelDirtyFlag)
	end
end

-- Local values: i
function Bale:getFillTypeInfo(fillTypeIndex)
	for v207_ = 1, #self.fillTypes do
		if self.fillTypes[v207_].fillTypeIndex == self.fillType then
			return self.fillTypes[v207_]
		end
	end
	return nil
end

function Bale:setCanBeSold(canBeSold)
	self.canBeSold = canBeSold
end

function Bale:getCanBeSold()
	return self.canBeSold
end

-- Local values: i, meshData, visibility, fillTypeInfo, maxTime
function Bale:setWrappingState(wrappingState, updateFermentation)
	if self.isServer and self.wrappingState ~= wrappingState then
		self:raiseDirtyFlags(self.wrapStateDirtyFlag)
	end
	self.wrappingState = wrappingState
	for v214_ = 1, #self.meshes do
		local v215_ = self.meshes[v214_]
		local v216_
		if v215_.supportsWrapping or wrappingState == 0 then
			v216_ = v215_.fillTypeVisibility
		else
			v216_ = false
		end
		setVisibility(v215_.node, v216_)
		if v216_ then
			setShaderParameter(v215_.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
		end
	end
	if self.isServer and (updateFermentation ~= false and self.wrappingState >= 1) then
		local v217_ = self:getFillTypeInfo(self.fillType)
		if v217_ ~= nil and (v217_.fermenting ~= nil and (v217_.fermenting.requiresWrapping and not self.isFermenting)) then
			local v218_ = v217_.fermenting.time * 86400000
			local v219_ = self.isMissionBale and 0 or v218_
			g_baleManager:registerFermentation(self, 0, v219_)
			self.isFermenting = true
			self:raiseDirtyFlags(self.fermentingDirtyFlag)
		end
	end
	if wrappingState > 0 then
		g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
	else
		g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	end
end

-- Local values: i, meshData, materialId
function Bale:setWrapTextures(diffuse, normal)
	self.wrapDiffuse = diffuse or self.wrapDiffuse
	self.wrapNormal = normal or self.wrapNormal
	for v223_ = 1, #self.meshes do
		local v224_ = self.meshes[v223_]
		local v225_ = getMaterial(v224_.node, 0)
		if self.wrapDiffuse ~= nil then
			if textureFileExists(self.wrapDiffuse) then
				v225_ = setMaterialCustomMapFromFile(v225_, "wrapDiffuseMap", self.wrapDiffuse, false, true, false)
			else
				Logging.warning("Unknown bale wrapping texture \'%s\'. Using default texture.", self.wrapDiffuse)
			end
		end
		if self.wrapNormal ~= nil then
			if textureFileExists(self.wrapNormal) then
				v225_ = setMaterialCustomMapFromFile(v225_, "wrapNormalMap", self.wrapNormal, false, false, false)
			else
				Logging.warning("Unknown bale wrapping texture \'%s\'. Using default texture.", self.wrapNormal)
			end
		end
		setMaterial(v224_.node, v225_, 0)
		setShaderParameter(v224_.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
		setShaderParameter(v224_.node, "colorScale", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3], 1, false)
	end
	if self.isServer and (diffuse ~= nil or normal ~= nil) then
		self:raiseDirtyFlags(self.texturesDirtyFlag)
	end
end

-- Local values: i, meshData
function Bale:setColor(r, g, b)
	local v230_ = r or 1
	local v231_ = g or 1
	local v232_ = b or 1
	if v230_ ~= self.wrappingColor[1] or (v231_ ~= self.wrappingColor[2] or v232_ ~= self.wrappingColor[3]) then
		if self.isServer then
			self:raiseDirtyFlags(self.wrapColorDirtyFlag)
		end
		self.wrappingColor[1] = v230_
		self.wrappingColor[2] = v231_
		self.wrappingColor[3] = v232_
		for v233_ = 1, #self.meshes do
			local v234_ = self.meshes[v233_]
			if getHasShaderParameter(v234_.node, "colorScale") then
				setShaderParameter(v234_.node, "colorScale", v230_, v231_, v232_, 1, false)
			end
		end
	end
end

function Bale:setIsMissionBale(state)
	self.isMissionBale = state
end

function Bale:getMeshNodes()
	return self.tensionBeltMeshes
end

function Bale:getSupportsTensionBelts()
	return true
end

function Bale:getTensionBeltNodeId()
	return self.nodeId
end

function Bale:getBaleSupportsBaleLoader()
	return true
end

function Bale:getAllowPickup()
	return self.allowPickup
end

function Bale:getAdditionalMountingDistance()
	return self.isRoundbale and 0 or self.height * 0.5
end

function Bale:getIsFermenting()
	return self.isFermenting
end

function Bale:getFermentingPercentage()
	return not self.isFermenting and 0 or self.fermentingPercentage
end

function Bale:onFermentationUpdate(percentage)
	self.fermentingPercentage = percentage
	self:raiseDirtyFlags(self.fermentingDirtyFlag)
end

-- Local values: fillTypeInfo
function Bale:onFermentationEnd()
	if self.isServer and self.isFermenting then
		local v246_ = self:getFillTypeInfo(self.fillType)
		if v246_ ~= nil and v246_.fermenting ~= nil then
			self:setFillType(v246_.fermenting.outputFillTypeIndex)
		end
		self.isFermenting = false
		self:raiseDirtyFlags(self.fermentingDirtyFlag)
	end
end

function Bale:getCanBeOpened()
	if self.wrappingState <= 0 then
		return false
	elseif self.isFermenting then
		return false
	else
		return self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE
	end
end

function Bale:getInteractionPosition()
	if not g_localPlayer:getIsInVehicle() then
		return getWorldTranslation(g_localPlayer.rootNode)
	end
end

-- Local values: px, py, pz, x, y, z, distance
function Bale:getCanInteract()
	if not g_currentMission.accessHandler:canPlayerAccess(self) then
		return false
	end
	local v249_, v250_, v251_ = self:getInteractionPosition()
	if v249_ == nil then
		return false
	end
	local v252_, v253_, v254_ = getWorldTranslation(self.nodeId)
	return MathUtil.vector3Length(v252_ - v249_, v253_ - v250_, v254_ - v251_) <= Bale.INTERACTION_RADIUS
end

function Bale:open()
	self:setWrappingState(0)
end

-- Local values: i, meshData
function Bale:resetDetailVisibilityCut()
	for v257_ = 1, #self.meshes do
		local v258_ = self.meshes[v257_]
		if getHasShaderParameter(v258_.node, "visibilityXZ") then
			setShaderParameter(v258_.node, "visibilityXZ", 5, -5, 5, -5, false)
		end
	end
end

-- Local values: i
function Bale:setDetailVisibilityCutNode(node, axis, direction)
	for v263_ = 1, #self.meshes do
		Bale.setBaleMeshVisibilityCut(self.meshes[v263_].node, node, axis, direction, false)
	end
end

-- Local values: sx, sy, sz, sw, x, _, z, i
function Bale.setBaleMeshVisibilityCut(baleMesh, node, axis, direction, recursively)
	if getHasShaderParameter(baleMesh, "visibilityXZ") then
		local v269_ = nil
		local v270_ = nil
		local v271_ = nil
		local v272_ = nil
		local v273_, _, v274_ = localToLocal(node, baleMesh, 0, 0, 0)
		if axis == 1 then
			if direction > 0 then
				v274_ = v272_
				v269_ = v273_
			else
				v274_ = v272_
				v270_ = v273_
			end
		elseif direction > 0 then
			v271_ = v274_
			v274_ = v272_
		end
		setShaderParameter(baleMesh, "visibilityXZ", v269_, v270_, v271_, v274_, false)
	end
	if recursively then
		for v275_ = 1, getNumOfChildren(baleMesh) do
			Bale.setBaleMeshVisibilityCut(getChildAt(baleMesh, v275_ - 1), node, axis, direction, recursively)
		end
	end
end
function Bale.doDensityMapItemAreaUpdate(p276_, p277_, p278_, ...)
	if p276_.isRoundbale then
		local v279_, _, v280_ = getWorldTranslation(p276_.nodeId)
		local v281_ = v279_ + p276_.width * 0.4
		local v282_ = v280_ + p276_.width * 0.4
		local v283_ = v279_ - p276_.width * 0.4
		local v284_ = v280_ + p276_.width * 0.4
		local v285_ = v279_ + p276_.width * 0.4
		local v286_ = v280_ - p276_.width * 0.4
		p277_(p278_, v281_ + 0.25, v282_ + 0.25, v283_ + 0.25, v284_ + 0.25, v285_ + 0.25, v286_ + 0.25, ...)
	else
		local v287_, _, v288_ = localToWorld(p276_.nodeId, p276_.width * 0.4, p276_.height * 0.4, p276_.length * 0.4)
		local v289_, _, v290_ = localToWorld(p276_.nodeId, -p276_.width * 0.4, -p276_.height * 0.4, p276_.length * 0.4)
		local v291_, _, v292_ = localToWorld(p276_.nodeId, p276_.width * 0.4, p276_.height * 0.4, -p276_.length * 0.4)
		p277_(p278_, v287_ + 0.25, v288_ + 0.25, v289_ + 0.25, v290_ + 0.25, v291_ + 0.25, v292_ + 0.25, ...)
	end
end

-- Local values: fillType, fillLevel, fillTypeDesc
function Bale:showInfo(box)
	local v295_ = self:getFillType()
	local v296_ = self:getFillLevel()
	box:addLine(g_fillTypeManager:getFillTypeByIndex(v295_).title, g_i18n:formatVolume(v296_, 0))
	if self:getIsFermenting() then
		box:addLine(g_i18n:getText("info_fermenting"), string.format("%d%%", self:getFermentingPercentage() * 100))
	end
	box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(self:getMass()))
end

function Bale:setUniqueId(uniqueId)
	self.uniqueId = uniqueId
end

function Bale:getUniqueId()
	return self.uniqueId
end

-- Local values: xmlFile, baleId, baleRoot, sharedLoadRequestId, i3dFilename, _, baseDirectory, meshes, fillTypes, variations
function Bale.createDummyBale(xmlFilename, fillTypeIndex, variationId, wrappingState, wrappingColor)
	local v305_ = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)
	local v306_ = nil
	local v307_ = v305_:getValue("bale.filename")
	local v308_
	if v307_ == nil then
		v308_ = nil
	else
		local _, v309_ = Utils.getModNameAndBaseDirectory(xmlFilename)
		local v310_ = Utils.getFilename(v307_, v309_)
		local v311_
		v311_, v308_ = g_i3DManager:loadSharedI3DFile(v310_, false, false)
		if v311_ ~= 0 then
			v306_ = getChildAt(v311_, 0)
			setRigidBodyType(v306_, RigidBodyType.NONE)
			unlink(v306_)
			local v312_ = wrappingState or 0
			local v313_ = Bale.loadVisualMeshesFromXML(v306_, v305_, v309_)
			local v314_ = {}
			Bale.loadFillTypesFromXML(v314_, v305_, v309_)
			Bale.setFillTypeTextures(v313_, v314_, fillTypeIndex)
			local v315_ = {}
			Bale.loadVariationsFromXML(v315_, v305_, v309_)
			Bale.setVariationTextures(v313_, v315_, variationId)
			Bale.updateVisualMeshVisibility(v313_, fillTypeIndex, v312_ > 0)
			Bale.updateVisualMeshWrappingState(v313_, v312_, wrappingColor)
			delete(v311_)
		end
	end
	v305_:delete()
	return v306_, v308_
end

function Bale.loadTexturesFromXML(target, xmlFile, key, baseDirectory)
	target.diffuseFilename = xmlFile:getValue(key .. ".diffuse#filename", nil, baseDirectory)
	target.diffuseUseFillTypeArray = xmlFile:getValue(key .. ".diffuse#useFillTypeArray", false)
	target.normalFilename = xmlFile:getValue(key .. ".normal#filename", nil, baseDirectory)
	target.normalUseFillTypeArray = xmlFile:getValue(key .. ".normal#useFillTypeArray", false)
	target.alphaFilename = xmlFile:getValue(key .. ".alpha#filename", nil, baseDirectory)
	target.baleNormalFilename = xmlFile:getValue(key .. ".baleNormal#filename", nil, baseDirectory)
	target.netWrapDiffuseFilename = xmlFile:getValue(key .. ".netWrapDiffuse#filename", nil, baseDirectory)
	target.netWrapNormalFilename = xmlFile:getValue(key .. ".netWrapNormal#filename", nil, baseDirectory)
end

function Bale.loadFillTypesFromXML(fillTypes, xmlFile, baseDirectory)
	xmlFile:iterate("bale.fillTypes.fillType", function(_, p323_)
		-- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) fillTypes
		local v324_ = xmlFile:getValue(p323_ .. "#name")
		local v325_ = g_fillTypeManager:getFillTypeIndexByName(v324_)
		if v325_ ~= nil then
			local v326_ = {
				["fillTypeIndex"] = v325_,
				["capacity"] = xmlFile:getValue(p323_ .. "#capacity", 1000),
				["mass"] = xmlFile:getValue(p323_ .. "#mass", 500) / 1000,
				["forceAcceleration"] = xmlFile:getValue(p323_ .. "#forceAcceleration"),
				["supportsWrapping"] = xmlFile:getValue(p323_ .. "#supportsWrapping", false),
				["materialName"] = xmlFile:getValue(p323_ .. "#materialName"),
				["alphaMaterialName"] = xmlFile:getValue(p323_ .. "#alphaMaterialName")
			}
			Bale.loadTexturesFromXML(v326_, xmlFile, p323_, baseDirectory)
			local v327_ = xmlFile:getValue(p323_ .. ".fermenting#outputFillType")
			local v328_ = g_fillTypeManager:getFillTypeIndexByName(v327_)
			if v328_ ~= nil then
				v326_.fermenting = {}
				v326_.fermenting.outputFillTypeIndex = v328_
				v326_.fermenting.requiresWrapping = xmlFile:getValue(p323_ .. ".fermenting#requiresWrapping", true)
				v326_.fermenting.time = xmlFile:getValue(p323_ .. ".fermenting#time", 0)
			end
			local v329_ = fillTypes
			table.insert(v329_, v326_)
		end
	end)
end

-- Local values: _, key, id, variation
function Bale.loadVariationsFromXML(variations, xmlFile, baseDirectory)
	for _, v333_ in xmlFile:iterator("bale.variations.variation") do
		local v334_ = xmlFile:getValue(v333_ .. "#id")
		if v334_ ~= nil then
			local v335_ = {
				["id"] = v334_
			}
			Bale.loadTexturesFromXML(v335_, xmlFile, v333_, baseDirectory)
			table.insert(variations, v335_)
		end
	end
	if #variations == 0 then
		table.insert(variations, {
			["id"] = "DEFAULT"
		})
	end
end

-- Local values: i, fillTypeInfo, _, meshData, materialName, materialId, textureArrayIndex
function Bale.setFillTypeTextures(meshes, fillTypes, fillTypeIndex)
	for v339_ = 1, #fillTypes do
		local v340_ = fillTypes[v339_]
		if v340_.fillTypeIndex == fillTypeIndex then
			for _, v341_ in ipairs(meshes) do
				local v342_ = v340_.materialName
				if v341_.isAlphaMesh then
					v342_ = v340_.alphaMaterialName
				end
				if v340_.materialName ~= nil then
					local v343_ = g_materialManager:getBaseMaterialByName(v342_)
					if v343_ == nil then
						Logging.warning("Unable to find bale material \'%s\'", v342_)
					else
						setMaterial(v341_.node, v343_, 0)
					end
				end
				Bale.setTexturesForNode(v341_.node, v340_)
				if getHasShaderParameter(v341_.node, "fillTypeId") then
					local v344_ = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(v340_.fillTypeIndex)
					if v344_ ~= nil then
						setShaderParameter(v341_.node, "fillTypeId", v344_ - 1, 0, 0, 0, true)
					end
				end
			end
			return
		end
	end
end

-- Local values: variation, i, _, meshData, _, meshData
function Bale.setVariationTextures(meshes, variations, id)
	if type(id) == "number" then
		local v348_ = variations[id]
		if v348_ == nil then
			id = nil
		else
			id = v348_.id or nil
		end
	end
	for v349_ = 1, #variations do
		if variations[v349_].id == id then
			for _, v350_ in ipairs(meshes) do
				Bale.setTexturesForNode(v350_.node, variations[v349_])
			end
			return
		end
	end
	if #variations > 0 then
		for _, v351_ in ipairs(meshes) do
			Bale.setTexturesForNode(v351_.node, variations[1])
		end
	end
end

-- Local values: materialId, shaderFilename
function Bale.setTexturesForNode(nodeId, textureData)
	if getHasClassId(nodeId, ClassIds.SHAPE) then
		local v354_ = getMaterial(nodeId, 0)
		if v354_ ~= 0 and getMaterialCustomShaderFilename(v354_):contains("wrapBaleShader") then
			if textureData.diffuseFilename == nil then
				if textureData.diffuseUseFillTypeArray then
					g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, g_terrainNode, true, false, false)
					v354_ = getMaterial(nodeId, 0)
				end
			else
				v354_ = setMaterialDiffuseMapFromFile(v354_, textureData.diffuseFilename, true, true, false)
			end
			if textureData.normalFilename == nil then
				if textureData.normalUseFillTypeArray then
					g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, g_terrainNode, false, true, false)
					v354_ = getMaterial(nodeId, 0)
				end
			else
				v354_ = setMaterialNormalMapFromFile(v354_, textureData.normalFilename, true, false, false)
			end
			if textureData.alphaFilename ~= nil then
				v354_ = setMaterialCustomMapFromFile(v354_, "alphaMap", textureData.alphaFilename, true, false, false)
			end
			if textureData.baleNormalFilename ~= nil then
				v354_ = setMaterialCustomMapFromFile(v354_, "baleNormalMap", textureData.baleNormalFilename, true, false, false)
			end
			if textureData.netWrapDiffuseFilename ~= nil then
				v354_ = setMaterialCustomMapFromFile(v354_, "netWrapDiffuseMap", textureData.netWrapDiffuseFilename, true, true, false)
			end
			if textureData.netWrapNormalFilename ~= nil then
				v354_ = setMaterialCustomMapFromFile(v354_, "netWrapNormalMap", textureData.netWrapNormalFilename, true, false, false)
			end
			setMaterial(nodeId, v354_, 0)
		end
	end
end

-- Local values: meshes, tensionBeltMeshes
function Bale.loadVisualMeshesFromXML(rootNode, xmlFile, baseDirectory)
	local v_u_357_ = {}
	local v_u_358_ = {}
	xmlFile:iterate("bale.baleMeshes.baleMesh", function(_, p359_)
		-- upvalues: (copy) xmlFile, (copy) rootNode, (copy) v_u_358_, (copy) v_u_357_
		local v360_ = {
			["node"] = xmlFile:getValue(p359_ .. "#node", nil, rootNode),
			["supportsWrapping"] = xmlFile:getValue(p359_ .. "#supportsWrapping", true)
		}
		local v361_ = xmlFile:getValue(p359_ .. "#fillTypes")
		v360_.fillTypes = g_fillTypeManager:getFillTypesByNames(v361_)
		v360_.fillTypeVisibility = true
		v360_.isTensionBeltMesh = xmlFile:getValue(p359_ .. "#isTensionBeltMesh", false)
		if v360_.isTensionBeltMesh then
			local v362_ = v_u_358_
			local v363_ = v360_.node
			table.insert(v362_, v363_)
		end
		v360_.isAlphaMesh = xmlFile:getValue(p359_ .. "#isAlphaMesh", false)
		local v364_ = v_u_357_
		table.insert(v364_, v360_)
	end)
	return v_u_357_, v_u_358_
end

-- Local values: i, meshData, j
function Bale.updateVisualMeshVisibility(meshes, fillTypeIndex, isWrapped)
	for v368_ = 1, #meshes do
		local v369_ = meshes[v368_]
		if v369_.fillTypes ~= nil and #v369_.fillTypes > 0 then
			setVisibility(v369_.node, false)
			v369_.fillTypeVisibility = false
			for v370_ = 1, #v369_.fillTypes do
				if v369_.fillTypes[v370_] == fillTypeIndex then
					if v369_.supportsWrapping or not isWrapped then
						setVisibility(v369_.node, true)
					end
					v369_.fillTypeVisibility = true
					break
				end
			end
		end
	end
end

-- Local values: i, node
function Bale.updateVisualMeshWrappingState(meshes, wrappingState, wrappingColor)
	for v374_ = 1, #meshes do
		local v375_ = meshes[v374_].node
		setShaderParameter(v375_, "wrappingState", wrappingState, 0, 0, 0, false)
		if wrappingState > 0 and getHasShaderParameter(v375_, "colorScale") then
			if wrappingColor == nil or #wrappingColor ~= 3 then
				setShaderParameter(v375_, "colorScale", 0.85, 0.85, 0.85, 1, false)
			else
				setShaderParameter(v375_, "colorScale", wrappingColor[1], wrappingColor[2], wrappingColor[3], 1, false)
			end
		end
	end
end
BaleActivatable = {}
local v_u_376_ = Class(BaleActivatable)
function BaleActivatable.new(p377_)
	-- upvalues: (copy) v_u_376_
	local v378_ = v_u_376_
	local v379_ = setmetatable({}, v378_)
	v379_.bale = p377_
	v379_.activateText = g_i18n:getText("action_cutBale")
	return v379_
end

function BaleActivatable:getIsActivatable()
	return self.bale:getCanInteract() and self.bale:getCanBeOpened() and true or false
end

function BaleActivatable:getHasAccess(farmId)
	return g_currentMission.accessHandler:canFarmAccessOtherId(farmId, self.bale:getOwnerFarmId())
end

-- Local values: x, _, z, distance
function BaleActivatable:getDistance(posX, posY, posZ)
	if self.bale.nodeId == 0 then
		return math.huge
	end
	local v386_, _, v387_ = getWorldTranslation(self.bale.nodeId)
	return MathUtil.vector2Length(posX - v386_, posZ - v387_)
end

function BaleActivatable:run()
	if g_server == nil then
		g_client:getServerConnection():sendEvent(BaleOpenEvent.new(self.bale))
	else
		self.bale:open()
	end
end
