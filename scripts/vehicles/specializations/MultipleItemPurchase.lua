MultipleItemPurchase = {}
function MultipleItemPurchase.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("multipleItemPurchaseAmount", g_i18n:getText("configuration_buyableBaleAmount"), nil, VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("MultipleItemPurchase")
	v1_:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#filename", "Item filename")
	v1_:register(XMLValueType.BOOL, "vehicle.multipleItemPurchase#isVehicle", "Is Loading a vehicle (false=Bale)", false)
	v1_:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#fillType", "Bale fill type", "STRAW")
	v1_:register(XMLValueType.BOOL, "vehicle.multipleItemPurchase#baleIsWrapped", "Bale is wrapped", false)
	v1_:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#baleVariationId", "Bale variation identifier", "DEFAULT")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.multipleItemPurchase.offsets.offset(?)#offset", "Offset")
	v1_:register(XMLValueType.FLOAT, "vehicle.multipleItemPurchase.offsets.offset(?)#amount", "Amount of items to activate offset")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.multipleItemPurchase.itemPositions.itemPosition(?)#position", "Bale position")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.multipleItemPurchase.itemPositions.itemPosition(?)#rotation", "Bale rotation")
	v1_:setXMLSpecializationType()
end

function MultipleItemPurchase.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end

function MultipleItemPurchase.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadItemAtPosition", MultipleItemPurchase.loadItemAtPosition)
	SpecializationUtil.registerFunction(vehicleType, "onFinishLoadingVehicle", MultipleItemPurchase.onFinishLoadingVehicle)
end

function MultipleItemPurchase.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", MultipleItemPurchase.getTotalMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitCapacity", MultipleItemPurchase.getFillUnitCapacity)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setVisibility", MultipleItemPurchase.setVisibility)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", MultipleItemPurchase.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", MultipleItemPurchase.removeFromPhysics)
end

function MultipleItemPurchase.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", MultipleItemPurchase)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoadFinished", MultipleItemPurchase)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", MultipleItemPurchase)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MultipleItemPurchase)
end

-- Local values: spec, fillTypeName, positionOffset, i, baseKey, offset, amount, baseKey, position, rotation, _, component
function MultipleItemPurchase:onLoad(savegame)
	local v7_ = self.spec_multipleItemPurchase
	v7_.loadedBales = {}
	v7_.loadedVehicles = {}
	v7_.itemFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.multipleItemPurchase#filename"), self.baseDirectory)
	v7_.isVehicle = self.xmlFile:getValue("vehicle.multipleItemPurchase#isVehicle", false)
	local v8_ = self.xmlFile:getValue("vehicle.multipleItemPurchase#fillType", "STRAW")
	v7_.baleFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(v8_)
	v7_.baleIsWrapped = self.xmlFile:getValue("vehicle.multipleItemPurchase#baleIsWrapped", false)
	v7_.baleVariationId = self.xmlFile:getValue("vehicle.multipleItemPurchase#baleVariationId", "DEFAULT")
	local v9_ = 0
	local v10_ = { 0, 0, 0 }
	while true do
		local v11_ = string.format("vehicle.multipleItemPurchase.offsets.offset(%d)", v9_)
		if not self.xmlFile:hasProperty(v11_) then
			break
		end
		local v12_ = self.xmlFile:getValue(v11_ .. "#offset", nil, true)
		if self.xmlFile:getValue(v11_ .. "#amount") > self.configurations.multipleItemPurchaseAmount then
			v12_ = v10_
		end
		v9_ = v9_ + 1
		v10_ = v12_
	end
	v7_.positions = {}
	local v13_ = 0
	while true do
		local v14_ = string.format("vehicle.multipleItemPurchase.itemPositions.itemPosition(%d)", v13_)
		if not self.xmlFile:hasProperty(v14_) then
			break
		end
		local v15_ = self.xmlFile:getValue(v14_ .. "#position", nil, true)
		local v16_ = self.xmlFile:getValue(v14_ .. "#rotation", nil, true)
		if v15_ ~= nil and v16_ ~= nil then
			if v10_ ~= nil then
				v15_[1] = v15_[1] + v10_[1]
				v15_[2] = v15_[2] + v10_[2]
				v15_[3] = v15_[3] + v10_[3]
			end
			local v17_ = v7_.positions
			table.insert(v17_, {
				["position"] = v15_,
				["rotation"] = v16_
			})
		end
		v13_ = v13_ + 1
	end
	for _, v18_ in ipairs(self.components) do
		local v19_ = setCollisionFilterMask
		local v20_ = v18_.node
		local v21_ = getCollisionFilterMask(v18_.node)
		local v22_ = CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT
		v19_(v20_, (bit32.bxor(v21_, v22_)))
	end
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdate", MultipleItemPurchase)
	end
