VariableWorkWidthHUDExtension = {}
local VariableWorkWidthHUDExtension_mt = Class(VariableWorkWidthHUDExtension)
function VariableWorkWidthHUDExtension.new(vehicle, customMt)
	local self = setmetatable({}, customMt or VariableWorkWidthHUDExtension_mt)
	self.priority = GS_PRIO_HIGH
	local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
	self.background = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	self.background:setColor(r, g, b, a)
	self.bar = ThreePartOverlay.new()
	self.bar:setLeftPart("gui.progressbar_left", 0, 0)
	self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	self.bar:setRightPart("gui.progressbar_right", 0, 0)
	self.separator = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	self.separator:setColor(1, 1, 1, 0.25)
	self.title = utf8ToUpper(g_i18n:getText("info_partialWorkingWidth"))
	self.vehicle = vehicle
	self.variableWorkWidth = vehicle.spec_variableWorkWidth
	self.numSections = #self.variableWorkWidth.sections
	self:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
	return self
end
function VariableWorkWidthHUDExtension:delete()
	self.background:delete()
	self.bar:delete()
	self.separator:delete()
	g_messageCenter:unsubscribeAll(self)
end
function VariableWorkWidthHUDExtension:storeScaledValues()
	local _ = nil
	local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local width, height = getNormalizedScreenValues(330 * uiScale, 50 * uiScale)
	self.background:setDimension(width, height)
	self.titleOffsetX, self.titleOffsetY = getNormalizedScreenValues(14 * uiScale, 27 * uiScale)
	self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(316 * uiScale, 27 * uiScale)
	_, self.textSize = getNormalizedScreenValues(0, 12 * uiScale)
	self.barOffsetX, self.barOffsetY = getNormalizedScreenValues(14 * uiScale, 11 * uiScale)
	self.barSpacingX = getNormalizedScreenValues(5 * uiScale, 0)
	local barPartWidth, barPartHeight = getNormalizedScreenValues(3, 6)
	local barMaxWidth, _ = getNormalizedScreenValues(302 * uiScale, 0)
	local totalSpacingX = self.barSpacingX * (self.numSections - 1)
	self.singleBarWidth = (barMaxWidth - totalSpacingX) / self.numSections
	self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
	self.bar:setMiddlePart(nil, self.singleBarWidth - 2 * barPartWidth, barPartHeight)
	self.bar:setRightPart(nil, barPartWidth, barPartHeight)
	local _, seperatorHeight = getNormalizedScreenValues(0, 15 * uiScale)
	self.separatorOffsetX, self.separatorOffsetY = getNormalizedScreenValues(2 * uiScale, 6 * uiScale)
	self.separator:setDimension(g_pixelSizeX, seperatorHeight)
end
function VariableWorkWidthHUDExtension:draw(inputHelpDisplay, posX, posY)
	local activeColor = HUD.COLOR.ACTIVE
	posY = posY - self.background.height
	self.background:setPosition(posX, posY)
	self.background:render()
	setTextBold(true)
	setTextColor(1, 1, 1, 1)
	setTextAlignment(RenderText.ALIGN_LEFT)
	local titlePosX = posX + self.titleOffsetX
	local titlePosY = posY + self.titleOffsetY
	renderText(titlePosX, titlePosY, self.textSize, self.title)
	setTextBold(false)
	local textPosX = posX + self.textOffsetX
	local textPosY = posY + self.textOffsetY
	local text = nil
	local usage = self.vehicle:getVariableWorkWidthUsage()
	if usage ~= nil then
		usage = MathUtil.round(usage)
		text = string.format(g_i18n:getText("info_workWidthAndUsage"), usage, self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea))
	else
		text = string.format(g_i18n:getText("info_workWidth"), self.vehicle:getWorkAreaWidth(self.variableWorkWidth.widthReferenceWorkArea))
	end
	setTextAlignment(RenderText.ALIGN_RIGHT)
	renderText(textPosX, textPosY, self.textSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	local barPosX = posX + self.barOffsetX
	local barPosY = posY + self.barOffsetY
	for i = 1, self.numSections do
		local alpha = 1
		local section = self.variableWorkWidth.sections[i]
		if not section.isActive then
			alpha = 0.25
		end
		self.bar:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4] * alpha)
		self.bar:setPosition(barPosX, barPosY)
		self.bar:render()
		if section.isCenter then
			local separatorPosX = barPosX - self.separatorOffsetX - self.separator.width
			local separatorPosY = posY + self.separatorOffsetY
			self.separator:setPosition(separatorPosX, separatorPosY)
			self.separator:render()
			separatorPosX = barPosX + self.singleBarWidth + self.separatorOffsetX
			self.separator:setPosition(separatorPosX, separatorPosY)
			self.separator:render()
		end
		barPosX = barPosX + self.singleBarWidth + self.barSpacingX
	end
	return posY
end
function VariableWorkWidthHUDExtension:getHeight()
	return self.background.height
end
