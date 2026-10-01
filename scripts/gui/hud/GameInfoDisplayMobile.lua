local data = nil
if GameInfoDisplayMobile ~= nil then
	local old = g_currentMission.hud.gameInfoDisplay
	data = {}
	data.vehicle = old.vehicle
	data.hud = old.hud
	data.uiScale = old.uiScale
	data.hudAtlasPath = old.hudAtlasPath
	data.controlHudAtlasPath = old.controlHudAtlasPath
	data.moneyUnit = old.moneyUnit
	data.missionInfo = old.missionInfo
	data.environment = old.environment
	old:delete()
end
GameInfoDisplayMobile = {}
local GameInfoDisplayMobile_mt = Class(GameInfoDisplayMobile, HUDDisplayElement)
GameInfoDisplayMobile.HIDE_TIME = 500
function GameInfoDisplayMobile.new(hud, hudAtlasPath, moneyUnit, controlHudAtlasPath)
	local backgroundOverlay = GameInfoDisplayMobile.createBackground()
	local self = GameInfoDisplayMobile:superClass().new(backgroundOverlay, nil, GameInfoDisplayMobile_mt)
	self.hud = hud
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.controlHudAtlasPath = controlHudAtlasPath
	self.moneyUnit = moneyUnit
	self.vehicle = nil
	self.isRideable = false
	self.buttons = {}
	self.textElements = {}
	self:createMenuButton()
	self:createShopButton()
	self:createMapButton()
	self:createHelpButton()
	self:createWeatherElement()
	self:createMoneyElement()
	self:createFuelFitnessElement()
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
	return self
end
function GameInfoDisplayMobile:setVehicle(vehicle)
	self.vehicle = vehicle
	if vehicle ~= nil then
		self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
	else
		self.isRideable = false
	end
	self.fuelFitnessElement:setVisible(vehicle ~= nil)
end
function GameInfoDisplayMobile:createButton(callbackFunc, iconSize, iconUVs, inputAction, refButton)
	local buttonOffsetX, buttonOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.BUTTON_OFFSET))
	local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(iconSize))
	local button = HUDButtonElement.new(self.hud, 0, 0)
	local buttonWidth = button:getWidth()
	local basePosX, basePosY = self:getPosition()
	local baseWidth = self:getWidth()
	local baseHeight = self:getHeight()
	local anchorRight = basePosX + baseWidth
	local anchorTop = basePosY + baseHeight
	local posX = anchorRight
	if refButton ~= nil then
		local buttonPosX = refButton:getPosition()
		posX = buttonPosX + buttonOffsetX
	end
	posX = posX - buttonWidth
	local posY = anchorTop + buttonOffsetY - button:getHeight()
	button:setPosition(posX, posY)
	button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(iconUVs))
	button:setAction(inputAction)
	button:addTouchHandler(callbackFunc, self)
	button.offsetX = posX - anchorRight
	button.offsetY = posY - anchorTop
	table.insert(self.buttons, button)
	self:addChild(button)
	return button
end
function GameInfoDisplayMobile:updateButtonPosition(button, refPosX, refPosY)
	local posX = refPosX + button.offsetX * self.uiScale
	button:setPosition(posX, nil)
end
function GameInfoDisplayMobile:createMenuButton()
	local iconSize = GameInfoDisplayMobile.SIZE.ICON
	local iconUVs = GameInfoDisplayMobile.UV.MENU
	self.menuButton = self:createButton(self.onOpenMenu, iconSize, iconUVs, InputAction.MENU)
end
function GameInfoDisplayMobile:createShopButton()
	local iconSize = GameInfoDisplayMobile.SIZE.ICON
	local iconUVs = GameInfoDisplayMobile.UV.SHOP
	self.shopButton = self:createButton(self.onOpenShop, iconSize, iconUVs, InputAction.TOGGLE_STORE, self.menuButton)
end
function GameInfoDisplayMobile:createMapButton()
	local iconSize = GameInfoDisplayMobile.SIZE.ICON
	local iconUVs = GameInfoDisplayMobile.UV.MAP
	self.mapButton = self:createButton(self.onOpenMap, iconSize, iconUVs, InputAction.TOGGLE_MAP, self.shopButton)
