I18N = {}
local I18N_mt = Class(I18N)
I18N.L10N_FILES_DIRECTORY = "dataS/l10n/"
I18N.MONEY_MAX_DISPLAY_VALUE = 999999999
I18N.MONEY_MIN_DISPLAY_VALUE = -999999999
g_xmlManager:addEarlyCreateSchemaFunction(function()
	I18N.xmlSchema = XMLSchema.new("l18n")
	I18N.registerXMLPaths(I18N.xmlSchema)
end)
function I18N.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.FLOAT, "l10n.fluid#factor", "", 1)
	xmlSchema:register(XMLValueType.FLOAT, "l10n.power#factor", "", 1)
	local baseKey = "l10n.elements.e(?)"
	xmlSchema:register(XMLValueType.STRING, "l10n.elements.e(?)" .. "#k", "The name of the string", nil)
	xmlSchema:register(XMLValueType.STRING, "l10n.elements.e(?)" .. "#v", "The text of the string", nil)
end
function I18N.new()
	local self = setmetatable({}, I18N_mt)
	self.texts = {}
	self.modEnvironments = {}
	if g_addTestCommands then
		addConsoleCommand("gsI18nVerify", "Checks all localization files for empty or 'TODO' texts, warns if placeholders mismatch between languages", "consoleCommandVerifyAll", self, "[ignoreTodos=false]; [l10nDir]; [l10nFilePrefix]")
	end
	self.debugActive = StartParams.getIsSet("debugI18N")
	if self.debugActive then
		print("debugI18N active")
		if not StartParams.getIsSet("scriptDebug") then
			Logging.devWarning("'-debugI18N' start parameter should only be used in combination with '-scriptDebug' start parameter")
		end
		self.usedTexts = {}
		self.printedWarnings = {}
		self:loadUsedKeysFromXML()
		addConsoleCommand("gsI18nSaveUsedKeysXml", "", "saveUsedKeysToXML", self)
		g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN, self.saveUsedKeysToXML, self)
		g_messageCenter:subscribe(MessageType.GUI_MAIN_SCREEN_OPEN, self.saveUsedKeysToXML, self)
	end
	return self
end
function I18N:load()
	self.texts = {}
	if not g_isDevelopmentVersion and g_languageShort ~= "en" then
		local baseXMLFile = XMLFile.load("l10n_en", I18N.L10N_FILES_DIRECTORY .. "l10n_en.xml")
		self:loadEntriesFromXML(baseXMLFile, self.texts, true)
		baseXMLFile:delete()
	end
	local xmlFile = XMLFile.load("l10n" .. g_languageSuffix, I18N.L10N_FILES_DIRECTORY .. "l10n" .. g_languageSuffix .. ".xml")
	self:loadEntriesFromXML(xmlFile, self.texts, true)
	self:mergePlatformText(self.texts)
	self.fluidFactor = xmlFile:getFloat("l10n.fluid#factor", 1)
	self.powerFactorHP = xmlFile:getFloat("l10n.power#factor", 1)
	self.powerFactorKW = 0.735499
	self.moneyUnit = GS_MONEY_EURO
	self.useMiles = false
	self.useFahrenheit = false
	self.useAcre = false
	xmlFile:delete()
	self.thousandsGroupingChar = self:getText("unit_digitGroupingSymbol")
	if self.thousandsGroupingChar ~= " " and (self.thousandsGroupingChar ~= "." and self.thousandsGroupingChar ~= ",") then
		self.thousandsGroupingChar = " "
	end
	self.decimalSeparator = self:getText("unit_decimalSymbol") or "."
	if g_gameSettings ~= nil then
		self.moneyUnit = g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT)
		self.useMiles = g_gameSettings:getValue(GameSettings.SETTING.USE_MILES)
		self.useFahrenheit = g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT)
		self.useAcre = g_gameSettings:getValue(GameSettings.SETTING.USE_ACRE)
	end
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.setMoneyUnit, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.setUseMiles, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_ACRE], self.setUseAcre, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.setUseFahrenheit, self)
end
function I18N:delete()
	g_messageCenter:unsubscribeAll(self)
end
function I18N:loadFromXMLFile(xmlFilename)
	self.texts = {}
	local xmlFile = XMLFile.load("l10n", xmlFilename)
	self:loadEntriesFromXML(xmlFile, self.texts, false)
	xmlFile:delete()
