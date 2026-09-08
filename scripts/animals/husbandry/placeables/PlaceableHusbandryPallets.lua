PlaceableHusbandryPallets = {}

function PlaceableHusbandryPallets.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end

function PlaceableHusbandryPallets.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onPalletTriggerCallback", PlaceableHusbandryPallets.onPalletTriggerCallback)
	SpecializationUtil.registerFunction(placeableType, "getAllPalletsCallback", PlaceableHusbandryPallets.getAllPalletsCallback)
	SpecializationUtil.registerFunction(placeableType, "updatePallets", PlaceableHusbandryPallets.updatePallets)
	SpecializationUtil.registerFunction(placeableType, "addPendingLiters", PlaceableHusbandryPallets.addPendingLiters)
	SpecializationUtil.registerFunction(placeableType, "getPalletCallback", PlaceableHusbandryPallets.getPalletCallback)
	SpecializationUtil.registerFunction(placeableType, "showSpawnerBlockedWarning", PlaceableHusbandryPallets.showSpawnerBlockedWarning)
	SpecializationUtil.registerFunction(placeableType, "showPalletBlockedWarning", PlaceableHusbandryPallets.showPalletBlockedWarning)
	SpecializationUtil.registerFunction(placeableType, "updatePalletInfo", PlaceableHusbandryPallets.updatePalletInfo)
end

function PlaceableHusbandryPallets.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryPallets.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryPallets.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryPallets.updateInfo)
end

function PlaceableHusbandryPallets.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandryPallets)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryPallets)
end

function PlaceableHusbandryPallets.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	local v7_ = basePath .. ".husbandry.pallets.palletSpawner(?)"
	schema:register(XMLValueType.NODE_INDEX, v7_ .. ".palletTrigger(?)#node", "A pallet trigger")
	FillTypeManager.registerConfigXMLFilltypes(schema, v7_)
	schema:register(XMLValueType.STRING, v7_ .. "#unitText", "Pallet fill type unit")
	schema:register(XMLValueType.INT, v7_ .. "#maxNumPallets", "Maximum number of pallets")
	PalletSpawner.registerXMLPaths(schema, v7_)
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryPallets.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".pendingLiters(?)#fillType", "Name of the filltype")
	schema:register(XMLValueType.FLOAT, basePath .. ".pendingLiters(?)#liters", "Pending liters")
	schema:setXMLSpecializationType()
end

