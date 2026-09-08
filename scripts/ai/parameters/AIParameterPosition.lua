-- Local values: AIParameterPosition_mt
AIParameterPosition = {}
local AIParameterPosition_mt = Class(AIParameterPosition, AIParameter)

-- Upvalues: AIParameterPosition_mt
-- Local values: self
function AIParameterPosition.new(customMt)
	-- upvalues: (copy) AIParameterPosition_mt
	local v3_ = AIParameter.new(customMt or AIParameterPosition_mt)
	v3_.type = AIParameterType.POSITION
	v3_.x = nil
	v3_.z = nil
	return v3_
end

function AIParameterPosition:saveToXMLFile(xmlFile, key, usedModNames)
	if self.x ~= nil then
		xmlFile:setFloat(key .. "#x", self.x)
		xmlFile:setFloat(key .. "#z", self.z)
	end
end

function AIParameterPosition:loadFromXMLFile(xmlFile, key)
	self.x = xmlFile:getFloat(key .. "#x", self.x)
	self.z = xmlFile:getFloat(key .. "#z", self.z)
end

-- Local values: x, z
function AIParameterPosition:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self:setPosition(streamReadFloat32(streamId), (streamReadFloat32(streamId)))
	end
end

function AIParameterPosition:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.x ~= nil) then
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.z)
	end
end

function AIParameterPosition:setPosition(x, z)
	self.x = x
	self.z = z
end

function AIParameterPosition:getPosition()
	return self.x, self.z
end

function AIParameterPosition:getString()
	return string.format("< %.1f , %.1f >", self.x, self.z)
end

function AIParameterPosition:validate()
	if self.x == nil or self.z == nil then
		return false, g_i18n:getText("ai_validationErrorNoPosition")
	elseif g_currentMission.aiSystem:getIsPositionReachable(self.x, 0, self.z) then
		return true, nil
	else
		return false, g_i18n:getText("ai_validationErrorBlockedPosition")
	end
end