end
function I18N:loadEntriesFromXML(xmlFile, outputEntries, overwriteExistingText)
	for nodeIndex, nodeKey in xmlFile:iterator("l10n.elements.e") do
		local name = xmlFile:getString(nodeKey .. "#k")
		if string.isNilOrWhitespace(name) then
			Logging.xmlWarning(xmlFile, "Node at path %q is missing a name (k attribute)", nodeKey)
		elseif outputEntries[name] == nil or overwriteExistingText then
			local text = xmlFile:getString(nodeKey .. "#v")
			if string.isNilOrWhitespace(text) then
				Logging.xmlWarning(xmlFile, "Node at path %q is missing a text (v attribute)", nodeKey)
			else
				if string.trim(utf8ToUpper(text)) == "TODO" then
					text = "TODO:" .. name
					if self.debugActive and self.printedWarnings[name] == nil then
						Logging.devWarning("TODO text set for loca key '%s' in %q", name, xmlFile:getFilename())
						self.printedWarnings[name] = true
					end
				end
				outputEntries[name] = string.gsub(text, "\r\n", "\n")
			end
		end
	end
end
function I18N:mergePlatformText(texts)
	for key, text in pairs(texts) do
		for _, postfix in ipairs(Platform.l10nPostfixes) do
			local postfixKey = key .. postfix
			if texts[postfixKey] ~= nil then
				texts[key] = texts[postfixKey]
				break
			end
		end
		if texts[key] == text then
			continue
		end
		Logging.devInfo("I18N platform specific text %s: '%s'", key, texts[key])
	end
end
function I18N:saveUsedKeysToXML()
	local fileName = getUserProfileAppPath() .. "l10n_usedKeys.xml"
	local xmlFile = createXMLFile("l10n_usedKeys", fileName, "l10n")
	if xmlFile == 0 then
		Logging.error("Failed to create l10n_usedKeys xml file")
	else
		local usedCount = 0
		for key in pairs(self.usedTexts) do
			setXMLString(xmlFile, string.format("l10n.used(%d)#k", usedCount), key)
			usedCount = usedCount + 1
		end
		saveXMLFile(xmlFile)
		delete(xmlFile)
		local textsCount = table.size(self.texts)
		local unusedCount = textsCount - usedCount
		print(string.format("I18N debug: saved '%s': %i unused, %i used, %i total keys ", fileName, unusedCount, usedCount, textsCount))
	end
end
function I18N:loadUsedKeysFromXML()
	local fileName = getUserProfileAppPath() .. "l10n_usedKeys.xml"
	local xmlFile = XMLFile.loadIfExists("l10n_usedKeys", fileName)
	if xmlFile then
		xmlFile:iterate("l10n.used", function(_, key)
			self.usedTexts[xmlFile:getString(key .. "#k")] = true
		end)
		print(string.format("I18N debug: loaded '%s': %i used keys ", fileName, table.size(self.usedTexts)))
		xmlFile:delete()
	else
		Logging.devWarning("I18N debug: Unable to load used loca keys file %s", fileName)
	end
end
function I18N:addModI18N(modName)
	local modi18n = {}
	modi18n.texts = {}
	setmetatable(modi18n, { __index = self })
	setmetatable(modi18n.texts, { __index = self.texts })
	self.modEnvironments[modName] = modi18n
	function modi18n.setText(i18nInstance, name, value)
		i18nInstance.texts[name] = value
	end
	function modi18n.hasModText(i18nInstance, name)
		return i18nInstance.texts[name] ~= nil
	end
	function modi18n.setGlobalText(i18nInstance, name, value)
		name = modName .. "." .. name
		if self.texts[name] == nil then
			self.texts[name] = value
		end
	end
	return modi18n
end
function I18N:getText(name, customEnv)
	local ret = nil
	if customEnv ~= nil then
		local modEnv = self.modEnvironments[customEnv]
		if modEnv ~= nil then
			ret = modEnv.texts[name]
		end
	end
	if ret == nil then
		ret = self.texts[name]
		if ret == nil then
			ret = string.format("Missing '%s' in l10n%s.xml", name, g_languageSuffix)
			if g_showDevelopmentWarnings then
				Logging.devWarning(ret)
			end
		end
	end
	return ret
