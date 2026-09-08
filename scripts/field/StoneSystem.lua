-- Local values: StoneSystem_mt
StoneSystem = {}
local StoneSystem_mt = Class(StoneSystem)
g_xmlManager:addCreateSchemaFunction(function()
	StoneSystem.xmlSchema = XMLSchema.new("stones")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = StoneSystem.xmlSchema
	v2_:register(XMLValueType.STRING, "map.stones#name", "Stone layer name")
	v2_:register(XMLValueType.STRING, "map.stones#title", "Stone title")
	v2_:register(XMLValueType.INT, "map.stones.general#firstChannel", "Stone first channel")
	v2_:register(XMLValueType.INT, "map.stones.general#numChannels", "Stone num channels")
	v2_:register(XMLValueType.VECTOR_N, "map.stones.mapColors.mapColor(?)#states", "Map color states", nil, true)
	v2_:register(XMLValueType.VECTOR_4, "map.stones.mapColors.mapColor(?)#default", "Default map colors")
	v2_:register(XMLValueType.VECTOR_4, "map.stones.mapColors.mapColor(?)#colorBlind", "Color blind map colors")
	v2_:register(XMLValueType.INT, "map.stones.picking#maskValue", "Stone mask value")
	v2_:register(XMLValueType.INT, "map.stones.picking#minValue", "Stone min value")
	v2_:register(XMLValueType.INT, "map.stones.picking#maxValue", "Stone max value")
	v2_:register(XMLValueType.INT, "map.stones.picking#pickedValue", "Stone picked value")
	v2_:register(XMLValueType.FLOAT, "map.stones.picking#litersPerSqm", "Stone liters per sqm")
	v2_:register(XMLValueType.INT, "map.stones.growth.update(?)#period", "Stone update period")
	v2_:register(XMLValueType.INT, "map.stones.growth.update(?)#sourceState", "Stone update source state")
	v2_:register(XMLValueType.INT, "map.stones.growth.update(?)#targetState", "Stone update target state")
	v2_:register(XMLValueType.STRING, "map.stones.wear.type(?)#name", "Vehicle type name")
	v2_:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier1", "Multiplier in stone state 1")
	v2_:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier2", "Multiplier in stone state 2")
	v2_:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier3", "Multiplier in stone state 3")
end)

-- Upvalues: StoneSystem_mt
-- Local values: self
function StoneSystem.new(customMt)
	-- upvalues: (copy) StoneSystem_mt
	local v4_ = customMt or StoneSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.baseDirectory = ""
	v5_.densityMap = nil
	v5_.growthMapping = {}
	v5_.wearByType = {}
	v5_.mapColor = {}
	v5_.mapColorBlind = {}
	return v5_
end

function StoneSystem:delete()
	removeConsoleCommand("gsStoneSystemAddDelta")
	removeConsoleCommand("gsStoneSystemSetState")
	removeConsoleCommand("gsStoneSystemToggleDebug")
	self.densityMap = nil
	if self.debugArea ~= nil then
		self.debugArea:delete()
	end
end

