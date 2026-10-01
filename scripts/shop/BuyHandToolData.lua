BuyHandToolData = {}
local BuyHandToolData_mt = Class(BuyHandToolData)
function BuyHandToolData.new(customMt)
	local self = setmetatable({}, customMt or BuyHandToolData_mt)
	self.storeItem = nil
	self.isFreeOfCharge = false
	self.ownerFarmId = AccessHandler.EVERYONE
	self.price = 0
	self.holder = nil
	return self
end
function BuyHandToolData:isValid()
	if self.storeItem == nil then
		return false
	elseif GS_IS_CONSOLE_VERSION and not fileExists(self.storeItem.xmlFilename) then
		return false
	else
		return true
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
function BuyHandToolData:readStream(streamId, connection)
	local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.storeItem = g_storeManager:getItemByXMLFilename(string.lower(xmlFilename))
	self.isFreeOfCharge = streamReadBool(streamId)
	self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function BuyHandToolData:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))
	streamWriteBool(streamId, self.isFreeOfCharge)
	streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end
function BuyHandToolData:buy(callback, callbackTarget, callbackArguments)
	local data = HandToolLoadingData.new()
	data:setStoreItem(self.storeItem)
	data:setOwnerFarmId(self.ownerFarmId)
	data:setHolder(self.holder)
	data:load(self.onBought, self, { callback = callback, callbackTarget = callbackTarget, callbackArguments = callbackArguments })
end
function BuyHandToolData:onBought(handTool, loadingState, arguments)
	if loadingState == HandToolLoadingState.OK and not self.isFreeOfCharge then
		local financeCategory = MoneyType.getMoneyTypeByName(self.storeItem.financeCategory) or MoneyType.SHOP_HANDTOOL_BUY
		g_currentMission:addMoney(-self.price, self.ownerFarmId, financeCategory, true)
	end
	if arguments.callback ~= nil then
		arguments.callback(arguments.callbackTarget, handTool, loadingState, arguments.callbackArguments)
	end
end