end

-- Local values: spec, j, position
function MultipleItemPurchase:onPreLoadFinished(savegame)
	local v24_ = self.spec_multipleItemPurchase
	for v25_, v26_ in ipairs(v24_.positions) do
		if v25_ <= self.configurations.multipleItemPurchaseAmount then
			self:loadItemAtPosition(v26_)
		end
	end
end

-- Local values: spec, x, y, z, rx, ry, rz, baleObject, color, loadingTask, data, configurations, storeItem, configName, configItems
function MultipleItemPurchase:loadItemAtPosition(position)
	local v29_ = self.spec_multipleItemPurchase
	if self.isServer or self.propertyState == VehiclePropertyState.SHOP_CONFIG then
		local v30_ = localToWorld
		local v31_ = self.components[1].node
		local v32_ = position.position
		local v33_, v34_, v35_ = v30_(v31_, unpack(v32_))
		local v36_ = localRotationToWorld
		local v37_ = self.components[1].node
		local v38_ = position.rotation
		local v39_, v40_, v41_ = v36_(v37_, unpack(v38_))
		if not v29_.isVehicle then
			local v42_ = Bale.new(self.isServer, self.isClient)
			if v42_:loadFromConfigXML(v29_.itemFilename, v33_, v34_, v35_, v39_, v40_, v41_) then
				v42_:setFillType(v29_.baleFillTypeIndex, true)
				v42_:setOwnerFarmId(self:getActiveFarm(), true)
				v42_:setVariationId(v29_.baleVariationId)
				if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
					v42_:register()
				end
				if v29_.baleIsWrapped then
					v42_:setWrappingState(1)
					if self.configurations.baseColor ~= nil then
						local v43_ = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor)
						v42_:setColor(unpack(v43_))
					end
				end
				v42_:removeFromPhysics()
				local v44_ = v29_.loadedBales
				table.insert(v44_, v42_)
			else
				Logging.error("Failed to load multi purchase item \'%s\'", v29_.itemFilename)
			end
		end
		local v45_ = self:createLoadingTask(self)
		local v46_ = VehicleLoadingData.new()
		v46_:setFilename(v29_.itemFilename)
		v46_:setPosition(v33_, v34_, v35_)
		v46_:setRotation(v39_, v40_, v41_)
		v46_:setPropertyState(self.propertyState)
		v46_:setIsRegistered(self.propertyState ~= VehiclePropertyState.SHOP_CONFIG)
		v46_:setForceServer(self.propertyState == VehiclePropertyState.SHOP_CONFIG)
		v46_:setOwnerFarmId(self:getActiveFarm())
		local v47_ = {}
		local v48_ = g_storeManager:getItemByXMLFilename(v29_.itemFilename)
		if v48_ ~= nil and v48_.configurations ~= nil then
			for v49_, _ in pairs(v48_.configurations) do
				if self.configurations[v49_] ~= nil then
					v47_[v49_] = self.configurations[v49_]
				end
			end
		end
		v46_:setConfigurations(v47_)
		v46_:load(self.onFinishLoadingVehicle, self, v45_)
	end
end

