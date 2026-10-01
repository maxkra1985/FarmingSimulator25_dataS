ConditionalAnimation = {}
local ConditionalAnimation_mt = Class(ConditionalAnimation)
g_xmlManager:addCreateSchemaFunction(function()
	ConditionalAnimation.xmlSchema = XMLSchema.new("conditionalAnimation")
end)
g_xmlManager:addInitSchemaFunction(function()
	local schema = ConditionalAnimation.xmlSchema
	ConditionalAnimation.registerXMLPaths(schema, "conditionalAnimation")
end)
function ConditionalAnimation.registerXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. ".item(?)#id", "")
	schema:register(XMLValueType.FLOAT, key .. ".item(?)#entryTransitionDuration", "")
	schema:register(XMLValueType.FLOAT, key .. ".item(?)#exitTransitionDuration", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).clips#speedScaleType", "", nil, false, { "none", "fixed", "distance", "angular" })
	schema:register(XMLValueType.FLOAT, key .. ".item(?).clips#speedScaleParameter", "")
	schema:register(XMLValueType.BOOL, key .. ".item(?).clips#blended", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).clips#blendingParameter", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).clips#blendingParameterType", "", nil, false, { "scalar", "angular" })
	schema:register(XMLValueType.STRING, key .. ".item(?).clips.clip(?)#clipName", "")
	schema:register(XMLValueType.BOOL, key .. ".item(?).clips.clip(?)#loop", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).clips.clip(?)#id", "")
	schema:register(XMLValueType.FLOAT, key .. ".item(?).clips.clip(?)#blendingThreshold", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).callbacks.callback(?)#name", "")
	schema:register(XMLValueType.FLOAT, key .. ".item(?).callbacks.callback(?)#time", "")
	schema:register(XMLValueType.FLOAT, key .. ".item(?).callbacks.callback(?)#interval", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#parameter", "")
	schema:register(XMLValueType.BOOL, key .. ".item(?).conditions.conditionGroup(?).condition(?)#or_condition", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#greater", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#greaterOrEqual", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#lower", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#lowerOrEqual", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#equal", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#notEqual", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#between", 'between="value1, value2"')
	schema:register(XMLValueType.FLOAT, key .. ".item(?).conditions.conditionGroup(?).condition(?)#outside", 'outside="value1, value2"')
end
ConditionalAnimation.TYPE = {}
ConditionalAnimation.TYPE.FLOAT = 0
ConditionalAnimation.TYPE.BOOL = 1
function ConditionalAnimation.new(customMt)
	local self = setmetatable({}, customMt or ConditionalAnimation_mt)
	self.animationId = nil
	self.parameters = {}
	self.nameToParameter = {}
	self.specialParameterIdDistance = 0
	self.specialParameterIdAngle = 0
	self.widestParameterNameWidth = 0
	return self
end
function ConditionalAnimation:load(skeletonNode, xmlFilename, xmlKey, sourceNode)
	if self.animationId ~= nil then
		Logging.error("ConditionalAnimation already loaded!")
		printCallstack()
	elseif g_dedicatedServer == nil then
		local xmlFile = XMLFile.load("ConditionalAnimation", xmlFilename)
		if xmlFile ~= nil then
			for _, itemKey in xmlFile:iterator(xmlKey .. ".item") do
				for _, conditionGroupKey in xmlFile:iterator(itemKey .. ".conditions.conditionGroup") do
					for _, conditionKey in xmlFile:iterator(conditionGroupKey .. ".condition") do
						local parameter = xmlFile:getString(conditionKey .. "#parameter")
						if self.nameToParameter[parameter] == nil then
							Logging.xmlWarning(xmlFile, "Parameter '%s' not defined for condition '%s'", parameter, conditionKey)
						end
					end
				end
			end
			xmlFile:delete()
		end
		if sourceNode ~= nil and not cloneAnimCharacterSet(sourceNode, getParent(skeletonNode)) then
			Logging.warning("Cloning character animation set failed, aborting animation load")
			return
		end
		self.skeletonNode = skeletonNode
		local animCharsetId = getAnimCharacterSet(getChildAt(skeletonNode, 0))
		local animationId = createConditionalAnimation()
		if animationId ~= 0 and animCharsetId ~= 0 then
			self.animationId = animationId
			for _, parameter in pairs(self.parameters) do
				conditionalAnimationRegisterParameter(self.animationId, parameter.id, parameter.type, parameter.name)
			end
			initConditionalAnimation(self.animationId, animCharsetId, xmlFilename, xmlKey)
			self:setSpecialParameterIds(self.specialParameterIdDistance, self.specialParameterIdAngle)
		end
	end
end
function ConditionalAnimation:unload()
	if self.animationId ~= nil then
		delete(self.animationId)
		self.animationId = nil
	end
end
function ConditionalAnimation:delete()
	self:unload()
end
function ConditionalAnimation:registerParameter(name, paramType)
	if self.nameToParameter[name] ~= nil then
		Logging.error("ConditionalAnimation parameter '%s' already defined", tostring(name))
		return nil
	else
		local paramTypeName = paramType == ConditionalAnimation.TYPE.FLOAT and "float" or "bool"
		local id = #self.parameters + 1
		local parameter = { id = id, name = name, type = paramType }
		parameter.value = paramType == ConditionalAnimation.TYPE.FLOAT and 0 or false
		parameter.debugName = string.format("(%s) %s:", paramTypeName, name)
		table.insert(self.parameters, parameter)
		self.nameToParameter[name] = id
		local parameterDebugNameWidth = getTextWidth(1, parameter.debugName)
		if self.widestParameterNameWidth < parameterDebugNameWidth then
			self.widestParameterNameWidth = parameterDebugNameWidth
		end
		return id
	end
end
function ConditionalAnimation:setSpecialParameterIds(distanceParameterId, angleParameterId)
	self.specialParameterIdDistance = distanceParameterId
	self.specialParameterIdAngle = angleParameterId
	if self.animationId ~= nil then
		setConditionalAnimationSpecificParameterIds(self.animationId, distanceParameterId, angleParameterId)
	end
end
function ConditionalAnimation:setParameter(parameterId, value)
	local param = self.parameters[parameterId]
	if param == nil then
		return
	else
		param.value = value
		if self.animationId ~= nil then
			if param.type == ConditionalAnimation.TYPE.FLOAT then
				setConditionalAnimationFloatValue(self.animationId, param.id, value)
				return
			end
			if param.type == ConditionalAnimation.TYPE.BOOL then
				setConditionalAnimationBoolValue(self.animationId, param.id, value)
				return
			end
			Logging.warning("Unsupported conditional animation parameter type! " .. tostring(param.type))
		end
	end
end
function ConditionalAnimation:getParameter(parameterId)
	local param = self.parameters[parameterId]
	if param == nil then
		return nil
	else
		if self.animationId ~= nil then
			if param.type == ConditionalAnimation.TYPE.FLOAT then
				return getConditionalAnimationFloatValue(self.animationId, param.id)
			elseif param.type == ConditionalAnimation.TYPE.BOOL then
				return getConditionalAnimationFloatValue(self.animationId, param.id)
			else
				Logging.warning("Unsupported conditional animation parameter type! " .. tostring(param.type))
				return nil
			end
		end
		return nil
	end
end
function ConditionalAnimation:update(dt)
	if self.animationId ~= nil then
		updateConditionalAnimation(self.animationId, dt)
	end
end
function ConditionalAnimation:debugDraw(x, y, textSize)
	if self.animationId ~= nil then
		local wx, wy, wz = getWorldTranslation(self.skeletonNode)
		conditionalAnimationDebugDraw(self.animationId, wx, wy, wz)
	end
	return y
end
