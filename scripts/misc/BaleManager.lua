-- Local values: BaleManager_mt
BaleManager = {}
BaleManager.baleXMLSchema = nil
BaleManager.mapBalesXMLSchema = nil
local BaleManager_mt = Class(BaleManager, AbstractManager)

-- Upvalues: BaleManager_mt
-- Local values: self
function BaleManager.new(customMt)
	-- upvalues: (copy) BaleManager_mt
	local v3_ = AbstractManager.new(customMt or BaleManager_mt)
	BaleManager.baleXMLSchema = XMLSchema.new("bale")
	BaleManager.registerBaleXMLPaths(BaleManager.baleXMLSchema)
	BaleManager.mapBalesXMLSchema = XMLSchema.new("mapBales")
	BaleManager.registerMapBalesXMLPaths(BaleManager.mapBalesXMLSchema)
	return v3_
end

function BaleManager:initDataStructures()
	self.bales = {}
	self.modBalesToLoad = {}
	self.fermentations = {}
end

-- Local values: filename, xmlFilename, balesXMLFile, i, bale, baleXmlFile, _, bale
function BaleManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	BaleManager:superClass().loadMapData(self)
	local v8_ = getXMLString(xmlFile, "map.bales#filename")
	if v8_ == nil then
		Logging.xmlInfo(xmlFile, "No bales xml defined in map")
		return false
	end
	local v9_ = Utils.getFilename(v8_, baseDirectory)
	local v10_ = XMLFile.load("TempBales", v9_, BaleManager.mapBalesXMLSchema)
	if v10_ ~= nil then
		self:loadBales(v10_, baseDirectory)
		v10_:delete()
	end
	for v11_ = #self.modBalesToLoad, 1, -1 do
		local v12_ = self.modBalesToLoad[v11_]
		local v13_ = XMLFile.load("TempBale", v12_.xmlFilename, BaleManager.baleXMLSchema)
		if v13_ ~= nil then
			if self:loadBaleDataFromXML(v12_, v13_, v12_.baseDirectory) then
				local v14_ = self.bales
				table.insert(v14_, v12_)
			end
			v13_:delete()
		end
		table.remove(self.modBalesToLoad, v11_)
	end
	BaleManager.SEND_NUM_BITS = MathUtil.getNumRequiredBits(#self.bales)
	for _, v15_ in ipairs(self.bales) do
		v15_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v15_.i3dFilename, false, true, self.baleLoaded, self, v15_)
	end
	if g_addCheatCommands then
		addConsoleCommand("gsBaleAdd", "Adds a bale", "consoleCommandAddBale", self, "[fillTypeName]; [isRoundbale]; [width]; [height]; [length]; [wrapState]; [modName]")
		addConsoleCommand("gsBaleAddAll", "Adds a bale", "consoleCommandAddBaleAll", self, "[drawSizeBox]")
		addConsoleCommand("gsBaleList", "List available bale types", "consoleCommandListBales", self)
	end
	return true
end

-- Local values: collisionPreset, baleId
function BaleManager:baleLoaded(i3dNode, failedReason, bale)
	if i3dNode ~= 0 then
		bale.sharedRoot = i3dNode
		local v18_ = CollisionPreset.BALE
		local v19_ = getChildAt(i3dNode, 0)
		if getCollisionFilterGroup(v19_) ~= v18_.group then
			Logging.error("Bale \'%s\' has wrong collision group mask. Expected: %d, got: %d", bale.xmlFilename, v18_.group, getCollisionFilterGroup(v19_))
		end
		if getCollisionFilterMask(v19_) ~= v18_.mask then
			Logging.error("Bale \'%s\' has wrong collision mask. Expected: %d, got: %d", bale.xmlFilename, v18_.mask, getCollisionFilterMask(v19_))
		end
		removeFromPhysics(i3dNode)
	end
end

