-- Local values: AnimalScreenDealerFarm_mt
AnimalScreenDealerFarm = {}
local AnimalScreenDealerFarm_mt = Class(AnimalScreenDealerFarm, AnimalScreenBase)

-- Upvalues: AnimalScreenDealerFarm_mt
-- Local values: self
function AnimalScreenDealerFarm.new(husbandry, customMt)
	-- upvalues: (copy) AnimalScreenDealerFarm_mt
	local v4_ = AnimalScreenBase.new(customMt or AnimalScreenDealerFarm_mt)
	v4_.husbandry = husbandry
	v4_.sourceActionText = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUY)
	v4_.targetActionText = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELL)
	v4_.sourceTitle = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.DEALER)
	return v4_
end

-- Local values: animalTypeIndex, animalType, _, subTypeIndex, subType, _, visual, item
function AnimalScreenDealerFarm:initSourceItems()
	self.sourceItems = {}
	local v6_ = self.husbandry:getAnimalTypeIndex()
	local v7_ = g_currentMission.animalSystem:getTypeByIndex(v6_)
	if v7_ ~= nil then
		for _, v8_ in ipairs(v7_.subTypes) do
			local v9_ = g_currentMission.animalSystem:getSubTypeByIndex(v8_)
			for _, v10_ in ipairs(v9_.visuals) do
				if v10_.store.canBeBought then
					local v11_ = AnimalItemNew.new(v9_.subTypeIndex, v10_.minAge)
					if self.sourceItems[v6_] == nil then
						self.sourceItems[v6_] = {}
					end
					local v12_ = self.sourceItems[v6_]
					table.insert(v12_, v11_)
				end
			end
		end
	end
end

-- Local values: animalTypeIndex
function AnimalScreenDealerFarm:getSourceAnimalTypes()
	local v14_ = self.husbandry:getAnimalTypeIndex()
	return { g_currentMission.animalSystem:getTypeByIndex(v14_) }
end

function AnimalScreenDealerFarm:getSourceItems(animalTypeIndex, isBuyMode)
	return isBuyMode and (self.sourceItems[animalTypeIndex] or {}) or {}
end

-- Local values: clusters, _, cluster, item
function AnimalScreenDealerFarm:initTargetItems()
	self.targetItems = {}
	local v19_ = self.husbandry:getClusters()
	if v19_ ~= nil then
		for _, v20_ in ipairs(v19_) do
			local v21_ = AnimalItemStock.new(v20_)
			local v22_ = self.targetItems
			table.insert(v22_, v21_)
		end
	end
end

-- Local values: name, used, total
function AnimalScreenDealerFarm:getTargetName()
	local v24_ = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.FARM)
	local v25_ = self.husbandry:getNumOfAnimals()
	local v26_ = self.husbandry:getMaxNumOfAnimals()
	return string.format("%s (%d / %d)", v24_, v25_, v26_)
end

-- Local values: item, subTypeIndex, age, singlePrice, transportFee, buyPrice, errorCode, data, text
function AnimalScreenDealerFarm:applySource(animalTypeIndex, itemIndex, numItems)
	local v31_ = self.sourceItems[animalTypeIndex][itemIndex]
	local v32_ = v31_:getSubTypeIndex()
	local v33_ = v31_:getAge()
	local v34_ = -v31_:getPrice()
	local v35_ = -v31_:getTranportationFee(numItems)
	local v36_ = v34_ * numItems
	local v37_ = AnimalBuyEvent.validate(self.husbandry, v32_, v33_, numItems, v36_, v35_, self.husbandry:getOwnerFarmId())
	if v37_ ~= nil then
		local v38_ = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[v37_]
		self.errorCallback(g_i18n:getText(v38_.text))
		return false
	end
	local v39_ = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.BUYING)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, v39_)
	g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.husbandry, v32_, v33_, numItems, v36_, v35_))
	return true
end

-- Local values: data
function AnimalScreenDealerFarm:onAnimalBought(errorCode)
	g_messageCenter:unsubscribe(AnimalBuyEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v42_ = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]
	self.sourceActionFinished(v42_.isWarning, g_i18n:getText(v42_.text))
end

