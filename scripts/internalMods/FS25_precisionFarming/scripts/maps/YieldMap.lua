-- Local values: YieldMap_mt, worldCoordsToLocalCoords
YieldMap = {}
YieldMap.MOD_NAME = g_currentModName
local YieldMap_mt = Class(YieldMap, ValueMap)
source(g_currentModDirectory .. "scripts/densityMapUpdates/YieldMapResetDensityMapTask.lua")

-- Upvalues: YieldMap_mt
-- Local values: self
function YieldMap.new(pfModule, customMt)
	-- upvalues: (copy) YieldMap_mt
	local v4_ = ValueMap.new(pfModule, customMt or YieldMap_mt)
	v4_.filename = "precisionFarming_yieldMap.grle"
	v4_.name = "yieldMap"
	v4_.id = "YIELD_MAP"
	v4_.label = "ui_mapOverviewYield"
	v4_.densityMapModifiersYield = {}
	v4_.densityMapModifiersReset = nil
	v4_.densityMapModifiersClear = nil
	v4_.minimapGradientSliceId = "precisionFarming.gradient_red_green"
	v4_.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
	v4_.minimapLabelName = g_i18n:getText("ui_mapOverviewYield", YieldMap.MOD_NAME)
	v4_.yieldMapSelected = false
	v4_.selectedFarmland = nil
	v4_.selectedField = nil
	v4_.selectedFieldArea = nil
	return v4_
end

function YieldMap:initialize()
	YieldMap:superClass().initialize(self)
	self.densityMapModifiersYield = {}
	self.densityMapModifiersReset = nil
	self.densityMapModifiersClear = nil
	self.yieldMapSelected = false
	self.selectedFarmland = nil
	self.selectedField = nil
	self.selectedFieldArea = nil
end

function YieldMap:delete()
	g_messageCenter:unsubscribeAll(self)
	YieldMap:superClass().delete(self)
end

-- Local values: i, baseKey, yieldValue, j, color1, color2, colorBlind1, colorBlind2
function YieldMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	local v10_ = key .. ".yieldMap"
	self.numChannels = getXMLInt(xmlFile, v10_ .. ".bitVectorMap#numChannels") or 4
	self.maxValue = 2 ^ self.numChannels - 1
	self.sizeX = getXMLInt(xmlFile, v10_ .. ".bitVectorMap#sizeX") or 1024
	self.sizeY = getXMLInt(xmlFile, v10_ .. ".bitVectorMap#sizeY") or 1024
	self.bitVectorMap = self:loadSavedBitVectorMap("YieldMap", self.filename, self.numChannels, self.sizeX)
	self:addBitVectorMapToSync(self.bitVectorMap)
	self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.yieldValues = {}
	local v11_ = 0
	while true do
		local v12_ = string.format("%s.yieldValues.yieldValue(%d)", v10_, v11_)
		if not hasXMLProperty(xmlFile, v12_) then
			break
		end
		local v13_ = {
			["value"] = getXMLInt(xmlFile, v12_ .. "#value") or 0,
			["displayValue"] = getXMLFloat(xmlFile, v12_ .. "#displayValue") or 100,
			["color"] = string.getVector(getXMLString(xmlFile, v12_ .. "#color"), 3),
			["colorBlind"] = string.getVector(getXMLString(xmlFile, v12_ .. "#colorBlind"), 3)
		}
		local v14_
		if v13_.color == nil then
			v14_ = false
		else
			v14_ = v13_.colorBlind ~= nil
		end
		v13_.showInMenu = v14_
		local v15_ = self.yieldValues
		table.insert(v15_, v13_)
		v11_ = v11_ + 1
	end
	for v16_ = 1, #self.yieldValues - 1 do
		if self.yieldValues[v16_].color == nil and v16_ > 1 then
			local v17_ = self.yieldValues[v16_ - 1].color
			local v18_ = self.yieldValues[v16_ + 1].color
			if v17_ ~= nil and v18_ ~= nil then
				self.yieldValues[v16_].color = {}
				self.yieldValues[v16_].color[1] = (v17_[1] + v18_[1]) * 0.5
				self.yieldValues[v16_].color[2] = (v17_[2] + v18_[2]) * 0.5
				self.yieldValues[v16_].color[3] = (v17_[3] + v18_[3]) * 0.5
			end
			local v19_ = self.yieldValues[v16_ - 1].colorBlind
			local v20_ = self.yieldValues[v16_ + 1].colorBlind
			if v19_ ~= nil and v20_ ~= nil then
				self.yieldValues[v16_].colorBlind = {}
				self.yieldValues[v16_].colorBlind[1] = (v19_[1] + v20_[1]) * 0.5
				self.yieldValues[v16_].colorBlind[2] = (v19_[2] + v20_[2]) * 0.5
				self.yieldValues[v16_].colorBlind[3] = (v19_[3] + v20_[3]) * 0.5
			end
		end
	end
	self.minimapGradientLabelName = string.format("%d%% - %d%%", self:getMinMaxValue())
	g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
	return true
