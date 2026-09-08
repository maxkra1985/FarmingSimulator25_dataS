-- Local values: DebugElement_mt
DebugElement = {}
local DebugElement_mt = Class(DebugElement)

-- Upvalues: DebugElement_mt
-- Local values: self
function DebugElement.new(customMt)
	-- upvalues: (copy) DebugElement_mt
	local v3_ = customMt or DebugElement_mt
	local v4_ = setmetatable({}, v3_)
	v4_.x = 0
	v4_.y = 0
	v4_.z = 0
	v4_.color = Color.new(1, 1, 1, 1)
	v4_.text = nil
	v4_.textSize = nil
	v4_.textColor = nil
	v4_.textClipDistance = nil
	v4_.isVisible = true
	v4_.clipDistance = nil
	v4_.hideWhenGuiIsOpen = true
	return v4_
end

-- Local values: x, y, z
function DebugElement:getShouldBeDrawn()
	if self.isVisible then
		if self.hideWhenGuiIsOpen and (g_gui ~= nil and (g_gui:getIsGuiVisible() and g_gui.currentGuiName ~= "ConstructionScreen")) then
			return false
		end
		if self.clipDistance ~= nil then
			local v6_, v7_, v8_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			if MathUtil.vector3Length(v6_ - self.x, v7_ - self.y, v8_ - self.z) > self.clipDistance then
				return false
			end
		end
		return true
	end
end

function DebugElement:draw() end

function DebugElement:addToManager(groupId, lifetime, maxCount)
	g_debugManager:addElement(self, groupId, lifetime, maxCount)
	return self
end

function DebugElement:setColorRGBA(r, g, b, a)
	self.color = Color.new(r, g, b, a)
	return self
end

function DebugElement:setColor(color)
	if color ~= nil and (color.isa ~= nil and color:isa(Color)) then
		self.color = color
		return self
	end
	Logging.error("DebugElement:setColor called with argument not being a \'Color\' object")
	printCallstack()
	return self
end

function DebugElement:setText(text)
	self.text = text and tostring(text) or nil
	return self
end

function DebugElement:setTextSize(textSize)
	self.textSize = textSize
	return self
end

function DebugElement:setTextColor(color)
	if color ~= nil and (color.isa ~= nil and color:isa(Color)) then
		self.textColor = color
		return self
	end
	Logging.error("DebugElement:setTextColor called with argument not being a \'Color\' object")
	printCallstack()
	return self
end

function DebugElement:setTextClipDistance(textClipDistance)
	self.textClipDistance = textClipDistance
	return self
end

function DebugElement:setIsVisible(isVisible)
	self.isVisible = isVisible
	return self
end

function DebugElement:setVisbileWhenGUIOpen(isVisible)
	self.hideWhenGuiIsOpen = not isVisible
	return self
end

function DebugElement:setClipDistance(clipDistance)
	self.clipDistance = clipDistance
	return self
end

function DebugElement:setIsSolid(isSolid)
	self.solid = isSolid
	return self
end
