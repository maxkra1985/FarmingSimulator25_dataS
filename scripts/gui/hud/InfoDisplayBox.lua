-- Local values: InfoDisplayBox_mt
InfoDisplayBox = {}
local InfoDisplayBox_mt = Class(InfoDisplayBox)

-- Upvalues: InfoDisplayBox_mt
-- Local values: self
function InfoDisplayBox.new(infoDisplay, uiScale, customMt)
	-- upvalues: (copy) InfoDisplayBox_mt
	local v5_ = customMt or InfoDisplayBox_mt
	local v6_ = setmetatable({}, v5_)
	v6_.infoDisplay = infoDisplay
	v6_.uiScale = uiScale
	return v6_
end

function InfoDisplayBox:delete() end

function InfoDisplayBox:setScale(uiScale)
	self.uiScale = uiScale
	self:storeScaledValues()
end

function InfoDisplayBox:storeScaledValues() end

function InfoDisplayBox:canDraw()
	return true
end

function InfoDisplayBox:draw(posX, posY)
	return posX, posY
end
