-- Local values: ConditionalAnimation_mt
ConditionalAnimation = {}
local ConditionalAnimation_mt = Class(ConditionalAnimation)
g_xmlManager:addCreateSchemaFunction(function()
	ConditionalAnimation.xmlSchema = XMLSchema.new("conditionalAnimation")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = ConditionalAnimation.xmlSchema
	ConditionalAnimation.registerXMLPaths(v2_, "conditionalAnimation")
end)

function ConditionalAnimation.registerXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. ".item(?)#id", "")
	schema:register(XMLValueType.FLOAT, key .. ".item(?)#entryTransitionDuration", "")
	schema:register(XMLValueType.FLOAT, key .. ".item(?)#exitTransitionDuration", "")
	schema:register(XMLValueType.STRING, key .. ".item(?).clips#speedScaleType", "", nil, false, {
		"none",
		"fixed",
		"distance",
		"angular"
	})
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
	schema:register(XMLValueType.STRING, key .. ".item(?).conditions.conditionGroup(?).condition(?)#between", "between=\"value1, value2\"")
	schema:register(XMLValueType.FLOAT, key .. ".item(?).conditions.conditionGroup(?).condition(?)#outside", "outside=\"value1, value2\"")
end
ConditionalAnimation.TYPE = {}
ConditionalAnimation.TYPE.FLOAT = 0
ConditionalAnimation.TYPE.BOOL = 1

-- Upvalues: ConditionalAnimation_mt
-- Local values: self
function ConditionalAnimation.new(customMt)
	-- upvalues: (copy) ConditionalAnimation_mt
	local v6_ = customMt or ConditionalAnimation_mt
	local v7_ = setmetatable({}, v6_)
	v7_.animationId = nil
	v7_.parameters = {}
	v7_.nameToParameter = {}
	v7_.specialParameterIdDistance = 0
	v7_.specialParameterIdAngle = 0
	v7_.widestParameterNameWidth = 0
	return v7_
end

-- Local values: xmlFile, _, itemKey, _, conditionGroupKey, _, conditionKey, parameter, animCharsetId, animationId, _, parameter
function ConditionalAnimation:load(skeletonNode, xmlFilename, xmlKey, sourceNode)
	if self.animationId == nil then
		if g_dedicatedServer == nil then
			local v13_ = XMLFile.load("ConditionalAnimation", xmlFilename)
			if v13_ ~= nil then
				for _, v14_ in v13_:iterator(xmlKey .. ".item") do
					for _, v15_ in v13_:iterator(v14_ .. ".conditions.conditionGroup") do
						for _, v16_ in v13_:iterator(v15_ .. ".condition") do
							local v17_ = v13_:getString(v16_ .. "#parameter")
							if self.nameToParameter[v17_] == nil then
								Logging.xmlWarning(v13_, "Parameter \'%s\' not defined for condition \'%s\'", v17_, v16_)
							end
						end
					end
				end
				v13_:delete()
			end
			if sourceNode == nil or cloneAnimCharacterSet(sourceNode, getParent(skeletonNode)) then
				self.skeletonNode = skeletonNode
				local v18_ = getAnimCharacterSet(getChildAt(skeletonNode, 0))
				local v19_ = createConditionalAnimation()
				if v19_ ~= 0 and v18_ ~= 0 then
					self.animationId = v19_
					for _, v20_ in pairs(self.parameters) do
						conditionalAnimationRegisterParameter(self.animationId, v20_.id, v20_.type, v20_.name)
					end
					initConditionalAnimation(self.animationId, v18_, xmlFilename, xmlKey)
					self:setSpecialParameterIds(self.specialParameterIdDistance, self.specialParameterIdAngle)
				end
			else
				Logging.warning("Cloning character animation set failed, aborting animation load")
			end
		else
			return
		end
	else
		Logging.error("ConditionalAnimation already loaded!")
		printCallstack()
		return
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

-- Local values: paramTypeName, id, parameter, parameterDebugNameWidth
function ConditionalAnimation:registerParameter(name, paramType)
	if self.nameToParameter[name] ~= nil then
		Logging.error("ConditionalAnimation parameter \'%s\' already defined", (tostring(name)))
		return nil
	end
	local v26_ = paramType == ConditionalAnimation.TYPE.FLOAT and "float" or "bool"
	local v27_ = #self.parameters + 1
	local v28_ = {
		["id"] = v27_,
		["name"] = name,
		["type"] = paramType,
		["value"] = paramType == ConditionalAnimation.TYPE.FLOAT and 0 or false,
		["debugName"] = string.format("(%s) %s:", v26_, name)
	}
	local v29_ = self.parameters
	table.insert(v29_, v28_)
	self.nameToParameter[name] = v27_
	local v30_ = getTextWidth(1, v28_.debugName)
	if self.widestParameterNameWidth < v30_ then
		self.widestParameterNameWidth = v30_
	end
	return v27_
end

function ConditionalAnimation:setSpecialParameterIds(distanceParameterId, angleParameterId)
	self.specialParameterIdDistance = distanceParameterId
	self.specialParameterIdAngle = angleParameterId
	if self.animationId ~= nil then
		setConditionalAnimationSpecificParameterIds(self.animationId, distanceParameterId, angleParameterId)
	end
end

-- Local values: param
function ConditionalAnimation:setParameter(parameterId, value)
	local v37_ = self.parameters[parameterId]
	if v37_ ~= nil then
		v37_.value = value
		if self.animationId ~= nil then
			if v37_.type == ConditionalAnimation.TYPE.FLOAT then
				setConditionalAnimationFloatValue(self.animationId, v37_.id, value)
				return
			end
			if v37_.type == ConditionalAnimation.TYPE.BOOL then
				setConditionalAnimationBoolValue(self.animationId, v37_.id, value)
				return
			end
			local v38_ = Logging.warning
			local v39_ = v37_.type
			v38_("Unsupported conditional animation parameter type! " .. tostring(v39_))
		end
	end
end

-- Local values: param
function ConditionalAnimation:getParameter(parameterId)
	local v42_ = self.parameters[parameterId]
	if v42_ == nil then
		return nil
	end
	if self.animationId == nil then
		return nil
	end
	if v42_.type == ConditionalAnimation.TYPE.FLOAT then
		return getConditionalAnimationFloatValue(self.animationId, v42_.id)
	end
	if v42_.type == ConditionalAnimation.TYPE.BOOL then
		return getConditionalAnimationFloatValue(self.animationId, v42_.id)
	end
	local v43_ = Logging.warning
	local v44_ = v42_.type
	v43_("Unsupported conditional animation parameter type! " .. tostring(v44_))
	return nil
end

function ConditionalAnimation:update(dt)
	if self.animationId ~= nil then
		updateConditionalAnimation(self.animationId, dt)
	end
end

-- Local values: wx, wy, wz
function ConditionalAnimation:debugDraw(x, y, textSize)
	if self.animationId ~= nil then
		local v49_, v50_, v51_ = getWorldTranslation(self.skeletonNode)
		conditionalAnimationDebugDraw(self.animationId, v49_, v50_, v51_)
	end
	return y
end
