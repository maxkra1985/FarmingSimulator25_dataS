-- Local values: data, old, GameInfoDisplay_mt, gameInfoDisplay
local v1_
if GameInfoDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.gameInfoDisplay
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
GameInfoDisplay = {}
GameInfoDisplay.HELP_ANCHOR_MONEY = 1
GameInfoDisplay.HELP_ANCHOR_CALENDAR = 2
GameInfoDisplay.HELP_ANCHOR_WEATHER = 3
GameInfoDisplay.HELP_ANCHOR_CLOCK = 4
local data = Class(GameInfoDisplay, HUDDisplay)
function GameInfoDisplay.new()
	-- upvalues: (copy) data
	local v4_ = GameInfoDisplay:superClass().new(data)
	local v5_ = HUD.COLOR.ACTIVE
	local v6_ = 0
	local v7_ = 0
	local v8_ = 0
	local v9_ = 0.8
	v4_.moneyBgRight = g_overlayManager:createOverlay("gui.gameInfo_right", 0, 0, 0, 0)
	v4_.moneyBgRight:setColor(v6_, v7_, v8_, v9_)
	v4_.moneyBgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
	v4_.moneyBgScale:setColor(v6_, v7_, v8_, v9_)
	local v10_ = HUD.COLOR.BACKGROUND
	local v11_, v12_, v13_, v14_ = unpack(v10_)
	v4_.infoBgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
	v4_.infoBgScale:setColor(v11_, v12_, v13_, v14_)
	v4_.infoBgLeft = g_overlayManager:createOverlay("gui.gameInfo_left", 0, 0, 0, 0)
	v4_.infoBgLeft:setColor(v11_, v12_, v13_, v14_)
	v4_.calendarIcon = g_overlayManager:createOverlay("gui.icon_calendar", 0, 0, 0, 0)
	v4_.calendarIcon:setColor(v5_[1], v5_[2], v5_[3], v5_[4])
	v4_.weatherIcon = g_overlayManager:createOverlay("gui.icon_weather_sun", 0, 0, 0, 0)
	v4_.weatherIcon:setColor(v5_[1], v5_[2], v5_[3], v5_[4])
	v4_.weatherNextIcon = g_overlayManager:createOverlay("gui.icon_weather_sun", 0, 0, 0, 0)
	v4_.weatherNextIcon:setColor(1, 1, 1, 0.2)
	v4_.clockIcon = g_overlayManager:createOverlay("gui.icon_clock", 0, 0, 0, 0)
	v4_.clockIcon:setColor(v5_[1], v5_[2], v5_[3], v5_[4])
	v4_.clockHandHour = g_overlayManager:createOverlay("gui.clockhand_hour", 0, 0, 0, 0)
	v4_.clockHandHour:setColor(v5_[1], v5_[2], v5_[3], v5_[4])
	v4_.clockHandMinute = g_overlayManager:createOverlay("gui.clockhand_minute", 0, 0, 0, 0)
	v4_.clockHandMinute:setColor(v5_[1], v5_[2], v5_[3], v5_[4])
	v4_.fastForwardIcon = g_overlayManager:createOverlay("gui.fastforward", 0, 0, 0, 0)
	v4_.fastForwardIcon:setColor(v5_[1], v5_[2], v5_[3], v5_[4])
	v4_.fastForwardArrowIcon = g_overlayManager:createOverlay("gui.fastforward_arrow", 0, 0, 0, 0)
	v4_.fastForwardArrowIcon:setColor(0, 0, 0, 1)
	v4_.weatherSliceIds = {}
	v4_.weatherSliceIds[WeatherType.SUN] = "gui.icon_weather_sun"
	v4_.weatherSliceIds[WeatherType.PARTIALLY_CLOUDY] = "gui.icon_weather_partiallyCloudy"
	v4_.weatherSliceIds[WeatherType.CLOUDY] = "gui.icon_weather_cloudy"
	v4_.weatherSliceIds[WeatherType.RAIN] = "gui.icon_weather_rain"
	v4_.weatherSliceIds[WeatherType.SNOW] = "gui.icon_weather_snow"
	v4_.weatherSliceIds[WeatherType.HAIL] = "gui.icon_weather_hail"
	v4_.weatherSliceIds[WeatherType.TWISTER] = "gui.icon_weather_twister"
	v4_.weatherSliceIds[WeatherType.THUNDER] = "gui.icon_weather_thunder"
	return v4_
