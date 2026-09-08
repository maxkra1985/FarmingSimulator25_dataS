-- Local values: WildlifeSpeciesFlyBy_mt
WildlifeSpeciesFlyBy = {}
local WildlifeSpeciesFlyBy_mt = Class(WildlifeSpeciesFlyBy, WildlifeSpecies)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = WildlifeSpecies.xmlSchema
	v2_:register(XMLValueType.INT, "species.flyBy#minNumAnimalsPerInstance")
	v2_:register(XMLValueType.INT, "species.flyBy#maxNumAnimalsPerInstance")
	v2_:register(XMLValueType.FLOAT, "species.flyBy#fallPerMeter")
	v2_:register(XMLValueType.FLOAT, "species.flyBy#climbPerMeter")
	v2_:register(XMLValueType.FLOAT, "species.flyBy#speedKmH")
	v2_:register(XMLValueType.FLOAT, "species.flyBy#minDistanceToGround")
	v2_:register(XMLValueType.FLOAT, "species.flyBy.group#minRadius")
	v2_:register(XMLValueType.FLOAT, "species.flyBy.group#maxRadius")
	WildlifeInstanceGraphics.registerXMLPaths(v2_, "species.flyBy")
end)

-- Upvalues: WildlifeSpeciesFlyBy_mt
-- Local values: self
function WildlifeSpeciesFlyBy.new(customMt)
	-- upvalues: (copy) WildlifeSpeciesFlyBy_mt
	local v4_ = WildlifeSpecies.new(customMt or WildlifeSpeciesFlyBy_mt)
	v4_.moveDistancePerMs = MathUtil.kmhToMps(10) / 1000
	v4_.fallPerMeter = 0.1
	v4_.climbPerMeter = 0.2
	v4_.minDistanceToGround = 20
	v4_.minNumAnimalsPerInstance = 1
	v4_.maxNumAnimalsPerInstance = 1
	v4_.groupMinRadius = 0.5
	v4_.groupMaxRadius = 10
	v4_.graphics = 10
	return v4_
end

-- Local values: success
function WildlifeSpeciesFlyBy:loadFromXML(xmlFile, baseDirectory)
	if not WildlifeSpeciesFlyBy:superClass().loadFromXML(self, xmlFile, baseDirectory) then
		return false
	end
	self.moveDistancePerMs = MathUtil.kmhToMps(xmlFile:getValue("species.flyBy#speedKmH", 20)) / 1000
	self.fallPerMeter = xmlFile:getValue("species.flyBy#fallPerMeter", self.fallPerMeter)
	self.climbPerMeter = xmlFile:getValue("species.flyBy#climbPerMeter", self.climbPerMeter)
	self.minDistanceToGround = xmlFile:getValue("species.flyBy#minDistanceToGround", self.minDistanceToGround)
	local v8_ = xmlFile:getValue("species.flyBy#minNumAnimalsPerInstance", self.minNumAnimalsPerInstance)
	self.minNumAnimalsPerInstance = math.max(v8_, 1)
	local v9_ = xmlFile:getValue("species.flyBy#maxNumAnimalsPerInstance", self.maxNumAnimalsPerInstance)
	self.maxNumAnimalsPerInstance = math.max(v9_, 1)
	self.groupMinRadius = xmlFile:getValue("species.flyBy.group#minRadius", self.groupMinRadius)
	self.groupMaxRadius = xmlFile:getValue("species.flyBy.group#maxRadius", self.groupMaxRadius)
	self.graphics = WildlifeInstanceGraphics.loadAttributesTable(xmlFile, "species.flyBy")
	if self.maxNumAnimalsPerInstance < self.minNumAnimalsPerInstance then
		local v10_ = self.maxNumAnimalsPerInstance
		local v11_ = self.minNumAnimalsPerInstance
		self.minNumAnimalsPerInstance = v10_
		self.maxNumAnimalsPerInstance = v11_
	end
	return true
end

function WildlifeSpeciesFlyBy:getInstanceConstructor()
	return WildlifeInstanceFlyByGroup.new
end

-- Local values: spawnDistance, x, z, terrainY, y, intersectDistance, intersectAngle, intersectX, intersectZ, directionX, directionZ, numAnimals
function WildlifeSpeciesFlyBy:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
	if not WildlifeSpeciesFlyBy:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
		return false
	end
	local v18_ = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
	local v19_, v20_ = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, v18_)
	local v21_ = getTerrainHeightAtWorldPos(g_terrainNode, v19_, 0, v20_) + self.minDistanceToGround
	local v22_ = MathUtil.randomFloat(0, self.spawnRadiusMin)
	local v23_ = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
	local v24_ = playerX + math.cos(v23_) * v22_
	local v25_ = playerZ + math.sin(v23_) * v22_
	local v26_, v27_ = MathUtil.vector2Normalize(v24_ - v19_, v25_ - v20_)
	self:spawnInstances(v19_, v21_, v20_, math.random(self.minNumAnimalsPerInstance, self.maxNumAnimalsPerInstance), v26_, v27_)
	return true
end

-- Local values: instance
function WildlifeSpeciesFlyBy:spawnInstances(x, y, z, numAnimals, flyDirectionX, flyDirectionZ)
	local v35_ = self:createInstance()
	v35_:setFlyDirection(flyDirectionX, flyDirectionZ)
	v35_:setNumAnimals(numAnimals)
	v35_:setGroupRadius(self.groupMinRadius, self.groupMaxRadius)
	v35_:spawnAt(x, y, z)
	self:finishSpawning(true)
end

-- Local values: rx, rz
function WildlifeSpeciesFlyBy:debugSpawn(x, y, z, numAnimals, rot)
	WildlifeSpeciesFlyBy:superClass().debugSpawn(self, x, y, z, numAnimals)
	local v42_, v43_ = MathUtil.getDirectionFromYRotation(rot or 0)
	self:spawnInstances(x, y, z, numAnimals, v42_, v43_)
end
