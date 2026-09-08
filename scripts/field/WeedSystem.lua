-- Local values: WeedSystem_mt
WeedSystem = {}
local WeedSystem_mt = Class(WeedSystem)
g_xmlManager:addCreateSchemaFunction(function()
	WeedSystem.xmlSchema = XMLSchema.new("weed")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = WeedSystem.xmlSchema
	v2_:register(XMLValueType.STRING, "map.weed#name", "Weed layer name")
	v2_:register(XMLValueType.STRING, "map.weed#title", "Weed title")
	v2_:register(XMLValueType.INT, "map.weed.general#firstChannel", "Weed first channel")
	v2_:register(XMLValueType.INT, "map.weed.general#numChannels", "Weed num channels")
	v2_:register(XMLValueType.VECTOR_N, "map.weed.mapColors.mapColor(?)#states", "Map color states", nil, true)
	v2_:register(XMLValueType.VECTOR_4, "map.weed.mapColors.mapColor(?)#default", "Default map colors")
	v2_:register(XMLValueType.VECTOR_4, "map.weed.mapColors.mapColor(?)#colorBlind", "Color blind map colors")
	v2_:register(XMLValueType.INT, "map.weed.states.sparseStart#value", "Weed sparse state")
	v2_:register(XMLValueType.INT, "map.weed.states.denseStart#value", "Weed sparse state")
	v2_:register(XMLValueType.INT, "map.weed.fieldInfoStates.fieldInfoState(?)#state", "Field info weed state")
	v2_:register(XMLValueType.STRING, "map.weed.fieldInfoStates.fieldInfoState(?)#title", "Field info weed state title")
	v2_:register(XMLValueType.INT, "map.weed.growth.update(?)#sourceState", "Weed update source state")
	v2_:register(XMLValueType.INT, "map.weed.growth.update(?)#targetState", "Weed update target state")
	v2_:register(XMLValueType.INT, "map.weed.factors.factor(?)#state", "Weed factor state")
	v2_:register(XMLValueType.FLOAT, "map.weed.factors.factor(?)#value", "Weed factor")
	v2_:register(XMLValueType.INT, "map.weed.infoLayer#firstChannel", "Weed info layer first channel")
	v2_:register(XMLValueType.INT, "map.weed.infoLayer#numChannels", "Weed info layer num channels")
	v2_:register(XMLValueType.STRING, "map.weed.infoLayer#filename", "Weed info layer filename")
	v2_:register(XMLValueType.INT, "map.weed.infoLayer.blockingState#value", "Weed info layer blocking value")
	v2_:register(XMLValueType.INT, "map.weed.infoLayer.blockingState#firstChannel", "Weed info layer blocking first channel")
	v2_:register(XMLValueType.INT, "map.weed.infoLayer.blockingState#numChannels", "Weed info layer blocking num channels")
	v2_:register(XMLValueType.STRING, "map.replacements.herbicide.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	v2_:register(XMLValueType.INT, "map.replacements.herbicide.replacements(?).replacement(?)#sourceState", "Herbicide replacement source state")
	v2_:register(XMLValueType.INT, "map.replacements.herbicide.replacements(?).replacement(?)#targetState", "Herbicide replacement target state")
	v2_:register(XMLValueType.STRING, "map.replacements.weeder.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	v2_:register(XMLValueType.INT, "map.replacements.weeder.replacements(?).replacement(?)#sourceState", "Weeder replacement source state")
	v2_:register(XMLValueType.INT, "map.replacements.weeder.replacements(?).replacement(?)#targetState", "Weeder replacement target state")
	v2_:register(XMLValueType.STRING, "map.replacements.weederHoe.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	v2_:register(XMLValueType.INT, "map.replacements.weederHoe.replacements(?).replacement(?)#sourceState", "Weeder hoe replacement source state")
	v2_:register(XMLValueType.INT, "map.replacements.weederHoe.replacements(?).replacement(?)#targetState", "Weeder hoe replacement target state")
	v2_:register(XMLValueType.STRING, "map.replacements.mulcher.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	v2_:register(XMLValueType.INT, "map.replacements.mulcher.replacements(?).replacement(?)#sourceState", "Mulcher replacement source state")
	v2_:register(XMLValueType.INT, "map.replacements.mulcher.replacements(?).replacement(?)#targetState", "Mulcher replacement target state")
end)

-- Upvalues: WeedSystem_mt
-- Local values: self
function WeedSystem.new(customMt)
	-- upvalues: (copy) WeedSystem_mt
	local v4_ = customMt or WeedSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.baseDirectory = ""
	v5_.densityMap = nil
	v5_.herbicideReplacements = {}
	v5_.weederReplacements = {}
	v5_.weederHoeReplacements = {}
	v5_.mulcherReplacements = {}
	v5_.growthMapping = {}
	v5_.factors = {}
	v5_.fieldInfoStates = {}
	v5_.infoLayer = nil
	v5_.mapColor = {}
	v5_.mapColorBlind = {}
	return v5_
end

function WeedSystem:delete()
	removeConsoleCommand("gsWeedSystemAddDelta")
	removeConsoleCommand("gsWeedSystemSetState")
	self.densityMap = nil
	if self.infoLayer ~= nil and self.infoLayer.map ~= nil then
		delete(self.infoLayer.map)
	end
	self.infoLayer = nil
end

-- Local values: xmlFile, title, color
function WeedSystem:loadWeed(filename)
	local v_u_9_ = XMLFile.load("weed", filename, WeedSystem.xmlSchema)
	if v_u_9_ ~= nil then
		self.name = v_u_9_:getValue("map.weed#name") or self.name
		local v10_ = v_u_9_:getValue("map.weed#title")
		if v10_ ~= nil then
			self.title = g_i18n:convertText(v10_) or self.title
		end
		self.firstChannel = v_u_9_:getValue("map.weed.general#firstChannel") or (self.firstChannel or 0)
		self.numChannels = v_u_9_:getValue("map.weed.general#numChannels") or (self.numChannels or 3)
		self.minValue = 1
		self.maxValue = 5
		local v_u_11_ = {
			0.6,
			0.6,
			0.6,
			1
		}
		v_u_9_:iterate("map.weed.mapColors.mapColor", function(_, p12_)
			-- upvalues: (copy) v_u_9_, (copy) v_u_11_, (copy) self
			local v13_ = v_u_9_:getValue(p12_ .. "#states", 1, true)
			if v13_ == nil then
				Logging.xmlError(v_u_9_, "Missing values for \'\'", p12_ .. "#states")
			else
				local v14_ = {
					["states"] = v13_,
					["color"] = v_u_9_:getValue(p12_ .. "#default", v_u_11_, 4)
				}
				local v15_ = {
					["states"] = v13_,
					["color"] = v_u_9_:getValue(p12_ .. "#colorBlind", v_u_11_, 4)
				}
				local v16_ = self.mapColor
				table.insert(v16_, v14_)
				local v17_ = self.mapColorBlind
				table.insert(v17_, v15_)
			end
		end)
		self:loadInfoLayer(v_u_9_, "map.weed.infoLayer")
		self.sparseStartState = v_u_9_:getValue("map.weed.states.sparseStart#value") or (self.sparseStartState or 1)
		self.denseStartState = v_u_9_:getValue("map.weed.states.denseStart#value") or (self.denseStartState or 2)
		v_u_9_:iterate("map.weed.growth.update", function(_, p18_)
			-- upvalues: (copy) v_u_9_, (copy) self
			local v19_ = v_u_9_:getValue(p18_ .. "#sourceState")
			local v20_ = v_u_9_:getValue(p18_ .. "#targetState")
			if v19_ ~= nil then
				self.growthMapping[v19_] = v20_
			end
		end)
		v_u_9_:iterate("map.weed.factors.factor", function(_, p21_)
			-- upvalues: (copy) v_u_9_, (copy) self
			local v22_ = v_u_9_:getValue(p21_ .. "#state")
			local v23_ = v_u_9_:getValue(p21_ .. "#value")
			if v22_ ~= nil and v23_ ~= nil then
				self.factors[v22_] = v23_
			end
		end)
		v_u_9_:iterate("map.weed.fieldInfoStates.fieldInfoState", function(_, p24_)
			-- upvalues: (copy) v_u_9_, (copy) self
			local v25_ = v_u_9_:getValue(p24_ .. "#state")
			local v26_ = v_u_9_:getValue(p24_ .. "#title")
			if v25_ ~= nil and v26_ ~= nil then
				self.fieldInfoStates[v25_] = g_i18n:convertText(v26_)
			end
		end)
		self:loadReplacements(v_u_9_, "map.replacements.herbicide", self.herbicideReplacements)
		self:loadReplacements(v_u_9_, "map.replacements.weeder", self.weederReplacements)
		self:loadReplacements(v_u_9_, "map.replacements.weederHoe", self.weederHoeReplacements)
		self:loadReplacements(v_u_9_, "map.replacements.mulcher", self.mulcherReplacements)
		v_u_9_:delete()
	end
end

function WeedSystem:loadReplacements(xmlFile, key, replacements)
	xmlFile:iterate(key .. ".replacements", function(_, p30_)
		-- upvalues: (copy) xmlFile, (copy) replacements
		local v31_ = xmlFile:getValue(p30_ .. "#fruitType")
		local v32_
		if v31_ == nil then
			v32_ = nil
		else
			v32_ = g_fruitTypeManager:getFruitTypeByName(v31_)
			if v32_ == nil then
				Logging.xmlWarning(xmlFile, "FruitType \'%s\' not defined for \'%s\'", v31_, p30_)
				return
			end
		end
		local v_u_33_ = {
			["fruitType"] = v32_,
			["replacements"] = {}
		}
		local v_u_34_ = false
		xmlFile:iterate(p30_ .. ".replacement", function(_, p35_)
			-- upvalues: (ref) xmlFile, (copy) v_u_33_, (ref) v_u_34_
			local v36_ = xmlFile:getValue(p35_ .. "#sourceState")
			local v37_ = xmlFile:getValue(p35_ .. "#targetState")
			if v36_ ~= nil then
				v_u_33_.replacements[v36_] = v37_
				v_u_34_ = true
			end
		end)
		if v_u_34_ then
			if v_u_33_.fruitType == nil then
				replacements.weed = v_u_33_
			else
				if replacements.custom == nil then
					replacements.custom = {}
				end
				local v38_ = replacements.custom
				table.insert(v38_, v_u_33_)
			end
		end
	end)
end

-- Local values: filename
function WeedSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory
	self:loadWeed("data/maps/maps_weed.xml")
	local v42_ = getXMLString(xmlFile, "map.weed#filename")
	if v42_ ~= nil then
		self:loadWeed((Utils.getFilename(v42_, baseDirectory)))
	end
	if g_currentMission:getIsServer() and g_addCheatCommands then
		addConsoleCommand("gsWeedSystemAddDelta", "Add weed delta to field", "consoleCommandAddDelta", self, "fieldId; [delta]")
		addConsoleCommand("gsWeedSystemSetState", "Set weed state to field", "consoleCommandSetState", self, "fieldId; state")
	end
	return true
end

function WeedSystem:addDensityMapSyncer(densityMapSyncer)
	if self.densityMap ~= nil then
		densityMapSyncer:addDensityMap(self.densityMap)
	end
end

function WeedSystem:getMapHasWeed()
	return self.densityMap ~= nil
end

function WeedSystem:getDensityMapData()
	return self.densityMap, self.firstChannel, self.numChannels, self.minValue, self.maxValue
end

function WeedSystem:getMaxValue()
	return self.maxValue
end

function WeedSystem:getHerbicideReplacements()
	return self.herbicideReplacements
end

function WeedSystem:getWeederReplacements(isHoeWeeder)
	if isHoeWeeder then
		return self.weederHoeReplacements
	else
		return self.weederReplacements
	end
end

-- Local values: replacements
function WeedSystem:getCanBeWeeded(weedState)
	return self.weederReplacements.weed.replacements[weedState] ~= nil
end

-- Local values: replacements
function WeedSystem:getWeededState(weedState)
	return self.weederReplacements.weed.replacements[weedState]
end

-- Local values: replacements
function WeedSystem:getCanBeHoed(weedState)
	return self.weederHoeReplacements.weed.replacements[weedState] ~= nil
end

-- Local values: replacements
function WeedSystem:getHoedState(weedState)
	return self.weederHoeReplacements.weed.replacements[weedState]
end

function WeedSystem:getMulcherReplacements()
	return self.mulcherReplacements
end

function WeedSystem:getGrowthMapping()
	return self.growthMapping
end

function WeedSystem:getColors()
	return self.mapColor, self.mapColorBlind
end

function WeedSystem:getTitle()
	return self.title
end

function WeedSystem:getSparseStartState()
	return self.sparseStartState
end

function WeedSystem:getDenseStartState()
	return self.denseStartState
end

function WeedSystem:getFactors()
	return self.factors
end

function WeedSystem:getFieldInfoStates()
	return self.fieldInfoStates
end

-- Local values: id, _, data, path, missionInfo, loadFromSave
function WeedSystem:initTerrain(mission, terrainNode, terrainDetailId)
	local v70_, _ = getTerrainDataPlaneByName(terrainNode, self.name)
	if v70_ ~= nil and v70_ ~= 0 then
		self.densityMap = v70_
		self.weedModifier = DensityMapModifier.new(self.densityMap, self.firstChannel, self.numChannels, terrainNode)
		self.weedFilter = DensityMapFilter.new(self.densityMap, self.firstChannel, self.numChannels)
		self.weedFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
	end
	local v71_ = self.infoLayer
	if v71_ == nil or v71_.filename == nil then
		self.infoLayer = nil
	else
		v71_.map = createBitVectorMap("weedInfoLayer")
		local v72_ = v71_.path
		local v73_ = mission.missionInfo
		local v74_
		if v73_.isValid then
			v72_ = v73_.savegameDirectory .. "/" .. v71_.filename
			v74_ = true
		else
			v74_ = false
		end
		if v74_ and not loadBitVectorMapFromFile(v71_.map, v72_, v71_.numChannels) then
			Logging.warning("Loading weed info layer file \'" .. tostring(v72_) .. "\' failed! Loading default.")
			v74_ = false
		end
		if not (v74_ or loadBitVectorMapFromFile(v71_.map, v71_.path, v71_.numChannels)) then
			local v75_ = Logging.warning
			local v76_ = v71_.path
			v75_("Loading weed info layer file \'" .. tostring(v76_) .. "\' failed!")
		end
		local v77_, v78_ = getBitVectorMapSize(v71_.map)
		v71_.width = v77_
		v71_.height = v78_
		v71_.isBitVector = true
		v71_.canBeDeleted = true
	end
end

-- Local values: data, filename
function WeedSystem:loadInfoLayer(xmlFile, key)
	local v82_ = self.infoLayer or {}
	v82_.firstChannel = xmlFile:getValue(key .. "#firstChannel") or (v82_.firstChannel or 0)
	v82_.numChannels = xmlFile:getValue(key .. "#numChannels") or (v82_.numChannels or 1)
	local v83_ = xmlFile:getValue(key .. "#filename")
	if v83_ ~= nil then
		v82_.path = Utils.getFilename(v83_, self.baseDirectory)
		v82_.filename = Utils.getFilenameFromPath(v82_.path)
	end
	v82_.maxValue = 2 ^ v82_.numChannels - 1
	v82_.blockingState = v82_.blockingState or {}
	v82_.blockingState.value = xmlFile:getValue(key .. ".blockingState#value") or (v82_.blockingState.value or 1)
	v82_.blockingState.firstChannel = xmlFile:getValue(key .. ".blockingState#firstChannel") or (v82_.blockingState.firstChannel or 0)
	v82_.blockingState.numChannels = xmlFile:getValue(key .. ".blockingState#numChannels") or (v82_.blockingState.numChannels or 1)
	self.infoLayer = v82_
	return true
end

-- Local values: data, blockingState
function WeedSystem:getBlockingStateData()
	local v85_ = self.infoLayer
	if v85_ == nil then
		return nil
	end
	local v86_ = v85_.blockingState
	return v86_.value, v86_.firstChannel, v86_.numChannels
end

-- Local values: data
function WeedSystem:getInfoLayerData()
	local v88_ = self.infoLayer
	if v88_ == nil then
		return nil
	else
		return v88_.map, v88_.firstChannel, v88_.numChannels
	end
end

function WeedSystem:getInfoLayer()
	return self.infoLayer
end

function WeedSystem:getWeedStateAtWorldPos(worldX, worldZ)
	return self.densityMap == nil and 0 or getDensityStatesAtWorldPos(self.densityMap, worldX, 0, worldZ)
end

-- Local values: value
function WeedSystem:getWeedFactorAtWorldPos(worldX, worldZ)
	if self.densityMap == nil then
		return 0
	end
	local v96_ = getDensityStatesAtWorldPos(self.densityMap, worldX, 0, worldZ)
	return self.factors[v96_] or 0
end

-- Local values: modifier, i, accumulator, changedTexels, totalTexels
function WeedSystem:addPolygonDelta(polygonVertices, delta)
	if self.weedModifier ~= nil then
		local v100_ = self.weedModifier
		v100_:clearPolygonPoints()
		for v101_ = 1, #polygonVertices, 2 do
			v100_:addPolygonPointWorldCoords(polygonVertices[v101_], polygonVertices[v101_ + 1])
		end
		v100_:executeAdd(delta)
		local v102_, v103_, v104_ = v100_:executeSetWithStats(self.maxValue, self.weedFilter)
		return v102_, v103_, v104_
	end
end

-- Local values: modifier, i, accumulator, changedTexels, totalTexels
function WeedSystem:setPolygonState(polygonVertices, state)
	if self.weedModifier ~= nil then
		local v108_ = self.weedModifier
		v108_:clearPolygonPoints()
		for v109_ = 1, #polygonVertices, 2 do
			v108_:addPolygonPointWorldCoords(polygonVertices[v109_], polygonVertices[v109_ + 1])
		end
		local v110_, v111_, v112_ = v108_:executeSetWithStats(state)
		return v110_, v111_, v112_
	end
end

-- Local values: field, modifier, _, point, x, _, z
function WeedSystem:consoleCommandAddDelta(fieldId, delta)
	local v116_ = tonumber(fieldId)
	local v117_ = tonumber(delta) or 1
	if v116_ == nil then
		return "Missing field index. gsWeedSystemAddDelta <fieldId> [<delta>]"
	end
	local v118_ = g_fieldManager:getFieldById(v116_)
	if v118_ == nil then
		return "Field not found"
	end
	if self.weedModifier == nil then
		return "No weed defined for current map"
	end
	local v119_ = self.weedModifier
	v119_:clearPolygonPoints()
	for _, v120_ in ipairs(v118_:getPolygonPoints()) do
		local v121_, _, v122_ = getWorldTranslation(v120_)
		v119_:addPolygonPointWorldCoords(v121_, v122_)
	end
	v119_:executeAdd(v117_)
	v119_:executeSet(self.maxValue, self.weedFilter)
	return "Added weed delta " .. v117_
end

-- Local values: field, modifier, _, point, x, _, z
function WeedSystem:consoleCommandSetState(fieldId, state)
	local v126_ = tonumber(fieldId)
	local v127_ = tonumber(state) or 1
	if v126_ == nil then
		return "Missing field index. gsWeedSystemSetState <fieldId> [<delta>]"
	end
	local v128_ = g_fieldManager:getFieldById(v126_)
	if v128_ == nil then
		return "Field not found"
	end
	if self.weedModifier == nil then
		return "No weed defined for current map"
	end
	local v129_ = self.weedModifier
	v129_:clearPolygonPoints()
	for _, v130_ in ipairs(v128_:getPolygonPoints()) do
		local v131_, _, v132_ = getWorldTranslation(v130_)
		v129_:addPolygonPointWorldCoords(v131_, v132_)
	end
	v129_:executeSet(v127_)
	return "Set weed state " .. v127_
end
