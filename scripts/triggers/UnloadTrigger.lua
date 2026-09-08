-- Local values: UnloadTrigger_mt
UnloadTrigger = {}
UnloadTrigger.CUSTOM_TRIGGERS = {}

function UnloadTrigger.registerCustomTrigger(name, classObj)
	UnloadTrigger.CUSTOM_TRIGGERS[name] = classObj
end

-- Local values: name, classObj
function UnloadTrigger.registerTriggerXMLPaths(schema, basePath)
	for v5_, v6_ in pairs(UnloadTrigger.CUSTOM_TRIGGERS) do
		if v6_.registerXMLPaths ~= nil then
			v6_.registerXMLPaths(schema, basePath .. "." .. v5_ .. "(?)")
		end
	end
end
UnloadTrigger.registerCustomTrigger("unloadTrigger", UnloadTrigger)

-- Local values: triggers, name, class, _, triggerKey, trigger
function UnloadTrigger.createTriggers(isServer, isClient, xmlFile, key, components, target, extraAttributes, i3dMappings)
	local v15_ = {}
	for v16_, v17_ in pairs(UnloadTrigger.CUSTOM_TRIGGERS) do
		for _, v18_ in xmlFile:iterator(key .. "." .. v16_) do
			local v19_ = v17_.new(isServer, isClient)
			if v19_:load(components, xmlFile, v18_, target, extraAttributes, i3dMappings) then
				v19_:setTarget(target)
				table.insert(v15_, v19_)
			else
				v19_:delete()
			end
		end
	end
	return v15_
end

function UnloadTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#exactFillRootNode", "Exact fill root node")
	schema:register(XMLValueType.FLOAT, basePath .. "#priceScale", "Price scale added for sold goods")
	schema:register(XMLValueType.STRING, basePath .. "#acceptedToolTypes", "List of accepted tool types")
	FillTypeManager.registerConfigXMLFilltypes(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#aiNode", "AI target node, required for the station to support AI. AI drives to the node in positive Z direction. Height is not relevant.")
	schema:register(XMLValueType.STRING, basePath .. ".fillTypeConversion(?)#incomingFillType", "Filltype to be converted")
	schema:register(XMLValueType.STRING, basePath .. ".fillTypeConversion(?)#outgoingFillType", "Filltype to be converted to")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillTypeConversion(?)#ratio", "Conversion ratio between input- and output amount", 1)
end
local v_u_22_ = Class(UnloadTrigger, Object)
InitStaticObjectClass(UnloadTrigger, "UnloadTrigger")

-- Upvalues: UnloadTrigger_mt
-- Local values: self
function UnloadTrigger.new(isServer, isClient, customMt)
	-- upvalues: (copy) v_u_22_
	local v26_ = Object.new(isServer, isClient, customMt or v_u_22_)
	v26_.fillTypes = {}
	v26_.acceptedToolTypes = {}
	v26_.fillTypeConversions = {}
	v26_.notAllowedWarningText = nil
	v26_.extraAttributes = nil
	return v26_
end

-- Local values: priceScale, _, fillTypeConversionPath, fillTypeIndexIncoming, fillTypeIndexOutgoing, ratio
function UnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
	self.exactFillRootNode = xmlFile:getValue(xmlNode .. "#exactFillRootNode", nil, components, i3dMappings)
	if self.exactFillRootNode ~= nil then
		if not CollisionFlag.getHasGroupFlagSet(self.exactFillRootNode, CollisionFlag.FILLABLE) then
			Logging.xmlWarning(xmlFile, "Missing collision group %s. Please add this bit to the collision filter group of exact fill node \'%s\'", CollisionFlag.getBitAndName(CollisionFlag.FILLABLE), I3DUtil.getNodePath(self.exactFillRootNode))
			return false
		end
		g_currentMission:addNodeObject(self.exactFillRootNode, self)
	end
	self.aiNode = xmlFile:getValue(xmlNode .. "#aiNode", nil, components, i3dMappings)
	self.supportsAIUnloading = self.aiNode ~= nil
	local v34_ = xmlFile:getValue(xmlNode .. "#priceScale", nil)
	if v34_ ~= nil then
		self.extraAttributes = {
			["priceScale"] = v34_
		}
	end
	for _, v35_ in xmlFile:iterator(xmlNode .. ".fillTypeConversion") do
		local v36_ = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(v35_ .. "#incomingFillType"))
		if v36_ ~= nil then
			local v37_ = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(v35_ .. "#outgoingFillType"))
			if v37_ ~= nil then
				local v38_ = xmlFile:getValue(v35_ .. "#ratio", 1)
				local v39_ = {
					["outgoingFillType"] = v37_,
					["ratio"] = math.clamp(v38_, 0.01, 10000)
				}
				self.fillTypeConversions[v36_] = v39_
			end
		end
	end
	if target ~= nil then
		self:setTarget(target)
	end
	self:loadFillTypes(xmlFile, xmlNode)
	self:loadAcceptedToolType(xmlFile, xmlNode)
	self.isEnabled = true
	self.extraAttributes = extraAttributes or self.extraAttributes
	return true
end

function UnloadTrigger:delete()
	if self.exactFillRootNode ~= nil then
		g_currentMission:removeNodeObject(self.exactFillRootNode)
	end
	UnloadTrigger:superClass().delete(self)
end

