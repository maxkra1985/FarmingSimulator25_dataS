-- Local values: isReloading, modName, modDir, ExtendedCombineHUDExtension_mt, renderLimitedText
local v1_ = ExtendedCombineHUDExtension ~= nil
local v2_ = g_currentModName or ExtendedCombineHUDExtension.MOD_NAME
local v3_ = g_currentModDirectory or ExtendedCombineHUDExtension.MOD_DIR
ExtendedCombineHUDExtension = {}
ExtendedCombineHUDExtension.MOD_NAME = v2_
ExtendedCombineHUDExtension.MOD_DIR = v3_
local isReloading = Class(ExtendedCombineHUDExtension)

-- Upvalues: ExtendedCombineHUDExtension_mt
-- Local values: self, r, g, b, a
function ExtendedCombineHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) isReloading
	local v7_ = customMt or isReloading
	local v8_ = setmetatable({}, v7_)
	v8_.priority = GS_PRIO_LOW
	v8_.vehicle = vehicle
	v8_.combine = vehicle.spec_combine
	v8_.extendedCombine = vehicle[ExtendedCombine.SPEC_TABLE_NAME]
	v8_.backgroundTop = g_overlayManager:createOverlay("precisionFarming.shortcutBox_top", 0, 0, 0, 0)
	v8_.backgroundMiddle = g_overlayManager:createOverlay("precisionFarming.shortcutBox_middle", 0, 0, 0, 0)
	v8_.backgroundBottom = g_overlayManager:createOverlay("precisionFarming.shortcutBox_bottom", 0, 0, 0, 0)
	local v9_ = HUD.COLOR.BACKGROUND
	local v10_, v11_, v12_, v13_ = unpack(v9_)
	v8_.backgroundTop:setColor(v10_, v11_, v12_, v13_)
	v8_.backgroundMiddle:setColor(v10_, v11_, v12_, v13_)
	v8_.backgroundBottom:setColor(v10_, v11_, v12_, v13_)
	v8_.separatorVertical = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v8_.separatorVertical:setColor(1, 1, 1, 0.25)
	v8_.yieldPercentageBar = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v8_.yieldPercentageBar:setColor(1, 1, 1, 1)
	v8_.currentYieldOverlay = g_overlayManager:createOverlay("precisionFarming.currentYield", 0, 0, 0, 0)
	v8_.currentYieldOverlay:setColor(1, 1, 1, 1)
	v8_.workAreaOverlay = g_overlayManager:createOverlay("precisionFarming.workedArea", 0, 0, 0, 0)
	v8_.workAreaOverlay:setColor(1, 1, 1, 1)
	v8_.workAreaOverlayTotal = g_overlayManager:createOverlay("precisionFarming.workedAreaTotal", 0, 0, 0, 0)
	v8_.workAreaOverlayTotal:setColor(1, 1, 1, 1)
	v8_.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], v8_.setColorBlindMode, v8_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v8_.storeScaledValues, v8_)
	v8_:storeScaledValues()
	return v8_
end

function ExtendedCombineHUDExtension:delete()
	self.backgroundTop:delete()
	self.backgroundMiddle:delete()
	self.backgroundBottom:delete()
	self.separatorVertical:delete()
	self.yieldPercentageBar:delete()
	self.currentYieldOverlay:delete()
	self.workAreaOverlay:delete()
	self.workAreaOverlayTotal:delete()
	g_messageCenter:unsubscribeAll(self)
	self.vehicle = nil
	self.combine = nil
	self.extendedCombine = nil
end

-- Local values: _, uiScale, _, heightTopBottom, barX, barY
function ExtendedCombineHUDExtension:storeScaledValues()
	local v16_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v17_, v18_ = getNormalizedScreenValues(330 * v16_, 42 * v16_)
	self.displayWidth = v17_
	self.displayHeight = v18_
	local _, v19_ = getNormalizedScreenValues(0, 8 * v16_)
	self.backgroundTop:setDimension(self.displayWidth, v19_)
	self.backgroundMiddle:setDimension(self.displayWidth, self.displayHeight - v19_ * 2)
	self.backgroundBottom:setDimension(self.displayWidth, v19_)
	self.separatorVertical:setDimension(g_pixelSizeX, self.displayHeight * 0.8)
	local v20_, v21_ = getNormalizedScreenValues(20 * v16_, 3 * v16_)
	self.yieldPercentageBar:setDimension(v20_, v21_)
	local v22_, v23_ = getNormalizedScreenValues(38 * v16_, 38 * v16_)
	self.iconX = v22_
	self.iconY = v23_
	self.currentYieldOverlay:setDimension(self.iconX, self.iconY)
	self.workAreaOverlay:setDimension(self.iconX, self.iconY)
	self.workAreaOverlayTotal:setDimension(self.iconX, self.iconY)
	local v24_, _ = getNormalizedScreenValues(310 * v16_, 0)
	self.contentWidth = v24_
	local v25_, _ = getNormalizedScreenValues(5 * v16_, 0)
	self.spacingX = v25_
	local v26_, _ = getNormalizedScreenValues(38 * v16_, 0)
	self.textWidth = v26_
