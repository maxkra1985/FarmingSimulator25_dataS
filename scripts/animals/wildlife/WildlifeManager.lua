-- Local values: WildlifeManager_mt
WildlifeManager = {}
local WildlifeManager_mt = Class(WildlifeManager)
g_xmlManager:addCreateSchemaFunction(function()
	WildlifeManager.xmlSchema = XMLSchema.new("wildlife")
	WildlifeManager.registerXMLPaths(WildlifeManager.xmlSchema)
end)

function WildlifeManager.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.STRING, "wildlife.annotation", "Copyright annotation")
	xmlSchema:register(XMLValueType.STRING, "wildlife.groups.group(?)#name", "Name of the wildlife group", nil, true)
	xmlSchema:register(XMLValueType.INT, "wildlife.groups.group(?)#maxNumInstances", "Maximum number of instances of this wildlife group", nil, false)
	xmlSchema:register(XMLValueType.STRING, "wildlife.species.species(?)#filename", "The config filename of the wildlife species", nil, true)
	xmlSchema:register(XMLValueType.STRING_LIST, "wildlife.species.species(?)#groups", "List of group names this wildlife species belongs to", nil, true)
end
function WildlifeManager.new()
	-- upvalues: (copy) WildlifeManager_mt
	local v3_ = WildlifeManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_.nameToGroup = {}
	v4_.speciesToGroups = {}
	v4_.species = {}
	v4_.nameToSpecies = {}
	v4_.modSpecies = {}
	v4_.usedBudget = 0
	v4_.maximumBudget = 100
	v4_.speciesSpawnPending = false
	v4_.debugDrawActive = false
	return v4_
end

function WildlifeManager:registerModWildlifeFile(filename, baseDirectory, groupNames)
	local v9_ = self.modSpecies
	table.insert(v9_, {
		["filename"] = filename,
		["baseDirectory"] = baseDirectory,
		["groupNames"] = groupNames
	})
end

-- Local values: _, species
function WildlifeManager:unloadMapData()
	for _, v11_ in pairs(self.species) do
		v11_:delete()
	end
	table.clear(self.species)
	table.clear(self.nameToGroup)
	table.clear(self.nameToSpecies)
	table.clear(self.modSpecies)
	removeConsoleCommand("gsWildlifeSpawn")
	removeConsoleCommand("gsWildlifeDebugToggle")
end

-- Local values: filename, wildlifeXMLFile, _, groupKey, name, maxNumInstances, _, speciesKey, speciesFilename, groupNames, species, _, groupName, group, _, modSpecies, speciesFilename, species, _, groupName, group
function WildlifeManager:loadMapData(xmlFile, baseDirectory)
	local v15_ = getXMLString(xmlFile, "map.wildlife#filename")
	if v15_ == nil then
		Logging.info("No wildlife file defined in map, skipping")
		return
	end
	local v16_ = Utils.getFilename(v15_, baseDirectory)
	local v17_ = XMLFile.load("wildlife", v16_, WildlifeManager.xmlSchema)
	if v17_ == nil then
		Logging.error("Could not load wildlife file at %s. Note that default wildlife is now stored under data/animals/wildlife.", v16_)
		return
	end
	for _, v18_ in v17_:iterator("wildlife.groups.group") do
		local v19_ = v17_:getValue(v18_ .. "#name")
		if v19_ == nil then
			Logging.xmlWarning(v17_, "Missing group name for \'%s\'", v18_)
			break
		end
		self:addGroup(v19_, (v17_:getValue(v18_ .. "#maxNumInstances")))
	end
	for _, v20_ in v17_:iterator("wildlife.species.species") do
		local v21_ = v17_:getValue(v20_ .. "#filename")
		if v21_ == nil then
			Logging.xmlWarning(v17_, "Missing filename for wildlife species \'%s\'", v20_)
		else
			local v22_ = v17_:getValue(v20_ .. "#groups")
			local v23_ = self:loadSpecies(Utils.getFilename(v21_, baseDirectory), baseDirectory)
			if v23_ ~= nil then
				self.speciesToGroups[v23_] = {}
				for _, v24_ in ipairs(v22_) do
					local v25_ = self:addGroup(v24_, nil)
					table.addElement(v25_.species, v23_)
					table.addElement(self.speciesToGroups[v23_], v25_)
				end
			end
		end
	end
	v17_:delete()
	for _, v26_ in ipairs(self.modSpecies) do
		local v27_ = self:loadSpecies(Utils.getFilename(v26_.filename, v26_.baseDirectory), v26_.baseDirectory)
		if v27_ ~= nil then
			self.speciesToGroups[v27_] = self.speciesToGroups[v27_] or {}
			for _, v28_ in ipairs(v26_.groupNames) do
				local v29_ = self:addGroup(v28_, nil)
				table.addElement(v29_.species, v27_)
				table.addElement(self.speciesToGroups[v27_], v29_)
			end
		end
	end
	table.clear(self.modSpecies)
	self:initialise()
	if g_isDevelopmentVersion then
		addConsoleCommand("gsWildlifeSpawn", "Spawns a species instance", "consoleCommandSpawnSpecies", self, "speciesName;distance;numInstances;rotation", false)
		addConsoleCommand("gsWildlifeDebugToggle", "Toggles debug draw", "consoleCommandToggleDebugDraw", self)
	end
