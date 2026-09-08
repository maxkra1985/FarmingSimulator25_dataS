ObjectChangeUtil = {}

-- Local values: _, nodeKey, i3dMappings, node, object
function ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, objects, rootNode, parent)
	for _, v6_ in xmlFile:iterator(key .. ".objectChange") do
		local v7_
		if parent == nil then
			v7_ = nil
		else
			v7_ = parent.i3dMappings
		end
		local v8_ = xmlFile:getValue(v6_ .. "#node", nil, rootNode, v7_)
		if v8_ ~= nil then
			local v9_ = {
				["node"] = v8_
			}
			ObjectChangeUtil.loadValuesFromXML(xmlFile, v6_, v8_, v9_, parent, rootNode, v7_)
			objects = objects or {}
			table.insert(objects, v9_)
		end
	end
	return objects
end
function ObjectChangeUtil.loadValueType(p10_, p11_, p12_, p13_, p14_, p15_, p16_, ...)
	local v17_ = p11_:getValue(p12_ .. "#" .. p13_ .. "Active", ...)
	local v18_ = p11_:getValue(p12_ .. "#" .. p13_ .. "Inactive", ...)
	if v17_ == nil and v18_ == nil then
		return nil
	end
	local v19_ = {
		["active"] = v17_ ~= nil and type(v17_) ~= "table" and { v17_ } or v17_,
		["inactive"] = v18_ ~= nil and type(v18_) ~= "table" and { v18_ } or v18_,
		["getFunc"] = p14_,
		["setFunc"] = p15_,
		["interpolatable"] = p16_,
		["name"] = p13_
	}
	table.insert(p10_, v19_)
	return v19_
end

