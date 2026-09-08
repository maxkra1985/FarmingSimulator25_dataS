-- Local values: data, old, POIInfoDisplay_mt, poiInfoDisplay, k, elem
local v1_
if POIInfoDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.poiInfoDisplay
	v1_ = {
		["text"] = v2_.text,
		["uiScale"] = v2_.uiScale
	}
	v2_:delete()
end
POIInfoDisplay = {}
local data = Class(POIInfoDisplay, HUDDisplayElement)
function POIInfoDisplay.new()
	-- upvalues: (copy) data
	local v4_ = POIInfoDisplay.createBackground()
	local v5_ = POIInfoDisplay:superClass().new(v4_, nil, data)
	v5_.text = ""
	local v6_ = POIInfoDisplay.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.r = v7_
	v5_.g = v8_
	v5_.b = v9_
	v5_.a = v10_
	v5_:applyValues(1)
	local v11_, v12_ = v5_:getPosition()
	local v13_ = g_overlayManager:createOverlay(POIInfoDisplay.SLICE_IDS.ICON, v11_ + v5_.iconOffsetX, v12_ + v5_.iconOffsetY, v5_.iconSizeX, v5_.iconSizeY)
	v13_:setColor(1, 1, 1, 1)
	v5_:addChild(HUDElement.new(v13_))
	return v5_
end

function POIInfoDisplay:setText(text)
	self.text = text
end

-- Local values: posX, posY, height, width
function POIInfoDisplay:draw()
	if self.text ~= "" then
		local v17_, v18_ = self:getPosition()
		local v19_ = self:getHeight()
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		local v20_ = getTextWidth(self.textSize, self.text) + self.offsetLeft + self.offsetRight
		drawFilledRectRound(v17_, v18_, v20_, v19_, self.uiScale, self.r, self.g, self.b, self.a)
		renderText(v17_ + self.offsetLeft, v18_ + self.offsetBottom, self.textSize, self.text)
		POIInfoDisplay:superClass().draw(self)
	end
end

-- Local values: posX, posY
function POIInfoDisplay:setScale(uiScale)
	POIInfoDisplay:superClass().setScale(self, uiScale, uiScale)
	self.uiScale = uiScale
	local v23_, v24_ = POIInfoDisplay.getBackgroundPosition(uiScale)
	self:setPosition(v23_, v24_)
	self:applyValues(uiScale)
end

-- Local values: offsetLeft, _, offsetRight, _, _, offsetBottom, _, textSize, iconSizeX, iconSizeY, iconOffsetX, iconOffsetY
function POIInfoDisplay:applyValues(uiScale)
	local v27_, _ = getNormalizedScreenValues(POIInfoDisplay.POSITION.OFFSET_LEFT, 0)
	self.offsetLeft = v27_ * uiScale
	local v28_, _ = getNormalizedScreenValues(POIInfoDisplay.POSITION.OFFSET_RIGHT, 0)
	self.offsetRight = v28_ * uiScale
	local _, v29_ = getNormalizedScreenValues(0, POIInfoDisplay.POSITION.OFFSET_BOTTOM)
	self.offsetBottom = v29_ * uiScale
	local _, v30_ = getNormalizedScreenValues(0, POIInfoDisplay.SIZE.TEXT)
	self.textSize = v30_ * uiScale
	local v31_ = getNormalizedScreenValues
	local v32_ = POIInfoDisplay.SIZE.ICON
	local v33_, v34_ = v31_(unpack(v32_))
	self.iconSizeX = v33_ * uiScale
	self.iconSizeY = v34_ * uiScale
	local v35_ = getNormalizedScreenValues
	local v36_ = POIInfoDisplay.POSITION.ICON_OFFSET
	local v37_, v38_ = v35_(unpack(v36_))
	self.iconOffsetX = v37_ * uiScale
	self.iconOffsetY = v38_ * uiScale
end

-- Local values: _, height, offsetX, offsetY, posX, posY
function POIInfoDisplay.getBackgroundPosition(uiScale)
	local v40_ = getNormalizedScreenValues
	local v41_ = POIInfoDisplay.SIZE.SELF
	local _, v42_ = v40_(unpack(v41_))
	local v43_ = getNormalizedScreenValues
	local v44_ = POIInfoDisplay.POSITION.SELF
	local v45_, v46_ = v43_(unpack(v44_))
	return v45_ * uiScale, 1 + v46_ * uiScale - v42_ * uiScale
end
function POIInfoDisplay.createBackground()
	local v47_, v48_ = POIInfoDisplay.getBackgroundPosition(1)
	local v49_ = getNormalizedScreenValues
	local v50_ = POIInfoDisplay.SIZE.SELF
	local v51_, v52_ = v49_(unpack(v50_))
	return Overlay.new(nil, v47_, v48_, v51_, v52_)
end
POIInfoDisplay.SIZE = {
	["SELF"] = { 340, 46 },
	["BOX_MARGIN"] = 20,
	["TEXT"] = 32,
	["ICON"] = { 40, 40 }
}
POIInfoDisplay.POSITION = {
	["ICON_OFFSET"] = { 15, 3 },
	["SELF"] = { 33, -127 },
	["OFFSET_LEFT"] = 61,
	["OFFSET_RIGHT"] = 20,
	["OFFSET_BOTTOM"] = 13
}
POIInfoDisplay.COLOR = {
	["BACKGROUND"] = {
		0,
		0,
		0,
		0.4
	}
}
POIInfoDisplay.SLICE_IDS = {
	["ICON"] = "gui.exclamationCircle"
}
if v1_ ~= nil then
	local v53_ = POIInfoDisplay.new()
	v53_:setScale(v1_.uiScale)
	v53_:setText(v1_.text)
	for v54_, v55_ in ipairs(g_currentMission.hud.displayComponents) do
		if v55_ == g_currentMission.hud.poiInfoDisplay then
			g_currentMission.hud.displayComponents[v54_] = v53_
			break
		end
	end
	g_currentMission.hud.poiInfoDisplay = v53_
	Logging.info("Reloaded")
end
