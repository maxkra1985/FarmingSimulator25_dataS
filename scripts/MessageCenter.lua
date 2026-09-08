-- Local values: MessageCenter_mt, noOp
MessageCenter = {}
local MessageCenter_mt = Class(MessageCenter)
source("dataS/scripts/MessageType.lua")

-- Upvalues: MessageCenter_mt
-- Local values: self
function MessageCenter.new(self)
	-- upvalues: (copy) MessageCenter_mt
	local v2_ = MessageCenter_mt
	local v3_ = setmetatable({}, v2_)
	v3_.subscribers = {}
	v3_.queue = {}
	return v3_
end

function MessageCenter.delete(self) end

-- Local values: index, message
function MessageCenter:update(dt)
	if #self.queue > 0 then
		local v5_ = 1
		while true do
			local v6_ = self.queue[v5_]
			if v6_ == nil then
				break
			end
			if v6_.targetUpdateLoopIndex == nil or g_updateLoopIndex >= v6_.targetUpdateLoopIndex then
				local v7_ = v6_.messageType
				local v8_ = v6_.arguments
				self:publish(v7_, unpack(v8_))
				table.remove(self.queue, v5_)
			else
				v5_ = v5_ + 1
			end
		end
	end
end

-- Local values: subscribers
function MessageCenter:subscribe(messageType, callback, callbackTarget, argument, isOneShot)
	if messageType == nil then
		Logging.warning("Tried subscribing to a message with a nil-value message type. Check subscribe() function call arguments at:")
		printCallstack()
		return
	elseif callback == nil then
		Logging.warning("Tried subscribing to a message with a nil-value callback. Check subscribe() function call arguments at:")
		printCallstack()
	else
		assertWithCallstack(type(callback) == "function", "Error: MessageCenter:subscribe(): given argument \'callback\' is not a function")
		local v15_ = self.subscribers[messageType]
		if v15_ == nil then
			v15_ = {}
			self.subscribers[messageType] = v15_
		end
		local v16_ = {
			["callback"] = callback,
			["callbackTarget"] = callbackTarget,
			["argument"] = argument,
			["isOneShot"] = Utils.getNoNil(isOneShot, false)
		}
		table.insert(v15_, v16_)
	end
end

function MessageCenter:subscribeOneshot(messageType, callback, callbackTarget, argument)
	self:subscribe(messageType, callback, callbackTarget, argument, true)
end

-- Local values: subscribers, i, info
function MessageCenter:unsubscribe(messageType, callbackTarget, callback)
	local v26_ = self.subscribers[messageType]
	if v26_ ~= nil then
		for v27_ = #v26_, 1, -1 do
			local v28_ = v26_[v27_]
			if v28_.callbackTarget == callbackTarget and (callback == nil or v28_.callback == callback) then
				table.remove(v26_, v27_)
			end
		end
		if #v26_ == 0 then
			self.subscribers[messageType] = nil
		end
	end
end

-- Local values: k, subscribers, i, info
function MessageCenter:unsubscribeAll(callbackTarget)
	for v31_, v32_ in pairs(self.subscribers) do
		for v33_ = #v32_, 1, -1 do
			if v32_[v33_].callbackTarget == callbackTarget then
				table.remove(v32_, v33_)
			end
		end
		if #v32_ == 0 then
			self.subscribers[v31_] = nil
		end
	end
end
function MessageCenter.publish(p34_, p35_, ...)
	if p35_ == nil then
		Logging.warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
		printCallstack()
	else
		local v36_ = p34_.subscribers[p35_]
		if v36_ ~= nil then
			local v37_ = 1
			while true do
				local v38_ = v36_[v37_]
				if v38_ == nil then
					break
				end
				if v38_.callbackTarget == nil then
					if v38_.argument == nil then
						v38_.callback(...)
					else
						v38_.callback(v38_.argument, ...)
					end
				elseif v38_.argument == nil then
					v38_.callback(v38_.callbackTarget, ...)
				else
					v38_.callback(v38_.callbackTarget, v38_.argument, ...)
				end
				if v38_.isOneShot then
					table.remove(v36_, v37_)
				else
					v37_ = v37_ + 1
				end
			end
		end
	end
end
function MessageCenter.publishDelayed(p39_, p40_, ...)
	if p40_ == nil then
		Logging.warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
		printCallstack()
	else
		p39_:publishDelayedAfterFrames(p40_, 1, ...)
	end
end
function MessageCenter.publishDelayedAfterFrames(p41_, p42_, p43_, ...)
	if p42_ == nil then
		Logging.warning("Tried publishing a message with a nil-value message type. Check publish() function call arguments at:")
		printCallstack()
	else
		local v44_ = {
			["messageType"] = p42_,
			["targetUpdateLoopIndex"] = g_updateLoopIndex + p43_,
			["arguments"] = { ... }
		}
		local v45_ = p41_.queue
		table.insert(v45_, v44_)
	end
end

-- Local values: messageName, time, sorted, size, i, messageName, yOffset
function MessageCenter:drawDebug()
	for v47_, v48_ in pairs(self.debugLastMessages) do
		if v48_ + 5000 < g_time then
			self.debugLastMessages[v47_] = nil
		end
	end
	local v49_ = table.toList(self.debugLastMessages)
	table.sort(v49_, function(p50_, p51_)
		-- upvalues: (copy) self
		return self.debugLastMessages[p50_] > self.debugLastMessages[p51_]
	end)
	setTextBold(true)
	renderText(0.5, 0.8, 0.016, "recently published messages:")
	setTextBold(false)
	for v52_, v53_ in ipairs(v49_) do
		local v54_ = 0.8 - v52_ * 0.016
		renderText(0.45, v54_, 0.016, v53_)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.44, v54_, 0.016, string.format("%d", g_time - self.debugLastMessages[v53_]))
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

-- Local values: messageCount, subscriberCount, messageType, subscribers, messageName, k, v, k, v, name, setting, _, subscriber, target
function MessageCenter:consoleCommandPrintActiveSubscribers()
	local v56_ = 0
	local v57_ = 0
	for v58_, v59_ in pairs(self.subscribers) do
		local v60_ = nil
		if type(v58_) == "number" then
			for v61_, v62_ in pairs(MessageType) do
				if v62_ == v58_ then
					v60_ = v61_
					break
				end
			end
			if v60_ == nil then
				for v63_, v64_ in pairs(MessageType.SETTING_CHANGED) do
					if v64_ == v58_ then
						for v65_, v66_ in pairs(GameSettings.SETTING) do
							if v63_ == v66_ then
								v60_ = v65_
								break
							end
						end
						break
					end
				end
			end
		else
			v60_ = ClassUtil.getClassName(v58_)
		end
		if v60_ == nil then
			v60_ = type(v58_) .. " " .. tostring(v58_)
		end
		log("Message Subscribers for \'" .. v60_ .. "\':")
		for _, v67_ in ipairs(v59_) do
			local v68_ = v67_.callbackTarget
			if v68_ ~= nil then
				v68_ = ClassUtil.getClassNameByObject(v68_)
			end
			log("    ", v68_ or (v67_.callback or "Unknown"))
			v56_ = v56_ + 1
		end
		v57_ = v57_ + 1
	end
	log("\n Total Messages:" .. v57_)
	log("Total Subscribers: " .. v56_)
end

function MessageCenter:consoleCommandDrawMessages()
	self.debugDrawLastMessages = not self.debugDrawLastMessages
	if self.debugDrawLastMessages then
		self.debugLastMessages = {}
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
		self.debugLastMessages = nil
	end
	return string.format("drawLastMessages=%s", self.debugDrawLastMessages)
end
