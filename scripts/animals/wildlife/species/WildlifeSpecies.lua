-- Local values: WildlifeSpecies_mt
WildlifeSpecies = {}
local WildlifeSpecies_mt = Class(WildlifeSpecies)
WildlifeSpecies.SPAWN_COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.WATER
WildlifeSpecies.BASE_SPAWN_RULES_DIRECTORY = "dataS/scripts/animals/wildlife/spawnRules/"

function WildlifeSpecies.formatRange(range)
	return type(range) ~= "table" and "nil" or string.format("min: %.2f, max: %.2f", range.minimum, range.maximum)
end
g_xmlManager:addCreateSchemaFunction(function()
	WildlifeSpecies.xmlSchema = XMLSchema.new("wildlifeSpecies")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v3_ = WildlifeSpecies.xmlSchema
	v3_:register(XMLValueType.STRING, "species.annotation", "Copyright annotation")
	v3_:register(XMLValueType.STRING, "species.class", "The controller class of the wildlife species", nil, true)
	v3_:register(XMLValueType.STRING, "species.name", "The name of the wildlife species", nil, true)
	v3_:register(XMLValueType.INT, "species.settings#maxNumInstances", "Max number of instances per species", nil, true)
	v3_:register(XMLValueType.FLOAT, "species.settings#costPerAnimal", "The spawn cost of the wildlife species", nil, true)
	v3_:register(XMLValueType.FLOAT, "species.settings#fleeDistance", "Flee distance")
	v3_:register(XMLValueType.FLOAT, "species.settings.foliageBending#minX", "Min. width")
	v3_:register(XMLValueType.FLOAT, "species.settings.foliageBending#maxX", "Max. width")
	v3_:register(XMLValueType.FLOAT, "species.settings.foliageBending#minZ", "Min. length")
	v3_:register(XMLValueType.FLOAT, "species.settings.foliageBending#maxZ", "Max. length")
	v3_:register(XMLValueType.FLOAT, "species.settings.foliageBending#yOffset", "Y translation offset")
	v3_:register(XMLValueType.FLOAT, "species.settings.spawnTimer#minSeconds", "Min time need to pass by to spawn a new instance")
	v3_:register(XMLValueType.FLOAT, "species.settings.spawnTimer#maxSeconds", "Max time need to pass by to spawn a new instance")
	v3_:register(XMLValueType.FLOAT, "species.settings.spawnTimer#retryMinSeconds", "Min time need to pass by to try spawning a new instance after a spawn failure")
	v3_:register(XMLValueType.FLOAT, "species.settings.spawnTimer#retryMaxSeconds", "Max time need to pass by to try spawning a new instance after a spawn failure")
	v3_:register(XMLValueType.FLOAT, "species.settings.despawn#radius", "Distance to player after a instance will despawn")
	v3_:register(XMLValueType.FLOAT, "species.settings.spawn#radiusMin", "A instance cannot spawn within the min radius")
	v3_:register(XMLValueType.FLOAT, "species.settings.spawn#radiusMax", "A instance cannot spawn if distance is greater than max radius")
	v3_:register(XMLValueType.DAY_TIME, "species.settings.time#from", "Start day time")
	v3_:register(XMLValueType.DAY_TIME, "species.settings.time#to", "End day time")
	v3_:register(XMLValueType.FLOAT, "species.settings.treeCheck#radius", "", nil, false)
	v3_:register(XMLValueType.FLOAT, "species.settings.treeCheck#height", "", nil, false)
	v3_:register(XMLValueType.INT, "species.settings.treeCheck#minNumTrees", "", nil, false)
end)

-- Upvalues: WildlifeSpecies_mt
-- Local values: self
function WildlifeSpecies.new(customMt)
	-- upvalues: (copy) WildlifeSpecies_mt
	local v5_ = customMt or WildlifeSpecies_mt
	local v6_ = setmetatable({}, v5_)
	v6_.name = nil
	v6_.costPerAnimal = 1
	v6_.maxNumInstances = 1
	v6_.instances = {}
	v6_.fleeDistance = nil
	v6_.foliageBendingArea = nil
	v6_.spawnTimerMinSeconds = 60000
	v6_.spawnTimerMaxSeconds = 60000
	v6_.spawnTimer = v6_.spawnTimerMinSeconds
	v6_.despawnRadius = 200
	v6_.spawnRadiusMin = 120
	v6_.spawnRadiusMax = 150
	v6_.treeCheckRadius = 15
	v6_.treeCheckHeight = 15
	v6_.treeCheckMinNumTrees = 15
	v6_.pooledInstances = ObjectPool.new(v6_:getInstanceConstructor(), v6_)
	return v6_
end

function WildlifeSpecies:initialise() end

function WildlifeSpecies:getInstanceConstructor()
	return WildlifeInstance.new
end

-- Local values: _, instance, _, instance
function WildlifeSpecies:delete()
	for _, v8_ in pairs(self.instances) do
		self.pooledInstances:returnToPool(v8_)
	end
	table.clear(self.instances)
	for _, v9_ in pairs(self.pooledInstances.pool) do
		v9_:delete()
	end
	self.pooledInstances:clear()
end

