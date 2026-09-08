PlaceableBuyingStation = {}

function PlaceableBuyingStation.prerequisitesPresent(specializations)
	return true
end

function PlaceableBuyingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getBuyingStation", PlaceableBuyingStation.getBuyingStation)
end

function PlaceableBuyingStation.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableBuyingStation.collectPickObjects)
end

function PlaceableBuyingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBuyingStation)
end

function PlaceableBuyingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("BuyingStation")
	BuyingStation.registerXMLPaths(schema, basePath .. ".buyingStation")
	schema:setXMLSpecializationType()
end
function PlaceableBuyingStation.initSpecialization()
	g_storeManager:addSpecType("buyingStationFillTypes", "shopListAttributeIconOutput", BuyingStation.loadSpecValueFillTypes, BuyingStation.getSpecValueFillTypes, StoreSpecies.PLACEABLE)
end

-- Local values: spec, buyingStation
function PlaceableBuyingStation:onLoad(savegame)
	local v7_ = self.spec_buyingStation
	local v8_ = BuyingStation.new(self.isServer, self.isClient)
	if v8_:load(self.components, self.xmlFile, "placeable.buyingStation", self.customEnvironment, self.i3dMappings) then
		v7_.buyingStation = v8_
		v7_.buyingStation.owningPlaceable = self
		g_currentMission.storageSystem:addLoadingStation(v7_.buyingStation, v7_.buyingStation.owningPlaceable)
	else
		Logging.xmlError(self.xmlFile, "Could not load buying station")
		v8_:delete()
	end
end

-- Local values: spec
function PlaceableBuyingStation:onDelete()
	local v10_ = self.spec_buyingStation
	if v10_.buyingStation ~= nil then
		g_currentMission.storageSystem:removeLoadingStation(v10_.buyingStation, v10_.buyingStation.owningPlaceable)
		v10_.buyingStation:delete()
	end
end

-- Local values: spec
function PlaceableBuyingStation:onFinalizePlacement()
	local v12_ = self.spec_buyingStation
	if v12_.buyingStation ~= nil then
		v12_.buyingStation:register(true)
	end
end

-- Local values: spec, buyingStationId
function PlaceableBuyingStation:onReadStream(streamId, connection)
	local v16_ = self.spec_buyingStation
	if v16_.buyingStation ~= nil then
		local v17_ = NetworkUtil.readNodeObjectId(streamId)
		v16_.buyingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(v16_.buyingStation, v17_)
	end
end

-- Local values: spec
function PlaceableBuyingStation:onWriteStream(streamId, connection)
	local v21_ = self.spec_buyingStation
	if v21_.buyingStation ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v21_.buyingStation))
		v21_.buyingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, v21_.buyingStation)
	end
end

-- Local values: spec, _, loadTrigger
function PlaceableBuyingStation:collectPickObjects(superFunc, node)
	local v25_ = self.spec_buyingStation
	if v25_.buyingStation ~= nil then
		for _, v26_ in ipairs(v25_.buyingStation.loadTriggers) do
			if node == v26_.triggerNode then
				return
			end
		end
	end
	superFunc(self, node)
end

function PlaceableBuyingStation:getBuyingStation()
	return self.spec_buyingStation.buyingStation
end