end
function I18N:hasText(name, customEnv)
	if name == nil then
		return false
	else
		local ret = nil
		if customEnv ~= nil then
			local modEnv = self.modEnvironments[customEnv]
			if modEnv ~= nil then
				ret = modEnv.texts[name]
			end
		end
		if ret == nil then
			ret = self.texts[name]
		end
		return ret ~= nil
	end
end
function I18N:setText(name, value)
	self.texts[name] = value
end
function I18N:setMoneyUnit(unit)
	self.moneyUnit = unit
end
function I18N:setUseMiles(useMiles)
	self.useMiles = useMiles
end
function I18N:setUseFahrenheit(useFahrenheit)
	self.useFahrenheit = useFahrenheit
end
function I18N:setUseAcre(useAcre)
	self.useAcre = useAcre
end
function I18N:getCurrency(currency)
	return currency * self:getCurrencyFactor()
end
function I18N:getCurrencyFactor()
	if self.moneyUnit == GS_MONEY_EURO then
		return 1
	elseif self.moneyUnit == GS_MONEY_POUND then
		return 0.79
	else
		return 1.34
	end
end
function I18N:getMeasuringUnit(useLongName)
	local postfix = "Short"
	if useLongName then
		postfix = ""
	end
	if self.useMiles then
		return self.texts["unit_miles" .. postfix]
	else
		return self.texts["unit_km" .. postfix]
	end
end
function I18N:getVolumeUnit(useLongName)
	local postfix = not useLongName and "Short" or ""
	return self.texts["unit_liter" .. postfix]
end
function I18N:getVolume(liters)
	return liters
end
function I18N:getSpeedMeasuringUnit()
	if self.useMiles then
		return self.texts.unit_mph
	else
		return self.texts.unit_kmh
	end
end
function I18N:getSpeed(speedKmh)
	if self.useMiles then
		return speedKmh * 0.62137
	else
		return speedKmh
	end
end
function I18N:getTemperature(temperatureCelsius)
	if self.useFahrenheit then
		return temperatureCelsius * 1.8 + 32
	else
		return temperatureCelsius
	end
end
function I18N:formatTemperature(temperatureCelsius, precision, useLongName)
	local temperature = self:getTemperature(temperatureCelsius)
	local str = self:getTemperatureUnit(useLongName)
	return string.format("%1." .. (precision or 0) .. "f%s", temperature, str)
end
function I18N:getTemperatureUnit(useLongName)
	local postfix = "Short"
	if useLongName then
		postfix = ""
	end
	if self.useFahrenheit then
		return self.texts["unit_fahrenheit" .. postfix]
	else
		return self.texts["unit_celsius" .. postfix]
	end
end
function I18N:getAreaUnit(useLongName)
	local postfix = "Short"
	if useLongName then
		postfix = ""
	end
	if self.useAcre then
		return self.texts["unit_acre" .. postfix]
	else
		return self.texts["unit_ha" .. postfix]
	end
end
function I18N:getArea(ha)
	if self.useAcre then
		return ha * 2.4711
	else
		return ha
	end
end
function I18N:formatArea(areaInHa, precision, useLongName)
	local area = self:getArea(areaInHa)
	local str = self:getAreaUnit(useLongName)
	return MathUtil.round(area, precision) .. " " .. str
end
function I18N:getDistanceUnit(useLongName)
	local postfix = "Short"
	if useLongName then
		postfix = ""
	end
	if self.useMiles then
		return self.texts["unit_ft" .. postfix]
	else
		return self.texts["unit_m" .. postfix]
	end
end
function I18N:getDistance(distance, isDistanceInMeter)
	if self.useMiles then
		if isDistanceInMeter then
			return distance * 3.28084
		else
			return distance * 0.62137
		end
	end
	return distance
end
function I18N:formatDistance(distanceInMeter, precision, useLongName)
	local distance = self:getDistance(distanceInMeter, true)
	local str = self:getDistanceUnit(useLongName)
	return MathUtil.round(distance, precision) .. " " .. str
end
function I18N:getFluid(fluid)
	return fluid * self.fluidFactor
end
function I18N:formatFluid(liters)
	return string.format("%s %s", self:formatNumber(self:getFluid(liters)), g_i18n:getText("unit_literShort"))
