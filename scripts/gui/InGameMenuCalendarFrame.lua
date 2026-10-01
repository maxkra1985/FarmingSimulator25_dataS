InGameMenuCalendarFrame = {}
local InGameMenuCalendarFrame_mt = Class(InGameMenuCalendarFrame, TabbedMenuFrameElement)
InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE = 1
InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE = 2
InGameMenuCalendarFrame.BLOCK_COLORS = { [false] = { [InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = { 0.22323, 0.40724, 0.00368, 1 }, [InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = { 0.53328, 0.06301, 0.00335, 1 } }, [true] = { [InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = { 0.2122, 0.1779, 0.0027, 0.95 }, [InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = { 0.3372, 0.4397, 0.9911, 0.95 } } }
function InGameMenuCalendarFrame.register()
	local inGameMenuCalendarFrame = InGameMenuCalendarFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuCalendarFrame.xml", "CalendarFrame", inGameMenuCalendarFrame, true)
end
function InGameMenuCalendarFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuCalendarFrame_mt)
	self.isColorBlindMode = false
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0
	self.fruitTypes = {}
	self.calendarHeader = {}
	self.clonedElements = {}
	return self
end
function InGameMenuCalendarFrame.createFromExistingGui(gui, guiName)
	local newGui = InGameMenuCalendarFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function InGameMenuCalendarFrame:delete()
	if self.fruitRowTemplate ~= nil then
		self.fruitRowTemplate:delete()
	end
	for _, clonedElement in pairs(self.clonedElements) do
		clonedElement:delete()
	end
	self.separatorBigTemplate:delete()
	self.separatorTemplate:delete()
	self.monthTextTemplate:delete()
	InGameMenuCalendarFrame:superClass().delete(self)
end
function InGameMenuCalendarFrame:initialize()
	InGameMenuCalendarFrame:superClass().initialize(self)
	self.separatorBigTemplate:unlinkElement()
	self.separatorTemplate:unlinkElement()
	self.monthTextTemplate:unlinkElement()
	FocusManager:removeElement(self.separatorBigTemplate)
	FocusManager:removeElement(self.separatorTemplate)
	FocusManager:removeElement(self.monthTextTemplate)
	self.separatorBigTemplate:clone(self.tableHeaderBox)
	local clonedText = nil
	local clonedSeparator = nil
	for i = 1, 12 do
		clonedText = self.monthTextTemplate:clone(self.tableHeaderBox)
		table.insert(self.clonedElements, clonedText)
		self.calendarHeader[i] = clonedText
		if i % 3 == 0 then
			clonedSeparator = self.separatorBigTemplate:clone(self.tableHeaderBox)
		else
			clonedSeparator = self.separatorTemplate:clone(self.tableHeaderBox)
		end
		table.insert(self.clonedElements, clonedSeparator)
	end
	self.tableHeaderBox:invalidateLayout()
end
function InGameMenuCalendarFrame:onFrameOpen()
	InGameMenuCalendarFrame:superClass().onFrameOpen(self)
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	self:rebuildTable()
	self:updateTodayBar()
	self:setPeriodTitles()
	self:updateLegend()
	g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
	FocusManager:setFocus(self.slider)
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.onTemperatureUnitChanged, self)
	if g_currentMission ~= nil then
		self.forecast = g_currentMission.environment.weather.forecast
	end
	self:reloadWeatherData()
end
function InGameMenuCalendarFrame:onFrameClose()
	g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self)
	g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
	g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self)
	InGameMenuCalendarFrame:superClass().onFrameClose(self)
end
function InGameMenuCalendarFrame:updateTodayBar()
	local env = g_currentMission.environment
	local season = env.currentSeason - 1
	local intoSeason = (env.currentDayInSeason - 1) / env:getDaysPerSeason()
	local percentage = season * 0.25 + intoSeason * 0.25
	local parentSize = self.todayBar.parent.size[1]
	self.todayBar:setPosition(parentSize * percentage + parentSize / (env:getDaysPerSeason() * 4) * 0.5, nil)
end
function InGameMenuCalendarFrame:setPeriodTitles()
	for i = 1, 12 do
		local element = self.calendarHeader[i]
		element:setText(g_i18n:formatPeriod(i, true))
	end
end
function InGameMenuCalendarFrame:updateLegend()
	self.legendPlantingSeason:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]))
	self.legendHarvestSeason:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]))
	self.legendHarvestSeason.parent:invalidateLayout()
