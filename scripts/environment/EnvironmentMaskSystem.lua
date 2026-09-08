-- Local values: EnvironmentMaskSystem_mt
EnvironmentMaskSystem = {}
EnvironmentMaskSystem.VISIBILITY_CONDITION_FLAGS_XML_PATH = "shared/visibilityConditionFlags.xml"
local EnvironmentMaskSystem_mt = Class(EnvironmentMaskSystem)

-- Upvalues: EnvironmentMaskSystem_mt
-- Local values: self, xmlFile, _, weatherFlagKey, _, weatherFlagKey, lightsProfile
function EnvironmentMaskSystem.new(mission, customMt)
	-- upvalues: (copy) EnvironmentMaskSystem_mt
	local v4_ = customMt or EnvironmentMaskSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.mission = mission
	v5_.weatherMaskModifiers = {}
	v5_.weatherFlagNameToModifier = {}
	v5_.viewerSpatialityMaskModifiers = {}
	v5_.viewerSpatialityFlagNameToModifier = {}
	v5_.isDebugViewActive = false
	v5_.minuteOfDay = 0
	v5_.dayOfYear = 1
	v5_.weatherMask = 0
	v5_.viewerSpatialityMask = 0
	local v6_ = XMLFile.load("visibilityConditionFlagsXml", EnvironmentMaskSystem.VISIBILITY_CONDITION_FLAGS_XML_PATH)
	for _, v7_ in v6_:iterator("visibilityConditionFlags.weatherFlags.flag") do
		v5_:registerWeatherMaskModifier(v6_:getString(v7_ .. "#name"), v6_:getInt(v7_ .. "#bit"))
	end
	v5_.setWeatherSun = v5_:getWeatherModifierUpdateFuncFromFlagName("SUN")
	v5_.setWeatherRain = v5_:getWeatherModifierUpdateFuncFromFlagName("RAIN")
	v5_.setWeatherHail = v5_:getWeatherModifierUpdateFuncFromFlagName("HAIL")
	v5_.setWeatherSnow = v5_:getWeatherModifierUpdateFuncFromFlagName("SNOW")
	v5_.setWeatherCloudy = v5_:getWeatherModifierUpdateFuncFromFlagName("CLOUDY")
	v5_.setIsDay = v5_:getWeatherModifierUpdateFuncFromFlagName("DAY")
	v5_.setIsNight = v5_:getWeatherModifierUpdateFuncFromFlagName("NIGHT")
	v5_.setIsSpring = v5_:getWeatherModifierUpdateFuncFromFlagName("SPRING")
	v5_.setIsSummer = v5_:getWeatherModifierUpdateFuncFromFlagName("SUMMER")
	v5_.setIsAutumn = v5_:getWeatherModifierUpdateFuncFromFlagName("AUTUMN")
	v5_.setIsWinter = v5_:getWeatherModifierUpdateFuncFromFlagName("WINTER")
	for _, v8_ in v6_:iterator("visibilityConditionFlags.viewerSpatialityFlags.flag") do
		v5_:registerViewerSpatialityMaskModifier(v6_:getString(v8_ .. "#name"), v6_:getInt(v8_ .. "#bit"))
	end
	v5_.setIsInterior = v5_:getViewerSpatialityModifierUpdateFuncFromFlagName("INTERIOR")
	v5_.setIsExterior = v5_:getViewerSpatialityModifierUpdateFuncFromFlagName("EXTERIOR")
	v5_.setInVehicle = v5_:getViewerSpatialityModifierUpdateFuncFromFlagName("IN_VEHICLE")
	v5_.setOutVehicle = v5_:getViewerSpatialityModifierUpdateFuncFromFlagName("OUT_VEHICLE")
	v5_.setIndoor = v5_:getViewerSpatialityModifierUpdateFuncFromFlagName("INDOOR")
	v5_:onLightsProfileChanged((g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)))
	v6_:delete()
	g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, v5_.onWeatherChanged, v5_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.LIGHTS_PROFILE], v5_.onLightsProfileChanged, v5_)
	g_messageCenter:subscribe(MessageType.OWN_PLAYER_ENTERED, v5_.onPlayerEntered, v5_)
	g_messageCenter:subscribe(MessageType.OWN_PLAYER_LEFT, v5_.onPlayerLeft, v5_)
	addConsoleCommand("gsEnvironmentMaskSystemToggleDebugView", "Toggles the environment mask system debug view", "consoleCommandToggleDebugView", v5_)
	return v5_
end

function EnvironmentMaskSystem:delete()
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsEnvironmentMaskSystemToggleDebugView")
end

function EnvironmentMaskSystem:update(dt)
	setEnvironmentSettings(self.minuteOfDay + 1, self.dayOfYear, self.weatherMask, self.viewerSpatialityMask)
end

