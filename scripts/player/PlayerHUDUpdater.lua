PlayerHUDUpdater = {}
local PlayerHUDUpdater_mt = Class(PlayerHUDUpdater)
function PlayerHUDUpdater.new()
	local self = setmetatable({}, PlayerHUDUpdater_mt)
	self.object = nil
	self.splitShape = nil
	self.isBale = false
	self.isVehicle = false
	self.isPallet = false
	self.isSplitShape = false
	self.isAnimal = false
	local infoDisplay = g_currentMission.hud.infoDisplay
	if Platform.isMobile then
		self.fieldBox = infoDisplay:createBox(InfoDisplayKeyValueBoxMobile)
		self.objectBox = infoDisplay:createBox(InfoDisplayKeyValueBoxMobile)
	else
		self.fieldBox = infoDisplay:createBox(InfoDisplayKeyValueBox)
		self.objectBox = infoDisplay:createBox(InfoDisplayKeyValueBox)
	end
	self.fieldInfo = FieldState.new()
	return self
end
function PlayerHUDUpdater:delete()
	local infoDisplay = g_currentMission.hud.infoDisplay
	infoDisplay:destroyBox(self.fieldBox)
	infoDisplay:destroyBox(self.objectBox)
end
function PlayerHUDUpdater:update(dt, x, y, z, rotY)
	self:showFieldInfo(x, z, rotY)
	if Platform.playerInfo.showVehicleInfo then
		if self.isVehicle then
			self:showVehicleInfo(self.object)
			return
		end
		if self.isBale then
			self:showBaleInfo(self.object)
			return
		end
		if self.isPallet then
			self:showPalletInfo(self.object)
			return
		end
		if self.isSplitShape and self.splitShape ~= nil then
			self:showSplitShapeInfo(self.splitShape)
			return
		end
		if self.isAnimal then
			self:showAnimalInfo(self.object)
		end
	end
end
function PlayerHUDUpdater:setCurrentRaycastTarget(node)
	if self.currentRaycastTarget ~= node then
		self.currentRaycastTarget = node
		self:updateRaycastObject()
	end
end
function PlayerHUDUpdater:updateRaycastObject()
	if self.object ~= nil and self.object.removeDeleteListener ~= nil then
		self.object:removeDeleteListener(self, PlayerHUDUpdater.onDeleteObject)
	end
	self.isBale = false
	self.isVehicle = false
	self.isPallet = false
	self.isSplitShape = false
	self.isAnimal = false
	self.object = nil
	self.splitShape = nil
	if self.currentRaycastTarget == nil or not entityExists(self.currentRaycastTarget) then
		return
	end
	local object = g_currentMission:getNodeObject(self.currentRaycastTarget)
	if object ~= nil then
		self.object = object
		if object:isa(Vehicle) then
			if object.isPallet then
				self.isPallet = true
			else
				self.isVehicle = true
			end
		elseif object:isa(Bale) then
			self.isBale = true
		end
		if self.object ~= nil and self.object.addDeleteListener ~= nil then
			self.object:addDeleteListener(self, PlayerHUDUpdater.onDeleteObject)
		end
	elseif getHasClassId(self.currentRaycastTarget, ClassIds.MESH_SPLIT_SHAPE) then
		self.isSplitShape = true
		self.splitShape = self.currentRaycastTarget
	else
		local husbandryId, animalId = getAnimalFromCollisionNode(self.currentRaycastTarget)
		if husbandryId ~= nil and husbandryId ~= 0 then
			local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandryById(husbandryId)
			if clusterHusbandry ~= nil then
				local cluster = clusterHusbandry:getClusterByAnimalId(animalId)
				if cluster ~= nil then
					self.isAnimal = true
					self.object = cluster
				end
			end
		end
	end
end
function PlayerHUDUpdater:onDeleteObject(object)
	if object == self.object then
		self.isBale = false
		self.isVehicle = false
		self.isPallet = false
		self.isSplitShape = false
		self.isAnimal = false
		self.object = nil
	end
end
function PlayerHUDUpdater:convertFarmToName(farm)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return g_i18n:getText("fieldInfo_ownerYou")
	else
		return farm.name
	end
end
function PlayerHUDUpdater:showVehicleInfo(vehicle)
	local name = vehicle:getFullName()
	local farmId = vehicle:getOwnerFarmId()
	if farmId ~= FarmManager.SPECTATOR_FARM_ID then
		local box = self.objectBox
		box:clear()
		box:setTitle(name)
		local farm = g_farmManager:getFarmById(farmId)
		if farm ~= nil then
			local propertyState = vehicle:getPropertyState()
			if propertyState == VehiclePropertyState.OWNED then
				box:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(farm))
			else
				box:addLine(g_i18n:getText("infohud_rentedBy"), self:convertFarmToName(farm))
			end
		end
		vehicle:showInfo(box)
		box:showNextFrame()
	end
