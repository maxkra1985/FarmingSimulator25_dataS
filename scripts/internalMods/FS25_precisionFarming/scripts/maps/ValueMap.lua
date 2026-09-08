-- Local values: ValueMap_mt
ValueMap = {}
ValueMap.MOD_NAME = g_currentModName
local ValueMap_mt = Class(ValueMap)

-- Upvalues: ValueMap_mt
-- Local values: self
function ValueMap.new(pfModule, customMt)
	-- upvalues: (copy) ValueMap_mt
	local v4_ = customMt or ValueMap_mt
	local v5_ = setmetatable({}, v4_)
	v5_.pfModule = pfModule
	v5_.filename = "valueMap.grle"
	v5_.name = "valueMap"
	v5_.id = "VALUE_MAP"
	v5_.label = "unknown"
	v5_.requireMinimapDisplay = false
	v5_.minimapSourceObject = nil
	v5_.minimapSourceObjectSelected = false
	v5_.requireMinimapUpdate = false
	v5_.minimapMissionState = false
	v5_.minimapAdditionalElementRealSize = { -1, -1 }
	v5_.minimapAdditionalElementLinkNode = nil
	v5_.minimapGradientSliceId = nil
	v5_.minimapGradientColorBlindSliceId = nil
	v5_.minimapLabelName = nil
	v5_.minimapLabelNameMission = nil
	v5_.minimapGradientLabelName = nil
	v5_.bitVectorMapsToSync = {}
	v5_.bitVectorMapsToSave = {}
	v5_.bitVectorMapsToDelete = {}
	return v5_
end

function ValueMap:initialize()
	self.bitVectorMapsToSync = {}
	self.bitVectorMapsToSave = {}
	self.bitVectorMapsToDelete = {}
	self.requireMinimapDisplay = false
	self.minimapSourceObject = nil
	self.minimapSourceObjectSelected = false
	self.requireMinimapUpdate = false
	self.minimapMissionState = false
end

function ValueMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return true
end