function BaleManager:unloadMapData()
	self:unloadBaleData()
	if g_addCheatCommands then
		removeConsoleCommand("gsBaleAdd")
		removeConsoleCommand("gsBaleList")
	end
	BaleManager:superClass().unloadMapData(self)
end

-- Local values: _, bale
function BaleManager:unloadBaleData()
	for _, v22_ in ipairs(self.bales) do
		if v22_.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(v22_.sharedLoadRequestId)
			v22_.sharedLoadRequestId = nil
		end
		if v22_.sharedRoot ~= nil then
			delete(v22_.sharedRoot)
			v22_.sharedRoot = nil
		end
	end
end

function BaleManager:loadBales(xmlFile, baseDirectory)
	xmlFile:iterate("map.bales.bale", function(_, p26_)
		-- upvalues: (copy) self, (copy) xmlFile, (copy) baseDirectory
		self:loadBaleFromXML(xmlFile, p26_, baseDirectory)
	end)
	return true
end

-- Local values: xmlFilename, bale, baleXmlFile, success
function BaleManager:loadBaleFromXML(xmlFile, key, baseDirectory)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile)
	end
	local v31_ = xmlFile:getString(key .. "#filename")
	if v31_ ~= nil then
		local v32_ = {
			["xmlFilename"] = Utils.getFilename(v31_, baseDirectory),
			["isAvailable"] = xmlFile:getBool(key .. "#isAvailable", true)
		}
		local v33_ = XMLFile.load("TempBale", v32_.xmlFilename, BaleManager.baleXMLSchema)
		if v33_ ~= nil then
			local v34_ = self:loadBaleDataFromXML(v32_, v33_, baseDirectory)
			v33_:delete()
			if v34_ then
				local v35_ = self.bales
				table.insert(v35_, v32_)
				return true
			end
		end
	end
	Logging.xmlError(xmlFile, "Failed to load bale from xml \'%s\'", key)
	return false
end

-- Local values: xmlFilename, bale
function BaleManager:loadModBaleFromXML(xmlFile, key, baseDirectory, customEnvironment)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile)
	end
	local v41_ = xmlFile:getString(key .. "#filename")
	if v41_ == nil then
		Logging.xmlError(xmlFile, "Failed to load bale from xml \'%s\'", key)
		return false
	end
	local v42_ = {
		["xmlFilename"] = Utils.getFilename(v41_, baseDirectory),
		["baseDirectory"] = baseDirectory,
		["customEnvironment"] = customEnvironment,
		["isAvailable"] = xmlFile:getBool(key .. "#isAvailable", true)
	}
	local v43_ = self.modBalesToLoad
	table.insert(v43_, v42_)
	return true
end

