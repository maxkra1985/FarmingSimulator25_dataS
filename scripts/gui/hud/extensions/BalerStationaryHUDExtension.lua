-- Local values: BalerStationaryHUDExtension_mt
BalerStationaryHUDExtension = {}
local BalerStationaryHUDExtension_mt = Class(BalerStationaryHUDExtension)

-- Upvalues: BalerStationaryHUDExtension_mt
-- Local values: self, r, g, b, a
function BalerStationaryHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) BalerStationaryHUDExtension_mt
	local v4_ = customMt or BalerStationaryHUDExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.priority = GS_PRIO_HIGH
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.backgroundTop = g_overlayManager:createOverlay("gui.hudExtension_top", 0, 0, 0, 0)
	v5_.backgroundTop:setColor(v7_, v8_, v9_, v10_)
	v5_.backgroundScale = g_overlayManager:createOverlay("gui.hudExtension_middle", 0, 0, 0, 0)
	v5_.backgroundScale:setColor(v7_, v8_, v9_, v10_)
	v5_.backgroundBottom = g_overlayManager:createOverlay("gui.hudExtension_bottom", 0, 0, 0, 0)
	v5_.backgroundBottom:setColor(v7_, v8_, v9_, v10_)
	v5_.vehicleIcon = g_overlayManager:createOverlay("gui.icon_goeweil", 0, 0, 0, 0)
	v5_.baleIcon = g_overlayManager:createOverlay("gui.icon_goeweil_bale", 0, 0, 0, 0)
	v5_.grassIcon = g_overlayManager:createOverlay("gui.icon_goeweil_grass", 0, 0, 0, 0)
	v5_.wrappedBaleIcon = g_overlayManager:createOverlay("gui.icon_goeweil_wrappedBale", 0, 0, 0, 0)
	v5_.vehicle = vehicle
	v5_.baler = vehicle.spec_baler
	v5_.baleWrapper = vehicle.spec_baleWrapper
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

function BalerStationaryHUDExtension:delete()
	self.backgroundTop:delete()
	self.backgroundScale:delete()
	self.backgroundBottom:delete()
	self.vehicleIcon:delete()
	self.baleIcon:delete()
	self.grassIcon:delete()
	self.wrappedBaleIcon:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height
function BalerStationaryHUDExtension:storeScaledValues()
	local v13_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local _, v14_ = getNormalizedScreenValues(0, 115 * v13_)
	self.totalHeight = v14_
	local v15_, v16_ = getNormalizedScreenValues(330 * v13_, 6 * v13_)
	self.backgroundTop:setDimension(v15_, v16_)
	self.backgroundBottom:setDimension(v15_, v16_)
	self.backgroundScale:setDimension(v15_, self.totalHeight - 2 * v16_)
	local v17_, v18_ = getNormalizedScreenValues(250 * v13_, 95 * v13_)
	self.vehicleIcon:setDimension(v17_, v18_)
	local v19_, v20_ = getNormalizedScreenValues(38 * v13_, 38 * v13_)
	local v21_ = self.baleIcon
	local v22_ = self.baleIcon
	v21_.defaultWidth = v19_
	v22_.defaultHeight = v20_
	self.baleIcon:setDimension(v19_, v20_)
	local v23_, v24_ = getNormalizedScreenValues(55 * v13_, 30 * v13_)
	local v25_ = self.grassIcon
	local v26_ = self.grassIcon
	v25_.defaultWidth = v23_
	v26_.defaultHeight = v24_
	self.grassIcon:setDimension(v23_, v24_)
	local v27_, v28_ = getNormalizedScreenValues(38 * v13_, 38 * v13_)
	self.wrappedBaleIcon:setDimension(v27_, v28_)
	local v29_, v30_ = getNormalizedScreenValues(26 * v13_, 10 * v13_)
	self.vehicleIconOffsetX = v29_
	self.vehicleIconOffsetY = v30_
	local v31_, v32_ = getNormalizedScreenValues(44 * v13_, 45 * v13_)
	self.wrappedBaleIconOffsetX = v31_
	self.wrappedBaleIconOffsetY = v32_
	local v33_, v34_ = getNormalizedScreenValues(133 * v13_, 69 * v13_)
	self.baleIconOffsetX = v33_
	self.baleIconOffsetY = v34_
	local v35_, v36_ = getNormalizedScreenValues(232 * v13_, 50 * v13_)
	self.grassIconOffsetX = v35_
	self.grassIconOffsetY = v36_
	local _, v37_ = getNormalizedScreenValues(0, 12 * v13_)
	self.textSize = v37_
	local v38_, v39_ = getNormalizedScreenValues(133 * v13_, 100 * v13_)
	self.baleTextOffsetX = v38_
	self.baleTextOffsetY = v39_
	local v40_, v41_ = getNormalizedScreenValues(238 * v13_, 75 * v13_)
	self.bunkerTextOffsetX = v40_
	self.bunkerTextOffsetY = v41_
