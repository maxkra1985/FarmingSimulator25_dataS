-- Local values: FieldInfoDisplayExtension_mt
FieldInfoDisplayExtension = {}
FieldInfoDisplayExtension.MOD_NAME = g_currentModName
local FieldInfoDisplayExtension_mt = Class(FieldInfoDisplayExtension)

-- Upvalues: FieldInfoDisplayExtension_mt
-- Local values: self
function FieldInfoDisplayExtension.new(precisionFarming, customMt)
	-- upvalues: (copy) FieldInfoDisplayExtension_mt
	local v4_ = customMt or FieldInfoDisplayExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.fieldInfos = {}
	v5_.texts = {}
	v5_.texts.boxTitle = g_i18n:getText("ui_header")
	v5_.texts.expectedYield = g_i18n:getText("fieldInfo_expectedYield")
	v5_.texts.yieldPotential = g_i18n:getText("fieldInfo_yieldPotential")
	return v5_
end

function FieldInfoDisplayExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	self.precisionFarming:collectFieldInfos(self)
	return true
end

function FieldInfoDisplayExtension:delete() end

-- Local values: fieldInfo
function FieldInfoDisplayExtension:addFieldInfo(text, object, updateFunc, prio, yieldChangeFunc)
	local v12_ = self.fieldInfos
	table.insert(v12_, {
		["text"] = text,
		["object"] = object,
		["updateFunc"] = updateFunc,
		["yieldChangeFunc"] = yieldChangeFunc,
		["value"] = nil,
		["color"] = nil,
		["additionalText"] = nil,
		["showWarning"] = nil
	})
end

-- Local values: i, fieldInfo
function FieldInfoDisplayExtension:infoBoxAddData(func, funcTarget, fieldInfo)
	for v16_ = 1, #self.fieldInfos do
		local v17_ = self.fieldInfos[v16_]
		if v17_.value ~= nil then
			if v17_.additionalText == nil then
				func(funcTarget, v17_.text, v17_.value, v17_.showWarning, v17_.color)
			else
				func(funcTarget, string.format(v17_.text .. " (%s)", v17_.additionalText), v17_.value, v17_.showWarning, v17_.color)
			end
		end
	end
end

-- Local values: fruitTypeIndex, fruitGrowthState, fruitType, maxGrowingState, isGrowing, _, plowFactor, _, weedFactor, stubbleFactor, rollerFactor, harvestMultiplier, yieldPotential, yieldPotentialToHa, yieldPotentialFactor, yieldPotentialFactorBest, i, fieldInfo, factor, proportion, _yieldPotential, _yieldPotentialToHa, _yieldPotentialFactor, _yieldPotentialFactorBest, expectedYield, expectedYieldToHa, expectedYieldBest, expectedYieldBestToHa
function FieldInfoDisplayExtension:infoBoxAddYieldData(func, funcTarget, fieldInfo)
	local v22_ = fieldInfo.fruitTypeIndex
	local v23_ = fieldInfo.growthState
	local v24_ = g_fruitTypeManager:getFruitTypeByIndex(v22_)
	if v24_ ~= nil then
		local v25_ = v24_.minHarvestingGrowthState - 1
		if v24_.minPreparingGrowthState >= 0 then
			local v26_ = v24_.minPreparingGrowthState - 1
			v25_ = math.min(v25_, v26_)
		end
		if v23_ > 0 and v23_ <= v25_ and true or (v24_.minPreparingGrowthState >= 0 and (v24_.minPreparingGrowthState <= v23_ and v23_ <= v24_.maxPreparingGrowthState) and true or (v24_.minHarvestingGrowthState <= v23_ and v23_ <= v24_.maxHarvestingGrowthState and true or false)) then
			local _, v27_, _, v28_, v29_, v30_ = fieldInfo:getHarvestScaleFactors()
			local v31_ = 0 + v27_ * 0.1 + v28_ * 0.15 + v29_ * 0.025 + v30_ * 0.025
			local v32_ = nil
			local v33_ = nil
			local v34_ = nil
			local v35_ = nil
			for v36_ = 1, #self.fieldInfos do
				local v37_ = self.fieldInfos[v36_]
				if v37_.yieldChangeFunc ~= nil then
					local v38_, v39_, v40_, v41_, v42_, v43_ = v37_.yieldChangeFunc(v37_.object, v37_)
					v31_ = v31_ + v38_ * v39_
					v32_ = v40_ or v32_
					v33_ = v41_ or v33_
					v34_ = v42_ or v34_
					v35_ = v43_ or v35_
				end
			end
			if v32_ ~= nil and v32_ > 0 then
				local v44_ = 50 + v31_ * 50
				local v45_ = math.ceil(v44_) / 100
				local v46_ = v45_ * v32_ * (v34_ or 1)
				local v47_ = v45_ * v33_ * (v34_ or 1)
				local v48_ = v32_ * (v35_ or 1)
				local v49_ = v33_ * (v35_ or 1)
				if v33_ ~= 0 then
					func(funcTarget, self.texts.expectedYield, string.format("%d %% | %.1f to/ha", v46_ * 100, v47_))
					func(funcTarget, self.texts.yieldPotential, string.format("%d %% | %.1f to/ha", v48_ * 100, v49_))
					return
				end
				func(funcTarget, self.texts.expectedYield, string.format("%d %%", v46_ * 100))
				func(funcTarget, self.texts.yieldPotential, string.format("%d %%", v48_ * 100))
			end
		end
	end