-- Local values: i3dFilename
function BaleManager:loadBaleDataFromXML(bale, xmlFile, baseDirectory)
	local v47_ = xmlFile:getValue("bale.filename")
	if v47_ == nil then
		Logging.xmlError(xmlFile, "No i3D file defined in bale xml.")
		return false
	end
	bale.i3dFilename = Utils.getFilename(v47_, baseDirectory)
	if not fileExists(bale.i3dFilename) then
		Logging.xmlError(xmlFile, "Bale i3d file could not be found \'%s\'", bale.i3dFilename)
		return false
	end
	bale.isRoundbale = xmlFile:getValue("bale.size#isRoundbale", true)
	bale.width = MathUtil.round(xmlFile:getValue("bale.size#width", 0), 2)
	bale.height = MathUtil.round(xmlFile:getValue("bale.size#height", 0), 2)
	bale.length = MathUtil.round(xmlFile:getValue("bale.size#length", 0), 2)
	bale.diameter = MathUtil.round(xmlFile:getValue("bale.size#diameter", 0), 2)
	bale.maxStackHeight = xmlFile:getValue("bale.size#maxStackHeight", bale.isRoundbale and 2 or 3)
	bale.visualWidth = xmlFile:getValue("bale.size#visualWidth", bale.width)
	bale.visualHeight = xmlFile:getValue("bale.size#visualHeight", bale.height)
	bale.visualLength = xmlFile:getValue("bale.size#visualLength", bale.length)
	bale.visualDiameter = xmlFile:getValue("bale.size#visualDiameter", bale.diameter)
	if bale.isRoundbale and (bale.diameter == 0 or bale.width == 0) then
		Logging.xmlError(xmlFile, "Missing size attributes for round bale. Requires width and diameter.")
		return false
	end
	if not bale.isRoundbale and (bale.width == 0 or (bale.height == 0 or bale.length == 0)) then
		Logging.xmlError(xmlFile, "Missing size attributes for square bale. Requires width, height and length.")
		return false
	end
	bale.fillTypes = {}
	xmlFile:iterate("bale.fillTypes.fillType", function(_, p48_)
		-- upvalues: (copy) xmlFile, (copy) bale
		local v49_ = xmlFile:getValue(p48_ .. "#name")
		local v50_ = g_fillTypeManager:getFillTypeIndexByName(v49_)
		if v50_ == nil then
			Logging.xmlWarning(xmlFile, "Unknown fill type \'%s\' for bale in \'%s\'", v49_, p48_)
		else
			local v51_ = {
				["fillTypeIndex"] = v50_,
				["capacity"] = xmlFile:getValue(p48_ .. "#capacity", 0)
			}
			local v52_ = bale.fillTypes
			table.insert(v52_, v51_)
		end
	end)
	bale.variations = {}
	xmlFile:iterate("bale.variations.variation", function(_, p53_)
		-- upvalues: (copy) xmlFile, (copy) bale
		local v54_ = xmlFile:getValue(p53_ .. "#id")
		if v54_ ~= nil then
			local v55_ = bale.variations
			table.insert(v55_, {
				["id"] = v54_
			})
		end
	end)
	if #bale.variations == 0 then
		local v56_ = bale.variations
		table.insert(v56_, {
			["id"] = "DEFAULT"
		})
	end
	return true
end

-- Local values: numFermentations, timeScale, i, fermentation, percentage
function BaleManager:update(dt)
	if g_server ~= nil then
		local v59_ = #self.fermentations
		if v59_ > 0 then
			local v60_ = g_currentMission:getEffectiveTimeScale()
			for v61_ = v59_, 1, -1 do
				local v62_ = self.fermentations[v61_]
				v62_.time = v62_.time + dt * v60_
				if v62_.time >= v62_.maxTime then
					v62_.bale:onFermentationUpdate(1)
					v62_.bale:onFermentationEnd()
					table.remove(self.fermentations, v61_)
				else
					local v63_ = v62_.time / v62_.maxTime
					local v64_ = v63_ * 100
					local v65_ = math.floor(v64_)
					local v66_ = v62_.percentageSend * 100
					if v65_ ~= math.floor(v66_) then
						v62_.bale:onFermentationUpdate(v63_)
						v62_.percentageSend = v63_
					end
				end
			end
		end
	end
end

-- Local values: fermentation
function BaleManager:registerFermentation(bale, currentTime, maxTime)
	local v71_ = {
		["bale"] = bale,
		["time"] = currentTime,
		["percentageSend"] = 0,
		["maxTime"] = (not Platform.gameplay.hasBaleFermentation and 0 or maxTime) * g_currentMission.missionInfo.economicDifficulty
	}
	local v72_ = self.fermentations
	table.insert(v72_, v71_)
end

-- Local values: i
function BaleManager:getFermentationTime(bale)
	for v75_ = 1, #self.fermentations do
		if self.fermentations[v75_].bale == bale then
			return self.fermentations[v75_].time
		end
	end
	return 0
end

-- Local values: i
function BaleManager:removeFermentation(bale)
	for v78_ = #self.fermentations, 1, -1 do
		if self.fermentations[v78_].bale == bale then
			table.remove(self.fermentations, v78_)
		end
	end
end

function BaleManager:getBaleDescByIndex(baleIndex)
	return self.bales[baleIndex]
end