-- Local values: posY, textSize, textOffset, _, modifier, isActive, _, modifier, isActive
function EnvironmentMaskSystem:drawDebug()
	if self.isDebugViewActive then
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.4, 0.72, getCorrectTextSize(0.014), "Environment State")
		renderText(0.6, 0.72, getCorrectTextSize(0.014), "Weather Mask:")
		renderText(0.7, 0.72, getCorrectTextSize(0.014), "Viewer Spatiality Mask:")
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v12_ = getCorrectTextSize(0.012)
		local v13_ = getCorrectTextSize(0.001)
		local v14_ = 0.7
		for _, v15_ in ipairs(self.weatherMaskModifiers) do
			local v16_ = self.weatherMask
			local v17_ = v15_.bitflag
			local v18_ = bit32.band(v16_, v17_) ~= 0
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.6, v14_, v12_, v15_.name .. ":  ")
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.6, v14_, v12_, (tostring(v18_)))
			v14_ = v14_ - v12_ - v13_
		end
		local v19_ = 0.7
		for _, v20_ in ipairs(self.viewerSpatialityMaskModifiers) do
			local v21_ = self.viewerSpatialityMask
			local v22_ = v20_.bitflag
			local v23_ = bit32.band(v21_, v22_) ~= 0
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.7, v19_, v12_, v20_.name .. ":  ")
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.7, v19_, v12_, (tostring(v23_)))
			v19_ = v19_ - v12_ - v13_
		end
		local v24_ = 0.7
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.4, v24_ - (v12_ + v13_) * 0, v12_, "MinuteOfDay:  ")
		renderText(0.4, v24_ - (v12_ + v13_) * 1, v12_, "DayOfYear:  ")
		renderText(0.4, v24_ - (v12_ + v13_) * 2, v12_, "WeatherMask:  ")
		renderText(0.4, v24_ - (v12_ + v13_) * 3, v12_, "ViewerSpatialityMask:  ")
		local v25_ = 0.7
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v26_ = renderText
		local v27_ = v25_ - (v12_ + v13_) * 0
		local v28_ = self.minuteOfDay
		v26_(0.4, v27_, v12_, (tostring(v28_)))
		local v29_ = renderText
		local v30_ = v25_ - (v12_ + v13_) * 1
		local v31_ = self.dayOfYear
		v29_(0.4, v30_, v12_, (tostring(v31_)))
		local v32_ = renderText
		local v33_ = v25_ - (v12_ + v13_) * 2
		local v34_ = self.weatherMask
		v32_(0.4, v33_, v12_, (tostring(v34_)))
		local v35_ = renderText
		local v36_ = v25_ - (v12_ + v13_) * 3
		local v37_ = self.viewerSpatialityMask
		v35_(0.4, v36_, v12_, (tostring(v37_)))
	end
end

function EnvironmentMaskSystem:setDayTime(dayTime)
	local v40_ = dayTime / 1000 / 60
	self.minuteOfDay = math.floor(v40_)
end

function EnvironmentMaskSystem:setDayOfYear(dayOfYear, season)
	self.dayOfYear = math.clamp(dayOfYear, 0, 365)
	self.setIsSpring(season == Season.SPRING)
	self.setIsSummer(season == Season.SUMMER)
	self.setIsAutumn(season == Season.AUTUMN)
	self.setIsWinter(season == Season.WINTER)
end

-- Local values: typeIndex
function EnvironmentMaskSystem:onWeatherChanged(weatherObject)
	local v46_ = weatherObject.weatherType
	self.setWeatherSun(v46_ == WeatherType.SUN)
	self.setWeatherRain(v46_ == WeatherType.RAIN)
	self.setWeatherHail(v46_ == WeatherType.HAIL)
	self.setWeatherSnow(v46_ == WeatherType.SNOW)
	self.setWeatherCloudy(v46_ == WeatherType.CLOUDY)
end

-- Local values: lightsProfileLow, lightsProfileHigh
function EnvironmentMaskSystem:onLightsProfileChanged(lightsProfile)
	self:getViewerSpatialityModifierUpdateFuncFromFlagName("LIGHTS_PROFILE_LOW")(lightsProfile < GS_PROFILE_HIGH)
	self:getViewerSpatialityModifierUpdateFuncFromFlagName("LIGHTS_PROFILE_HIGH")(GS_PROFILE_HIGH <= lightsProfile)
end

function EnvironmentMaskSystem:setIsSunOn(isSunOn)
	self.setIsDay(isSunOn)
	self.setIsNight(not isSunOn)
end

function EnvironmentMaskSystem:setIsIndoor(isIndoor)
	self.setIndoor(isIndoor)
end

function EnvironmentMaskSystem:onPlayerEntered()
	self.setInVehicle(false)
	self.setOutVehicle(true)
end

function EnvironmentMaskSystem:onPlayerLeft()
	self.setInVehicle(true)
	self.setOutVehicle(false)
end