end

function ExtendedCombineHUDExtension:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
	end
end

function ExtendedCombineHUDExtension:getHeight()
	return self.displayHeight or 0
end
local function v_u_35_(p30_, p31_, p32_, p33_, p34_)
	if p34_ ~= nil then
		while p34_ < getTextWidth(p32_, p33_) do
			p32_ = p32_ * 0.98
		end
	end
	setTextColor(1, 1, 1, 1)
	renderText(p30_, p31_, p32_, p33_)
end

-- Upvalues: renderLimitedText
-- Local values: yield, yieldPct, yieldPotential, yieldRatingPct, workedHectars, workedHectarsTotal, areaUnit, yieldUnit, contentOffset, gradient, r, g, b
function ExtendedCombineHUDExtension:draw(inputHelpDisplay, posX, posY)
	-- upvalues: (copy) v_u_35_
	if self.extendedCombine == nil then
		return posY
	end
	local v40_ = self.extendedCombine.lastYieldWeight
	local v41_ = self.extendedCombine.lastYieldPercentage
	local v42_ = self.extendedCombine.lastYieldPotential
	local v43_ = (v41_ - 50) / (v42_ - 50)
	local v44_ = self.combine.workedHectars - self.combine.workedHectarsInitial
	local v45_ = self.combine.workedHectars
	local v46_ = g_i18n:getText("unit_haShort")
	local v47_ = g_i18n:getText("unit_tonsShort") .. " / " .. v46_
	self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
	self.backgroundMiddle:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height)
	self.backgroundBottom:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height - self.backgroundBottom.height)
	self.backgroundTop:render()
	self.backgroundMiddle:render()
	self.backgroundBottom:render()
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	local v48_ = posX + (self.displayWidth - self.contentWidth) * 0.5
	self.currentYieldOverlay:setPosition(v48_, posY - self.displayHeight * 0.5 - self.currentYieldOverlay.height * 0.5)
	self.currentYieldOverlay:render()
	local v49_ = v48_ + self.iconX + self.spacingX
	setTextBold(true)
	v_u_35_(v49_ + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%.1f", v40_), self.textWidth)
	setTextBold(false)
	v_u_35_(v49_ + self.textWidth * 0.5, posY - self.displayHeight * 0.7, inputHelpDisplay.textSize, v47_, self.textWidth)
	local v50_ = v49_ + self.textWidth + self.spacingX
	self.separatorVertical:setPosition(v50_, posY - self.displayHeight * 0.5 - self.separatorVertical.height * 0.5)
	self.separatorVertical:render()
	local v51_ = v50_ + self.spacingX
	setTextBold(true)
	v_u_35_(v51_ + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%d", v41_), self.textWidth)
	setTextBold(false)
	v_u_35_(v51_ + self.textWidth * 0.5, posY - self.displayHeight * 0.65, inputHelpDisplay.textSize, "%", self.textWidth)
	self.yieldPercentageBar:setPosition(v51_ + self.textWidth * 0.5 - self.yieldPercentageBar.width * 0.5, posY - self.displayHeight * 0.92)
	local v52_, v53_, v54_ = ExtendedCombineHUDExtension.GRADIENT[self.isColorBlindMode]:get(v43_)
	self.yieldPercentageBar:setColor(v52_, v53_, v54_, 1)
	self.yieldPercentageBar:render()
	local v55_ = v51_ + self.textWidth + self.spacingX
	self.separatorVertical:setPosition(v55_, posY - self.displayHeight * 0.5 - self.separatorVertical.height * 0.5)
	self.separatorVertical:render()
	local v56_ = v55_ + self.spacingX
	self.workAreaOverlay:setPosition(v56_, posY - self.displayHeight * 0.5 - self.workAreaOverlay.height * 0.5)
	self.workAreaOverlay:render()
	local v57_ = v56_ + self.iconX + self.spacingX
	setTextBold(true)
	v_u_35_(v57_ + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%.1f", v44_), self.textWidth)
	setTextBold(false)
	v_u_35_(v57_ + self.textWidth * 0.5, posY - self.displayHeight * 0.7, inputHelpDisplay.textSize, v46_, self.textWidth)
	local v58_ = v57_ + self.textWidth + self.spacingX
	self.separatorVertical:setPosition(v58_, posY - self.displayHeight * 0.5 - self.separatorVertical.height * 0.5)
	self.separatorVertical:render()
	local v59_ = v58_ + self.spacingX
	self.workAreaOverlayTotal:setPosition(v59_, posY - self.displayHeight * 0.5 - self.workAreaOverlayTotal.height * 0.5)
	self.workAreaOverlayTotal:render()
	local v60_ = v59_ + self.iconX + self.spacingX
	setTextBold(true)
	v_u_35_(v60_ + self.textWidth * 0.5, posY - self.displayHeight * 0.3, inputHelpDisplay.textSize * 1.25, string.format("%.1f", v45_), self.textWidth)
	setTextBold(false)
	v_u_35_(v60_ + self.textWidth * 0.5, posY - self.displayHeight * 0.7, inputHelpDisplay.textSize, v46_, self.textWidth)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextAlignment(RenderText.ALIGN_LEFT)
	return posY - self.displayHeight
end
ExtendedCombineHUDExtension.GRADIENT = {}
ExtendedCombineHUDExtension.GRADIENT[false] = AnimCurve.new(linearInterpolator3, 2)
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.9216,
	0.0003,
	0.0012,
	["time"] = 0
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.9911,
	0.0152,
	0,
	["time"] = 0.0667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.9911,
	0.0529,
	0,
	["time"] = 0.1333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.9911,
	0.0999,
	0,
	["time"] = 0.2
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.9911,
	0.1714,
	0,
	["time"] = 0.2667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.9911,
	0.2664,
	0,
	["time"] = 0.3333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	1,
	0.4125,
	0,
	["time"] = 0.4
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	1,
	0.5457,
	0,
	["time"] = 0.4667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.7758,
	0.5395,
	0.0021,
	["time"] = 0.5333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.5089,
	0.5089,
	0.0056,
	["time"] = 0.6
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.3278,
	0.4969,
	0.011,
	["time"] = 0.6667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.1878,
	0.4793,
	0.0242,
	["time"] = 0.7333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.0931,
	0.4793,
	0.0382,
	["time"] = 0.8
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.0319,
	0.4621,
	0.0529,
	["time"] = 0.8667
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.0048,
	0.3419,
	0.0723,
	["time"] = 0.9333
})
ExtendedCombineHUDExtension.GRADIENT[false]:addKeyframe({
	0.0048,
	0.2619,
	0.1223,
	["time"] = 1
})
ExtendedCombineHUDExtension.GRADIENT[true] = AnimCurve.new(linearInterpolator3, 2)
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.3467,
	0.1384,
	0.0296,
	["time"] = 0
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.402,
	0.1912,
	0.0497,
	["time"] = 0.0667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.4793,
	0.2705,
	0.0823,
	["time"] = 0.1333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.5711,
	0.3813,
	0.1329,
	["time"] = 0.2
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.6514,
	0.4852,
	0.1845,
	["time"] = 0.2667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.7835,
	0.6445,
	0.3278,
	["time"] = 0.3333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	1,
	0.8963,
	0.7231,
	["time"] = 0.4
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	1,
	1,
	1,
	["time"] = 0.4667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.7605,
	0.9301,
	0.9559,
	["time"] = 0.5333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.3763,
	0.6795,
	0.6307,
	["time"] = 0.6
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.227,
	0.5395,
	0.4675,
	["time"] = 0.6667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.1714,
	0.4564,
	0.3916,
	["time"] = 0.7333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.1144,
	0.3712,
	0.305,
	["time"] = 0.8
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.0742,
	0.2961,
	0.2307,
	["time"] = 0.8667
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.0482,
	0.2384,
	0.1812,
	["time"] = 0.9333
})
ExtendedCombineHUDExtension.GRADIENT[true]:addKeyframe({
	0.0282,
	0.1884,
	0.1312,
	["time"] = 1
})
if v1_ then
	g_currentMission.vehicleSystem:consoleCommandReloadVehicle()
end
