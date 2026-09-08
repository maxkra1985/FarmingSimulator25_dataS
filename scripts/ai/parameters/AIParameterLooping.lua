-- Local values: AIParameterLooping_mt
AIParameterLooping = {}
local AIParameterLooping_mt = Class(AIParameterLooping, AIParameter)

-- Upvalues: AIParameterLooping_mt
-- Local values: self
function AIParameterLooping.new(customMt)
	-- upvalues: (copy) AIParameterLooping_mt
	local v3_ = AIParameter.new(customMt or AIParameterLooping_mt)
	v3_.type = AIParameterType.SELECTOR
	v3_.isLooping = false
	return v3_
end

function AIParameterLooping:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setBool(key .. "#isLooping", self.isLooping)
end

function AIParameterLooping:loadFromXMLFile(xmlFile, key)
	self.isLooping = xmlFile:getBool(key .. "#isLooping", self.isLooping)
end

function AIParameterLooping:readStream(streamId, connection)
	self:setIsLooping(streamReadBool(streamId))
end

function AIParameterLooping:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isLooping)
end

function AIParameterLooping:setIsLooping(isLooping)
	self.isLooping = isLooping
end

function AIParameterLooping:getIsLooping()
	return self.isLooping
end

function AIParameterLooping:getString()
	if self.isLooping then
		return g_i18n:getText("ai_parameterValueLooping")
	else
		return g_i18n:getText("ai_parameterValueNoLooping")
	end
end

function AIParameterLooping:setNextItem()
	self.isLooping = not self.isLooping
end

function AIParameterLooping:setPreviousItem()
	self.isLooping = not self.isLooping
end