-- Local values: xmlFile, color
function StoneSystem:loadStones(filename)
	local v_u_9_ = XMLFile.load("stones", filename, StoneSystem.xmlSchema)
	self.name = v_u_9_:getValue("map.stones#name") or self.name
	self.title = g_i18n:convertText(v_u_9_:getValue("map.stones#title")) or self.title
	self.firstChannel = v_u_9_:getValue("map.stones.general#firstChannel") or (self.firstChannel or 0)
	self.numChannels = v_u_9_:getValue("map.stones.general#numChannels") or (self.numChannels or 3)
	self.maskValue = v_u_9_:getValue("map.stones.picking#maskValue") or (self.maskValue or 1)
	self.minValue = v_u_9_:getValue("map.stones.picking#minValue") or (self.minValue or 2)
	self.maxValue = v_u_9_:getValue("map.stones.picking#maxValue") or (self.maxValue or 4)
	self.litersPerSqm = v_u_9_:getValue("map.stones.picking#litersPerSqm") or (self.litersPerSqm or 5)
	self.pickedValue = v_u_9_:getValue("map.stones.picking#pickedValue") or (self.pickedValue or 5)
	v_u_9_:iterate("map.stones.growth.update", function(_, p10_)
		-- upvalues: (copy) v_u_9_, (copy) self
		local v11_ = v_u_9_:getValue(p10_ .. "#period")
		local v12_ = v_u_9_:getValue(p10_ .. "#sourceState")
		local v13_ = v_u_9_:getValue(p10_ .. "#targetState")
		if v11_ ~= nil and (v12_ ~= nil and v13_ ~= nil) then
			local v14_ = self.growthMapping
			table.insert(v14_, {
				["from"] = v12_,
				["to"] = v13_,
				["period"] = v11_
			})
		end
	end)
	local v_u_15_ = {
		0.6,
		0.6,
		0.6,
		1
	}
	v_u_9_:iterate("map.stones.mapColors.mapColor", function(_, p16_)
		-- upvalues: (copy) v_u_9_, (copy) v_u_15_, (copy) self
		local v17_ = v_u_9_:getValue(p16_ .. "#states", 1, true)
		if v17_ == nil then
			Logging.xmlError(v_u_9_, "Missing values for \'\'", p16_ .. "#states")
		else
			local v18_ = {
				["states"] = v17_,
				["color"] = v_u_9_:getValue(p16_ .. "#default", v_u_15_, 4)
			}
			local v19_ = {
				["states"] = v17_,
				["color"] = v_u_9_:getValue(p16_ .. "#colorBlind", v_u_15_, 4)
			}
			local v20_ = self.mapColor
			table.insert(v20_, v18_)
			local v21_ = self.mapColorBlind
			table.insert(v21_, v19_)
		end
	end)
	self.wearByType = {}
	v_u_9_:iterate("map.stones.wear.type", function(_, p22_)
		-- upvalues: (copy) v_u_9_, (copy) self
		local v23_ = v_u_9_:getValue(p22_ .. "#name")
		local v24_ = v_u_9_:getValue(p22_ .. "#multiplier1")
		local v25_ = v_u_9_:getValue(p22_ .. "#multiplier2")
		local v26_ = v_u_9_:getValue(p22_ .. "#multiplier3")
		if v23_ ~= nil and (v24_ ~= nil and (v25_ ~= nil and v26_ ~= nil)) then
			self.wearByType[string.upper(v23_)] = { v24_, v25_, v26_ }
		end
	end)
	v_u_9_:delete()
end

-- Local values: filename
function StoneSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory
	self:loadStones("data/maps/maps_stones.xml")
	local v30_ = getXMLString(xmlFile, "map.stones#filename")
	if v30_ ~= nil then
		self:loadStones((Utils.getFilename(v30_, baseDirectory)))
	end
	if g_server ~= nil and g_addCheatCommands then
		addConsoleCommand("gsStoneSystemAddDelta", "Add stone delta to field", "consoleCommandAddDelta", self, "fieldId; [delta]")
		addConsoleCommand("gsStoneSystemSetState", "Set stone state to field", "consoleCommandSetState", self, "fieldId; state")
		addConsoleCommand("gsStoneSystemToggleDebug", "Toggles debug view", "consoleCommandToggleDebug", self)
	end
	return true
end

function StoneSystem:addDensityMapSyncer(densityMapSyncer)
	if self.densityMap ~= nil then
		densityMapSyncer:addDensityMap(self.densityMap)
	end
end

function StoneSystem:getDensityMapData()
	return self.densityMap, self.firstChannel, self.numChannels
end

function StoneSystem:getMapHasStones()
	return self.densityMap ~= nil
end

function StoneSystem:getMinMaxValues()
	return self.minValue, self.maxValue
end

function StoneSystem:getPickedValue()
	return self.pickedValue
end

function StoneSystem:getMaskValue()
	return self.maskValue
end

function StoneSystem:getLitersPerSqm()
	return self.litersPerSqm
end

function StoneSystem:getWearMultiplierByType(name)
	if name == nil then
		return nil
	else
		return self.wearByType[string.upper(name)]
	end
end

-- Local values: id, _
function StoneSystem:initTerrain(mission, terrainNode, terrainDetailId)
	local v43_, _ = getTerrainDataPlaneByName(terrainNode, self.name)
	if v43_ ~= nil and v43_ ~= 0 then
		self.densityMap = v43_
		self.stoneModifier = DensityMapModifier.new(self.densityMap, self.firstChannel, self.numChannels, g_terrainNode)
		self.stoneFilter = DensityMapFilter.new(self.stoneModifier)
	end
