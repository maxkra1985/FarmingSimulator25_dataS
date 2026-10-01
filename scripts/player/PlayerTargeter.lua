PlayerTargeter = {}
local PlayerTargeter_mt = Class(PlayerTargeter)
function PlayerTargeter.new(player)
	local self = setmetatable({}, PlayerTargeter_mt)
	self.player = player
	self.pooledTargets = ObjectPool.new()
	self.combinedTargetMask = 0
	self.targetedMasks = {}
	self.closestTargetsByKey = {}
	self.currentTargetsByKey = {}
	self.highestMaxDistance = 0
	self.lastRayX = nil
	self.lastRayY = nil
	self.lastRayZ = nil
	self.lastRayDirectionX = nil
	self.lastRayDirectionY = nil
	self.lastRayDirectionZ = nil
	return self
end
function PlayerTargeter:delete() end
function PlayerTargeter:getLastLookRay()
	return self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ
end
function PlayerTargeter:getHasTargetedKey(targetKey)
	return self.targetedMasks[targetKey] ~= nil
end
function PlayerTargeter:addTargetType(targetKey, targetMask, minDistance, maxDistance)
	if self:getHasTargetedKey(targetKey) then
		return
	else
		self.highestMaxDistance = math.max(self.highestMaxDistance, maxDistance)
		self.targetedMasks[targetKey] = { key = targetKey, mask = targetMask, maxDistance = maxDistance, minDistance = minDistance or 0, filterFunctions = {} }
		self:recalculateCombinedTargetMask()
	end
end
function PlayerTargeter:addFilterToTargetType(targetKey, filterFunction)
	local targetedMask = self.targetedMasks[targetKey]
	table.insert(targetedMask.filterFunctions, filterFunction)
end
function PlayerTargeter:removeTargetType(targetKey)
	self.targetedMasks[targetKey] = nil
	self:recalculateCombinedTargetMask()
	self.highestMaxDistance = 0
	for _, targetedMask in pairs(self.targetedMasks) do
		self.highestMaxDistance = math.max(self.highestMaxDistance, targetedMask.maxDistance)
	end
end
function PlayerTargeter:recalculateCombinedTargetMask()
	self.combinedTargetMask = 0
	for _, targetedMask in pairs(self.targetedMasks) do
		self.combinedTargetMask = bit32.bor(self.combinedTargetMask, targetedMask.mask)
	end
end
function PlayerTargeter:getClosestTargetedNodeFromType(targetKey)
	local closestTarget = self.closestTargetsByKey[targetKey]
	return closestTarget ~= nil and closestTarget.node or nil
end
function PlayerTargeter:update(dt)
	self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ = self.player:getLookRay()
	if self.lastRayX == nil then
		return
	else
		self:resetState()
		raycastAllAsync(self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ, self.highestMaxDistance, "raycastCallback", self, self.combinedTargetMask)
	end
end
function PlayerTargeter:resetState()
	for key, target in pairs(self.closestTargetsByKey) do
		self.pooledTargets:returnToPool(target)
		self.closestTargetsByKey[key] = nil
	end
	self.closestTargetsByKey = self.currentTargetsByKey
	self.currentTargetsByKey = self.closestTargetsByKey
end
function PlayerTargeter:raycastCallback(hitNode, x, y, z, distance, normalX, normalY, normalZ, subShapeIndex, hitShapeId, isLast)
	if hitNode == nil or hitNode == 0 then
		return
	end
	for _, targetedMask in pairs(self.targetedMasks) do
		self:tryAddTargetWithMask(hitNode, x, y, z, targetedMask, distance)
	end
end
function PlayerTargeter:tryAddTargetWithMask(hitNode, x, y, z, targetedMask, distance)
	if targetedMask.maxDistance < distance or distance < targetedMask.minDistance or not CollisionFlag.getHasGroupFlagSet(hitNode, targetedMask.mask) then
		return
	end
	local existingClosestTarget = self.currentTargetsByKey[targetedMask.key]
	if existingClosestTarget ~= nil and existingClosestTarget.distance < distance then
		return
	end
	for i, filterFunction in ipairs(targetedMask.filterFunctions) do
		if filterFunction(hitNode, x, y, z) then
			continue
		end
		return
	end
	local target = self.pooledTargets:getOrCreateNext()
	target.x = x
	target.y = y
	target.z = z
	target.node = hitNode
	target.distance = distance
	self.currentTargetsByKey[targetedMask.key] = target
end
function PlayerTargeter:debugDraw(x, y, textSize)
	y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Targeter", nil, true)
	local combinedMaskName = CollisionFlag.getFlagsStringFromMask(self.combinedTargetMask)
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Combined mask: %q", combinedMaskName), nil, true)
	y = DebugUtil.renderTextLine(x, y, textSize, "Masks:", nil, true)
	for key, targetedMask in pairs(self.targetedMasks) do
		local maskNode = self:getClosestTargetedNodeFromType(key)
		local nodeName = maskNode ~= nil and entityExists(maskNode) and getName(maskNode) or "none"
		local maskName = CollisionFlag.getFlagsStringFromMask(targetedMask.mask)
		y = DebugUtil.renderTextLine(x, y, textSize, string.format("Mask %q: %q", maskName, nodeName))
	end
	return y
end
