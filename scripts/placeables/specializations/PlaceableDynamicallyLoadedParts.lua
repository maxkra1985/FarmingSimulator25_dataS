PlaceableDynamicallyLoadedParts = {}

function PlaceableDynamicallyLoadedParts.prerequisitesPresent(specializations)
	return true
end

function PlaceableDynamicallyLoadedParts.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onDynamicallyPartI3DLoaded", PlaceableDynamicallyLoadedParts.onDynamicallyPartI3DLoaded)
end

function PlaceableDynamicallyLoadedParts.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDynamicallyLoadedParts)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDynamicallyLoadedParts)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDynamicallyLoadedParts)
end

function PlaceableDynamicallyLoadedParts.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("DynamicallyLoadedParts")
	local v5_ = basePath .. ".dynamicallyLoadedParts.dynamicallyLoadedPart(?)"
	schema:register(XMLValueType.STRING, v5_ .. "#filename", "Filename to i3d file")
	schema:register(XMLValueType.NODE_INDEX, v5_ .. "#node", "Node in external i3d file", "0")
	schema:register(XMLValueType.NODE_INDEX, v5_ .. "#linkNode", "Link node", "0>")
	schema:register(XMLValueType.VECTOR_TRANS, v5_ .. "#position", "Position")
	schema:register(XMLValueType.NODE_INDEX, v5_ .. "#rotationNode", "Rotation node", "node")
	schema:register(XMLValueType.VECTOR_ROT, v5_ .. "#rotation", "Rotation node rotation")
	schema:register(XMLValueType.STRING, v5_ .. "#shaderParameterName", "Shader parameter name")
	schema:register(XMLValueType.VECTOR_4, v5_ .. "#shaderParameter", "Shader parameter to apply")
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, v5_)
	schema:setXMLSpecializationType()
end

-- Local values: spec
function PlaceableDynamicallyLoadedParts:onLoad(savegame)
	local v_u_7_ = self.spec_dynamicallyLoadedParts
	v_u_7_.sharedLoadRequestIds = {}
	v_u_7_.parts = {}
	self.xmlFile:iterate("placeable.dynamicallyLoadedParts.dynamicallyLoadedPart", function(_, p8_)
		-- upvalues: (copy) self, (copy) v_u_7_
		local v9_ = self.xmlFile:getValue(p8_ .. "#filename")
		if v9_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing filename for dynamically loaded part \'%s\'", p8_)
		else
			local v10_ = Utils.getFilename(v9_, self.baseDirectory)
			local v11_ = {
				["xmlFile"] = self.xmlFile,
				["key"] = p8_,
				["loadingTask"] = self:createLoadingTask(v_u_7_),
				["filename"] = v10_
			}
			local v12_ = g_i3DManager:loadSharedI3DFileAsync(v10_, true, true, self.onDynamicallyPartI3DLoaded, self, v11_)
			local v13_ = v_u_7_.sharedLoadRequestIds
			table.insert(v13_, v12_)
		end
	end)
end

