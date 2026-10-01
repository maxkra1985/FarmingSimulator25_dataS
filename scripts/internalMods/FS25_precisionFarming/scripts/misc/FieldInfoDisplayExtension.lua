FieldInfoDisplayExtension = {}
FieldInfoDisplayExtension.MOD_NAME = g_currentModName
local FieldInfoDisplayExtension_mt = Class(FieldInfoDisplayExtension)
function FieldInfoDisplayExtension.new(precisionFarming, customMt)
	local self = setmetatable({}, customMt or FieldInfoDisplayExtension_mt)
	self.precisionFarming = precisionFarming
	self.fieldInfos = {}
	self.texts = {}
	self.texts.boxTitle = g_i18n:getText("ui_header")
	self.texts.expectedYield = g_i18n:getText("fieldInfo_expectedYield")
	self.texts.yieldPotential = g_i18n:getText("fieldInfo_yieldPotential")
	return self
end
function FieldInfoDisplayExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	self.precisionFarming:collectFieldInfos(self)
	return true
end
function FieldInfoDisplayExtension:delete() end
function FieldInfoDisplayExtension:addFieldInfo(text, object, updateFunc, prio, yieldChangeFunc)
	local fieldInfo = { text = text, object = object, updateFunc = updateFunc, yieldChangeFunc = yieldChangeFunc, value = nil, color = nil, additionalText = nil, showWarning = nil }
	table.insert(self.fieldInfos, fieldInfo)
end
function FieldInfoDisplayExtension:infoBoxAddData(func, funcTarget, fieldInfo)
	for i = 1, #self.fieldInfos do
		local fieldInfo = self.fieldInfos[i]
		if fieldInfo.value == nil then
			continue
		end
		if fieldInfo.additionalText ~= nil then
			func(funcTarget, string.format(fieldInfo.text .. " (%s)", fieldInfo.additionalText), fieldInfo.value, fieldInfo.showWarning, fieldInfo.color)
		else
			func(funcTarget, fieldInfo.text, fieldInfo.value, fieldInfo.showWarning, fieldInfo.color)
		end
	end
end
function FieldInfoDisplayExtension:infoBoxAddYieldData(func, funcTarget, fieldInfo)
	local fruitTypeIndex = fieldInfo.fruitTypeIndex
	local fruitGrowthState = fieldInfo.growthState
	local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	if fruitType == nil then
		return
	else
		local maxGrowingState = fruitType.minHarvestingGrowthState - 1
		if 0 <= fruitType.minPreparingGrowthState then
			maxGrowingState = math.min(maxGrowingState, fruitType.minPreparingGrowthState - 1)
		end
		local isGrowing = false
		if 0 < fruitGrowthState then
			if fruitGrowthState <= maxGrowingState then
				isGrowing = true
			elseif 0 <= fruitType.minPreparingGrowthState then
				if fruitType.minPreparingGrowthState <= fruitGrowthState then
					if fruitGrowthState <= fruitType.maxPreparingGrowthState then
						isGrowing = true
					elseif fruitType.minHarvestingGrowthState <= fruitGrowthState then
						if fruitGrowthState <= fruitType.maxHarvestingGrowthState then
							isGrowing = true
						end
					end
				end
			end
		end
		if isGrowing then
			local _, plowFactor, _, weedFactor, stubbleFactor, rollerFactor = fieldInfo:getHarvestScaleFactors()
			local harvestMultiplier = 0
			harvestMultiplier = harvestMultiplier + plowFactor * 0.1
			harvestMultiplier = harvestMultiplier + weedFactor * 0.15
			harvestMultiplier = harvestMultiplier + stubbleFactor * 0.025
			harvestMultiplier = harvestMultiplier + rollerFactor * 0.025
			local yieldPotential = nil
			local yieldPotentialToHa = nil
			local yieldPotentialFactor = nil
			local yieldPotentialFactorBest = nil
			for i = 1, #self.fieldInfos do
				local fieldInfo = self.fieldInfos[i]
				if fieldInfo.yieldChangeFunc == nil then
					continue
				end
				local factor, proportion, _yieldPotential, _yieldPotentialToHa, _yieldPotentialFactor, _yieldPotentialFactorBest = fieldInfo.yieldChangeFunc(fieldInfo.object, fieldInfo)
				harvestMultiplier = harvestMultiplier + factor * proportion
				yieldPotential = _yieldPotential or yieldPotential
				yieldPotentialToHa = _yieldPotentialToHa or yieldPotentialToHa
				yieldPotentialFactor = _yieldPotentialFactor or yieldPotentialFactor
				yieldPotentialFactorBest = _yieldPotentialFactorBest or yieldPotentialFactorBest
			end
			if yieldPotential ~= nil and 0 < yieldPotential then
				harvestMultiplier = math.ceil(50 + harvestMultiplier * 50) / 100
				local expectedYield = harvestMultiplier * yieldPotential * (yieldPotentialFactor or 1)
				local expectedYieldToHa = harvestMultiplier * yieldPotentialToHa * (yieldPotentialFactor or 1)
				local expectedYieldBest = yieldPotential * (yieldPotentialFactorBest or 1)
				local expectedYieldBestToHa = yieldPotentialToHa * (yieldPotentialFactorBest or 1)
				if yieldPotentialToHa ~= 0 then
					func(funcTarget, self.texts.expectedYield, string.format("%d %% | %.1f to/ha", expectedYield * 100, expectedYieldToHa))
					func(funcTarget, self.texts.yieldPotential, string.format("%d %% | %.1f to/ha", expectedYieldBest * 100, expectedYieldBestToHa))
					return
				end
				func(funcTarget, self.texts.expectedYield, string.format("%d %%", expectedYield * 100))
				func(funcTarget, self.texts.yieldPotential, string.format("%d %%", expectedYieldBest * 100))
			end
		end
	end
