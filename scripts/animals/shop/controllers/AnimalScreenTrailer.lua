-- Local values: AnimalScreenTrailer_mt
AnimalScreenTrailer = {}
local AnimalScreenTrailer_mt = Class(AnimalScreenTrailer, AnimalScreenBase)

-- Upvalues: AnimalScreenTrailer_mt
-- Local values: self
function AnimalScreenTrailer.new(trailer, customMt)
	-- upvalues: (copy) AnimalScreenTrailer_mt
	local v4_ = AnimalScreenBase.new(customMt or AnimalScreenTrailer_mt)
	v4_.trailer = trailer
	v4_.trailer:setAnimalScreenController(v4_)
	return v4_
end

function AnimalScreenTrailer:reset()
	self.trailer:setAnimalScreenController(nil)
	AnimalScreenTrailer:superClass().reset(self)
end

-- Local values: rideables, _, rideable, cluster, animalTypeIndex, item
function AnimalScreenTrailer:initSourceItems()
	self.sourceItems = {}
	self.clusterToVehicle = {}
	local v7_ = self.trailer:getRideablesInTrigger()
	if v7_ ~= nil then
		for _, v8_ in ipairs(v7_) do
			local v9_ = v8_:getCluster()
			local v10_ = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(v9_.subTypeIndex)
			local v11_ = AnimalItemStock.new(v9_)
			if self.sourceItems[v10_] == nil then
				self.sourceItems[v10_] = {}
			end
			local v12_ = self.sourceItems[v10_]
			table.insert(v12_, v11_)
			self.clusterToVehicle[v9_] = v8_
		end
	end
end

-- Local values: supportedAnimalTypes, animalTypes, _, animalType
function AnimalScreenTrailer:getSourceAnimalTypes()
	local v14_ = g_currentMission.animalSystem:getTypes()
	local v15_ = {}
	for _, v16_ in ipairs(v14_) do
		if self.trailer:getSupportsAnimalType(v16_.typeIndex) then
			table.insert(v15_, v16_)
		end
	end
	return v15_
end

-- Local values: clusters, _, cluster, item
function AnimalScreenTrailer:initTargetItems()
	self.targetItems = {}
	local v18_ = self.trailer:getClusters()
	if v18_ ~= nil then
		for _, v19_ in ipairs(v18_) do
			local v20_ = AnimalItemStock.new(v19_)
			local v21_ = self.targetItems
			table.insert(v21_, v20_)
		end
	end
end

-- Local values: name, currentAnimalType, used, total
function AnimalScreenTrailer:getSourceName()
	local v23_ = self.trailer:getName()
	local v24_ = self.trailer:getCurrentAnimalType()
	if v24_ == nil then
		return v23_
	end
	local v25_ = self.trailer:getNumOfAnimals()
	local v26_ = self.trailer:getMaxNumOfAnimals(v24_)
	return string.format("%s (%d / %d)", v23_, v25_, v26_)
end

function AnimalScreenTrailer:getTargetName()
	return ""
end

function AnimalScreenTrailer:getSourceActionText()
	return g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_TRAILER)
end

function AnimalScreenTrailer:getTargetActionText()
	return g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_SPAWN_PLACE)
end

-- Local values: text, item
function AnimalScreenTrailer:getApplySourceConfirmationText(animalTypeIndex, itemIndex, numItems)
	local v31_ = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER)
	if numItems == 1 then
		v31_ = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_TRAILER_SINGULAR)
	end
	local v32_ = self.sourceItems[animalTypeIndex][itemIndex]
	return string.namedFormat(v31_, "numAnimals", numItems, "animalType", v32_:getTitle() .. ", " .. v32_:getName())
end

-- Local values: text, item
function AnimalScreenTrailer:getApplyTargetConfirmationText(animalTypeIndex, itemIndex, numItems)
	local v36_ = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_SPAWN_PLACE)
	if numItems == 1 then
		v36_ = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.CONFIRM_MOVE_TO_SPAWN_PLACE_SINGULAR)
	end
	local v37_ = self.targetItems[itemIndex]
	return string.format(v36_, v37_:getTitle() .. ", " .. v37_:getName())
end

function AnimalScreenTrailer:getSourcePrice(animalTypeIndex, itemIndex, numItems)
	return false, 0, 0, 0
end

function AnimalScreenTrailer:getTargetPrice(animalTypeIndex, itemIndex, numItems)
	return false, 0, 0, 0
end

function AnimalScreenTrailer:getSourceMaxNumAnimals(itemIndex)
	return 1
end

function AnimalScreenTrailer:getTargetMaxNumAnimals(itemIndex)
	return 1
end

function AnimalScreenTrailer:getSourceData(id)
	return { self.trailer }, g_i18n:getText("ui_animalLoadOnto")
end

function AnimalScreenTrailer:getTargetData()
	return { self.trailer }, g_i18n:getText("ui_animalUnloadFrom")
end

