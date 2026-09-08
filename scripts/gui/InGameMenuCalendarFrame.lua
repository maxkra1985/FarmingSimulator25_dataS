-- Local values: InGameMenuCalendarFrame_mt
InGameMenuCalendarFrame = {}
local InGameMenuCalendarFrame_mt = Class(InGameMenuCalendarFrame, TabbedMenuFrameElement)
InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE = 1
InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE = 2
local v2_ = InGameMenuCalendarFrame
local v3_ = {
	[false] = {
		[InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = {
			0.22323,
			0.40724,
			0.00368,
			1
		},
		[InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = {
			0.53328,
			0.06301,
			0.00335,
			1
		}
	},
	[true] = {
		[InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = {
			0.2122,
			0.1779,
			0.0027,
			0.95
		},
		[InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = {
			0.3372,
			0.4397,
			0.9911,
			0.95
		}
	}
}
v2_.BLOCK_COLORS = v3_
function InGameMenuCalendarFrame.register()
	local v4_ = InGameMenuCalendarFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuCalendarFrame.xml", "CalendarFrame", v4_, true)
end

-- Upvalues: InGameMenuCalendarFrame_mt
-- Local values: self
function InGameMenuCalendarFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuCalendarFrame_mt
	local v7_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuCalendarFrame_mt)
	v7_.isColorBlindMode = false
	v7_.scrollInputDelay = 0
	v7_.scrollInputDelayDir = 0
	v7_.fruitTypes = {}
	v7_.calendarHeader = {}
	v7_.clonedElements = {}
	return v7_
end

-- Local values: newGui
function InGameMenuCalendarFrame.createFromExistingGui(gui, guiName)
	local v10_ = InGameMenuCalendarFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v10_, true)
	return v10_
end

-- Local values: _, clonedElement
function InGameMenuCalendarFrame:delete()
	if self.fruitRowTemplate ~= nil then
		self.fruitRowTemplate:delete()
	end
	for _, v12_ in pairs(self.clonedElements) do
		v12_:delete()
	end
	self.separatorBigTemplate:delete()
	self.separatorTemplate:delete()
	self.monthTextTemplate:delete()
	InGameMenuCalendarFrame:superClass().delete(self)
end

-- Local values: clonedText, clonedSeparator, i
function InGameMenuCalendarFrame:initialize()
	InGameMenuCalendarFrame:superClass().initialize(self)
	self.separatorBigTemplate:unlinkElement()
	self.separatorTemplate:unlinkElement()
	self.monthTextTemplate:unlinkElement()
	FocusManager:removeElement(self.separatorBigTemplate)
	FocusManager:removeElement(self.separatorTemplate)
	FocusManager:removeElement(self.monthTextTemplate)
	self.separatorBigTemplate:clone(self.tableHeaderBox)
	for v14_ = 1, 12 do
		local v15_ = self.monthTextTemplate:clone(self.tableHeaderBox)
		local v16_ = self.clonedElements
		table.insert(v16_, v15_)
		self.calendarHeader[v14_] = v15_
		local v17_
		if v14_ % 3 == 0 then
			v17_ = self.separatorBigTemplate:clone(self.tableHeaderBox)
		else
			v17_ = self.separatorTemplate:clone(self.tableHeaderBox)
		end
		local v18_ = self.clonedElements
		table.insert(v18_, v17_)
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

-- Local values: env, season, intoSeason, percentage, parentSize
function InGameMenuCalendarFrame:updateTodayBar()
	local v22_ = g_currentMission.environment
	local v23_ = v22_.currentSeason - 1
	local v24_ = (v22_.currentDayInSeason - 1) / v22_:getDaysPerSeason()
	local v25_ = v23_ * 0.25 + v24_ * 0.25
	local v26_ = self.todayBar.parent.size[1]
	self.todayBar:setPosition(v26_ * v25_ + v26_ / (v22_:getDaysPerSeason() * 4) * 0.5, nil)
end

-- Local values: i, element
function InGameMenuCalendarFrame:setPeriodTitles()
	for v28_ = 1, 12 do
		self.calendarHeader[v28_]:setText(g_i18n:formatPeriod(v28_, true))
	end
end

function InGameMenuCalendarFrame:updateLegend()
	local v30_ = self.legendPlantingSeason
	local v31_ = InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]
	v30_:setImageColor(nil, unpack(v31_))
	local v32_ = self.legendHarvestSeason
	local v33_ = InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]
	v32_:setImageColor(nil, unpack(v33_))
	self.legendHarvestSeason.parent:invalidateLayout()
