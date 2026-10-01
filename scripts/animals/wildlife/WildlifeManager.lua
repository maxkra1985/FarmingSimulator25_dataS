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
	local self = setmetatable({}, WildlifeManager_mt)
	self.nameToGroup = {}
	self.speciesToGroups = {}
	self.species = {}
	self.nameToSpecies = {}
	self.modSpecies = {}
	self.usedBudget = 0
	self.maximumBudget = 100
	self.speciesSpawnPending = false
	self.debugDrawActive = false
	return self
end
function WildlifeManager:registerModWildlifeFile(filename, baseDirectory, groupNames)
	table.insert(self.modSpecies, { filename = filename, baseDirectory = baseDirectory, groupNames = groupNames })
end
function WildlifeManager:unloadMapData()
	for _, species in pairs(self.species) do
		species:delete()
	end
	table.clear(self.species)
	table.clear(self.nameToGroup)
	table.clear(self.nameToSpecies)
	table.clear(self.modSpecies)
	removeConsoleCommand("gsWildlifeSpawn")
	removeConsoleCommand("gsWildlifeDebugToggle")
end
function WildlifeManager:loadMapData(xmlFile, baseDirectory)
	local filename = getXMLString(xmlFile, "map.wildlife#filename")
	if filename == nil then
		Logging.info("No wildlife file defined in map, skipping")
		return
	end
	filename = Utils.getFilename(filename, baseDirectory)
	local wildlifeXMLFile = XMLFile.load("wildlife", filename, WildlifeManager.xmlSchema)
	if wildlifeXMLFile == nil then
		Logging.error("Could not load wildlife file at %s. Note that default wildlife is now stored under data/animals/wildlife.", filename)
	else
		for _, groupKey in wildlifeXMLFile:iterator("wildlife.groups.group") do
			local name = wildlifeXMLFile:getValue(groupKey .. "#name")
			if name == nil then
				Logging.xmlWarning(wildlifeXMLFile, "Missing group name for '%s'", groupKey)
				break
			end
			local maxNumInstances = wildlifeXMLFile:getValue(groupKey .. "#maxNumInstances")
			self:addGroup(name, maxNumInstances)
		end
		for _, speciesKey in wildlifeXMLFile:iterator("wildlife.species.species") do
			local speciesFilename = wildlifeXMLFile:getValue(speciesKey .. "#filename")
			if speciesFilename == nil then
				Logging.xmlWarning(wildlifeXMLFile, "Missing filename for wildlife species '%s'", speciesKey)
			else
				local groupNames = wildlifeXMLFile:getValue(speciesKey .. "#groups")
				speciesFilename = Utils.getFilename(speciesFilename, baseDirectory)
				local species = self:loadSpecies(speciesFilename, baseDirectory)
				if species == nil then
					continue
				end
				self.speciesToGroups[species] = {}
				for _, groupName in ipairs(groupNames) do
					local group = self:addGroup(groupName, nil)
					table.addElement(group.species, species)
					table.addElement(self.speciesToGroups[species], group)
				end
			end
		end
		wildlifeXMLFile:delete()
		for _, modSpecies in ipairs(self.modSpecies) do
			local speciesFilename = Utils.getFilename(modSpecies.filename, modSpecies.baseDirectory)
			local species = self:loadSpecies(speciesFilename, modSpecies.baseDirectory)
			if species == nil then
				continue
			end
			self.speciesToGroups[species] = self.speciesToGroups[species] or {}
			for _, groupName in ipairs(modSpecies.groupNames) do
				local group = self:addGroup(groupName, nil)
				table.addElement(group.species, species)
				table.addElement(self.speciesToGroups[species], group)
			end
		end
		table.clear(self.modSpecies)
		self:initialise()
		if g_isDevelopmentVersion then
			addConsoleCommand("gsWildlifeSpawn", "Spawns a species instance", "consoleCommandSpawnSpecies", self, "speciesName;distance;numInstances;rotation", false)
			addConsoleCommand("gsWildlifeDebugToggle", "Toggles debug draw", "consoleCommandToggleDebugDraw", self)
		end
	end
end
function WildlifeManager:addGroup(groupName, maxNumInstances)
	local groupNameUpper = string.upper(groupName)
	if self.nameToGroup[groupNameUpper] ~= nil then
		return self.nameToGroup[groupNameUpper]
	else
		local group = { name = groupName, maxNumInstances = maxNumInstances }
		group.species = {}
		group.numInstances = 0
		self.nameToGroup[groupNameUpper] = group
		return group
	end