-- Local values: item, cluster, rideable, errorCode, data, text
function AnimalScreenTrailer:applySource(animalTypeIndex, itemIndex, numItems)
	local v43_ = self.sourceItems[animalTypeIndex][itemIndex]:getCluster()
	local v44_ = self.clusterToVehicle[v43_]
	local v45_ = AnimalLoadEvent.validate(self.trailer, v44_, self.trailer:getOwnerFarmId())
	if v45_ ~= nil then
		local v46_ = AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING[v45_]
		self.errorCallback(g_i18n:getText(v46_.text))
		return false
	end
	local v47_ = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_TRAILER)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, v47_)
	g_messageCenter:subscribe(AnimalLoadEvent, self.onAnimalLoadedToTrailer, self)
	g_client:getServerConnection():sendEvent(AnimalLoadEvent.new(self.trailer, v44_))
	return true
end

-- Local values: data
function AnimalScreenTrailer:onAnimalMovedToSpawnPlace(errorCode)
	g_messageCenter:unsubscribe(AnimalUnloadEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v50_ = AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING[errorCode]
	self.sourceActionFinished(v50_.isWarning, g_i18n:getText(v50_.text))
end

-- Local values: item, clusterId, errorCode, data, text
function AnimalScreenTrailer:applyTarget(animalTypeIndex, itemIndex, numItems)
	local v53_ = self.targetItems[itemIndex]:getClusterId()
	local v54_ = AnimalUnloadEvent.validate(self.trailer, v53_)
	if v54_ ~= nil then
		local v55_ = AnimalScreenTrailer.UNLOAD_ERROR_CODE_MAPPING[v54_]
		self.errorCallback(g_i18n:getText(v55_.text))
		return false
	end
	local v56_ = g_i18n:getText(AnimalScreenTrailer.L10N_SYMBOL.MOVE_TO_SPAWN_PLACE)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_TARGET, v56_)
	g_messageCenter:subscribe(AnimalUnloadEvent, self.onAnimalMovedToSpawnPlace, self)
	g_client:getServerConnection():sendEvent(AnimalUnloadEvent.new(self.trailer, v53_))
	return true
end

-- Local values: data
function AnimalScreenTrailer:onAnimalLoadedToTrailer(errorCode)
	g_messageCenter:unsubscribe(AnimalLoadEvent, self)
	self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
	local v59_ = AnimalScreenTrailer.LOAD_ERROR_CODE_MAPPING[errorCode]
	self.targetActionFinished(v59_.isWarning, g_i18n:getText(v59_.text))
end

function AnimalScreenTrailer:onAnimalsChanged(obj, clusters)
	if obj == self.trailer then
		self:initItems()
		self.animalsChangedCallback()
	end
end
AnimalScreenTrailer.L10N_SYMBOL = {
	["MOVE_TO_SPAWN_PLACE"] = "shop_moveToSpawnPlace",
	["MOVE_TO_TRAILER"] = "shop_moveToTrailer",
	["CONFIRM_MOVE_TO_SPAWN_PLACE"] = "shop_doYouWantToMoveAnimalsToSpawnPlace",
	["CONFIRM_MOVE_TO_TRAILER"] = "shop_doYouWantToMoveAnimalsToTrailer",
	["CONFIRM_MOVE_TO_SPAWN_PLACE_SINGULAR"] = "shop_doYouWantToMoveAnimalsToSpawnPlaceSingular",
	["CONFIRM_MOVE_TO_TRAILER_SINGULAR"] = "shop_doYouWantToMoveAnimalsToTrailerSingular"
}
local v62_ = AnimalScreenTrailer
local v63_ = {
	[AnimalLoadEvent.LOAD_SUCCESS] = {
		["warning"] = false,
		["text"] = "shop_movedToTrailer"
	},
	[AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION] = {
		["warning"] = true,
		["text"] = "shop_messageNoPermissionToTradeAnimals"
	},
	[AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageTrailerDoesNotExist"
	},
	[AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST] = {
		["warning"] = true,
		["text"] = "shop_messageRideableDoesNotExist"
	},
	[AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER] = {
		["warning"] = true,
		["text"] = "shop_messageInvalidCluster"
	},
	[AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalTypeNotSupportedByTrailer"
	},
	[AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughAnimals"
	},
	[AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughSpaceAnimalsTrailer"
	}
}
v62_.LOAD_ERROR_CODE_MAPPING = v63_
local v64_ = AnimalScreenTrailer
local v65_ = {
	[AnimalUnloadEvent.UNLOAD_SUCCESS] = {
		["warning"] = false,
		["text"] = "shop_movedToSpawnPlace"
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_NO_PERMISSION] = {
		["warning"] = true,
		["text"] = "shop_messageNoPermissionToTradeAnimals"
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER] = {
		["warning"] = true,
		["text"] = "shop_messageInvalidCluster"
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalCouldNotBeUnloaded"
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalDoesNotSupportUnloading"
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughSpaceAnimalsArea"
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS] = {
		["warning"] = true,
		["text"] = "shop_messageNotEnoughAnimals"
	},
	[AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED] = {
		["warning"] = true,
		["text"] = "shop_messageAnimalRideableLimitReached"
	}
}
v64_.UNLOAD_ERROR_CODE_MAPPING = v65_
