PlaceableWorkshop = {}

function PlaceableWorkshop.prerequisitesPresent(specializations)
	return true
end

function PlaceableWorkshop.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableWorkshop.setOwnerFarmId)
end

function PlaceableWorkshop.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWorkshop)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWorkshop)
end

function PlaceableWorkshop.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Workshop")
	VehicleSellingPoint.registerXMLPaths(schema, basePath .. ".workshop.sellingPoint")
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableWorkshop:onLoad(savegame)
	local v6_ = self.spec_workshop
	v6_.sellingPoint = VehicleSellingPoint.new()
	v6_.sellingPoint:load(self.components, self.xmlFile, "placeable.workshop.sellingPoint", self.i3dMappings)
	v6_.sellingPoint:setOwnerFarmId(self:getOwnerFarmId())
	v6_.sellingPoint.owningPlaceable = self
end

-- Local values: spec
function PlaceableWorkshop:onDelete()
	local v8_ = self.spec_workshop
	if v8_.sellingPoint ~= nil then
		v8_.sellingPoint:delete()
	end
end

-- Local values: spec
function PlaceableWorkshop:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	local v13_ = self.spec_workshop
	superFunc(self, ownerFarmId, noEventSend)
	if v13_.sellingPoint ~= nil then
		v13_.sellingPoint:setOwnerFarmId(ownerFarmId)
	end
end