end
function GameInfoDisplayMobile:createHelpButton()
	local width, height = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BUTTON_HIGHLIGHT))
	local highlight = Overlay.new(self.hudAtlasPath, 0, 0, width, height)
	highlight:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BUTTON_HIGHLIGHT))
	self.helpHighlightElement = HUDElement.new(highlight)
	self:addChild(self.helpHighlightElement)
	self.helpHighlightElement:setVisible(false)
	local iconSize = GameInfoDisplayMobile.SIZE.ICON
	local iconUVs = GameInfoDisplayMobile.UV.HELP
	self.helpButton = self:createButton(self.onOpenHelp, iconSize, iconUVs, InputAction.TOGGLE_HELP, self.mapButton)
	local basePosX, basePosY = self:getPosition()
	local anchorTop = basePosY + self:getHeight()
	local anchorRight = basePosX + self:getWidth()
	local offsetX, offsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.BUTTON_HIGHLIGHT))
	local posX, posY = self.helpButton:getPosition()
	posX = posX + offsetX
	posY = posY + offsetY
	self.helpHighlightElement:setPosition(posX, posY)
	self.helpHighlightElement.offsetX = posX - anchorRight
	self.helpHighlightElement.offsetY = posY - anchorTop
end
function GameInfoDisplayMobile:createBackgroundElements(posX, posY, sizeX)
	local sizeXLeft, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BG_LEFT))
	local sizeXRight, _ = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BG_RIGHT))
	local overlayLeft = Overlay.new(self.hudAtlasPath, posX, posY, sizeXLeft, sizeY)
	overlayLeft:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_LEFT))
	local baseElement = HUDElement.new(overlayLeft)
	self:addChild(baseElement)
	local posXMiddle = posX + sizeXLeft
	local sizeXMiddle = sizeX - sizeXLeft - sizeXRight
	local overlayMiddle = Overlay.new(self.hudAtlasPath, posXMiddle, posY, sizeXMiddle, sizeY)
	overlayMiddle:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_MIDDLE))
	baseElement:addChild(HUDElement.new(overlayMiddle))
	local posXRight = posXMiddle + sizeXMiddle
	local overlayRight = Overlay.new(self.hudAtlasPath, posXRight, posY, sizeXRight, sizeY)
	overlayRight:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.BG_RIGHT))
	baseElement:addChild(HUDElement.new(overlayRight))
	baseElement.totalSize = sizeX
	return baseElement
end
function GameInfoDisplayMobile:createWeatherElement()
	self.weatherOffsetX, self.weatherOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.WEATHER))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.WEATHER))
	local basePosX = self:getPosition()
	local posX = math.max(basePosX, self.weatherOffsetX)
	local posY = 1 + self.weatherOffsetY - sizeY
	self.weatherElement = self:createBackgroundElements(posX, posY, sizeX)
	local separatorSizeX, separatorSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.WEATHER_SEPARATOR))
	local separatorOffsetX, separatorOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.WEATHER_SEPARATOR))
	local separatorOverlay = Overlay.new(self.hudAtlasPath, posX + separatorOffsetX, posY + separatorOffsetY, separatorSizeX, separatorSizeY)
	separatorOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	self.weatherElement:addChild(HUDElement.new(separatorOverlay))
	local seasonOverlayUVs = {}
	for i, uvs in pairs(GameInfoDisplayMobile.UV.SEASON_ICON) do
		seasonOverlayUVs[i] = GuiUtils.getUVs(uvs)
	end
	local seasonIconSizeX, seasonIconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.SEASON_ICON))
	local seasonOffsetX, seasonOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.SEASON_ICON))
	local seasonOverlay = Overlay.new(self.controlHudAtlasPath, posX + seasonOffsetX, posY + seasonOffsetY, seasonIconSizeX, seasonIconSizeY)
	seasonOverlay:setUVs(seasonOverlayUVs[1])
	local seasonElement = HUDElement.new(seasonOverlay)
	self.weatherElement:addChild(seasonElement)
	local _, textSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.MONTH_TEXT)
	local monthOffsetX, monthOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.MONTH_TEXT))
	local colorWhite = { 1, 1, 1, 1 }
	local monthDrawFunc = function()
		seasonElement:setUVs(seasonOverlayUVs[self.environment.currentSeason])
		local text = g_i18n:formatDayInPeriod(nil, nil, true)
		local x, y = self.weatherElement:getPosition()
		local textX = x + monthOffsetX * self.uiScale
		local textY = y + monthOffsetY * self.uiScale
		GameInfoDisplayMobile.drawText(textX, textY, textSize * self.uiScale, true, RenderText.ALIGN_LEFT, colorWhite, text)
	end
	table.insert(self.textElements, monthDrawFunc)
	local timeIconSizeX, timeIconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.TIME_ICON))
	local timeOffsetX, timeOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.TIME_ICON))
	local timeOverlay = Overlay.new(self.controlHudAtlasPath, posX + timeOffsetX, posY + timeOffsetY, timeIconSizeX, timeIconSizeY)
	timeOverlay:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.TIME))
	local timeElement = HUDElement.new(timeOverlay)
	self.weatherElement:addChild(timeElement)
	local _, timeTextSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.TIME_TEXT)
	local timeTextOffsetX, timeTextOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.TIME_TEXT))
	local timeTextSpacingOffsetX, _ = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.TIME_TEXT_OFFSET))
	local timeDrawFunc = function()
		local currentTime = self.environment.dayTime / 3600000
		local timeHours = math.floor(currentTime)
		local timeMinutes = math.floor((currentTime - timeHours) * 60)
		local hours = string.format("%02d", timeHours)
		local minutes = string.format("%02d", timeMinutes)
		local x, y = self.weatherElement:getPosition()
		local textX = x + timeTextOffsetX * self.uiScale
		local textY = y + timeTextOffsetY * self.uiScale
		GameInfoDisplayMobile.drawText(textX - timeTextSpacingOffsetX * self.uiScale, textY, timeTextSize * self.uiScale, true, RenderText.ALIGN_RIGHT, colorWhite, hours)
		GameInfoDisplayMobile.drawText(textX, textY, timeTextSize * self.uiScale, true, RenderText.ALIGN_CENTER, colorWhite, ":")
		GameInfoDisplayMobile.drawText(textX + timeTextSpacingOffsetX * self.uiScale, textY, timeTextSize * self.uiScale, true, RenderText.ALIGN_LEFT, colorWhite, minutes)
	end
	table.insert(self.textElements, timeDrawFunc)