end

-- Local values: groupNameUpper, group
function WildlifeManager:addGroup(groupName, maxNumInstances)
	local v33_ = string.upper(groupName)
	if self.nameToGroup[v33_] ~= nil then
		return self.nameToGroup[v33_]
	end
	local v34_ = {
		["name"] = groupName,
		["species"] = {},
		["maxNumInstances"] = maxNumInstances,
		["numInstances"] = 0
	}
	self.nameToGroup[v33_] = v34_
	return v34_
end

-- Local values: species, name
function WildlifeManager:loadSpecies(filename, baseDirectory)
	local v38_ = WildlifeUtil.createFromXMLFilename(filename, baseDirectory)
	if v38_ == nil then
		return nil
	end
	local v39_ = string.upper(v38_.name)
	if self.nameToSpecies[v39_] ~= nil then
		Logging.warning("Wildlife species \'%s\' already defined", v38_.name)
		v38_:delete()
		return nil
	end
	self.nameToSpecies[v39_] = v38_
	local v40_ = self.species
	table.insert(v40_, v38_)
	return v38_
end

-- Local values: i, species
function WildlifeManager:initialise()
	for _, v42_ in ipairs(self.species) do
		v42_:initialise()
	end
end

-- Local values: _, group, _, species, groups, numInstances, _, group
function WildlifeManager:update(dt)
	if g_localPlayer then
		for _, v45_ in pairs(self.nameToGroup) do
			v45_.numInstances = 0
		end
		self.usedBudget = 0
		for _, v46_ in ipairs(self.species) do
			v46_:update(dt)
			v46_.canBeSpawned = true
			self.usedBudget = self.usedBudget + v46_:getCosts()
			local v47_ = self.speciesToGroups[v46_]
			if v47_ ~= nil then
				local v48_ = v46_:getNumInstances()
				for _, v49_ in ipairs(v47_) do
					v49_.numInstances = v49_.numInstances + v48_
					if v49_.maxNumInstances ~= nil and v49_.numInstances >= v49_.maxNumInstances then
						v46_.canBeSpawned = false
					end
				end
			end
		end
		self:trySpawnWildlife()
	end
end