end

function GameInfoDisplay:delete()
	self.moneyBgRight:delete()
	self.moneyBgScale:delete()
	self.infoBgScale:delete()
	self.infoBgLeft:delete()
	self.calendarIcon:delete()
	self.weatherIcon:delete()
	self.weatherNextIcon:delete()
	self.clockIcon:delete()
	self.fastForwardIcon:delete()
	self.fastForwardArrowIcon:delete()
	self.clockHandHour:delete()
	self.clockHandMinute:delete()
	GameInfoDisplay:superClass().delete(self)
end

-- Local values: textSize, textOffsetY, moneyBgRightWidth, infoBgHeight, infoBgLeftWidth, calendarIconWidth, calendarIconHeight, weatherIconWidth, weatherIconHeight, weatherIconNextWidth, weatherIconNextHeight, clockIconWidth, clockIconHeight, clockHandHourWidth, clockHandHourHeight, clockHandMinuteWidth, clockHandMinuteHeight, fastForwardWidth, fastForwardHeight, fastForwardArrowWidth, fastForwardArrowHeight
function GameInfoDisplay:storeScaledValues()
	self:setPosition(g_hudAnchorRight, g_hudAnchorTop)
	self.helpAnchorOffsetY = self:scalePixelToScreenHeight(-80)
	local v17_, v18_ = self:scalePixelValuesToScreenVector(10, 65)
	self.moneyBgRight:setDimension(v17_, v18_)
	self.moneyBgScale:setDimension(0, v18_)
	self.moneyTextSize = self:scalePixelToScreenHeight(17)
	self.moneyTextSpacing = self:scalePixelToScreenWidth(20)
	local v19_, v20_ = self:scalePixelValuesToScreenVector(-20, 27)
	self.moneyTextOffsetX = v19_
	self.moneyTextOffsetY = v20_
	self.moneyHelpOffsetX = self:scalePixelToScreenWidth(-60)
	local v21_ = self:scalePixelToScreenWidth(10)
	self.infoBgScale:setDimension(0, v18_)
	self.infoBgLeft:setDimension(v21_, v18_)
	local v22_, v23_ = self:scalePixelValuesToScreenVector(48, 48)
	self.calendarIcon:setDimension(v22_, v23_)
	self.calendarIconOffsetY = self:scalePixelToScreenHeight(10)
	self.calendarTextSize = self:scalePixelToScreenHeight(17)
	self.calendarTextOffsetY = self:scalePixelToScreenHeight(27)
	self.calendarHelpOffsetX = self:scalePixelToScreenWidth(-60)
	local v24_, v25_ = self:scalePixelValuesToScreenVector(48, 48)
	self.weatherIcon:setDimension(v24_, v25_)
	self.weatherIconOffsetY = self:scalePixelToScreenHeight(8)
	local v26_, v27_ = self:scalePixelValuesToScreenVector(32, 32)
	self.weatherNextIcon:setDimension(v26_, v27_)
	local v28_, v29_ = self:scalePixelValuesToScreenVector(55, 8)
	self.weatherNextIconOffsetX = v28_
	self.weatherNextIconOffsetY = v29_
	self.weatherNextIconSpacing = self:scalePixelToScreenWidth(42)
	self.weatherHelpOffsetX = self:scalePixelToScreenWidth(-60)
	local v30_, v31_ = self:scalePixelValuesToScreenVector(48, 48)
	self.clockIcon:setDimension(v30_, v31_)
	local v32_, v33_ = self:scalePixelValuesToScreenVector(2, 8)
	self.clockHandHour:setDimension(v32_, v33_)
	local v34_, v35_ = self:scalePixelValuesToScreenVector(2, 12)
	self.clockHandMinute:setDimension(v34_, v35_)
	self.clockIconOffsetY = self:scalePixelToScreenHeight(8)
	self.clockTextSize = self:scalePixelToScreenHeight(17)
	self.clockTextOffsetY = self:scalePixelToScreenHeight(27)
	local v36_, v37_ = self:scalePixelValuesToScreenVector(10, 10)
	self.clockHandSmallX = v36_
	self.clockHandSmallY = v37_
	local v38_, v39_ = self:scalePixelValuesToScreenVector(23, 14)
	self.fastForwardIcon:setDimension(v38_, v39_)
	local v40_, v41_ = self:scalePixelValuesToScreenVector(6, 6)
	self.fastForwardArrowIcon:setDimension(v40_, v41_)
	local v42_, v43_ = self:scalePixelValuesToScreenVector(10, 26)
	self.fastForwardOffsetX = v42_
	self.fastForwardOffsetY = v43_
	local v44_, v45_ = self:scalePixelValuesToScreenVector(5, 27)
	self.fastForwardTextOffsetX = v44_
	self.fastForwardTextOffsetY = v45_
	self.fastForwardTextSize = self:scalePixelToScreenHeight(17)
	local v46_, v47_ = self:scalePixelValuesToScreenVector(9, 4)
	self.fastForwardArrowOffsetX = v46_
	self.fastForwardArrowOffsetY = v47_
	local v48_, v49_ = self:scalePixelValuesToScreenVector(6, 4)
	self.fastForwardArrow1OffsetX = v48_
	self.fastForwardArrow1OffsetY = v49_
	local v50_, v51_ = self:scalePixelValuesToScreenVector(13, 4)
	self.fastForwardArrow2OffsetX = v50_
	self.fastForwardArrow2OffsetY = v51_
	self.separatorWidth = self:scalePixelToScreenWidth(2)
	self.separatorHeight = self:scalePixelToScreenHeight(35)
	self.separatorOffsetY = self:scalePixelToScreenHeight(17)
	self.spacing = self:scalePixelToScreenWidth(20)
