MixerWagonHUDExtension = {}
local MixerWagonHUDExtension_mt = Class(MixerWagonHUDExtension)
function MixerWagonHUDExtension.new(vehicle, customMt)
	local self = setmetatable({}, customMt or MixerWagonHUDExtension_mt)
	self.priority = GS_PRIO_HIGH
	local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
	self.backgroundTop = g_overlayManager:createOverlay("gui.hudExtension_top", 0, 0, 0, 0)
	self.backgroundTop:setColor(r, g, b, a)
	self.backgroundScale = g_overlayManager:createOverlay("gui.hudExtension_middle", 0, 0, 0, 0)
	self.backgroundScale:setColor(r, g, b, a)
	self.backgroundBottom = g_overlayManager:createOverlay("gui.hudExtension_bottom", 0, 0, 0, 0)
	self.backgroundBottom:setColor(r, g, b, a)
	self.bar = ThreePartOverlay.new()
	self.bar:setLeftPart("gui.progressbar_left", 0, 0)
	self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	self.bar:setRightPart("gui.progressbar_right", 0, 0)
	self.marker = g_overlayManager:createOverlay("gui.tmr_marker", 0, 0, 0, 0)
	self.vehicle = vehicle
	self.mixerWagon = vehicle.spec_mixerWagon
	self.numFillTypes = #self.mixerWagon.mixerWagonFillTypes
	self.fillTypeStatus = {}
	for _, mixerWagonFillType in ipairs(self.mixerWagon.mixerWagonFillTypes) do
		local firstFilltype = next(mixerWagonFillType.fillTypes)
		local fillType = g_fillTypeManager:getFillTypeByIndex(firstFilltype)
		if fillType == nil then
			continue
		end
		local icon = Overlay.new(fillType.hudOverlayFilename, 0, 0, 0, 0)
		local status = { icon = icon, fillLevel = 0, minPercentage = mixerWagonFillType.minPercentage, maxPercentage = mixerWagonFillType.maxPercentage }
		table.insert(self.fillTypeStatus, status)
	end
	self.badMixColor = { 0.8069, 0.0097, 0.0097, 1 }
	self.title = utf8ToUpper(string.format("%s - %s", g_i18n:getText("info_mixingRatio"), vehicle:getFullName()))
	self:storeScaledValues()
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)
	return self
end
function MixerWagonHUDExtension:delete()
	self.backgroundTop:delete()
	self.backgroundScale:delete()
	self.backgroundBottom:delete()
	self.marker:delete()
	self.bar:delete()
	for _, status in ipairs(self.fillTypeStatus) do
		status.icon:delete()
	end
	g_messageCenter:unsubscribeAll(self)
end
function MixerWagonHUDExtension:storeScaledValues()
	local _ = nil
	local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	_, self.offsetTop = getNormalizedScreenValues(0, 26 * uiScale)
	_, self.offsetBottom = getNormalizedScreenValues(0, 8 * uiScale)
	_, self.heightPerFillType = getNormalizedScreenValues(0, 24 * uiScale)
	self.totalHeight = self.heightPerFillType * self.numFillTypes + self.offsetTop + self.offsetBottom
	local width, height = getNormalizedScreenValues(330 * uiScale, 6 * uiScale)
	self.backgroundTop:setDimension(width, height)
	self.backgroundBottom:setDimension(width, height)
	self.backgroundScale:setDimension(width, self.totalHeight - 2 * height)
	self.titleOffsetX, self.titleOffsetY = getNormalizedScreenValues(14 * uiScale, -19 * uiScale)
	_, self.titleSize = getNormalizedScreenValues(0, 12 * uiScale)
	self.barOffsetX, self.barOffsetY = getNormalizedScreenValues(45 * uiScale, 10 * uiScale)
	local barPartWidth, barPartHeight = getNormalizedScreenValues(3, 6)
	self.barMaxWidth, _ = getNormalizedScreenValues(235 * uiScale, 0)
	self.barPartsWidth = 2 * barPartWidth
	self.barPartHeight = barPartHeight
	self.middlePartMaxWidth = self.barMaxWidth - self.barPartsWidth
	self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
	self.bar:setMiddlePart(nil, self.middlePartMaxWidth, barPartHeight)
	self.bar:setRightPart(nil, barPartWidth, barPartHeight)
	local iconWidth, iconHeight = getNormalizedScreenValues(25 * uiScale, 25 * uiScale)
	for _, status in ipairs(self.fillTypeStatus) do
		status.icon:setDimension(iconWidth, iconHeight)
	end
	self.iconOffsetX, self.iconOffsetY = getNormalizedScreenValues(11 * uiScale, 2 * uiScale)
	self.textOffsetX, self.textOffsetY = getNormalizedScreenValues(-5 * uiScale, 8 * uiScale)
	_, self.textSize = getNormalizedScreenValues(0, 12 * uiScale)
	local markerWidth, markerHeight = getNormalizedScreenValues(11 * uiScale, 11 * uiScale)
	self.marker:setDimension(markerWidth, markerHeight)
