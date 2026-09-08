TensionBeltObject = {}

function TensionBeltObject.prerequisitesPresent(specializations)
	return true
end
function TensionBeltObject.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("TensionBeltObject")
	v1_:register(XMLValueType.BOOL, "vehicle.tensionBeltObject#supportsTensionBelts", "Supports tension belts", true)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBeltObject.meshNodes.meshNode(?)#node", "Mesh node for tension belt calculation")
	v1_:setXMLSpecializationType()
end

function TensionBeltObject.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsTensionBelts", TensionBeltObject.getSupportsTensionBelts)
	SpecializationUtil.registerFunction(vehicleType, "getMeshNodes", TensionBeltObject.getMeshNodes)
	SpecializationUtil.registerFunction(vehicleType, "getTensionBeltNodeId", TensionBeltObject.getTensionBeltNodeId)
end

function TensionBeltObject.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TensionBeltObject)
end

-- Local values: spec, _, meshNodeKey, node
function TensionBeltObject:onLoad(savegame)
	local v5_ = self.spec_tensionBeltObject
	v5_.supportsTensionBelts = self.xmlFile:getValue("vehicle.tensionBeltObject#supportsTensionBelts", true)
	v5_.meshNodes = {}
	for _, v6_ in self.xmlFile:iterator("vehicle.tensionBeltObject.meshNodes.meshNode") do
		local v7_ = self.xmlFile:getValue(v6_ .. "#node", nil, self.components, self.i3dMappings)
		if v7_ ~= nil then
			if getHasClassId(v7_, ClassIds.SHAPE) then
				if getShapeIsCPUMesh(v7_) then
					local v8_ = v5_.meshNodes
					table.insert(v8_, v7_)
				else
					Logging.xmlWarning(self.xmlFile, "Mesh node %q at %q does not have the \'CPU-Mesh\' flag (Shape settings) enabled which required for tension belts", I3DUtil.getNodePath(v7_), v6_)
				end
			else
				Logging.xmlWarning(self.xmlFile, "Node %q at %q is not a shape", I3DUtil.getNodePath(v7_), v6_)
			end
		end
	end
end

function TensionBeltObject:getSupportsTensionBelts()
	return self.spec_tensionBeltObject.supportsTensionBelts
end

function TensionBeltObject:getMeshNodes()
	return self.spec_tensionBeltObject.meshNodes
end

function TensionBeltObject:getTensionBeltNodeId()
	return self.components[1].node
end