end

-- Local values: environment, posX, posY, activeColor, money, farm, moneyText, moneyCurrencyText, moneyTextWidth, moneyCurrencyTextWidth, scaleWidth, moneyTextPosX, moneyTextPosY, calendarText, calendarTextWidth, currentTime, timeHours, timeMinutes, clockText, clockTextWidth, timeScale, fastForwardText, fastForwardTextWidth, sixHours, dayPlus6h, timePlus6h, weatherState, nextWeatherState, nextWeatherOffset, gameInfoTotalWidth, separatorPosX, separatorPosY, separatorPosYEnd, hourRotation, minutesRotation, clockHandPosX, clockHandPosY, fastForwardPosX, arrowPosX, arrowPosY, arrowPosX, arrowPosY
function GameInfoDisplay:draw()
	GameInfoDisplay:superClass().draw(self)
	local v53_ = g_currentMission.environment
	local v54_, v55_ = self:getPosition()
	local v56_ = v55_ - self.moneyBgRight.height
	local v57_ = HUD.COLOR.ACTIVE
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	setTextColor(1, 1, 1, 1)
	local v58_ = g_localPlayer == nil and 0 or g_farmManager:getFarmById(g_localPlayer.farmId).money
	local v59_ = g_i18n:formatMoney(v58_, 0, false, true)
	local v60_ = g_i18n:getCurrencySymbol(true)
	local v61_ = getTextWidth(self.moneyTextSize, v59_)
	local v62_ = getTextWidth(self.moneyTextSize, v60_)
	self.moneyBgRight:setPosition(v54_ - self.moneyBgRight.width, v56_)
	self.moneyBgRight:render()
	local v63_ = v61_ + v62_ + 2 * self.moneyTextSpacing - self.moneyBgRight.width
	self.moneyBgScale:setDimension(v63_, nil)
	self.moneyBgScale:setPosition(self.moneyBgRight.x - self.moneyBgScale.width, v56_)
	self.moneyBgScale:render()
	self.helpOffsetXMoney = self.moneyBgScale.x + self.moneyBgScale.width * 0.5
	local v64_ = v54_ + self.moneyTextOffsetX
	local v65_ = v56_ + self.moneyTextOffsetY
	renderText(v64_, v65_, self.moneyTextSize, v59_)
	setTextColor(v57_[1], v57_[2], v57_[3], v57_[4])
	local v66_ = v64_ - v61_
	renderText(v66_, v65_, self.moneyTextSize, v60_)
	local v67_ = utf8ToUpper(g_i18n:formatDayInPeriod(nil, nil, true))
	local v68_ = getTextWidth(self.calendarTextSize, v67_)
	local v69_ = v53_.dayTime / 3600000
	local v70_ = math.floor(v69_)
	local v71_ = (v69_ - v70_) * 60
	local v72_ = math.floor(v71_)
	local v73_ = string.format("%02d:%02d", v70_, v72_)
	local v74_ = getTextWidth(self.clockTextSize, v73_)
	local v75_ = g_currentMission:getEffectiveTimeScale()
	local v76_
	if v75_ < 1 then
		v76_ = string.format("%0.1f", v75_)
	else
		v76_ = string.format("%d", v75_)
	end
	local v77_ = getTextWidth(self.fastForwardTextSize, v76_)
	local v78_, v79_ = v53_:getDayAndDayTime(v53_.dayTime + 21600000, v53_.currentMonotonicDay)
	local v80_ = v53_.weather:getCurrentWeatherType()
	local v81_ = v53_.weather:getNextWeatherType(v78_, v79_)
	if v80_ ~= self.lastWeatherState then
		self.lastWeatherState = v80_
		self.weatherIcon:setSliceId(self.weatherSliceIds[v80_])
	end
	if v81_ ~= self.lastNextWeatherState then
		self.lastNextWeatherState = v81_
		self.weatherNextIcon:setSliceId(self.weatherSliceIds[v81_])
	end
	local v82_ = v80_ == v81_ and 0 or self.weatherNextIconSpacing
	local v83_ = self.calendarIcon.width + self.weatherIcon.width + v82_ + self.clockIcon.width + self.fastForwardIcon.width + self.fastForwardOffsetX + self.fastForwardTextOffsetX + 6 * self.spacing + 2 * self.separatorWidth + v68_ + v74_ + v77_
	self.infoBgScale:setDimension(v83_ - self.infoBgLeft.width, nil)
	self.infoBgScale:setPosition(self.moneyBgScale.x - self.infoBgScale.width, v56_)
	self.infoBgScale:render()
	self.infoBgLeft:setPosition(self.infoBgScale.x - self.infoBgLeft.width, v56_)
	self.infoBgLeft:render()
	self.weatherIcon:setPosition(self.infoBgLeft.x + self.spacing, v56_ + self.weatherIconOffsetY)
	self.weatherIcon:render()
	self.helpOffsetXWeather = self.infoBgLeft.x + self.spacing + self.weatherIcon.width * 0.5
	if v80_ ~= v81_ then
		self.weatherNextIcon:setPosition(self.weatherIcon.x + self.weatherNextIconOffsetX, self.weatherIcon.y + self.weatherNextIconOffsetY)
		self.weatherNextIcon:render()
	end
	local v84_ = v82_ + self.weatherIcon.x + self.weatherIcon.width + self.spacing
	local v85_ = v56_ + self.separatorOffsetY
	local v86_ = v56_ + self.separatorOffsetY + self.separatorHeight
	drawLine2D(v84_, v85_, v84_, v86_, self.separatorWidth, 1, 1, 1, 0.2)
	self.calendarIcon:setPosition(v84_ + self.spacing, v56_ + self.calendarIconOffsetY)
	self.calendarIcon:render()
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	renderText(self.calendarIcon.x + self.calendarIcon.width, v56_ + self.calendarTextOffsetY, self.calendarTextSize, v67_)
	self.helpOffsetXCalendar = self.calendarIcon.x + self.calendarIcon.width + v68_ * 0.5
	local v87_ = self.calendarIcon.x + self.calendarIcon.width + v68_ + self.spacing
	drawLine2D(v87_, v85_, v87_, v86_, self.separatorWidth, 1, 1, 1, 0.2)
	self.clockIcon:setPosition(v87_ + self.spacing, v56_ + self.clockIconOffsetY)
	self.clockIcon:render()
	local v88_ = -(v69_ % 12 / 12) * 3.141592653589793 * 2
	local v89_ = -(v69_ - v70_) * 3.141592653589793 * 2
	local v90_ = self.clockIcon.x + self.clockIcon.width * 0.5
	local v91_ = self.clockIcon.y + self.clockIcon.height * 0.5
	self.clockHandMinute:setPosition(v90_, v91_)
	self.clockHandMinute:setRotation(v89_, self.clockHandMinute.width * 0.5, 0)
	self.clockHandMinute:render()
	self.clockHandHour:setPosition(v90_, v91_)
	self.clockHandHour:setRotation(v88_, self.clockHandHour.width * 0.5, 0)
	self.clockHandHour:render()
	self.helpOffsetXClock = self.clockIcon.x + self.clockIcon.width + v74_ * 0.5
	renderText(self.clockIcon.x + self.clockIcon.width, v56_ + self.clockTextOffsetY, self.clockTextSize, v73_)
	local v92_ = self.clockIcon.x + self.clockIcon.width + v74_ + self.fastForwardOffsetX
	self.fastForwardIcon:setPosition(v92_, v56_ + self.fastForwardOffsetY)
	self.fastForwardIcon:render()
	if v75_ > 1 then
		local v93_ = self.fastForwardIcon.x + self.fastForwardArrow1OffsetX
		local v94_ = self.fastForwardIcon.y + self.fastForwardArrow1OffsetY
		self.fastForwardArrowIcon:setPosition(v93_, v94_)
		self.fastForwardArrowIcon:render()
		local v95_ = self.fastForwardIcon.x + self.fastForwardArrow2OffsetX
		local v96_ = self.fastForwardIcon.y + self.fastForwardArrow2OffsetY
		self.fastForwardArrowIcon:setPosition(v95_, v96_)
		self.fastForwardArrowIcon:render()
	else
		local v97_ = self.fastForwardIcon.x + self.fastForwardArrowOffsetX
		local v98_ = self.fastForwardIcon.y + self.fastForwardArrowOffsetY
		self.fastForwardArrowIcon:setPosition(v97_, v98_)
		self.fastForwardArrowIcon:render()
	end
	renderText(self.fastForwardIcon.x + self.fastForwardIcon.width + self.fastForwardTextOffsetX, v56_ + self.fastForwardTextOffsetY, self.fastForwardTextSize, v76_)
	setTextBold(false)
end

-- Local values: posX, posY
function GameInfoDisplay:getHelpAnchorPosition(typeId)
	local v101_, v102_ = self:getPosition()
	if typeId == GameInfoDisplay.HELP_ANCHOR_MONEY then
		v101_ = self.helpOffsetXMoney
	elseif typeId == GameInfoDisplay.HELP_ANCHOR_CALENDAR then
		v101_ = self.helpOffsetXCalendar
	elseif typeId == GameInfoDisplay.HELP_ANCHOR_CLOCK then
		v101_ = self.helpOffsetXClock
	elseif typeId == GameInfoDisplay.HELP_ANCHOR_WEATHER then
		v101_ = self.helpOffsetXWeather
	end
	return v101_ or 0, v102_ + self.helpAnchorOffsetY
end
if v1_ ~= nil then
	local v103_ = GameInfoDisplay.new()
	v103_:setScale(v1_.uiScale)
	v103_:setVisible(v1_.isVisible)
	g_currentMission.hud.gameInfoDisplay = v103_
	g_currentMission.hud.displayComponents.gameInfoDisplay = v103_
	Logging.info("Reloaded")
end