end
function FieldInfoDisplayExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "new", function(superFunc, ...)
		local hudUpdater = superFunc(...)
		hudUpdater.precisionFarmingBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayBoxPrecisionFarming)
		hudUpdater.precisionFarmingBox:setTitle(self.texts.boxTitle)
		return hudUpdater
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "delete", function(superFunc, hudUpdater, ...)
		g_currentMission.hud.infoDisplay:destroyBox(hudUpdater.precisionFarmingBox)
		return superFunc(hudUpdater, ...)
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "showFieldInfo", function(superFunc, hudUpdater, posX, posY, posZ)
		superFunc(hudUpdater, posX, posY, posZ)
		local fieldInfo = hudUpdater.fieldInfo
		if fieldInfo.groundType == FieldGroundType.NONE then
			return
		else
			local box = hudUpdater.precisionFarmingBox
			box:clear()
			box:setTitle(self.texts.boxTitle)
			self:infoBoxAddData(box.addLine, box, fieldInfo)
			self:infoBoxAddYieldData(box.addLine, box, fieldInfo)
			box:showNextFrame()
		end
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "fieldAddField", function(superFunc, hudUpdater, fieldInfo, box)
		superFunc(hudUpdater, fieldInfo, box)
		for _, line in ipairs(box.lines) do
			if line.isActive and (line.key == g_i18n:getText("fieldInfo_yieldBonus") or line.key == g_i18n:getText("ui_growthMapFertilized")) then
				line.isActive = false
			end
		end
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "fieldAddFieldActions", function(superFunc, hudUpdater, fieldInfo, box)
		superFunc(hudUpdater, fieldInfo, box)
		for _, line in ipairs(box.lines) do
			if line.isActive and line.key == g_i18n:getText("ui_growthMapNeedsLime") then
				line.isActive = false
			end
		end
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "update", function(superFunc, hudUpdater, dt, x, y, z, rotY)
		superFunc(hudUpdater, dt, x, y, z, rotY)
		local isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
		for i = 1, #self.fieldInfos do
			local fieldInfo = self.fieldInfos[i]
			fieldInfo.value, fieldInfo.color, fieldInfo.additionalText, fieldInfo.showWarning = fieldInfo.updateFunc(fieldInfo.object, fieldInfo, x, z, isColorBlindMode)
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "updateFieldInfoBox", function(superFunc, _self, screenX, screenY)
		local localX, localY = _self.ingameMap:getLocalPosition(screenX, screenY)
		local worldX, worldZ = _self.ingameMap:localToWorldPos(localX, localY)
		if _self.fieldInfo == nil then
			_self.fieldInfo = FieldState.new()
		end
		local fieldInfo = _self.fieldInfo
		fieldInfo:update(worldX, worldZ)
		if fieldInfo.groundType == FieldGroundType.NONE then
			return false
		else
			for i = 1, #self.fieldInfos do
				local pfFieldInfo = self.fieldInfos[i]
				pfFieldInfo.value, pfFieldInfo.color, pfFieldInfo.additionalText, pfFieldInfo.showWarning = pfFieldInfo.updateFunc(pfFieldInfo.object, pfFieldInfo, worldX, worldZ, false)
			end
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
			_self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_farmland"), tostring(fieldInfo.farmlandId))
			if Platform.playerInfo.showNPCNames then
				_self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), farmName)
			elseif ownedByYou then
				_self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_owned"))
			else
				_self:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_notOwned"))
			end
			local fruitTypeIndex = fieldInfo.fruitTypeIndex
			local growthState = fieldInfo.growthState
			local isGrowing = false
			if fruitTypeIndex ~= FruitType.UNKNOWN then
				local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
				_self:addFieldInfoKeyValue(g_i18n:getText("statistic_fillType"), fruitTypeDesc.fillType.title)
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
					_self:addFieldInfoKeyValue(g_i18n:getText("ui_mapOverviewGrowth"), text)
				end
			end
			self:infoBoxAddData(_self.addFieldInfoKeyValue, _self, fieldInfo)
			if isGrowing then
				self:infoBoxAddYieldData(_self.addFieldInfoKeyValue, _self, fieldInfo)
			end
			if g_currentMission.missionInfo.weedsEnabled then
				local weedSystem = g_currentMission.weedSystem
				local fieldInfoStates = weedSystem:getFieldInfoStates()
				local weedState = fieldInfo.weedState
				local toolName = nil
				if 0 < weedState then
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
						_self:addFieldInfoKeyValue(title, toolName or "")
					end
				end
			end
			return true
		end
	end)
end