end

-- Local values: _, fruitDesc
function InGameMenuCalendarFrame:rebuildTable()
	self.fruitTypes = {}
	for _, v35_ in pairs(g_fruitTypeManager:getFruitTypes()) do
		if v35_.shownOnMap then
			local v36_ = self.fruitTypes
			table.insert(v36_, v35_)
		end
	end
	table.sort(self.fruitTypes, function(p37_, p38_)
		local v39_ = g_fruitTypeManager:getFillTypeByFruitTypeIndex(p37_.index)
		local v40_ = g_fruitTypeManager:getFillTypeByFruitTypeIndex(p38_.index)
		return v39_.title < v40_.title
	end)
	self.calendar:reloadData()
end

function InGameMenuCalendarFrame:reloadWeatherData()
	self.forecastHourlyList:reloadData()
	self.forecastDailyList:reloadData()
	self:updateTodayView()
end

-- Local values: now, period, dayInPeriod, dir, profile
function InGameMenuCalendarFrame:updateTodayView()
	local v43_ = self.forecast:getCurrentWeather()
	self.nowTemperature:setValue(v43_.temperature)
	self.nowWindSpeed:setValue(self:meterPerSecondToBeaufort(v43_.windSpeed))
	self.nowWeatherIcon:setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[v43_.forecastType])
	local v44_ = g_currentMission.environment.currentPeriod
	local v45_ = g_currentMission.environment.currentDayInPeriod
	self.nowWeatherMonth:setText(g_i18n:formatDayInPeriod(v45_, v44_, false))
	local v46_ = self.nowWindDirection
	if Platform.isMobile then
		v46_:applyProfile((self:getWindDirectionIconProfileByAngle(v43_.windDirection)))
	else
		local v47_ = v43_.windDirection
		v46_:setImageRotation(math.rad(v47_) + 3.141592653589793)
	end
end

function InGameMenuCalendarFrame:getNumberOfItemsInSection(list, section)
	return list == self.calendar and #self.fruitTypes or (self.forecast == nil and 0 or (list == self.forecastHourlyList and 12 or 6))
end

