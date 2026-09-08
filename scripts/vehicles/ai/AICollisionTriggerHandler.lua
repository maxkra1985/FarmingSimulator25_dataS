-- Local values: AICollisionTriggerHandler_mt
AICollisionTriggerHandler = {}
local AICollisionTriggerHandler_mt = Class(AICollisionTriggerHandler)
AICollisionTriggerHandler.UPDATE_INTERVAL = 5
AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS = 1
AICollisionTriggerHandler.COLLISION_MASK = CollisionFlag.AI_BLOCKING + CollisionFlag.PLAYER + CollisionFlag.TREE + CollisionFlag.VEHICLE

-- Upvalues: AICollisionTriggerHandler_mt
-- Local values: self
function AICollisionTriggerHandler.new(customMt)
	-- upvalues: (copy) AICollisionTriggerHandler_mt
	local v3_ = customMt or AICollisionTriggerHandler_mt
	local v4_ = setmetatable({}, v3_)
	v4_.numCollidingVehicles = {}
	v4_.vehicleIgnoreList = {}
	v4_.collisionTriggerByVehicle = {}
	v4_.maxUpdateIndex = 1
	v4_.hasStaticCollision = false
	v4_.isBlocked = false
	v4_.dynamicHitPointDistance = math.huge
	v4_.staticHitPointDistance = math.huge
	return v4_
end

-- Local values: vehicles, i, subVehicle, index, v, trigger, i
function AICollisionTriggerHandler:init(vehicle, strategy)
	self.vehicle = vehicle
	self.strategy = strategy
	if vehicle.isServer then
		self.collisionTriggerByVehicle = {}
		self.rootVehicle = vehicle.rootVehicle
		local v8_ = self.rootVehicle.childVehicles
		for v9_ = 1, #v8_ do
			local v10_ = v8_[v9_]
			if v10_.getAICollisionTriggers ~= nil then
				v10_:getAICollisionTriggers(self.collisionTriggerByVehicle)
			end
			if v10_.getAIImplementCollisionTriggers ~= nil then
				v10_:getAIImplementCollisionTriggers(self.collisionTriggerByVehicle)
			end
		end
		local v11_ = 1
		for v12_, v13_ in pairs(self.collisionTriggerByVehicle) do
			v13_.vehicle = v12_
			v13_.updateIndex = v11_
			v13_.hasCollision = false
			v13_.hasStaticCollision = false
			v13_.isValid = true
			v13_.hitCounter = 0
			v13_.hitStaticCounter = 0
			v13_.curTriggerLength = 5
			v13_.curTriggerDirection = 1
			v13_.dynamicHitPoint = { 0, 0, 0 }
			v13_.dynamicHitPointValid = false
			v13_.dynamicHitPointDistance = math.huge
			v13_.dynamicHitPointInitialDistance = 0
			v13_.staticHitPoint = { 0, 0, 0 }
			v13_.staticHitPointValid = false
			v13_.staticHitPointDistance = math.huge
			v13_.staticHitPointInitialDistance = 0
			v13_.positions = {}
			for _ = 1, (AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS + 1) * 3 do
				local v14_ = v13_.positions
				table.insert(v14_, 0)
			end
			v11_ = v11_ + AICollisionTriggerHandler.UPDATE_INTERVAL
		end
		self.maxUpdateIndex = v11_
	end
end

