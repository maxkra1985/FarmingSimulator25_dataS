WildlifeSpeciesAlligator = {}
local WildlifeSpeciesAlligator_mt = Class(WildlifeSpeciesAlligator, WildlifeSpecies)
WildlifeSpeciesAlligator.DEFAULT_SKELETON_INDEX = "0"
WildlifeSpeciesAlligator.DEFAULT_FLEE_DISTANCE = 4
WildlifeSpeciesAlligator.DEFAULT_WALK_SPEED = 1.2
WildlifeSpeciesAlligator.DEFAULT_SWIM_SPEED = 1.8
WildlifeSpeciesAlligator.DEFAULT_FAST_SWIM_SPEED = WildlifeSpeciesAlligator.DEFAULT_SWIM_SPEED
WildlifeSpeciesAlligator.DEFAULT_FAST_SWIM_DISTANCE = 0
WildlifeSpeciesAlligator.DEFAULT_IN_WATER_Y_OFFSET = 0
WildlifeSpeciesAlligator.MIN_WADE_DEPTH = 0.05
WildlifeSpeciesAlligator.DEFAULT_MAX_WALK_DISTANCE = 60
WildlifeSpeciesAlligator.DEFAULT_FRONT_OFFSET = 0.9
WildlifeSpeciesAlligator.DEFAULT_BACK_OFFSET = -0.9
WildlifeSpeciesAlligator.DEFAULT_SIDE_OFFSET = 0.25
WildlifeSpeciesAlligator.DEFAULT_GROUND_Y_OFFSET = 0
WildlifeSpeciesAlligator.DEFAULT_SWIM_DISTANCE_MIN = 8
WildlifeSpeciesAlligator.DEFAULT_SWIM_DISTANCE_MAX = 15
WildlifeSpeciesAlligator.DEFAULT_BANK_CLEARANCE = 0
g_xmlManager:addInitSchemaFunction(function()
	local xmlSchema = WildlifeSpecies.xmlSchema
	local basePath = "species.alligator"
	xmlSchema:register(XMLValueType.STRING, "species.alligator" .. ".asset#filename", "Asset i3d file holding the animated skeleton, the renderable mesh and the animation clips", nil, true)
	xmlSchema:register(XMLValueType.STRING, "species.alligator" .. ".asset#skeletonNode", "Index path of the skeleton root inside the asset i3d", WildlifeSpeciesAlligator.DEFAULT_SKELETON_INDEX)
	xmlSchema:register(XMLValueType.INT, "species.alligator" .. ".asset.texture(?)#tileUIndex", "U index of the tile of the diffuse atlas this variant uses", 0)
	xmlSchema:register(XMLValueType.INT, "species.alligator" .. ".asset.texture(?)#tileVIndex", "V index of the tile of the diffuse atlas this variant uses", 0)
	xmlSchema:register(XMLValueType.INT, "species.alligator" .. ".asset.texture(?)#numTilesU", "Number of tiles of the diffuse atlas in U", 1)
	xmlSchema:register(XMLValueType.INT, "species.alligator" .. ".asset.texture(?)#numTilesV", "Number of tiles of the diffuse atlas in V", 1)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#walkSpeed", "Speed in m/s an instance walks towards the water at", WildlifeSpeciesAlligator.DEFAULT_WALK_SPEED)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#maxWalkDistance", "Distance in meters an instance walks while escaping before it gives up on reaching water and stops", WildlifeSpeciesAlligator.DEFAULT_MAX_WALK_DISTANCE)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#swimSpeed", "Speed in m/s an instance swims at", WildlifeSpeciesAlligator.DEFAULT_SWIM_SPEED)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#fastSwimSpeed", "Speed in m/s an instance swims the beginning of its escape at", WildlifeSpeciesAlligator.DEFAULT_FAST_SWIM_SPEED)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#fastSwimDistance", "Distance in meters an instance covers at the faster swim speed before it settles to the swim speed", WildlifeSpeciesAlligator.DEFAULT_FAST_SWIM_DISTANCE)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#inWaterYOffset", "Height offset in meters applied to the water surface while an instance swims", WildlifeSpeciesAlligator.DEFAULT_IN_WATER_Y_OFFSET)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#minSwimDistance", "Min. distance in meters an instance swims before it despawns", WildlifeSpeciesAlligator.DEFAULT_SWIM_DISTANCE_MIN)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#maxSwimDistance", "Max. distance in meters an instance swims before it despawns", WildlifeSpeciesAlligator.DEFAULT_SWIM_DISTANCE_MAX)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".movement#bankClearance", "Distance in meters a swimming instance stops short of the bank it swims towards", WildlifeSpeciesAlligator.DEFAULT_BANK_CLEARANCE)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".groundAlignment#frontOffset", "Longitudinal offset of the front ground sample the body is aligned to", WildlifeSpeciesAlligator.DEFAULT_FRONT_OFFSET)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".groundAlignment#backOffset", "Longitudinal offset of the two rear ground samples the body is aligned to", WildlifeSpeciesAlligator.DEFAULT_BACK_OFFSET)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".groundAlignment#sideOffset", "Lateral half distance between the two rear ground samples", WildlifeSpeciesAlligator.DEFAULT_SIDE_OFFSET)
	xmlSchema:register(XMLValueType.FLOAT, "species.alligator" .. ".groundAlignment#yOffset", "Height offset in meters of the body above the ground it is aligned to", WildlifeSpeciesAlligator.DEFAULT_GROUND_Y_OFFSET)
	xmlSchema:register(XMLValueType.VECTOR_3, "species.alligator" .. ".shallowWaterObstacle#size", "Size in meters of the body as an obstacle in the shallow water simulation, no obstacle if not set")
	ConditionalAnimation.registerXMLPaths(xmlSchema, "species.alligator" .. ".conditionalAnimation")
end)
function WildlifeSpeciesAlligator.new(customMt)
	local self = WildlifeSpeciesAlligator:superClass().new(customMt or WildlifeSpeciesAlligator_mt)
	self.configFilename = nil
	self.assetFilename = nil
	self.skeletonIndex = WildlifeSpeciesAlligator.DEFAULT_SKELETON_INDEX
	self.fleeDistance = WildlifeSpeciesAlligator.DEFAULT_FLEE_DISTANCE
	self.walkSpeed = WildlifeSpeciesAlligator.DEFAULT_WALK_SPEED
	self.maxWalkDistance = WildlifeSpeciesAlligator.DEFAULT_MAX_WALK_DISTANCE
	self.swimSpeed = WildlifeSpeciesAlligator.DEFAULT_SWIM_SPEED
	self.fastSwimSpeed = WildlifeSpeciesAlligator.DEFAULT_FAST_SWIM_SPEED
	self.fastSwimDistance = WildlifeSpeciesAlligator.DEFAULT_FAST_SWIM_DISTANCE
	self.inWaterYOffset = WildlifeSpeciesAlligator.DEFAULT_IN_WATER_Y_OFFSET
	self.frontOffset = WildlifeSpeciesAlligator.DEFAULT_FRONT_OFFSET
	self.backOffset = WildlifeSpeciesAlligator.DEFAULT_BACK_OFFSET
	self.sideOffset = WildlifeSpeciesAlligator.DEFAULT_SIDE_OFFSET
	self.groundYOffset = WildlifeSpeciesAlligator.DEFAULT_GROUND_Y_OFFSET
	self.swimDistanceMin = WildlifeSpeciesAlligator.DEFAULT_SWIM_DISTANCE_MIN
	self.swimDistanceMax = WildlifeSpeciesAlligator.DEFAULT_SWIM_DISTANCE_MAX
	self.bankClearance = WildlifeSpeciesAlligator.DEFAULT_BANK_CLEARANCE
	self.shallowWaterObstacleSize = nil
	self.shallowWaterObstacleOffset = nil
	self.soundAttributes = nil
	self.textureVariants = {}
	self.spawnNodes = {}
	self.spawnNodeVariants = {}
	return self