end
function WildlifeManager:loadSpecies(filename, baseDirectory)
	local species = WildlifeUtil.createFromXMLFilename(filename, baseDirectory)
	if species == nil then
		return nil
	end
	local name = string.upper(species.name)
	if self.nameToSpecies[name] ~= nil then
		Logging.warning("Wildlife species '%s' already defined", species.name)
		species:delete()
		return nil
	else
		self.nameToSpecies[name] = species
		table.insert(self.species, species)
		return species
	end
end
function WildlifeManager:initialise()
	for i, species in ipairs(self.species) do
		species:initialise()
	end
end
function WildlifeManager:update(dt)
	if not g_localPlayer then
		return
	else
		for _, group in pairs(self.nameToGroup) do
			group.numInstances = 0
		end
		self.usedBudget = 0
		for _, species in ipairs(self.species) do
			species:update(dt)
			species.canBeSpawned = true
			self.usedBudget = self.usedBudget + species:getCosts()
			local groups = self.speciesToGroups[species]
			if groups == nil then
				continue
			end
			local numInstances = species:getNumInstances()
			for _, group in ipairs(groups) do
				group.numInstances = group.numInstances + numInstances
				if group.maxNumInstances == nil then
					continue
				end
				if group.maxNumInstances <= group.numInstances then
					species.canBeSpawned = false
				end
			end
		end
		self:trySpawnWildlife()
	end
end
function WildlifeManager:drawDebug()
	local i = 0
	local x = 0.8
	local y = 0.8
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(true)
	renderText(0.8, y, 0.012, "Wildlife Groups")
	setTextBold(false)
	for groupName, group in pairs(self.nameToGroup) do
		y = y - 0.015
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.8, y, 0.012, string.format("%s : ", groupName))
		setTextAlignment(RenderText.ALIGN_LEFT)
		if group.maxNumInstances ~= nil and group.maxNumInstances <= group.numInstances then
			setTextColor(1, 0, 0, 1)
		end
		renderText(0.8, y, 0.012, string.format("%d / %d", group.numInstances, group.maxNumInstances or -1))
		setTextColor(1, 1, 1, 1)
	end
	y = y - 0.025
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(true)
	renderText(0.8, y, 0.012, "Wildlife Species")
	setTextBold(false)
	for _, species in pairs(self.species) do
		y = y - 0.015
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.8, y, 0.012, string.format("%s : ", species.name))
		setTextAlignment(RenderText.ALIGN_LEFT)
		if species.canBeSpawned == false then
			setTextColor(1, 0, 0, 1)
		end
		renderText(0.8, y, 0.012, string.format("%d => %d", species:getNumInstances(), species:getCosts()))
		setTextColor(1, 1, 1, 1)
		species:drawDebug()
	end
end
function WildlifeManager:trySpawnWildlife()
	if g_localPlayer == nil or g_localPlayer:getCurrentRootNode() == nil then
		return
	end
	if self.speciesSpawnPending then
		return
	end
	if self.maximumBudget <= self.usedBudget then
		return
	end
	local species = nil
	for _, s in ipairs_randomStart(self.species) do
		if s.canBeSpawned then
			species = s
			break
		end
	end
	if species == nil then
		return
	end
	local playerX, playerZ, playerRotY = g_localPlayer:getMapPositionAndLookYaw()
	local cameraFovY = getFovY(g_cameraManager:getActiveCamera())
	local canSpawn = species:getCanSpawnInstance()
	if not canSpawn then
	else
		self.speciesSpawnPending = true
		local spawnCallback = function(success)
			self.speciesSpawnPending = false
			species:resetSpawnTimer(success)
		end
		species:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, spawnCallback)
	end
end
function WildlifeManager:consoleCommandSpawnSpecies(speciesName, distance, numInstances, rot)
	if speciesName == nil then
		printError("Missing species name")
		return string.format("Available species: %s", table.concatKeys(self.nameToSpecies, ", "))
	end
	distance = tonumber(distance) or 50
	numInstances = math.clamp(tonumber(numInstances) or 1, 1, 100)
	rot = math.rad(tonumber(rot) or 0)
	local species = self.nameToSpecies[string.upper(speciesName)]
	if species == nil then
		printError(string.format("Species '%s' not defined for map", speciesName))
		return string.format("Available species: %s", table.concatKeys(self.nameToSpecies, ", "))
	else
		local x, z, rotY = g_localPlayer:getMapPositionAndLookYaw()
		local dirX, dirZ = MathUtil.getDirectionFromYRotation(rotY)
		x = x + dirX * distance
		z = z + dirZ * distance
		local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		species:debugSpawn(x, y, z, numInstances, rot)
		return "Spawned species instances"
	end
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