-- Local values: dynamicHitPointDistance, staticHitPointDistance, currentIndex, v, trigger, x, y, z, x, y, z, dx, dy, dz, v, trigger, i, dx, dy, dz
function AICollisionTriggerHandler:update(dt, movingDirection)
	local v17_ = g_updateLoopIndex % self.maxUpdateIndex
	local v18_ = math.huge
	local v19_ = math.huge
	for v20_, v21_ in pairs(self.collisionTriggerByVehicle) do
		if v21_.dynamicHitPointValid then
			local v22_, v23_, v24_ = getWorldTranslation(v21_.node)
			local v25_ = v21_.length - MathUtil.vector3Length(v21_.dynamicHitPoint[1] - v22_, v21_.dynamicHitPoint[2] - v23_, v21_.dynamicHitPoint[3] - v24_) - v21_.dynamicHitPointInitialDistance
			v21_.dynamicHitPointDistance = math.max(v25_, 0)
		end
		if v21_.staticHitPointValid then
			local v26_, v27_, v28_ = getWorldTranslation(v21_.node)
			local v29_ = v21_.length - MathUtil.vector3Length(v21_.staticHitPoint[1] - v26_, v21_.staticHitPoint[2] - v27_, v21_.staticHitPoint[3] - v28_) - v21_.staticHitPointInitialDistance
			v21_.staticHitPointDistance = math.max(v29_, 0)
		end
		local v30_ = v21_.dynamicHitPointDistance
		v18_ = math.min(v30_, v18_)
		local v31_ = v21_.staticHitPointDistance
		v19_ = math.min(v31_, v19_)
		if v21_.updateIndex == v17_ then
			self:generateTriggerPath(v20_, v21_, movingDirection)
			if v21_.isValid then
				v21_.hitCounter = 0
				v21_.hitStaticCounter = 0
				local v32_, v33_, v34_ = localDirectionToWorld(v21_.node, 0, 0, v21_.curTriggerDirection)
				getVehicleCollisionDistance(v21_.positions, v32_, v33_, v34_, v21_.width, v21_.height, "onVehicleCollisionDistanceCallback", self, v21_, AICollisionTriggerHandler.COLLISION_MASK, true, true, true, true)
			end
		end
	end
	self.dynamicHitPointDistance = v18_
	self.staticHitPointDistance = v19_
	if self.collisionDistanceCallback ~= nil then
		local v35_ = self.collisionDistanceCallback
		local v36_ = self.dynamicHitPointDistance
		local v37_ = self.staticHitPointDistance
		v35_((math.min(v36_, v37_)))
	end
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		for v38_, v39_ in pairs(self.collisionTriggerByVehicle) do
			self:generateTriggerPath(v38_, v39_, movingDirection)
			if v39_.isValid then
				for v40_ = 1, #v39_.positions - 3, 3 do
					drawDebugLine(v39_.positions[v40_ + 0], v39_.positions[v40_ + 1] + 2, v39_.positions[v40_ + 2], 1, 0, 0, v39_.positions[v40_ + 3], v39_.positions[v40_ + 4] + 2, v39_.positions[v40_ + 5], 0, 1, 0, true)
				end
				local v41_, v42_, v43_ = localDirectionToWorld(v39_.node, 0, 0, 1)
				debugDrawVehicleCollision(v39_.positions, v41_, v42_, v43_, v39_.width, v39_.height)
			end
		end
	end
end

function AICollisionTriggerHandler:setStaticCollisionCallback(callback)
	self.staticCollisionCallback = callback
end

-- Local values: hasStaticCollision, v, trigger
function AICollisionTriggerHandler:updateStaticCollisionCallback()
	local v47_ = false
	for _, v48_ in pairs(self.collisionTriggerByVehicle) do
		if v48_.hasStaticCollision then
			v47_ = true
			break
		end
	end
	if v47_ ~= self.hasStaticCollision then
		self.hasStaticCollision = v47_
		if self.staticCollisionCallback ~= nil then
			self.staticCollisionCallback(v47_)
		end
	end
end

function AICollisionTriggerHandler:setIsBlockedCallback(callback)
	self.isBlockedCallback = callback
end

-- Local values: isBlocked, v, trigger
function AICollisionTriggerHandler:updateBlockedCallback()
	local v52_ = false
	for _, v53_ in pairs(self.collisionTriggerByVehicle) do
		if v53_.hasCollision then
			v52_ = true
			break
		end
	end
	if v52_ ~= self.isBlocked then
		self.isBlocked = v52_
		if self.isBlockedCallback ~= nil then
			self.isBlockedCallback(v52_)
		end
	end
end

function AICollisionTriggerHandler:setCollisionDistanceCallback(callback)
	self.collisionDistanceCallback = callback
end