end
function WildlifeSpeciesAlligator:loadFromXML(xmlFile, baseDirectory)
	local success = WildlifeSpeciesAlligator:superClass().loadFromXML(self, xmlFile, baseDirectory)
	if not success then
		return false
	end
	local assetFilename = xmlFile:getString("species.alligator.asset#filename")
	if assetFilename == nil then
		Logging.xmlWarning(xmlFile, "Missing asset filename for wildlife species '%s'", self.name)
		return false
	else
		local resolvedAssetFilename = Utils.getFilename(assetFilename, baseDirectory)
		self.configFilename = xmlFile:getFilename()
		self.assetFilename = resolvedAssetFilename
		self.skeletonIndex = xmlFile:getString("species.alligator.asset#skeletonNode") or WildlifeSpeciesAlligator.DEFAULT_SKELETON_INDEX
		self.walkSpeed = xmlFile:getFloat("species.alligator.movement#walkSpeed") or self.walkSpeed
		self.maxWalkDistance = xmlFile:getFloat("species.alligator.movement#maxWalkDistance") or self.maxWalkDistance
		self.swimSpeed = xmlFile:getFloat("species.alligator.movement#swimSpeed") or self.swimSpeed
		self.inWaterYOffset = xmlFile:getFloat("species.alligator.movement#inWaterYOffset") or self.inWaterYOffset
		local fastSwimSpeed = xmlFile:getFloat("species.alligator.movement#fastSwimSpeed") or self.fastSwimSpeed
		self.fastSwimSpeed = math.max(fastSwimSpeed, self.swimSpeed)
		self.fastSwimDistance = xmlFile:getFloat("species.alligator.movement#fastSwimDistance") or self.fastSwimDistance
		self.frontOffset = xmlFile:getFloat("species.alligator.groundAlignment#frontOffset") or self.frontOffset
		self.backOffset = xmlFile:getFloat("species.alligator.groundAlignment#backOffset") or self.backOffset
		self.sideOffset = xmlFile:getFloat("species.alligator.groundAlignment#sideOffset") or self.sideOffset
		self.groundYOffset = xmlFile:getFloat("species.alligator.groundAlignment#yOffset") or self.groundYOffset
		self:loadShallowWaterObstacle(xmlFile)
		self.wadeDepth = math.max(self.groundYOffset - self.inWaterYOffset, WildlifeSpeciesAlligator.MIN_WADE_DEPTH)
		local swimDistanceMin = xmlFile:getFloat("species.alligator.movement#minSwimDistance") or self.swimDistanceMin
		local swimDistanceMax = xmlFile:getFloat("species.alligator.movement#maxSwimDistance") or self.swimDistanceMax
		self.swimDistanceMin = swimDistanceMin
		self.swimDistanceMax = math.max(swimDistanceMax, swimDistanceMin)
		local bankClearance = xmlFile:getFloat("species.alligator.movement#bankClearance") or self.bankClearance
		self.bankClearance = math.max(bankClearance, 0)
		self:loadTextureVariants(xmlFile)
		self.soundAttributes = WildlifeInstanceSounds.loadAttributesTable(xmlFile)
		return true
	end
