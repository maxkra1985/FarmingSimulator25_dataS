-- Local values: TramlineMap_mt, worldCoordsToLocalCoords
TramlineMap = {}
TramlineMap.MIN_STRAIGHT_SEGMENT_LENGTH = 10
source(g_currentModDirectory .. "scripts/gui/TramlineSettingsDialog.lua")
source(g_currentModDirectory .. "scripts/densityMapUpdates/TramlineMapDensityMapTask.lua")
local TramlineMap_mt = Class(TramlineMap, ValueMap)

-- Upvalues: TramlineMap_mt
-- Local values: self, _, number, _, number, i
function TramlineMap.new(pfModule, customMt)
	-- upvalues: (copy) TramlineMap_mt
	local v4_ = ValueMap.new(pfModule, customMt or TramlineMap_mt)
	v4_.filename = "precisionFarming_tramlineMap.grle"
	v4_.name = "tramlineMap"
	v4_.id = "TRAMLINE_MAP"
	v4_.label = ""
	if g_server ~= nil then
		addConsoleCommand("pfTramlineSet", "Sets the tramlines for a specific farmland", "debugTramlineSet", v4_)
	end
	v4_.farmlandTramlineStates = {}
	v4_.implementWidths = {
		0,
		15,
		18,
		20,
		21,
		24,
		27,
		28,
		30,
		33,
		36,
		39,
		40,
		42,
		44,
		45,
		51,
		52,
		54,
		60
	}
	v4_.implementWidthTexts = {}
	for _, v5_ in ipairs(v4_.implementWidths) do
		if v5_ == 0 then
			local v6_ = v4_.implementWidthTexts
			local v7_ = g_i18n
			table.insert(v6_, v7_:getText("ui_tramlinesOff"))
		else
			local v8_ = v4_.implementWidthTexts
			local v9_ = string.format
			table.insert(v8_, v9_("%dm", v5_))
		end
	end
	v4_.spacings = {
		2,
		2.5,
		3,
		3.5
	}
	v4_.spacingTexts = {}
	for _, v10_ in ipairs(v4_.spacings) do
		local v11_ = v4_.spacingTexts
		local v12_ = string.format
		table.insert(v11_, v12_("%.1fm", v10_))
	end
	v4_.workDirectionTexts = {}
	v4_.workDirectionTextToDeg = {}
	local v13_ = v4_.workDirectionTexts
	local v14_ = g_i18n
	table.insert(v13_, v14_:getText("ai_settingAutomatic"))
	v4_.workDirectionTextToDeg[1] = -57.29577951308232
	for v15_ = 0, 175, 5 do
		local v16_ = v4_.workDirectionTexts
		local v17_ = string.format
		table.insert(v16_, v17_("%d \194\176", v15_))
		v4_.workDirectionTextToDeg[#v4_.workDirectionTexts] = v15_
	end
	MessageType.PRECISION_FARMING_TRAMLINES_CHANGED = nextMessageTypeId()
	return v4_
end

function TramlineMap:initialize()
	TramlineMap:superClass().initialize(self)
	self.densityMapModifiersPaint = {}
	self.densityMapModifiersClear = {}
	self.densityMapModifiersReset = nil
	TramlineSettingsDialog.register()
end

function TramlineMap:delete()
	TramlineMap:superClass().delete(self)
	if g_server ~= nil then
		removeConsoleCommand("pfTramlineSet")
	end
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: missionInfo, mapXMLFilename, mapXMLFile
function TramlineMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	local v23_ = key .. ".tramlineMap"
	self.npcFieldFruitTypes = {}
	self:loadTramlineFruitTypesFromXML(xmlFile, v23_ .. ".npcFields#fruitTypes")
	local v24_ = g_currentMission.missionInfo
	local v25_ = Utils.getFilename(v24_.mapXMLFilename, g_currentMission.baseDirectory)
	local v26_ = loadXMLFile("MapXML", v25_)
	if v26_ ~= nil then
		self:loadTramlineFruitTypesFromXML(v26_, "map.precisionFarming.npcTramlines#fruitTypes")
		delete(v26_)
	end
	self.npcWorkingWidth = getXMLInt(xmlFile, v23_ .. ".npcFields#workingWidth") or 27
	self.npcSpacing = getXMLFloat(xmlFile, v23_ .. ".npcFields#spacing") or 2
	if g_server ~= nil then
		g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
	end
	return true
end

function TramlineMap:initTerrain(mission, terrainId, filename)
	TramlineMap:superClass().initTerrain(self, mission, terrainId, filename)
	self.numChannels = 2
	self.size = g_currentMission.fruitMapSize
	self.bitVectorMap = self:loadSavedBitVectorMap("TramlineMap", self.filename, self.numChannels, self.size)
	self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
	self:addBitVectorMapToDelete(self.bitVectorMap)
end

-- Local values: fruitTypesStr, fruitTypes, j, fruitType
function TramlineMap:loadTramlineFruitTypesFromXML(xmlFile, key)
	local v34_ = getXMLString(xmlFile, key)
	if v34_ ~= nil then
		local v35_ = v34_:split(" ")
		for v36_ = 1, #v35_ do
			local v37_ = g_fruitTypeManager:getFruitTypeByName(v35_[v36_])
			if v37_ == nil then
				Logging.xmlWarning(xmlFile, "Invalid fruit type \'%s\' for npc fields \'%s\'", v35_[v36_], key)
			else
				self.npcFieldFruitTypes[v37_.index] = true
			end
		end
	end
end

function TramlineMap:loadFromItemsXML(xmlFile, key)
	xmlFile:iterate((key .. ".tramlineMap") .. ".farmland", function(_, p41_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v42_ = xmlFile:getInt(p41_ .. "#farmlandId")
		if v42_ ~= nil then
			local v43_ = {
				["workingWidth"] = xmlFile:getFloat(p41_ .. "#width")
			}
			if v43_.workingWidth ~= nil then
				v43_.workDirection = xmlFile:getFloat(p41_ .. "#workDirection", -57.29577951308232)
				v43_.spacing = xmlFile:getFloat(p41_ .. "#spacing", 2)
				v43_.pendingUpdate = xmlFile:getBool(p41_ .. "#pendingUpdate", false)
				self.farmlandTramlineStates[v42_] = v43_
			end
		end
	end)
end

-- Local values: i, farmlandId, state, baseKey
function TramlineMap:saveToXMLFile(xmlFile, key, usedModNames)
	local v47_ = key .. ".tramlineMap"
	local v48_ = 0
	for v49_, v50_ in pairs(self.farmlandTramlineStates) do
		local v51_ = string.format("%s.farmland(%d)", v47_, v48_)
		xmlFile:setInt(v51_ .. "#farmlandId", v49_)
		xmlFile:setFloat(v51_ .. "#width", v50_.workingWidth)
		xmlFile:setFloat(v51_ .. "#workDirection", v50_.workDirection)
		xmlFile:setFloat(v51_ .. "#spacing", v50_.spacing or 2)
		xmlFile:setBool(v51_ .. "#pendingUpdate", Utils.getNoNil(v50_.pendingUpdate, false))
		v48_ = v48_ + 1
	end
end

function TramlineMap:sendInitialClientState(connection, user, farm)
	connection:sendEvent(TramlineMapInitialEvent.new(self.farmlandTramlineStates))
end

function TramlineMap:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
end

function TramlineMap:update(dt) end
local function v_u_64_(p56_, p57_, p58_, p59_, p60_, p61_, p62_, p63_)
	return (p56_ + p63_ * 0.5) / p63_ * p62_ + 0.5 - 1, (p57_ + p63_ * 0.5) / p63_ * p62_ + 0.5 - 1, (p58_ + p63_ * 0.5) / p63_ * p62_ + 0.5 - 1, (p59_ + p63_ * 0.5) / p63_ * p62_ + 0.5 - 1, (p60_ + p63_ * 0.5) / p63_ * p62_ + 0.5 - 1, (p61_ + p63_ * 0.5) / p63_ * p62_ + 0.5 - 1
end

-- Local values: farmlandId
function TramlineMap:getTramlineWidthAtWorldPos(worldPosX, worldPosZ)
	local v68_ = g_farmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	if v68_ == nil or self.farmlandTramlineStates[v68_] == nil then
		return nil
	else
		return self.farmlandTramlineStates[v68_].workingWidth
	end
end

-- Upvalues: worldCoordsToLocalCoords
-- Local values: modifier, dirX, dirZ, yRot, rotOffsetFactor, offset, sideDirX, sideDirZ, minOffset, maxOffset, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ
function TramlineMap:paintLine(sx, sz, ex, ez, spacing)
	-- upvalues: (copy) v_u_64_
	local v75_ = spacing or 2
	local v76_ = self.densityMapModifiersPaint.modifier
	if v76_ == nil then
		self.densityMapModifiersPaint.modifier = DensityMapModifier.new(self.bitVectorMap, 0, 1)
		v76_ = self.densityMapModifiersPaint.modifier
		v76_:setPolygonRoundingMode(DensityRoundingMode.NEAREST_EXPAND)
	end
	local v77_, v78_ = MathUtil.vector2Normalize(ex - sx, ez - sz)
	local v79_ = MathUtil.getYRotationFromDirection(v77_, v78_)
	local v80_ = math.abs(v79_) % 1.5707963267948966 / 1.5707963267948966
	if v80_ > 0.5 then
		v80_ = 1 - v80_
	end
	local v81_ = v80_ * 2
	local v82_ = v75_ * 0.5 + v81_ * 0.25
	local v83_ = -v78_
	local v84_, v85_
	if math.abs(v83_) > math.abs(v77_) then
		v84_ = math.sign(v83_)
		v85_ = 0
	else
		v85_ = math.sign(v77_)
		v84_ = 0
	end
	v76_:resetDensityMapAndChannels(self.bitVectorMap, 0, 1)
	local v86_ = -v82_ - 0.01
	local v87_ = -v82_ + 0.01
	local v88_, v89_, v90_, v91_, v92_, v93_ = v_u_64_(sx + v84_ * v86_, sz + v85_ * v86_, sx + v84_ * v87_, sz + v85_ * v87_, ex + v84_ * v86_, ez + v85_ * v86_, self.size, g_currentMission.terrainSize)
	v76_:setParallelogramDensityMapCoords(v88_, v89_, v90_, v91_, v92_, v93_, DensityCoordType.POINT_POINT_POINT)
	v76_:executeSet(1)
	local v94_ = v82_ - 0.01
	local v95_ = v82_ + 0.01
	local v96_, v97_, v98_, v99_, v100_, v101_ = v_u_64_(sx + v84_ * v94_, sz + v85_ * v94_, sx + v84_ * v95_, sz + v85_ * v95_, ex + v84_ * v94_, ez + v85_ * v94_, self.size, g_currentMission.terrainSize)
	v76_:setParallelogramDensityMapCoords(v96_, v97_, v98_, v99_, v100_, v101_, DensityCoordType.POINT_POINT_POINT)
	v76_:executeSet(1)
	v76_:resetDensityMapAndChannels(self.bitVectorMap, 1, 1)
	local v102_ = -(v75_ * 0.5 + 1)
	local v103_ = v75_ * 0.5 + 1
	local v104_, v105_, v106_, v107_, v108_, v109_ = v_u_64_(sx + v84_ * v102_, sz + v85_ * v102_, sx + v84_ * v103_, sz + v85_ * v103_, ex + v84_ * v102_, ez + v85_ * v102_, self.size, g_currentMission.terrainSize)
	v76_:setParallelogramDensityMapCoords(v104_, v105_, v106_, v107_, v108_, v109_, DensityCoordType.POINT_POINT_POINT)
	v76_:executeSet(1)
end

-- Local values: multiModifiers, multiModifier
function TramlineMap:clearTramlines(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, densityMapShape, npcField)
	local v119_ = self.densityMapModifiersClear.multiModifiers
	if v119_ == nil then
		self.densityMapModifiersClear.multiModifiers = {}
		self.densityMapModifiersClear.multiModifiers[true] = DensityMapMultiModifier.new()
		self.densityMapModifiersClear.multiModifiers[false] = DensityMapMultiModifier.new()
		self:addTramlineClearToMultiModifier(self.densityMapModifiersClear.multiModifiers[true], true)
		self:addTramlineClearToMultiModifier(self.densityMapModifiersClear.multiModifiers[false], false)
		v119_ = self.densityMapModifiersClear.multiModifiers
	end
	local v120_ = v119_[Utils.getNoNil(npcField, false)]
	if densityMapShape == nil then
		v120_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	else
		densityMapShape:applyToModifier(v120_)
	end
	v120_:execute()
end

-- Local values: tramlineFilter, weedSystem, weedMapId, weedFirstChannel, weedNumChannels, weedModifier, fruitFilter, fruitModifier, _, desc
function TramlineMap:addTramlineClearToMultiModifier(multiModifier, npcField)
	local v124_ = DensityMapFilter.new(self.bitVectorMap, 0, 1)
	v124_:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	local v125_ = g_currentMission.weedSystem
	if v125_:getMapHasWeed() then
		local v126_, v127_, v128_ = v125_:getDensityMapData()
		multiModifier:addExecuteSet(0, DensityMapModifier.new(v126_, v127_, v128_, g_terrainNode), v124_)
	end
	local v129_ = nil
	local v130_ = nil
	for _, v131_ in pairs(g_fruitTypeManager:getFruitTypes()) do
		if (not npcField or self.npcFieldFruitTypes[v131_.index]) and v131_.terrainDataPlaneId ~= nil then
			if v129_ == nil then
				v129_ = DensityMapFilter.new(v131_.terrainDataPlaneId, v131_.startStateChannel, v131_.numStateChannels)
			else
				v129_:resetDensityMapAndChannels(v131_.terrainDataPlaneId, v131_.startStateChannel, v131_.numStateChannels)
			end
			v129_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			if v130_ == nil then
				v130_ = DensityMapModifier.new(v131_.terrainDataPlaneId, v131_.startStateChannel, v131_.numStateChannels)
			else
				v130_:resetDensityMapAndChannels(v131_.terrainDataPlaneId, v131_.startStateChannel, v131_.numStateChannels)
			end
			v130_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
			multiModifier:addExecuteSet(0, v130_, v124_, v129_)
		end
	end
end

-- Local values: farmland, state
function TramlineMap:setFarmlandTramlines(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit, noEventSend)
	if enabled then
		self:resetFarmlandTramlines(farmlandId)
	end
	if math.abs(workingWidth) > 0.1 then
		if g_farmlandManager:getFarmlandById(farmlandId) == nil then
			Logging.devError("TramlineMap: Farmland with id %d not found", farmlandId)
		else
			local v140_ = {
				["workingWidth"] = workingWidth,
				["workDirection"] = workDirection,
				["spacing"] = spacing,
				["enabled"] = enabled
			}
			v140_.pendingUpdate = v140_.enabled
			v140_.clearFruit = clearFruit
			self.farmlandTramlineStates[farmlandId] = v140_
		end
	else
		self.farmlandTramlineStates[farmlandId] = nil
	end
	TramlineMapSetEvent.sendEvent(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit, noEventSend)
	g_messageCenter:publish(MessageType.PRECISION_FARMING_TRAMLINES_CHANGED)
end

-- Local values: farmland, state, posX, posZ, fieldCourseSettings, segmentFunc, finishedFunc
function TramlineMap:onDensityMapUpdateFinished(farmlandId)
	local v_u_143_ = g_farmlandManager:getFarmlandById(farmlandId)
	local v_u_144_ = self.farmlandTramlineStates[farmlandId]
	if v_u_143_ ~= nil and (v_u_144_ ~= nil and v_u_144_.pendingUpdate) then
		v_u_144_.pendingUpdate = false
		if g_server ~= nil then
			local v145_, v146_ = v_u_143_:getIndicatorPosition()
			local v147_ = FieldCourseSettings.new()
			v147_.implementWidth = v_u_144_.workingWidth
			local v148_ = v_u_144_.workDirection
			v147_.workDirection = math.rad(v148_)
			v147_.numHeadlands = 1
			v147_.segmentExtendedToBoundary = true
			v147_.segmentHeadlandReverseLines = true
			v147_.segmentMinOffset = 3
			v147_.segmentMinLength = 25
			FieldCourseIterator.new(v145_, v146_, v147_, function(p149_, p150_, p151_, p152_, p153_, p154_, _, _)
				-- upvalues: (copy) self, (copy) v_u_144_
				if TramlineMap.MIN_STRAIGHT_SEGMENT_LENGTH < p153_ or p154_ ~= nil then
					self:paintLine(p149_, p150_, p151_, p152_, v_u_144_.spacing)
				end
			end, function()
				-- upvalues: (copy) v_u_144_, (copy) farmlandId, (copy) self, (copy) v_u_143_
				if v_u_144_.clearFruit then
					v_u_144_.clearFruit = false
					local v155_ = g_fieldManager:getFieldById(farmlandId)
					if v155_ ~= nil then
						self:clearTramlines(nil, nil, nil, nil, nil, nil, v155_:getDensityMapPolygon(), not v_u_143_.isOwned)
					end
				end
				Logging.devInfo("TramlineMap: Set tramlines for farmland %d (%d m)", farmlandId, v_u_144_.workingWidth)
			end)
		end
	end
end

-- Local values: updateTask
function TramlineMap:resetFarmlandTramlines(farmlandId)
	local v157_ = TramlineMapDensityMapTask.new()
	v157_:setData(farmlandId)
	v157_:enqueue()
end

-- Local values: functionData, multiModifier
function TramlineMap:getResetTramlinesMultiMudifier(farmlandId)
	local v160_ = self.densityMapModifiersReset
	if v160_ == nil then
		v160_ = {
			["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode),
			["multiModifiers"] = {}
		}
		self.densityMapModifiersReset = v160_
	end
	local v161_ = v160_.multiModifiers[farmlandId]
	if v161_ == nil then
		v161_ = DensityMapMultiModifier.new()
		v160_.multiModifiers[farmlandId] = v161_
		v161_:addExecuteSet(0, v160_.modifier)
	end
	return v161_
end

function TramlineMap:buildOverlay(overlay, yieldFilter, isColorBlindMode)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 0.1)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, 2, 0, 0, 0, 0)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, 2, 2, 0, 1, 0)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, 2, 3, 0, 1, 0)
end

