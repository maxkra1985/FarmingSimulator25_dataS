PlaceableWashingStation = {}

function PlaceableWashingStation.prerequisitesPresent(specializations)
	return true
end

function PlaceableWashingStation.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableWashingStation.setOwnerFarmId)
end

function PlaceableWashingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWashingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWashingStation)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWashingStation)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableWashingStation)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableWashingStation)
end

function PlaceableWashingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("WashingStation")
	WashingStation.registerXMLPaths(schema, basePath .. ".washingStation.station(?)")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableWashingStation:onLoad(savegame)
	local v_u_6_ = self.spec_washingStation
	v_u_6_.washingStations = {}
	self.xmlFile:iterate("placeable.washingStation.station", function(_, p7_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v8_ = WashingStation.new(self.isServer, self.isClient)
		if v8_:load(self.components, self.xmlFile, p7_, self.customEnvironment, self.i3dMappings, self.rootNode) then
			local v9_ = v_u_6_.washingStations
			table.insert(v9_, v8_)
		else
			v8_:delete()
		end
	end)
end

-- Local values: spec, _, washingStation
function PlaceableWashingStation:onDelete()
	local v11_ = self.spec_washingStation
	if v11_.washingStations ~= nil then
		for _, v12_ in ipairs(v11_.washingStations) do
			v12_:delete()
		end
	end
end

-- Local values: spec, _, washingStation
function PlaceableWashingStation:onFinalizePlacement()
	local v14_ = self.spec_washingStation
	if v14_.washingStations ~= nil then
		for _, v15_ in ipairs(v14_.washingStations) do
			v15_:setOwnerFarmId(self:getOwnerFarmId(), true)
			v15_:register(true)
		end
	end
end

-- Local values: spec, _, washingStation, washingStationId
function PlaceableWashingStation:onReadStream(streamId, connection)
	local v19_ = self.spec_washingStation
	if v19_.washingStations ~= nil then
		for _, v20_ in ipairs(v19_.washingStations) do
			local v21_ = NetworkUtil.readNodeObjectId(streamId)
			v20_:readStream(streamId, connection)
			g_client:finishRegisterObject(v20_, v21_)
		end
	end
end

-- Local values: spec, _, washingStation
function PlaceableWashingStation:onWriteStream(streamId, connection)
	local v25_ = self.spec_washingStation
	if v25_.washingStations ~= nil then
		for _, v26_ in ipairs(v25_.washingStations) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v26_))
			v26_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v26_)
		end
	end
end

-- Local values: spec, _, washingStation
function PlaceableWashingStation:setOwnerFarmId(superFunc, farmId, noEventSend)
	local v31_ = self.spec_washingStation
	superFunc(self, farmId, noEventSend)
	if v31_.washingStations ~= nil then
		for _, v32_ in ipairs(v31_.washingStations) do
			v32_:setOwnerFarmId(farmId, true)
		end
	end
end
