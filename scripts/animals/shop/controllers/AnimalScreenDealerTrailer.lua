-- Local values: AnimalScreenDealerTrailer_mt
AnimalScreenDealerTrailer = {}
local AnimalScreenDealerTrailer_mt = Class(AnimalScreenDealerTrailer, AnimalScreenBase)

-- Upvalues: AnimalScreenDealerTrailer_mt
-- Local values: self
function AnimalScreenDealerTrailer.new(trailer, customMt)
	-- upvalues: (copy) AnimalScreenDealerTrailer_mt
	local v4_ = AnimalScreenBase.new(customMt or AnimalScreenDealerTrailer_mt)
	v4_.trailer = trailer
	v4_.sourceActionText = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.BUY)
	v4_.targetActionText = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.SELL)
	v4_.sourceTitle = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.DEALER)
	return v4_
end

-- Local values: currentAnimalType, animalTypes, _, animalType, _, subTypeIndex, subType, _, visual, item
function AnimalScreenDealerTrailer:initSourceItems()
	self.sourceItems = {}
	local v6_ = self.trailer:getCurrentAnimalType()
	local v7_ = g_currentMission.animalSystem:getTypes()
	for _, v8_ in ipairs(v7_) do
		if (v6_ == nil or v8_ == v6_) and self.trailer:getSupportsAnimalType(v8_.typeIndex) then
			for _, v9_ in ipairs(v8_.subTypes) do
				local v10_ = g_currentMission.animalSystem:getSubTypeByIndex(v9_)
				for _, v11_ in ipairs(v10_.visuals) do
					if v11_.store.canBeBought then
						local v12_ = AnimalItemNew.new(v10_.subTypeIndex, v11_.minAge)
						if self.sourceItems[v8_.typeIndex] == nil then
							self.sourceItems[v8_.typeIndex] = {}
						end
						local v13_ = self.sourceItems[v8_.typeIndex]
						table.insert(v13_, v12_)
					end
				end
			end
		end
	end
end

-- Local values: currentAnimalType, supportedAnimalTypes, animalTypes, _, animalType
function AnimalScreenDealerTrailer:getSourceAnimalTypes()
	local v15_ = self.trailer:getCurrentAnimalType()
	if v15_ ~= nil then
		return { v15_ }
	end
	local v16_ = g_currentMission.animalSystem:getTypes()
	local v17_ = {}
	for _, v18_ in ipairs(v16_) do
		if self.trailer:getSupportsAnimalType(v18_.typeIndex) then
			table.insert(v17_, v18_)
		end
	end
	return v17_
end

-- Local values: clusters, _, cluster, item
function AnimalScreenDealerTrailer:initTargetItems()
	self.targetItems = {}
	local v20_ = self.trailer:getClusters()
	if v20_ ~= nil then
		for _, v21_ in ipairs(v20_) do
			local v22_ = AnimalItemStock.new(v21_)
			local v23_ = self.targetItems
			table.insert(v23_, v22_)
		end
	end
end

-- Local values: name, currentAnimalType, used, total
function AnimalScreenDealerTrailer:getTargetName()
	local v25_ = self.trailer:getName()
	local v26_ = self.trailer:getCurrentAnimalType()
	if v26_ == nil then
		return v25_
	end
	local v27_ = self.trailer:getNumOfAnimals()
	local v28_ = self.trailer:getMaxNumOfAnimals(v26_)
	return string.format("%s (%d / %d)", v25_, v27_, v28_)
end

-- Local values: item, singlePrice, buyPrice
function AnimalScreenDealerTrailer:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	local v33_ = self.sourceItems[animalTypeIndex][itemIndex]:getPrice() * numItems
	return true, v33_, 0, v33_
end

-- Local values: item, singlePrice, sellPrice
function AnimalScreenDealerTrailer:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	local v37_ = self.targetItems[itemIndex]:getPrice() * numItems
	return true, v37_, 0, v37_
end

-- Local values: item, animalSystem, subType, animalType, used, total, free, maxNumAnimals
function AnimalScreenDealerTrailer:getSourceMaxNumAnimals(animalTypeIndex, itemIndex)
	local v41_ = self.sourceItems[animalTypeIndex][itemIndex]
	local v42_ = g_currentMission.animalSystem
	local v43_ = v42_:getTypeByIndex(v42_:getSubTypeByIndex(v41_:getSubTypeIndex()).typeIndex)
	local v44_ = self.trailer:getNumOfAnimals()
	local v45_ = self.trailer:getMaxNumOfAnimals(v43_) - v44_
	local v46_ = self:getMaxNumAnimals()
	return math.min(v46_, v45_)
end

-- Local values: item
function AnimalScreenDealerTrailer:getTargetMaxNumAnimals(itemIndex)
	local v49_ = self.targetItems[itemIndex]
	return v49_ == nil and 0 or v49_:getNumAnimals()
end

function AnimalScreenDealerTrailer:getSourceData(id)
	return { self.trailer }, g_i18n:getText("ui_animalLoadOnto")
end

function AnimalScreenDealerTrailer:getTargetData()
	return { self.trailer }, g_i18n:getText("ui_animalSellFrom")
end

-- Local values: _, _, _, totalPrice, text, price, item
function AnimalScreenDealerTrailer:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
	local _, _, _, v56_ = self:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	local v57_ = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_BUY)
	if numItems == 1 then
		v57_ = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_BUY_SINGULAR)
	end
	local v58_ = g_i18n:formatMoney(math.abs(v56_), 0, true, true)
	local v59_ = self.sourceItems[animalTypeIndex][itemIndex]
	return string.namedFormat(v57_, "numAnimals", numItems, "animalType", v59_:getTitle() .. ", " .. v59_:getName(), "price", v58_)