-- Local values: fruitDesc, fillType, plantElementIndex, harvestElementIndex, plantStart, plantEnd, harvestStart, harvestEnd, growthMode, i, isPlantable, plantElement, isHarvestable, harvestElement, forecastInfo, timeHours, profile, forecastInfo, period, dayInPeriod
function InGameMenuCalendarFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.calendar then
		local v54_ = self.fruitTypes[index]
		local v55_ = g_fruitTypeManager:getFillTypeByFruitTypeIndex(v54_.index)
		cell:getAttribute("fruitIcon"):setImageFilename(v55_.hudOverlayFilename)
		cell:getAttribute("fruitName"):setText(v55_.title)
		cell:getAttribute("fruitPlanting2"):setVisible(false)
		cell:getAttribute("fruitHarvesting2"):setVisible(false)
		local v56_ = g_currentMission.missionInfo.growthMode
		local v57_ = nil
		local v58_ = 1
		local v59_ = nil
		local v60_ = nil
		local v61_ = 1
		local v62_ = nil
		for v63_ = 1, 12 do
			local v64_ = v54_:getIsPlantableInPeriod(v56_, v63_)
			if v57_ == nil and (v64_ and v63_) then
				v57_ = v63_
			end
			if v57_ ~= nil and not v64_ then
				v59_ = v63_ - 1 or v59_
			end
			v59_ = v63_ == 12 and 12 or v59_
			if v57_ ~= nil and v59_ ~= nil then
				local v65_ = cell:getAttribute("fruitPlanting" .. v58_)
				v65_:setSize(self.calendarHeader[v59_].absPosition[1] - self.calendarHeader[v57_].absPosition[1] + self.calendarHeader[v57_].absSize[1])
				v65_:setPosition(self.calendarHeader[v57_].absPosition[1] - self.calendar.absPosition[1])
				local v66_ = InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]
				v65_:setImageColor(nil, unpack(v66_))
				v65_:setVisible(true)
				v57_ = nil
				v58_ = 2
				v59_ = nil
			end
			local v67_ = v54_:getIsHarvestableInPeriod(v56_, v63_)
			if v62_ == nil and (v67_ and v63_) then
				v62_ = v63_
			end
			if v62_ ~= nil and not v67_ then
				v60_ = v63_ - 1 or v60_
			end
			v60_ = v63_ == 12 and 12 or v60_
			if v62_ ~= nil and v60_ ~= nil then
				local v68_ = cell:getAttribute("fruitHarvesting" .. v61_)
				v68_:setSize(self.calendarHeader[v60_].absPosition[1] - self.calendarHeader[v62_].absPosition[1] + self.calendarHeader[v62_].absSize[1])
				v68_:setPosition(self.calendarHeader[v62_].absPosition[1] - self.calendar.absPosition[1])
				local v69_ = InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]
				v68_:setImageColor(nil, unpack(v69_))
				v68_:setVisible(true)
				v60_ = nil
				v61_ = 2
				v62_ = nil
			end
		end
	elseif list == self.forecastHourlyList then
		local v70_ = self.forecast:getHourlyForecast((index - 1) * 2)
		if v70_ ~= nil then
			local v71_ = v70_.time / 3600000 + 0.0001
			local v72_ = math.floor(v71_)
			cell:getAttribute("icon"):setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[v70_.forecastType])
			cell:getAttribute("time"):setText(string.format("%02d:00", v72_))
			cell:getAttribute("temperature"):setValue(v70_.temperature)
			cell:getAttribute("windSpeed"):setValue(self:meterPerSecondToBeaufort(v70_.windSpeed))
			if Platform.isMobile then
				local v73_ = self:getWindDirectionIconProfileByAngle(v70_.windDirection)
				cell:getAttribute("windDirection"):applyProfile(v73_)
			else
				local v74_ = cell:getAttribute("windDirection")
				local v75_ = v70_.windDirection
				v74_:setImageRotation(math.rad(v75_) + 3.141592653589793)
			end
		end
	else
		local v76_ = g_currentMission.environment.weather.forecast:getDailyForecast(index)
		local v77_ = g_currentMission.environment:getPeriodFromDay(v76_.day)
		local v78_ = g_currentMission.environment:getDayInPeriodFromDay(v76_.day)
		cell:getAttribute("day"):setText(g_i18n:formatDayInPeriod(v78_, v77_, true))
		cell:getAttribute("icon"):setImageSlice(nil, InGameMenuCalendarFrame.ICON_SLICES[v76_.forecastType])
		cell:getAttribute("highTemperature"):setValue(v76_.highTemperature)
		cell:getAttribute("lowTemperature"):setValue(v76_.lowTemperature)
	end
end

function InGameMenuCalendarFrame:meterPerSecondToBeaufort(mps)
	local v80_ = math.ceil(mps) / 0.836
	local v81_ = math.pow(v80_, 0.6666666666666666)
	return math.floor(v81_)
end

function InGameMenuCalendarFrame:getWindDirectionIconProfileByAngle(angle)
	local v83_ = MathUtil.snapValue(angle % 360, 45)
	return InGameMenuCalendarFrame.WIND_DIRECTION_PROFILES[v83_]
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
InGameMenuCalendarFrame.ICON_SLICES = {
	[WeatherType.SUN] = "gui.icon_weather_sun",
	[WeatherType.PARTIALLY_CLOUDY] = "gui.icon_weather_partiallyCloudy",
	[WeatherType.CLOUDY] = "gui.icon_weather_cloudy",
	[WeatherType.RAIN] = "gui.icon_weather_rain",
	[WeatherType.SNOW] = "gui.icon_weather_snow",
	[WeatherType.HAIL] = "gui.icon_weather_hail",
	[WeatherType.THUNDER] = "gui.icon_weather_thunder",
	[WeatherType.TWISTER] = "gui.icon_weather_twister"
}
InGameMenuCalendarFrame.WIND_DIRECTION_PROFILES = {
	[0] = "ingameMenuWeatherWindIndicatorIcon",
	[45] = "ingameMenuWeatherWindIndicatorIcon45",
	[90] = "ingameMenuWeatherWindIndicatorIcon90",
	[135] = "ingameMenuWeatherWindIndicatorIcon135",
	[180] = "ingameMenuWeatherWindIndicatorIcon180",
	[225] = "ingameMenuWeatherWindIndicatorIcon225",
	[270] = "ingameMenuWeatherWindIndicatorIcon270",
	[315] = "ingameMenuWeatherWindIndicatorIcon315"
}