-- Local values: entry, shaderParameter, recursive, sharedShaderParameter, centerOfMassMaskActive, centerOfMassMaskInactive, i, rigidBodyTypeActiveStr, t, rigidBodyTypeInactiveStr, t
function ObjectChangeUtil.loadValuesFromXML(xmlFile, key, node, object, parent, rootNode, i3dMappings)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionActive", key .. "#compoundChildActive or #rigidBodyTypeActive")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionInactive", key .. "#compoundChildInactive or #rigidBodyTypeInactive")
	object.parent = parent
	object.interpolation = xmlFile:getValue(key .. "#interpolation", false)
	object.interpolationTime = xmlFile:getValue(key .. "#interpolationTime", 1)
	object.values = {}
	local v34_ = ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "parentNode", nil, function(p27_)
		-- upvalues: (copy) node
		local v28_, v29_, v30_ = getWorldTranslation(node)
		local v31_, v32_, v33_ = getWorldRotation(node)
		link(p27_, node)
		setWorldTranslation(node, v28_, v29_, v30_)
		setWorldRotation(node, v31_, v32_, v33_)
	end, false, nil, rootNode, i3dMappings)
	if v34_ ~= nil then
		if v34_.active == nil then
			v34_.active = { getParent(object.node) }
		end
		if v34_.inactive == nil then
			v34_.inactive = { getParent(object.node) }
		end
	end
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "delete", nil, function(p35_)
		-- upvalues: (copy) node
		if p35_ then
			local v36_ = getParent(node)
			local v37_ = getName(node)
			local v38_ = string.format("%s_deletedByObjectChange", v37_)
			local v39_ = getChildIndex(node)
			local v40_ = createTransformGroup(v38_)
			link(v36_, v40_, v39_)
			delete(node)
		end
	end, false)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "translation", function()
		-- upvalues: (copy) node
		return getTranslation(node)
	end, function(p41_, p42_, p43_)
		-- upvalues: (copy) node
		setTranslation(node, p41_, p42_, p43_)
	end, true, nil, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "rotation", function()
		-- upvalues: (copy) node
		return getRotation(node)
	end, function(p44_, p45_, p46_)
		-- upvalues: (copy) node
		setRotation(node, p44_, p45_, p46_)
	end, true, nil, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "scale", function()
		-- upvalues: (copy) node
		return getScale(node)
	end, function(p47_, p48_, p49_)
		-- upvalues: (copy) node
		setScale(node, p47_, p48_, p49_)
	end, true, nil, true)
	local v_u_50_ = xmlFile:getValue(key .. "#shaderParameter")
	if v_u_50_ ~= nil then
		if xmlFile:getValue(key .. "#shaderParameterSetRecursive", false) then
			if I3DUtil.getHasShaderParameterRec(node, v_u_50_) then
				ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "shaderParameter", function()
					-- upvalues: (copy) node, (copy) v_u_50_
					return I3DUtil.getShaderParameterRec(node, v_u_50_)
				end, function(p51_, p52_, p53_, p54_)
					-- upvalues: (copy) node, (copy) v_u_50_
					setShaderParameterRecursive(node, v_u_50_, p51_, p52_, p53_, p54_, false)
				end, true, nil, true)
			else
				Logging.xmlWarning(xmlFile, "Missing shader parameter \'%s\' on object \'%s\' or any of its children (recursive) in \'%s\'", v_u_50_, getName(node), key)
			end
		elseif getHasClassId(node, ClassIds.SHAPE) then
			if getHasShaderParameter(node, v_u_50_) then
				local v_u_55_ = xmlFile:getValue(key .. "#sharedShaderParameter", false)
				ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "shaderParameter", function()
					-- upvalues: (copy) node, (copy) v_u_50_
					return getShaderParameter(node, v_u_50_)
				end, function(p56_, p57_, p58_, p59_)
					-- upvalues: (copy) node, (copy) v_u_50_, (copy) v_u_55_
					setShaderParameter(node, v_u_50_, p56_, p57_, p58_, p59_, v_u_55_)
				end, true, nil, true)
			else
				Logging.xmlWarning(xmlFile, "Missing shader parameter \'%s\' on object \'%s\' in \'%s\'", v_u_50_, getName(node), key)
			end
		else
			Logging.xmlWarning(xmlFile, "Given node %q at %q is not a shape and cannot have a shaderParameter applied to it", getName(node), key)
		end
	end
	local v60_ = xmlFile:getString(key .. "#centerOfMassActive")
	local v61_ = xmlFile:getString(key .. "#centerOfMassInactive")
	if v60_ ~= nil or v61_ ~= nil then
		local v62_ = (v60_ or ""):split(" ")
		local v63_ = (v61_ or ""):split(" ")
		object.centerOfMassMask = { 1, 1, 1 }
		object.centerOfMassMaskActive = false
		for v64_ = 1, 3 do
			if v62_ ~= nil and v62_[v64_] == "-" then
				object.centerOfMassMask[v64_] = 0
				object.centerOfMassMaskActive = true
			end
			if v63_ ~= nil and v63_[v64_] == "-" then
				object.centerOfMassMask[v64_] = 0
				object.centerOfMassMaskActive = true
			end
		end
	end
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "centerOfMass", function()
		-- upvalues: (copy) node
		return getCenterOfMass(node)
	end, function(p65_, p66_, p67_)
		-- upvalues: (copy) object, (copy) node
		local v68_, v69_, v70_
		if object.centerOfMassMaskActive == nil then
			v68_ = p67_
			v69_ = p66_
			v70_ = p65_
		else
			v70_, v69_, v68_ = getCenterOfMass(node)
			if object.centerOfMassMask[1] ~= 0 then
				v70_ = p65_
			end
			if object.centerOfMassMask[2] ~= 0 then
				v69_ = p66_
			end
			if object.centerOfMassMask[3] ~= 0 then
				v68_ = p67_
			end
		end
		setCenterOfMass(node, v70_, v69_, v68_)
	end, true, nil, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "mass", function()
		-- upvalues: (copy) node
		return getMass(node)
	end, function(p71_)
		-- upvalues: (copy) node, (copy) parent, (copy) object
		setMass(node, p71_ / 1000)
		if parent ~= nil and parent.components ~= nil then
			for _, v72_ in ipairs(parent.components) do
				if v72_.node == object.node then
					v72_.defaultMass = p71_ / 1000
					parent:setMassDirty()
				end
			end
		end
	end, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "visibility", nil, function(p73_)
		-- upvalues: (copy) node
		setVisibility(node, p73_)
	end, false)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "compoundChild", nil, function(p74_)
		-- upvalues: (copy) node
		setIsCompoundChild(node, p74_)
	end, false)
	local v75_ = xmlFile:getValue(key .. "#rigidBodyTypeActive")
	if v75_ ~= nil then
		object.rigidBodyTypeActive = RigidBodyType[string.upper(v75_)]
		local v76_ = object.rigidBodyTypeActive
		if v76_ ~= RigidBodyType.STATIC and (v76_ ~= RigidBodyType.DYNAMIC and (v76_ ~= RigidBodyType.KINEMATIC and v76_ ~= RigidBodyType.NONE)) then
			Logging.xmlWarning(xmlFile, "Invalid rigidBodyTypeActive \'%s\' for object change node \'%s\'. Use \'Static\', \'Dynamic\', \'Kinematic\' or \'None\'!", v75_, key)
			object.rigidBodyTypeActive = nil
		end
	end
	local v77_ = xmlFile:getValue(key .. "#rigidBodyTypeInactive")
	if v77_ ~= nil then
		object.rigidBodyTypeInactive = RigidBodyType[string.upper(v77_)]
		local v78_ = object.rigidBodyTypeInactive
		if v78_ ~= RigidBodyType.STATIC and (v78_ ~= RigidBodyType.DYNAMIC and (v78_ ~= RigidBodyType.KINEMATIC and v78_ ~= RigidBodyType.NONE)) then
			Logging.xmlWarning(xmlFile, "Invalid rigidBodyTypeInactive \'%s\' for object change node \'%s\'. Use \'Static\', \'Dynamic\', \'Kinematic\' or \'None\'!", v77_, key)
			object.rigidBodyTypeInactive = nil
		end
	end
	if parent ~= nil and parent.loadObjectChangeValuesFromXML ~= nil then
		parent:loadObjectChangeValuesFromXML(xmlFile, key, node, object)
	end
