-- Local values: PlayerTargeter_mt
PlayerTargeter = {}
local PlayerTargeter_mt = Class(PlayerTargeter)

-- Upvalues: PlayerTargeter_mt
-- Local values: self
function PlayerTargeter.new(player)
	-- upvalues: (copy) PlayerTargeter_mt
	local v3_ = PlayerTargeter_mt
	local v4_ = setmetatable({}, v3_)
	v4_.player = player
	v4_.pooledTargets = ObjectPool.new()
	v4_.combinedTargetMask = 0
	v4_.targetedMasks = {}
	v4_.closestTargetsByKey = {}
	v4_.currentTargetsByKey = {}
	v4_.highestMaxDistance = 0
	v4_.lastRayX = nil
	v4_.lastRayY = nil
	v4_.lastRayZ = nil
	v4_.lastRayDirectionX = nil
	v4_.lastRayDirectionY = nil
	v4_.lastRayDirectionZ = nil
	return v4_
end

function PlayerTargeter:delete() end

function PlayerTargeter:getLastLookRay()
	return self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ
end

function PlayerTargeter:getHasTargetedKey(targetKey)
	return self.targetedMasks[targetKey] ~= nil
end

function PlayerTargeter:addTargetType(targetKey, targetMask, minDistance, maxDistance)
	if not self:getHasTargetedKey(targetKey) then
		local v13_ = self.highestMaxDistance
		self.highestMaxDistance = math.max(v13_, maxDistance)
		self.targetedMasks[targetKey] = {
			["key"] = targetKey,
			["mask"] = targetMask,
			["minDistance"] = minDistance or 0,
			["maxDistance"] = maxDistance,
			["filterFunctions"] = {}
		}
		self:recalculateCombinedTargetMask()
	end
end

-- Local values: targetedMask
function PlayerTargeter:addFilterToTargetType(targetKey, filterFunction)
	local v17_ = self.targetedMasks[targetKey].filterFunctions
	table.insert(v17_, filterFunction)
end

-- Local values: _, targetedMask
function PlayerTargeter:removeTargetType(targetKey)
	self.targetedMasks[targetKey] = nil
	self:recalculateCombinedTargetMask()
	self.highestMaxDistance = 0
	for _, v20_ in pairs(self.targetedMasks) do
		local v21_ = self.highestMaxDistance
		local v22_ = v20_.maxDistance
		self.highestMaxDistance = math.max(v21_, v22_)
	end
end

-- Local values: _, targetedMask
function PlayerTargeter:recalculateCombinedTargetMask()
	self.combinedTargetMask = 0
	for _, v24_ in pairs(self.targetedMasks) do
		local v25_ = self.combinedTargetMask
		local v26_ = v24_.mask
		self.combinedTargetMask = bit32.bor(v25_, v26_)
	end
end

-- Local values: closestTarget
function PlayerTargeter:getClosestTargetedNodeFromType(targetKey)
	local v29_ = self.closestTargetsByKey[targetKey]
	return v29_ ~= nil and v29_.node or nil
end

function PlayerTargeter:update(dt)
	local v31_, v32_, v33_, v34_, v35_, v36_ = self.player:getLookRay()
	self.lastRayX = v31_
	self.lastRayY = v32_
	self.lastRayZ = v33_
	self.lastRayDirectionX = v34_
	self.lastRayDirectionY = v35_
	self.lastRayDirectionZ = v36_
	if self.lastRayX ~= nil then
		self:resetState()
		raycastAllAsync(self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ, self.highestMaxDistance, "raycastCallback", self, self.combinedTargetMask)
	end
end

-- Local values: key, target
function PlayerTargeter:resetState()
	for v38_, v39_ in pairs(self.closestTargetsByKey) do
		self.pooledTargets:returnToPool(v39_)
		self.closestTargetsByKey[v38_] = nil
	end
	local v40_ = self.currentTargetsByKey
	local v41_ = self.closestTargetsByKey
	self.closestTargetsByKey = v40_
	self.currentTargetsByKey = v41_
end

-- Local values: _, targetedMask
function PlayerTargeter:raycastCallback(hitNode, x, y, z, distance, normalX, normalY, normalZ, subShapeIndex, hitShapeId, isLast)
	if hitNode ~= nil and hitNode ~= 0 then
		for _, v48_ in pairs(self.targetedMasks) do
			self:tryAddTargetWithMask(hitNode, x, y, z, v48_, distance)
		end
	end
end

-- Local values: existingClosestTarget, i, filterFunction, target
function PlayerTargeter:tryAddTargetWithMask(hitNode, x, y, z, targetedMask, distance)
	if targetedMask.maxDistance < distance or (distance < targetedMask.minDistance or not CollisionFlag.getHasGroupFlagSet(hitNode, targetedMask.mask)) then
		return
	else
		local v56_ = self.currentTargetsByKey[targetedMask.key]
		if v56_ == nil or v56_.distance >= distance then
			for _, v57_ in ipairs(targetedMask.filterFunctions) do
				if not v57_(hitNode, x, y, z) then
					return
				end
			end
			local v58_ = self.pooledTargets:getOrCreateNext()
			v58_.x = x
			v58_.y = y
			v58_.z = z
			v58_.node = hitNode
			v58_.distance = distance
			self.currentTargetsByKey[targetedMask.key] = v58_
		end
	end
end

-- Local values: combinedMaskName, key, targetedMask, maskNode, nodeName, maskName
function PlayerTargeter:debugDraw(x, y, textSize)
	local v63_ = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Targeter", nil, true)
	local v64_ = CollisionFlag.getFlagsStringFromMask(self.combinedTargetMask)
	local v65_ = DebugUtil.renderTextLine(x, v63_, textSize, string.format("Combined mask: %q", v64_), nil, true)
	local v66_ = DebugUtil.renderTextLine(x, v65_, textSize, "Masks:", nil, true)
	for v67_, v68_ in pairs(self.targetedMasks) do
		local v69_ = self:getClosestTargetedNodeFromType(v67_)
		local v70_ = (v69_ == nil or not entityExists(v69_)) and "none" or (getName(v69_) or "none")
		local v71_ = CollisionFlag.getFlagsStringFromMask(v68_.mask)
		v66_ = DebugUtil.renderTextLine(x, v66_, textSize, string.format("Mask %q: %q", v71_, v70_))
	end
	return v66_
end
