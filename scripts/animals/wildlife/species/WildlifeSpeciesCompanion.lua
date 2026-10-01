WildlifeSpeciesCompanion = {}
local WildlifeSpeciesCompanion_mt = Class(WildlifeSpeciesCompanion, WildlifeSpecies)
g_xmlManager:addInitSchemaFunction(function()
	local xmlSchema = WildlifeSpecies.xmlSchema
	local basePath = "species.companion"
	AnimalCompanionManager.registerXMLPaths(xmlSchema, "species.companion")
	xmlSchema:register(XMLValueType.INT, "species.companion" .. "#maxNumAnimalsPerInstance")
end)
function WildlifeSpeciesCompanion.new(customMt)
	local self = WildlifeSpecies.new(customMt or WildlifeSpeciesCompanion_mt)
	self.filename = nil
	self.maxNumAnimalsPerInstance = 1
	return self
end
function WildlifeSpeciesCompanion:loadFromXML(xmlFile, baseDirectory)
	local success = WildlifeSpeciesCompanion:superClass().loadFromXML(self, xmlFile, baseDirectory)
	if not success then
		return false
	else
		self.filename = xmlFile:getFilename()
		self.maxNumAnimalsPerInstance = xmlFile:getValue("species.companion#maxNumAnimalsPerInstance", self.maxNumAnimalsPerInstance)
		return true
	end
end
function WildlifeSpeciesCompanion:getInstanceConstructor()
	return WildlifeInstanceCompanion.new
end
function WildlifeSpeciesCompanion:spawnInstances(x, y, z, numInstances)
	numInstances = numInstances or math.random(1, self.maxNumAnimalsPerInstance)
	local instance = self:createInstance()
	instance:setNumAnimals(numInstances)
	instance:spawnAt(x, y, z)
	self:finishSpawning(true)
end
function WildlifeSpeciesCompanion:debugSpawn(x, y, z, numInstances)
	WildlifeSpeciesCompanion:superClass().debugSpawn(self, x, y, z, numInstances)
	self:spawnInstances(x, y, z, numInstances)
end