-- Local values: spec, loadingTask, filename, xmlFile, partKey, node, linkedSkinnedShapes, linkedBones, missingShapesForBones, shape, bone, bone, shape, bone2, shape2, linkNode, x, y, z, rotationNode, rotX, rotY, rotZ, shaderParameterName, sx, sy, sz, sw, objectChanges, dynamicallyLoadedPart
function PlaceableDynamicallyLoadedParts:onDynamicallyPartI3DLoaded(i3dNode, failedReason, args)
	local v17_ = self.spec_dynamicallyLoadedParts
	local v18_ = args.loadingTask
	local v19_ = args.filename
	local v20_ = args.xmlFile
	local v21_ = args.key
	if i3dNode == 0 then
		Logging.xmlError(v20_, "Could not load load part %q at %q!", v19_, v21_)
		self:finishLoadingTask(v18_)
		return false
	end
	local v22_ = v20_:getValue(v21_ .. "#node", "0", i3dNode)
	if v22_ == nil then
		Logging.xmlWarning(v20_, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find node in loaded i3d", v21_)
		self:finishLoadingTask(v18_)
		delete(i3dNode)
		return false
	end
	local v_u_23_ = nil
	I3DUtil.iterateRecursively(v22_, function(p24_)
		-- upvalues: (ref) v_u_23_
		if getHasClassId(p24_, ClassIds.SHAPE) and getShapeIsSkinned(p24_) then
			v_u_23_ = v_u_23_ or {}
			v_u_23_[p24_] = true
		end
	end)
	local v_u_25_ = nil
	I3DUtil.iterateRecursively(i3dNode, function(p26_)
		-- upvalues: (ref) v_u_25_
		if getHasClassId(p26_, ClassIds.SHAPE) and getShapeIsSkinned(p26_) then
			for v27_ = 0, getNumOfShapeBones(p26_) - 1 do
				local v28_ = getShapeBone(p26_, v27_)
				v_u_25_ = v_u_25_ or {}
				v_u_25_[v28_] = p26_
			end
		end
	end)
	if v_u_23_ ~= nil or v_u_25_ ~= nil then
		local v_u_29_ = nil
		I3DUtil.iterateRecursively(v22_, function(p30_)
			-- upvalues: (ref) v_u_25_, (ref) v_u_23_, (ref) v_u_29_
			local v31_ = v_u_25_[p30_]
			if v31_ ~= nil then
				v_u_25_[p30_] = nil
				if v_u_23_ == nil or v_u_23_[v31_] == nil then
					v_u_29_ = v_u_29_ or {}
					v_u_29_[v31_] = p30_
				end
			end
		end)
		if v_u_29_ ~= nil then
			for v32_, v33_ in pairs(v_u_29_) do
				Logging.xmlWarning(self.xmlFile, "Node %q at %q do not contain the skinned shape %q for bone %q, ignoring", getName(v22_), v21_ .. "#node", getName(v32_), getName(v33_))
			end
			self:finishLoadingTask(v18_)
			delete(i3dNode)
			return false
		end
		if next(v_u_25_) ~= nil then
			local v34_ = v_u_25_
			local v35_ = v_u_23_
			for _, v36_ in pairs(v_u_25_) do
				if v35_ == nil or v35_[v36_] ~= nil then
					Logging.xmlWarning(self.xmlFile, "Node %q at %q does not contain all bones of the skinned shape %q and cannot be linked on their own, ignoring", getName(v22_), v21_ .. "#node", getName(v36_))
					for v37_, v38_ in pairs(v34_) do
						if v36_ == v38_ then
							v34_[v37_] = nil
						end
					end
					if v35_ ~= nil then
						v35_[v36_] = nil
					end
				end
			end
			self:finishLoadingTask(v18_)
			delete(i3dNode)
			return false
		end
	end
	local v39_ = v20_:getValue(v21_ .. "#linkNode", "0>", self.components, self.i3dMappings)
	if v39_ == nil then
		Logging.xmlWarning(v20_, "Failed to load dynamicallyLoadedPart \'%s\'. Unable to find linkNode", v21_)
		self:finishLoadingTask(v18_)
		delete(i3dNode)
		return false
	end
	removeFromPhysics(v22_)
	local v40_, v41_, v42_ = v20_:getValue(v21_ .. "#position")
	if v40_ ~= nil and (v41_ ~= nil and v42_ ~= nil) then
		setTranslation(v22_, v40_, v41_, v42_)
	end
	local v43_ = v20_:getValue(v21_ .. "#rotationNode", v22_, i3dNode)
	local v44_, v45_, v46_ = v20_:getValue(v21_ .. "#rotation")
	if v44_ ~= nil and (v45_ ~= nil and v46_ ~= nil) then
		setRotation(v43_, v44_, v45_, v46_)
	end
	local v47_ = v20_:getValue(v21_ .. "#shaderParameterName")
	local v48_, v49_, v50_, v51_ = v20_:getValue(v21_ .. "#shaderParameter")
	if v47_ ~= nil and (v48_ ~= nil and (v49_ ~= nil and (v50_ ~= nil and v51_ ~= nil))) then
		setShaderParameter(v22_, v47_, v48_, v49_, v50_, v51_, false)
	end
	local v52_ = ObjectChangeUtil.loadObjectChangeFromXML(v20_, v21_, nil, i3dNode, nil)
	ObjectChangeUtil.setObjectChanges(v52_, true, nil)
	link(v39_, v22_)
	delete(i3dNode)
	local v53_ = v17_.parts
	table.insert(v53_, {
		["filename"] = v19_,
		["node"] = v22_
	})
	self:finishLoadingTask(v18_)
	return true
end

-- Local values: spec, _, sharedLoadRequestId, _, part
function PlaceableDynamicallyLoadedParts:onDelete()
	local v55_ = self.spec_dynamicallyLoadedParts
	if v55_.sharedLoadRequestIds ~= nil then
		for _, v56_ in ipairs(v55_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v56_)
		end
		v55_.sharedLoadRequestIds = nil
	end
	if v55_.parts ~= nil then
		for _, v57_ in pairs(v55_.parts) do
			delete(v57_.node)
		end
	end
end

-- Local values: spec, _, part
function PlaceableDynamicallyLoadedParts:onFinalizePlacement()
	local v59_ = self.spec_dynamicallyLoadedParts
	if v59_.parts ~= nil then
		for _, v60_ in pairs(v59_.parts) do
			addToPhysics(v60_.node)
		end
	end
end
