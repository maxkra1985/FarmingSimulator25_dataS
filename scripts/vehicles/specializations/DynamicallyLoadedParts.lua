DynamicallyLoadedParts = {}

function DynamicallyLoadedParts.prerequisitesPresent(specializations)
	return true
end
function DynamicallyLoadedParts.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("DynamicallyLoadedParts")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#filename", "Filename to i3d file")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#node", "Node in external i3d file", "0|0")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#linkNode", "Link node", "0>")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#position", "Position", "0 0 0")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#rotationNode", "Rotation node", "node")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#rotation", "Rotation node rotation")
	v1_:register(XMLValueType.STRING, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#shaderParameterName", "Shader parameter name")
	v1_:register(XMLValueType.VECTOR_4, "vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart(?)#shaderParameter", "Shader parameter to apply")
	v1_:setXMLSpecializationType()
end

function DynamicallyLoadedParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "onDynamicallyPartI3DLoaded", DynamicallyLoadedParts.onDynamicallyPartI3DLoaded)
end

function DynamicallyLoadedParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DynamicallyLoadedParts)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", DynamicallyLoadedParts)
end

-- Local values: spec
function DynamicallyLoadedParts:onLoad(savegame)
	local v_u_5_ = self.spec_dynamicallyLoadedParts
	v_u_5_.sharedLoadRequestIds = {}
	v_u_5_.parts = {}
	self.xmlFile:iterate("vehicle.dynamicallyLoadedParts.dynamicallyLoadedPart", function(_, p6_)
		-- upvalues: (copy) self, (copy) v_u_5_
		local v7_ = self.xmlFile:getValue(p6_ .. "#filename")
		if v7_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing filename for dynamically loaded part \'%s\'", p6_)
		else
			local v8_ = {
				["filename"] = Utils.getFilename(v7_, self.baseDirectory)
			}
			local v9_ = {
				["xmlFile"] = self.xmlFile,
				["partKey"] = p6_,
				["dynamicallyLoadedPart"] = v8_
			}
			local v10_ = self:loadSubSharedI3DFile(v8_.filename, false, false, self.onDynamicallyPartI3DLoaded, self, v9_)
			local v11_ = v_u_5_.sharedLoadRequestIds
			table.insert(v11_, v10_)
		end
	end)
end

-- Local values: spec, _, sharedLoadRequestId
function DynamicallyLoadedParts:onDelete()
	local v13_ = self.spec_dynamicallyLoadedParts
	if v13_.sharedLoadRequestIds ~= nil then
		for _, v14_ in ipairs(v13_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v14_)
		end
		v13_.sharedLoadRequestIds = nil
	end
end

-- Local values: spec, xmlFile, partKey, dynamicallyLoadedPart, node, linkNode, isReference, filename, runtimeLoaded, xmlName, i3dName, x, y, z, rotationNode, rotX, rotY, rotZ, shaderParameterName, sx, sy, sz, sw
function DynamicallyLoadedParts:onDynamicallyPartI3DLoaded(i3dNode, failedReason, args)
	local v18_ = self.spec_dynamicallyLoadedParts
	local v19_ = args.xmlFile
	local v20_ = args.partKey
	local v21_ = args.dynamicallyLoadedPart
	if i3dNode == 0 then
		Logging.xmlWarning(v19_, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to load i3d", v20_)
		return false
	end
	local v22_ = v19_:getValue(v20_ .. "#node", "0|0", i3dNode)
	if v22_ == nil then
		Logging.xmlWarning(v19_, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find node in loaded i3d", v20_)
		delete(i3dNode)
		return false
	end
	local v23_ = v19_:getValue(v20_ .. "#linkNode", "0>", self.components, self.i3dMappings)
	if v23_ == nil then
		Logging.xmlWarning(v19_, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find linkNode", v20_)
		delete(i3dNode)
		return false
	end
	local v24_, v25_, v26_ = getReferenceInfo(v23_)
	if not (v24_ and v26_) then
		local v27_, v28_, v29_ = v19_:getValue(v20_ .. "#position")
		if v27_ == nil or (v28_ == nil or v29_ == nil) then
			setTranslation(v22_, 0, 0, 0)
		else
			setTranslation(v22_, v27_, v28_, v29_)
		end
		setRotation(v22_, 0, 0, 0)
		local v30_ = v19_:getValue(v20_ .. "#rotationNode", v22_, i3dNode)
		local v31_, v32_, v33_ = v19_:getValue(v20_ .. "#rotation")
		if v31_ ~= nil and (v32_ ~= nil and v33_ ~= nil) then
			setRotation(v30_, v31_, v32_, v33_)
		end
		local v34_ = v19_:getValue(v20_ .. "#shaderParameterName")
		local v35_, v36_, v37_, v38_ = v19_:getValue(v20_ .. "#shaderParameter")
		if v34_ ~= nil and (v35_ ~= nil and (v36_ ~= nil and (v37_ ~= nil and v38_ ~= nil))) then
			setShaderParameter(v22_, v34_, v35_, v36_, v37_, v38_, false)
		end
		link(v23_, v22_)
		delete(i3dNode)
		local v39_ = v18_.parts
		table.insert(v39_, v21_)
		return true
	end
	local v40_ = Utils.getFilenameInfo(v21_.filename, true)
	local v41_ = Utils.getFilenameInfo(v25_, true)
	if v40_ ~= v41_ then
		Logging.xmlWarning(v19_, "DynamicallyLoadedPart \'%s\' loading different file from XML compared to i3D. (XML: %s vs i3D: %s)", getName(v23_), v40_, v41_)
	end
	Logging.xmlWarning(v19_, "DynamicallyLoadedPart link node \'%s\' is a runtime loaded reference. Please load it either via XML or the i3D reference, but not both!", getName(v23_))
	delete(i3dNode)
end
