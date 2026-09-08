HandToolHolders = {}

function HandToolHolders.prerequisitesPresent(specializations)
	return true
end
function HandToolHolders.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("handToolHolder", g_i18n:getText("shop_configuration"), "handToolHolders", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("HandToolHolders")
	HandToolHolder.registerXMLPaths(v1_, "vehicle.handToolHolders")
	HandToolHolder.registerXMLPaths(v1_, "vehicle.handToolHolders.handToolHolderConfigurations.handToolHolderConfiguration(?)")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	HandToolHolder.registerSavegameXMLPaths(Vehicle.xmlSchemaSavegame, "vehicles.vehicle(?).handToolHolders.handToolHolder(?)")
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).handToolHolders.handToolHolder(?)#index", "Index of the holder", nil, true)
end

function HandToolHolders.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onHandToolStoredInHolder")
	SpecializationUtil.registerEvent(vehicleType, "onHandToolTakenFromHolder")
end

function HandToolHolders.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onHandToolHolderFinished", HandToolHolders.onHandToolHolderFinished)
end

function HandToolHolders.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setOwnerFarmId", HandToolHolders.setOwnerFarmId)
end

function HandToolHolders.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", HandToolHolders)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", HandToolHolders)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", HandToolHolders)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", HandToolHolders)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", HandToolHolders)
	SpecializationUtil.registerEventListener(vehicleType, "onRegistered", HandToolHolders)
end

-- Local values: spec, configurationId, configKey, name, brand, holderName, nodeIndex, key, handToolHolder, loadingTask, args
function HandToolHolders:onLoad(savegame)
	local v9_ = self.spec_handToolHolders
	local v10_ = self.configurations.handToolHolder or 1
	local v11_ = string.format("vehicle.handToolHolders.handToolHolderConfigurations.handToolHolderConfiguration(%d)", v10_ - 1)
	local v12_ = not self.xmlFile:hasProperty(v11_) and "vehicle.handToolHolders" or v11_
	v9_.handToolHolders = {}
	local v13_ = self:getName()
	local v14_ = g_brandManager:getBrandByIndex(self:getBrand())
	if v14_ ~= nil then
		v13_ = v14_.title .. " " .. v13_
	end
	local v15_ = string.format(g_i18n:getText("ui_handToolHolderVehicle"), v13_)
	for _, v16_ in self.xmlFile:iterator(v12_ .. ".handToolHolder") do
		local v17_ = HandToolHolder.new(self, self.isServer, self.isClient)
		v17_:setHolderName(v15_)
		local v18_ = {
			["loadingTask"] = self:createLoadingTask(self),
			["xmlFile"] = self.xmlFile,
			["key"] = v16_,
			["savegame"] = savegame
		}
		v17_:load(self.xmlFile, v16_, self.onHandToolHolderFinished, self, v18_, self.components, self.i3dMappings, self.baseDirectory, self.customEnvironment)
	end
end

-- Local values: spec, handToolIndex, savegame, _, key, index
function HandToolHolders:onHandToolHolderFinished(handToolHolder, args)
	if handToolHolder ~= nil then
		local v22_ = self.spec_handToolHolders
		handToolHolder:setOwnerFarmId(self:getOwnerFarmId())
		handToolHolder:setStoreCallback(function(p23_)
			-- upvalues: (copy) self, (copy) handToolHolder
			SpecializationUtil.raiseEvent(self, "onHandToolStoredInHolder", p23_, handToolHolder)
		end)
		handToolHolder:setPickupCallback(function(p24_)
			-- upvalues: (copy) self, (copy) handToolHolder
			SpecializationUtil.raiseEvent(self, "onHandToolTakenFromHolder", p24_, handToolHolder)
		end)
		local v25_ = v22_.handToolHolders
		table.insert(v25_, handToolHolder)
		local v26_ = #v22_.handToolHolders
		local v27_ = args.savegame
		if v27_ ~= nil and not v27_.resetVehicles then
			for _, v28_ in v27_.xmlFile:iterator(v27_.key .. ".handToolHolders.handToolHolder") do
				if v27_.xmlFile:getValue(v28_ .. "#index") == v26_ then
					handToolHolder:loadFromXMLFile(v27_.xmlFile, v28_)
					break
				end
			end
		end
	end
	self:finishLoadingTask(args.loadingTask)
end

-- Local values: spec, _, handToolHolder
function HandToolHolders:onDelete()
	local v30_ = self.spec_handToolHolders
	if v30_.handToolHolders ~= nil then
		for _, v31_ in ipairs(v30_.handToolHolders) do
			v31_:delete()
		end
		table.clear(v30_.handToolHolders)
	end
end

-- Local values: spec, k, handToolHolder, holderKey
function HandToolHolders:saveToXMLFile(xmlFile, key, usedModNames)
	local v35_ = self.spec_handToolHolders
	if v35_.handToolHolders ~= nil then
		for v36_, v37_ in ipairs(v35_.handToolHolders) do
			local v38_ = string.format("%s.handToolHolder(%d)", key, v36_ - 1)
			xmlFile:setValue(v38_ .. "#index", v36_)
			v37_:saveToXMLFile(xmlFile, v38_)
		end
	end
end

-- Local values: spec, _, handToolHolder
function HandToolHolders:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v42_ = self.spec_handToolHolders
		if v42_.handToolHolders ~= nil then
			for _, v43_ in ipairs(v42_.handToolHolders) do
				NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v43_))
				v43_:writeStream(streamId, connection)
				g_server:registerObjectInStream(connection, v43_)
			end
		end
	end
end

-- Local values: spec, _, handToolHolder, handToolHolderId
function HandToolHolders:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local v47_ = self.spec_handToolHolders
		if v47_.handToolHolders ~= nil then
			for _, v48_ in ipairs(v47_.handToolHolders) do
				local v49_ = NetworkUtil.readNodeObjectId(streamId)
				v48_:readStream(streamId, connection)
				g_client:finishRegisterObject(v48_, v49_)
			end
		end
	end
end

-- Local values: spec, _, handToolHolder
function HandToolHolders:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	superFunc(self, ownerFarmId, noEventSend)
	local v54_ = self.spec_handToolHolders
	if v54_.handToolHolders ~= nil then
		for _, v55_ in ipairs(v54_.handToolHolders) do
			v55_:setOwnerFarmId(ownerFarmId, true)
		end
	end
end

-- Local values: spec, _, handToolHolder
function HandToolHolders:onRegistered(alreadySent)
	local v57_ = self.spec_handToolHolders
	if v57_.handToolHolders ~= nil then
		for _, v58_ in ipairs(v57_.handToolHolders) do
			v58_:register(true)
		end
	end
end