-- Local values: baleIndex, bale, baleIndex, bale
function BaleManager:getBaleIndex(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	if customEnvironment ~= nil then
		for v89_ = 1, #self.bales do
			local v90_ = self.bales[v89_]
			if v90_.isAvailable and (customEnvironment == v90_.customEnvironment and self:getIsBaleMatching(v90_, fillTypeIndex, isRoundbale, width, height, length, diameter)) then
				return v89_
			end
		end
	end
	for v91_ = 1, #self.bales do
		local v92_ = self.bales[v91_]
		if v92_.isAvailable and (v92_.customEnvironment == nil and self:getIsBaleMatching(v92_, fillTypeIndex, isRoundbale, width, height, length, diameter)) then
			return v91_
		end
	end
	return nil
end

-- Local values: i, bale
function BaleManager:getBaleInfoByXMLFilename(xmlFilename, useVisualInfomation)
	for v96_ = 1, #self.bales do
		local v97_ = self.bales[v96_]
		if v97_.xmlFilename == xmlFilename then
			if useVisualInfomation == true then
				return v97_.isRoundbale, v97_.visualWidth, v97_.visualHeight, v97_.visualLength, v97_.visualDiameter, v97_.maxStackHeight
			else
				return v97_.isRoundbale, v97_.width, v97_.height, v97_.length, v97_.diameter, v97_.maxStackHeight
			end
		end
	end
	return false, 0, 0, 0, 0, 1
end

-- Local values: fillTypeMatch, j, sizeMatch
function BaleManager:getIsBaleMatching(bale, fillTypeIndex, isRoundbale, width, height, length, diameter)
	if bale.isRoundbale == isRoundbale then
		local v105_ = false
		for v106_ = 1, #bale.fillTypes do
			if bale.fillTypes[v106_].fillTypeIndex == fillTypeIndex then
				v105_ = true
				break
			end
		end
		if v105_ then
			local v107_
			if isRoundbale then
				if width == nil or MathUtil.round(width, 2) == bale.width then
					v107_ = diameter == nil and true or MathUtil.round(diameter, 2) == bale.diameter
				else
					v107_ = false
				end
			elseif (width == nil or MathUtil.round(width, 2) == bale.width) and (height == nil or MathUtil.round(height, 2) == bale.height) then
				v107_ = length == nil and true or MathUtil.round(length, 2) == bale.length
			else
				v107_ = false
			end
			if v107_ then
				return true
			end
		end
	end
	return false
end

-- Local values: baleIndex
function BaleManager:getBaleXMLFilename(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	local v116_ = self:getBaleIndex(fillTypeIndex, isRoundbale, width, height, length, diameter, customEnvironment)
	if v116_ == nil then
		return nil
	else
		return self.bales[v116_].xmlFilename, v116_
	end
end

-- Local values: i
function BaleManager:getBaleTypeIndexByXMLFilename(xmlFilename)
	for v119_ = 1, #self.bales do
		if self.bales[v119_].xmlFilename == xmlFilename then
			return v119_
		end
	end
	return nil
end

function BaleManager:getBaleXMLFilenameByIndex(baleIndex)
	if baleIndex == nil or self.bales[baleIndex] == nil then
		return nil
	else
		return self.bales[baleIndex].xmlFilename
	end
end

function BaleManager:getIsRoundBale(baleIndex)
	if baleIndex == nil or self.bales[baleIndex] == nil then
		return nil
	else
		return self.bales[baleIndex].isRoundbale
	end
end

-- Local values: bale, j
function BaleManager:getBaleCapacityByBaleIndex(baleIndex, fillTypeIndex)
	if baleIndex ~= nil then
		local v127_ = self.bales[baleIndex]
		if v127_ ~= nil then
			for v128_ = 1, #v127_.fillTypes do
				if v127_.fillTypes[v128_].fillTypeIndex == fillTypeIndex then
					return v127_.fillTypes[v128_].capacity
				end
			end
		end
	end
	return 0
end

-- Local values: capacities, _, bale, _, fillTypeData
function BaleManager:getPossibleCapacitiesForFillType(fillTypeIndex)
	local v131_ = {}
	for _, v132_ in ipairs(self.bales) do
		for _, v133_ in ipairs(v132_.fillTypes) do
			if v133_.fillTypeIndex == fillTypeIndex then
				local v134_ = v133_.capacity
				table.insert(v131_, v134_)
			end
		end
	end
	return v131_
end

-- Local values: usage, fillTypeIndex, baleXMLFilename, _, x, y, z, dirX, dirZ, ry, farmId, baleObject
function BaleManager:consoleCommandAddBale(fillTypeName, isRoundbale, width, height, length, wrapState, modName)
	if g_currentMission:getIsServer() then
		local v143_ = Utils.getNoNil(fillTypeName, "STRAW")
		local v144_ = Utils.stringToBoolean(isRoundbale)
		local v145_
		if width == nil then
			v145_ = nil
		else
			v145_ = tonumber(width) or nil
		end
		local v146_
		if height == nil then
			v146_ = nil
		else
			v146_ = tonumber(height) or nil
		end
		local v147_
		if length == nil then
			v147_ = nil
		else
			v147_ = tonumber(length) or nil
		end
		if wrapState == nil or tonumber(wrapState) ~= nil then
			local v148_ = tonumber(wrapState or 0)
			local v149_ = g_fillTypeManager:getFillTypeIndexByName(v143_)
			if v149_ == nil then
				Logging.error("Invalid fillTypeName \'%s\' (e.g. STRAW).\nUsage: %s", v143_, "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
			else
				local v150_, _ = self:getBaleXMLFilename(v149_, v144_, v145_, v146_, v147_, v146_, modName)
				if v150_ ~= nil then
					local v151_, v152_, v153_ = g_localPlayer:getPosition()
					local v154_, v155_ = g_localPlayer:getCurrentFacingDirection()
					local v156_ = v151_ + v154_ * 4
					local v157_ = v153_ + v155_ * 4
					local v158_ = v152_ + 5
					local v159_ = MathUtil.getYRotationFromDirection(v154_, v155_)
					local v160_ = g_currentMission:getFarmId()
					local v161_ = (v160_ == FarmManager.SPECTATOR_FARM_ID or not v160_) and 1 or v160_
					local v162_ = Bale.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
					if v162_:loadFromConfigXML(v150_, v156_, v158_, v157_, 0, v159_, 0) then
						v162_:setFillType(v149_, true)
						v162_:setWrappingState(v148_)
						v162_:setOwnerFarmId(v161_, true)
						v162_:register()
					end
					return string.format("Created bale at (%.2f, %.2f, %.2f). For specific bales use: %s", v156_, v158_, v157_, "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
				end
				Logging.error("Could not find bale for given size attributes!\nUsage: %s", "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
				self:consoleCommandListBales()
			end
		else
			Logging.error("Invalid wrapState \'%s\', number expected.\nUsage: %s", wrapState, "gsBaleAdd fillTypeName isRoundBale [width] [height/diameter] [length] [wrapState] [modName]")
			return
		end
	else
		Logging.error("Command only allowed on server!")
		return
	end
end

-- Local values: wx, wy, wz, dirX, dirZ, _, bale, xmlFilename, balesXMLFile, spawnBales, numBalesToLoad, baleLoaded, _, bale
function BaleManager:consoleCommandAddBaleAll(drawSizeBox)
	if g_server == nil then
		Logging.error("Command only allowed on server!")
	else
		local v_u_165_ = string.lower(drawSizeBox or "") == "true"
		local v_u_166_, v_u_167_, v_u_168_, v_u_169_
		if self.debugLoadPosition == nil then
			local v170_, v171_, v172_ = g_localPlayer:getPosition()
			v_u_166_ = v170_
			v_u_167_ = v172_
			local v173_, v174_ = g_localPlayer:getCurrentFacingDirection()
			v_u_168_ = v173_
			v_u_169_ = v174_
			self.debugLoadPosition = {
				v_u_166_,
				v171_,
				v_u_167_,
				v_u_168_,
				v_u_169_
			}
		else
			v_u_166_ = self.debugLoadPosition[1]
			local _ = self.debugLoadPosition[2]
			v_u_167_ = self.debugLoadPosition[3]
			v_u_168_ = self.debugLoadPosition[4]
			v_u_169_ = self.debugLoadPosition[5]
		end
		if self.debugBales ~= nil then
			for _, v175_ in ipairs(self.debugBales) do
				v175_:delete()
			end
		end
		g_debugManager:removeGroup("baleManager")
		self.debugBales = {}
		self:unloadBaleData()
		g_i3DManager:clearEntireSharedI3DFileCache()
		self.bales = {}
		local v176_ = Utils.getFilename("data/maps/maps_bales.xml")
		local v177_ = XMLFile.load("TempBales", v176_, BaleManager.mapBalesXMLSchema)
		if v177_ ~= nil then
			self:loadBales(v177_)
			v177_:delete()
		end
		local function v_u_201_()
			-- upvalues: (ref) v_u_166_, (ref) v_u_167_, (ref) v_u_168_, (ref) v_u_169_, (copy) self, (ref) v_u_165_
			local v178_ = Color.new(0.2, 0.2, 0.2, 1)
			local v179_ = v_u_166_ + v_u_168_ * 4
			local v180_ = v_u_167_ + v_u_169_ * 4
			v_u_166_ = v179_
			v_u_167_ = v180_
			local v181_ = MathUtil.getYRotationFromDirection(v_u_168_, v_u_169_)
			local v182_ = 0
			for _, v183_ in ipairs(self.bales) do
				for _, v184_ in ipairs(v183_.fillTypes) do
					local v185_ = (v183_.isRoundbale and v183_.width or v183_.length) * 0.5
					for v186_, v187_ in ipairs(v183_.variations) do
						local v188_ = v_u_166_ + v_u_168_ * v185_ - v_u_169_ * v182_
						local v189_ = v_u_167_ + v_u_169_ * v185_ + v_u_168_ * v182_
						local v190_ = v183_.isRoundbale and v183_.diameter or v183_.height
						local v191_ = getTerrainHeightAtWorldPos(g_terrainNode, v188_, 0, v189_) + v190_ * 0.5
						local v192_ = Bale.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
						if v192_:loadFromConfigXML(v183_.xmlFilename, v188_, v191_, v189_, 0, v181_, 0) then
							v192_:setFillType(v184_.fillTypeIndex, true)
							v192_:setVariationIndex(v186_)
							v192_:setOwnerFarmId(g_currentMission:getFarmId(), true)
							v192_:register()
							v192_:removeFromPhysics()
							local v193_ = string.format("%s (%s - %s)", Utils.getFilenameFromPath(v183_.xmlFilename), g_fillTypeManager:getFillTypeNameByIndex(v184_.fillTypeIndex), v187_.id)
							local v194_, v195_, v196_ = localRotationToWorld(v192_.nodeId, 0, 3.141592653589793, 0)
							DebugText3D.new():createWithWorldPos(v188_, v191_ + v190_ * 0.5 + 0.25, v189_, v194_, v195_, v196_, v193_, 0.07):addToManager("baleManager", nil, math.huge)
							if v_u_165_ then
								local v197_, v198_, v199_
								if v183_.isRoundbale then
									v197_ = v183_.diameter
									v198_ = v183_.diameter
									v199_ = v183_.width
								else
									v197_ = v183_.width
									v198_ = v183_.height
									v199_ = v183_.length
								end
								DebugBox.new():createWithWorldPosAndRot(v188_, v191_, v189_, v194_, v195_, v196_, v197_, v198_, v199_):setColor(v178_):addToManager("baleManager", nil, math.huge)
							end
							local v200_ = self.debugBales
							table.insert(v200_, v192_)
						end
						v185_ = v185_ + (v183_.isRoundbale and v183_.width or v183_.length) + 1
					end
					v182_ = v182_ + 2.5
				end
				v182_ = v182_ + 5
			end
		end
		local v_u_202_ = #self.bales
		local function v206_(_, p203_, p204_, p205_)
			-- upvalues: (copy) self, (ref) v_u_202_, (copy) v_u_201_
			self:baleLoaded(p203_, p204_, p205_)
			v_u_202_ = v_u_202_ - 1
			if v_u_202_ == 0 then
				v_u_201_()
			end
		end
		for _, v207_ in ipairs(self.bales) do
			v207_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v207_.i3dFilename, false, true, v206_, self, v207_)
		end
	end
end

-- Local values: _, bale, attributes, _, sizeProperty, fillTypeNames, _, fillTypeData
function BaleManager:consoleCommandListBales()
	print("Available bale types:")
	for _, v209_ in ipairs(self.bales) do
		local v210_ = { v209_.xmlFilename }
		local v211_ = string.format
		local v212_ = v209_.isRoundbale
		table.insert(v210_, v211_("isRoundbale=%s", v212_))
		for _, v213_ in ipairs({
			"width",
			"height",
			"length",
			"diameter"
		}) do
			if v209_[v213_] ~= nil and v209_[v213_] ~= 0 then
				local v214_ = string.format
				local v215_ = v209_[v213_]
				table.insert(v210_, v214_("%s=%s", v213_, v215_))
			end
		end
		log(table.concat(v210_, "  "))
		local v216_ = {}
		for _, v217_ in ipairs(v209_.fillTypes) do
			local v218_ = g_fillTypeManager
			local v219_ = v217_.fillTypeIndex
			table.insert(v216_, v218_:getFillTypeNameByIndex(v219_))
		end
		log("    fillTypes: ", table.concat(v216_, "  "))
	end
end

function BaleManager.registerBaleXMLPaths(schema)
	schema:register(XMLValueType.STRING, "bale.filename", "Path to i3d file")
	schema:register(XMLValueType.BOOL, "bale.size#isRoundbale", "Bale is a roundbale", true)
	schema:register(XMLValueType.FLOAT, "bale.size#width", "Bale Width", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#height", "Bale Height", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#length", "Bale Length", 0)
	schema:register(XMLValueType.FLOAT, "bale.size#diameter", "Bale Diameter", 0)
	schema:register(XMLValueType.INT, "bale.size#maxStackHeight", "Max. stack height for automatic spawning of bales", "2 or round bales and 3 for square bales")
	schema:register(XMLValueType.FLOAT, "bale.size#visualWidth", "Bale Width (Real size of the visuals if different)", "Same as #width")
	schema:register(XMLValueType.FLOAT, "bale.size#visualHeight", "Bale Height (Real size of the visuals if different)", "Same as #height")
	schema:register(XMLValueType.FLOAT, "bale.size#visualLength", "Bale Length (Real size of the visuals if different)", "Same as #length")
	schema:register(XMLValueType.FLOAT, "bale.size#visualDiameter", "Bale Diameter (Real size of the visuals if different)", "Same as #diameter")
	schema:register(XMLValueType.NODE_INDEX, "bale.mountableObject#triggerNode", "Trigger node")
	schema:register(XMLValueType.FLOAT, "bale.mountableObject#forceAcceleration", "Acceleration force", 4)
	schema:register(XMLValueType.FLOAT, "bale.mountableObject#forceLimitScale", "Force limit scale", 1)
	schema:register(XMLValueType.BOOL, "bale.mountableObject#axisFreeY", "Joint is free in Y direction", false)
	schema:register(XMLValueType.BOOL, "bale.mountableObject#axisFreeX", "Joint is free in X direction", false)
	schema:register(XMLValueType.STRING, "bale.uvId", "Specify that this bale model has a custom UV. This will result in baleWrapper to replace the bale if the UV is different to the defined one in the baleWrapper. So the baleWrapper will always use a bale with a UV that matches the wrapping texture.", "DEFAULT")
	schema:register(XMLValueType.NODE_INDEX, "bale.baleMeshes.baleMesh(?)#node", "Path to mesh node")
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#supportsWrapping", "Defines if the mesh is hidden while wrapping or not")
	schema:register(XMLValueType.STRING, "bale.baleMeshes.baleMesh(?)#fillTypes", "If defined this mesh is only visible if any of this fillTypes is set")
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#isTensionBeltMesh", "Defines if this mesh is detected for tension belt calculation", false)
	schema:register(XMLValueType.BOOL, "bale.baleMeshes.baleMesh(?)#isAlphaMesh", "Defines if the mesh is a alpha mesh (different material will be applied)", false)
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?)#name", "Name of fill type")
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#capacity", "Fill level of bale with this fill type")
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#mass", "Mass of bale with this fill type", 500)
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?)#forceAcceleration", "Force acceleration value of bale with this fill type", "bale.mountableObject#forceAcceleration")
	schema:register(XMLValueType.BOOL, "bale.fillTypes.fillType(?)#supportsWrapping", "Wrapping is allowed while this type is used")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?)#materialName", "Bale material to use")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?)#alphaMaterialName", "Bale material to use on alpha mesh parts")
	BaleManager.registerBaleTextureXMLPaths(schema, "bale.fillTypes.fillType(?)")
	schema:register(XMLValueType.STRING, "bale.variations.variation(?)#id", "Variation identifier")
	BaleManager.registerBaleTextureXMLPaths(schema, "bale.variations.variation(?)")
	schema:register(XMLValueType.STRING, "bale.fillTypes.fillType(?).fermenting#outputFillType", "Output fill type after fermenting")
	schema:register(XMLValueType.BOOL, "bale.fillTypes.fillType(?).fermenting#requiresWrapping", "Wrapping is required to start fermenting", true)
	schema:register(XMLValueType.FLOAT, "bale.fillTypes.fillType(?).fermenting#time", "Fermenting time in ingame days which represent months", 1)
	schema:register(XMLValueType.STRING, "bale.packedBale#singleBale", "Path to single bale xml filename")
	schema:register(XMLValueType.NODE_INDEX, "bale.packedBale.singleBale(?)#node", "Single bale spawn node")
end

function BaleManager.registerBaleTextureXMLPaths(schema, basePath)
	schema:register(XMLValueType.FILENAME, basePath .. ".diffuse#filename", "Diffuse texture to apply to all mesh nodes")
	schema:register(XMLValueType.BOOL, basePath .. ".diffuse#useFillTypeArray", "Use the fill type array texture for diffuse", false)
	schema:register(XMLValueType.FILENAME, basePath .. ".normal#filename", "Normal texture to apply to all mesh nodes")
	schema:register(XMLValueType.BOOL, basePath .. ".normal#useFillTypeArray", "Use the fill type array texture for normal", false)
	schema:register(XMLValueType.FILENAME, basePath .. ".alpha#filename", "Alpha texture to apply to all mesh nodes")
	schema:register(XMLValueType.FILENAME, basePath .. ".baleNormal#filename", "Bale normal texture to apply to all mesh nodes")
	schema:register(XMLValueType.FILENAME, basePath .. ".netWrapDiffuse#filename", "Net wrap diffuse texture to apply to all mesh nodes")
	schema:register(XMLValueType.FILENAME, basePath .. ".netWrapNormal#filename", "Net Wrap normal texture to apply to all mesh nodes")
end

function BaleManager.registerMapBalesXMLPaths(schema)
	schema:register(XMLValueType.STRING, "map.bales.bale(?)#filename", "Path to bale xml")
	schema:register(XMLValueType.STRING, "map.bales.bale(?)#isAvailable", "Bale is available for all balers to spawn")
end
g_baleManager = BaleManager.new()