end
function I18N:formatVolume(liters, precision, unit)
	return string.format("%s %s", self:formatNumber(self:getVolume(liters), precision), unit or self:getVolumeUnit())
end
function I18N:formatMass(mass, maxMass, showKg)
	local unit = "unit_tonsShort"
	local precision = 1
	if showKg ~= false and mass < 1 then
		if maxMass == nil or maxMass == 0 then
			unit = "unit_kg"
			mass = mass * 1000
			precision = 0
		else
			if mass < 1 and (maxMass ~= nil and maxMass ~= 0) then
				unit = "unit_kg"
				mass = mass * 1000
				maxMass = maxMass * 1000
				precision = 0
			end
		end
	end
	if maxMass ~= nil and maxMass ~= 0 then
		return string.format("%s-%s %s", self:formatNumber(MathUtil.round(mass, precision), precision), self:formatNumber(MathUtil.round(maxMass, precision), precision), g_i18n:getText(unit))
	end
	return string.format("%s %s", self:formatNumber(MathUtil.round(mass, precision), precision), g_i18n:getText(unit))
end
function I18N:getPower(power)
	return power * self.powerFactorHP, power * self.powerFactorKW
end
function I18N:formatNumber(number, precision, forcePrecision)
	if number == math.huge then
		return "inf"
	elseif number == -math.huge then
		return "-inf"
	else
		precision = precision or 0
		if precision == 0 then
			if number == nil then
				printCallstack()
			end
			if number < 0 then
				number = math.ceil(number)
			else
				number = math.floor(number)
			end
		end
		local baseString = tostring(MathUtil.round(number, precision))
		local prefix, thousandsPart, decimalPart = string.match(baseString, "^([^%d]*%d)(%d*)[.]?(%d*)")
		if thousandsPart == nil then
			printCallstack()
			error(string.format("I18N:formatNumber: unable to split string %q (number %q)", baseString, tostring(number)))
		end
		local thousandsPartReversed = string.reverse(thousandsPart)
		thousandsPartReversed = string.gsub(thousandsPartReversed, "(%d%d%d)", "%1" .. self.thousandsGroupingChar)
		local formattedNumber = prefix .. string.reverse(thousandsPartReversed)
		if 0 < precision and (0 < string.len(decimalPart) and (forcePrecision or tonumber(decimalPart) ~= 0)) then
			formattedNumber = formattedNumber .. self.decimalSeparator .. string.sub(decimalPart, 1, precision)
		end
		return formattedNumber
	end
end
function I18N:formatMoney(number, precision, addCurrency, prefixCurrencySymbol)
	local clampedDisplayMoney = math.clamp(number, I18N.MONEY_MIN_DISPLAY_VALUE, I18N.MONEY_MAX_DISPLAY_VALUE)
	local currencyString = self:formatNumber(clampedDisplayMoney, precision)
	if addCurrency == nil or addCurrency then
		if prefixCurrencySymbol == nil or not prefixCurrencySymbol then
			currencyString = currencyString .. "\194\160" .. self:getCurrencySymbol(true)
			return currencyString
		end
		currencyString = self:getCurrencySymbol(true) .. "\194\160" .. currencyString
	end
	return currencyString
end
function I18N:getCurrencySymbol(useShort)
	local postFix = ""
	if useShort then
		postFix = "Short"
	end
	if self.moneyUnit == GS_MONEY_EURO then
		return self:getText("unit_euro" .. postFix)
	elseif self.moneyUnit == GS_MONEY_POUND then
		return self:getText("unit_pound" .. postFix)
	else
		return self:getText("unit_dollar" .. postFix)
	end
end
function I18N:convertText(textOrKey, customEnv)
	if textOrKey == nil then
		Logging.warning("Text to convert is nil")
		printCallstack()
		return nil
	else
		if string.startsWith(textOrKey, "$l10n_") then
			textOrKey = g_i18n:getText(string.sub(textOrKey, 7), customEnv)
		end
		return textOrKey
	end
