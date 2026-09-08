-- Local values: BuyHandToolData_mt
BuyHandToolData = {}
local BuyHandToolData_mt = Class(BuyHandToolData)

-- Upvalues: BuyHandToolData_mt
-- Local values: self
function BuyHandToolData.new(customMt)
	-- upvalues: (copy) BuyHandToolData_mt
	local v3_ = customMt or BuyHandToolData_mt
	local v4_ = setmetatable({}, v3_)
	v4_.storeItem = nil
	v4_.isFreeOfCharge = false
	v4_.ownerFarmId = AccessHandler.EVERYONE
	v4_.price = 0
	v4_.holder = nil
	return v4_
end

function BuyHandToolData:isValid()
	if self.storeItem == nil then
		return false
	else
		return (not GS_IS_CONSOLE_VERSION or fileExists(self.storeItem.xmlFilename)) and true or false
	end
end

function BuyHandToolData:setHolder(holder)
	self.holder = holder
end

function BuyHandToolData:setStoreItem(storeItem)
	self.storeItem = storeItem
end

function BuyHandToolData:setIsFreeOfCharge(isFreeOfCharge)
	self.isFreeOfCharge = isFreeOfCharge
end

function BuyHandToolData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end

function BuyHandToolData:setPrice(price)
	self.price = price
end

function BuyHandToolData:updatePrice()
	self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem)
end

-- Local values: xmlFilename
function BuyHandToolData:readStream(streamId, connection)
	local v19_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.storeItem = g_storeManager:getItemByXMLFilename(string.lower(v19_))
	self.isFreeOfCharge = streamReadBool(streamId)
	self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function BuyHandToolData:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))
	streamWriteBool(streamId, self.isFreeOfCharge)
	streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

-- Local values: data
function BuyHandToolData:buy(callback, callbackTarget, callbackArguments)
	local v26_ = HandToolLoadingData.new()
	v26_:setStoreItem(self.storeItem)
	v26_:setOwnerFarmId(self.ownerFarmId)
	v26_:setHolder(self.holder)
	v26_:load(self.onBought, self, {
		["callback"] = callback,
		["callbackTarget"] = callbackTarget,
		["callbackArguments"] = callbackArguments
	})
end

-- Local values: financeCategory
function BuyHandToolData:onBought(handTool, loadingState, arguments)
	if loadingState == HandToolLoadingState.OK and not self.isFreeOfCharge then
		local v31_ = MoneyType.getMoneyTypeByName(self.storeItem.financeCategory) or MoneyType.SHOP_HANDTOOL_BUY
		g_currentMission:addMoney(-self.price, self.ownerFarmId, v31_, true)
	end
	if arguments.callback ~= nil then
		arguments.callback(arguments.callbackTarget, handTool, loadingState, arguments.callbackArguments)
	end
end
