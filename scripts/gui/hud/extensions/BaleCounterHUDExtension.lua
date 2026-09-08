-- Local values: BaleCounterHUDExtension_mt
BaleCounterHUDExtension = {}
local BaleCounterHUDExtension_mt = Class(BaleCounterHUDExtension)

-- Upvalues: BaleCounterHUDExtension_mt
-- Local values: self, r, g, b, a
function BaleCounterHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) BaleCounterHUDExtension_mt
	local v4_ = customMt or BaleCounterHUDExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.priority = GS_PRIO_NORMAL
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.background = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
	v5_.background:setColor(v7_, v8_, v9_, v10_)
	v5_.sessionOverlay = g_overlayManager:createOverlay("gui.baleCount_session", 0, 0, 0, 0)
	v5_.sessionOverlay:setColor(1, 1, 1, 1)
	v5_.lifetimeOverlay = g_overlayManager:createOverlay("gui.baleCount_lifetime", 0, 0, 0, 0)
	v5_.lifetimeOverlay:setColor(1, 1, 1, 1)
	v5_.title = utf8ToUpper(g_i18n:getText("info_baleCounter"))
	v5_.vehicle = vehicle
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

function BaleCounterHUDExtension:delete()
	self.background:delete()
	self.sessionOverlay:delete()
	self.lifetimeOverlay:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height, iconWidth, iconHeight
function BaleCounterHUDExtension:storeScaledValues()
	local v13_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v14_, v15_ = getNormalizedScreenValues(330 * v13_, 25 * v13_)
	self.background:setDimension(v14_, v15_)
	local v16_, v17_ = getNormalizedScreenValues(20 * v13_, 20 * v13_)
	self.sessionOverlay:setDimension(v16_, v17_)
	self.lifetimeOverlay:setDimension(v16_, v17_)
	local v18_, v19_ = getNormalizedScreenValues(14 * v13_, 8 * v13_)
	self.textOffsetX = v18_
	self.textOffsetY = v19_
	local _, v20_ = getNormalizedScreenValues(0, 12 * v13_)
	self.textSize = v20_
	local v21_, v22_ = getNormalizedScreenValues(210 * v13_, 3 * v13_)
	self.sessionIconOffsetX = v21_
	self.sessionIconOffsetY = v22_
	local v23_, v24_ = getNormalizedScreenValues(270 * v13_, 4 * v13_)
	self.lifetimeIconOffsetX = v23_
	self.lifetimeIconOffsetY = v24_
	local v25_, v26_ = getNormalizedScreenValues(235 * v13_, 8 * v13_)
	self.sessionTextOffsetX = v25_
	self.sessionTextOffsetY = v26_
	local v27_, v28_ = getNormalizedScreenValues(295 * v13_, 8 * v13_)
	self.lifetimeTextOffsetX = v27_
	self.lifetimeTextOffsetY = v28_
end

-- Local values: titlePosX, titlePosY, spec, sessionOverlay, lifetimeOverlay
function BaleCounterHUDExtension:draw(inputHelpDisplay, posX, posY)
	local v32_ = posY - self.background.height
	self.background:setPosition(posX, v32_)
	self.background:render()
	setTextBold(true)
	setTextColor(1, 1, 1, 1)
	setTextAlignment(RenderText.ALIGN_LEFT)
	local v33_ = posX + self.textOffsetX
	local v34_ = v32_ + self.textOffsetY
	renderText(v33_, v34_, self.textSize, self.title)
	setTextBold(false)
	local v35_ = self.vehicle.spec_baleCounter
	local v36_ = self.sessionOverlay
	v36_:setPosition(posX + self.sessionIconOffsetX, v32_ + self.sessionIconOffsetY)
	v36_:render()
	renderText(posX + self.sessionTextOffsetX, v32_ + self.sessionTextOffsetY, self.textSize, string.format("%d", v35_.sessionCounter))
	local v37_ = self.lifetimeOverlay
	v37_:setPosition(posX + self.lifetimeIconOffsetX, v32_ + self.lifetimeIconOffsetY)
	v37_:render()
	renderText(posX + self.lifetimeTextOffsetX, v32_ + self.lifetimeTextOffsetY, self.textSize, string.format("%d", v35_.lifetimeCounter))
	return v32_
end

function BaleCounterHUDExtension:getHeight()
	return self.background.height
end