end
function GameInfoDisplayMobile:createMoneyElement()
	local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.MONEY))
	self.moneyOffsetX, self.moneyOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.MONEY))
	local weatherPos = self.weatherElement:getPosition()
	local weatherWidth = self.weatherElement.totalSize
	local posX = weatherPos + weatherWidth + self.moneyOffsetX
	local posY = 1 + self.moneyOffsetY - sizeY
	self.moneyElement = self:createBackgroundElements(posX, posY, sizeX)
	local moneyOverlayUVs = {}
	for i, uvs in pairs(GameInfoDisplayMobile.UV.MONEY_ICON) do
		moneyOverlayUVs[i] = GuiUtils.getUVs(uvs)
	end
	local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.MONEY_ICON))
	local iconOffsetX, iconOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.MONEY_ICON))
	local overlay = Overlay.new(self.controlHudAtlasPath, posX + iconOffsetX, posY + iconOffsetY, iconSizeX, iconSizeY)
	overlay:setUVs(moneyOverlayUVs[1])
	local moneyElement = HUDElement.new(overlay)
	self.moneyElement:addChild(moneyElement)
	local _, textSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.MONEY_TEXT)
	local moneyOffsetX, moneyOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.MONEY_TEXT))
	local colorWhite = { 1, 1, 1, 1 }
	local monthDrawFunc = function()
		moneyElement:setUVs(moneyOverlayUVs[self.moneyUnit])
		local money = "0"
		if g_localPlayer ~= nil then
			local farm = g_farmManager:getFarmById(g_localPlayer.farmId)
			local value = farm.money
			if 100000000 <= value then
				value = math.min(value / 1000000, 999999)
				money = g_i18n:formatNumber(value, 2, true) .. " M"
			else
				money = g_i18n:formatMoney(farm.money, 0, false, true)
			end
		end
		local x, y = moneyElement:getPosition()
		local textX = x + moneyOffsetX * self.uiScale
		local textY = y + moneyOffsetY * self.uiScale
		GameInfoDisplayMobile.drawText(textX, textY, textSize * self.uiScale, true, RenderText.ALIGN_RIGHT, colorWhite, money)
	end
	table.insert(self.textElements, monthDrawFunc)