-- Local values: i, x, y, groupName, group, _, species
function WildlifeManager:drawDebug()
	local v51_ = 0.8
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(true)
	renderText(0.8, v51_, 0.012, "Wildlife Groups")
	setTextBold(false)
	for v52_, v53_ in pairs(self.nameToGroup) do
		v51_ = v51_ - 0.015
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.8, v51_, 0.012, string.format("%s : ", v52_))
		setTextAlignment(RenderText.ALIGN_LEFT)
		if v53_.maxNumInstances ~= nil and v53_.numInstances >= v53_.maxNumInstances then
			setTextColor(1, 0, 0, 1)
		end
		renderText(0.8, v51_, 0.012, string.format("%d / %d", v53_.numInstances, v53_.maxNumInstances or -1))
		setTextColor(1, 1, 1, 1)
	end
	local v54_ = v51_ - 0.025
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(true)
	renderText(0.8, v54_, 0.012, "Wildlife Species")
	setTextBold(false)
	for _, v55_ in pairs(self.species) do
		v54_ = v54_ - 0.015
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.8, v54_, 0.012, string.format("%s : ", v55_.name))
		setTextAlignment(RenderText.ALIGN_LEFT)
		if v55_.canBeSpawned == false then
			setTextColor(1, 0, 0, 1)
		end
		renderText(0.8, v54_, 0.012, string.format("%d => %d", v55_:getNumInstances(), v55_:getCosts()))
		setTextColor(1, 1, 1, 1)
		v55_:drawDebug()
	end
end

-- Local values: species, _, s, playerX, playerZ, playerRotY, cameraFovY, canSpawn, spawnCallback
function WildlifeManager:trySpawnWildlife()
	if g_localPlayer == nil or g_localPlayer:getCurrentRootNode() == nil then
		return
	end
	if self.speciesSpawnPending then
		return
	end
	if self.usedBudget >= self.maximumBudget then
		return
	end
	local v_u_57_ = nil
	for _, v58_ in ipairs_randomStart(self.species) do
		if v58_.canBeSpawned then
			v_u_57_ = v58_
			break
		end
	end
	if v_u_57_ == nil then
		return
	else
		local v59_, v60_, v61_ = g_localPlayer:getMapPositionAndLookYaw()
		local v62_ = getFovY(g_cameraManager:getActiveCamera())
		if v_u_57_:getCanSpawnInstance() then
			self.speciesSpawnPending = true
			v_u_57_:trySpawnAt(v59_, v60_, v61_, v62_, function(p63_)
				-- upvalues: (copy) self, (ref) v_u_57_
				self.speciesSpawnPending = false
				v_u_57_:resetSpawnTimer(p63_)
			end)
		end
	end
end

-- Local values: species, x, z, rotY, dirX, dirZ, y
function WildlifeManager:consoleCommandSpawnSpecies(speciesName, distance, numInstances, rot)
	if speciesName == nil then
		printError("Missing species name")
		return string.format("Available species: %s", table.concatKeys(self.nameToSpecies, ", "))
	end
	local v69_ = tonumber(distance) or 50
	local v70_ = tonumber(numInstances) or 1
	local v71_ = math.clamp(v70_, 1, 100)
	local v72_ = tonumber(rot) or 0
	local v73_ = math.rad(v72_)
	local v74_ = self.nameToSpecies[string.upper(speciesName)]
	if v74_ == nil then
		printError(string.format("Species \'%s\' not defined for map", speciesName))
		return string.format("Available species: %s", table.concatKeys(self.nameToSpecies, ", "))
	end
	local v75_, v76_, v77_ = g_localPlayer:getMapPositionAndLookYaw()
	local v78_, v79_ = MathUtil.getDirectionFromYRotation(v77_)
	local v80_ = v75_ + v78_ * v69_
	local v81_ = v76_ + v79_ * v69_
	v74_:debugSpawn(v80_, getTerrainHeightAtWorldPos(g_terrainNode, v80_, 0, v81_), v81_, v71_, v73_)
	return "Spawned species instances"
end

function WildlifeManager:consoleCommandToggleDebugDraw()
	self.debugDrawActive = not self.debugDrawActive
	if self.debugDrawActive then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
	return string.format("DebugDraw=%s", self.debugDrawActive)
end
g_wildlifeManager = WildlifeManager.new()
