-- Local values: InfoDisplay_mt
InfoDisplay = {}
local InfoDisplay_mt = Class(InfoDisplay, HUDDisplay)
function InfoDisplay.new()
	-- upvalues: (copy) InfoDisplay_mt
	local v2_ = InfoDisplay:superClass().new(InfoDisplay_mt)
	v2_.isEnabled = true
	v2_.boxMarginY = 0
	v2_.totalHeight = 0
	v2_.boxes = {}
	return v2_
end

-- Local values: _, box
function InfoDisplay:setScale(uiScale)
	InfoDisplay:superClass().setScale(self, uiScale)
	for _, v5_ in ipairs(self.boxes) do
		v5_:setScale(uiScale)
	end
end

function InfoDisplay:storeScaledValues()
	self:setPosition(g_hudAnchorRight, g_hudAnchorBottom)
	self.boxMarginY = self:scalePixelToScreenHeight(5)
end

-- Local values: posX, posY, startPosY, i, box
function InfoDisplay:draw()
	self.totalHeight = 0
	if self.isEnabled then
		InfoDisplay:superClass().draw(self)
		local v8_, v9_ = self:getPosition()
		local v10_ = v9_
		for v11_ = #self.boxes, 1, -1 do
			local v12_ = self.boxes[v11_]
			if v12_:canDraw() then
				local v13_
				v8_, v13_ = v12_:draw(v8_, v9_)
				v9_ = v13_ + self.boxMarginY
			end
		end
		self.totalHeight = v9_ - v10_
	end
end

function InfoDisplay:setEnabled(isEnabled)
	self.isEnabled = isEnabled
end

-- Local values: box
function InfoDisplay:createBox(class)
	local v18_ = class.new(self, self.uiScale)
	v18_:setScale(self.uiScale)
	table.addElement(self.boxes, v18_)
	return v18_
end

function InfoDisplay:destroyBox(box)
	table.removeElement(self.boxes, box)
	box:delete()
end

function InfoDisplay:getDisplayHeight()
	return not self.isEnabled and 0 or self.totalHeight
end