function ValueMap:postLoad(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return true
end

-- Local values: missionInfo, savegameFilename, bitVectorMap, newValueMap
function ValueMap:loadSavedBitVectorMap(name, filename, numChannels, size)
	local v11_ = g_currentMission.missionInfo
	local v12_
	if v11_.savegameDirectory == nil then
		v12_ = nil
	else
		v12_ = v11_.savegameDirectory .. "/" .. filename
		if not fileExists(v12_) then
			v12_ = nil
		end
	end
	local v13_ = createBitVectorMap(name)
	if v12_ ~= nil and not loadBitVectorMapFromFile(v13_, v12_, numChannels) then
		Logging.error("while loading bit vector map \'%s\'", v12_)
		v12_ = nil
	end
	local v14_
	if v12_ == nil then
		delete(v13_)
		v13_ = createBitVectorMap(name)
		loadBitVectorMapNew(v13_, size, size, numChannels, false)
		v14_ = true
	else
		v14_ = false
	end
	return v13_, v14_
end

function ValueMap:addBitVectorMapToSync(bitVectorMap)
	if bitVectorMap ~= nil then
		local v17_ = self.bitVectorMapsToSync
		table.insert(v17_, {
			["bitVectorMap"] = bitVectorMap
		})
	end
end

function ValueMap:addBitVectorMapToSave(bitVectorMap, filename)
	if bitVectorMap ~= nil then
		local v21_ = self.bitVectorMapsToSave
		table.insert(v21_, {
			["bitVectorMap"] = bitVectorMap,
			["filename"] = filename
		})
	end
end

function ValueMap:addBitVectorMapToDelete(bitVectorMap)
	if bitVectorMap ~= nil then
		local v24_ = self.bitVectorMapsToDelete
		table.insert(v24_, {
			["bitVectorMap"] = bitVectorMap
		})
	end
end

-- Local values: i
function ValueMap:initTerrain(mission, terrainId, filename)
	if mission.densityMapSyncer ~= nil then
		for v27_ = 1, #self.bitVectorMapsToSync do
			mission.densityMapSyncer:addDensityMap(self.bitVectorMapsToSync[v27_].bitVectorMap)
		end
	end
end

-- Local values: i
function ValueMap:delete()
	for v29_ = 1, #self.bitVectorMapsToDelete do
		delete(self.bitVectorMapsToDelete[v29_].bitVectorMap)
	end
	self.bitVectorMapsToDelete = {}
end

function ValueMap:loadFromItemsXML(xmlFile, key) end

function ValueMap:saveToXMLFile(xmlFile, key, usedModNames) end

function ValueMap:update(dt) end

function ValueMap:buildOverlay(overlay, valueFilter, isColorBlindMode) end

function ValueMap:getDisplayValues()
	return {}
end

function ValueMap:getValueFilter()
	return {}
end

function ValueMap:getMinimapValueFilter()
	return self:getValueFilter()
end

function ValueMap:getOverviewLabel()
	return g_i18n:getText(self.label, ValueMap.MOD_NAME)
end

function ValueMap:getId()
	return self.id
end

function ValueMap:getShowInMenu()
	return true
end

function ValueMap:getAllowCoverage()
	return false
end

function ValueMap:collectFarmlandHotspotActions(actions) end

function ValueMap:setRequireMinimapDisplay(state, sourceObject, isSelected)
	if self.minimapSourceObject == nil or self.minimapSourceObject == sourceObject then
		self.requireMinimapDisplay = state
		if state then
			self.minimapSourceObject = sourceObject
			self.minimapSourceObjectSelected = isSelected
			return
		end
		self.minimapSourceObject = nil
		self.minimapSourceObjectSelected = false
	end
end

function ValueMap:getRequireMinimapDisplay()
	return self.requireMinimapDisplay, self.minimapSourceObjectSelected
end

function ValueMap:setMinimapRequiresUpdate(state)
	self.requireMinimapUpdate = state
end

function ValueMap:setMinimapMissionState(state)
	if state ~= self.minimapMissionState then
		self.minimapMissionState = state
		self:setMinimapRequiresUpdate(true)
	end
end

function ValueMap:getMinimapUpdateTimeLimit()
	return self.minimapMissionState and 1 or 0.25
end

function ValueMap:getMinimapRequiresUpdate()
	return self.requireMinimapUpdate
end

function ValueMap:getMinimapAdditionalElement()
	return nil
end

function ValueMap:setMinimapAdditionalElementRealSize(x, y)
	self.minimapAdditionalElementRealSize[1] = x
	self.minimapAdditionalElementRealSize[2] = y
end

function ValueMap:getMinimapAdditionalElementRealSize()
	return self.minimapAdditionalElementRealSize[1], self.minimapAdditionalElementRealSize[2]
end

function ValueMap:setMinimapAdditionalElementLinkNode(linkNode)
	self.minimapAdditionalElementLinkNode = linkNode
end

function ValueMap:getMinimapAdditionalElementLinkNode()
	return self.minimapAdditionalElementLinkNode
end

function ValueMap:getMinimapLabel()
	if self.minimapMissionState then
		return self.minimapLabelNameMission or self.minimapLabelName
	else
		return self.minimapLabelName
	end
end

function ValueMap:getMinimapGradientLabel()
	if self.minimapMissionState then
		return nil
	else
		return self.minimapGradientLabelName
	end
end

function ValueMap:getMinimapGradientSliceId(isColorBlindMode)
	return isColorBlindMode and self.minimapGradientColorBlindSliceId or self.minimapGradientSliceId
end

function ValueMap:getMinimapZoomFactor()
	return 3
end

function ValueMap:collectFieldInfos(fieldInfoDisplayExtension) end

function ValueMap:getHelpLinePage()
	return 0
end

function ValueMap.roundToPixelCenter(x, z, terrainSize, mapSize)
	local v59_ = MathUtil.round((x + terrainSize * 0.5) / terrainSize * mapSize - 0.5) + 0.5
	local v60_ = MathUtil.round((z + terrainSize * 0.5) / terrainSize * mapSize - 0.5) + 0.5
	return v59_ / mapSize * terrainSize - terrainSize * 0.5, v60_ / mapSize * terrainSize - terrainSize * 0.5
end

function ValueMap:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(DensityMapHeightManager, "saveCollisionMap", function(p63_, p64_, p65_)
		-- upvalues: (copy) self
		for v66_ = 1, #self.bitVectorMapsToSave do
			local v67_ = self.bitVectorMapsToSave[v66_]
			saveBitVectorMapToFile(v67_.bitVectorMap, p65_ .. "/" .. v67_.filename)
		end
		p63_(p64_, p65_)
	end)
	pfModule:overwriteGameFunction(DensityMapHeightManager, "prepareSaveCollisionMap", function(p68_, p69_, p70_)
		-- upvalues: (copy) self
		for v71_ = 1, #self.bitVectorMapsToSave do
			local v72_ = self.bitVectorMapsToSave[v71_]
			prepareSaveBitVectorMapToFile(v72_.bitVectorMap, p70_ .. "/" .. v72_.filename)
		end
		p68_(p69_, p70_)
	end)
	pfModule:overwriteGameFunction(DensityMapHeightManager, "savePreparedCollisionMap", function(p_u_73_, p_u_74_, p_u_75_, p_u_76_)
		-- upvalues: (copy) self
		local v_u_80_ = {
			["saveBitVectorMap"] = function(p_u_77_)
				-- upvalues: (ref) self, (copy) v_u_80_, (copy) p_u_73_, (copy) p_u_74_, (copy) p_u_75_, (copy) p_u_76_
				local v78_ = {
					["tempCallback"] = function()
						-- upvalues: (ref) self, (copy) p_u_77_, (ref) v_u_80_, (ref) p_u_73_, (ref) p_u_74_, (ref) p_u_75_, (ref) p_u_76_
						if p_u_77_ < #self.bitVectorMapsToSave then
							v_u_80_.saveBitVectorMap(p_u_77_ + 1)
						else
							p_u_73_(p_u_74_, p_u_75_, p_u_76_)
						end
					end
				}
				local v79_ = self.bitVectorMapsToSave[p_u_77_]
				savePreparedBitVectorMapToFile(v79_.bitVectorMap, "tempCallback", v78_)
			end
		}
		if #self.bitVectorMapsToSave >= 1 then
			v_u_80_.saveBitVectorMap(1)
		else
			p_u_73_(p_u_74_, p_u_75_, p_u_76_)
		end
	end)
end
