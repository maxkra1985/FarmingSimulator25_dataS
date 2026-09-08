-- Local values: AnimatedObjectActivatable_mt
AnimatedObjectActivatable = {}
local AnimatedObjectActivatable_mt = Class(AnimatedObjectActivatable)

-- Upvalues: AnimatedObjectActivatable_mt
-- Local values: self
function AnimatedObjectActivatable.new(animatedObject)
	-- upvalues: (copy) AnimatedObjectActivatable_mt
	local v3_ = AnimatedObjectActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.animatedObject = animatedObject
	v4_.activateText = ""
	return v4_
end

-- Local values: controls, _
function AnimatedObjectActivatable:registerCustomInput(inputContext)
	local v6_ = self.animatedObject.controls
	if v6_.posAction then
		if v6_.negAction then
			if v6_.posAction == v6_.negAction then
				local _, v7_ = g_inputBinding:registerActionEvent(v6_.posAction, self, self.onAnimationInputContinuous, false, false, true, true)
				v6_.posActionEventId = v7_
			else
				local _, v8_ = g_inputBinding:registerActionEvent(v6_.posAction, self, self.onAnimationInputContinuous, false, false, true, true)
				v6_.posActionEventId = v8_
				local _, v9_ = g_inputBinding:registerActionEvent(v6_.negAction, self, self.onAnimationInputContinuous, false, false, true, true)
				v6_.negActionEventId = v9_
			end
		else
			local _, v10_ = g_inputBinding:registerActionEvent(v6_.posAction, self, self.onAnimationInputToggle, false, true, false, true)
			v6_.posActionEventId = v10_
		end
	end
	if v6_.posActionEventId then
		g_inputBinding:setActionEventTextPriority(v6_.posActionEventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventTextVisibility(v6_.posActionEventId, true)
		if v6_.posActionText then
			g_inputBinding:setActionEventText(v6_.posActionEventId, v6_.posActionText)
		end
	end
	if v6_.negActionEventId then
		g_inputBinding:setActionEventTextPriority(v6_.negActionEventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventTextVisibility(v6_.negActionEventId, true)
		if v6_.negActionText then
			g_inputBinding:setActionEventText(v6_.negActionEventId, v6_.negActionText)
		end
	end
	self:updateActionEventTexts()
end

-- Local values: controls
function AnimatedObjectActivatable:removeCustomInput(inputContext)
	g_inputBinding:removeActionEventsByTarget(self)
	local v12_ = self.animatedObject.controls
	v12_.posActionEventId = nil
	v12_.negActionEventId = nil
end

-- Local values: changed, animation, controls, direction
function AnimatedObjectActivatable:onAnimationInputContinuous(actionName, inputValue)
	local v16_ = false
	local v17_ = self.animatedObject.animation
	local v18_ = self.animatedObject.controls
	local v19_ = 0
	if inputValue == 0 then
		if v17_.direction ~= 0 and v18_.wasPressed then
			v16_ = true
			v19_ = 0
		end
	elseif actionName == v18_.posAction and inputValue > 0 then
		v18_.wasPressed = true
		if v17_.direction ~= 1 and v17_.time ~= 1 then
			v16_ = true
			v19_ = 1
		end
	elseif actionName == v18_.negAction or actionName == v18_.posAction and inputValue < 0 then
		v18_.wasPressed = true
		if v17_.direction ~= -1 and v17_.time ~= 0 then
			v16_ = true
			v19_ = -1
		end
	end
	if v16_ then
		self.animatedObject:setDirection(v19_)
	end
end

-- Local values: direction
function AnimatedObjectActivatable:onAnimationInputToggle()
	local v21_ = self.animatedObject.animation.direction * -1
	self.animatedObject:setDirection(v21_)
	self:updateActionEventTexts()
end

-- Local values: controls, animation
function AnimatedObjectActivatable:updateActionEventTexts()
	local v23_ = self.animatedObject.controls
	if v23_.posAction and (not v23_.negAction and (v23_.posActionText ~= nil and v23_.negActionText ~= nil)) then
		local v24_ = self.animatedObject.animation
		if v24_.direction == 0 and v24_.time == 0 or v24_.direction < 0 then
			g_inputBinding:setActionEventText(v23_.posActionEventId, v23_.posActionText)
			return
		end
		g_inputBinding:setActionEventText(v23_.posActionEventId, v23_.negActionText)
	end
end

function AnimatedObjectActivatable:getIsActivatable()
	return self.animatedObject:getCanBeTriggered()
end

function AnimatedObjectActivatable:activate()
	g_currentMission:addDrawable(self)
end

function AnimatedObjectActivatable:deactivate()
	g_currentMission:removeDrawable(self)
end

-- Local values: tx, ty, tz
function AnimatedObjectActivatable:getDistance(x, y, z)
	if self.animatedObject.triggerNode == nil then
		return math.huge
	end
	local v32_, v33_, v34_ = getWorldTranslation(self.animatedObject.triggerNode)
	return MathUtil.vector3Length(x - v32_, y - v33_, z - v34_)
end

function AnimatedObjectActivatable:draw()
	if self.animatedObject.openingHours ~= nil and self.animatedObject.openingHours.closedText ~= nil then
		g_currentMission:addExtraPrintText(self.animatedObject.openingHours.closedText)
	end
end

function AnimatedObjectActivatable:run()
	self:onAnimationInputToggle()
end
