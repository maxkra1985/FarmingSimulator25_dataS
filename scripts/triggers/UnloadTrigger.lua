UnloadTrigger = {}
UnloadTrigger.CUSTOM_TRIGGERS = {}
function UnloadTrigger.registerCustomTrigger(name, classObj)
	UnloadTrigger.CUSTOM_TRIGGERS[name] = classObj
end
function UnloadTrigger.registerTriggerXMLPaths(schema, basePath)
	for name, classObj in pairs(UnloadTrigger.CUSTOM_TRIGGERS) do
		if classObj.registerXMLPaths == nil then
			continue
		end
		classObj.registerXMLPaths(schema, basePath .. "." .. name .. "(?)")
	end
end
UnloadTrigger.registerCustomTrigger("unloadTrigger", UnloadTrigger)
function UnloadTrigger.createTriggers(isServer, isClient, xmlFile, key, components, target, extraAttributes, i3dMappings)
	local triggers = {}
	for name, class in pairs(UnloadTrigger.CUSTOM_TRIGGERS) do
		for _, triggerKey in xmlFile:iterator(key .. "." .. name) do
			local trigger = class.new(isServer, isClient)
			if trigger:load(components, xmlFile, triggerKey, target, extraAttributes, i3dMappings) then
				trigger:setTarget(target)
				table.insert(triggers, trigger)
			else
				trigger:delete()
			end
		end
	end
	return triggers
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
local UnloadTrigger_mt = Class(UnloadTrigger, Object)
InitStaticObjectClass(UnloadTrigger, "UnloadTrigger")
function UnloadTrigger.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or UnloadTrigger_mt)
	self.fillTypes = {}
	self.acceptedToolTypes = {}
	self.fillTypeConversions = {}
	self.notAllowedWarningText = nil
	self.extraAttributes = nil
	return self
end
function UnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
	self.exactFillRootNode = xmlFile:getValue(xmlNode .. "#exactFillRootNode", nil, components, i3dMappings)
	if self.exactFillRootNode ~= nil then
		if not CollisionFlag.getHasGroupFlagSet(self.exactFillRootNode, CollisionFlag.FILLABLE) then
			Logging.xmlWarning(xmlFile, "Missing collision group %s. Please add this bit to the collision filter group of exact fill node '%s'", CollisionFlag.getBitAndName(CollisionFlag.FILLABLE), I3DUtil.getNodePath(self.exactFillRootNode))
			return false
		end
		g_currentMission:addNodeObject(self.exactFillRootNode, self)
	end
	self.aiNode = xmlFile:getValue(xmlNode .. "#aiNode", nil, components, i3dMappings)
	self.supportsAIUnloading = self.aiNode ~= nil
	local priceScale = xmlFile:getValue(xmlNode .. "#priceScale", nil)
	if priceScale ~= nil then
		self.extraAttributes = { priceScale = priceScale }
	end
	for _, fillTypeConversionPath in xmlFile:iterator(xmlNode .. ".fillTypeConversion") do
		local fillTypeIndexIncoming = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(fillTypeConversionPath .. "#incomingFillType"))
		if fillTypeIndexIncoming == nil then
			continue
		end
		local fillTypeIndexOutgoing = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(fillTypeConversionPath .. "#outgoingFillType"))
		if fillTypeIndexOutgoing == nil then
			continue
		end
		local ratio = math.clamp(xmlFile:getValue(fillTypeConversionPath .. "#ratio", 1), 0.01, 10000)
		self.fillTypeConversions[fillTypeIndexIncoming] = { outgoingFillType = fillTypeIndexOutgoing, ratio = ratio }
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
function UnloadTrigger:loadAcceptedToolType(xmlFile, xmlNode)
	local acceptedToolTypeNames = xmlFile:getValue(xmlNode .. "#acceptedToolTypes")
	local acceptedToolTypes = string.getVector(acceptedToolTypeNames)
	if acceptedToolTypes ~= nil then
		for _, acceptedToolType in pairs(acceptedToolTypes) do
			local toolTypeInt = g_toolTypeManager:getToolTypeIndexByName(acceptedToolType)
			self.acceptedToolTypes[toolTypeInt] = true
		end
	else
		self.acceptedToolTypes = nil
	end