end
function GameInfoDisplayMobile:createFuelFitnessElement()
	self.fuelOffsetX, self.fuelOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.FUEL))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.FUEL))
	local moneyPos = self.moneyElement:getPosition()
	local moneyWidth = self.moneyElement.totalSize
	local posX = moneyPos + moneyWidth + self.fuelOffsetX
	local posY = 1 + self.fuelOffsetY - sizeY
	self.fuelFitnessElement = self:createBackgroundElements(posX, posY, sizeX)
	local fuelOverlayUVs = {}
	for i, uvs in pairs(GameInfoDisplayMobile.UV.FUEL_ICON) do
		fuelOverlayUVs[i] = GuiUtils.getUVs(uvs)
	end
	local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.FUEL_ICON))
	local iconOffsetX, iconOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.FUEL_ICON))
	local overlay = Overlay.new(self.controlHudAtlasPath, posX + iconOffsetX, posY + iconOffsetY, iconSizeX, iconSizeY)
	local _, uvs = next(fuelOverlayUVs)
	overlay:setUVs(uvs)
	local fuelElement = HUDElement.new(overlay)
	self.fuelFitnessElement:addChild(fuelElement)
	local fitnessUVs = GuiUtils.getUVs(GameInfoDisplayMobile.UV.HORSE)
	local _, textSize = getNormalizedScreenValues(0, GameInfoDisplayMobile.SIZE.FUEL_TEXT)
	local fuelOffsetX, fuelOffsetY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.FUEL_TEXT))
	local colorWhite = { 1, 1, 1, 1 }
	local fuelDrawFunc = function()
		local x, y = self.fuelFitnessElement:getPosition()
		local textX = x + fuelOffsetX * self.uiScale
		local textY = y + fuelOffsetY * self.uiScale
		if self.vehicle ~= nil then
			if self.isRideable then
				local horse = self.vehicle:getCluster()
				local dailyRiding = math.floor(horse:getRidingFactor() * 100)
				local color = colorWhite
				if dailyRiding <= 5 then
					color = GameInfoDisplayMobile.COLOR.FUEL_EMPTY
				end
				GameInfoDisplayMobile.drawText(textX, textY, textSize * self.uiScale, true, RenderText.ALIGN_RIGHT, color, string.format("%d%%", dailyRiding))
				fuelElement:setUVs(fitnessUVs)
				return
			end
			if self.vehicle.getConsumerFillUnitIndex ~= nil then
				local fillUnitIndex = self.vehicle:getConsumerFillUnitIndex(FillType.DIESEL) or self.vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or self.vehicle:getConsumerFillUnitIndex(FillType.METHANE)
				if fillUnitIndex ~= nil then
					local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(self.vehicle:getFillUnitFillType(fillUnitIndex))
					local fillLevel = MathUtil.round(self.vehicle:getFillUnitFillLevelPercentage(fillUnitIndex) * 100)
					local color = colorWhite
					if fillLevel <= 5 then
						color = GameInfoDisplayMobile.COLOR.FUEL_EMPTY
					end
					GameInfoDisplayMobile.drawText(textX, textY, textSize * self.uiScale, true, RenderText.ALIGN_RIGHT, color, string.format("%d%%", fillLevel))
					fuelElement:setUVs(fuelOverlayUVs[fillTypeName])
				end
			end
		end
	end
	table.insert(self.textElements, fuelDrawFunc)
