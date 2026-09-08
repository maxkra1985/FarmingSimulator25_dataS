PlaceableSellingStation = {}

function PlaceableSellingStation.prerequisitesPresent(specializations)
	return true
end

function PlaceableSellingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getSellingStation", PlaceableSellingStation.getSellingStation)
end

function PlaceableSellingStation.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableSellingStation.collectPickObjects)
end

function PlaceableSellingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSellingStation)
end

function PlaceableSellingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SellingStation")
	SellingStation.registerXMLPaths(schema, basePath .. ".sellingStation")
	schema:setXMLSpecializationType()
end

function PlaceableSellingStation.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SellingStation")
	SellingStation.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end
function PlaceableSellingStation.initSpecialization()
	g_storeManager:addSpecType("sellingStationFillTypes", "shopListAttributeIconInput", SellingStation.loadSpecValueFillTypes, SellingStation.getSpecValueFillTypes, StoreSpecies.PLACEABLE)
end

-- Local values: spec, xmlFile
function PlaceableSellingStation:onLoad(savegame)
	local v9_ = self.spec_sellingStation
	local v10_ = self.xmlFile
	v9_.sellingStation = SellingStation.new(self.isServer, self.isClient)
	v9_.sellingStation:load(self.components, v10_, "placeable.sellingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
	v9_.sellingStation.owningPlaceable = self
end

-- Local values: spec
function PlaceableSellingStation:onDelete()
	local v12_ = self.spec_sellingStation
	if v12_.sellingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(v12_.sellingStation, self)
		g_currentMission.economyManager:removeSellingStation(v12_.sellingStation)
		v12_.sellingStation:delete()
	end
end

-- Local values: spec
function PlaceableSellingStation:onFinalizePlacement()
	local v14_ = self.spec_sellingStation
	v14_.sellingStation:register(true)
	g_currentMission.storageSystem:addUnloadingStation(v14_.sellingStation, self)
	g_currentMission.economyManager:addSellingStation(v14_.sellingStation)
end

-- Local values: spec, sellingStationId
function PlaceableSellingStation:onReadStream(streamId, connection)
	local v18_ = self.spec_sellingStation
	local v19_ = NetworkUtil.readNodeObjectId(streamId)
	v18_.sellingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(v18_.sellingStation, v19_)
end

-- Local values: spec
function PlaceableSellingStation:onWriteStream(streamId, connection)
	local v23_ = self.spec_sellingStation
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v23_.sellingStation))
	v23_.sellingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, v23_.sellingStation)
end

function PlaceableSellingStation:getSellingStation()
	return self.spec_sellingStation.sellingStation
end

-- Local values: spec, foundNode, _, unloadTrigger
function PlaceableSellingStation:collectPickObjects(superFunc, node)
	local v28_ = self.spec_sellingStation
	local v29_ = false
	for _, v30_ in ipairs(v28_.sellingStation.unloadTriggers) do
		if node == v30_.exactFillRootNode then
			v29_ = true
			break
		end
	end
	if not v29_ then
		superFunc(self, node)
	end
end

-- Local values: spec
function PlaceableSellingStation:loadFromXMLFile(xmlFile, key)
	self.spec_sellingStation.sellingStation:loadFromXMLFile(xmlFile, key)
end

-- Local values: spec
function PlaceableSellingStation:saveToXMLFile(xmlFile, key, usedModNames)
	self.spec_sellingStation.sellingStation:saveToXMLFile(xmlFile, key, usedModNames)
end