-- Local values: spec, _, key, fillTypes, maxNumPallets, palletSpawner, _, fillTypeIndex, palletTriggers, _, triggerKey, node, info, animalTypeIndex, animalType, _, subTypeIndex, subType, pallets
function PlaceableHusbandryPallets:onLoad(savegame)
	local v11_ = self.spec_husbandryPallets
	v11_.fillTypeIndexToPalletSpawner = {}
	v11_.palletSpawner = {}
	v11_.fillTypes = {}
	v11_.litersPerHour = {}
	v11_.currentPallets = {}
	v11_.maxNumPallets = {}
	v11_.numPalletInfoUpdateRunning = 0
	v11_.numSpawnsPending = 0
	v11_.pendingLiters = {}
	v11_.capacities = {}
	v11_.capacitiesPending = {}
	v11_.capacitiesSent = {}
	v11_.maxCapacitiesPending = {}
	v11_.fillLevels = {}
	v11_.fillLevelsPending = {}
	v11_.fillLevelsSent = {}
	v11_.pallets = {}
	v11_.activeFillTypes = {}
	for _, v12_ in self.xmlFile:iterator("placeable.husbandry.pallets.palletSpawner") do
		local v13_ = g_fillTypeManager:loadCombinedFillTypesFromConfig(self.xmlFile, v12_)
		if #v13_ > 0 then
			local v14_ = self.xmlFile:getValue(v12_ .. "#maxNumPallets", 1)
			local v15_ = PalletSpawner.new(self.baseDirectory)
			v15_:load(self.components, self.xmlFile, v12_, self.customEnvironment, self.i3dMappings)
			for _, v16_ in ipairs(v13_) do
				if v11_.fillTypeIndexToPalletSpawner[v16_] == nil then
					v11_.fillTypeIndexToPalletSpawner[v16_] = v15_
					local v17_ = v11_.fillTypes
					table.insert(v17_, v16_)
					v11_.litersPerHour[v16_] = 0
					v11_.maxNumPallets[v16_] = v14_
					v11_.capacities[v16_] = 0
					v11_.capacitiesPending[v16_] = 0
					v11_.capacitiesSent[v16_] = 0
					v11_.maxCapacitiesPending[v16_] = 0
					v11_.fillLevels[v16_] = 0
					v11_.fillLevelsPending[v16_] = 0
					v11_.fillLevelsSent[v16_] = 0
					v11_.pendingLiters[v16_] = 0
				else
					Logging.xmlWarning(self.xmlFile, "There is already a palletSpawner defined for fillType \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v16_))
				end
			end
			local v18_
			if self.isServer then
				v18_ = {}
				for _, v19_ in self.xmlFile:iterator(v12_ .. ".palletTrigger") do
					local v20_ = self.xmlFile:getValue(v19_ .. "#node", nil, self.components, self.i3dMappings)
					if v20_ ~= nil then
						if CollisionFlag.getHasMaskFlagSet(v20_, CollisionFlag.VEHICLE) then
							table.insert(v18_, {
								["node"] = v20_,
								["added"] = false
							})
						else
							Logging.xmlWarning(self.xmlFile, "Pallet trigger %q at %q does not have \'VEHICLE\' bit set in its mask, ignoring", I3DUtil.getNodePath(v20_, self.rootNode), v19_)
						end
					end
				end
			else
				v18_ = nil
			end
			local v21_ = v11_.palletSpawner
			table.insert(v21_, {
				["palletSpawner"] = v15_,
				["maxNumPallets"] = v14_,
				["palletTriggers"] = v18_
			})
		end
	end
	v11_.palletLimitReached = false
	v11_.infoHudTooManyPallets = {
		["title"] = g_i18n:getText("infohud_tooManyPallets"),
		["accentuate"] = true
	}
	v11_.dirtyFlag = self:getNextDirtyFlag()
	local v22_ = self:getAnimalTypeIndex()
	local v23_ = g_currentMission.animalSystem:getTypeByIndex(v22_)
	if v23_ ~= nil then
		for _, v24_ in ipairs(v23_.subTypes) do
			local v25_ = g_currentMission.animalSystem:getSubTypeByIndex(v24_)
			if v25_.output ~= nil then
				local v26_ = v25_.output.pallets
				if v26_ ~= nil and v11_.litersPerHour[v26_.fillType] == nil then
					Logging.xmlWarning(self.xmlFile, "Husbandry does not support pallet filltype \'%s\'", g_fillTypeManager:getFillTypeNameByIndex(v26_.fillType))
				end
			end
		end
	end
end

-- Local values: spec, _, info, _, trigger
function PlaceableHusbandryPallets:onDelete()
	local v28_ = self.spec_husbandryPallets
	if v28_.palletSpawner ~= nil then
		for _, v29_ in ipairs(v28_.palletSpawner) do
			v29_.palletSpawner:delete()
			if v29_.palletTriggers ~= nil then
				for _, v30_ in ipairs(v29_.palletTriggers) do
					if v30_.added then
						removeTrigger(v30_.node)
					end
				end
			end
		end
	end
end

-- Local values: spec, _, info, _, trigger
function PlaceableHusbandryPallets:onFinalizePlacement()
	local v32_ = self.spec_husbandryPallets
	if v32_.palletSpawner ~= nil then
		for _, v33_ in ipairs(v32_.palletSpawner) do
			if v33_.palletTriggers ~= nil then
				for _, v34_ in ipairs(v33_.palletTriggers) do
					addTrigger(v34_.node, "onPalletTriggerCallback", self)
					v34_.added = true
				end
			end
		end
	end
end

-- Local values: spec, _, fillTypeIndex
function PlaceableHusbandryPallets:onReadStream(streamId, connection)
	local v37_ = self.spec_husbandryPallets
	for _, v38_ in ipairs(v37_.fillTypes) do
		v37_.fillLevelsSent[v38_] = streamReadFloat32(streamId)
		v37_.capacitiesSent[v38_] = streamReadFloat32(streamId)
	end
	v37_.palletLimitReached = streamReadBool(streamId)
end

-- Local values: spec, _, fillTypeIndex
function PlaceableHusbandryPallets:onWriteStream(streamId, connection)
	local v41_ = self.spec_husbandryPallets
	for _, v42_ in ipairs(v41_.fillTypes) do
		streamWriteFloat32(streamId, v41_.fillLevelsSent[v42_])
		streamWriteFloat32(streamId, v41_.capacitiesSent[v42_])
	end
	streamWriteBool(streamId, v41_.palletLimitReached)
end

-- Local values: spec, _, fillTypeIndex
function PlaceableHusbandryPallets:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v46_ = self.spec_husbandryPallets
		for _, v47_ in ipairs(v46_.fillTypes) do
			v46_.fillLevelsSent[v47_] = streamReadFloat32(streamId)
			v46_.capacitiesSent[v47_] = streamReadFloat32(streamId)
		end
		v46_.palletLimitReached = streamReadBool(streamId)
	end
end

-- Local values: spec, _, fillTypeIndex
function PlaceableHusbandryPallets:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v52_ = self.spec_husbandryPallets
		local v53_ = streamWriteBool
		local v54_ = v52_.dirtyFlag
		if v53_(streamId, bit32.band(dirtyMask, v54_) ~= 0) then
			for _, v55_ in ipairs(v52_.fillTypes) do
				streamWriteFloat32(streamId, v52_.fillLevelsSent[v55_])
				streamWriteFloat32(streamId, v52_.capacitiesSent[v55_])
			end
			streamWriteBool(streamId, v52_.palletLimitReached)
		end
	end
end

-- Local values: spec, _, pendingKey, fillTypeIndex
function PlaceableHusbandryPallets:loadFromXMLFile(xmlFile, key)
	local v59_ = self.spec_husbandryPallets
	for _, v60_ in xmlFile:iterator(key .. ".pendingLiters") do
		local v61_ = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(v60_ .. "#fillType"))
		if v61_ ~= nil then
			v59_.pendingLiters[v61_] = xmlFile:getValue(v60_ .. "#liters") or 0
		end
	end
	self:updatePalletInfo()
