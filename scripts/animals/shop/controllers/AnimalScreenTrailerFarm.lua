-- Local values: AnimalScreenTrailerFarm_mt
AnimalScreenTrailerFarm = {}
local AnimalScreenTrailerFarm_mt = Class(AnimalScreenTrailerFarm, AnimalScreenBase)

-- Upvalues: AnimalScreenTrailerFarm_mt
-- Local values: self
function AnimalScreenTrailerFarm.new(husbandry, trailer, customMt)
	-- upvalues: (copy) AnimalScreenTrailerFarm_mt
	local v5_ = AnimalScreenBase.new(customMt or AnimalScreenTrailerFarm_mt)
	v5_.husbandry = husbandry
	v5_.trailer = trailer
	return v5_
end

-- Local values: animalTypeIndex, clusters, _, cluster, item
function AnimalScreenTrailerFarm:initSourceItems()
	self.sourceItems = {}
	local v7_ = self.trailer:getCurrentAnimalType()
	if v7_ ~= nil then
		local v8_ = v7_.typeIndex
		local v9_ = self.trailer:getClusters()
		if v9_ ~= nil then
			for _, v10_ in ipairs(v9_) do
				local v11_ = AnimalItemStock.new(v10_)
				if self.sourceItems[v8_] == nil then
					self.sourceItems[v8_] = {}
				end
				local v12_ = self.sourceItems[v8_]
				table.insert(v12_, v11_)
			end
		end
	end
end

-- Local values: animalTypeIndex
function AnimalScreenTrailerFarm:getSourceAnimalTypes()
	local v14_ = self.husbandry:getAnimalTypeIndex()
	return { g_currentMission.animalSystem:getTypeByIndex(v14_) }
end

-- Local values: clusters, _, cluster, item
function AnimalScreenTrailerFarm:initTargetItems()
	self.targetItems = {}
	local v16_ = self.husbandry:getClusters()
	if v16_ ~= nil then
		for _, v17_ in ipairs(v16_) do
			local v18_ = AnimalItemStock.new(v17_)
			local v19_ = self.targetItems
			table.insert(v19_, v18_)
		end
	end
end

-- Local values: name, currentAnimalType, used, total
function AnimalScreenTrailerFarm:getSourceName()
	local v21_ = self.trailer:getName()
	local v22_ = self.trailer:getCurrentAnimalType()
	if v22_ == nil then
		return v21_
	end
	local v23_ = self.trailer:getNumOfAnimals()
	local v24_ = self.trailer:getMaxNumOfAnimals(v22_)
	return string.format("%s (%d / %d)", v21_, v23_, v24_)
end

-- Local values: name, used, total
function AnimalScreenTrailerFarm:getTargetName()
	local v26_ = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.FARM)
	local v27_ = self.husbandry:getNumOfAnimals()
	local v28_ = self.husbandry:getMaxNumOfAnimals()
	return string.format("%s (%d / %d)", v26_, v27_, v28_)
end

function AnimalScreenTrailerFarm:getSourceActionText()
	return g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM)
end

function AnimalScreenTrailerFarm:getTargetActionText()
	return g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER)
end

-- Local values: text, item
function AnimalScreenTrailerFarm:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
	local v33_ = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_FARM)
	if numItems == 1 then
		v33_ = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_FARM_SINGULAR)
	end
	local v34_ = self.sourceItems[animalTypeIndex][itemIndex]
	return string.namedFormat(v33_, "numAnimals", numItems, "animalType", v34_:getTitle() .. ", " .. v34_:getName())
end

-- Local values: text, item
function AnimalScreenTrailerFarm:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
	local v38_ = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER)
	if numItems == 1 then
		v38_ = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER_SINGULAR)
	end
	local v39_ = self.targetItems[itemIndex]
	return string.namedFormat(v38_, "numAnimals", numItems, "animalType", v39_:getTitle() .. ", " .. v39_:getName())
end

function AnimalScreenTrailerFarm:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	return false, 0, 0, 0
end

function AnimalScreenTrailerFarm:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	return false, 0, 0, 0
end

-- Local values: item, maxNumAnimals
function AnimalScreenTrailerFarm:getSourceMaxNumAnimals(animalTypeIndex, itemIndex)
	if self.sourceItems[animalTypeIndex] == nil then
		return 0
	end
	local v43_ = self.sourceItems[animalTypeIndex][itemIndex]
	if v43_ == nil then
		return 0
	end
	local v44_ = self:getMaxNumAnimals()
	local v45_ = v43_:getNumAnimals()
	local v46_ = self.husbandry
	return math.min(v44_, v45_, v46_:getNumOfFreeAnimalSlots())
end

-- Local values: item, animalSystem, subType, animalType, used, total, free, maxNumAnimals
function AnimalScreenTrailerFarm:getTargetMaxNumAnimals(itemIndex)
	local v49_ = self.targetItems[itemIndex]
	if v49_ == nil then
		return 0
	end
	local v50_ = g_currentMission.animalSystem
	local v51_ = v50_:getTypeByIndex(v50_:getSubTypeByIndex(v49_:getSubTypeIndex()).typeIndex)
	local v52_ = self.trailer:getNumOfAnimals()
	local v53_ = self.trailer:getMaxNumOfAnimals(v51_) - v52_
	local v54_ = self:getMaxNumAnimals()
	return math.min(v54_, v53_, v49_:getNumAnimals())
end

function AnimalScreenTrailerFarm:getSourceData(id)
	return { self.trailer }, g_i18n:getText("ui_animalUnloadFrom")
end