-- Local values: name, bitflag, _, modifier, modifier
function EnvironmentMaskSystem:registerWeatherMaskModifier(modifierName, bit)
	local v58_ = string.upper(modifierName)
	local v59_ = 2 ^ bit
	for _, v60_ in ipairs(self.weatherMaskModifiers) do
		if v60_.name == v58_ then
			Logging.error("Weather mask modifier name \'%s\' already used", modifierName)
			return false
		end
		if v60_.bitflag == v59_ then
			Logging.error("Weather mask modifier \'%s\' bit \'%d\' already used for modifier \'%s\'", modifierName, bit, v60_.name)
			return false
		end
	end
	local v_u_69_ = {
		["name"] = v58_,
		["bitflag"] = v59_,
		["updateFunc"] = function(p61_)
			-- upvalues: (copy) self, (copy) v_u_69_
			if p61_ then
				local v62_ = self
				local v63_ = self.weatherMask
				local v64_ = v_u_69_.bitflag
				v62_.weatherMask = bit32.bor(v63_, v64_)
			else
				local v65_ = self
				local v66_ = self.weatherMask
				local v67_ = v_u_69_.bitflag
				local v68_ = bit32.bnot(v67_)
				v65_.weatherMask = bit32.band(v66_, v68_)
			end
		end
	}
	local v70_ = self.weatherMaskModifiers
	table.insert(v70_, v_u_69_)
	self.weatherFlagNameToModifier[v_u_69_.name] = v_u_69_
	return v_u_69_.updateFunc
end

-- Local values: name, bitflag, _, modifier, modifier
function EnvironmentMaskSystem:registerViewerSpatialityMaskModifier(modifierName, bit)
	local v74_ = string.upper(modifierName)
	local v75_ = 2 ^ bit
	for _, v76_ in ipairs(self.viewerSpatialityMaskModifiers) do
		if v76_.name == v74_ then
			Logging.error("Given viewer spatiality mask modifier name \'%s\' already used", modifierName)
			return false
		end
		if v76_.bitflag == v75_ then
			Logging.error("Viewer spatiality mask modifier \'%s\' bit \'%d\' already used for modifier \'%s\'", modifierName, bit, v76_.name)
			return false
		end
	end
	local v_u_85_ = {
		["name"] = v74_,
		["bitflag"] = v75_,
		["updateFunc"] = function(p77_)
			-- upvalues: (copy) self, (copy) v_u_85_
			if p77_ then
				local v78_ = self
				local v79_ = self.viewerSpatialityMask
				local v80_ = v_u_85_.bitflag
				v78_.viewerSpatialityMask = bit32.bor(v79_, v80_)
			else
				local v81_ = self
				local v82_ = self.viewerSpatialityMask
				local v83_ = v_u_85_.bitflag
				local v84_ = bit32.bnot(v83_)
				v81_.viewerSpatialityMask = bit32.band(v82_, v84_)
			end
		end
	}
	local v86_ = self.viewerSpatialityMaskModifiers
	table.insert(v86_, v_u_85_)
	self.viewerSpatialityFlagNameToModifier[v_u_85_.name] = v_u_85_
	return v_u_85_.updateFunc
end

-- Local values: modifier
function EnvironmentMaskSystem:getWeatherModifierUpdateFuncFromFlagName(flagName)
	local v89_ = self.weatherFlagNameToModifier[flagName]
	if v89_ ~= nil and v89_.updateFunc ~= nil then
		return v89_.updateFunc
	end
	Logging.error("No weather modifier registered for \'%s\'. Using empty update function", flagName)
	return function() end
end

-- Local values: modifier
function EnvironmentMaskSystem:getViewerSpatialityModifierUpdateFuncFromFlagName(flagName)
	local v92_ = self.viewerSpatialityFlagNameToModifier[flagName]
	if v92_ ~= nil and v92_.updateFunc ~= nil then
		return v92_.updateFunc
	end
	Logging.error("No viewer spatiality modifier registered for \'%s\'. Using empty update function", flagName)
	return function() end
end

function EnvironmentMaskSystem:getWeatherMaskFromFlagName(flagName)
	return self.weatherFlagNameToModifier[string.upper(flagName)]
end

-- Local values: mask, _, flagName, modifier
function EnvironmentMaskSystem:getWeatherMaskFromFlagNames(flagNames)
	if flagNames == nil or flagNames == "" then
		return nil
	end
	local v97_ = 0
	for _, v98_ in pairs(string.split(string.upper(flagNames), " ")) do
		local v99_ = self.weatherFlagNameToModifier[v98_]
		if v99_ == nil then
			Logging.error("Unknown weather flag \'%s\'. Available flags: %s", v98_, table.concatKeys(self.weatherFlagNameToModifier, " "))
		else
			local v100_ = v99_.bitflag
			v97_ = bit32.bor(v97_, v100_)
		end
	end
	return v97_
end

function EnvironmentMaskSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive
	if self.isDebugViewActive then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
end