end

-- Local values: _, _, _, totalPrice, text, price, item
function AnimalScreenDealerTrailer:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
	local _, _, _, v64_ = self:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	local v65_ = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_SELL)
	if numItems == 1 then
		v65_ = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.CONFIRM_SELL_SINGULAR)
	end
	local v66_ = g_i18n:formatMoney(math.abs(v64_), 0, true, true)
	local v67_ = self.targetItems[itemIndex]
	return string.namedFormat(v65_, "numAnimals", numItems, "animalType", v67_:getTitle() .. ", " .. v67_:getName(), "price", v66_)
end

-- Local values: item, subTypeIndex, age, singlePrice, buyPrice, errorCode, data, text
function AnimalScreenDealerTrailer:applySource(animalTypeIndex, itemIndex, numItems)
	local v72_ = self.sourceItems[animalTypeIndex][itemIndex]
	local v73_ = v72_:getSubTypeIndex()
	local v74_ = v72_:getAge()
	local v75_ = -v72_:getPrice() * numItems
	local v76_ = AnimalBuyEvent.validate(self.trailer, v73_, v74_, numItems, v75_, 0, self.trailer:getOwnerFarmId())
	if v76_ ~= nil then
		local v77_ = AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[v76_]
		self.errorCallback(g_i18n:getText(v77_.text))
		return false
	end
	local v78_ = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.BUYING)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, v78_)
	g_messageCenter:subscribe(AnimalBuyEvent, self.onAnimalBought, self)
	g_client:getServerConnection():sendEvent(AnimalBuyEvent.new(self.trailer, v73_, v74_, numItems, v75_, 0))
	return true
end

-- Local values: data
function AnimalScreenDealerTrailer:onAnimalBought(errorCode)
	g_messageCenter:unsubscribe(AnimalBuyEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v81_ = AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[errorCode]
	self.sourceActionFinished(v81_.isWarning, g_i18n:getText(v81_.text))
end

-- Local values: item, singlePrice, sellPrice, clusterId, errorCode, data, text
function AnimalScreenDealerTrailer:applyTarget(animalTypeIndex, itemIndex, numItems)
	local v85_ = self.targetItems[itemIndex]
	local v86_ = v85_:getPrice() * numItems
	local v87_ = v85_:getClusterId()
	local v88_ = AnimalSellEvent.validate(self.trailer, v87_, numItems, v86_, 0)
	if v88_ ~= nil then
		local v89_ = AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING[v88_]
		self.errorCallback(g_i18n:getText(v89_.text))
		return false
	end
	local v90_ = g_i18n:getText(AnimalScreenDealerTrailer.L10N_SYMBOL.SELLING)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, v90_)
	g_messageCenter:subscribe(AnimalSellEvent, self.onAnimalSold, self)
	g_client:getServerConnection():sendEvent(AnimalSellEvent.new(self.trailer, v87_, numItems, v86_, 0))
	return true
end

-- Local values: data
function AnimalScreenDealerTrailer:onAnimalSold(errorCode)
	g_messageCenter:unsubscribe(AnimalSellEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v93_ = AnimalScreenDealerTrailer.SELL_ERROR_CODE_MAPPING[errorCode]
	self.targetActionFinished(v93_.isWarning, g_i18n:getText(v93_.text))
end

function AnimalScreenDealerTrailer:onAnimalsChanged(trailer, clusters)
	if trailer == self.trailer then
		self:initItems()
		self.animalsChangedCallback()
	end
end

-- Local values: data
function AnimalScreenDealerTrailer:onAnimalBuyError(errorCode)
	local v97_ = AnimalScreenDealerTrailer.BUY_ERROR_CODE_MAPPING[errorCode]
	if v97_ ~= nil then
		InfoDialog.show(g_i18n:getText(v97_.text))
	end
end
AnimalScreenDealerTrailer.L10N_SYMBOL = {
	["DEALER"] = "animals_dealer",
	["BUY"] = "button_buy",
	["SELL"] = "button_sell",
	["CONFIRM_BUY"] = "shop_doYouWantToBuyAnimals",
	["CONFIRM_SELL"] = "shop_doYouWantToSellAnimals",
	["CONFIRM_BUY_SINGULAR"] = "shop_doYouWantToBuyAnimalsSingular",
	["CONFIRM_SELL_SINGULAR"] = "shop_doYouWantToSellAnimalsSingular",
	["BUYING"] = "shop_messageBuyingAnimals",
	["SELLING"] = "shop_messageSellingAnimals"
}
local v98_ = AnimalScreenDealerTrailer
local v99_ = {
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
		["text"] = "shop_messageNotEnoughSpaceAnimalsTrailer"
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_NOT_SUPPORTED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalTypeNotSupportedByTrailer"
	},
	[AnimalBuyEvent.BUY_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalGlobalLimitReached"
	},
	[AnimalBuyEvent.BUY_ERROR_OBJECT_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageTrailerDoesNotExist"
	},
	[AnimalBuyEvent.BUY_ERROR_NO_BARN_AVAILABLE] = {
		["warning"] = true,
		["text"] = "shop_messageHusbandryBuyBarnFirst"
	}
}
v98_.BUY_ERROR_CODE_MAPPING = v99_
local v100_ = AnimalScreenDealerTrailer
local v101_ = {
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
		["text"] = "shop_messageTrailerDoesNotExist"
	}
}
v100_.SELL_ERROR_CODE_MAPPING = v101_
