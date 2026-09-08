-- Local values: AnimalScreenDealer_mt
AnimalScreenDealer = {}
local AnimalScreenDealer_mt = Class(AnimalScreenDealer, AnimalScreenBase)

-- Upvalues: AnimalScreenDealer_mt
-- Local values: self
function AnimalScreenDealer.new(customMt)
	-- upvalues: (copy) AnimalScreenDealer_mt
	local v3_ = AnimalScreenBase.new(customMt or AnimalScreenDealer_mt)
	v3_.husbandries = {}
	v3_.targetHusbandries = {}
	v3_.husbandry = nil
	v3_.sourceAnimalTypes = {}
	v3_.targetAnimalTypes = {}
	v3_.sourceActionText = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.BUY)
	v3_.targetActionText = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.SELL)
	v3_.sourceTitle = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.DEALER)
	return v3_
end

-- Local values: husbandries, _, husbandry, animalTypeIndex
function AnimalScreenDealer:initItems()
	AnimalScreenDealer:superClass().initItems(self)
	self.husbandries = {}
	self.targetHusbandries = {}
	self.targetAnimalTypes = {}
	local v5_ = g_currentMission.husbandrySystem:getPlaceablesByFarm()
	for _, v6_ in pairs(v5_) do
		local v7_ = v6_:getAnimalTypeIndex()
		if self.husbandries[v7_] == nil then
			self.husbandries[v7_] = {}
		end
		if v6_:getNumOfAnimals() > 0 then
			local v8_ = self.targetAnimalTypes
			local v9_ = g_currentMission.animalSystem
			table.insert(v8_, v9_:getTypeByIndex(v7_))
			local v10_ = self.targetHusbandries
			table.insert(v10_, v6_)
		end
		local v11_ = self.husbandries[v7_]
		table.insert(v11_, v6_)
	end
	table.sort(self.targetAnimalTypes, function(p12_, p13_)
		return p12_.typeIndex < p13_.typeIndex
	end)
	table.sort(self.targetHusbandries, function(p14_, p15_)
		return p14_:getAnimalTypeIndex() < p15_:getAnimalTypeIndex()
	end)
end

-- Local values: animalTypeIndex, animalType, _, subTypeIndex, subType, _, visual, item
function AnimalScreenDealer:initSourceItems()
	self.sourceItems = {}
	self.sourceAnimalTypes = g_currentMission.animalSystem:getTypes()
	for v17_, v18_ in pairs(self.sourceAnimalTypes) do
		for _, v19_ in ipairs(v18_.subTypes) do
			local v20_ = g_currentMission.animalSystem:getSubTypeByIndex(v19_)
			for _, v21_ in ipairs(v20_.visuals) do
				if v21_.store.canBeBought then
					local v22_ = AnimalItemNew.new(v20_.subTypeIndex, v21_.minAge)
					if self.sourceItems[v17_] == nil then
						self.sourceItems[v17_] = {}
					end
					local v23_ = self.sourceItems[v17_]
					table.insert(v23_, v22_)
				end
			end
		end
	end
end

function AnimalScreenDealer:getSourceAnimalTypes(isBuying)
	if isBuying then
		return self.sourceAnimalTypes
	else
		return self.targetAnimalTypes
	end
end

-- Local values: clusters, _, cluster, item
function AnimalScreenDealer:initTargetItems()
	self.targetItems = {}
	if self.husbandry ~= nil then
		local v27_ = self.husbandry:getClusters()
		if v27_ ~= nil then
			for _, v28_ in ipairs(v27_) do
				local v29_ = AnimalItemStock.new(v28_)
				local v30_ = self.targetItems
				table.insert(v30_, v29_)
			end
		end
	end
end

-- Local values: name, used, total
function AnimalScreenDealer:getTargetName()
	local v32_ = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.FARM)
	local v33_ = self.husbandry:getNumOfAnimals()
	local v34_ = self.husbandry:getMaxNumOfAnimals()
	return string.format("%s (%d / %d)", v32_, v33_, v34_)
end