end
function PlayerHUDUpdater:showBaleInfo(bale)
	local farm = g_farmManager:getFarmById(bale:getOwnerFarmId())
	local box = self.objectBox
	box:clear()
	box:setTitle(g_i18n:getText("infohud_bale"))
	if farm ~= nil then
		box:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(farm))
	end
	bale:showInfo(box)
	box:showNextFrame()
end
function PlayerHUDUpdater:showPalletInfo(pallet)
	local mass = pallet:getTotalMass()
	local farm = g_farmManager:getFarmById(pallet:getOwnerFarmId())
	local box = self.objectBox
	box:clear()
	if pallet.getInfoBoxTitle ~= nil then
		box:setTitle(pallet:getInfoBoxTitle())
	else
		box:setTitle(g_i18n:getText("infohud_pallet"))
	end
	if farm ~= nil then
		box:addLine(g_i18n:getText("fieldInfo_ownedBy"), self:convertFarmToName(farm))
	end
	box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(mass))
	pallet:showInfo(box)
	box:showNextFrame()
end
function PlayerHUDUpdater:showSplitShapeInfo(shape)
	if not entityExists(shape) or not getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE) then
		return
	end
	local splitTypeId = getSplitType(shape)
	if splitTypeId == 0 then
		return
	end
	local isSplit = getIsSplitShapeSplit(shape)
	local isStatic = getRigidBodyType(shape) == RigidBodyType.STATIC
	if isSplit and isStatic then
		return
	end
	local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(shape)
	local splitType = g_splitShapeManager:getSplitTypeByIndex(splitTypeId)
	local splitTypeName = splitType and splitType.title
	local length = math.max(sizeX, sizeY, sizeZ)
	if math.abs(length) == math.huge then
		return
	else
		local box = self.objectBox
		box:clear()
		if isSplit then
			box:setTitle(g_i18n:getText("infohud_wood"))
		else
			box:setTitle(g_i18n:getText("infohud_tree"))
		end
		if splitTypeName ~= nil then
			box:addLine(g_i18n:getText("infohud_type"), splitTypeName)
		end
		box:addLine(g_i18n:getText("infohud_length"), g_i18n:formatNumber(length, 1) .. " m")
		if g_currentMission:getIsServer() and not isStatic then
			local mass = getMass(shape)
			box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(mass))
		end
		box:showNextFrame()
	end
end
function PlayerHUDUpdater:showAnimalInfo(cluster)
	local box = self.objectBox
	box:clear()
	box:setTitle(g_i18n:getText("infohud_animal"))
	cluster:showInfo(box)
	box:showNextFrame()
end
function PlayerHUDUpdater:onFieldDataUpdateFinished(data)
	if self.requestedFieldData then
		self.fieldData = data
		self.fieldInfoNeedsRebuild = true
	end
	self.requestedFieldData = false
end
function PlayerHUDUpdater:showFieldInfo(posX, posZ, rotY)
	local fieldInfo = self.fieldInfo
	local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
	local distance = 2
	local x = posX + dirX * 2
	local z = posZ + dirZ * 2
	fieldInfo:update(x, z)
	if fieldInfo.groundType == FieldGroundType.NONE then
		return
	else
		local box = self.fieldBox
		box:clear()
		box:setTitle(g_i18n:getText("ui_fieldInfo"))
		self:fieldAddFarmland(fieldInfo, box)
		self:fieldAddField(fieldInfo, box)
		self:fieldAddWeed(fieldInfo, box)
		self:fieldAddFieldActions(fieldInfo, box)
		self.fieldInfoNeedsRebuild = false
		box:showNextFrame()
	end
end
function PlayerHUDUpdater:fieldAddFarmland(fieldInfo, box)
	local farmName = nil
	local ownedByYou = false
	local ownerFarmId = fieldInfo.ownerFarmId
	if ownerFarmId == g_currentMission:getFarmId() then
		if ownerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
			farmName = g_i18n:getText("fieldInfo_ownerYou")
			ownedByYou = true
		elseif ownerFarmId == AccessHandler.EVERYONE or ownerFarmId == AccessHandler.NOBODY then
			local farmland = g_farmlandManager:getFarmlandById(fieldInfo.farmlandId)
			if farmland == nil then
				farmName = g_i18n:getText("fieldInfo_ownerNobody")
			else
				local npc = farmland:getNPC()
				farmName = npc ~= nil and npc.title or "Unknown"
			end
		else
			local farm = g_farmManager:getFarmById(ownerFarmId)
			farmName = farm ~= nil and farm.name or "Unknown"
		end
	end
	box:addLine(g_i18n:getText("fieldInfo_farmland"), tostring(fieldInfo.farmlandId))
	if Platform.playerInfo.showNPCNames then
		box:addLine(g_i18n:getText("fieldInfo_ownedBy"), farmName)
	elseif ownedByYou then
		box:addLine(g_i18n:getText("fieldInfo_owned"))
	else
		box:addLine(g_i18n:getText("fieldInfo_notOwned"))
	end
