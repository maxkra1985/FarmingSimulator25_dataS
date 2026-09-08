-- Local values: BuyPlaceableData_mt
BuyPlaceableData = {}
local BuyPlaceableData_mt = Class(BuyPlaceableData)

-- Upvalues: BuyPlaceableData_mt
-- Local values: self
function BuyPlaceableData.new(customMt)
	-- upvalues: (copy) BuyPlaceableData_mt
	local v3_ = customMt or BuyPlaceableData_mt
	local v4_ = setmetatable({}, v3_)
	v4_.storeItem = nil
	v4_.isFreeOfCharge = false
	v4_.configurations = {}
	v4_.boughtConfigurations = {}
	v4_.configurationData = {}
	v4_.ownerFarmId = AccessHandler.EVERYONE
	v4_.price = 0
	v4_.displacementCosts = 0
	v4_.modifyTerrain = false
	v4_.realignToTerrain = true
	v4_.position = { 0, 0, 0 }
	v4_.rotation = { 0, 0, 0 }
	return v4_
end

function BuyPlaceableData:isValid()
	if self.storeItem == nil then
		return false
	else
		return (not GS_IS_CONSOLE_VERSION or fileExists(self.storeItem.xmlFilename)) and true or false
	end
end

function BuyPlaceableData:setStoreItem(storeItem)
	self.storeItem = storeItem
end

function BuyPlaceableData:setPosition(x, y, z)
	local v12_ = self.position
	local v13_ = self.position
	local v14_ = self.position
	v12_[1] = x
	v13_[2] = y
	v14_[3] = z
end

function BuyPlaceableData:setRotation(rx, ry, rz)
	local v19_ = self.rotation
	local v20_ = self.rotation
	local v21_ = self.rotation
	v19_[1] = rx
	v20_[2] = ry
	v21_[3] = rz
end

function BuyPlaceableData:setIsFreeOfCharge(isFreeOfCharge)
	self.isFreeOfCharge = isFreeOfCharge
end

-- Local values: configName, index
function BuyPlaceableData:setConfigurations(configurations, boughtConfigurations)
	self.configurations = configurations or self.configurations
	self.boughtConfigurations = boughtConfigurations or self.boughtConfigurations
	for v27_, v28_ in pairs(self.configurations) do
		if self.boughtConfigurations[v27_] == nil then
			self.boughtConfigurations[v27_] = {}
		end
		self.boughtConfigurations[v27_][v28_] = true
	end
end

function BuyPlaceableData:setConfigurationData(configurationData)
	self.configurationData = configurationData or self.configurationData
end

function BuyPlaceableData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end

function BuyPlaceableData:setPrice(price)
	self.price = price
end

function BuyPlaceableData:updatePrice()
	self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem, self.configurations, nil)
end

function BuyPlaceableData:setDisplacementCosts(displacementCosts)
	self.displacementCosts = displacementCosts
end

function BuyPlaceableData:setModifyTerrain(modifyTerrain)
	self.modifyTerrain = modifyTerrain
end

function BuyPlaceableData:setRealignToTerrainAfterLeveling(realignToTerrain)
	self.realignToTerrain = realignToTerrain
end

-- Local values: xmlFilename
function BuyPlaceableData:readStream(streamId, connection)
	local v45_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.storeItem = g_storeManager:getItemByXMLFilename(string.lower(v45_))
	self.position[1] = streamReadFloat32(streamId)
	self.position[2] = streamReadFloat32(streamId)
	self.position[3] = streamReadFloat32(streamId)
	self.rotation[1] = streamReadFloat32(streamId)
	self.rotation[2] = streamReadFloat32(streamId)
	self.rotation[3] = streamReadFloat32(streamId)
	local v46_, v47_, v48_ = ConfigurationUtil.readConfigurationsFromStream(g_placeableConfigurationManager, streamId, connection, v45_)
	self.configurations = v46_
	self.boughtConfigurations = v47_
	self.configurationData = v48_
	self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.isFreeOfCharge = streamReadBool(streamId)
	self.displacementCosts = streamReadInt32(streamId)
	self.modifyTerrain = streamReadBool(streamId)
	self.realignToTerrain = streamReadBool(streamId)
end

function BuyPlaceableData:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))
	streamWriteFloat32(streamId, self.position[1])
	streamWriteFloat32(streamId, self.position[2])
	streamWriteFloat32(streamId, self.position[3])
	streamWriteFloat32(streamId, self.rotation[1])
	streamWriteFloat32(streamId, self.rotation[2])
	streamWriteFloat32(streamId, self.rotation[3])
	ConfigurationUtil.writeConfigurationsToStream(g_placeableConfigurationManager, streamId, connection, self.storeItem.xmlFilename, self.configurations, self.boughtConfigurations, self.configurationData)
	streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteBool(streamId, self.isFreeOfCharge)
	streamWriteInt32(streamId, self.displacementCosts)
	streamWriteBool(streamId, self.modifyTerrain)
	streamWriteBool(streamId, self.realignToTerrain)
end

-- Local values: data
function BuyPlaceableData:buy(callback, callbackTarget, callbackArguments)
	local v56_ = PlaceableLoadingData.new()
	v56_:setStoreItem(self.storeItem)
	v56_:setConfigurations(self.configurations, self.boughtConfigurations)
	v56_:setConfigurationData(self.configurationData)
	v56_:setOwnerFarmId(self.ownerFarmId)
	v56_:setPosition(self.position[1], self.position[2], self.position[3])
	v56_:setRotation(self.rotation[1], self.rotation[2], self.rotation[3])
	v56_:load(self.onLoaded, self, {
		["callback"] = callback,
		["callbackTarget"] = callbackTarget,
		["callbackArguments"] = callbackArguments
	})
end

-- Local values: deformationCallback
function BuyPlaceableData:onLoaded(placeable, loadingState, arguments)
	if loadingState == PlaceableLoadingState.OK then
		local function v66_(p61_, p62_, _)
			-- upvalues: (copy) placeable, (copy) self, (copy) arguments, (copy) loadingState
			if p61_ == TerrainDeformation.STATE_SUCCESS then
				if p62_ > 0 and self.realignToTerrain then
					local v63_, v64_, v65_ = placeable:getPosition()
					placeable:setPose(nil, getTerrainHeightAtWorldPos(g_terrainNode, v63_, v64_, v65_), nil)
				end
				self:onBought(placeable, loadingState, arguments)
			else
				placeable:delete()
				self:onBought(nil, PlaceableLoadingState.DEFORMATION_FAILED, arguments)
			end
		end
		if self.modifyTerrain and placeable.applyDeformation ~= nil then
			placeable:applyDeformation(false, v66_)
		else
			v66_(TerrainDeformation.STATE_SUCCESS, 0, nil)
		end
	else
		self:onBought(placeable, loadingState, arguments)
		return
	end
end

-- Local values: totalCosts, financeCategory
function BuyPlaceableData:onBought(placeable, loadingState, arguments)
	if loadingState == PlaceableLoadingState.OK then
		if not self.isFreeOfCharge then
			local v71_ = self.price + self.displacementCosts
			local v72_ = MoneyType.getMoneyTypeByName(self.storeItem.financeCategory) or MoneyType.SHOP_PROPERTY_BUY
			g_currentMission:addMoney(-v71_, self.ownerFarmId, v72_, true, true)
		end
		placeable.undoTimer = g_time
		placeable:finalizePlacement()
		placeable:onBuy()
	end
	if arguments.callback ~= nil then
		arguments.callback(arguments.callbackTarget, placeable, loadingState, arguments.callbackArguments)
	end
end