-- Local values: item, subTypeIndex, age, singlePrice, transportFee, buyPrice, errorCode, data, text
function AnimalScreenDealer:applySource(animalTypeIndex, itemIndex, numItems)
	local v39_ = self.sourceItems[animalTypeIndex][itemIndex]
	local v40_ = v39_:getSubTypeIndex()
	local v41_ = v39_:getAge()
	local v42_ = -v39_:getPrice()
	local v43_ = -v39_:getTranportationFee(numItems)
	local v44_ = v42_ * numItems
	local v45_ = AnimalBuyEvent.validate(self.husbandry, v40_, v41_, numItems, v44_, v43_, self.husbandry:getOwnerFarmId())
	if v45_ ~= nil then
		local v46_ = AnimalScreenDealer.BUY_ERROR_CODE_MAPPING[v45_]
		self.errorCallback(g_i18n:getText(v46_.text))
		return false
	end
	local v47_ = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.BUYING)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, v47_)
	g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.husbandry, v40_, v41_, numItems, v44_, v43_))
	return true
end

-- Local values: data
function AnimalScreenDealer:onAnimalBought(errorCode)
	g_messageCenter:unsubscribe(AnimalBuyEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v50_ = AnimalScreenDealer.BUY_ERROR_CODE_MAPPING[errorCode]
	self.sourceActionFinished(v50_.isWarning, g_i18n:getText(v50_.text))
end

-- Local values: item, singlePrice, feePrice, sellPrice, clusterId, errorCode, data, text
function AnimalScreenDealer:applyTarget(animalTypeIndex, itemIndex, numItems)
	local v54_ = self.targetItems[itemIndex]
	local v55_ = v54_:getPrice()
	local v56_ = -v54_:getTranportationFee(numItems)
	local v57_ = v55_ * numItems
	local v58_ = v54_:getClusterId()
	local v59_ = AnimalSellEvent.validate(self.husbandry, v58_, numItems, v57_, v56_)
	if v59_ ~= nil then
		local v60_ = AnimalScreenDealer.SELL_ERROR_CODE_MAPPING[v59_]
		self.errorCallback(g_i18n:getText(v60_.text))
		return false
	end
	local v61_ = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.SELLING)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, v61_)
	g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
	g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.husbandry, v58_, numItems, v57_, v56_))
	return true
end

-- Local values: data
function AnimalScreenDealer:onAnimalSold(errorCode)
	g_messageCenter:unsubscribe(AnimalSellEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v64_ = AnimalScreenDealer.SELL_ERROR_CODE_MAPPING[errorCode]
	self.targetActionFinished(v64_.isWarning, g_i18n:getText(v64_.text))
end

-- Local values: item, singlePrice, transportFee, buyPrice
function AnimalScreenDealer:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	local v69_ = self.sourceItems[animalTypeIndex][itemIndex]
	local v70_ = v69_:getPrice()
	local v71_ = v69_:getTranportationFee(numItems)
	local v72_ = v70_ * numItems
	return true, v72_, v71_, v72_ + v71_
end

-- Local values: item, singlePrice, transportFee, sellPrice
function AnimalScreenDealer:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	local v76_ = self.targetItems[itemIndex]
	local v77_ = v76_:getPrice()
	local v78_ = -v76_:getTranportationFee(numItems)
	local v79_ = v77_ * numItems
	return true, v79_, v78_, v79_ + v78_
end

-- Local values: _, _, _, totalPrice, text, price, item
function AnimalScreenDealer:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
	local _, _, _, v84_ = self:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	local v85_ = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_BUY)
	if numItems == 1 then
		v85_ = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_BUY_SINGULAR)
	end
	local v86_ = g_i18n:formatMoney(math.abs(v84_), 0, true, true)
	local v87_ = self.sourceItems[animalTypeIndex][itemIndex]
	return string.namedFormat(v85_, "numAnimals", numItems, "animalType", v87_:getTitle() .. ", " .. v87_:getName(), "price", v86_)
end

-- Local values: _, _, _, totalPrice, text, price, item
function AnimalScreenDealer:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
	local _, _, _, v92_ = self:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	local v93_ = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_SELL)
	if numItems == 1 then
		v93_ = g_i18n:getText(AnimalScreenDealer.L10N_SYMBOL.CONFIRM_SELL_SINGULAR)
	end
	local v94_ = g_i18n:formatMoney(math.abs(v92_), 0, true, true)
	local v95_ = self.targetItems[itemIndex]
	return string.namedFormat(v93_, "numAnimals", numItems, "animalType", v95_:getTitle() .. ", " .. v95_:getName(), "price", v94_)
end

