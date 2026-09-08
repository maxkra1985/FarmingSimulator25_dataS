-- Local values: SplitShapeManager_mt
SplitShapeManager = {}
local SplitShapeManager_mt = Class(SplitShapeManager, AbstractManager)

-- Upvalues: SplitShapeManager_mt
-- Local values: self
function SplitShapeManager.new(customMt)
	-- upvalues: (copy) SplitShapeManager_mt
	return AbstractManager.new(customMt or SplitShapeManager_mt)
end

function SplitShapeManager:initDataStructures()
	self.typesByIndex = {}
	self.typesByName = {}
	self.activeYarders = {}
end

function SplitShapeManager:loadMapData()
	SplitShapeManager:superClass().loadMapData(self)
	self:addSplitType("SPRUCE", "treeType_spruce", 1, 0.7, 3, true, nil, 1000, 6)
	self:addSplitType("PINE", "treeType_pine", 2, 0.7, 3, true, nil, 1000)
	self:addSplitType("LARCH", "treeType_larch", 3, 0.7, 3, true, nil, 1000)
	self:addSplitType("BIRCH", "treeType_birch", 4, 0.85, 3.2, true, nil, 1000)
	self:addSplitType("BEECH", "treeType_beech", 5, 0.9, 3.4, true, nil, 1000)
	self:addSplitType("MAPLE", "treeType_maple", 6, 0.9, 3.4, true, nil, 1000)
	self:addSplitType("OAK", "treeType_oak", 7, 0.9, 3.4, true, nil, 1000)
	self:addSplitType("ASH", "treeType_ash", 8, 0.9, 3.4, true, nil, 1000)
	self:addSplitType("LOCUST", "treeType_locust", 9, 1, 3.8, true, nil, 1000)
	self:addSplitType("MAHOGANY", "treeType_mahogany", 10, 1.1, 3, true, nil, 1000)
	self:addSplitType("POPLAR", "treeType_poplar", 11, 0.7, 7.5, true, nil, 1000)
	self:addSplitType("AMERICANELM", "treeType_americanElm", 12, 0.7, 3.5, true, nil, 1000)
	self:addSplitType("CYPRESS", "treeType_cypress", 13, 0.7, 3.5, true, nil, 1000)
	self:addSplitType("DOWNYSERVICEBERRY", "treeType_downyServiceberry", 14, 0.7, 3.5, false, nil, 1000)
	self:addSplitType("PAGODADOGWOOD", "treeType_pagodaDogwood", 15, 0.7, 3.5, true, nil, 1000)
	self:addSplitType("SHAGBARKHICKORY", "treeType_shagbarkHickory", 16, 0.7, 3.5, true, nil, 1000)
	self:addSplitType("STONEPINE", "treeType_stonePine", 17, 0.7, 3.5, true, nil, 1000)
	self:addSplitType("WILLOW", "treeType_willow", 18, 0.7, 3.5, true, nil, 1000)
	self:addSplitType("OLIVETREE", "treeType_oliveTree", 19, 0.6, 3.5, true, nil, 1000)
	self:addSplitType("GIANTSEQUOIA", "treeType_giantSequoia", 20, 0.3, 0.3, true, nil, 1000)
	self:addSplitType("LODGEPOLEPINE", "treeType_lodgepolePine", 21, 1, 3.7, true, nil, 1000)
	self:addSplitType("PONDEROSAPINE", "treeType_ponderosaPine", 22, 1, 3.7, true, nil, 1000)
	self:addSplitType("DEADWOOD", "treeType_deadwood", 23, 0.1, 0.5, true, nil, 1000)
	self:addSplitType("TRANSPORT", "treeType_transport", 24, 0.1, 0.3, true, nil, 10)
	self:addSplitType("ASPEN", "treeType_aspen", 25, 1.2, 3.3, true, nil, 1000)
	self:addSplitType("APPLE", "treeType_apple", 26, 0.8, 1.2, false, nil, 1000)
	self:addSplitType("BETULAERMANII", "treeType_betulaErmanii", 27, 0.6, 3.5, true, nil, 1000)
	self:addSplitType("BOXELDER", "treeType_boxelder", 28, 0.9, 3.4, true, nil, 1000)
	self:addSplitType("CHERRY", "treeType_cherry", 29, 1, 3.8, false, nil, 1000)
	self:addSplitType("CHINESEELM", "treeType_chineseElm", 30, 0.7, 3.5, false, nil, 1000)
	self:addSplitType("GOLDENRAIN", "treeType_goldenRain", 31, 0.6, 3.5, true, nil, 1000)
	self:addSplitType("JAPANESEZELKOVA", "treeType_japaneseZelkova", 32, 0.7, 3.5, true, nil, 1000)
	self:addSplitType("NORTHERNCATALPA", "treeType_northernCatalpa", 33, 0.7, 3, false, nil, 1000)
	self:addSplitType("TILIAAMURENSIS", "treeType_tiliaAmurensis", 34, 0.9, 3.4, false, nil, 1000)
	self:addSplitType("RAVAGED", "treeType_ravaged", 35, 0.4, 3, true, nil, 1000)
	self:addSplitType("PINUSTABULIFORMIS", "treeType_pinusTabuliformis", 36, 0.9, 3.5, true, nil, 1000)
	self:addSplitType("PINUSSYLVESTRIS", "treeType_pinusSylvestris", 37, 0.8, 3.3, true, nil, 1000)
	self:addSplitType("CHESTNUT", "treeType_chestnut", 38, 0.85, 3.3, true, nil, 1000)
	if g_isDevelopmentVersion then
		addConsoleCommand("gsSplitTypesExport", "Exports registered split types to xml files", "exportToXML", self)
	end
	return true
end