-- Local values: foliageBendingKey
function WildlifeSpecies:loadFromXML(xmlFile, baseDirectory)
	self.name = xmlFile:getValue("species.name")
	if self.name == nil then
		Logging.xmlWarning(xmlFile, "Missing wildlife species name")
		return false
	end
	self.isSpawnPending = false
	self.spawnCallbackFunc = nil
	self.costPerAnimal = xmlFile:getValue("species.settings#costPerAnimal", 1)
	self.maxNumInstances = xmlFile:getValue("species.settings#maxNumInstances", 1)
	self.fleeDistance = xmlFile:getValue("species.settings#fleeDistance", self.fleeDistance)
	self.timeFrom = xmlFile:getValue("species.settings.time#from") or 0
	self.timeTo = xmlFile:getValue("species.settings.time#to") or 86400000
	self.spawnTimerRetryMinSeconds = xmlFile:getValue("species.settings.spawnTimer#retryMinSeconds", 5) * 1000
	self.spawnTimerRetryMaxSeconds = xmlFile:getValue("species.settings.spawnTimer#retryMaxSeconds", 10) * 1000
	self.spawnTimerMinSeconds = xmlFile:getValue("species.settings.spawnTimer#minSeconds", 10) * 1000
	self.spawnTimerMaxSeconds = xmlFile:getValue("species.settings.spawnTimer#maxSeconds", 60) * 1000
	self:resetSpawnTimer(true)
	if xmlFile:hasProperty("species.settings.foliageBending") then
		self.foliageBendingArea = {}
		self.foliageBendingArea.minX = xmlFile:getValue("species.settings.foliageBending#minX", -1)
		self.foliageBendingArea.maxX = xmlFile:getValue("species.settings.foliageBending#maxX", 1)
		self.foliageBendingArea.minZ = xmlFile:getValue("species.settings.foliageBending#minZ", -1)
		self.foliageBendingArea.maxZ = xmlFile:getValue("species.settings.foliageBending#maxZ", 1)
		self.foliageBendingArea.yOffset = xmlFile:getValue("species.settings.foliageBending#yOffset", 0)
	end
	self.despawnRadius = xmlFile:getValue("species.settings.despawn#radius", self.despawnRadius)
	self.spawnRadiusMin = xmlFile:getValue("species.settings.spawn#radiusMin", self.spawnRadiusMin)
	self.spawnRadiusMax = xmlFile:getValue("species.settings.spawn#radiusMax", self.spawnRadiusMax)
	self.treeCheckRadius = xmlFile:getValue("species.settings.treeCheck#radius", self.treeCheckRadius)
	self.treeCheckHeight = xmlFile:getValue("species.settings.treeCheck#height", self.treeCheckHeight)
	self.treeCheckMinNumTrees = xmlFile:getValue("species.settings.treeCheck#minNumTrees", self.treeCheckMinNumTrees)
	return true
end

-- Local values: playerX, playerZ, playerRotY, k, instance
function WildlifeSpecies:update(dt)
	self.spawnTimer = self.spawnTimer - dt
	local v14_, v15_, v16_ = g_localPlayer:getMapPositionAndLookYaw()
	for _, v17_ in ipairs_reverse(self.instances) do
		v17_:update(dt)
		if self:getCanDespawnInstance(v17_, v14_, v15_, v16_) then
			self:despawn(v17_)
		end
	end
end

-- Local values: k, instance
function WildlifeSpecies:drawDebug()
	for _, v19_ in ipairs(self.instances) do
		v19_:drawDebug()
	end
end

-- Local values: distance
function WildlifeSpecies:getCanDespawnInstance(instance, playerX, playerZ, playerRotY)
	return instance:calculateDistanceFrom(playerX, playerZ) > self.despawnRadius
end

-- Local values: numInstances, _, instance
function WildlifeSpecies:getCosts()
	local v25_ = 0
	for _, v26_ in ipairs(self.instances) do
		v25_ = v26_:getNumAnimals()
	end
	return v25_ * self.costPerAnimal
end

function WildlifeSpecies:getNumInstances()
	return #self.instances
end

function WildlifeSpecies:despawn(instance)
	if instance ~= nil then
		instance:despawn()
		self:removeInstance(instance)
	end
end

function WildlifeSpecies:removeInstance(instance)
	table.removeElement(self.instances, instance)
	self.pooledInstances:returnToPool(instance)
end

-- Local values: instance
function WildlifeSpecies:createInstance()
	local v33_ = self.pooledInstances:getOrCreateNext()
	table.addElement(self.instances, v33_)
	return v33_
end

-- Local values: dayTime
function WildlifeSpecies:getCanSpawnInstance()
	if self.spawnTimer > 0 then
		return false
	end
	if #self.instances >= self.maxNumInstances then
		return false
	end
	if self.isSpawnPending then
		return false
	end
	local v35_ = g_currentMission.environment.dayTime
	return not MathUtil.getIsOutOfBounds(v35_, self.timeFrom, self.timeTo)
end

function WildlifeSpecies:resetSpawnTimer(success)
	if success then
		self.spawnTimer = MathUtil.randomFloat(self.spawnTimerMinSeconds, self.spawnTimerMaxSeconds)
	else
		self.spawnTimer = MathUtil.randomFloat(self.spawnTimerRetryMinSeconds, self.spawnTimerRetryMaxSeconds)
	end
end

function WildlifeSpecies:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
	if self.isSpawnPending then
		callbackFunc(false)
		return false
	end
	self.spawnCallbackFunc = callbackFunc
	self.isSpawnPending = true
	return true
end

function WildlifeSpecies:debugSpawn(x, y, z, numInstances)
	self.isSpawnPending = true
end

function WildlifeSpecies:finishSpawning(success)
	if self.spawnCallbackFunc ~= nil then
		self.spawnCallbackFunc(success)
		self.spawnCallbackFunc = nil
	end
	self.isSpawnPending = false
end

-- Local values: onFinishCallback
function WildlifeSpecies:runForestCheck(x, y, z, callbackFunc)
	WildlifeUtil.getNumOfTrees(x, y, z, self.treeCheckRadius, self.treeCheckHeight, function(p48_)
		-- upvalues: (copy) callbackFunc, (copy) self
		callbackFunc(self.treeCheckMinNumTrees <= p48_)
	end)
end