end
function MixerWagonHUDExtension:draw(inputHelpDisplay, posX, posY)
	local barBgColor = HUD.COLOR.BACKGROUND_DARK
	local activeColor = HUD.COLOR.ACTIVE
	local badMixColor = self.badMixColor
	self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
	self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
	self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
	self.backgroundTop:render()
	self.backgroundScale:render()
	self.backgroundBottom:render()
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	local maxWidth = self.backgroundTop.width - 2 * self.titleOffsetX
	local title = Utils.limitTextToWidth(self.title, self.titleSize, maxWidth, false, "...")
	renderText(posX + self.titleOffsetX, posY + self.titleOffsetY, self.titleSize, title)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	local totalFillLevel = 0
	if 0 < self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) then
		for i, mixerWagonFillType in ipairs(self.mixerWagon.mixerWagonFillTypes) do
			totalFillLevel = totalFillLevel + mixerWagonFillType.fillLevel
			self.fillTypeStatus[i].fillLevel = mixerWagonFillType.fillLevel
		end
	end
	local fillTypePosY = posY - self.offsetTop
	local fillTypeTextPosX = posX + self.backgroundTop.width + self.textOffsetX
	for _, status in ipairs(self.fillTypeStatus) do
		fillTypePosY = fillTypePosY - self.heightPerFillType
		local icon = status.icon
		icon:setPosition(posX + self.iconOffsetX, fillTypePosY + self.iconOffsetY)
		icon:render()
		self.bar:setMiddlePart(nil, self.middlePartMaxWidth, nil)
		self.bar:setColor(barBgColor[1], barBgColor[2], barBgColor[3], barBgColor[4])
		self.bar:setPosition(posX + self.barOffsetX, fillTypePosY + self.barOffsetY)
		self.bar:render()
		local percentage = 0
		if 0 < self.vehicle:getFillUnitFillLevel(self.mixerWagon.fillUnitIndex) then
			percentage = status.fillLevel / totalFillLevel
		end
		local scale = self.barMaxWidth * (status.maxPercentage - status.minPercentage) - self.barPartsWidth
		local offsetX = self.barMaxWidth * status.minPercentage
		local color = badMixColor
		if 0 < status.fillLevel and (self.vehicle:getFillUnitFillType(self.mixerWagon.fillUnitIndex) ~= FillType.FORAGE_MIXING or status.minPercentage <= percentage and percentage <= status.maxPercentage) then
			color = activeColor
		end
		self.bar:setColor(color[1], color[2], color[3], color[4])
		self.bar:setMiddlePart(nil, scale, nil)
		self.bar:setPosition(posX + self.barOffsetX + offsetX, nil)
		self.bar:render()
		self.marker:setPosition(posX + self.barOffsetX + self.barMaxWidth * percentage - self.marker.width * 0.5, self.bar.y - (self.marker.height - self.barPartHeight) * 0.5)
		self.marker:render()
		local text = string.format("%d%%", percentage * 100)
		renderText(fillTypeTextPosX, fillTypePosY + self.textOffsetY, self.textSize, text)
	end
	setTextBold(false)
	return self.backgroundBottom.y
end
function MixerWagonHUDExtension:getHeight()
	return self.totalHeight
end