function SplitShapeManager:unloadMapData()
	removeConsoleCommand("gsSplitTypesExport")
	SplitShapeManager:superClass().unloadMapData(self)
end

-- Local values: desc
function SplitShapeManager:addSplitType(name, l10nKey, splitTypeIndex, pricePerLiter, woodChipsPerLiter, allowsWoodHarvester, customEnvironment, volumeToLiter, woodHarvesterAreaThreshold)
	if self.typesByIndex[splitTypeIndex] == nil then
		local v16_ = string.upper(name)
		if self.typesByName[v16_] == nil then
			if type(woodHarvesterAreaThreshold) ~= "number" then
				woodHarvesterAreaThreshold = nil
			end
			local v17_ = {
				["name"] = v16_,
				["title"] = g_i18n:getText(l10nKey, customEnvironment),
				["splitTypeIndex"] = splitTypeIndex,
				["pricePerLiter"] = pricePerLiter,
				["woodChipsPerLiter"] = woodChipsPerLiter,
				["allowsWoodHarvester"] = allowsWoodHarvester,
				["woodHarvesterAreaThreshold"] = woodHarvesterAreaThreshold or 4.5,
				["volumeToLiter"] = volumeToLiter or 1000
			}
			self.typesByIndex[splitTypeIndex] = v17_
			self.typesByName[v16_] = v17_
		else
			Logging.error("SplitShapeManager:addSplitType(): SplitType name \'%s\' is already in use", v16_)
		end
	else
		Logging.error("SplitShapeManager:addSplitType(): SplitTypeIndex \'%d\' is already in use for \'%s\'", splitTypeIndex, name)
		return
	end
end

function SplitShapeManager:getSplitTypeByIndex(index)
	return self.typesByIndex[index]
end

-- Local values: splitTypeData
function SplitShapeManager:getSplitTypeNameByIndex(index)
	local v22_ = self.typesByIndex[index]
	return v22_ == nil and "<NO_SPLIT_TYPE>" or v22_.name
end

-- Local values: splitType
function SplitShapeManager:getSplitTypeIndexByName(name)
	if name == nil then
		return nil
	else
		local v25_ = string.upper(name)
		local v26_ = self.typesByName[v25_]
		if v26_ == nil then
			return nil
		else
			return v26_.splitTypeIndex
		end
	end
end

-- Local values: isAllowed, objectId, _, vehicle
function SplitShapeManager:getIsShapeCutAllowed(x, z, shape, farmId, connection)
	local v33_ = g_missionManager:getIsShapeCutAllowed(shape, x, z, farmId)
	if v33_ ~= nil then
		return v33_
	end
	if Platform.gameplay.treeCutFarmlandRestrictions and not g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z) then
		return false
	end
	for v34_, _ in pairs(self.activeYarders) do
		local v35_ = NetworkUtil.getObject(v34_)
		if v35_ == nil then
			self.activeYarders[v34_] = nil
		elseif v35_:getIsTreeShapeUsedForYarderSetup(shape) then
			return false
		end
	end
	return g_currentMission:getHasPlayerPermission("cutTrees", connection)
end

-- Local values: objectId
function SplitShapeManager:addActiveYarder(vehicle)
	local v38_ = NetworkUtil.getObjectId(vehicle)
	self.activeYarders[v38_] = true
end

-- Local values: objectId
function SplitShapeManager:removeActiveYarder(vehicle)
	local v41_ = NetworkUtil.getObjectId(vehicle)
	self.activeYarders[v41_] = nil
end

-- Local values: splitTypeIndex, splitTypeDesc, _, sizeY, sizeZ, _, _, area
function SplitShapeManager:getSplitShapeAllowsHarvester(splitShapeId)
	local v43_ = getSplitType(splitShapeId)
	local v44_ = g_splitShapeManager:getSplitTypeByIndex(v43_)
	if v44_ ~= nil and v44_.allowsWoodHarvester then
		local _, v45_, v46_, _, _ = getSplitShapeStats(splitShapeId)
		local v47_ = v45_ * v46_
		if v47_ > 0.01 and v47_ < v44_.woodHarvesterAreaThreshold then
			return true
		end
	end
	return false
end

-- Local values: xmlFile, warningComment, typesSorted, _, desc, index, desc, element
function SplitShapeManager:exportToXML(_)
	if g_isDevelopmentVersion then
		local v49_ = XMLFile.create("SplitTypes", "", "splitTypes")
		v49_:addComment("splitTypes", "Warning: This file is exported from script and should not be edited manually")
		local v50_ = {}
		for _, v51_ in pairs(self.typesByName) do
			table.insert(v50_, v51_)
		end
		table.sort(v50_, function(p52_, p53_)
			return p52_.splitTypeIndex < p53_.splitTypeIndex
		end)
		for v54_, v55_ in ipairs(v50_) do
			local v56_ = string.format("splitTypes.splitType(%d)", v54_ - 1)
			v49_:setInt(v56_ .. "#index", v55_.splitTypeIndex)
			v49_:setString(v56_ .. "#name", v55_.name)
		end
		v49_:addComment("splitTypes", "Warning: This file is exported from script and should not be edited manually")
		v49_:saveTo("../tools/exporter/maya/splitTypes.xml", true)
		v49_:delete()
	end
end
g_splitShapeManager = SplitShapeManager.new()
g_splitTypeManager = {}
local v57_ = g_splitTypeManager
setmetatable(v57_, {
	["__index"] = function(_, p58_)
		if FindDeletedObjects.isRunning == nil then
			Logging.error("\'g_splitTypeManager\' no longer exists, use \'g_splitShapeManager\' instead!")
			printCallstack()
		end
		return g_splitShapeManager[p58_]
	end
})