-- Local values: item, singlePrice, feePrice, sellPrice, clusterId, errorCode, data, text
function AnimalScreenDealerFarm:applyTarget(animalTypeIndex, itemIndex, numItems)
	local v46_ = self.targetItems[itemIndex]
	local v47_ = v46_:getPrice()
	local v48_ = -v46_:getTranportationFee(numItems)
	local v49_ = v47_ * numItems
	local v50_ = v46_:getClusterId()
	local v51_ = AnimalSellEvent.validate(self.husbandry, v50_, numItems, v49_, v48_)
	if v51_ ~= nil then
		local v52_ = AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[v51_]
		self.errorCallback(g_i18n:getText(v52_.text))
		return false
	end
	local v53_ = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.SELLING)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, v53_)
	g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
	g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.husbandry, v50_, numItems, v49_, v48_))
	return true
end

-- Local values: data
function AnimalScreenDealerFarm:onAnimalSold(errorCode)
	g_messageCenter:unsubscribe(AnimalSellEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v56_ = AnimalScreenDealerFarm.SELL_ERROR_CODE_MAPPING[errorCode]
	self.targetActionFinished(v56_.isWarning, g_i18n:getText(v56_.text))
end

-- Local values: item, singlePrice, transportFee, buyPrice
function AnimalScreenDealerFarm:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	local v61_ = self.sourceItems[animalTypeIndex][itemIndex]
	local v62_ = v61_:getPrice()
	local v63_ = v61_:getTranportationFee(numItems)
	local v64_ = v62_ * numItems
	return true, v64_, v63_, v64_ + v63_
end

-- Local values: item, singlePrice, transportFee, sellPrice
function AnimalScreenDealerFarm:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	local v68_ = self.targetItems[itemIndex]
	local v69_ = v68_:getPrice()
	local v70_ = -v68_:getTranportationFee(numItems)
	local v71_ = v69_ * numItems
	return true, v71_, v70_, v71_ + v70_
end

-- Local values: _, _, _, totalPrice, text, price, item
function AnimalScreenDealerFarm:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
	local _, _, _, v76_ = self:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	local v77_ = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_BUY)
	if numItems == 1 then
		v77_ = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_BUY_SINGULAR)
	end
	local v78_ = g_i18n:formatMoney(math.abs(v76_), 0, true, true)
	local v79_ = self.sourceItems[animalTypeIndex][itemIndex]
	return string.namedFormat(v77_, "numAnimals", numItems, "animalType", v79_:getTitle() .. ", " .. v79_:getName(), "price", v78_)
end

-- Local values: _, _, _, totalPrice, text, price, item
function AnimalScreenDealerFarm:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
	local _, _, _, v84_ = self:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	local v85_ = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_SELL)
	if numItems == 1 then
		v85_ = g_i18n:getText(AnimalScreenDealerFarm.L10N_SYMBOL.CONFIRM_SELL_SINGULAR)
	end
	local v86_ = g_i18n:formatMoney(math.abs(v84_), 0, true, true)
	local v87_ = self.targetItems[itemIndex]
	return string.namedFormat(v85_, "numAnimals", numItems, "animalType", v87_:getTitle() .. ", " .. v87_:getName(), "price", v86_)
end

-- Local values: maxNumAnimals
function AnimalScreenDealerFarm:getSourceMaxNumAnimals(itemIndex)
	local v89_ = self:getMaxNumAnimals()
	local v90_ = self.husbandry
	return math.min(v89_, v90_:getNumOfFreeAnimalSlots())
end

-- Local values: item
function AnimalScreenDealerFarm:getTargetMaxNumAnimals(itemIndex)
	return self.targetItems[itemIndex]:getNumAnimals()
end

function AnimalScreenDealerFarm:getSourceData(id)
	return { self.husbandry }, g_i18n:getText("ui_animalTransport")
end

function AnimalScreenDealerFarm:getTargetData()
	return { #self.targetItems > 0 and self.husbandry or nil }, g_i18n:getText("ui_husbandryInformation")
end

function AnimalScreenDealerFarm:onAnimalsChanged(husbandry, clusters)
	if husbandry == self.husbandry then
		self:initItems()
		self.animalsChangedCallback()
	end
end

-- Local values: data
function AnimalScreenDealerFarm:onAnimalBuyError(errorCode)
	local v98_ = AnimalScreenDealerFarm.BUY_ERROR_CODE_MAPPING[errorCode]
	if v98_ ~= nil then
		InfoDialog.show(g_i18n:getText(v98_.text))
	end
end
AnimalScreenDealerFarm.L10N_SYMBOL = {
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
local v99_ = AnimalScreenDealerFarm
local v100_ = {
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
v99_.BUY_ERROR_CODE_MAPPING = v100_
local v101_ = AnimalScreenDealerFarm
local v102_ = {
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
v101_.SELL_ERROR_CODE_MAPPING = v102_
