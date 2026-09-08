-- Local values: AIParameterVehicle_mt
AIParameterVehicle = {}
local AIParameterVehicle_mt = Class(AIParameterVehicle, AIParameter)

-- Upvalues: AIParameterVehicle_mt
-- Local values: self
function AIParameterVehicle.new(customMt)
	-- upvalues: (copy) AIParameterVehicle_mt
	local v3_ = AIParameter.new(customMt or AIParameterVehicle_mt)
	v3_.type = AIParameterType.TEXT
	v3_.vehicleId = nil
	return v3_
end

-- Local values: vehicle
function AIParameterVehicle:saveToXMLFile(xmlFile, key, usedModNames)
	local v7_ = self:getVehicle()
	if v7_ ~= nil then
		xmlFile:setString(key .. "#vehicleUniqueId", v7_:getUniqueId())
	end
end

function AIParameterVehicle:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self.vehicleId = NetworkUtil.readNodeObjectId(streamId)
	end
end

function AIParameterVehicle:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.vehicleId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, self.vehicleId)
	end
end

function AIParameterVehicle:getCanBeChanged()
	return false
end

-- Local values: vehicle
function AIParameterVehicle:getString()
	local v13_ = NetworkUtil.getObject(self.vehicleId)
	return v13_ == nil and "" or v13_:getName()
end

function AIParameterVehicle:setVehicle(vehicle)
	self.vehicleId = NetworkUtil.getObjectId(vehicle)
end

-- Local values: vehicle
function AIParameterVehicle:getVehicle()
	local v17_ = NetworkUtil.getObject(self.vehicleId)
	if v17_ == nil or not v17_:getIsSynchronized() then
		return nil
	else
		return v17_
	end
end

-- Local values: vehicle
function AIParameterVehicle:validate(needsAITarget)
	if self.vehicleId == nil then
		return false, g_i18n:getText("ai_validationErrorNoVehicle")
	else
		local v20_ = self:getVehicle()
		if v20_ == nil then
			return false, g_i18n:getText("ai_validationErrorVehicleDoesNotExistAnymore")
		elseif v20_.setAITarget == nil and (needsAITarget == nil or needsAITarget == true) then
			return false, g_i18n:getText("ai_validationErrorVehicleDoesNotSupportAI")
		else
			return true, nil
		end
	end
end
