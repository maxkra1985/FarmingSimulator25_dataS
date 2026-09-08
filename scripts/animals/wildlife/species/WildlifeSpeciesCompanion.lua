-- Local values: WildlifeSpeciesCompanion_mt
WildlifeSpeciesCompanion = {}
local WildlifeSpeciesCompanion_mt = Class(WildlifeSpeciesCompanion, WildlifeSpecies)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = WildlifeSpecies.xmlSchema
	AnimalCompanionManager.registerXMLPaths(v2_, "species.companion")
	v2_:register(XMLValueType.INT, "species.companion#maxNumAnimalsPerInstance")
end)

-- Upvalues: WildlifeSpeciesCompanion_mt
-- Local values: self
function WildlifeSpeciesCompanion.new(customMt)
	-- upvalues: (copy) WildlifeSpeciesCompanion_mt
	local v4_ = WildlifeSpecies.new(customMt or WildlifeSpeciesCompanion_mt)
	v4_.filename = nil
	v4_.maxNumAnimalsPerInstance = 1
	return v4_
end

-- Local values: success
function WildlifeSpeciesCompanion:loadFromXML(xmlFile, baseDirectory)
	if not WildlifeSpeciesCompanion:superClass().loadFromXML(self, xmlFile, baseDirectory) then
		return false
	end
	self.filename = xmlFile:getFilename()
	self.maxNumAnimalsPerInstance = xmlFile:getValue("species.companion#maxNumAnimalsPerInstance", self.maxNumAnimalsPerInstance)
	return true
end

function WildlifeSpeciesCompanion:getInstanceConstructor()
	return WildlifeInstanceCompanion.new
end

-- Local values: instance
function WildlifeSpeciesCompanion:spawnInstances(x, y, z, numInstances)
	local v13_ = numInstances or math.random(1, self.maxNumAnimalsPerInstance)
	local v14_ = self:createInstance()
	v14_:setNumAnimals(v13_)
	v14_:spawnAt(x, y, z)
	self:finishSpawning(true)
end

function WildlifeSpeciesCompanion:debugSpawn(x, y, z, numInstances)
	WildlifeSpeciesCompanion:superClass().debugSpawn(self, x, y, z, numInstances)
	self:spawnInstances(x, y, z, numInstances)
end
