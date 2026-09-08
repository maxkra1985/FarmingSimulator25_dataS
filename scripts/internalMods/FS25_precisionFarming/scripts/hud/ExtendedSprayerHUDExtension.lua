-- Local values: isReloading, modName, modDir, ExtendedSprayerHUDExtension_mt, formatDecimalNumber, renderLimitedText
local v1_ = ExtendedSprayerHUDExtension ~= nil
local v2_ = g_currentModName or ExtendedSprayerHUDExtension.MOD_NAME
local v3_ = g_currentModDirectory or ExtendedSprayerHUDExtension.MOD_DIR
ExtendedSprayerHUDExtension = {}
ExtendedSprayerHUDExtension.MOD_NAME = v2_
ExtendedSprayerHUDExtension.MOD_DIR = v3_
ExtendedSprayerHUDExtension.GUI_ELEMENTS = ExtendedSprayerHUDExtension.MOD_DIR .. "gui/ui_elements.png"
local isReloading = Class(ExtendedSprayerHUDExtension)

-- Upvalues: ExtendedSprayerHUDExtension_mt
-- Local values: self, r, g, b, a
function ExtendedSprayerHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) isReloading
	local v7_ = customMt or isReloading
	local v8_ = setmetatable({}, v7_)
	v8_.priority = GS_PRIO_LOW
	v8_.vehicle = vehicle
	v8_.extendedSprayer = vehicle[ExtendedSprayer.SPEC_TABLE_NAME]
	v8_.backgroundTop = g_overlayManager:createOverlay("precisionFarming.shortcutBox_top", 0, 0, 0, 0)
	v8_.backgroundMiddle = g_overlayManager:createOverlay("precisionFarming.shortcutBox_middle", 0, 0, 0, 0)
	v8_.backgroundBottom = g_overlayManager:createOverlay("precisionFarming.shortcutBox_bottom", 0, 0, 0, 0)
	local v9_ = HUD.COLOR.BACKGROUND
	local v10_, v11_, v12_, v13_ = unpack(v9_)
	v8_.backgroundTop:setColor(v10_, v11_, v12_, v13_)
	v8_.backgroundMiddle:setColor(v10_, v11_, v12_, v13_)
	v8_.backgroundBottom:setColor(v10_, v11_, v12_, v13_)
	v8_.gradient = g_overlayManager:createOverlay(ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT, 0, 0, 0, 0)
	v8_.gradientInactive = g_overlayManager:createOverlay(ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT, 0, 0, 0, 0)
	v8_.gradientInactive:setColor(0.4, 0.4, 0.4, 1)
	v8_.actualBar = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, 0, 0)
	local v14_ = v8_.actualBar
	local v15_ = ExtendedSprayerHUDExtension.COLOR.ACTUAL_BAR
	v14_:setColor(unpack(v15_))
	v8_.targetBar = g_overlayManager:createOverlay("precisionFarming.target_bar", 0, 0, 0, 0)
	v8_.targetFlag = g_overlayManager:createOverlay("precisionFarming.target_flag", 0, 0, 0, 0)
	v8_.setValueBar = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, 0, 0)
	local v16_ = v8_.setValueBar
	local v17_ = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_GOOD
	v16_:setColor(unpack(v17_))
	v8_.footerSeparationBar = g_overlayManager:createOverlay("precisionFarming.filled", 0, 0, 0, 0)
	local v18_ = v8_.footerSeparationBar
	local v19_ = ExtendedSprayerHUDExtension.COLOR.SEPARATOR_BAR
	v18_:setColor(unpack(v19_))
	v8_.actualPos = 0.34
	v8_.targetPos = 0.8
	v8_.actualValue = 0
	v8_.actualValueStr = "%.3f"
	v8_.setValue = 0
	v8_.targetValue = 0
	v8_.hasValidValues = false
	v8_.soilMap = g_precisionFarming.soilMap
	v8_.pHMap = g_precisionFarming.pHMap
	v8_.nitrogenMap = g_precisionFarming.nitrogenMap
	v8_.texts = {}
	v8_.texts.headline_ph_lime = g_i18n:getText("hudExtensionSprayer_headline_ph_lime", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.headline_n_solidFertilizer = g_i18n:getText("hudExtensionSprayer_headline_n_solidFertilizer", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.headline_n_liquidFertilizer = g_i18n:getText("hudExtensionSprayer_headline_n_liquidFertilizer", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.headline_n_slurryTanker = g_i18n:getText("hudExtensionSprayer_headline_n_slurryTanker", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.headline_n_manureSpreader = g_i18n:getText("hudExtensionSprayer_headline_n_manureSpreader", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.actualValue = g_i18n:getText("hudExtensionSprayer_actualValue", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.newValue = g_i18n:getText("hudExtensionSprayer_newValue", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.targetReached = g_i18n:getText("hudExtensionSprayer_targetReached", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.applicationRate = g_i18n:getText("hudExtensionSprayer_applicationRate", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.soilType = g_i18n:getText("hudExtensionSprayer_soilType", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.unknown = g_i18n:getText("hudExtensionSprayer_unknown", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.automaticShort = g_i18n:getText("hudExtensionSprayer_automaticShort", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_limeAuto = g_i18n:getText("hudExtensionSprayer_description_limeAuto", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_limeManual = g_i18n:getText("hudExtensionSprayer_description_limeManual", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_slurryAuto = g_i18n:getText("hudExtensionSprayer_description_slurryAuto", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_manureAuto = g_i18n:getText("hudExtensionSprayer_description_manureAuto", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_fertilizerAutoFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerAutoFruit", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_fertilizerAutoNoFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerAutoNoFruit", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_fertilizerAutoNoFruitDefault = g_i18n:getText("hudExtensionSprayer_description_fertilizerAutoNoFruitDefault", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_fertilizerManualFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerManualFruit", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_fertilizerManualNoFruit = g_i18n:getText("hudExtensionSprayer_description_fertilizerManualNoFruit", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.description_noFertilizerRequired = g_i18n:getText("hudExtensionSprayer_description_noFertilizerRequired", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.texts.invalidValues = g_i18n:getText("hudExtensionSprayer_invalidValues", ExtendedSprayerHUDExtension.MOD_NAME)
	v8_.actualValueStr = v8_.texts.unknown
	v8_.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], v8_.setColorBlindMode, v8_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v8_.storeScaledValues, v8_)
	v8_:storeScaledValues()
	return v8_
end

function ExtendedSprayerHUDExtension:delete()
	self.backgroundTop:delete()
	self.backgroundMiddle:delete()
	self.backgroundBottom:delete()
	self.gradient:delete()
	self.gradientInactive:delete()
	self.actualBar:delete()
	self.targetBar:delete()
	self.targetFlag:delete()
	self.setValueBar:delete()
	self.footerSeparationBar:delete()
	g_messageCenter:unsubscribeAll(self)
	self.vehicle = nil
	self.extendedSprayer = nil
end

-- Local values: _, uiScale, _, heightTopBottom, width, height, _, displayHeight, _, additionalTextHeightOffset, _, invalidHeightOffset, _, noSetBarHeightOffset
function ExtendedSprayerHUDExtension:storeScaledValues()
	local v22_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v23_, _ = getNormalizedScreenValues(300 * v22_, 0 * v22_)
	self.contentMaxWidth = v23_
	local _, v24_ = getNormalizedScreenValues(0, 8 * v22_)
	local v25_, v26_ = getNormalizedScreenValues(330 * v22_, 129 * v22_)
	self.backgroundTop:setDimension(v25_, v24_)
	self.backgroundMiddle:setDimension(v25_, v26_)
	self.backgroundBottom:setDimension(v25_, v24_)
	local v27_, v28_ = getNormalizedScreenValues(260 * v22_, 8 * v22_)
	self.gradient:setDimension(v27_, v28_)
	self.gradientInactive:setDimension(v27_, v28_)
	local v29_, v30_ = getNormalizedScreenValues(3 * v22_, 20 * v22_)
	self.actualBar:setDimension(v29_, v30_)
	local v31_, v32_ = getNormalizedScreenValues(3 * v22_, 6 * v22_)
	self.targetBar:setDimension(v31_, v32_)
	local v33_, v34_ = getNormalizedScreenValues(23 * v22_, 29 * v22_)
	self.targetFlag:setDimension(v33_, v34_)
	local v35_, v36_ = getNormalizedScreenValues(3 * v22_, 14 * v22_)
	self.setValueBar:setDimension(v35_, v36_)
	local v37_, _ = getNormalizedScreenValues(330 * v22_, 0)
	self.footerSeparationBar:setDimension(v37_, g_pixelSizeY)
	local _, v38_ = getNormalizedScreenValues(0 * v22_, 130 * v22_)
	self.displayHeight = v38_
	local _, v39_ = getNormalizedScreenValues(0 * v22_, 25 * v22_)
	self.additionalTextHeightOffset = v39_
	local _, v40_ = getNormalizedScreenValues(0 * v22_, 50 * v22_)
	self.invalidHeightOffset = v40_
	local _, v41_ = getNormalizedScreenValues(0 * v22_, 15 * v22_)
	self.noSetBarHeightOffset = v41_
	self.additionalDisplayHeight = 0
	local _, v42_ = getNormalizedScreenValues(0 * v22_, 20 * v22_)
	self.textHeightHeadline = v42_
	local _, v43_ = getNormalizedScreenValues(0 * v22_, 13 * v22_)
	self.textHeight = v43_
	local v44_, v45_ = getNormalizedScreenValues(0 * v22_, -75 * v22_)
	self.gradientPosX = v44_
	self.gradientPosY = v45_
	local _, v46_ = getNormalizedScreenValues(0 * v22_, 9 * v22_)
	self.footerOffset = v46_
	local v47_, _ = getNormalizedScreenValues(2 * v22_, 0)
	self.footerTextSpacing = v47_
	local v48_, v49_ = getNormalizedScreenValues(1 * v22_, 1 * v22_)
	self.pixelSizeX = v48_
	self.pixelSizeY = v49_
end

function ExtendedSprayerHUDExtension:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
		self.pHMap:setMinimapRequiresUpdate(true)
		self.nitrogenMap:setMinimapRequiresUpdate(true)
	end
end

function ExtendedSprayerHUDExtension:getHeight()
	return (self.displayHeight or 0) + (self.additionalDisplayHeight or 0)
end
local function v_u_54_(p53_)
	if math.floor(p53_) == p53_ then
		return string.format("%.1f", p53_)
	else
		return string.format("%s", p53_)
	end
end
local function v_u_60_(p55_, p56_, p57_, p58_, p59_)
	if p59_ ~= nil then
		while p59_ < getTextWidth(p57_, p58_) do
			p57_ = p57_ * 0.98
		end
	end
	setTextColor(1, 1, 1, 1)
	renderText(p55_, p56_, p57_, p58_)
	return getTextWidth(p57_, p58_)
end

-- Upvalues: formatDecimalNumber, renderLimitedText
-- Local values: vehicle, spec, headline, applicationRate, applicationRateReal, applicationRateStr, changeBarText, minValue, maxValue, soilTypeName, soilType, hasLimeLoaded, fillTypeDesc, sourceVehicle, fillUnitIndex, sprayFillType, massPerLiter, descriptionText, stepResolution, enableZeroTargetFlag, pHChanged, requiredLitersPerHa, pHActual, pHTarget, litersPerHectar, nitrogenChanged, nActual, nTarget, forcedFruitType, fruitTypeIndex, fillType, fruitTypeIndex, fillType, nAmount, str, totalHeight, middleHeight, centerX, gradientPosX, gradientPosY, gradientVisibilePos, uvs, uv5, uv7, labelMin, labelMax, widthDiff, additionalChangeLineHeight, changeBarRendered, targetBarX, targetBarY, showFlag, actualBarText, actualBarTextOffset, actualBarSkipFlagCollisionCheck, actualBarX, actualBarY, actualTextWidth, rightTextBorder, leftTextBorder, goodColor, badColor, difference, differenceInv, r, g, b, a, setValueBarX, setValueBarY, setBarTextX, setBarTextY, setTextWidth, bottomPosY, sideOffset, rateText, rateWidth, maxWidth
function ExtendedSprayerHUDExtension:draw(inputHelpDisplay, posX, posY)
	-- upvalues: (copy) v_u_54_, (copy) v_u_60_
	local v64_ = self.vehicle
	local v65_ = self.extendedSprayer
	if v65_ == nil then
		return posY
	else
		local v66_ = self.texts.headline_ph_lime
		local v67_ = 0
		local v68_ = "%.2f t/ha"
		local v69_ = ""
		local v70_ = 0
		local v71_ = 0
		self.hasValidValues = false
		local v72_ = ""
		if v65_.lastTouchedSoilType ~= 0 and self.soilMap ~= nil then
			local v73_ = self.soilMap:getSoilTypeByIndex(v65_.lastTouchedSoilType)
			if v73_ ~= nil then
				v72_ = v73_.name
			end
		end
		local v74_, v75_ = ExtendedSprayer.getFillTypeSourceVehicle(v64_)
		local v76_ = v74_:getFillUnitFillType(v75_)
		local v77_ = g_fillTypeManager:getFillTypeByIndex(v76_).massPerLiter / FillTypeManager.MASS_SCALE
		local v78_ = v76_ == FillType.LIME
		local v79_ = ""
		local v80_ = nil
		local v81_ = false
		local v82_
		if v78_ then
			self.gradient:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT)
			self.gradientInactive:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.PH_GRADIENT)
			v82_ = v65_.lastLitersPerHectar * v77_
			local v83_
			if v65_.sprayAmountAutoMode then
				v83_ = 0
			else
				local v84_ = self.pHMap:getLimeUsageByStateChange(v65_.sprayAmountManual)
				v83_ = self.pHMap:getPhValueFromChangedStates(v65_.sprayAmountManual)
				v82_ = v84_ * v77_
				if v83_ > 0 then
					v69_ = string.format("pH +%s", v_u_54_(v83_))
				end
			end
			if v65_.phActualValue ~= 0 and (v65_.phTargetValue ~= 0 and self.vehicle.isOnField) then
				local v85_ = self.pHMap:getPhValueFromInternalValue(v65_.phActualValue)
				local v86_ = self.pHMap:getPhValueFromInternalValue(v65_.phTargetValue)
				self.actualValue = v85_
				self.setValue = v85_ + v83_
				self.targetValue = v86_
				if v65_.sprayAmountAutoMode then
					local v87_ = self.targetValue - self.actualValue
					if v87_ > 0 then
						v69_ = string.format("pH +%s", v_u_54_(v87_))
					end
					self.setValue = self.targetValue
				end
				self.actualValueStr = "pH %.3f"
				if v72_ ~= "" then
					if v65_.sprayAmountAutoMode then
						v79_ = string.format(self.texts.description_limeAuto, v72_, v_u_54_(v86_))
					else
						v79_ = string.format(self.texts.description_limeManual, v72_, v_u_54_(v86_))
					end
				end
				self.hasValidValues = true
			end
			if self.pHMap ~= nil then
				v70_, v71_ = self.pHMap:getMinMaxValue()
			end
			v80_ = v65_.pHMap:getPhValueFromChangedStates(1)
		else
			self.gradient:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.N_GRADIENT)
			self.gradientInactive:setSliceId(self.isColorBlindMode and ExtendedSprayerHUDExtension.SLICES.COLOR_BLIND_GRADIENT or ExtendedSprayerHUDExtension.SLICES.N_GRADIENT)
			v82_ = v65_.lastLitersPerHectar
			local v88_
			if v65_.sprayAmountAutoMode then
				v88_ = 0
			else
				v82_ = self.nitrogenMap:getFertilizerUsageByStateChange(v65_.sprayAmountManual, v76_)
				v88_ = self.nitrogenMap:getNitrogenFromChangedStates(v65_.sprayAmountManual)
				if v88_ > 0 then
					v69_ = string.format("+%dkg N/ha", v88_)
				end
			end
			if v65_.isSolidFertilizerSprayer then
				v66_ = self.texts.headline_n_solidFertilizer
				v82_ = v82_ * v77_ * 1000
				v68_ = "%d kg/ha"
			elseif v65_.isLiquidFertilizerSprayer then
				v66_ = self.texts.headline_n_liquidFertilizer
				v68_ = "%d l/ha"
			elseif v65_.isSlurryTanker then
				v66_ = self.texts.headline_n_slurryTanker
				v68_ = "%.1f m\194\179/ha"
				v82_ = v82_ / 1000
				if v65_.sprayAmountAutoMode and v72_ ~= "" then
					v79_ = string.format(self.texts.description_slurryAuto, v72_)
				end
			elseif v65_.isManureSpreader then
				v66_ = self.texts.headline_n_manureSpreader
				v68_ = "%.1f t/ha"
				v82_ = v82_ * v77_
				if v65_.sprayAmountAutoMode and v72_ ~= "" then
					v79_ = string.format(self.texts.description_manureAuto, v72_)
				end
			else
				v82_ = v67_
			end
			if v65_.nActualValue > 0 and (v65_.nTargetValue > 0 and (self.vehicle.isOnField and not v65_.isDoingMissionWork)) then
				local v89_ = self.nitrogenMap
				local v90_ = v65_.nActualValue
				local v91_ = self.nitrogenMap.maxValue
				local v92_ = v89_:getNitrogenValueFromInternalValue((math.clamp(v90_, 0, v91_)))
				local v93_ = self.nitrogenMap
				local v94_ = v65_.nTargetValue
				local v95_ = self.nitrogenMap.maxValue
				local v96_ = v93_:getNitrogenValueFromInternalValue((math.clamp(v94_, 0, v95_)))
				self.actualValue = v92_
				self.setValue = v92_ + v88_
				self.targetValue = v96_
				if v65_.sprayAmountAutoMode then
					local v97_ = self.targetValue - self.actualValue
					if v97_ > 0 then
						v69_ = string.format("+%dkg N/ha", v97_)
					end
					self.setValue = self.targetValue
				end
				self.actualValueStr = "%dkg N/ha"
				local v98_
				if v64_.spec_sowingMachine == nil then
					v98_ = nil
				else
					v98_ = v64_.spec_sowingMachine.workAreaParameters.seedsFruitType
				end
				local v99_ = v98_ or v65_.nApplyAutoModeFruitType
				if v99_ ~= nil then
					local v100_ = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v99_))
					if v100_ ~= nil and (v100_ ~= FillType.UNKNOWN and v72_ ~= "") then
						if v96_ > 0 then
							if v65_.sprayAmountAutoMode then
								v79_ = string.format(self.texts.description_fertilizerAutoFruit, v100_.title, v72_)
							else
								v79_ = string.format(self.texts.description_fertilizerManualFruit, v100_.title, v72_)
							end
						else
							v79_ = self.texts.description_noFertilizerRequired
							v81_ = true
						end
					end
				end
				if v79_ == "" and v72_ ~= "" then
					if v65_.sprayAmountAutoMode then
						v79_ = string.format(self.texts.description_fertilizerAutoNoFruit, v72_)
						if self.nitrogenMap ~= nil then
							local v101_ = self.nitrogenMap:getFruitTypeIndexByFruitRequirementIndex(v65_.nApplyAutoModeFruitRequirementDefaultIndex)
							if v101_ ~= nil then
								local v102_ = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v101_))
								if v102_ ~= nil then
									v79_ = string.format(self.texts.description_fertilizerAutoNoFruitDefault, v102_.title, v72_)
								end
							end
						end
					else
						v79_ = string.format(self.texts.description_fertilizerManualNoFruit, v72_)
					end
				end
				self.hasValidValues = true
			end
			if self.nitrogenMap ~= nil then
				v70_, v71_ = self.nitrogenMap:getMinMaxValue()
				local v103_ = v65_.lastNitrogenProportion
				if v103_ == 0 then
					v103_ = self.nitrogenMap:getNitrogenAmountFromFillType(v76_)
				end
				if v65_.isSlurryTanker then
					local v104_ = (v74_.getIsUsingExactNitrogenAmount == nil or not v74_:getIsUsingExactNitrogenAmount()) and " (~%skgN/m\194\179)" or " (%skgN/m\194\179)"
					v68_ = v68_ .. string.format(v104_, MathUtil.round(v103_ * 1000, 1))
				else
					v68_ = v68_ .. string.format(" (%s%%%%N)", MathUtil.round(v103_ * 100, 1))
				end
				v80_ = self.nitrogenMap:getNitrogenFromChangedStates(1)
			end
		end
		if v65_.sprayAmountAutoMode then
			v68_ = v68_ .. string.format(" (%s)", self.texts.automaticShort)
			v72_ = ""
		end
		local v105_ = (self.actualValue - v70_) / (v71_ - v70_)
		self.actualPos = math.min(v105_, 1)
		local v106_ = (self.setValue - v70_) / (v71_ - v70_)
		self.setValuePos = math.min(v106_, 1)
		local v107_ = (self.targetValue - v70_) / (v71_ - v70_)
		self.targetPos = math.min(v107_, 1)
		local v108_ = self:getHeight() - self.backgroundTop.height - self.backgroundBottom.height
		self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
		self.backgroundMiddle:setPosition(posX, posY - self.backgroundTop.height - v108_)
		self.backgroundBottom:setPosition(posX, posY - self.backgroundTop.height - v108_ - self.backgroundBottom.height)
		self.backgroundMiddle:setDimension(nil, v108_)
		self.backgroundTop:render()
		self.backgroundMiddle:render()
		self.backgroundBottom:render()
		local v109_ = posX + self.backgroundTop.width * 0.5
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		v_u_60_(v109_, posY - self.textHeightHeadline * 1.1, self.textHeightHeadline, v66_, self.contentMaxWidth)
		setTextBold(false)
		local v110_ = v109_ - self.gradientInactive.width * 0.5 + self.gradientPosX
		local v111_ = posY + self.gradientPosY
		if not self.hasValidValues then
			v111_ = v111_ + (self.actualBar.height - self.gradientInactive.height) + self.textHeight
		end
		self.gradientInactive:setPosition(v110_, v111_)
		self.gradientInactive:render()
		local v112_ = not self.hasValidValues and 0 or self.actualPos
		self.gradient:setPosition(v110_, v111_)
		self.gradient:setDimension(v112_ * self.gradientInactive.width)
		local v113_ = self.gradient.uvs
		local v114_ = v113_[1] + (v113_[5] - v113_[1]) * v112_
		local v115_ = v113_[3] + (v113_[7] - v113_[3]) * v112_
		setOverlayUVs(self.gradient.overlayId, v113_[1], v113_[2], v113_[3], v113_[4], v114_, v113_[6], v115_, v113_[8])
		self.gradient:render()
		local v116_, v117_
		if v78_ then
			v116_ = string.format("pH\n%s", v70_)
			v117_ = string.format("pH\n%s", v71_)
		else
			v116_ = string.format("%s\nkg/ha", v70_)
			v117_ = string.format("%s\nkg/ha", v71_)
		end
		local v118_ = (self.backgroundTop.width - self.gradientInactive.width) * 0.25
		v_u_60_(posX + v118_, v111_ + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, v116_)
		v_u_60_(posX + self.backgroundTop.width - v118_, v111_ + self.gradientInactive.height * 0.85, self.gradientInactive.height * 1.3, v117_)
		local v119_ = 0
		local v120_ = false
		if self.hasValidValues then
			local v121_ = self.targetPos ~= 0 and true or v81_
			local v122_
			if v121_ then
				v122_ = v110_ + self.gradientInactive.width * self.targetPos - self.targetBar.width * 0.5
				self.targetBar:setPosition(v122_, v111_)
				self.targetBar:render()
				self.targetFlag:setPosition(v122_, v111_ + self.targetBar.height)
				self.targetFlag:render()
			else
				v122_ = nil
			end
			local v123_ = nil
			local v124_ = self.actualBar.height + self.textHeight * 1.1
			local v125_ = false
			if self.actualPos == self.targetPos then
				if (v65_.sprayAmountAutoMode or self.targetPos == self.setValuePos) and self.targetPos ~= 0 then
					v123_ = string.format(self.texts.targetReached, string.format(self.actualValueStr, self.actualValue))
					v124_ = -self.textHeight * 0.7
					v125_ = true
					v120_ = true
				end
			else
				v123_ = string.format(self.texts.actualValue, string.format(self.actualValueStr, self.actualValue))
			end
			if v123_ ~= nil then
				local v126_ = v110_ + self.gradientInactive.width * self.actualPos - self.actualBar.width * 0.5
				local v127_ = v111_ + (self.gradientInactive.height - self.actualBar.height) * 0.5
				self.actualBar:setPosition(v126_, v127_)
				self.actualBar:render()
				local v128_ = getTextWidth(self.textHeight * 0.7, v123_)
				local v129_ = posX + self.backgroundTop.width - v128_ * 0.5
				local v130_ = math.min(v126_, v129_)
				local v131_ = posX + v128_ * 0.5
				local v132_ = math.max(v130_, v131_)
				if not v125_ and v121_ then
					local v133_ = v132_ + v128_ * 0.5
					if v122_ < v133_ and v133_ < v122_ + self.targetFlag.width * 0.5 then
						v132_ = v122_ - v128_ * 0.5 - self.pixelSizeX
					end
					local v134_ = v132_ - v128_ * 0.5
					if v122_ < v134_ and v134_ < v122_ + self.targetFlag.width * 0.5 or v134_ < v122_ and v122_ < v133_ then
						v132_ = v122_ + self.targetFlag.width + self.pixelSizeX + v128_ * 0.5
					end
				end
				v_u_60_(v132_, v127_ + v124_, self.textHeight * 0.7, v123_)
			end
			if self.setValuePos > self.actualPos then
				local v135_ = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_GOOD
				local v136_ = ExtendedSprayerHUDExtension.COLOR.SET_VALUE_BAR_BAD
				local v137_ = self.setValue - self.targetValue
				local v138_ = math.abs(v137_) / v80_ / 3
				local v139_ = math.min(v138_, 1)
				local v140_ = 1 - v139_
				local v141_ = v139_ * v136_[1] + v140_ * v135_[1]
				local v142_ = v139_ * v136_[2] + v140_ * v135_[2]
				local v143_ = v139_ * v136_[3] + v140_ * v135_[3]
				local v144_ = v110_ + self.gradientInactive.width * self.actualPos
				local v145_ = v111_ - self.gradientInactive.height - self.setValueBar.height
				self.setValueBar:setPosition(v144_, v145_)
				local v146_ = self.setValueBar
				local v147_ = self.gradientInactive.width
				local v148_ = self.setValuePos
				v146_:setDimension(v147_ * (math.min(v148_, 1) - self.actualPos))
				self.setValueBar:setColor(v141_, v142_, v143_, 1)
				self.setValueBar:render()
				local v149_ = v144_ + self.setValueBar.width * 0.5
				local v150_ = v145_ + self.setValueBar.height * 0.2
				if getTextWidth(self.setValueBar.height * 0.9, v69_) > self.setValueBar.width * 0.95 then
					v150_ = v145_ - self.setValueBar.height
					v119_ = self.setValueBar.height
				end
				v_u_60_(v149_, v150_, self.setValueBar.height * 0.9, v69_)
				v120_ = true
			end
		else
			v79_ = self.texts.invalidValues
		end
		local v151_ = posY - self:getHeight()
		if v79_ ~= "" and self.additionalDisplayHeight ~= 0 then
			setTextAlignment(RenderText.ALIGN_CENTER)
			v_u_60_(v109_, v151_ + self.footerOffset + self.textHeight * 1.85, self.textHeight, v79_, self.contentMaxWidth)
		end
		self.footerSeparationBar:setPosition(v109_ - self.footerSeparationBar.width * 0.5, v151_ + self.footerOffset + self.textHeight * 1.3)
		self.footerSeparationBar:render()
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v152_ = (self.backgroundTop.width - self.contentMaxWidth) * 0.5
		local v153_ = self.texts.applicationRate .. " " .. string.format(v68_, v82_, 0)
		local v154_ = v_u_60_(posX + v152_, v151_ + self.footerOffset, self.textHeight, v153_, self.contentMaxWidth)
		if v72_ ~= "" then
			local v155_ = self.contentMaxWidth - v154_ - self.footerTextSpacing
			setTextAlignment(RenderText.ALIGN_RIGHT)
			v_u_60_(posX + self.backgroundTop.width - v152_, v151_ + self.footerOffset, self.textHeight, string.format(self.texts.soilType, v72_), v155_)
		end
		self.additionalDisplayHeight = v119_
		if v79_ ~= "" then
			self.additionalDisplayHeight = self.additionalDisplayHeight + self.additionalTextHeightOffset
		end
		if self.hasValidValues then
			if not v120_ then
				self.additionalDisplayHeight = self.additionalDisplayHeight - self.noSetBarHeightOffset
			end
			return v151_
		else
			self.additionalDisplayHeight = self.additionalDisplayHeight - self.invalidHeightOffset
			return v151_
		end
	end
end
ExtendedSprayerHUDExtension.COLOR = {
	["TARGET_BAR"] = {
		1,
		1,
		1,
		1
	},
	["ACTUAL_BAR"] = {
		0.601,
		0.01,
		0.01,
		1
	},
	["SEPARATOR_BAR"] = {
		1,
		1,
		1,
		0.3
	},
	["SET_VALUE_BAR_GOOD"] = {
		0.01,
		0.41,
		0.01,
		1
	},
	["SET_VALUE_BAR_BAD"] = {
		0.61,
		0.01,
		0.01,
		1
	}
}
ExtendedSprayerHUDExtension.SLICES = {
	["PH_GRADIENT"] = "precisionFarming.gradient_ph",
	["N_GRADIENT"] = "precisionFarming.gradient_red_green",
	["COLOR_BLIND_GRADIENT"] = "precisionFarming.gradient_color_blind"
}
if v1_ then
	g_currentMission.vehicleSystem:consoleCommandReloadVehicle()
end