function TramlineMap:getShowInMenu()
	return false
end

function TramlineMap:collectFarmlandHotspotActions(actions)
	local v166_ = {
		["title"] = g_i18n:getText("ui_tramlines"),
		["callback"] = self.onSetUpTramlines,
		["callbackTarget"] = self
	}
	table.insert(actions, v166_)
end

-- Local values: callback, state, implementWidthIndex, workDirectionIndex, spacingIndex, i, number, i, _, i, number, fieldX, fieldZ, farmland
function TramlineMap:onSetUpTramlines(farmlandId)
	local function v181_(p169_, p170_, p171_, p172_, p173_)
		-- upvalues: (copy) self
		local v174_ = #p170_
		if p169_ and (v174_ > 0 and (p171_ ~= 0 and p172_ ~= 0)) then
			local v175_ = self.implementWidths[p171_]
			local v176_ = self.workDirectionTextToDeg[p172_]
			local v177_ = self.spacings[p173_]
			for v178_, v179_ in ipairs(p170_) do
				local v180_ = v178_ == v174_
				self:setFarmlandTramlines(v179_:getId(), v175_, v176_, v177_, v180_, false)
			end
		end
		if self.mapFrame ~= nil then
			self.mapFrame:toggleMapInput(true)
			self.mapFrame.ingameMap:onOpen()
			self.mapFrame.ingameMap:registerActionEvents()
			self.mapFrame.ingameMapBase:restoreDefaultFilter()
		end
	end
	local v182_ = self.farmlandTramlineStates[farmlandId]
	local v183_ = 1
	local v184_ = 1
	local v185_ = 1
	if v182_ ~= nil then
		for v186_, v187_ in ipairs(self.implementWidths) do
			if v187_ == v182_.workingWidth then
				v183_ = v186_
				break
			end
		end
		for v188_, _ in ipairs(self.workDirectionTextToDeg) do
			local v189_ = v182_.workDirection - self.workDirectionTextToDeg[v188_]
			if math.abs(v189_) < 0.1 then
				v184_ = v188_
				break
			end
		end
		for v190_, v191_ in ipairs(self.spacings) do
			local v192_ = v182_.spacing - v191_
			if math.abs(v192_) < 0.1 then
				v185_ = v190_
				break
			end
		end
	end
	local v193_ = g_farmlandManager:getFarmlandById(farmlandId)
	local v194_, v195_
	if v193_ == nil then
		v194_ = 0
		v195_ = 0
	else
		v194_, v195_ = v193_:getIndicatorPosition()
	end
	if self.mapFrame ~= nil then
		self.mapFrame.ingameMap:onClose()
		self.mapFrame:toggleMapInput(false)
		self.mapFrame.ingameMapBase:restoreDefaultFilter()
	end
	TramlineSettingsDialog.show(v183_, v184_, v185_, v194_, v195_, v181_)
