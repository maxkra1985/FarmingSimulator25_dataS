PlaceableVehicle = {}

function PlaceableVehicle.prerequisitesPresent(specializations)
	return true
end

function PlaceableVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onFinishLoadingVehicle", PlaceableVehicle.onFinishLoadingVehicle)
end

function PlaceableVehicle.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableVehicle.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "register", PlaceableVehicle.register)
end

function PlaceableVehicle.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableVehicle)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableVehicle)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableVehicle)
end

function PlaceableVehicle.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("PlaceableVehicle")
	schema:register(XMLValueType.FILENAME, "placeable.placeableVehicle.vehicle(?)#xmlFilename", "Path to vehicle xml file")
	schema:register(XMLValueType.NODE_INDEX, "placeable.placeableVehicle.vehicle(?)#linkNode", "Link node")
	schema:setXMLSpecializationType()
end

-- Local values: spec, _, vehicleKey, vehicleData, x, y, z, rx, ry, rz, data
function PlaceableVehicle:onLoad(savegame)
	local v6_ = self.spec_vehicle
	if self.isServer or self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		v6_.vehicles = {}
		v6_.loadedVehicles = {}
		for _, v7_ in self.xmlFile:iterator("placeable.placeableVehicle.vehicle") do
			local v8_ = {
				["filename"] = self.xmlFile:getValue(v7_ .. "#xmlFilename", nil, self.baseDirectory),
				["linkNode"] = self.xmlFile:getValue(v7_ .. "#linkNode", nil, self.components, self.i3dMappings)
			}
			if v8_.filename ~= nil and v8_.linkNode ~= nil then
				local v9_ = v6_.vehicles
				table.insert(v9_, v8_)
				local v10_, v11_, v12_ = getWorldTranslation(v8_.linkNode)
				local v13_, v14_, v15_ = getWorldRotation(v8_.linkNode)
				v8_.loadingTask = self:createLoadingTask(self)
				local v16_ = VehicleLoadingData.new()
				v16_:setFilename(v8_.filename)
				v16_:setPosition(v10_, v11_, v12_)
				v16_:setRotation(v13_, v14_, v15_)
				if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
					v16_:setPropertyState(VehiclePropertyState.SHOP_CONFIG)
				else
					v16_:setPropertyState(VehiclePropertyState.OWNED)
				end
				v16_:setIsRegistered(false)
				v16_:load(self.onFinishLoadingVehicle, self, v8_)
			end
		end
	end
end

-- Local values: _, vehicle, spec, _, vehicle, _, component, x, y, z, rx, ry, rz
function PlaceableVehicle:onFinishLoadingVehicle(vehicles, vehicleLoadState, vehicleData)
	if self:getIsBeingDeleted() then
		if vehicleLoadState == VehicleLoadingState.OK then
			for _, v21_ in ipairs(vehicles) do
				v21_:delete()
			end
		end
	else
		local v22_ = self.spec_vehicle
		if vehicleLoadState == VehicleLoadingState.OK then
			for _, v23_ in ipairs(vehicles) do
				v23_:removeFromPhysics()
				v23_:setOwnerFarmId(self.ownerFarmId)
				for _, v24_ in ipairs(v23_.components) do
					local v25_, v26_, v27_ = getWorldTranslation(v24_.node)
					local v28_, v29_, v30_ = getWorldRotation(v24_.node)
					link(vehicleData.linkNode, v24_.node)
					setWorldTranslation(v24_.node, v25_, v26_, v27_)
					setWorldRotation(v24_.node, v28_, v29_, v30_)
				end
				local v31_ = v22_.loadedVehicles
				table.insert(v31_, v23_)
			end
		else
			Logging.error("Failed to load placeable vehicle \'%s\'", vehicleData.filename)
		end
	end
	if vehicleData.loadingTask ~= nil then
		self:finishLoadingTask(vehicleData.loadingTask)
	end
end

-- Local values: spec, _, vehicle, _, component, x, y, z, rx, ry, rz
function PlaceableVehicle:onFinalizePlacement()
	if self.isServer and g_iconGenerator == nil then
		local v33_ = self.spec_vehicle
		if v33_.loadedVehicles ~= nil then
			for _, v34_ in ipairs(v33_.loadedVehicles) do
				for _, v35_ in ipairs(v34_.components) do
					local v36_, v37_, v38_ = getWorldTranslation(v35_.node)
					local v39_, v40_, v41_ = getWorldRotation(v35_.node)
					link(getRootNode(), v35_.node)
					setWorldTranslation(v35_.node, v36_, v37_, v38_)
					setWorldRotation(v35_.node, v39_, v40_, v41_)
				end
				v34_:addToPhysics()
				v34_:register()
			end
			v33_.loadedVehicles = nil
		end
	end
end

-- Local values: spec, _, vehicle
function PlaceableVehicle:onDelete()
	local v43_ = self.spec_vehicle
	if v43_.loadedVehicles ~= nil then
		for _, v44_ in ipairs(v43_.loadedVehicles) do
			v44_:delete(true)
		end
	end
end

function PlaceableVehicle:register(alreadySent)
	if self.propertyState ~= PlaceablePropertyState.CONSTRUCTION_PREVIEW then
		self:delete()
	end
end

-- Local values: spec, _, vehicleData
function PlaceableVehicle:collectPickObjects(superFunc, node)
	local v49_ = self.spec_vehicle
	if v49_.vehicles ~= nil then
		for _, v50_ in ipairs(v49_.vehicles) do
			if node == v50_.linkNode then
				return
			end
		end
	end
	superFunc(self, node)
end