end

function YieldMap:update(dt) end
local function v_u_29_(p21_, p22_, p23_, p24_, p25_, p26_, p27_, p28_)
	return (p21_ + p28_ * 0.5) / p28_ * p27_ + 0.5 - 1, (p22_ + p28_ * 0.5) / p28_ * p27_ + 0.5 - 1, (p23_ + p28_ * 0.5) / p28_ * p27_ + 0.5 - 1, (p24_ + p28_ * 0.5) / p28_ * p27_ + 0.5 - 1, (p25_ + p28_ * 0.5) / p28_ * p27_ + 0.5 - 1, (p26_ + p28_ * 0.5) / p28_ * p27_ + 0.5 - 1
end

-- Upvalues: worldCoordsToLocalCoords
-- Local values: modifier, maskFilter, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, internalYieldValue
function YieldMap:setAreaYield(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, yieldPercentage)
	-- upvalues: (copy) v_u_29_
	local v38_ = self.densityMapModifiersYield.modifier
	local v39_ = self.densityMapModifiersYield.maskFilter
	if v38_ == nil or v39_ == nil then
		self.densityMapModifiersYield.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels)
		v38_ = self.densityMapModifiersYield.modifier
		local v40_, v41_, v42_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.densityMapModifiersYield.maskFilter = DensityMapFilter.new(v40_, v41_, v42_)
		v39_ = self.densityMapModifiersYield.maskFilter
		v39_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	end
	local v43_, v44_, v45_, v46_, v47_, v48_ = v_u_29_(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
	v38_:setParallelogramDensityMapCoords(v43_, v44_, v45_, v46_, v47_, v48_, DensityCoordType.POINT_POINT_POINT)
	v38_:executeSet(self:getNearestInternalYieldValueFromValue(yieldPercentage / 2 * 100), v39_)
	self:setMinimapRequiresUpdate(true)
end

-- Local values: minDifference, minValue, i, yieldValue, difference
function YieldMap:getNearestInternalYieldValueFromValue(value)
	local v51_ = 10000
	local v52_ = 0
	if value > 0 then
		for v53_ = 1, #self.yieldValues do
			local v54_ = value - self.yieldValues[v53_].displayValue
			local v55_ = math.abs(v54_)
			if v55_ < v51_ then
				v52_ = self.yieldValues[v53_].value
				v51_ = v55_
			end
		end
	end
	return v52_
end

-- Local values: updateTask
function YieldMap:resetFarmlandYieldArea(farmlandId)
	local v57_ = YieldMapResetDensityMapTask.new()
	v57_:setData(farmlandId)
	v57_:enqueue()
	if g_server == nil and g_client ~= nil then
		g_client:getServerConnection():sendEvent(ResetYieldMapEvent.new(farmlandId))
	end
end

-- Local values: functionData, farmlandModifier
function YieldMap:getResetMultiModifier(farmlandId)
	local v60_ = self.densityMapModifiersReset
	if v60_ == nil then
		v60_ = {
			["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode),
			["farmlandMask"] = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits),
			["farmlandModifiers"] = {}
		}
		self.densityMapModifiersUncover = v60_
	end
	local v61_ = v60_.farmlandModifiers[farmlandId]
	if v61_ == nil then
		v61_ = DensityMapMultiModifier.new()
		v60_.farmlandMask:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
		v61_:addExecuteSet(0, v60_.modifier, v60_.farmlandMask)
		v60_.farmlandModifiers[farmlandId] = v61_
	end
	return v61_
end

-- Local values: functionData
function YieldMap:addClearToMultiModifier(multiModifier, filter1, filter2)
	local v66_ = self.densityMapModifiersClear
	if v66_ == nil then
		v66_ = {
			["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
		}
		self.densityMapModifiersClear = v66_
	end
	multiModifier:addExecuteSet(0, v66_.modifier, filter1, filter2)
end

-- Local values: yieldMapId, filterIndex, i, yieldValue, r, g, b
function YieldMap:buildOverlay(overlay, yieldFilter, isColorBlindMode)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	local v71_ = self.bitVectorMap
	local v72_ = 1
	for v73_ = 1, #self.yieldValues do
		local v74_ = self.yieldValues[v73_]
		if yieldFilter[v72_] then
			local v75_, v76_, v77_
			if isColorBlindMode then
				v75_ = v74_.colorBlind[1]
				v76_ = v74_.colorBlind[2]
				v77_ = v74_.colorBlind[3]
			else
				v75_ = v74_.color[1]
				v76_ = v74_.color[2]
				v77_ = v74_.color[3]
			end
			setDensityMapVisualizationOverlayStateColor(overlay, v71_, 0, 0, 0, self.numChannels, v74_.value, v75_, v76_, v77_)
		end
		if v74_.showInMenu then
			v72_ = v72_ + 1
		end
	end
end

function YieldMap:getMinimapZoomFactor()
	return 3
end

function YieldMap:getMinMaxValue()
	if #self.yieldValues > 0 then
		return self.yieldValues[1].displayValue, self.yieldValues[#self.yieldValues].displayValue, #self.yieldValues
	else
		return 0, 1, 0
	end
end

-- Local values: i, pct, yieldValue, yieldValueToDisplay
function YieldMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for v80_ = 1, #self.yieldValues do
			local v81_ = (v80_ - 1) / (#self.yieldValues - 1)
			local v82_ = self.yieldValues[v80_]
			if v82_.showInMenu then
				local v83_ = {
					["colors"] = {}
				}
				v83_.colors[true] = { v82_.colorBlind or { v81_ * 0.9 + 0.1, v81_ * 0.9 + 0.1, 0.1 } }
				v83_.colors[false] = { v82_.color }
				v83_.description = string.format("%d%%", v82_.displayValue)
				local v84_ = self.valuesToDisplay
				table.insert(v84_, v83_)
			end
		end
	end
	return self.valuesToDisplay
end

-- Local values: i
function YieldMap:getValueFilter()
	if self.valueFilter == nil then
		self.valueFilter = {}
		for v86_ = 1, #self.yieldValues do
			if self.yieldValues[v86_].showInMenu then
				local v87_ = self.valueFilter
				table.insert(v87_, true)
			end
		end
	end
	return self.valueFilter
end

function YieldMap:onValueMapSelectionChanged(valueMap)
	self.yieldMapSelected = valueMap == self
end

function YieldMap:onFarmlandSelectionChanged(farmlandId, fieldNumber, fieldArea)
	self.selectedFarmland = farmlandId
	self.selectedField = fieldNumber
	self.selectedFieldArea = fieldArea
end

function YieldMap:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if not loadFromSavegame then
		self:resetFarmlandYieldArea(farmlandId)
	end
end

function YieldMap:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
end

function YieldMap:getHelpLinePage()
	return 6
end

function YieldMap:collectFarmlandHotspotActions(actions)
	local v101_ = {
		["title"] = g_i18n:getText("ui_resetYield"),
		["callback"] = self.onResetYieldMapCallback,
		["callbackTarget"] = self
	}
	table.insert(actions, v101_)
end

function YieldMap:onResetYieldMapCallback(farmlandId)
	self.mapFrame:setMapSelectionItem(nil)
	self:resetFarmlandYieldArea(farmlandId)
	g_precisionFarming:updatePrecisionFarmingOverlays()
end