end

-- Local values: spec, index, fillTypeIndex, pendingLiters, pendingKey
function PlaceableHusbandryPallets:saveToXMLFile(xmlFile, key, usedModNames)
	local v65_ = self.spec_husbandryPallets
	local v66_ = 0
	for v67_, v68_ in pairs(v65_.pendingLiters) do
		if v68_ > 0 then
			local v69_ = string.format("%s.pendingLiters(%d)", key, v66_)
			xmlFile:setValue(v69_ .. "#fillType", g_fillTypeManager:getFillTypeNameByIndex(v67_))
			xmlFile:setValue(v69_ .. "#liters", v68_)
			v66_ = v66_ + 1
		end
	end
end

-- Local values: spec, fillTypeIndex, _, _, cluster, subType, pallets, age, litersPerAnimals, litersPerDay
function PlaceableHusbandryPallets:onHusbandryAnimalsUpdate(clusters)
	local v72_ = self.spec_husbandryPallets
	for v73_, _ in pairs(v72_.litersPerHour) do
		v72_.litersPerHour[v73_] = 0
	end
	v72_.activeFillTypes = {}
	for _, v74_ in ipairs(clusters) do
		local v75_ = g_currentMission.animalSystem:getSubTypeByIndex(v74_.subTypeIndex)
		if v75_ ~= nil then
			local v76_ = v75_.output.pallets
			if v76_ ~= nil then
				local v77_ = v74_:getAge()
				local v78_ = v76_.curve:get(v77_) * v74_:getNumAnimals()
				v72_.litersPerHour[v76_.fillType] = v72_.litersPerHour[v76_.fillType] + v78_ / 24
				table.addElement(v72_.activeFillTypes, v76_.fillType)
			end
		end
	end
end

-- Local values: spec, object, fillTypeIndex, pallet
function PlaceableHusbandryPallets:onPalletTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onLeave then
		local v82_ = self.spec_husbandryPallets
		local v83_ = g_currentMission:getNodeObject(otherId)
		if v83_ ~= nil then
			for v84_, v85_ in pairs(v82_.currentPallets) do
				if v83_ == v85_ then
					v82_.currentPallets[v84_] = nil
				end
			end
			v82_.pallets[v83_] = nil
			self:updatePalletInfo()
		end
	end
end

