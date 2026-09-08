-- Local values: isReloading, modName, modDir, ExtendedSowingMachineHUDExtension_mt, renderLimitedText
local v1_ = ExtendedSowingMachineHUDExtension ~= nil
local v2_ = g_currentModName or ExtendedSowingMachineHUDExtension.MOD_NAME
local v3_ = g_currentModDirectory or ExtendedSowingMachineHUDExtension.MOD_DIR
ExtendedSowingMachineHUDExtension = {}
ExtendedSowingMachineHUDExtension.MOD_NAME = v2_
ExtendedSowingMachineHUDExtension.MOD_DIR = v3_
ExtendedSowingMachineHUDExtension.GUI_ELEMENTS = ExtendedSowingMachineHUDExtension.MOD_DIR .. "gui/ui_elements.png"
local isReloading = Class(ExtendedSowingMachineHUDExtension)

-- Upvalues: ExtendedSowingMachineHUDExtension_mt
-- Local values: self, r, g, b, a, i, dotData
function ExtendedSowingMachineHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) isReloading
	local v7_ = customMt or isReloading
	local v8_ = setmetatable({}, v7_)
	v8_.priority = GS_PRIO_NORMAL
	v8_.vehicle = vehicle
	v8_.extendedSowingMachine = vehicle[ExtendedSowingMachine.SPEC_TABLE_NAME]
	v8_.backgroundTop = g_overlayManager:createOverlay("precisionFarming.shortcutBox_top", 0, 0, 0, 0)
	v8_.backgroundMiddle = g_overlayManager:createOverlay("precisionFarming.shortcutBox_middle", 0, 0, 0, 0)
	v8_.backgroundBottom = g_overlayManager:createOverlay("precisionFarming.shortcutBox_bottom", 0, 0, 0, 0)
	local v9_ = HUD.COLOR.BACKGROUND
	local v10_, v11_, v12_, v13_ = unpack(v9_)
	v8_.backgroundTop:setColor(v10_, v11_, v12_, v13_)
	v8_.backgroundMiddle:setColor(v10_, v11_, v12_, v13_)
	v8_.backgroundBottom:setColor(v10_, v11_, v12_, v13_)
	v8_.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v8_.separatorHorizontal:setColor(1, 1, 1, 0.25)
	v8_.dots = {}
	for _ = 1, 3 do
		local v14_ = {
			["dotEmpty"] = g_overlayManager:createOverlay("precisionFarming.seeds_dot_empty", 0, 0, 0, 0),
			["dotFilled"] = g_overlayManager:createOverlay("precisionFarming.seeds_dot_filled", 0, 0, 0, 0),
			["dotFill"] = g_overlayManager:createOverlay("precisionFarming.seeds_dot_fill", 0, 0, 0, 0)
		}
		local v15_ = v8_.dots
		table.insert(v15_, v14_)
	end
	v8_.seedsOverlay = g_overlayManager:createOverlay(ExtendedSowingMachineHUDExtension.SEED_RATE_SLICES[1], 0, 0, 0, 0)
	v8_.recommendOverlay = g_overlayManager:createOverlay("precisionFarming.seeds_recommendationBar", 0, 0, 0, 0)
	v8_.recommendOverlay:setColor(0.5, 0.5, 0.5, 1)
	v8_.texts = {}
	v8_.texts.headline = g_i18n:getText("hudExtensionSowingMachine_headline", ExtendedSowingMachineHUDExtension.MOD_NAME)
	v8_.texts.seedRate = g_i18n:getText("hudExtensionSowingMachine_seedRate", ExtendedSowingMachineHUDExtension.MOD_NAME)
	v8_.texts.auto = g_i18n:getText("hudExtensionSowingMachine_auto", ExtendedSowingMachineHUDExtension.MOD_NAME)
	v8_.texts.notAvailable = g_i18n:getText("hudExtensionSowingMachine_notAvailable", ExtendedSowingMachineHUDExtension.MOD_NAME)
	v8_.texts.tramlineWidth = g_i18n:getText("hudExtensionSowingMachine_tramlineWidth", ExtendedSowingMachineHUDExtension.MOD_NAME)
	v8_.texts.tramlineNotAvailable = g_i18n:getText("hudExtensionSowingMachine_tramlineNotAvailable", ExtendedSowingMachineHUDExtension.MOD_NAME)
	v8_.seedRateMap = g_precisionFarming.seedRateMap
	v8_.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], v8_.setColorBlindMode, v8_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v8_.storeScaledValues, v8_)
	v8_:storeScaledValues()
	return v8_
end

-- Local values: _, dotData
function ExtendedSowingMachineHUDExtension:delete()
	for _, v17_ in ipairs(self.dots) do
		v17_.dotEmpty:delete()
		v17_.dotFilled:delete()
		v17_.dotFill:delete()
	end
	self.backgroundTop:delete()
	self.backgroundMiddle:delete()
	self.backgroundBottom:delete()
	self.separatorHorizontal:delete()
	self.seedsOverlay:delete()
	self.recommendOverlay:delete()
	g_messageCenter:unsubscribeAll(self)
	self.vehicle = nil
	self.extendedSowingMachine = nil