end

-- Local values: _, object
function ObjectChangeUtil.setObjectChanges(objects, isActive, target, updateFunc, skipInterpolation)
	if objects ~= nil then
		for _, v84_ in pairs(objects) do
			ObjectChangeUtil.setObjectChange(v84_, isActive, target, updateFunc, skipInterpolation)
		end
	end
end

-- Local values: i, value, interpolator, i, value, interpolator
function ObjectChangeUtil.setObjectChange(object, isActive, target, updateFunc, skipInterpolation)
	if isActive then
		for v90_ = 1, #object.values do
			local v91_ = object.values[v90_]
			if v91_.active ~= nil then
				if object.interpolation and (v91_.interpolatable and not skipInterpolation) then
					local v92_ = ValueInterpolator.new(object.node .. v91_.name, v91_.getFunc, v91_.setFunc, v91_.active, object.interpolationTime)
					if v92_ ~= nil then
						v92_:setUpdateFunc(updateFunc, target, object.node)
						v92_:setDeleteListenerObject(object.parent)
					end
				else
					if skipInterpolation then
						ValueInterpolator.removeInterpolator(object.node .. v91_.name)
					end
					local v93_ = v91_.setFunc
					local v94_ = v91_.active
					v93_(unpack(v94_))
				end
			end
		end
		if object.rigidBodyTypeActive ~= nil then
			setRigidBodyType(object.node, object.rigidBodyTypeActive)
		end
	else
		for v95_ = 1, #object.values do
			local v96_ = object.values[v95_]
			if v96_.inactive ~= nil then
				if object.interpolation and (v96_.interpolatable and not skipInterpolation) then
					local v97_ = ValueInterpolator.new(object.node .. v96_.name, v96_.getFunc, v96_.setFunc, v96_.inactive, object.interpolationTime)
					if v97_ ~= nil then
						v97_:setUpdateFunc(updateFunc, target, object.node)
						v97_:setDeleteListenerObject(object.parent)
					end
				else
					if skipInterpolation then
						ValueInterpolator.removeInterpolator(object.node .. v96_.name)
					end
					local v98_ = v96_.setFunc
					local v99_ = v96_.inactive
					v98_(unpack(v99_))
				end
			end
		end
		if object.rigidBodyTypeInactive ~= nil then
			setRigidBodyType(object.node, object.rigidBodyTypeInactive)
		end
	end
	if target ~= nil then
		if target.setObjectChangeValues ~= nil then
			target:setObjectChangeValues(object, isActive)
		end
		if updateFunc ~= nil then
			updateFunc(target, object.node)
		end
	end