-- Local values: spec, fillTypeIndex, fillTypeIndex, palletSpawner
function PlaceableHusbandryPallets:updatePalletInfo()
	if self.isServer then
		local v87_ = self.spec_husbandryPallets
		if v87_.numPalletInfoUpdateRunning == 0 then
			for v88_ in pairs(v87_.capacitiesPending) do
				v87_.fillLevelsPending[v88_] = 0
				v87_.capacitiesPending[v88_] = 0
				v87_.maxCapacitiesPending[v88_] = 0
			end
			for v89_, v90_ in pairs(v87_.fillTypeIndexToPalletSpawner) do
				v87_.numPalletInfoUpdateRunning = v87_.numPalletInfoUpdateRunning + 1
				v90_:getAllPallets(v89_, self.getAllPalletsCallback, self)
			end
		end
	end
end

-- Local values: spec, _, pallet, fillUnitIndex, palletCapacity, fillTypeIndex, _, capacity
function PlaceableHusbandryPallets:getAllPalletsCallback(pallets, fillTypeIndex)
	local v94_ = self.spec_husbandryPallets
	local v95_ = v94_.numPalletInfoUpdateRunning - 1
	v94_.numPalletInfoUpdateRunning = math.max(v95_, 0)
	for _, v96_ in pairs(pallets) do
		local v97_ = v96_.spec_pallet.fillUnitIndex
		local v98_ = v96_:getFillUnitCapacity(v97_)
		v94_.capacitiesPending[fillTypeIndex] = v94_.capacitiesPending[fillTypeIndex] + v98_
		v94_.fillLevelsPending[fillTypeIndex] = v94_.fillLevelsPending[fillTypeIndex] + v96_:getFillUnitFillLevel(v97_)
		local v99_ = v94_.maxCapacitiesPending
		local v100_ = v94_.maxCapacitiesPending[fillTypeIndex]
		v99_[fillTypeIndex] = math.max(v100_, v98_)
	end
	if v94_.numPalletInfoUpdateRunning > 0 then
		::l5::
		return
	end
	for v101_, _ in pairs(v94_.fillLevels) do
		v94_.fillLevels[v101_] = v94_.fillLevelsPending[v101_]
		local v102_ = v94_.capacitiesPending[v101_]
		if #pallets < v94_.maxNumPallets[v101_] then
			v102_ = v94_.maxCapacitiesPending[v101_] * v94_.maxNumPallets[v101_]
		end
		v94_.capacities[v101_] = v102_
		local v103_ = v94_.fillLevels[v101_] - v94_.fillLevelsSent[v101_]
		if math.abs(v103_) > 1 then
			::l11::
			v94_.fillLevelsSent[v101_] = v94_.fillLevels[v101_]
			v94_.capacitiesSent[v101_] = v94_.capacities[v101_]
			self:raiseDirtyFlags(v94_.dirtyFlag)
		else
			local v104_ = v94_.capacities[v101_] - v94_.capacitiesSent[v101_]
			if math.abs(v104_) > 1 then
				goto l11
			end
		end
	end
	goto l5
end

-- Local values: spec, fillTypeIndex, pendingLiters, palletSpawner
function PlaceableHusbandryPallets:updatePallets()
	if self.isServer then
		local v106_ = self.spec_husbandryPallets
		if v106_.numSpawnsPending == 0 then
			for v107_, v108_ in pairs(v106_.pendingLiters) do
				if v108_ > 5 then
					local v109_ = v106_.fillTypeIndexToPalletSpawner[v107_]
					v106_.numSpawnsPending = v106_.numSpawnsPending + 1
					v109_:getOrSpawnPallet(self:getOwnerFarmId(), v107_, self.getPalletCallback, self)
				end
			end
		end
	end
end

-- Local values: spec
function PlaceableHusbandryPallets:addPendingLiters(fillTypeIndex, liters)
	if not self.isServer then
		return 0
	end
	if liters <= 0 then
		return 0
	end
	local v113_ = self.spec_husbandryPallets
	if v113_.pendingLiters[fillTypeIndex] == nil then
		return 0
	end
	v113_.pendingLiters[fillTypeIndex] = v113_.pendingLiters[fillTypeIndex] + liters
	self:updatePallets()
	return liters
end

