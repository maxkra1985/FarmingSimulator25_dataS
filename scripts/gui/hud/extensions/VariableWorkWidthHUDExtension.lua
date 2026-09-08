-- Local values: VariableWorkWidthHUDExtension_mt
VariableWorkWidthHUDExtension = {}
local VariableWorkWidthHUDExtension_mt = Class(VariableWorkWidthHUDExtension)

-- Upvalues: VariableWorkWidthHUDExtension_mt
-- Local values: self, r, g, b, a
function VariableWorkWidthHUDExtension.new(vehicle, customMt)
	-- upvalues: (copy) VariableWorkWidthHUDExtension_mt
	local v4_ = customMt or VariableWorkWidthHUDExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.priority = GS_PRIO_HIGH
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	v5_.background:setColor(v7_, v8_, v9_, v10_)
	v5_.bar = ThreePartOverlay.new()
	v5_.bar:setLeftPart("gui.progressbar_left", 0, 0)
	v5_.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	v5_.bar:setRightPart("gui.progressbar_right", 0, 0)
	v5_.separator = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v5_.separator:setColor(1, 1, 1, 0.25)
	v5_.title = utf8ToUpper(g_i18n:getText("info_partialWorkingWidth"))
	v5_.vehicle = vehicle
	v5_.variableWorkWidth = vehicle.spec_variableWorkWidth
	v5_.numSections = #v5_.variableWorkWidth.sections
	v5_:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], v5_.storeScaledValues, v5_)
	return v5_
end

function VariableWorkWidthHUDExtension:delete()
	self.background:delete()
	self.bar:delete()
	self.separator:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: _, uiScale, width, height, barPartWidth, barPartHeight, barMaxWidth, _, totalSpacingX, _, seperatorHeight
function VariableWorkWidthHUDExtension:storeScaledValues()
	local v13_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v14_, v15_ = getNormalizedScreenValues(330 * v13_, 50 * v13_)
	self.background:setDimension(v14_, v15_)
	local v16_, v17_ = getNormalizedScreenValues(14 * v13_, 27 * v13_)
	self.titleOffsetX = v16_
	self.titleOffsetY = v17_
	local v18_, v19_ = getNormalizedScreenValues(316 * v13_, 27 * v13_)
	self.textOffsetX = v18_
	self.textOffsetY = v19_
	local _, v20_ = getNormalizedScreenValues(0, 12 * v13_)
	self.textSize = v20_
	local v21_, v22_ = getNormalizedScreenValues(14 * v13_, 11 * v13_)
	self.barOffsetX = v21_
	self.barOffsetY = v22_
	self.barSpacingX = getNormalizedScreenValues(5 * v13_, 0)
	local v23_, v24_ = getNormalizedScreenValues(3, 6)
	local v25_, _ = getNormalizedScreenValues(302 * v13_, 0)
	self.singleBarWidth = (v25_ - self.barSpacingX * (self.numSections - 1)) / self.numSections
	self.bar:setLeftPart(nil, v23_, v24_)
	self.bar:setMiddlePart(nil, self.singleBarWidth - 2 * v23_, v24_)
	self.bar:setRightPart(nil, v23_, v24_)
	local _, v26_ = getNormalizedScreenValues(0, 15 * v13_)
	local v27_, v28_ = getNormalizedScreenValues(2 * v13_, 6 * v13_)
	self.separatorOffsetX = v27_
	self.separatorOffsetY = v28_
	self.separator:setDimension(g_pixelSizeX, v26_)
end

-- Local values: activeColor, titlePosX, titlePosY, textPosX, textPosY, text, usage, barPosX, barPosY, i, alpha, section, separatorPosX, separatorPosY
function VariableWorkWidthHUDExtension:draw(inputHelpDisplay, posX, posY)
	local v32_ = HUD.COLOR.ACTIVE
	local v33_ = posY - self.background.height
	self.background:setPosition(posX, v33_)
	self.background:render()
	setTextBold(true)
	setTextColor(1, 1, 1, 1)
	setTextAlignment(RenderText.ALIGN_LEFT)
	local v34_ = posX + self.titleOffsetX
	local v35_ = v33_ + self.titleOffsetY
	renderText(v34_, v35_, self.textSize, self.title)
	setTextBold(false)
	local v36_ = posX + self.textOffsetX
	local v37_ = v33_ + self.textOffsetY
	local v38_ = self.vehicle:getVariableWorkWidthUsage()
	local v39_
	if v38_ == nil then
		v39_ = string.format(g_i18n:getText("info_workWidth"), self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea))
	else
		local v40_ = MathUtil.round(v38_)
		v39_ = string.format(g_i18n:getText("info_workWidthAndUsage"), v40_, self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea))
	end
	setTextAlignment(RenderText.ALIGN_RIGHT)
	renderText(v36_, v37_, self.textSize, v39_)
	setTextAlignment(RenderText.ALIGN_LEFT)
	local v41_ = posX + self.barOffsetX
	local v42_ = v33_ + self.barOffsetY
	for v43_ = 1, self.numSections do
		local v44_ = self.variableWorkWidth.sections[v43_]
		local v45_ = v44_.isActive and 1 or 0.25
		self.bar:setColor(v32_[1], v32_[2], v32_[3], v32_[4] * v45_)
		self.bar:setPosition(v41_, v42_)
		self.bar:render()
		if v44_.isCenter then
			local v46_ = v41_ - self.separatorOffsetX - self.separator.width
			local v47_ = v33_ + self.separatorOffsetY
			self.separator:setPosition(v46_, v47_)
			self.separator:render()
			local v48_ = v41_ + self.singleBarWidth + self.separatorOffsetX
			self.separator:setPosition(v48_, v47_)
			self.separator:render()
		end
		v41_ = v41_ + self.singleBarWidth + self.barSpacingX
	end
	return v33_
end

function VariableWorkWidthHUDExtension:getHeight()
	return self.background.height
end
