PlaceableAnimalLoadingTrigger = {}

function PlaceableAnimalLoadingTrigger.prerequisitesPresent(placeableType)
	return true
end

function PlaceableAnimalLoadingTrigger.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAnimalLoadingTrigger)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAnimalLoadingTrigger)
end

function PlaceableAnimalLoadingTrigger.registerFunctions(placeableType) end

function PlaceableAnimalLoadingTrigger.registerOverwrittenFunctions(placeableType) end

function PlaceableAnimalLoadingTrigger.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("AnimalLoadingTrigger")
	AnimalLoadingTrigger.registerXMLPaths(schema, basePath .. ".animalLoadingTrigger")
	schema:setXMLSpecializationType()
end

function PlaceableAnimalLoadingTrigger.registerSavegameXMLPaths(schema, basePath) end

-- Local values: spec
function PlaceableAnimalLoadingTrigger:onLoad(savegame)
	local v5_ = self.spec_animalLoadingTrigger
	v5_.animalLoadingTrigger = AnimalLoadingTrigger.new(self.isServer, self.isClient)
	if not v5_.animalLoadingTrigger:loadFromXML(self.xmlFile, "placeable.animalLoadingTrigger", self.components, self.i3dMappings) then
		v5_.animalLoadingTrigger:delete()
		v5_.animalLoadingTrigger = nil
	end
end

-- Local values: spec
function PlaceableAnimalLoadingTrigger:onDelete()
	local v7_ = self.spec_animalLoadingTrigger
	if v7_.animalLoadingTrigger ~= nil then
		v7_.animalLoadingTrigger:delete()
		v7_.animalLoadingTrigger = nil
	end
end