-- Local values: acceptedToolTypeNames, acceptedToolTypes, _, acceptedToolType, toolTypeInt
function UnloadTrigger:loadAcceptedToolType(xmlFile, xmlNode)
	local v44_ = xmlFile:getValue(xmlNode .. "#acceptedToolTypes")
	local v45_ = string.getVector(v44_)
	if v45_ == nil then
		self.acceptedToolTypes = nil
	else
		for _, v46_ in pairs(v45_) do
			local v47_ = g_toolTypeManager:getToolTypeIndexByName(v46_)
			self.acceptedToolTypes[v47_] = true
		end
	end
end

-- Local values: fillTypes, _, fillType
function UnloadTrigger:loadFillTypes(xmlFile, xmlNode)
	local v51_ = g_fillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, xmlNode)
	if v51_ == nil then
		self.fillTypes = nil
	else
		for _, v52_ in pairs(v51_) do
			self.fillTypes[v52_] = true
		end
	end
end

function UnloadTrigger:setTarget(object)
	local v55_ = object.getIsFillTypeAllowed ~= nil
	assert(v55_, "Missing \'getIsFillTypeAllowed\' method for given target")
	local v56_ = object.getIsToolTypeAllowed ~= nil
	assert(v56_, "Missing \'getIsToolTypeAllowed\' method for given target")
	local v57_ = object.addFillLevelFromTool ~= nil
	assert(v57_, "Missing \'addFillLevelFromTool\' method for given target")
	local v58_ = object.getFreeCapacity ~= nil
	assert(v58_, "Missing \'getFreeCapacity\' method for given target")
	self.target = object
end

function UnloadTrigger:getTarget()
	return self.target
end

function UnloadTrigger:getFillUnitIndexFromNode(node)
	return 1
end

function UnloadTrigger:getFillUnitExactFillRootNode(fillUnitIndex)
	return self.exactFillRootNode
end

-- Local values: fillTypeConverison, convertedFillType, ratio, applied, applied
function UnloadTrigger:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, extraAttributes)
	local v68_ = self.fillTypeConversions[fillTypeIndex]
	if v68_ == nil then
		return self.target:addFillLevelFromTool(farmId, fillLevelDelta, fillTypeIndex, fillPositionData, toolType, extraAttributes or self.extraAttributes)
	end
	local v69_ = v68_.outgoingFillType
	local v70_ = v68_.ratio
	return self.target:addFillLevelFromTool(farmId, fillLevelDelta * v70_, v69_, fillPositionData, toolType, extraAttributes or self.extraAttributes) / v70_
end

-- Local values: supported
function UnloadTrigger:getFillUnitSupportsFillType(fillUnitIndex, fillType)
	return self:getIsFillTypeSupported(fillType)
end

function UnloadTrigger:getFillUnitSupportsToolType(fillUnit, toolType, fillType)
	return true
end

function UnloadTrigger:getFillUnitAllowsFillType(fillUnitIndex, fillType)
	return self:getIsFillTypeAllowed(fillType)
end

function UnloadTrigger:getIsFillTypeAllowed(fillType)
	return self:getIsFillTypeSupported(fillType)
end

-- Local values: conversion
function UnloadTrigger:getIsFillTypeSupported(fillType)
	if self.fillTypes ~= nil and not self.fillTypes[fillType] then
		return false
	end
	if self.target ~= nil then
		local v79_ = self.fillTypeConversions[fillType]
		if v79_ ~= nil then
			fillType = v79_.outgoingFillType
		end
		if not self.target:getIsFillTypeAllowed(fillType, self.extraAttributes) then
			return false
		end
	end
	return true
end

function UnloadTrigger:getIsFillAllowedFromFarm(farmId)
	return (self.target == nil or self.target.getIsFillAllowedFromFarm == nil) and true or self.target:getIsFillAllowedFromFarm(farmId)
end

-- Local values: conversion
function UnloadTrigger:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
	if self.target.getFreeCapacity == nil then
		return 0
	else
		local v85_ = self.fillTypeConversions[fillTypeIndex]
		if v85_ == nil then
			return self.target:getFreeCapacity(fillTypeIndex, farmId, self.extraAttributes)
		else
			return self.target:getFreeCapacity(v85_.outgoingFillType, farmId, self.extraAttributes) / v85_.ratio
		end
	end
end

-- Local values: accepted
function UnloadTrigger:getIsToolTypeAllowed(toolType)
	if self.acceptedToolTypes == nil or self.acceptedToolTypes[toolType] == true then
		return self.target:getIsToolTypeAllowed(toolType)
	else
		return false
	end
end

function UnloadTrigger:getCustomDischargeNotAllowedWarning()
	return self.notAllowedWarningText
end

function UnloadTrigger:getSupportAIUnloading()
	return self.supportsAIUnloading
end

-- Local values: x, _, z, xDir, _, zDir
function UnloadTrigger:getAITargetPositionAndDirection()
	local v91_, _, v92_ = getWorldTranslation(self.aiNode)
	local v93_, _, v94_ = localDirectionToWorld(self.aiNode, 0, 0, 1)
	return v91_, v92_, v93_, v94_
end

-- Local values: fillTypeNames, name, _, unloadTriggerKey, fillTypeIndices, _, fillTypeIndex, fillTypeName
function UnloadTrigger.loadSpecValueFillTypes(xmlFile, xmlPath, customEnvironment, baseDir)
	local v97_ = nil
	for v98_ in pairs(UnloadTrigger.CUSTOM_TRIGGERS) do
		for _, v99_ in xmlFile:iterator(xmlPath .. "." .. v98_) do
			local v100_ = g_fillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, v99_)
			if v100_ ~= nil then
				v97_ = v97_ or {}
				for _, v101_ in ipairs(v100_) do
					v97_[g_fillTypeManager:getFillTypeNameByIndex(v101_)] = true
				end
			end
		end
	end
	return v97_
end
