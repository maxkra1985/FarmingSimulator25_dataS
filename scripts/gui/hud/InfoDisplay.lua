InfoDisplay = {}
local InfoDisplay_mt = Class(InfoDisplay, HUDDisplay)
function InfoDisplay.new()
	local self = InfoDisplay:superClass().new(InfoDisplay_mt)
	self.isEnabled = true
	self.boxMarginY = 0
	self.totalHeight = 0
	self.boxes = {}
	return self
end
function InfoDisplay:setScale(uiScale)
	InfoDisplay:superClass().setScale(self, uiScale)
	for _, box in ipairs(self.boxes) do
		box:setScale(uiScale)
	end
end
function InfoDisplay:storeScaledValues()
	self:setPosition(g_hudAnchorRight, g_hudAnchorBottom)
	self.boxMarginY = self:scalePixelToScreenHeight(5)
end
function InfoDisplay:draw()
	self.totalHeight = 0
	if not self.isEnabled then
		return
	else
		InfoDisplay:superClass().draw(self)
		local posX, posY = self:getPosition()
		local startPosY = posY
		for i = #self.boxes, 1, -1 do
			local box = self.boxes[i]
			if box:canDraw() then
				posX, posY = box:draw(posX, posY)
				posY = posY + self.boxMarginY
			end
		end
		self.totalHeight = posY - startPosY
	end
end
function InfoDisplay:setEnabled(isEnabled)
	self.isEnabled = isEnabled
end
function InfoDisplay:createBox(class)
	local box = class.new(self, self.uiScale)
	box:setScale(self.uiScale)
	table.addElement(self.boxes, box)
	return box
end
function InfoDisplay:destroyBox(box)
	table.removeElement(self.boxes, box)
	box:delete()
end
function InfoDisplay:getDisplayHeight()
	if self.isEnabled then
		return self.totalHeight
	else
		return 0
	end
end