end
function UnloadTrigger:loadFillTypes(xmlFile, xmlNode)
	local fillTypes = g_fillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, xmlNode)
	if fillTypes ~= nil then
		for _, fillType in pairs(fillTypes) do
			self.fillTypes[fillType] = true
		end
	else
		self.fillTypes = nil
	end
end
function UnloadTrigger:setTarget(object)
	assert(object.getIsFillTypeAllowed ~= nil, "Missing 'getIsFillTypeAllowed' method for given target")
	assert(object.getIsToolTypeAllowed ~= nil, "Missing 'getIsToolTypeAllowed' method for given target")
	assert(object.addFillLevelFromTool ~= nil, "Missing 'addFillLevelFromTool' method for given target")
	assert(object.getFreeCapacity ~= nil, "Missing 'getFreeCapacity' method for given target")
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
function UnloadTrigger:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, extraAttributes)
	local fillTypeConverison = self.fillTypeConversions[fillTypeIndex]
	if fillTypeConverison ~= nil then
		local convertedFillType = fillTypeConverison.outgoingFillType
		local ratio = fillTypeConverison.ratio
		local applied = self.target:addFillLevelFromTool(farmId, fillLevelDelta * ratio, convertedFillType, fillPositionData, toolType, extraAttributes or self.extraAttributes)
		return applied / ratio
	else
		local applied = self.target:addFillLevelFromTool(farmId, fillLevelDelta, fillTypeIndex, fillPositionData, toolType, extraAttributes or self.extraAttributes)
		return applied
	end
end
function UnloadTrigger:getFillUnitSupportsFillType(fillUnitIndex, fillType)
	local supported = self:getIsFillTypeSupported(fillType)
	return supported
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
function UnloadTrigger:getIsFillTypeSupported(fillType)
	if self.fillTypes ~= nil and not self.fillTypes[fillType] then
		return false
	end
	if self.target ~= nil then
		local conversion = self.fillTypeConversions[fillType]
		if conversion ~= nil then
			fillType = conversion.outgoingFillType
		end
		if not self.target:getIsFillTypeAllowed(fillType, self.extraAttributes) then
			return false
		end
	end
	return true
end
function UnloadTrigger:getIsFillAllowedFromFarm(farmId)
	if self.target ~= nil and self.target.getIsFillAllowedFromFarm ~= nil then
		return self.target:getIsFillAllowedFromFarm(farmId)
	end
	return true
end
function UnloadTrigger:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
	if self.target.getFreeCapacity ~= nil then
		local conversion = self.fillTypeConversions[fillTypeIndex]
		if conversion ~= nil then
			return self.target:getFreeCapacity(conversion.outgoingFillType, farmId, self.extraAttributes) / conversion.ratio
		else
			return self.target:getFreeCapacity(fillTypeIndex, farmId, self.extraAttributes)
		end
	end
	return 0
end
function UnloadTrigger:getIsToolTypeAllowed(toolType)
	local accepted = true
	if self.acceptedToolTypes ~= nil and self.acceptedToolTypes[toolType] ~= true then
		accepted = false
	end
	if accepted then
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
function UnloadTrigger:getAITargetPositionAndDirection()
	local x, _, z = getWorldTranslation(self.aiNode)
	local xDir, _, zDir = localDirectionToWorld(self.aiNode, 0, 0, 1)
	return x, z, xDir, zDir
end
function UnloadTrigger.loadSpecValueFillTypes(xmlFile, xmlPath, customEnvironment, baseDir)
	local fillTypeNames = nil
	for name in pairs(UnloadTrigger.CUSTOM_TRIGGERS) do
		for _, unloadTriggerKey in xmlFile:iterator(xmlPath .. "." .. name) do
			local fillTypeIndices = g_fillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, unloadTriggerKey)
			if fillTypeIndices == nil then
				continue
			end
			fillTypeNames = fillTypeNames or {}
			for _, fillTypeIndex in ipairs(fillTypeIndices) do
				local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
				fillTypeNames[fillTypeName] = true
			end
		end
	end
	return fillTypeNames
end
