-- Local values: WildlifeSpeciesSimple_mt
WildlifeSpeciesSimple = {}
local WildlifeSpeciesSimple_mt = Class(WildlifeSpeciesSimple, WildlifeSpecies)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = WildlifeSpecies.xmlSchema
	WildlifeInstanceGraphics.registerXMLPaths(v2_, "species")
	WildlifeInstanceSounds.registerXMLPaths(v2_)
	WildlifeInstanceMover.registerXMLPaths(v2_)
	WildlifeFollowState.registerXMLPaths(v2_)
	WildlifeFleeState.registerXMLPaths(v2_)
	WildlifeWanderState.registerXMLPaths(v2_)
	WildlifeIdleState.registerXMLPaths(v2_)
end)

-- Upvalues: WildlifeSpeciesSimple_mt
-- Local values: self
function WildlifeSpeciesSimple.new(customMt)
	-- upvalues: (copy) WildlifeSpeciesSimple_mt
	local v4_ = WildlifeSpecies.new(customMt or WildlifeSpeciesSimple_mt)
	v4_.movementAttributes = WildlifeInstanceMover.DEFAULT_ATTRIBUTES
	v4_.graphicalAttributes = nil
	v4_.soundAttributes = nil
	v4_.behaviourAttributes = {}
	return v4_
end

function WildlifeSpeciesSimple:getInstanceConstructor()
	return WildlifeInstanceSimple.new
end

-- Local values: success
function WildlifeSpeciesSimple:loadFromXML(xmlFile, baseDirectory)
	if not WildlifeSpeciesSimple:superClass().loadFromXML(self, xmlFile, baseDirectory) then
		return false
	end
	self.behaviourAttributes.flee = WildlifeFleeState.loadAttributesTable(xmlFile)
	self.behaviourAttributes.wander = WildlifeWanderState.loadAttributesTable(xmlFile)
	self.behaviourAttributes.idle = WildlifeIdleState.loadAttributesTable(xmlFile)
	self.behaviourAttributes.follow = WildlifeFollowState.loadAttributesTable(xmlFile)
	self.graphicalAttributes = WildlifeInstanceGraphics.loadAttributesTable(xmlFile)
	self.soundAttributes = WildlifeInstanceSounds.loadAttributesTable(xmlFile)
	self.movementAttributes = WildlifeInstanceMover.loadAttributesTable(xmlFile)
	return self.graphicalAttributes ~= nil and self.soundAttributes ~= nil
end

function WildlifeSpeciesSimple:delete()
	if self.soundAttributes ~= nil then
		WildlifeInstanceSounds.deleteAttributesTable(self.soundAttributes)
	end
	WildlifeSpeciesSimple:superClass().delete(self)
end