end
function GameInfoDisplayMobile.drawText(posX, posY, textSize, textBold, textAlign, color, text)
	setTextColor(color[1], color[2], color[3], color[4])
	setTextBold(textBold)
	setTextAlignment(textAlign)
	renderText(posX, posY, textSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
end
function GameInfoDisplayMobile:drawTextElement(textElement)
	textElement.updateFunc()
	local color = textElement.color
	setTextColor(color[1], color[2], color[3], color[4])
	setTextBold(textElement.textBold)
	setTextAlignment(textElement.textAlign)
	renderText(textElement.posX, textElement.posY, textElement.textSize, textElement.text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
end
function GameInfoDisplayMobile:onOpenShop()
	if g_sleepManager:getIsSleeping() then
		return
	else
		g_currentMission:onToggleStore()
	end
end
function GameInfoDisplayMobile:onOpenMap()
	if g_sleepManager:getIsSleeping() then
		return
	else
		g_currentMission:onToggleMap()
	end
end
function GameInfoDisplayMobile:onOpenMenu()
	if g_sleepManager:getIsSleeping() then
		return
	else
		g_currentMission:onToggleMenu()
	end
end
function GameInfoDisplayMobile:onOpenHelp()
	if g_sleepManager:getIsSleeping() then
		return
	else
		g_currentMission:onToggleHelp()
	end
end
function GameInfoDisplayMobile:setMoneyUnit(moneyUnit)
	if moneyUnit ~= GS_MONEY_EURO and (moneyUnit ~= GS_MONEY_POUND and moneyUnit ~= GS_MONEY_DOLLAR) then
		moneyUnit = GS_MONEY_DOLLAR
	end
	self.moneyUnit = moneyUnit
end
function GameInfoDisplayMobile:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end
function GameInfoDisplayMobile:setEnvironment(environment)
	self.environment = environment
end
function GameInfoDisplayMobile:setMoneyVisible(isVisible) end
function GameInfoDisplayMobile:setTimeVisible(isVisible) end
function GameInfoDisplayMobile:setTemperatureVisible(isVisible) end
function GameInfoDisplayMobile:setWeatherVisible(isVisible) end
function GameInfoDisplayMobile:setDateVisible(isVisible) end
function GameInfoDisplayMobile:setTutorialVisible(isVisible) end
function GameInfoDisplayMobile:setTutorialProgress(progress) end
function GameInfoDisplayMobile:setHelpHighlighted(isHighlighted)
	self.isHelpHighlighted = isHighlighted
end
function GameInfoDisplayMobile:delete()
	g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
	GameInfoDisplayMobile:superClass().delete(self)
end
function GameInfoDisplayMobile:update(dt)
	self:updateButtons()
	local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
	local isHelpAvailable = g_helpLineManager:getIsContextBasedHelpAvailable(x, y, z)
	self.helpHighlightElement:setVisible(self.helpButtonActive and isHelpAvailable)
end
function GameInfoDisplayMobile:draw()
	for _, drawFuncs in ipairs(self.textElements) do
		drawFuncs()
	end
	GameInfoDisplayMobile:superClass().draw(self)
end
function GameInfoDisplayMobile:updateButtons()
	local shopButtonWasActive = self.shopButtonActive
	local helpButtonWasActive = self.helpButtonActive
	local mapButtonWasActive = self.mapButtonActive
	local menuButtonWasActive = self.menuButtonActive
	local isGuiVisible = g_gui:getIsGuiVisible()
end
function GameInfoDisplayMobile:setScale(uiScale)
	GameInfoDisplayMobile:superClass().setScale(self, uiScale, uiScale)
	local currentVisibility = self:getVisible()
	self:setVisible(true, false)
	self.uiScale = uiScale
	local posX, posY, width, height = GameInfoDisplayMobile.getBackgroundPositionAndSize(uiScale)
	self:setPosition(posX, posY)
	self:setDimension(width, height)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
	local refPosX = posX + width
	local refPosY = posY + height
	self:updateButtonPosition(self.shopButton, refPosX, refPosY)
	self:updateButtonPosition(self.menuButton, refPosX, refPosY)
	self:updateButtonPosition(self.mapButton, refPosX, refPosY)
	self:updateButtonPosition(self.helpButton, refPosX, refPosY)
	local buttonHighlight = self.helpHighlightElement
	posX = refPosX + buttonHighlight.offsetX * self.uiScale
	buttonHighlight:setPosition(posX, nil)
end
function GameInfoDisplayMobile:updateInsets()
	self:setScale(self.uiScale)
end
function GameInfoDisplayMobile.getBackgroundPositionAndSize(scale)
	local offX, offY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.BACKGROUND))
	local _, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BACKGROUND))
	offX = offX * scale
	local leftInset, rightInset, _, _ = getSafeFrameInsets()
	leftInset = math.max(leftInset, offX)
	rightInset = math.max(rightInset, offX)
	local sizeX = 1 - leftInset - rightInset
	local posX = leftInset
	local posY = 1 + offY * scale - sizeY * scale
	return posX, posY, sizeX, sizeY
end
function GameInfoDisplayMobile.createBackground()
	local posX, posY, width, height = GameInfoDisplayMobile.getBackgroundPositionAndSize(1)
	local overlay = Overlay.new(nil, posX, posY, width, height)
	return overlay