-- Local values: node, i, x, y, z
function AICollisionTriggerHandler:generateTriggerPath(vehicle, trigger, movingDirection)
	local v58_ = movingDirection >= 0 and trigger.node or (trigger.backNode or trigger.node)
	trigger.curTriggerDirection = movingDirection < 0 and trigger.backNode ~= trigger.node and (trigger.backNodeDirection or 1) or 1
	for v59_ = 0, AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS * 3, 3 do
		local v60_, v61_, v62_ = localToWorld(v58_, 0, 0, v59_ / AICollisionTriggerHandler.TRIGGER_SUBDIVISIONS / 3 * trigger.length * trigger.curTriggerDirection)
		trigger.positions[v59_ + 1] = v60_
		trigger.positions[v59_ + 2] = getTerrainHeightAtWorldPos(g_terrainNode, v60_, v61_, v62_) + trigger.height * 0.5
		trigger.positions[v59_ + 3] = v62_
	end
	trigger.isValid = true
end

-- Local values: vehicle, _, player, vehicle, hasCollision, hasStaticCollision
function AICollisionTriggerHandler:onVehicleCollisionDistanceCallback(distance, objectId, subShapeIndex, isLast, trigger)
	if g_currentMission ~= nil and self.collisionTriggerByVehicle ~= nil then
		for v67_, _ in pairs(self.collisionTriggerByVehicle) do
			if v67_.isDeleted or v67_.isDeleting then
				return false
			end
		end
		if objectId ~= 0 then
			if g_currentMission.playerSystem:getPlayerByRootNode(objectId) == nil then
				local v68_ = g_currentMission.nodeToObject[objectId]
				if (v68_ == nil or self.collisionTriggerByVehicle[v68_] == nil) and (not getHasTrigger(objectId) and (v68_ == nil or (v68_.getRootVehicle == nil or v68_:getRootVehicle() ~= self.rootVehicle))) then
					if getRigidBodyType(objectId) == RigidBodyType.DYNAMIC then
						local v69_ = getCollisionFilterGroup(objectId)
						local v70_ = CollisionFlag.VEHICLE
						if bit32.band(v69_, v70_) ~= 0 then
							trigger.hitCounter = trigger.hitCounter + 1
						end
					else
						trigger.hitStaticCounter = trigger.hitStaticCounter + 1
					end
				end
			else
				trigger.hitCounter = trigger.hitCounter + 1
			end
		end
		if objectId ~= 0 and not isLast then
			return true
		end
		local v71_ = trigger.hitCounter > 0
		if v71_ ~= trigger.hasCollision then
			trigger.hasCollision = v71_
			if v71_ then
				trigger.dynamicHitPointValid = true
				local v72_ = trigger.dynamicHitPoint
				local v73_ = trigger.dynamicHitPoint
				local v74_ = trigger.dynamicHitPoint
				local v75_, v76_, v77_ = getWorldTranslation(trigger.node)
				v72_[1] = v75_
				v73_[2] = v76_
				v74_[3] = v77_
				trigger.dynamicHitPointInitialDistance = trigger.vehicle.lastSpeedReal * g_physicsDt * AICollisionTriggerHandler.UPDATE_INTERVAL
			else
				trigger.dynamicHitPointValid = false
				trigger.dynamicHitPointDistance = math.huge
			end
			self:updateBlockedCallback()
		end
		local v78_ = trigger.hitStaticCounter > 0
		if v78_ ~= trigger.hasStaticCollision then
			trigger.hasStaticCollision = v78_
			if v78_ then
				trigger.staticHitPointValid = true
				local v79_ = trigger.staticHitPoint
				local v80_ = trigger.staticHitPoint
				local v81_ = trigger.staticHitPoint
				local v82_, v83_, v84_ = getWorldTranslation(trigger.node)
				v79_[1] = v82_
				v80_[2] = v83_
				v81_[3] = v84_
				trigger.staticHitPointInitialDistance = trigger.vehicle.lastSpeedReal * g_physicsDt * AICollisionTriggerHandler.UPDATE_INTERVAL
			else
				trigger.staticHitPointValid = false
				trigger.staticHitPointDistance = math.huge
			end
			self:updateStaticCollisionCallback()
		end
		return false
	end
end