end

-- Local values: _, uiScale, _, heightTopBottom, width, height, _, dotData
function ExtendedSowingMachineHUDExtension:storeScaledValues()
	local v19_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v20_, v21_ = getNormalizedScreenValues(330 * v19_, 61 * v19_)
	self.displayWidth = v20_
	self.displayHeight = v21_
	local _, v22_ = getNormalizedScreenValues(0, 8 * v19_)
	self.backgroundTop:setDimension(self.displayWidth, v22_)
	self.backgroundMiddle:setDimension(self.displayWidth, self.displayHeight - v22_ * 2)
	self.backgroundBottom:setDimension(self.displayWidth, v22_)
	local _, v23_ = getNormalizedScreenValues(0, 41 * v19_)
	self.seedRateHeight = v23_
	local _, v24_ = getNormalizedScreenValues(0, 20 * v19_)
	self.tramlineHeight = v24_
	self.separatorHorizontal:setDimension(self.displayWidth, g_pixelSizeY)
	local v25_, _ = getNormalizedScreenValues(300 * v19_, 0)
	self.contentWidth = v25_
	local _, v26_ = getNormalizedScreenValues(0, 16 * v19_)
	self.textHeightHeadline = v26_
	local _, v27_ = getNormalizedScreenValues(0, -1 * v19_)
	self.textOffsetHeadline = v27_
	local v28_, _ = getNormalizedScreenValues(145 * v19_, 0)
	self.textMaxWidthHeadline = v28_
	local v29_, v30_ = getNormalizedScreenValues(249 * v19_, 13 * v19_)
	self.rateTextOffsetX = v29_
	self.rateTextHeight = v30_
	local _, v31_ = getNormalizedScreenValues(0 * v19_, 10 * v19_)
	self.rateTextOffsetY = v31_
	local v32_, v33_ = getNormalizedScreenValues(185 * v19_, 13 * v19_)
	self.modeTextOffsetX = v32_
	self.modeTextHeight = v33_
	local _, v34_ = getNormalizedScreenValues(0, 2 * v19_)
	self.modeTextOffset = v34_
	local v35_, v36_ = getNormalizedScreenValues(205 * v19_, 12 * v19_)
	self.naTextOffsetX = v35_
	self.naTextHeight = v36_
	local v37_, _ = getNormalizedScreenValues(120 * v19_, 0)
	self.naTextMaxX = v37_
	local _, v38_ = getNormalizedScreenValues(0, 1 * v19_)
	self.naTextOffset = v38_
	local v39_, _ = getNormalizedScreenValues(35 * v19_, 0 * v19_)
	self.dotsFullWidth = v39_
	local v40_, _ = getNormalizedScreenValues(0 * v19_, 0)
	self.seedOverlayOffsetX = v40_
	local _, v41_ = getNormalizedScreenValues(0, 0 * v19_)
	self.recommendOverlayOffsetY = v41_
	local v42_, v43_ = getNormalizedScreenValues(12 * v19_, 12 * v19_)
	for _, v44_ in ipairs(self.dots) do
		v44_.dotEmpty:setDimension(v42_, v43_)
		v44_.dotFilled:setDimension(v42_, v43_)
		v44_.dotFill:setDimension(v42_, v43_)
	end
	local v45_, v46_ = getNormalizedScreenValues(30 * v19_, 30 * v19_)
	self.seedsOverlay:setDimension(v45_, v46_)
	local v47_, v48_ = getNormalizedScreenValues(9 * v19_, 4 * v19_)
	self.recommendOverlay:setDimension(v47_, v48_)
end

function ExtendedSowingMachineHUDExtension:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
	end
end

function ExtendedSowingMachineHUDExtension:getHeight()
	return self.displayHeight or 0
end
local function v_u_57_(p52_, p53_, p54_, p55_, p56_)
	if p56_ ~= nil then
		while p56_ < getTextWidth(p54_, p55_) do
			p54_ = p54_ * 0.98
		end
	end
	setTextColor(1, 1, 1, 1)
	renderText(p52_, p53_, p54_, p55_)
end