end
function InGameMenuCalendarFrame:rebuildTable()
	self.fruitTypes = {}
	for _, fruitDesc in pairs(g_fruitTypeManager:getFruitTypes()) do
		if fruitDesc.shownOnMap then
			table.insert(self.fruitTypes, fruitDesc)
		end
	end
	table.sort(self.fruitTypes, function(a, b)
		local fillTypeA = g_fruitTypeManager:getFillTypeByFruitTypeIndex(a.index)
		local fillTypeB = g_fruitTypeManager:getFillTypeByFruitTypeIndex(b.index)
		return fillTypeA.title < fillTypeB.title
	end)
	self.calendar:reloadData()
end
function InGameMenuCalendarFrame:reloadWeatherData()
	self.forecastHourlyList:reloadData()
	self.forecastDailyList:reloadData()
	self:updateTodayView()
end
function InGameMenuCalendarFrame:updateTodayView()
	local now = self.forecast:getCurrentWeather()
	self.nowTemperature:setValue(now.temperature)
	self.nowWindSpeed:setValue(self:meterPerSecondToBeaufort(now.windSpeed))
	self.nowWeatherIcon:setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[now.forecastType])
	local period = g_currentMission.environment.currentPeriod
	local dayInPeriod = g_currentMission.environment.currentDayInPeriod
	self.nowWeatherMonth:setText(g_i18n:formatDayInPeriod(dayInPeriod, period, false))
	local dir = self.nowWindDirection
	if Platform.isMobile then
		local profile = self:getWindDirectionIconProfileByAngle(now.windDirection)
		dir:applyProfile(profile)
	else
		dir:setImageRotation(math.rad(now.windDirection) + 3.141592653589793)
	end
end
function InGameMenuCalendarFrame:getNumberOfItemsInSection(list, section)
	if list == self.calendar then
		return #self.fruitTypes
	elseif self.forecast == nil then
		return 0
	elseif list == self.forecastHourlyList then
		return 12
	else
		return 6
	end
end
function InGameMenuCalendarFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.calendar then
		local fruitDesc = self.fruitTypes[index]
		local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitDesc.index)
		cell:getAttribute("fruitIcon"):setImageFilename(fillType.hudOverlayFilename)
		cell:getAttribute("fruitName"):setText(fillType.title)
		cell:getAttribute("fruitPlanting2"):setVisible(false)
		cell:getAttribute("fruitHarvesting2"):setVisible(false)
		local plantElementIndex = 1
		local harvestElementIndex = 1
		local plantStart = nil
		local plantEnd = nil
		local harvestStart = nil
		local harvestEnd = nil
		local growthMode = g_currentMission.missionInfo.growthMode
		for i = 1, 12 do
			plantStart = plantStart == nil and fruitDesc:getIsPlantableInPeriod(growthMode, i) and i or plantStart
			if plantStart ~= nil and not isPlantable then
				local _v128 = i - 1 or plantEnd
			end
			plantEnd = plantEnd
			if i == 12 then
				plantEnd = 12
			end
			if plantStart ~= nil and plantEnd ~= nil then
				local plantElement = cell:getAttribute("fruitPlanting" .. plantElementIndex)
				plantElement:setSize(self.calendarHeader[plantEnd].absPosition[1] - self.calendarHeader[plantStart].absPosition[1] + self.calendarHeader[plantStart].absSize[1])
				plantElement:setPosition(self.calendarHeader[plantStart].absPosition[1] - self.calendar.absPosition[1])
				plantElement:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]))
				plantElement:setVisible(true)
				plantStart = nil
				plantEnd = nil
				plantElementIndex = 2
			end
			harvestStart = harvestStart == nil and fruitDesc:getIsHarvestableInPeriod(growthMode, i) and i or harvestStart
			if harvestStart ~= nil and not isHarvestable then
				local _v204 = i - 1 or harvestEnd
			end
			harvestEnd = harvestEnd
			if i == 12 then
				harvestEnd = 12
			end
			if harvestStart == nil or harvestEnd == nil then
				continue
			end
			local harvestElement = cell:getAttribute("fruitHarvesting" .. harvestElementIndex)
			harvestElement:setSize(self.calendarHeader[harvestEnd].absPosition[1] - self.calendarHeader[harvestStart].absPosition[1] + self.calendarHeader[harvestStart].absSize[1])
			harvestElement:setPosition(self.calendarHeader[harvestStart].absPosition[1] - self.calendar.absPosition[1])
			harvestElement:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]))
			harvestElement:setVisible(true)
			harvestStart = nil
			harvestEnd = nil
			harvestElementIndex = 2
		end
	elseif list == self.forecastHourlyList then
		local forecastInfo = self.forecast:getHourlyForecast((index - 1) * 2)
		if forecastInfo ~= nil then
			local timeHours = math.floor(forecastInfo.time / 3600000 + 0.0001)
			cell:getAttribute("icon"):setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[forecastInfo.forecastType])
			cell:getAttribute("time"):setText(string.format("%02d:00", timeHours))
			cell:getAttribute("temperature"):setValue(forecastInfo.temperature)
			cell:getAttribute("windSpeed"):setValue(self:meterPerSecondToBeaufort(forecastInfo.windSpeed))
			if Platform.isMobile then
				local profile = self:getWindDirectionIconProfileByAngle(forecastInfo.windDirection)
				cell:getAttribute("windDirection"):applyProfile(profile)
			else
				cell:getAttribute("windDirection"):setImageRotation(math.rad(forecastInfo.windDirection) + 3.141592653589793)
			end
		end
	else
		local forecastInfo = g_currentMission.environment.weather.forecast:getDailyForecast(index)
		local period = g_currentMission.environment:getPeriodFromDay(forecastInfo.day)
		local dayInPeriod = g_currentMission.environment:getDayInPeriodFromDay(forecastInfo.day)
		cell:getAttribute("day"):setText(g_i18n:formatDayInPeriod(dayInPeriod, period, true))
		cell:getAttribute("icon"):setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[forecastInfo.forecastType])
		cell:getAttribute("highTemperature"):setValue(forecastInfo.highTemperature)
		cell:getAttribute("lowTemperature"):setValue(forecastInfo.lowTemperature)
	end
