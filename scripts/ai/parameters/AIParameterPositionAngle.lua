-- Local values: AIParameterPositionAngle_mt
AIParameterPositionAngle = {}
local AIParameterPositionAngle_mt = Class(AIParameterPositionAngle, AIParameterPosition)

-- Upvalues: AIParameterPositionAngle_mt
-- Local values: self
function AIParameterPositionAngle.new(snappingAngle, customMt)
	-- upvalues: (copy) AIParameterPositionAngle_mt
	local v4_ = AIParameterPosition.new(customMt or AIParameterPositionAngle_mt)
	v4_.type = AIParameterType.POSITION_ANGLE
	v4_.angle = nil
	v4_.snappingAngle = math.abs(snappingAngle or 0.08726646259971647)
	return v4_
end

function AIParameterPositionAngle:saveToXMLFile(xmlFile, key, usedModNames)
	AIParameterPositionAngle:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	if self.angle ~= nil then
		xmlFile:setFloat(key .. "#angle", self.angle)
	end
end

function AIParameterPositionAngle:loadFromXMLFile(xmlFile, key)
	AIParameterPositionAngle:superClass().loadFromXMLFile(self, xmlFile, key)
	self.angle = xmlFile:getFloat(key .. "#angle", self.angle)
end

-- Local values: angle
function AIParameterPositionAngle:readStream(streamId, connection)
	AIParameterPositionAngle:superClass().readStream(self, streamId, connection)
	if streamReadBool(streamId) then
		local v15_ = streamReadUIntN(streamId, 9)
		self:setAngle((math.rad(v15_)))
	end
end

-- Local values: angle
function AIParameterPositionAngle:writeStream(streamId, connection)
	AIParameterPositionAngle:superClass().writeStream(self, streamId, connection)
	if streamWriteBool(streamId, self.angle ~= nil) then
		local v19_ = self.angle
		local v20_ = math.deg(v19_)
		streamWriteUIntN(streamId, v20_, 9)
	end
end

-- Local values: numSteps
function AIParameterPositionAngle:setAngle(angleRad)
	local v23_ = angleRad % 6.283185307179586
	if v23_ < 0 then
		v23_ = v23_ + 6.283185307179586
	end
	if self.snappingAngle > 0 then
		v23_ = MathUtil.round(v23_ / self.snappingAngle, 0) * self.snappingAngle
	end
	self.angle = v23_
end

function AIParameterPositionAngle:getAngle()
	return self.angle
end

-- Local values: xDir, zDir
function AIParameterPositionAngle:getDirection()
	if self.angle == nil then
		return nil, nil
	end
	local v26_, v27_ = MathUtil.getDirectionFromYRotation(self.angle)
	return v26_, v27_
end

function AIParameterPositionAngle:setSnappingAngle(angle)
	self.snappingAngle = math.abs(angle)
end

function AIParameterPositionAngle:getSnappingAngle()
	return self.snappingAngle
end

function AIParameterPositionAngle:getString()
	local v32_ = string.format
	local v33_ = self.x
	local v34_ = self.z
	local v35_ = self.angle
	return v32_("< %.1f , %.1f | %d\194\176 >", v33_, v34_, (math.deg(v35_)))
end

-- Local values: isValid, errorMessage
function AIParameterPositionAngle:validate(fillTypeIndex, farmId)
	local v39_, v40_ = AIParameterPositionAngle:superClass().validate(self, fillTypeIndex, farmId)
	if v39_ then
		if self.angle == nil then
			return false, g_i18n:getText("ai_validationErrorNoAngle")
		else
			return true, nil
		end
	else
		return false, v40_
	end
end