function AnimalScreenTrailerFarm:getTargetData()
	return { self.husbandry }, g_i18n:getText("ui_husbandryInformation")
end

-- Local values: item, clusterId, errorCode, data, text
function AnimalScreenTrailerFarm:applySource(animalTypeIndex, itemIndex, numItems)
	local v61_ = self.sourceItems[animalTypeIndex][itemIndex]:getClusterId()
	local v62_ = AnimalMoveEvent.validate(self.trailer, self.husbandry, v61_, numItems, self.trailer:getOwnerFarmId())
	if v62_ ~= nil then
		local v63_ = AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[v62_]
		self.errorCallback(g_i18n:getText(v63_.text))
		return false
	end
	local v64_ = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_FARM)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, v64_)
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToFarm, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(self.trailer, self.husbandry, v61_, numItems))
	return true
end

-- Local values: data
function AnimalScreenTrailerFarm:onAnimalMovedToFarm(errorCode)
	g_messageCenter:unsubscribe(AnimalMoveEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v67_ = AnimalScreenTrailerFarm.MOVE_TO_FARM_ERROR_CODE_MAPPING[errorCode]
	self.sourceActionFinished(v67_.isWarning, g_i18n:getText(v67_.text))
end

-- Local values: item, clusterId, errorCode, data, text
function AnimalScreenTrailerFarm:applyTarget(animalTypeIndex, itemIndex, numItems)
	local v71_ = self.targetItems[itemIndex]:getClusterId()
	local v72_ = AnimalMoveEvent.validate(self.husbandry, self.trailer, v71_, numItems, self.trailer:getOwnerFarmId())
	if v72_ ~= nil then
		local v73_ = AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[v72_]
		self.errorCallback(g_i18n:getText(v73_.text))
		return false
	end
	local v74_ = g_i18n:getText(AnimalScreenTrailerFarm.L10N_SYMBOL.MOVE_TO_TRAILER)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, v74_)
	g_messageCenter:subscribe(AnimalMoveEvent, self.onAnimalMovedToTrailer, self)
	g_client:getServerConnection():sendEvent(AnimalMoveEvent.new(self.husbandry, self.trailer, v71_, numItems))
	return true
end

-- Local values: data
function AnimalScreenTrailerFarm:onAnimalMovedToTrailer(errorCode)
	g_messageCenter:unsubscribe(AnimalMoveEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v77_ = AnimalScreenTrailerFarm.MOVE_TO_TRAILER_ERROR_CODE_MAPPING[errorCode]
	self.targetActionFinished(v77_.isWarning, g_i18n:getText(v77_.text))
end

function AnimalScreenTrailerFarm:onAnimalsChanged(obj, clusters)
	if obj == self.trailer or obj == self.husbandry then
		self:initItems()
		self.animalsChangedCallback()
	end
end
AnimalScreenTrailerFarm.L10N_SYMBOL = {
	["FARM"] = "ui_farm",
	["MOVE_TO_FARM"] = "shop_moveToFarm",
	["MOVE_TO_TRAILER"] = "shop_moveToTrailer",
	["CONFIRM_MOVE_TO_FARM"] = "shop_doYouWantToMoveAnimalsToFarm",
	["CONFIRM_MOVE_TO_TRAILER"] = "shop_doYouWantToMoveAnimalsToTrailer",
	["CONFIRM_MOVE_TO_FARM_SINGULAR"] = "shop_doYouWantToMoveAnimalsToFarmSingular",
	["CONFIRM_MOVE_TO_TRAILER_SINGULAR"] = "shop_doYouWantToMoveAnimalsToTrailerSingular"
}
local v80_ = AnimalScreenTrailerFarm
local v81_ = {
	[AnimalMoveEvent.MOVE_SUCCESS] = {
		["warning"] = false,
		["text"] = "shop_movedToTrailer"
	},
	[AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION] = {
		["warning"] = true,
		["text"] = "shop_messageNoPermissionToTradeAnimals"
	},
	[AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageHusbandryDoesNotExist"
	},
	[AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageTrailerDoesNotExist"
	},
	[AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER] = {
		["warning"] = true,
		["text"] = "shop_messageInvalidCluster"
	},
	[AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalTypeNotSupportedByTrailer"
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughSpaceAnimalsTrailer"
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughAnimals"
	}
}
v80_.MOVE_TO_TRAILER_ERROR_CODE_MAPPING = v81_
local v82_ = AnimalScreenTrailerFarm
local v83_ = {
	[AnimalMoveEvent.MOVE_SUCCESS] = {
		["warning"] = false,
		["text"] = "shop_movedToFarm"
	},
	[AnimalMoveEvent.MOVE_ERROR_NO_PERMISSION] = {
		["warning"] = true,
		["text"] = "shop_messageNoPermissionToTradeAnimals"
	},
	[AnimalMoveEvent.MOVE_ERROR_SOURCE_OBJECT_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageTrailerDoesNotExist"
	},
	[AnimalMoveEvent.MOVE_ERROR_TARGET_OBJECT_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageHusbandryDoesNotExist"
	},
	[AnimalMoveEvent.MOVE_ERROR_INVALID_CLUSTER] = {
		["warning"] = true,
		["text"] = "shop_messageInvalidCluster"
	},
	[AnimalMoveEvent.MOVE_ERROR_ANIMAL_NOT_SUPPORTED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalTypeNotSupported"
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_SPACE] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughSpaceAnimals"
	},
	[AnimalMoveEvent.MOVE_ERROR_NOT_ENOUGH_ANIMALS] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughAnimals"
	}
}
v82_.MOVE_TO_FARM_ERROR_CODE_MAPPING = v83_