-- Local values: spec, fillUnitIndex, pendingLiters, delta
function PlaceableHusbandryPallets:getPalletCallback(pallet, result, fillTypeIndex)
	local v118_ = self.spec_husbandryPallets
	local v119_ = v118_.numSpawnsPending - 1
	v118_.numSpawnsPending = math.max(v119_, 0)
	v118_.currentPallets[fillTypeIndex] = pallet
	if pallet == nil then
		if result == PalletSpawner.RESULT_NO_SPACE then
			self:showSpawnerBlockedWarning(fillTypeIndex)
		elseif result == PalletSpawner.PALLET_LIMITED_REACHED and not v118_.palletLimitReached then
			v118_.palletLimitReached = true
			self:raiseDirtyFlags(v118_.dirtyFlag)
		end
	else
		if v118_.palletLimitReached then
			v118_.palletLimitReached = false
			self:raiseDirtyFlags(v118_.dirtyFlag)
		end
		if result == PalletSpawner.RESULT_SUCCESS then
			pallet:emptyAllFillUnits(true)
		end
		v118_.pallets[pallet] = true
		local v120_ = pallet.spec_pallet.fillUnitIndex
		local v121_ = v118_.pendingLiters[fillTypeIndex]
		local v122_ = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), v120_, v121_, fillTypeIndex, ToolType.UNDEFINED)
		if v122_ > 0 then
			local v123_ = v118_.pendingLiters
			local v124_ = v118_.pendingLiters[fillTypeIndex] - v122_
			v123_[fillTypeIndex] = math.max(v124_, 0)
			if v118_.pendingLiters[fillTypeIndex] > 5 then
				self:updatePallets()
			end
		end
	end
	self:updatePalletInfo()
end

-- Local values: spec
function PlaceableHusbandryPallets:showSpawnerBlockedWarning(fillTypeIndex)
	local v127_ = self.spec_husbandryPallets
	if not v127_.showedWarning then
		if self.isServer then
			g_currentMission:broadcastEventToFarm(AnimalHusbandryNoMorePalletSpaceEvent.new(self, fillTypeIndex), self:getOwnerFarmId(), false)
		end
		self:showPalletBlockedWarning(fillTypeIndex)
		v127_.showedWarning = true
	end
end

-- Local values: fillType, text
function PlaceableHusbandryPallets:showPalletBlockedWarning(fillTypeIndex)
	if self.isClient and g_currentMission:getFarmId() == self:getOwnerFarmId() then
		local v130_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		if v130_ ~= nil then
			local v131_ = string.format(g_i18n:getText("ingameNotification_palletSpawnerBlocked"), v130_.title, self:getName())
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, v131_)
		end
	end
end

-- Local values: spec
function PlaceableHusbandryPallets:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)
	local v135_ = self.spec_husbandryPallets
	if v135_.palletLimitReached then
		local v136_ = v135_.infoHudTooManyPallets
		table.insert(infoTable, v136_)
	end
end

-- Local values: infos, spec, _, fillTypeIndex, fillType, info, fillLevel, capacity, ratio
function PlaceableHusbandryPallets:getConditionInfos(superFunc)
	local v139_ = superFunc(self)
	local v140_ = self.spec_husbandryPallets
	for _, v141_ in ipairs(v140_.activeFillTypes) do
		local v142_ = g_fillTypeManager:getFillTypeByIndex(v141_)
		if v142_ ~= nil then
			local v143_ = {}
			local v144_ = v140_.fillLevels[v141_]
			local v145_ = v140_.capacities[v141_]
			v143_.title = v142_.title
			v143_.value = v144_
			local v146_ = v145_ <= 0 and 0 or v144_ / v145_
			v143_.ratio = math.clamp(v146_, 0, 1)
			v143_.invertedBar = true
			v143_.customUnitText = v140_.fillTypeUnit
			table.insert(v139_, v143_)
		end
	end
	return v139_
end

-- Local values: spec, _, fillTypeIndex, litersPerHour, delta
function PlaceableHusbandryPallets:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
	local v152_ = self.spec_husbandryPallets
	v152_.showedWarning = false
	if self.isServer then
		for _, v153_ in ipairs(v152_.fillTypes) do
			local v154_ = v152_.litersPerHour[v153_]
			if v154_ > 0 then
				local v155_ = productionFactor * globalProductionFactor * v154_ * g_currentMission.environment.timeAdjustment
				v152_.pendingLiters[v153_] = v152_.pendingLiters[v153_] + v155_
				self:updatePallets()
			end
		end
	end
end