end

-- Local values: field
function TramlineMap:debugTramlineSet(fieldId, workingWidth, workDirection, spacing)
	local v201_ = tonumber(fieldId)
	local v202_ = tonumber(workingWidth) or 30
	local v203_ = tonumber(workDirection) or -57.29577951308232
	local v204_ = tonumber(spacing) or 2
	local v205_ = g_fieldManager:getFieldById(v201_)
	if v205_ ~= nil and v205_.getDensityMapPolygon ~= nil then
		self:setFarmlandTramlines(v205_:getId(), v202_, v203_, v204_, true, true)
	end
end

-- Local values: field
function TramlineMap:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if not loadFromSavegame then
		if farmId == FarmlandManager.NO_OWNER_FARM_ID then
			if g_fieldManager:getFieldById(farmlandId) ~= nil then
				self:setFarmlandTramlines(farmlandId, self.npcWorkingWidth, -57.29577951308232, self.npcSpacing, true, false)
				return
			end
		else
			Logging.devInfo("TramlineMap: Reset tramlines on bought farmland %d", farmlandId)
			self:setFarmlandTramlines(farmlandId, 0, 0, 0, true, false)
		end
	end
end

function TramlineMap:overwriteGameFunctions(pfModule)
	TramlineMap:superClass().overwriteGameFunctions(self, pfModule)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateSowingArea", function(p212_, p213_, p214_, p215_, p216_, p217_, p218_, p219_, ...)
		-- upvalues: (copy) self
		local v220_, v221_ = p212_(p213_, p214_, p215_, p216_, p217_, p218_, p219_, ...)
		local v222_ = g_missionManager:getMissionMapActiveMissionIdAtWorldPosition((p214_ + p216_) * 0.5, (p215_ + p217_) * 0.5)
		if v220_ > 0 and v222_ == 0 then
			self:clearTramlines(p214_, p215_, p216_, p217_, p218_, p219_, nil, false)
		end
		return v220_, v221_
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDirectSowingArea", function(p223_, p224_, p225_, p226_, p227_, p228_, p229_, p230_, ...)
		-- upvalues: (copy) self
		local v231_, v232_ = p223_(p224_, p225_, p226_, p227_, p228_, p229_, p230_, ...)
		local v233_ = g_missionManager:getMissionMapActiveMissionIdAtWorldPosition((p225_ + p227_) * 0.5, (p226_ + p228_) * 0.5)
		if v231_ > 0 and v233_ == 0 then
			self:clearTramlines(p225_, p226_, p227_, p228_, p229_, p230_, nil, false)
		end
		return v231_, v232_
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateWheelDestructionArea", function(_, p234_, p235_, p236_, p237_, p238_, p239_, ...)
		-- upvalues: (copy) self
		local v240_ = self.updateWheelDestructionAreaData
		if v240_ == nil then
			local v241_ = g_terrainNode
			local v242_ = g_currentMission.fieldGroundSystem
			local v243_, v244_, v245_ = v242_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local v246_, v247_, v248_ = v242_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			v240_ = {
				["modifier"] = DensityMapModifier.new(v246_, v247_, v248_, v241_),
				["multiModifier"] = nil,
				["filter1"] = DensityMapFilter.new(v243_, v244_, v245_),
				["fieldFilter"] = DensityMapFilter.new(v243_, v244_, v245_)
			}
			v240_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			v240_.tramlineFilter = DensityMapFilter.new(self.bitVectorMap, 1, 1)
			v240_.tramlineFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
			self.updateWheelDestructionAreaData = v240_
		end
		local v249_ = v240_.modifier
		local v250_ = v240_.multiModifier
		local v251_ = v240_.filter1
		local v252_ = v240_.fieldFilter
		local v253_ = v240_.tramlineFilter
		g_currentMission.growthSystem:setIgnoreDensityChanges(true)
		if v250_ == nil then
			v250_ = DensityMapMultiModifier.new()
			v240_.multiModifier = v250_
			for _, v254_ in pairs(g_fruitTypeManager:getFruitTypes()) do
				if v254_.terrainDataPlaneId ~= nil and v254_.minWheelDestructionState ~= nil then
					v249_:resetDensityMapAndChannels(v254_.terrainDataPlaneId, v254_.startStateChannel, v254_.numStateChannels)
					v251_:resetDensityMapAndChannels(v254_.terrainDataPlaneId, v254_.startStateChannel, v254_.numStateChannels)
					v251_:setValueCompareParams(DensityValueCompareType.BETWEEN, v254_.minWheelDestructionState, v254_.maxWheelDestructionState)
					v250_:addExecuteSet(v254_.wheelDestructionState, v249_, v251_, v252_, v253_)
				end
			end
			for v255_ = 1, #g_currentMission.dynamicFoliageLayers do
				local v256_ = g_currentMission.dynamicFoliageLayers[v255_]
				v249_:resetDensityMapAndChannels(v256_, 0, (getTerrainDetailNumChannels(v256_)))
				v250_:addExecuteSet(0, v249_)
			end
		end
		v250_:updateParallelogramWorldCoords(p234_, p235_, p236_, p237_, p238_, p239_, DensityCoordType.POINT_POINT_POINT)
		v250_:execute()
		FSDensityMapUtil.removeWeedArea(p234_, p235_, p236_, p237_, p238_, p239_)
		g_currentMission.growthSystem:setIgnoreDensityChanges(false)
	end)
	pfModule:overwriteGameFunction(FieldUpdateTask, "prepare", function(p257_, p258_, ...)
		-- upvalues: (copy) self
		p257_(p258_, ...)
		self:addTramlineClearToMultiModifier(p258_.multiModifier, true)
	end)
	pfModule:overwriteGameFunction(FarmlandManager, "loadFromXMLFile", function(p259_, p260_, p261_, ...)
		-- upvalues: (copy) self
		local v262_ = p259_(p260_, p261_, ...)
		if self.npcWorkingWidth ~= nil then
			for _, v263_ in ipairs(g_farmlandManager.sortedFarmlands) do
				local v264_ = v263_:getId()
				if not v263_.isOwned and (g_fieldManager:getFieldById(v264_) ~= nil and self.farmlandTramlineStates[v264_] == nil) then
					Logging.devInfo("Initialize tramlines on NPC field \'%d\'", v264_)
					self:setFarmlandTramlines(v263_:getId(), self.npcWorkingWidth, -57.29577951308232, self.npcSpacing, true, true, true)
				end
			end
		end
		return v262_
	end)
	pfModule:overwriteGameFunction(AbstractFieldMission, "initializeModifier", function(p265_, p266_, ...)
		-- upvalues: (copy) self
		p265_(p266_, ...)
		if self.missionTramlineModifier ~= nil then
			p266_.field:getDensityMapPolygon():applyToModifier(self.missionTramlineModifier)
		end
	end)
	pfModule:overwriteGameFunction(SowMission, "createModifier", function(p267_, p268_, ...)
		-- upvalues: (copy) self
		p267_(p268_, ...)
		if self.missionTramlineModifier == nil then
			self.missionTramlineModifier = DensityMapModifier.new(self.bitVectorMap, 0, 1, g_terrainNode)
			self.missionTramlineFilter = DensityMapFilter.new(self.bitVectorMap, 0, 1)
			self.missionTramlineFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		end
	end)
	pfModule:overwriteGameFunction(SowMission, "getPartitionCompletion", function(p269_, p270_, p271_, ...)
		-- upvalues: (copy) self
		local v272_, v273_, v274_ = p269_(p270_, p271_, ...)
		if self.missionTramlineModifier ~= nil then
			if p270_.completionPartitions ~= nil and #p270_.completionPartitions > 1 then
				local v275_ = p270_.completionPartitions[p271_]
				self.missionTramlineModifier:setPolygonClipRegion(v275_.minZ, v275_.maxZ)
			end
			local _, v276_, _ = self.missionTramlineModifier:executeGet(self.missionTramlineFilter)
			v274_ = v274_ - v276_
		end
		return v272_, v273_, v274_
	end)
end
