PlaceablePointOfInterest = {}

function PlaceablePointOfInterest.prerequisitesPresent(specializations)
	return true
end

function PlaceablePointOfInterest.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("PointOfInterest")
	schema:register(XMLValueType.STRING, basePath .. ".pointOfInterest.point(?)#class")
	PointOfInterest.registerXMLPaths(schema, basePath .. ".pointOfInterest.point(?)")
	schema:setXMLSpecializationType()
end

function PlaceablePointOfInterest.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceablePointOfInterest.setOwnerFarmId)
end

function PlaceablePointOfInterest.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceablePointOfInterest)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceablePointOfInterest)
end

-- Local values: spec
function PlaceablePointOfInterest:onLoad(savegame)
	local v_u_6_ = self.spec_pointOfInterest
	v_u_6_.points = {}
	self.xmlFile:iterate("placeable.pointOfInterest.point", function(_, p7_)
		-- upvalues: (copy) self, (copy) v_u_6_
		local v8_ = self.xmlFile:getValue(p7_ .. "#class", "PointOfInterest")
		local v9_ = ClassUtil.getClassObject(v8_)
		if v9_ == nil then
			Logging.xmlError(self.xmlFile, "PointOfInterest class \'%s\' not defined for \'%s\'", v8_, p7_)
			return
		else
			local v10_ = v9_.new(self, self.customEnvironment)
			if v10_:load(self.components, self.xmlFile, p7_, self.customEnvironment, self.i3dMappings, self.rootNode) then
				local v11_ = v_u_6_.points
				table.insert(v11_, v10_)
			else
				v10_:delete()
			end
		end
	end)
end

-- Local values: spec, _, poi
function PlaceablePointOfInterest:onDelete()
	local v13_ = self.spec_pointOfInterest
	if v13_.points ~= nil then
		for _, v14_ in ipairs(v13_.points) do
			v14_:delete()
		end
	end
end

-- Local values: spec, _, point
function PlaceablePointOfInterest:setOwnerFarmId(superFunc, farmId, noEventSend)
	local v19_ = self.spec_pointOfInterest
	superFunc(self, farmId, noEventSend)
	for _, v20_ in ipairs(v19_.points) do
		v20_:setOwnerFarmId(farmId)
	end
end