end

function StoneSystem:getGrowthMapping()
	return self.growthMapping
end

function StoneSystem:getColors()
	return self.mapColor, self.mapColorBlind
end

function StoneSystem:getTitle()
	return self.title
end

function StoneSystem:getStoneStateAtWorldPos(worldX, worldZ)
	return self.densityMap == nil and 0 or getDensityStatesAtWorldPos(self.densityMap, worldX, 0, worldZ)
end

-- Local values: value, stoneLevel
function StoneSystem:getStoneLevelAtWorldPos(worldX, worldZ)
	if self.densityMap == nil then
		return 0
	end
	local v53_ = getDensityStatesAtWorldPos(self.densityMap, worldX, 0, worldZ)
	if v53_ == self.maskValue then
		return 0
	end
	local v54_ = v53_ - self.maskValue
	return math.max(0, v54_)
end

-- Local values: colors
function StoneSystem:consoleCommandToggleDebug()
	self.isDebugAreaActive = not self.isDebugAreaActive
	if self.isDebugAreaActive then
		local v56_ = {
			[0] = Color.new(0, 0.5, 0, 0.05),
			[1] = Color.new(0, 0, 1, 0.075),
			[2] = Color.new(0.995, 0.685, 0, 0.05),
			[3] = Color.new(0.846, 0.216, 0, 0.05),
			[4] = Color.new(0.695, 0.007, 0, 0.05),
			[5] = Color.new(0, 1, 0, 0.05),
			[6] = Color.new(0, 1, 0, 0.05),
			[7] = Color.new(0, 1, 0, 0.05),
			[8] = Color.new(0, 1, 0, 0.05)
		}
		self.debugArea = DebugDensityMap.newFromMap(self.densityMap, self.firstChannel, self.numChannels, 20, 0.05, v56_)
		g_debugManager:addElement(self.debugArea)
	elseif self.debugArea ~= nil then
		g_debugManager:removeElement(self.debugArea)
		self.debugArea:delete()
		self.debugArea = nil
	end
end

-- Local values: field, modifier, filter, _, point, x, _, z
function StoneSystem:consoleCommandAddDelta(fieldId, delta)
	local v60_ = tonumber(fieldId)
	local v61_ = tonumber(delta) or 1
	if v60_ == nil then
		return "Missing field index. gsStoneSystemAddDelta <fieldId> [<delta>]"
	end
	local v62_ = g_fieldManager:getFieldById(v60_)
	if v62_ == nil then
		return "Field not found"
	end
	if self.stoneModifier == nil then
		return "No stones defined for current map"
	end
	local v63_ = self.stoneModifier
	local v64_ = self.stoneFilter
	v63_:clearPolygonPoints()
	for _, v65_ in ipairs(v62_:getPolygonPoints()) do
		local v66_, _, v67_ = getWorldTranslation(v65_)
		v63_:addPolygonPointWorldCoords(v66_, v67_)
	end
	local v68_ = DensityValueCompareType.GREATER
	local v69_ = -v61_
	v64_:setValueCompareParams(v68_, (math.max(v69_, 0)))
	v63_:executeAdd(v61_, v64_)
	v64_:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
	v63_:executeSet(self.maxValue, v64_)
	return "Added stone delta " .. v61_
end

-- Local values: field, modifier, filter, _, point, x, _, z
function StoneSystem:consoleCommandSetState(fieldId, state)
	local v73_ = tonumber(fieldId)
	local v74_ = tonumber(state) or 1
	if v73_ == nil then
		return "Missing field index. gsStoneSystemSetState <fieldId> [<state>]"
	end
	local v75_ = g_fieldManager:getFieldById(v73_)
	if v75_ == nil then
		return "Field not found"
	end
	if self.stoneModifier == nil then
		return "No stones defined for current map"
	end
	local v76_ = self.stoneModifier
	local v77_ = self.stoneFilter
	v76_:clearPolygonPoints()
	for _, v78_ in ipairs(v75_:getPolygonPoints()) do
		local v79_, _, v80_ = getWorldTranslation(v78_)
		v76_:addPolygonPointWorldCoords(v79_, v80_)
	end
	v77_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	v76_:executeSet(v74_, v77_)
	return "Set stone state " .. v74_
end