end
function WildlifeSpeciesAlligator:loadTextureVariants(xmlFile)
	for _, textureKey in xmlFile:iterator("species.alligator.asset.texture") do
		local numTilesU = math.max(xmlFile:getInt(textureKey .. "#numTilesU", 1), 1)
		local numTilesV = math.max(xmlFile:getInt(textureKey .. "#numTilesV", 1), 1)
		local tileUIndex = xmlFile:getInt(textureKey .. "#tileUIndex", 0)
		local tileVIndex = xmlFile:getInt(textureKey .. "#tileVIndex", 0)
		local variant = {}
		variant.invSizeU = 1 / numTilesU
		variant.invSizeV = 1 / numTilesV
		variant.offsetU = tileUIndex / numTilesU
		variant.offsetV = tileVIndex / numTilesV
		table.insert(self.textureVariants, variant)
	end
end
function WildlifeSpeciesAlligator:loadShallowWaterObstacle(xmlFile)
	local obstacleSize = xmlFile:getVector("species.alligator.shallowWaterObstacle#size", nil, 3)
	if obstacleSize == nil then
		return
	else
		self.shallowWaterObstacleSize = obstacleSize
		self.shallowWaterObstacleOffset = { 0, obstacleSize[2] * 0.5, 0 }
	end
end
function WildlifeSpeciesAlligator:delete()
	if self.soundAttributes ~= nil then
		WildlifeInstanceSounds.deleteAttributesTable(self.soundAttributes)
		self.soundAttributes = nil
	end
	WildlifeSpeciesAlligator:superClass().delete(self)
