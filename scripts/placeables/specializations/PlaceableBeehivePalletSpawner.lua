PlaceableBeehivePalletSpawner = {}

function PlaceableBeehivePalletSpawner.prerequisitesPresent(specializations)
	return true
end

function PlaceableBeehivePalletSpawner.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "addFillLevel", PlaceableBeehivePalletSpawner.addFillLevel)
	SpecializationUtil.registerFunction(placeableType, "updatePallets", PlaceableBeehivePalletSpawner.updatePallets)
	SpecializationUtil.registerFunction(placeableType, "getPalletCallback", PlaceableBeehivePalletSpawner.getPalletCallback)
end

function PlaceableBeehivePalletSpawner.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableBeehivePalletSpawner.canBuy)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableBeehivePalletSpawner.updateInfo)
end

function PlaceableBeehivePalletSpawner.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableBeehivePalletSpawner)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableBeehivePalletSpawner)
end

function PlaceableBeehivePalletSpawner.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("BeehivePalletSpawner")
	PalletSpawner.registerXMLPaths(schema, basePath .. ".beehivePalletSpawner")
	schema:setXMLSpecializationType()
end

function PlaceableBeehivePalletSpawner.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".beehivePalletSpawner#pendingLiters", "Pending liters to be spawned")
end

-- Local values: spec, xmlFile, palletSpawnerKey
function PlaceableBeehivePalletSpawner:onLoad(savegame)
	local v9_ = self.spec_beehivePalletSpawner
	local v10_ = self.xmlFile
	v9_.palletSpawner = PalletSpawner.new(self.baseDirectory)
	if v9_.palletSpawner:load(self.components, v10_, "placeable.beehivePalletSpawner", self.customEnvironment, self.i3dMappings) then
		v9_.pendingLiters = 0
		v9_.spawnPending = false
		v9_.palletLimitReached = false
		v9_.infoHudTooManyPallets = {
			["title"] = g_i18n:getText("infohud_tooManyPallets")
		}
		v9_.fillType = g_fillTypeManager:getFillTypeIndexByName("HONEY")
		v9_.dirtyFlag = self:getNextDirtyFlag()
	else
		Logging.xmlError(v10_, "Unable to load pallet spawner %s", "placeable.beehivePalletSpawner")
		self:setLoadingState(PlaceableLoadingState.ERROR)
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:onDelete()
	local v12_ = self.spec_beehivePalletSpawner
	if v12_.palletSpawner ~= nil then
		v12_.palletSpawner:delete()
	end
	g_currentMission.beehiveSystem:removeBeehivePalletSpawner(self)
end

function PlaceableBeehivePalletSpawner:onFinalizePlacement()
	g_currentMission.beehiveSystem:addBeehivePalletSpawner(self)
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:onReadStream(streamId, connection)
	if connection:getIsServer() then
		self.spec_beehivePalletSpawner.palletLimitReached = streamReadBool(streamId)
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local v20_ = self.spec_beehivePalletSpawner
		streamWriteBool(streamId, v20_.palletLimitReached)
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		self.spec_beehivePalletSpawner.palletLimitReached = streamReadBool(streamId)
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v27_ = self.spec_beehivePalletSpawner
		streamWriteBool(streamId, v27_.palletLimitReached)
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:loadFromXMLFile(xmlFile, key)
	local v31_ = self.spec_beehivePalletSpawner
	v31_.pendingLiters = xmlFile:getValue(key .. ".beehivePalletSpawner#pendingLiters") or v31_.pendingLiters
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:saveToXMLFile(xmlFile, key, usedModNames)
	local v35_ = self.spec_beehivePalletSpawner
	if v35_.pendingLiters > 0 then
		xmlFile:setValue(key .. ".beehivePalletSpawner#pendingLiters", v35_.pendingLiters)
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:addFillLevel(fillLevel)
	if self.isServer then
		local v38_ = self.spec_beehivePalletSpawner
		if fillLevel ~= nil then
			v38_.pendingLiters = v38_.pendingLiters + fillLevel
		end
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:updatePallets()
	if self.isServer then
		local v40_ = self.spec_beehivePalletSpawner
		if not v40_.spawnPending and v40_.pendingLiters > 10 then
			v40_.spawnPending = true
			v40_.palletSpawner:getOrSpawnPallet(self:getOwnerFarmId(), v40_.fillType, self.getPalletCallback, self)
		end
	end
end

-- Local values: spec, delta
function PlaceableBeehivePalletSpawner:getPalletCallback(pallet, result, fillTypeIndex)
	local v45_ = self.spec_beehivePalletSpawner
	v45_.spawnPending = false
	if pallet == nil then
		if result ~= PalletSpawner.RESULT_NO_SPACE then
			if result == PalletSpawner.PALLET_LIMITED_REACHED and not v45_.palletLimitReached then
				v45_.palletLimitReached = true
				self:raiseDirtyFlags(v45_.dirtyFlag)
			end
		end
	else
		if result == PalletSpawner.RESULT_SUCCESS then
			if v45_.palletLimitReached then
				v45_.palletLimitReached = false
				self:raiseDirtyFlags(v45_.dirtyFlag)
			end
			pallet:emptyAllFillUnits(true)
		end
		local v46_ = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), 1, v45_.pendingLiters, fillTypeIndex, ToolType.UNDEFINED)
		local v47_ = v45_.pendingLiters - v46_
		v45_.pendingLiters = math.max(v47_, 0)
		return
	end
end

-- Local values: spec
function PlaceableBeehivePalletSpawner:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v51_ = self.spec_beehivePalletSpawner
	if v51_.palletLimitReached then
		local v52_ = v51_.infoHudTooManyPallets
		table.insert(infoTable, v52_)
	end
end

-- Local values: canBuy, warning
function PlaceableBeehivePalletSpawner:canBuy(superFunc)
	local v55_, v56_ = superFunc(self)
	if v55_ then
		if g_currentMission.beehiveSystem:getFarmBeehivePalletSpawner(g_localPlayer.farmId) == nil then
			return true, nil
		else
			return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
		end
	else
		return false, v56_
	end
end
