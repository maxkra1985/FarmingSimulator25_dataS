-- Local values: BasketTrigger_mt
BasketTrigger = {}
BasketTrigger.threePointDistanceThreshold = 6
local BasketTrigger_mt = Class(BasketTrigger)

-- Local values: trigger
function BasketTrigger:onCreate(id)
	local v3_ = BasketTrigger.new()
	if v3_:load(id) then
		g_currentMission:addNonUpdateable(v3_)
	else
		v3_:delete()
	end
end

-- Upvalues: BasketTrigger_mt
-- Local values: self
function BasketTrigger.new(customMt)
	-- upvalues: (copy) BasketTrigger_mt
	local v5_ = customMt or BasketTrigger_mt
	local v6_ = setmetatable({}, v5_)
	v6_.triggerId = 0
	v6_.nodeId = 0
	return v6_
end

function BasketTrigger:load(nodeId)
	self.nodeId = nodeId
	self.triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "triggerIndex"))
	if self.triggerId == nil then
		self.triggerId = nodeId
	end
	addTrigger(self.triggerId, "triggerCallback", self)
	self.triggerObjects = {}
	self.isEnabled = true
	return true
end

function BasketTrigger:delete()
	removeTrigger(self.triggerId)
end

-- Local values: object
function BasketTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isEnabled then
		if onEnter then
			if g_currentMission:getNodeObject(otherActorId).thrownFromPosition ~= nil then
				self.triggerObjects[otherActorId] = true
				return
			end
		elseif onLeave and self.triggerObjects[otherActorId] then
			self.triggerObjects[otherActorId] = false
		end
	end
end
