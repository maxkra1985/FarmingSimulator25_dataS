PlaceableHandToolHolders = {}

function PlaceableHandToolHolders.prerequisitesPresent(vehicleType)
	return true
end
function PlaceableHandToolHolders.initSpecialization()
	HandToolHolder.registerXMLPaths(Placeable.xmlSchema, "placeable.handToolHolders")
	local v1_ = Placeable.xmlSchemaSavegame
	HandToolHolder.registerSavegameXMLPaths(Placeable.xmlSchemaSavegame, "placeables.placeable(?).handToolHolders.handToolHolder(?)")
	v1_:register(XMLValueType.INT, "placeables.placeable(?).handToolHolders.handToolHolder(?)#index", "Index of the holder", nil, true)
end

function PlaceableHandToolHolders.registerEvents(vehicleType) end

function PlaceableHandToolHolders.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onHandToolHolderFinished", PlaceableHandToolHolders.onHandToolHolderFinished)
end

function PlaceableHandToolHolders.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableHandToolHolders.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setName", PlaceableHandToolHolders.setName)
end

function PlaceableHandToolHolders.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHandToolHolders)
	SpecializationUtil.registerEventListener(placeableType, "onLoadFinished", PlaceableHandToolHolders)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHandToolHolders)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHandToolHolders)
	SpecializationUtil.registerEventListener(placeableType, "saveToXMLFile", PlaceableHandToolHolders)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHandToolHolders)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHandToolHolders)
	SpecializationUtil.registerEventListener(placeableType, "onRegistered", PlaceableHandToolHolders)
end

-- Local values: spec, holderName, nodeIndex, key, handToolHolder, loadingTask, args
function PlaceableHandToolHolders:onLoad(savegame)
	self.spec_handToolHolders.handToolHolders = {}
	local v7_ = string.format(g_i18n:getText("ui_handToolHolderPlaceable"), self:getName())
	for _, v8_ in self.xmlFile:iterator("placeable.handToolHolders.handToolHolder") do
		local v9_ = HandToolHolder.new(self, self.isServer, self.isClient)
		v9_:setHolderName(v7_)
		local v10_ = {
			["loadingTask"] = self:createLoadingTask(self),
			["savegame"] = savegame
		}
		v9_:load(self.xmlFile, v8_, self.onHandToolHolderFinished, self, v10_, self.components, self.i3dMappings, self.baseDirectory, self.customEnvironment)
	end
end

-- Local values: spec, handToolIndex, savegame, _, key, index
function PlaceableHandToolHolders:onHandToolHolderFinished(handToolHolder, args)
	if handToolHolder ~= nil then
		local v14_ = self.spec_handToolHolders
		local v15_ = v14_.handToolHolders
		table.insert(v15_, handToolHolder)
		local v16_ = #v14_.handToolHolders
		local v17_ = args.savegame
		if v17_ ~= nil and not v17_.resetVehicles then
			for _, v18_ in v17_.xmlFile:iterator(v17_.key .. ".handToolHolders.handToolHolder") do
				if v17_.xmlFile:getValue(v18_ .. "#index") == v16_ then
					handToolHolder:loadFromXMLFile(v17_.xmlFile, v18_)
					break
				end
			end
		end
	end
	self:finishLoadingTask(args.loadingTask)
end

-- Local values: spec, i, handToolHolder, j, clickBox
function PlaceableHandToolHolders:onLoadFinished(savegame)
	local v20_ = self.spec_handToolHolders
	if v20_.handToolHolders ~= nil then
		for _, v21_ in ipairs(v20_.handToolHolders) do
			for _, v22_ in ipairs(v21_.clickBoxes) do
				removeFromPhysics(v22_)
			end
		end
	end
end

-- Local values: spec, i, handToolHolder, j, clickBox
function PlaceableHandToolHolders:onFinalizePlacement()
	local v24_ = self.spec_handToolHolders
	for _, v25_ in ipairs(v24_.handToolHolders) do
		for _, v26_ in ipairs(v25_.clickBoxes) do
			addToPhysics(v26_)
		end
		v25_:setOwnerFarmId(self:getOwnerFarmId())
	end
end

-- Local values: spec, _, handToolHolder
function PlaceableHandToolHolders:onDelete()
	local v28_ = self.spec_handToolHolders
	if v28_.handToolHolders ~= nil then
		for _, v29_ in ipairs(v28_.handToolHolders) do
			v29_:delete()
		end
	end
end

-- Local values: spec, k, handToolHolder, holderKey
function PlaceableHandToolHolders:saveToXMLFile(xmlFile, key, usedModNames)
	local v33_ = self.spec_handToolHolders
	if v33_.handToolHolders ~= nil then
		for v34_, v35_ in ipairs(v33_.handToolHolders) do
			local v36_ = string.format("%s.handToolHolder(%d)", key, v34_ - 1)
			xmlFile:setValue(v36_ .. "#index", v34_)
			v35_:saveToXMLFile(xmlFile, v36_)
		end
	end
end

-- Local values: spec, _, handToolHolder
function PlaceableHandToolHolders:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v40_ = self.spec_handToolHolders
		if v40_.handToolHolders ~= nil then
			for _, v41_ in ipairs(v40_.handToolHolders) do
				NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v41_))
				v41_:writeStream(streamId, connection)
				g_server:registerObjectInStream(connection, v41_)
			end
		end
	end
end

-- Local values: spec, _, handToolHolder, handToolHolderId
function PlaceableHandToolHolders:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v45_ = self.spec_handToolHolders
		if v45_.handToolHolders ~= nil then
			for _, v46_ in ipairs(v45_.handToolHolders) do
				local v47_ = NetworkUtil.readNodeObjectId(streamId)
				v46_:readStream(streamId, connection)
				g_client:finishRegisterObject(v46_, v47_)
			end
		end
	end
end

-- Local values: spec, _, handToolHolder
function PlaceableHandToolHolders:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	superFunc(self, ownerFarmId, noEventSend)
	local v52_ = self.spec_handToolHolders
	if v52_.handToolHolders ~= nil then
		for _, v53_ in ipairs(v52_.handToolHolders) do
			v53_:setOwnerFarmId(ownerFarmId, true)
		end
	end
end

-- Local values: spec, _, handToolHolder
function PlaceableHandToolHolders:setName(superFunc, name, noEventSend)
	superFunc(self, name, noEventSend)
	local v58_ = self.spec_handToolHolders
	if v58_.handToolHolders ~= nil then
		for _, v59_ in ipairs(v58_.handToolHolders) do
			v59_:setName(name)
		end
	end
end

-- Local values: spec, _, handToolHolder
function PlaceableHandToolHolders:onRegistered(alreadySent)
	local v61_ = self.spec_handToolHolders
	if v61_.handToolHolders ~= nil then
		for _, v62_ in ipairs(v61_.handToolHolders) do
			v62_:register(true)
		end
	end
end
