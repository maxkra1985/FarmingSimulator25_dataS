TreeRemoveEvent = {}
local TreeRemoveEvent_mt = Class(TreeRemoveEvent, Event)
InitStaticEventClass(TreeRemoveEvent, "TreeRemoveEvent")
TreeRemoveEvent.PRICE_PER_METER = 50
function TreeRemoveEvent.emptyNew()
	local self = Event.new(TreeRemoveEvent_mt)
	return self
end
function TreeRemoveEvent.new(splitShapeId)
	local self = TreeRemoveEvent.emptyNew()
	self.splitShapeId = splitShapeId
	return self
end
function TreeRemoveEvent:readStream(streamId, connection)
	self.splitShapeId = readSplitShapeIdFromStream(streamId)
	self:run(connection)
end
function TreeRemoveEvent:writeStream(streamId, connection)
	writeSplitShapeIdToStream(streamId, self.splitShapeId)
end
function TreeRemoveEvent:run(connection)
	if connection:getIsServer() then
		Logging.devError("TreeRemoveEvent: only client to server requests are supported")
		return
	end
	local player = g_currentMission:getPlayerByConnection(connection)
	if player == nil then
		return
	end
	local farmId = player.farmId
	local shape = self.splitShapeId
	if not TreeRemoveEvent.getIsTreeRemovable(shape, farmId, connection) then
		return
	end
	local price = TreeRemoveEvent.getPrice(shape)
	if g_currentMission:getMoney(farmId) < price then
		return
	else
		local aabbMin, aabbMax = getRigidBodyAABBVector(shape)
		deleteSplitShape(shape)
		g_densityMapHeightManager:setCollisionMapAreaDirty(aabbMin.x, aabbMin.z, aabbMax.x, aabbMax.z, true)
		g_currentMission.aiSystem:setAreaDirty(aabbMin.x, aabbMax.x, aabbMin.z, aabbMax.z)
		g_currentMission:addMoney(-price, farmId, MoneyType.SHOP_PROPERTY_BUY, true)
	end
end
function TreeRemoveEvent.getIsTreeRemovable(shape, farmId, connection)
	if shape == nil or shape == 0 then
		return false
	end
	if not entityExists(shape) or not getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE) then
		return false
	end
	if getSplitType(shape) == 0 or getIsSplitShapeSplit(shape) then
		return false
	end
	if getRigidBodyType(shape) ~= RigidBodyType.STATIC or getRigidBodyAABBVector(shape) == nil then
		return false
	end
	local x, _, z = getWorldTranslation(shape)
	if not g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z, true) then
		return false
	else
		return g_splitShapeManager:getIsShapeCutAllowed(x, z, shape, farmId, connection)
	end
end
function TreeRemoveEvent.getPrice(shape)
	local aabbMin, aabbMax = getRigidBodyAABBVector(shape)
	local height = aabbMax.y - aabbMin.y
	return math.ceil(height * TreeRemoveEvent.PRICE_PER_METER * EconomyManager.getCostMultiplier())
end
