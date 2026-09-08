-- Local values: VendingMachine_mt
VendingMachine = {}
local VendingMachine_mt = Class(VendingMachine)

function VendingMachine:onCreate(id)
	g_currentMission:addUpdateable(VendingMachine.new(id))
end

-- Upvalues: VendingMachine_mt
-- Local values: self
function VendingMachine.new(name)
	-- upvalues: (copy) VendingMachine_mt
	local v4_ = VendingMachine_mt
	local v5_ = setmetatable({}, v4_)
	v5_.triggerId = name
	addTrigger(name, "triggerCallback", v5_)
	v5_.isInTrigger = false
	v5_.moneyPerObject = 1
	v5_.time = 0
	v5_.emitTimer = 0
	v5_.useSound = createSample("VendingMachine")
	loadSample(v5_.useSound, "data/maps/sounds/vendingMachine.wav", false)
	v5_.isEnabled = true
	v5_.activateEventId = ""
	v5_.sharedLoadRequestId = nil
	return v5_
end

function VendingMachine:delete()
	g_currentMission:removeUpdateable(self)
	removeTrigger(self.triggerId)
	if self.useSound ~= nil then
		delete(self.useSound)
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
	self.triggerId = 0
end

-- Local values: rootNode, sharedLoadRequestId, node, dx, dy, dz
function VendingMachine:update(dt)
	self.time = self.time + dt
	if self.isInTrigger and self.emitTimer == 0 then
		g_inputBinding:setActionEventActive(self.activateEventId, true)
	end
	if self.emitTimer ~= 0 and self.emitTimer < self.time then
		self.emitTimer = 0
		local v9_, v10_ = g_i3DManager:loadSharedI3DFile("data/maps/models/objects/can/can.i3d", true, false)
		self.sharedLoadRequestId = v10_
		local v11_ = getChildAt(v9_, 0)
		link(getRootNode(), v11_)
		delete(v9_)
		setRotation(v11_, math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		setTranslation(v11_, localToWorld(self.triggerId, -0.11 + math.random() * 0.05, -0.25 + math.random() * 0.05, 0.32))
		local v12_, v13_, v14_ = localDirectionToWorld(self.triggerId, 0, 0, 0.0005 + math.random() * 0.001)
		addImpulse(v11_, v12_, v13_, v14_, 0, 0, 0, true)
	end
end

function VendingMachine:onActivate()
	playSample(self.useSound, 1, 1, 0, 0, 0)
	self.emitTimer = self.time + 1900 + math.random(0, 200)
	g_inputBinding:setActionEventActive(self.activateEventId, false)
end

-- Local values: localPlayer, _, eventId
function VendingMachine:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled then
		local v20_ = g_localPlayer
		if v20_ == nil or (v20_:getIsInVehicle() or otherId ~= v20_.rootNode) then
			return
		elseif onEnter then
			self.isInTrigger = true
			local _, v21_ = g_inputBinding:registerActionEvent(InputAction.ENTER, self, self.onActivate, false, true, false, true)
			g_inputBinding:setActionEventText(v21_, g_i18n:getText("action_activateVendingMachine"))
			self.activateEventId = v21_
		elseif onLeave then
			self.isInTrigger = false
			g_inputBinding:removeActionEventsByTarget(self)
		end
	else
		return
	end
end