end

function FieldInfoDisplayExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "new", function(p52_, ...)
		-- upvalues: (copy) self
		local v53_ = p52_(...)
		v53_.precisionFarmingBox = g_currentMission.hud.infoDisplay:createBox(InfoDisplayBoxPrecisionFarming)
		v53_.precisionFarmingBox:setTitle(self.texts.boxTitle)
		return v53_
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "delete", function(p54_, p55_, ...)
		g_currentMission.hud.infoDisplay:destroyBox(p55_.precisionFarmingBox)
		return p54_(p55_, ...)
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "showFieldInfo", function(p56_, p57_, p58_, p59_, p60_)
		-- upvalues: (copy) self
		p56_(p57_, p58_, p59_, p60_)
		local v61_ = p57_.fieldInfo
		if v61_.groundType ~= FieldGroundType.NONE then
			local v62_ = p57_.precisionFarmingBox
			v62_:clear()
			v62_:setTitle(self.texts.boxTitle)
			self:infoBoxAddData(v62_.addLine, v62_, v61_)
			self:infoBoxAddYieldData(v62_.addLine, v62_, v61_)
			v62_:showNextFrame()
		end
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "fieldAddField", function(p63_, p64_, p65_, p66_)
		p63_(p64_, p65_, p66_)
		for _, v67_ in ipairs(p66_.lines) do
			if v67_.isActive and (v67_.key == g_i18n:getText("fieldInfo_yieldBonus") or v67_.key == g_i18n:getText("ui_growthMapFertilized")) then
				v67_.isActive = false
			end
		end
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "fieldAddFieldActions", function(p68_, p69_, p70_, p71_)
		p68_(p69_, p70_, p71_)
		for _, v72_ in ipairs(p71_.lines) do
			if v72_.isActive and v72_.key == g_i18n:getText("ui_growthMapNeedsLime") then
				v72_.isActive = false
			end
		end
	end)
	pfModule:overwriteGameFunction(PlayerHUDUpdater, "update", function(p73_, p74_, p75_, p76_, p77_, p78_, p79_)
		-- upvalues: (copy) self
		p73_(p74_, p75_, p76_, p77_, p78_, p79_)
		local v80_ = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
		for v81_ = 1, #self.fieldInfos do
			local v82_ = self.fieldInfos[v81_]
			local v83_, v84_, v85_, v86_ = v82_.updateFunc(v82_.object, v82_, p76_, p78_, v80_)
			v82_.value = v83_
			v82_.color = v84_
			v82_.additionalText = v85_
			v82_.showWarning = v86_
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "updateFieldInfoBox", function(_, p87_, p88_, p89_)
		-- upvalues: (copy) self
		local v90_, v91_ = p87_.ingameMap:getLocalPosition(p88_, p89_)
		local v92_, v93_ = p87_.ingameMap:localToWorldPos(v90_, v91_)
		if p87_.fieldInfo == nil then
			p87_.fieldInfo = FieldState.new()
		end
		local v94_ = p87_.fieldInfo
		v94_:update(v92_, v93_)
		if v94_.groundType == FieldGroundType.NONE then
			return false
		end
		for v95_ = 1, #self.fieldInfos do
			local v96_ = self.fieldInfos[v95_]
			local v97_, v98_, v99_, v100_ = v96_.updateFunc(v96_.object, v96_, v92_, v93_, false)
			v96_.value = v97_
			v96_.color = v98_
			v96_.additionalText = v99_
			v96_.showWarning = v100_
		end
		local v101_ = false
		local v102_ = v94_.ownerFarmId
		local v103_
		if v102_ == g_currentMission:getFarmId() and v102_ ~= FarmManager.SPECTATOR_FARM_ID then
			v103_ = g_i18n:getText("fieldInfo_ownerYou")
			v101_ = true
		elseif v102_ == AccessHandler.EVERYONE or v102_ == AccessHandler.NOBODY then
			local v104_ = g_farmlandManager:getFarmlandById(v94_.farmlandId)
			if v104_ == nil then
				v103_ = g_i18n:getText("fieldInfo_ownerNobody")
			else
				local v105_ = v104_:getNPC()
				v103_ = v105_ ~= nil and v105_.title or "Unknown"
			end
		else
			local v106_ = g_farmManager:getFarmById(v102_)
			if v106_ == nil then
				v103_ = "Unknown"
			else
				v103_ = v106_.name
			end
		end
		local v107_ = g_i18n:getText("fieldInfo_farmland")
		local v108_ = v94_.farmlandId
		p87_:addFieldInfoKeyValue(v107_, (tostring(v108_)))
		if Platform.playerInfo.showNPCNames then
			p87_:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), v103_)
		elseif v101_ then
			p87_:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_owned"))
		else
			p87_:addFieldInfoKeyValue(g_i18n:getText("fieldInfo_ownedBy"), g_i18n:getText("fieldInfo_notOwned"))
		end
		local v109_ = v94_.fruitTypeIndex
		local v110_ = v94_.growthState
		local v111_ = false
		if v109_ ~= FruitType.UNKNOWN then
			local v112_ = g_fruitTypeManager:getFruitTypeByIndex(v109_)
			p87_:addFieldInfoKeyValue(g_i18n:getText("statistic_fillType"), v112_.fillType.title)
			local v113_ = nil
			if v112_:getIsCut(v110_) then
				v113_ = g_i18n:getText("ui_growthMapCut")
			elseif v112_:getIsWithered(v110_) then
				v113_ = g_i18n:getText("ui_growthMapWithered")
			elseif v112_:getIsGrowing(v110_) then
				v113_ = g_i18n:getText("ui_growthMapGrowing")
				v111_ = true
			elseif v112_:getIsPreparable(v110_) then
				v113_ = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
				v111_ = true
			elseif v112_:getIsHarvestable(v110_) then
				v113_ = g_i18n:getText("ui_growthMapReadyToHarvest")
				v111_ = true
			end
			if v113_ ~= nil then
				p87_:addFieldInfoKeyValue(g_i18n:getText("ui_mapOverviewGrowth"), v113_)
			end
		end
		self:infoBoxAddData(p87_.addFieldInfoKeyValue, p87_, v94_)
		if v111_ then
			self:infoBoxAddYieldData(p87_.addFieldInfoKeyValue, p87_, v94_)
		end
		if g_currentMission.missionInfo.weedsEnabled then
			local v114_ = g_currentMission.weedSystem
			local v115_ = v114_:getFieldInfoStates()
			local v116_ = v94_.weedState
			local v117_ = nil
			if v116_ > 0 then
				local v118_
				if v109_ == nil then
					v118_ = nil
				else
					v118_ = g_fruitTypeManager:getFruitTypeByIndex(v109_)
				end
				if Platform.gameplay.hasWeeder then
					if (v118_ == nil or v118_:getIsWeedable(v110_)) and v114_:getWeederReplacements(false).weed.replacements[v116_] == 0 then
						v117_ = g_i18n:getText("weed_destruction_weeder")
					end
					if v117_ == nil and (v118_ == nil or v118_:getIsHoeable(v110_)) and v114_:getWeederReplacements(true).weed.replacements[v116_] == 0 then
						v117_ = g_i18n:getText("weed_destruction_hoe")
					end
				end
				if v117_ == nil and (v118_ == nil or v118_:getIsGrowing(v110_)) then
					v117_ = g_i18n:getText("weed_destruction_herbicide")
				end
				local v119_ = v115_[v116_]
				if v119_ ~= nil then
					p87_:addFieldInfoKeyValue(v119_, v117_ or "")
				end
			end
		end
		return true
	end)
end