end
GameInfoDisplayMobile.SIZE = { BACKGROUND = { 1251, 106 }, BUTTON = { 106, 106 }, BUTTON_HIGHLIGHT = { 114, 114 }, ICON = { 84, 84 }, BG_LEFT = { 38, 75 }, BG_RIGHT = { 38, 75 }, BG_MIDDLE = { 34, 75 }, WEATHER = { 493, 75 }, WEATHER_SEPARATOR = { 2, 65 }, MONTH_TEXT = 54, SEASON_ICON = { 65, 65 }, TIME_ICON = { 75, 75 }, TIME_TEXT = 54, MONEY = { 390, 75 }, MONEY_ICON = { 75, 75 }, MONEY_TEXT = 54, FUEL = { 262, 75 }, FUEL_ICON = { 75, 75 }, FUEL_TEXT = 54 }
GameInfoDisplayMobile.POSITION = { BG_LEFT = { 38, 75 }, BG_RIGHT = { 38, 75 }, BG_MIDDLE = { 34, 75 }, BUTTON_OFFSET = { -25, -35 }, MENU = { -25, -35 }, SHOP = { -25, -35 }, MAP = { -25, -35 }, HELP = { -25, -35 }, BUTTON_HIGHLIGHT = { -4, -4 }, WEATHER = { 0, -35 }, WEATHER_SEPARATOR = { 232, 5 }, SEASON_ICON = { 10, 5 }, MONTH_TEXT = { 93, 18 }, TIME_ICON = { 246, 0 }, TIME_TEXT = { 400, 18 }, TIME_TEXT_OFFSET = { 5, 0 }, MONEY = { 15, -35 }, MONEY_ICON = { 5, 0 }, MONEY_TEXT = { 370, 18 }, FUEL = { 15, -35 }, FUEL_ICON = { 15, 0 }, FUEL_TEXT = { 242, 18 }, BACKGROUND = { 55, -1 } }
GameInfoDisplayMobile.UV = { BUTTON_NORMAL = { 132, 908, 106, 106 }, BUTTON_PRESSED = { 238, 908, 106, 106 }, BUTTON_DISABLED = { 344, 908, 106, 106 }, BUTTON_HIGHLIGHT = { 801, 904, 114, 114 }, SHOP = { 576, 96, 96, 96 }, MENU = { 864, 0, 96, 96 }, MAP = { 480, 96, 96, 96 }, HELP = { 0, 288, 96, 96 }, BG_LEFT = { 454, 928, 38, 75 }, BG_RIGHT = { 526, 928, 38, 75 }, BG_MIDDLE = { 498, 928, 34, 75 }, SEASON_ICON = { [Season.SPRING] = { 960, 48, 48, 48 }, [Season.SUMMER] = { 960, 96, 48, 48 }, [Season.AUTUMN] = { 960, 144, 48, 48 }, [Season.WINTER] = { 960, 0, 48, 48 } }, TIME = { 384, 192, 96, 96 }, MONEY_ICON = { [GS_MONEY_DOLLAR] = { 480, 192, 96, 96 }, [GS_MONEY_POUND] = { 576, 192, 96, 96 }, [GS_MONEY_EURO] = { 672, 192, 96, 96 } }, FUEL_ICON = { ["DIESEL"] = { 288, 192, 96, 96 }, ["ELECTRICCHARGE"] = { 768, 192, 96, 96 }, ["METHANE"] = { 864, 192, 96, 96 } }, HORSE = { 192, 192, 96, 96 } }
GameInfoDisplayMobile.COLOR = { BACKGROUND = { 1, 1, 1, 0.5 }, SEPARATOR = { 1, 1, 1, 0.5 }, FUEL_EMPTY = { 0.5029, 0.0152, 0.0152, 1 } }
if data ~= nil then
	local gameInfoDisplay = GameInfoDisplayMobile.new(data.hud, data.hudAtlasPath, data.moneyUnit, data.controlHudAtlasPath)
	gameInfoDisplay:setVehicle(data.vehicle)
	gameInfoDisplay:setScale(data.uiScale)
	gameInfoDisplay:setMoneyUnit(data.moneyUnit)
	gameInfoDisplay:setMissionInfo(data.missionInfo)
	gameInfoDisplay:setEnvironment(data.environment)
	for k, elem in ipairs(g_currentMission.hud.displayComponents) do
		if elem == g_currentMission.hud.gameInfoDisplay then
			g_currentMission.hud.displayComponents[k] = gameInfoDisplay
			break
		end
	end
	g_currentMission.hud.gameInfoDisplay = gameInfoDisplay
	Logging.info("Reloaded")
end
