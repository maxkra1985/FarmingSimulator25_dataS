WildlifeSpeciesSimple = {}
local WildlifeSpeciesSimple_mt = Class(WildlifeSpeciesSimple, WildlifeSpecies)
g_xmlManager:addInitSchemaFunction(function()
	local xmlSchema = WildlifeSpecies.xmlSchema
	WildlifeInstanceGraphics.registerXMLPaths(xmlSchema, "species")
	WildlifeInstanceSounds.registerXMLPaths(xmlSchema)
	WildlifeInstanceMover.registerXMLPaths(xmlSchema)
	WildlifeFollowState.registerXMLPaths(xmlSchema)
	WildlifeFleeState.registerXMLPaths(xmlSchema)
	WildlifeWanderState.registerXMLPaths(xmlSchema)
	WildlifeIdleState.registerXMLPaths(xmlSchema)
end)
function WildlifeSpeciesSimple.new(customMt)
	local self = WildlifeSpecies.new(customMt or WildlifeSpeciesSimple_mt)
	self.movementAttributes = WildlifeInstanceMover.DEFAULT_ATTRIBUTES
	self.graphicalAttributes = nil
	self.soundAttributes = nil
	self.behaviourAttributes = {}
	return self
end
function WildlifeSpeciesSimple:getInstanceConstructor()
	return WildlifeInstanceSimple.new
end
function WildlifeSpeciesSimple:loadFromXML(xmlFile, baseDirectory)
	local success = WildlifeSpeciesSimple:superClass().loadFromXML(self, xmlFile, baseDirectory)
	if not success then
		return false
	else
		self.behaviourAttributes.flee = WildlifeFleeState.loadAttributesTable(xmlFile)
		self.behaviourAttributes.wander = WildlifeWanderState.loadAttributesTable(xmlFile)
		self.behaviourAttributes.idle = WildlifeIdleState.loadAttributesTable(xmlFile)
		self.behaviourAttributes.follow = WildlifeFollowState.loadAttributesTable(xmlFile)
		self.graphicalAttributes = WildlifeInstanceGraphics.loadAttributesTable(xmlFile)
		self.soundAttributes = WildlifeInstanceSounds.loadAttributesTable(xmlFile)
		self.movementAttributes = WildlifeInstanceMover.loadAttributesTable(xmlFile)
		if self.graphicalAttributes == nil or self.soundAttributes == nil then
			return false
		end
		return true
	end
end
function WildlifeSpeciesSimple:delete()
	if self.soundAttributes ~= nil then
		WildlifeInstanceSounds.deleteAttributesTable(self.soundAttributes)
	end
	WildlifeSpeciesSimple:superClass().delete(self)
end