end

-- Local values: hasBaleOnWrapper, wrapTime, balerBunkerFillLevel, balerBunkerCapacity, balerMainFillLevel, balerMainCapacity, grassFillScale, baleScale, baleRotation
function BalerStationaryHUDExtension:draw(inputHelpDisplay, posX, posY)
	local v45_
	if self.baleWrapper.baleWrapperState > 0 then
		v45_ = self.baleWrapper.baleWrapperState < BaleWrapper.STATE_WRAPPER_DROPPING_BALE
	else
		v45_ = false
	end
	local v46_ = self.baleWrapper.currentWrapper.currentTime / self.baleWrapper.currentWrapper.animTime
	local v47_ = self.vehicle:getFillUnitFillLevel(self.baler.buffer.fillUnitIndex)
	local v48_ = self.vehicle:getFillUnitCapacity(self.baler.buffer.fillUnitIndex)
	local v49_ = self.vehicle:getFillUnitFillLevel(self.baler.fillUnitIndex)
	local v50_ = self.vehicle:getFillUnitCapacity(self.baler.fillUnitIndex)
	self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
	self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
	self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
	self.backgroundTop:render()
	self.backgroundScale:render()
	self.backgroundBottom:render()
	local v51_ = self.backgroundBottom.y
	self.vehicleIcon:setPosition(posX + self.vehicleIconOffsetX, v51_ + self.vehicleIconOffsetY)
	self.vehicleIcon:render()
	if v47_ > 0 then
		local v52_ = v47_ / v48_ * 0.3 + 0.7
		self.grassIcon:setScale(v52_, v52_)
		self.grassIcon:setPosition(posX + self.grassIconOffsetX - self.grassIcon.width * 0.5, v51_ + self.grassIconOffsetY - self.grassIcon.height * 0.5)
		self.grassIcon:render()
	end
	if v49_ > 0 then
		local v53_ = v49_ / v50_ * 0.5 + 0.5
		local v54_ = v49_ / v50_ * 5
		self.baleIcon:setScale(v53_, v53_)
		self.baleIcon:setRotation(-(v54_ * 3.141592653589793 * 2), self.baleIcon.width * 0.5, self.baleIcon.height * 0.5)
		self.baleIcon:setPosition(posX + self.baleIconOffsetX - self.baleIcon.width * 0.5, v51_ + self.baleIconOffsetY - self.baleIcon.height * 0.5)
		self.baleIcon:render()
	end
	if v45_ then
		self.wrappedBaleIcon:setPosition(posX + self.wrappedBaleIconOffsetX, v51_ + self.wrappedBaleIconOffsetY)
		self.wrappedBaleIcon:setRotation(-(v46_ * 3.141592653589793 * 2), self.wrappedBaleIcon.width * 0.5, self.wrappedBaleIcon.height * 0.5)
		self.wrappedBaleIcon:render()
	end
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderText(posX + self.bunkerTextOffsetX, v51_ + self.bunkerTextOffsetY, self.textSize, string.format("%dl", MathUtil.round(v47_)))
	renderText(posX + self.baleTextOffsetX, v51_ + self.baleTextOffsetY, self.textSize, string.format("%dl", MathUtil.round(v49_)))
	setTextAlignment(RenderText.ALIGN_LEFT)
	return self.backgroundBottom.y
end

function BalerStationaryHUDExtension:getHeight()
	return self.totalHeight
end