end
function InGameMenuCalendarFrame:meterPerSecondToBeaufort(mps)
	return math.floor(math.pow(math.ceil(mps) / 0.836, 0.6666666666666666))
end
function InGameMenuCalendarFrame:getWindDirectionIconProfileByAngle(angle)
	angle = MathUtil.snapValue(angle % 360, 45)
	return InGameMenuCalendarFrame.WIND_DIRECTION_PROFILES[angle]
end
function InGameMenuCalendarFrame:onDayChanged()
	self:updateTodayBar()
	self:reloadWeatherData()
end
function InGameMenuCalendarFrame:onHourChanged()
	self:reloadWeatherData()
end
function InGameMenuCalendarFrame:onTemperatureUnitChanged()
	self:updateTodayView()
end
function InGameMenuCalendarFrame:setColorBlindMode(isActive)
	if self.isColorBlindMode ~= isActive then
		self.isColorBlindMode = isActive
		self:rebuildTable()
		self:updateLegend()
	end
end
function InGameMenuCalendarFrame:draw()
	InGameMenuCalendarFrame:superClass().draw(self)
	drawDashedLine(self.todayBar.absPosition[1], self.todayBar.absPosition[2] + self.todayBar.absSize[2], self.todayBar.absSize[1], self.todayBar.absSize[2], -7 * g_pixelSizeY, -6 * g_pixelSizeY, 1, 1, 1, 1, false)
end
InGameMenuCalendarFrame.ICON_SLICES = { [WeatherType.SUN] = "gui.icon_weather_sun", [WeatherType.PARTIALLY_CLOUDY] = "gui.icon_weather_partiallyCloudy", [WeatherType.CLOUDY] = "gui.icon_weather_cloudy", [WeatherType.RAIN] = "gui.icon_weather_rain", [WeatherType.SNOW] = "gui.icon_weather_snow", [WeatherType.HAIL] = "gui.icon_weather_hail", [WeatherType.THUNDER] = "gui.icon_weather_thunder", [WeatherType.TWISTER] = "gui.icon_weather_twister" }
InGameMenuCalendarFrame.WIND_DIRECTION_PROFILES = { [0] = "ingameMenuWeatherWindIndicatorIcon", [45] = "ingameMenuWeatherWindIndicatorIcon45", [90] = "ingameMenuWeatherWindIndicatorIcon90", [135] = "ingameMenuWeatherWindIndicatorIcon135", [180] = "ingameMenuWeatherWindIndicatorIcon180", [225] = "ingameMenuWeatherWindIndicatorIcon225", [270] = "ingameMenuWeatherWindIndicatorIcon270", [315] = "ingameMenuWeatherWindIndicatorIcon315" }
