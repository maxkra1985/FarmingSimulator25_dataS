-- Local values: AccessHandler_mt
AccessHandler = {}
AccessHandler.EVERYONE = 0
AccessHandler.NOBODY = 2 ^ FarmManager.FARM_ID_SEND_NUM_BITS - 1
local AccessHandler_mt = Class(AccessHandler)

-- Upvalues: AccessHandler_mt
-- Local values: self
function AccessHandler.new(customMt)
	-- upvalues: (copy) AccessHandler_mt
	local v3_ = customMt or AccessHandler_mt
	return setmetatable({}, v3_)
end

function AccessHandler:delete() end

-- Local values: playerFarmId
function AccessHandler:canPlayerAccess(object, player, allowEqualAlways)
	local v8_
	if player == nil then
		v8_ = g_currentMission:getFarmId()
	else
		v8_ = player.farmId
	end
	return self:canFarmAccess(v8_, object, allowEqualAlways)
end

-- Local values: ownerFarmId
function AccessHandler:canFarmAccess(farmId, object, allowEqualAlways)
	if object == nil then
		return false
	else
		local v13_ = object:getOwnerFarmId()
		if farmId == FarmManager.SPECTATOR_FARM_ID and (not allowEqualAlways or farmId ~= v13_) then
			return false
		elseif v13_ == nil or v13_ == AccessHandler.EVERYONE then
			return true
		elseif farmId == nil then
			return v13_ == AccessHandler.EVERYONE
		else
			return self:canFarmAccessOtherId(farmId, v13_)
		end
	end
end

-- Local values: farm
function AccessHandler:canFarmAccessOtherId(farmId, objectFarmId)
	if objectFarmId == AccessHandler.EVERYONE then
		return true
	elseif objectFarmId == AccessHandler.NOBODY then
		return false
	elseif objectFarmId == farmId then
		return true
	else
		local v16_ = g_farmManager:getFarmById(farmId)
		if v16_ == nil then
			return false
		else
			return v16_:getIsContractingFor(objectFarmId)
		end
	end
end

-- Local values: ownerFarmId, farm
function AccessHandler:canFarmAccessLand(farmId, x, z, disallowContracting)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID then
		return false
	end
	local v21_ = g_farmlandManager:getOwnerIdAtWorldPosition(x, z)
	if v21_ == farmId then
		return true
	end
	local v22_ = g_farmManager:getFarmById(farmId)
	if v22_ == nil then
		return false
	end
	local v23_
	if disallowContracting == true then
		v23_ = false
	else
		v23_ = v22_:getIsContractingFor(v21_)
	end
	return v23_
end