end
function WildlifeSpeciesAlligator:initialise()
	WildlifeSpeciesAlligator:superClass().initialise(self)
	local spawnNodes = g_wildlifeManager:getSpawnNodes(self.name)
	if spawnNodes == nil then
		Logging.info("No spawn positions defined for wildlife species '%s', it will not spawn", self.name)
		return
	end
	self.spawnNodes = spawnNodes
	local numVariants = #self.textureVariants
	if numVariants == 0 then
		return
	else
		for i, spawnNode in ipairs(self.spawnNodes) do
			self.spawnNodeVariants[spawnNode] = self.textureVariants[(i - 1) % numVariants + 1]
		end
	end
end
function WildlifeSpeciesAlligator:getInstanceConstructor()
	return WildlifeInstanceAlligator.new
end
function WildlifeSpeciesAlligator:getCanSpawnInstance()
	if #self.spawnNodes == 0 then
		return false
	else
		return WildlifeSpeciesAlligator:superClass().getCanSpawnInstance(self)
	end
end
function WildlifeSpeciesAlligator:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
	if not WildlifeSpeciesAlligator:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
		return false
	end
	local spawnNode = self:getFreeSpawnNodeInRange(playerX, playerZ)
	if spawnNode == nil then
		self:finishSpawning(false)
		return false
	else
		self:spawnInstance(spawnNode)
		return true
	end
end
function WildlifeSpeciesAlligator:spawnInstance(spawnNode)
	local x, y, z = getWorldTranslation(spawnNode)
	local instance = self:createInstance()
	instance:setSpawnNode(spawnNode)
	instance:setTextureVariant(self.spawnNodeVariants[spawnNode])
	instance:spawnAt(x, y, z)
	self:finishSpawning(true)
end
function WildlifeSpeciesAlligator:debugSpawn(x, y, z, numInstances)
	WildlifeSpeciesAlligator:superClass().debugSpawn(self, x, y, z, numInstances)
	local spawnNode = self:getClosestFreeSpawnNode(x, z)
	if spawnNode == nil then
		self:finishSpawning(false)
	else
		self:spawnInstance(spawnNode)
	end
end
function WildlifeSpeciesAlligator:getFreeSpawnNodeInRange(positionX, positionZ)
	for _, spawnNode in ipairs_randomStart(self.spawnNodes) do
		local x, _, z = getWorldTranslation(spawnNode)
		local distance = MathUtil.vector2Length(positionX - x, positionZ - z)
		local isInRange = self.spawnRadiusMin <= distance and distance <= self.spawnRadiusMax
		if isInRange and self:getIsSpawnNodeFree(spawnNode) then
			return spawnNode
		end
	end
	return nil
end
function WildlifeSpeciesAlligator:getClosestFreeSpawnNode(positionX, positionZ)
	local closestSpawnNode = nil
	local closestDistance = math.huge
	for _, spawnNode in ipairs(self.spawnNodes) do
		local x, _, z = getWorldTranslation(spawnNode)
		local distance = MathUtil.vector2Length(positionX - x, positionZ - z)
		if distance < closestDistance and self:getIsSpawnNodeFree(spawnNode) then
			closestSpawnNode = spawnNode
			closestDistance = distance
		end
	end
	return closestSpawnNode
end
function WildlifeSpeciesAlligator:getIsSpawnNodeFree(spawnNode)
	for _, instance in ipairs(self.instances) do
		if instance.spawnNode == spawnNode then
			return false
		end
	end
	return true
end