end
function PlayerHUDUpdater:fieldAddField(fieldInfo, box)
	local fruitTypeIndex = fieldInfo.fruitTypeIndex
	local growthState = fieldInfo.growthState
	local isGrowing = false
	if fruitTypeIndex ~= FruitType.UNKNOWN then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		box:addLine(g_i18n:getText("statistic_fillType"), fruitTypeDesc.fillType.title)
		local text = nil
		if fruitTypeDesc:getIsCut(growthState) then
			text = g_i18n:getText("ui_growthMapCut")
		elseif fruitTypeDesc:getIsWithered(growthState) then
			text = g_i18n:getText("ui_growthMapWithered")
		elseif fruitTypeDesc:getIsGrowing(growthState) then
			text = g_i18n:getText("ui_growthMapGrowing")
			isGrowing = true
		elseif fruitTypeDesc:getIsPreparable(growthState) then
			text = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
			isGrowing = true
		elseif fruitTypeDesc:getIsHarvestable(growthState) then
			text = g_i18n:getText("ui_growthMapReadyToHarvest")
			isGrowing = true
		end
		if text ~= nil then
			box:addLine(g_i18n:getText("ui_mapOverviewGrowth"), text)
		end
	end
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	if isGrowing then
		local harvestMultiplier = fieldInfo:getHarvestScaleMultiplier()
		harvestMultiplier = harvestMultiplier - 1
		harvestMultiplier = MathUtil.round(harvestMultiplier * 100)
		box:addLine(g_i18n:getText("fieldInfo_yieldBonus"), string.format("+ %d %%", harvestMultiplier))
	end
	if 0 <= fieldInfo.sprayLevel then
		local sprayLevelMax = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local sprayFactor = fieldInfo.sprayLevel / sprayLevelMax
		box:addLine(g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", sprayFactor * 100))
	end
end
function PlayerHUDUpdater:fieldAddFieldActions(fieldInfo, box)
	local missionInfo = g_currentMission.missionInfo
	if Platform.gameplay.useLimeCounter and (missionInfo.limeRequired and fieldInfo.limeLevel == 0) then
		box:addLine(g_i18n:getText("ui_growthMapNeedsLime"), nil, true)
	end
	if fieldInfo.plowLevel == 0 and missionInfo.plowingRequiredEnabled then
		box:addLine(g_i18n:getText("ui_growthMapNeedsPlowing"), nil, true)
	end
	if Platform.gameplay.useRolling and 0 < fieldInfo.rollerLevel then
		box:addLine(g_i18n:getText("ui_growthMapNeedsRolling"), nil, true)
	end
end
function PlayerHUDUpdater:fieldAddWeed(fieldInfo, box)
	if not g_currentMission.missionInfo.weedsEnabled then
		return
	end
	local weedSystem = g_currentMission.weedSystem
	local fieldInfoStates = weedSystem:getFieldInfoStates()
	local weedState = fieldInfo.weedState
	local fruitTypeIndex = fieldInfo.fruitTypeIndex or FruitType.UNKNOWN
	local growthState = fieldInfo.growthState or 0
	local toolName = nil
	if weedState == 0 then
		return
	else
		local fruitTypeDesc = nil
		if fruitTypeIndex ~= nil then
			fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		end
		if Platform.gameplay.hasWeeder then
			if fruitTypeDesc == nil or fruitTypeDesc:getIsWeedable(growthState) then
				local weederReplacements = weedSystem:getWeederReplacements(false)
				local weed = weederReplacements.weed
				local targetState = weed.replacements[weedState]
				if targetState == 0 then
					toolName = g_i18n:getText("weed_destruction_weeder")
				end
			end
			if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsHoeable(growthState)) then
				local hoeReplacements = weedSystem:getWeederReplacements(true)
				local weed = hoeReplacements.weed
				local targetState = weed.replacements[weedState]
				if targetState == 0 then
					toolName = g_i18n:getText("weed_destruction_hoe")
				end
			end
		end
		if toolName == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsGrowing(growthState)) then
			toolName = g_i18n:getText("weed_destruction_herbicide")
		end
		local title = fieldInfoStates[weedState]
		if title ~= nil then
			box:addLine(title, toolName or "", true)
		end
	end
end