end

-- Local values: i, activeI, objectChangeKey, objects, objectChangeKey, objects
function ObjectChangeUtil.updateObjectChanges(xmlFile, key, configIndex, rootNode, parent)
	local v105_ = configIndex - 1
	local v106_ = 0
	while true do
		local v107_ = string.format(key .. "(%d)", v106_)
		if not xmlFile:hasProperty(v107_) then
			break
		end
		if v106_ ~= v105_ then
			local v108_ = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, v107_, nil, rootNode, parent)
			ObjectChangeUtil.setObjectChanges(v108_, false, parent)
		end
		v106_ = v106_ + 1
	end
	if v105_ < v106_ then
		local v109_ = string.format(key .. "(%d)", v105_)
		local v110_ = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, v109_, nil, rootNode, parent)
		ObjectChangeUtil.setObjectChanges(v110_, true, parent)
	end
end

function ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("ObjectChange_single", basePath)
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
	schema:resetXMLSharedRegistration("ObjectChange_single", basePath)
end

function ObjectChangeUtil.registerObjectChangesXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("ObjectChange_multiple", basePath)
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath .. ".objectChanges")
	schema:resetXMLSharedRegistration("ObjectChange_multiple", basePath)
end

-- Local values: positivStr, negativeStr
function ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
	schema:addDelayedRegistrationPath(basePath .. ".objectChange(?)", "ObjectChange")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#node", "Object change node")
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#interpolation", "Value will be interpolated", false)
	schema:register(XMLValueType.TIME, basePath .. ".objectChange(?)#interpolationTime", "Time for interpolation", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#deleteActive", string.format("%s if object change is active", "delete"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#deleteInactive", string.format("%s if object change is active", "delete"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#visibilityActive", string.format("%s if object change is active", "visibility"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#visibilityInactive", string.format("%s if object change is in active", "visibility"))
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".objectChange(?)#translationActive", string.format("%s if object change is active", "translation"))
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".objectChange(?)#translationInactive", string.format("%s if object change is in active", "translation"))
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".objectChange(?)#rotationActive", string.format("%s if object change is active", "rotation"))
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".objectChange(?)#rotationInactive", string.format("%s if object change is in active", "rotation"))
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".objectChange(?)#scaleActive", string.format("%s if object change is active", "scale"))
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".objectChange(?)#scaleInactive", string.format("%s if object change is in active", "scale"))
	schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#shaderParameter", "Shader parameter name")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".objectChange(?)#shaderParameterActive", string.format("%s if object change is active", "shaderParameter"))
	schema:register(XMLValueType.VECTOR_4, basePath .. ".objectChange(?)#shaderParameterInactive", string.format("%s if object change is in active", "shaderParameter"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#sharedShaderParameter", "Shader parameter is applied on all objects with the same material", false)
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#shaderParameterSetRecursive", "Shader parameter is applied to all child nodes recursively", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".objectChange(?)#massActive", string.format("%s if object change is active", "mass"))
	schema:register(XMLValueType.FLOAT, basePath .. ".objectChange(?)#massInactive", string.format("%s if object change is in active", "mass"))
	schema:register(XMLValueType.VECTOR_3, basePath .. ".objectChange(?)#centerOfMassActive", string.format("%s if object change is active", "center of mass"))
	schema:register(XMLValueType.VECTOR_3, basePath .. ".objectChange(?)#centerOfMassInactive", string.format("%s if object change is in active", "center of mass"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#compoundChildActive", string.format("%s if object change is active", "compound child state"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#compoundChildInactive", string.format("%s if object change is in active", "compound child state"))
	schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#rigidBodyTypeActive", string.format("%s if object change is active", "rigid body type"))
	schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#rigidBodyTypeInactive", string.format("%s if object change is in active", "rigid body type"))
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#parentNodeActive", string.format("%s if object change is active", "parent node"))
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#parentNodeInactive", string.format("%s if object change is in active", "parent node"))
end

function ObjectChangeUtil.addAdditionalObjectChangeXMLPaths(schema, func)
	schema:addDelayedRegistrationFunc("ObjectChange", func)
end