-- Upvalues: renderLimitedText
-- Local values: contentOffset, spec, seedsFruitType, lastSeedRate, lastSeedRateIndex, isSupported, currentRatePosX, currentRatePosY, i, dotData, dotPosX, dotPosY, displayValues, displayValue, color, uvIndex, textSize, tramlineText
function ExtendedSowingMachineHUDExtension:draw(inputHelpDisplay, posX, posY)
	-- upvalues: (copy) v_u_57_
	if self.extendedSowingMachine == nil then
		return posY
	end
	self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
	self.backgroundMiddle:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height)
	self.backgroundBottom:setPosition(posX, posY - self.backgroundTop.height - self.backgroundMiddle.height - self.backgroundBottom.height)
	self.backgroundTop:render()
	self.backgroundMiddle:render()
	self.backgroundBottom:render()
	local v62_ = posY - self.seedRateHeight
	local v63_ = (self.displayWidth - self.contentWidth) * 0.5
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	v_u_57_(posX + v63_, v62_ + self.seedRateHeight * 0.55 + self.textOffsetHeadline, self.textHeightHeadline, self.texts.headline, self.textMaxWidthHeadline)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextBold(false)
	local v64_ = self.extendedSowingMachine
	local v65_ = self.vehicle.spec_sowingMachine.workAreaParameters.seedsFruitType
	local v66_ = v64_.lastSeedRate
	local v67_ = v64_.lastSeedRateIndex
	if not v64_.seedRateAutoMode then
		v67_ = v64_.manualSeedRate
		v66_ = self.seedRateMap:getSeedRateByFruitTypeAndIndex(v65_, v67_)
	end
	local v68_ = self.seedRateMap:getIsFruitTypeSupported(v65_)
	if v68_ then
		setTextAlignment(RenderText.ALIGN_CENTER)
		local v69_ = posX + self.rateTextOffsetX
		local v70_ = v62_ + self.seedRateHeight * 0.5 - self.rateTextHeight * 0.5 + self.rateTextOffsetY
		v_u_57_(v69_, v70_, self.rateTextHeight, string.format(self.texts.seedRate, v66_))
		for v71_ = 1, #self.dots do
			local v72_ = self.dots[v71_]
			local v73_ = v69_ + (v71_ / 2 - 1) * self.dotsFullWidth - v72_.dotEmpty.width * 0.5
			local v74_ = v70_ - v72_.dotEmpty.height * 1.5
			if v67_ < v71_ then
				v72_.dotEmpty:setPosition(v73_, v74_)
				v72_.dotEmpty:render()
			else
				v72_.dotFilled:setPosition(v73_, v74_)
				v72_.dotFill:setPosition(v73_, v74_)
				v72_.dotFilled:render()
				local v75_ = self.seedRateMap:getDisplayValues()[v67_].colors[self.isColorBlindMode][1]
				v72_.dotFill:setColor(v75_[1], v75_[2], v75_[3], 1)
				v72_.dotFill:render()
			end
			if not v64_.seedRateAutoMode and (v64_.seedRateRecommendation ~= nil and v71_ <= v64_.seedRateRecommendation) then
				self.recommendOverlay:setPosition(v73_ + v72_.dotEmpty.width * 0.5 - self.recommendOverlay.width * 0.5, v74_ - self.recommendOverlay.height + self.recommendOverlayOffsetY)
				self.recommendOverlay:render()
			end
		end
		if v64_.seedRateAutoMode then
			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
			v_u_57_(posX + self.modeTextOffsetX, v62_ + self.seedRateHeight * 0.52, self.modeTextHeight, self.texts.auto)
		end
	else
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		v_u_57_(posX + v63_ + self.naTextOffsetX, v62_ + self.seedRateHeight * 0.52, self.naTextHeight, self.texts.notAvailable, self.naTextMaxX)
	end
	local v76_ = (v67_ == 0 or not v68_) and 2 or v67_
	local v77_ = self.seedsOverlay
	local v78_ = ExtendedSowingMachineHUDExtension.SEED_RATE_SLICES
	local v79_ = math.min(v76_, 3)
	v77_:setSliceId(v78_[math.max(v79_, 1)])
	self.seedsOverlay:setPosition(posX + self.backgroundTop.width - self.seedsOverlay.width - v63_ * 0.5, v62_ + self.seedRateHeight * 0.5 - self.seedsOverlay.height * 0.5)
	self.seedsOverlay:render()
	local v80_ = v62_ - self.tramlineHeight
	self.separatorHorizontal:renderCustom(posX, v80_ + self.tramlineHeight)
	local v81_ = inputHelpDisplay.textSize
	local v82_
	if v64_.tramlineWidth == nil then
		v82_ = self.texts.tramlineNotAvailable
	else
		v82_ = string.format(self.texts.tramlineWidth, v64_.tramlineWidth)
	end
	local v83_ = utf8ToUpper(v82_)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(true)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	v_u_57_(posX + v63_, v80_ + self.tramlineHeight * 0.6, v81_, v83_)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextBold(false)
	return v80_
end
ExtendedSowingMachineHUDExtension.SEED_RATE_SLICES = { "precisionFarming.seeds_rate_low", "precisionFarming.seeds_rate_mid", "precisionFarming.seeds_rate_high" }
if v1_ then
	g_currentMission.vehicleSystem:consoleCommandReloadVehicle()
end