-- Local values: _, vehicle, spec, _, vehicle
function MultipleItemPurchase:onFinishLoadingVehicle(vehicles, vehicleLoadState, loadingTask)
	if self.isDeleted or self.isDeleting then
		if vehicleLoadState == VehicleLoadingState.OK then
			for _, v54_ in ipairs(vehicles) do
				v54_:delete()
			end
		end
	else
		local v55_ = self.spec_multipleItemPurchase
		if vehicleLoadState == VehicleLoadingState.OK then
			for _, v56_ in ipairs(vehicles) do
				v56_:removeFromPhysics()
				v56_:setVisibility(false)
				local v57_ = v55_.loadedVehicles
				table.insert(v57_, v56_)
			end
		else
			Logging.error("Failed to load multi purchase item \'%s\'", v55_.itemFilename)
		end
		if loadingTask ~= nil then
			self:finishLoadingTask(loadingTask)
		end
	end
end

-- Local values: spec, _, bale, _, vehicle
function MultipleItemPurchase:onDelete()
	if self.propertyState == VehiclePropertyState.SHOP_CONFIG or (g_iconGenerator ~= nil or g_currentMission.vehicleSystem.debugVehiclesToBeLoaded ~= nil) then
		local v59_ = self.spec_multipleItemPurchase
		if v59_.loadedBales ~= nil then
			for _, v60_ in ipairs(v59_.loadedBales) do
				v60_:delete()
			end
			v59_.loadedBales = {}
			for _, v61_ in ipairs(v59_.loadedVehicles) do
				v61_:delete()
			end
			v59_.loadedVehicles = {}
		end
	end
end

function MultipleItemPurchase:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
		self:delete()
	end
end

-- Local values: mass, spec, _, bale, _, vehicle
function MultipleItemPurchase:getTotalMass(superFunc, onlyGivenVehicle)
	if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
		return 0
	end
	local v64_ = self.spec_multipleItemPurchase
	local v65_ = 0
	for _, v66_ in ipairs(v64_.loadedBales) do
		v65_ = v65_ + v66_:getMass()
	end
	for _, v67_ in ipairs(v64_.loadedVehicles) do
		v65_ = v65_ + v67_:getTotalMass()
	end
	return v65_
end

-- Local values: fillLevel, spec, _, bale, _, vehicle
function MultipleItemPurchase:getFillUnitCapacity(superFunc, fillUnitIndex)
	if self.propertyState ~= VehiclePropertyState.SHOP_CONFIG then
		return 0
	end
	local v69_ = self.spec_multipleItemPurchase
	local v70_ = 0
	for _, v71_ in ipairs(v69_.loadedBales) do
		v70_ = v70_ + v71_:getFillLevel()
	end
	for _, v72_ in ipairs(v69_.loadedVehicles) do
		if v72_.getFillUnitCapacity ~= nil then
			v70_ = v70_ + v72_:getFillUnitCapacity(1)
		end
	end
	return v70_
end

-- Local values: spec, _, vehicle
function MultipleItemPurchase:setVisibility(superFunc, state)
	local v76_ = self.spec_multipleItemPurchase
	for _, v77_ in ipairs(v76_.loadedVehicles) do
		v77_:setVisibility(state)
	end
	superFunc(self, state)
end

-- Local values: spec, _, bale, _, vehicle
function MultipleItemPurchase:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v80_ = self.spec_multipleItemPurchase
	for _, v81_ in ipairs(v80_.loadedBales) do
		v81_:addToPhysics()
	end
	for _, v82_ in ipairs(v80_.loadedVehicles) do
		v82_:addToPhysics()
	end
	return true
end

-- Local values: spec, _, bale, _, vehicle
function MultipleItemPurchase:removeFromPhysics(superFunc)
	local v85_ = self.spec_multipleItemPurchase
	for _, v86_ in ipairs(v85_.loadedBales) do
		v86_:removeFromPhysics()
	end
	for _, v87_ in ipairs(v85_.loadedVehicles) do
		v87_:removeFromPhysics()
	end
	return superFunc(self)
end