-- Local values: maxNumAnimals, husbandryMaxSlots
function AnimalScreenDealer:getSourceMaxNumAnimals(itemIndex)
	local v97_ = self:getMaxNumAnimals()
	local v98_ = self.husbandry == nil and 0 or (self.husbandry:getNumOfFreeAnimalSlots() or 0)
	return math.min(v97_, v98_)
end

-- Local values: item
function AnimalScreenDealer:getTargetMaxNumAnimals(itemIndex)
	return self.targetItems[itemIndex]:getNumAnimals()
end

function AnimalScreenDealer:getSourceData(id)
	return self.husbandries[id] or {}, g_i18n:getText("ui_animalTransport")
end

function AnimalScreenDealer:getTargetData(id)
	return { self.targetHusbandries[id] }, g_i18n:getText("ui_husbandryInformation")
end

function AnimalScreenDealer:onAnimalsChanged(husbandry, clusters)
	if husbandry == self.husbandry then
		self:initItems()
		self.animalsChangedCallback()
	end
end

-- Local values: data
function AnimalScreenDealer:onAnimalBuyError(errorCode)
	local v108_ = AnimalScreenDealer.BUY_ERROR_CODE_MAPPING[errorCode]
	if v108_ ~= nil then
		InfoDialog.show(g_i18n:getText(v108_.text))
	end
end

-- Local values: husbandries
function AnimalScreenDealer:setCurrentHusbandry(animalTypeIndex, husbandryIndex, isBuyMode)
	if isBuyMode then
		local v113_ = self.husbandries[animalTypeIndex]
		local v114_
		if v113_ == nil then
			v114_ = nil
		else
			v114_ = v113_[husbandryIndex] or nil
		end
		self.husbandry = v114_
	else
		self.husbandry = self.targetHusbandries[husbandryIndex]
	end
	self:initTargetItems()
end
AnimalScreenDealer.L10N_SYMBOL = {
	["DEALER"] = "animals_dealer",
	["FARM"] = "ui_farm",
	["CONFIRM_BUY"] = "shop_doYouWantToBuyAnimals",
	["CONFIRM_SELL"] = "shop_doYouWantToSellAnimals",
	["CONFIRM_BUY_SINGULAR"] = "shop_doYouWantToBuyAnimalsSingular",
	["CONFIRM_SELL_SINGULAR"] = "shop_doYouWantToSellAnimalsSingular",
	["BUYING"] = "shop_messageBuyingAnimals",
	["SELLING"] = "shop_messageSellingAnimals",
	["BUY"] = "button_buy",
	["SELL"] = "button_sell"
}
local v115_ = AnimalScreenDealer
local v116_ = {
	[AnimalBuyEvent.BUY_SUCCESS] = {
		["warning"] = false,
		["text"] = "shop_messageBoughtAnimals"
	},
	[AnimalBuyEvent.BUY_ERROR_NO_PERMISSION] = {
		["warning"] = true,
		["text"] = "shop_messageNoPermissionToTradeAnimals"
	},
	[AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_MONEY] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughMoneyToBuy"
	},
	[AnimalBuyEvent.BUY_ERROR_NOT_ENOUGH_SPACE] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughSpaceAnimals"
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalTypeNotSupported"
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalGlobalLimitReached"
	},
	[AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageHusbandryDoesNotExist"
	},
	[AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE] = {
		["warning"] = true,
		["text"] = "shop_messageHusbandryBuyBarnFirst"
	}
}
v115_.BUY_ERROR_CODE_MAPPING = v116_
local v117_ = AnimalScreenDealer
local v118_ = {
	[AnimalSellEvent.SELL_SUCCESS] = {
		["warning"] = false,
		["text"] = "shop_messageSoldAnimals"
	},
	[AnimalSellEvent.SELL_ERROR_NO_PERMISSION] = {
		["warning"] = true,
		["text"] = "shop_messageNoPermissionToTradeAnimals"
	},
	[AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER] = {
		["warning"] = true,
		["text"] = "shop_messageInvalidCluster"
	},
	[AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughAnimals"
	},
	[AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD] = {
		["warning"] = true,
		["text"] = "shop_messageCannotSellAnimal"
	},
	[AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageHusbandryDoesNotExist"
	}
}
v117_.SELL_ERROR_CODE_MAPPING = v118_