end
function I18N:insertTextParams(text, paramsStr, customEnvironment, xmlFile)
	local _, count = string.gsub(text, "%%s", "")
	local params = string.split(paramsStr, "|")
	if #params == count then
		for i = 1, #params do
			params[i] = self:convertText(params[i], customEnvironment)
		end
		text = string.format(text, unpack(params))
		return text
	elseif xmlFile ~= nil then
		Logging.xmlWarning(xmlFile, "Unable to insert parameters into text. Invalid number of params. (%d found in string '%s', %d params given in '%s')", count, text, #params, paramsStr)
		return text
	else
		Logging.warning("Unable to insert parameters into text. Invalid number of params. (%d found in string '%s', %d params given in '%s')", count, text, #params, paramsStr)
		return text
	end
end
function I18N:getCurrentDate()
	if g_languageShort == "en" then
		return getDate("%Y-%m-%d")
	elseif g_languageShort == "de" then
		return getDate("%d.%m.%Y")
	elseif g_languageShort == "jp" then
		return getDate("%Y/%m/%d")
	else
		return getDate("%d/%m/%Y")
	end
end
function I18N:consoleCommandVerifyAll(ignoreTodos, l10nDir, l10nFilePrefix)
	ignoreTodos = Utils.stringToBoolean(ignoreTodos)
	l10nDir = l10nDir or I18N.L10N_FILES_DIRECTORY
	l10nFilePrefix = l10nFilePrefix or "l10n_"
	self:verifyLocaFiles(ignoreTodos, l10nDir, l10nFilePrefix)
end
function I18N:verifyLocaFiles(ignoreTodos, l10nDir, l10nFilePrefix)
	print("Verifying i18n files:")
	setFileLogPrefixTimestamp(false)
	if ignoreTodos then
		printWarning("Warning: Ignoring 'TODO' and '' texts")
	end
	local formatsFromString = function(str)
		local result = ""
		local capturePattern = "%%%d?%.?%d*%a"
		for formatIdentifier, _ in str:gmatch("%%%d?%.?%d*%a") do
			result = result .. formatIdentifier
		end
		if result == "" then
			return nil
		else
			local _, count = str:gsub("%%", "")
			return result, count % 2
		end
	end
	local langToKeys = {}
	local allKeysSet = {}
	local masterLang = nil
	print("loading lang files")
	local numL = getNumOfLanguages()
	for langIndex = 0, numL - 1 do
		local code = getLanguageCode(langIndex)
		local filenameShort = l10nFilePrefix .. code .. ".xml"
		if code == "en" then
			masterLang = filenameShort
		end
		local xmlFilename = l10nDir .. filenameShort
		if fileExists(xmlFilename) then
			local keys = {}
			local xmlFile = XMLFile.load("l10n" .. g_languageSuffix, xmlFilename)
			self:loadEntriesFromXML(xmlFile, keys)
			xmlFile:delete()
			self:mergePlatformText(keys)
			langToKeys[filenameShort] = keys
			for key, _ in pairs(keys) do
				allKeysSet[key] = true
			end
			print(string.format("loaded %d entries from %s", table.size(keys), xmlFilename))
		else
			printWarning(string.format("Warning: unable to find xml file %s for langIndex %d", xmlFilename, langIndex))
		end
	end
	if next(langToKeys) == nil then
		return "Error: no l10n entries were loaded"
	else
		for key, _ in pairs(allKeysSet) do
			for lang, keys in pairs(langToKeys) do
				local text = keys[key]
				if text == nil then
					printWarning(string.format("Warning: Missing text for %s in %s", key, lang))
				else
					if ignoreTodos then
						continue
					end
					if text:trim() == "" or text:find("TODO") then
						printWarning(string.format("Warning: Empty or todo text for %s in %s", key, lang))
					end
				end
			end
		end
		local enFormatStrings = {}
		for key, text in pairs(langToKeys[masterLang]) do
			local result = ""
			local capturePattern = "%%%d?%.?%d*%a"
			for formatIdentifier, _ in text:gmatch("%%%d?%.?%d*%a") do
				result = result .. formatIdentifier
			end
			if result == "" then
				local formatString = nil
				local count = nil
			else
				local _, count = text:gsub("%%", "")
				formatString = result
				count = count % 2
			end
			if formatString == nil then
				continue
			end
			enFormatStrings[key] = { formatString, count }
			local _, num = string.gsub(formatString, "%%", "")
			if 1 < num then
				printError(string.format("Error: Multiple unnamed format specifiers (%s) in %q", formatString, key))
			end
		end
		for lang, keys in pairs(langToKeys) do
			if lang == masterLang then
				continue
			end
			print(lang)
			for key, text in pairs(keys) do
				getTextHeight(1, text)
				local result = ""
				local capturePattern = "%%%d?%.?%d*%a"
				for formatIdentifier, _ in text:gmatch("%%%d?%.?%d*%a") do
					result = result .. formatIdentifier
				end
				if result == "" then
					local formatStringText = nil
					local countText = nil
				else
					local _, count = text:gsub("%%", "")
					formatStringText = result
					countText = count % 2
				end
				local formatStringEn = enFormatStrings[key] and enFormatStrings[key][1]
				local countEn = enFormatStrings[key] and enFormatStrings[key][2]
				if formatStringText then
					local upperText = utf8ToUpper(text)
					if upperText ~= "TODO" then
						local enText = langToKeys[masterLang][key]
						if formatStringText ~= formatStringEn then
							printError(string.format("Error: Mismatching format strings for key '%s' in %s: '%s' <-> '%s'", key, lang, formatStringEn or "no placeholder", formatStringText or "no placeholder"))
							print(string.format("    %s: %s", masterLang, enText))
							print(string.format("    %s: %s", lang, text))
						end
						if countText ~= countEn then
							printError(string.format("Error: Mismatching '%%' characters (possible unescaped '%%') for key '%s' in %s", key, lang))
							print(string.format("    %s: %s", masterLang, enText))
							print(string.format("    %s: %s", lang, text))
						end
					end
					if enFormatStrings[key] then
						local tryStringFormat = function()
							string.format(text, 1, 2, 3, 4, 5, 6, 7, 8, 9)
						end
						if pcall(tryStringFormat) then
							continue
						end
						local enText = langToKeys[masterLang][key]
						printError(string.format("Error: String format cannot be applied on string '%s' in %s:\n    en: '%s'\n<->\n    %s: '%s'", key, lang, enText, lang, text))
					end
				end
			end
		end
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		return "Verified all i18n files"
	end
end
function I18N:formatMinutes(minutes)
	if minutes ~= nil then
		local hours = math.floor(minutes / 60)
		local mins = minutes - hours * 60
		return string.format(self:getText("ui_hours"), hours, mins)
	else
		return self:getText("ui_hours_none")
	end
end
function I18N:formatPeriod(period, useShort)
	local isSouthern = false
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		isSouthern = g_currentMission.environment.daylight.latitude < 0
		if period == nil then
			period = g_currentMission.environment.currentPeriod
		end
	end
	if period == nil then
		return nil
	else
		local month = period + 2
		if isSouthern then
			month = month + 6
		end
		month = (month - 1) % 12 + 1
		return self:getText("ui_month" .. month .. (useShort and "_short" or ""))
	end
end
function I18N:formatDayInPeriod(dayInPeriod, period, useShort)
	if g_currentMission == nil or g_currentMission.environment == nil then
		return nil
	end
	if dayInPeriod == nil then
		dayInPeriod = g_currentMission.environment.currentDayInPeriod
	end
	if period == nil then
		period = g_currentMission.environment.currentPeriod
	end
	local periodString = self:formatPeriod(period, useShort)
	local daysPerPeriod = g_currentMission.environment.daysPerPeriod
	if daysPerPeriod == 1 then
		return periodString
	else
		return string.format("%s %d", periodString, dayInPeriod)
	end
end
function I18N:formatNumMonth(numMonth)
	local locaMonth = "ui_months"
	if numMonth == 1 then
		locaMonth = "ui_month"
	end
	return string.format("%d %s", numMonth, self:getText(locaMonth))
end
function I18N:formatNumDay(numDay)
	local locaDay = "ui_days"
	if numDay == 1 then
		locaDay = "ui_day"
	end
	return string.format("%d %s", numDay, self:getText(locaDay))
end
function I18N:formatCurrentTime()
	if g_currentMission == nil or g_currentMission.environment == nil then
		return
	end
	local currentTime = g_currentMission.environment.dayTime / 3600000
	local timeHours = math.floor(currentTime)
	local timeMinutes = math.floor((currentTime - timeHours) * 60)
	local currentTimeText = string.format("%02d:%02d", timeHours, timeMinutes)
	return currentTimeText
end
