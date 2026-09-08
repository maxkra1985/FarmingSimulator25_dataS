-- Local values: I18N_mt
I18N = {}
local I18N_mt = Class(I18N)
I18N.L10N_FILES_DIRECTORY = "dataS/l10n/"
I18N.MONEY_MAX_DISPLAY_VALUE = 999999999
I18N.MONEY_MIN_DISPLAY_VALUE = -999999999
g_xmlManager:addEarlyCreateSchemaFunction(function()
	I18N.xmlSchema = XMLSchema.new("l18n")
	I18N.registerXMLPaths(I18N.xmlSchema)
end)

-- Local values: baseKey
function I18N.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.FLOAT, "l10n.fluid#factor", "", 1)
	xmlSchema:register(XMLValueType.FLOAT, "l10n.power#factor", "", 1)
	xmlSchema:register(XMLValueType.STRING, "l10n.elements.e(?)#k", "The name of the string", nil)
	xmlSchema:register(XMLValueType.STRING, "l10n.elements.e(?)#v", "The text of the string", nil)
end
function I18N.new()
	-- upvalues: (copy) I18N_mt
	local v3_ = I18N_mt
	local v4_ = setmetatable({}, v3_)
	v4_.texts = {}
	v4_.modEnvironments = {}
	if g_addTestCommands then
		addConsoleCommand("gsI18nVerify", "Checks all localization files for empty or \'TODO\' texts, warns if placeholders mismatch between languages", "consoleCommandVerifyAll", v4_, "[ignoreTodos=false]; [l10nDir]; [l10nFilePrefix]")
	end
	v4_.debugActive = StartParams.getIsSet("debugI18N")
	if v4_.debugActive then
		print("debugI18N active")
		if not StartParams.getIsSet("scriptDebug") then
			Logging.devWarning("\'-debugI18N\' start parameter should only be used in combination with \'-scriptDebug\' start parameter")
		end
		v4_.usedTexts = {}
		v4_.printedWarnings = {}
		v4_:loadUsedKeysFromXML()
		addConsoleCommand("gsI18nSaveUsedKeysXml", "", "saveUsedKeysToXML", v4_)
		g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN, v4_.saveUsedKeysToXML, v4_)
		g_messageCenter:subscribe(MessageType.GUI_MAIN_SCREEN_OPEN, v4_.saveUsedKeysToXML, v4_)
	end
	return v4_
end

-- Local values: baseXMLFile, xmlFile
function I18N:load()
	self.texts = {}
	if not g_isDevelopmentVersion and g_languageShort ~= "en" then
		local v6_ = XMLFile.load("l10n_en", I18N.L10N_FILES_DIRECTORY .. "l10n_en.xml")
		self:loadEntriesFromXML(v6_, self.texts, true)
		v6_:delete()
	end
	local v7_ = XMLFile.load("l10n" .. g_languageSuffix, I18N.L10N_FILES_DIRECTORY .. "l10n" .. g_languageSuffix .. ".xml")
	self:loadEntriesFromXML(v7_, self.texts, true)
	self:mergePlatformText(self.texts)
	self.fluidFactor = v7_:getFloat("l10n.fluid#factor", 1)
	self.powerFactorHP = v7_:getFloat("l10n.power#factor", 1)
	self.powerFactorKW = 0.735499
	self.moneyUnit = GS_MONEY_EURO
	self.useMiles = false
	self.useFahrenheit = false
	self.useAcre = false
	v7_:delete()
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

-- Local values: xmlFile
function I18N:loadFromXMLFile(xmlFilename)
	self.texts = {}
	local v11_ = XMLFile.load("l10n", xmlFilename)
	self:loadEntriesFromXML(v11_, self.texts, false)
	v11_:delete()
end

-- Local values: nodeIndex, nodeKey, name, text
function I18N:loadEntriesFromXML(xmlFile, outputEntries, overwriteExistingText)
	for _, v16_ in xmlFile:iterator("l10n.elements.e") do
		local v17_ = xmlFile:getString(v16_ .. "#k")
		if string.isNilOrWhitespace(v17_) then
			Logging.xmlWarning(xmlFile, "Node at path %q is missing a name (k attribute)", v16_)
		elseif outputEntries[v17_] == nil or overwriteExistingText then
			local v18_ = xmlFile:getString(v16_ .. "#v")
			if string.isNilOrWhitespace(v18_) then
				Logging.xmlWarning(xmlFile, "Node at path %q is missing a text (v attribute)", v16_)
			else
				if string.trim(utf8ToUpper(v18_)) == "TODO" then
					v18_ = "TODO:" .. v17_
					if self.debugActive and self.printedWarnings[v17_] == nil then
						Logging.devWarning("TODO text set for loca key \'%s\' in %q", v17_, xmlFile:getFilename())
						self.printedWarnings[v17_] = true
					end
				end
				outputEntries[v17_] = string.gsub(v18_, "\r\n", "\n")
			end
		end
	end
end

-- Local values: key, text, _, postfix, postfixKey
function I18N:mergePlatformText(texts)
	for v20_, v21_ in pairs(texts) do
		for _, v22_ in ipairs(Platform.l10nPostfixes) do
			local v23_ = v20_ .. v22_
			if texts[v23_] ~= nil then
				texts[v20_] = texts[v23_]
				break
			end
		end
		if texts[v20_] ~= v21_ then
			Logging.devInfo("I18N platform specific text %s: \'%s\'", v20_, texts[v20_])
		end
	end
end

-- Local values: fileName, xmlFile, usedCount, key, textsCount, unusedCount
function I18N:saveUsedKeysToXML()
	local v25_ = getUserProfileAppPath() .. "l10n_usedKeys.xml"
	local v26_ = createXMLFile("l10n_usedKeys", v25_, "l10n")
	if v26_ == 0 then
		Logging.error("Failed to create l10n_usedKeys xml file")
	else
		local v27_ = 0
		for v28_ in pairs(self.usedTexts) do
			setXMLString(v26_, string.format("l10n.used(%d)#k", v27_), v28_)
			v27_ = v27_ + 1
		end
		saveXMLFile(v26_)
		delete(v26_)
		local v29_ = table.size(self.texts)
		local v30_ = v29_ - v27_
		print(string.format("I18N debug: saved \'%s\': %i unused, %i used, %i total keys ", v25_, v30_, v27_, v29_))
	end
end

-- Local values: fileName, xmlFile
function I18N:loadUsedKeysFromXML()
	local v32_ = getUserProfileAppPath() .. "l10n_usedKeys.xml"
	local v_u_33_ = XMLFile.loadIfExists("l10n_usedKeys", v32_)
	if v_u_33_ then
		v_u_33_:iterate("l10n.used", function(_, p34_)
			-- upvalues: (copy) self, (copy) v_u_33_
			self.usedTexts[v_u_33_:getString(p34_ .. "#k")] = true
		end)
		print(string.format("I18N debug: loaded \'%s\': %i used keys ", v32_, table.size(self.usedTexts)))
		v_u_33_:delete()
	else
		Logging.devWarning("I18N debug: Unable to load used loca keys file %s", v32_)
	end
end

-- Local values: modi18n
function I18N:addModI18N(modName)
	local v37_ = {
		["texts"] = {}
	}
	setmetatable(v37_, {
		["__index"] = self
	})
	local v38_ = v37_.texts
	local v39_ = {
		["__index"] = self.texts
	}
	setmetatable(v38_, v39_)
	self.modEnvironments[modName] = v37_
	
function v37_:setText(name, value)
		self.texts[name] = value
	end
	function v37_.hasModText(p43_, p44_)
		return p43_.texts[p44_] ~= nil
	end
	function v37_.setGlobalText(_, p45_, p46_)
		-- upvalues: (copy) modName, (copy) self
		local v47_ = modName .. "." .. p45_
		if self.texts[v47_] == nil then
			self.texts[v47_] = p46_
		end
	end
	return v37_
end

-- Local values: ret, modEnv
function I18N:getText(name, customEnv)
	local v51_ = nil
	if customEnv ~= nil then
		local v52_ = self.modEnvironments[customEnv]
		if v52_ ~= nil then
			v51_ = v52_.texts[name]
		end
	end
	if v51_ == nil then
		v51_ = self.texts[name]
		if v51_ == nil then
			v51_ = string.format("Missing \'%s\' in l10n%s.xml", name, g_languageSuffix)
			if g_showDevelopmentWarnings then
				Logging.devWarning(v51_)
			end
		end
	end
	return v51_
end

-- Local values: ret, modEnv
function I18N:hasText(name, customEnv)
	if name == nil then
		return false
	end
	local v56_ = nil
	if customEnv ~= nil then
		local v57_ = self.modEnvironments[customEnv]
		if v57_ ~= nil then
			v56_ = v57_.texts[name]
		end
	end
	if v56_ == nil then
		v56_ = self.texts[name]
	end
	return v56_ ~= nil
end
function I18N.setText(p58_, p59_, p60_)
	p58_.texts[p59_] = p60_
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
	return self.moneyUnit == GS_MONEY_EURO and 1 or (self.moneyUnit == GS_MONEY_POUND and 0.79 or 1.34)
end

-- Local values: postfix
function I18N:getMeasuringUnit(useLongName)
	local v74_ = useLongName and "" or "Short"
	if self.useMiles then
		return self.texts["unit_miles" .. v74_]
	else
		return self.texts["unit_km" .. v74_]
	end
end

-- Local values: postfix
function I18N:getVolumeUnit(useLongName)
	return self.texts["unit_liter" .. (useLongName and "" or "Short")]
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

-- Local values: temperature, str
function I18N:formatTemperature(temperatureCelsius, precision, useLongName)
	local v87_ = self:getTemperature(temperatureCelsius)
	local v88_ = self:getTemperatureUnit(useLongName)
	return string.format("%1." .. (precision or 0) .. "f%s", v87_, v88_)
end

-- Local values: postfix
function I18N:getTemperatureUnit(useLongName)
	local v91_ = useLongName and "" or "Short"
	if self.useFahrenheit then
		return self.texts["unit_fahrenheit" .. v91_]
	else
		return self.texts["unit_celsius" .. v91_]
	end
end

-- Local values: postfix
function I18N:getAreaUnit(useLongName)
	local v94_ = useLongName and "" or "Short"
	if self.useAcre then
		return self.texts["unit_acre" .. v94_]
	else
		return self.texts["unit_ha" .. v94_]
	end
end

function I18N:getArea(ha)
	if self.useAcre then
		return ha * 2.4711
	else
		return ha
	end
end

-- Local values: area, str
function I18N:formatArea(areaInHa, precision, useLongName)
	local v101_ = self:getArea(areaInHa)
	local v102_ = self:getAreaUnit(useLongName)
	return MathUtil.round(v101_, precision) .. " " .. v102_
end

-- Local values: postfix
function I18N:getDistanceUnit(useLongName)
	local v105_ = useLongName and "" or "Short"
	if self.useMiles then
		return self.texts["unit_ft" .. v105_]
	else
		return self.texts["unit_m" .. v105_]
	end
end

function I18N:getDistance(distance, isDistanceInMeter)
	if self.useMiles then
		if isDistanceInMeter then
			return distance * 3.28084
		else
			return distance * 0.62137
		end
	else
		return distance
	end
end

-- Local values: distance, str
function I18N:formatDistance(distanceInMeter, precision, useLongName)
	local v113_ = self:getDistance(distanceInMeter, true)
	local v114_ = self:getDistanceUnit(useLongName)
	return MathUtil.round(v113_, precision) .. " " .. v114_
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

-- Local values: unit, precision
function I18N:formatMass(mass, maxMass, showKg)
	local v127_ = "unit_tonsShort"
	local v128_ = 1
	if showKg ~= false then
		if mass < 1 and (maxMass == nil or maxMass == 0) then
			mass = mass * 1000
			v128_ = 0
			v127_ = "unit_kg"
		elseif mass < 1 and (maxMass ~= nil and maxMass ~= 0) then
			mass = mass * 1000
			maxMass = maxMass * 1000
			v128_ = 0
			v127_ = "unit_kg"
		end
	end
	if maxMass == nil or maxMass == 0 then
		return string.format("%s %s", self:formatNumber(MathUtil.round(mass, v128_), v128_), g_i18n:getText(v127_))
	else
		return string.format("%s-%s %s", self:formatNumber(MathUtil.round(mass, v128_), v128_), self:formatNumber(MathUtil.round(maxMass, v128_), v128_), g_i18n:getText(v127_))
	end
end

function I18N:getPower(power)
	return power * self.powerFactorHP, power * self.powerFactorKW
end

-- Local values: baseString, prefix, thousandsPart, decimalPart, thousandsPartReversed, formattedNumber
function I18N:formatNumber(number, precision, forcePrecision)
	if number == math.huge then
		return "inf"
	end
	if number == -math.huge then
		return "-inf"
	end
	local v135_ = precision or 0
	if v135_ == 0 then
		if number == nil then
			printCallstack()
		end
		if number < 0 then
			number = math.ceil(number)
		else
			number = math.floor(number)
		end
	end
	local v136_ = MathUtil.round
	local v137_ = tostring(v136_(number, v135_))
	local v138_, v139_, v140_ = string.match(v137_, "^([^%d]*%d)(%d*)[.]?(%d*)")
	if v139_ == nil then
		printCallstack()
		error(string.format("I18N:formatNumber: unable to split string %q (number %q)", v137_, (tostring(number))))
	end
	local v141_ = string.reverse(v139_)
	local v142_ = string.gsub(v141_, "(%d%d%d)", "%1" .. self.thousandsGroupingChar)
	local v143_ = v138_ .. string.reverse(v142_)
	if v135_ > 0 and (string.len(v140_) > 0 and (forcePrecision or tonumber(v140_) ~= 0)) then
		v143_ = v143_ .. self.decimalSeparator .. string.sub(v140_, 1, v135_)
	end
	return v143_
end

-- Local values: clampedDisplayMoney, currencyString
function I18N:formatMoney(number, precision, addCurrency, prefixCurrencySymbol)
	local v149_ = I18N.MONEY_MIN_DISPLAY_VALUE
	local v150_ = I18N.MONEY_MAX_DISPLAY_VALUE
	local v151_ = self:formatNumber(math.clamp(number, v149_, v150_), precision)
	if addCurrency == nil or addCurrency then
		if prefixCurrencySymbol == nil or not prefixCurrencySymbol then
			return v151_ .. "\194\160" .. self:getCurrencySymbol(true)
		end
		v151_ = self:getCurrencySymbol(true) .. "\194\160" .. v151_
	end
	return v151_
end

-- Local values: postFix
function I18N:getCurrencySymbol(useShort)
	local v154_ = useShort and "Short" or ""
	if self.moneyUnit == GS_MONEY_EURO then
		return self:getText("unit_euro" .. v154_)
	elseif self.moneyUnit == GS_MONEY_POUND then
		return self:getText("unit_pound" .. v154_)
	else
		return self:getText("unit_dollar" .. v154_)
	end
end

function I18N:convertText(textOrKey, customEnv)
	if textOrKey ~= nil then
		if string.startsWith(textOrKey, "$l10n_") then
			textOrKey = g_i18n:getText(string.sub(textOrKey, 7), customEnv)
		end
		return textOrKey
	end
	Logging.warning("Text to convert is nil")
	printCallstack()
	return nil
end

-- Local values: _, count, params, i
function I18N:insertTextParams(text, paramsStr, customEnvironment, xmlFile)
	local _, v162_ = string.gsub(text, "%%s", "")
	local v163_ = string.split(paramsStr, "|")
	if #v163_ == v162_ then
		for v164_ = 1, #v163_ do
			v163_[v164_] = self:convertText(v163_[v164_], customEnvironment)
		end
		return string.format(text, unpack(v163_))
	elseif xmlFile == nil then
		Logging.warning("Unable to insert parameters into text. Invalid number of params. (%d found in string \'%s\', %d params given in \'%s\')", v162_, text, #v163_, paramsStr)
		return text
	else
		Logging.xmlWarning(xmlFile, "Unable to insert parameters into text. Invalid number of params. (%d found in string \'%s\', %d params given in \'%s\')", v162_, text, #v163_, paramsStr)
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
	self:verifyLocaFiles(Utils.stringToBoolean(ignoreTodos), l10nDir or I18N.L10N_FILES_DIRECTORY, l10nFilePrefix or "l10n_")
end

-- Local values: formatsFromString, langToKeys, allKeysSet, masterLang, numL, langIndex, code, filenameShort, xmlFilename, keys, xmlFile, key, _, key, _, lang, keys, text, enFormatStrings, str, key, text, result, capturePattern, formatIdentifier, _, _, count, formatString, count, _, num, lang, keys, key, text, str, result, capturePattern, formatIdentifier, _, _, count, formatStringText, countText, formatStringEn, countEn, upperText, enText, tryStringFormat, enText
function I18N:verifyLocaFiles(ignoreTodos, l10nDir, l10nFilePrefix)
	print("Verifying i18n files:")
	setFileLogPrefixTimestamp(false)
	if ignoreTodos then
		printWarning("Warning: Ignoring \'TODO\' and \'\' texts")
	end
	print("loading lang files")
	local v173_ = {}
	local v174_ = {}
	local v175_ = nil
	for v176_ = 0, getNumOfLanguages() - 1 do
		local v177_ = getLanguageCode(v176_)
		local v178_ = l10nFilePrefix .. v177_ .. ".xml"
		if v177_ == "en" then
			v175_ = v178_
		end
		local v179_ = l10nDir .. v178_
		if fileExists(v179_) then
			local v180_ = {}
			local v181_ = XMLFile.load("l10n" .. g_languageSuffix, v179_)
			self:loadEntriesFromXML(v181_, v180_)
			v181_:delete()
			self:mergePlatformText(v180_)
			v173_[v178_] = v180_
			for v182_, _ in pairs(v180_) do
				v174_[v182_] = true
			end
			print(string.format("loaded %d entries from %s", table.size(v180_), v179_))
		else
			printWarning(string.format("Warning: unable to find xml file %s for langIndex %d", v179_, v176_))
		end
	end
	if next(v173_) == nil then
		return "Error: no l10n entries were loaded"
	end
	for v183_, _ in pairs(v174_) do
		for v184_, v185_ in pairs(v173_) do
			local v186_ = v185_[v183_]
			if v186_ == nil then
				printWarning(string.format("Warning: Missing text for %s in %s", v183_, v184_))
			elseif not ignoreTodos and (v186_:trim() == "" or v186_:find("TODO")) then
				printWarning(string.format("Warning: Empty or todo text for %s in %s", v183_, v184_))
			end
		end
	end
	local v187_ = {}
	for v188_, v189_ in pairs(v173_[v175_]) do
		local v190_ = ""
		for v191_, _ in v189_:gmatch("%%%d?%.?%d*%a") do
			v190_ = v190_ .. v191_
		end
		local v192_
		if v190_ == "" then
			v190_ = nil
			v192_ = nil
		else
			local _, v193_ = v189_:gsub("%%", "")
			v192_ = v193_ % 2
		end
		if v190_ ~= nil then
			v187_[v188_] = { v190_, v192_ }
			local _, v194_ = string.gsub(v190_, "%%", "")
			if v194_ > 1 then
				printError(string.format("Error: Multiple unnamed format specifiers (%s) in %q", v190_, v188_))
			end
		end
	end
	for v195_, v196_ in pairs(v173_) do
		if v195_ ~= v175_ then
			print(v195_)
			for v197_, v_u_198_ in pairs(v196_) do
				getTextHeight(1, v_u_198_)
				local v199_ = ""
				for v200_, _ in v_u_198_:gmatch("%%%d?%.?%d*%a") do
					v199_ = v199_ .. v200_
				end
				local v201_
				if v199_ == "" then
					v201_ = nil
					v199_ = nil
				else
					local _, v202_ = v_u_198_:gsub("%%", "")
					v201_ = v202_ % 2
				end
				local v203_ = v187_[v197_]
				if v203_ then
					v203_ = v187_[v197_][1]
				end
				local v204_ = v187_[v197_]
				if v204_ then
					v204_ = v187_[v197_][2]
				end
				if v199_ then
					if utf8ToUpper(v_u_198_) ~= "TODO" then
						local v205_ = v173_[v175_][v197_]
						if v199_ ~= v203_ then
							printError(string.format("Error: Mismatching format strings for key \'%s\' in %s: \'%s\' <-> \'%s\'", v197_, v195_, v203_ or "no placeholder", v199_ or "no placeholder"))
							print(string.format("    %s: %s", v175_, v205_))
							print(string.format("    %s: %s", v195_, v_u_198_))
						end
						if v201_ ~= v204_ then
							printError(string.format("Error: Mismatching \'%%\' characters (possible unescaped \'%%\') for key \'%s\' in %s", v197_, v195_))
							print(string.format("    %s: %s", v175_, v205_))
							print(string.format("    %s: %s", v195_, v_u_198_))
						end
					end
					if v187_[v197_] and not pcall(function()
						-- upvalues: (copy) v_u_198_
						string.format(v_u_198_, 1, 2, 3, 4, 5, 6, 7, 8, 9)
					end) then
						local v206_ = v173_[v175_][v197_]
						printError(string.format("Error: String format cannot be applied on string \'%s\' in %s:\n    en: \'%s\'\n<->\n    %s: \'%s\'", v197_, v195_, v206_, v195_, v_u_198_))
					end
				end
			end
		end
	end
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	return "Verified all i18n files"
end

-- Local values: hours, mins
function I18N:formatMinutes(minutes)
	if minutes == nil then
		return self:getText("ui_hours_none")
	end
	local v209_ = minutes / 60
	local v210_ = math.floor(v209_)
	local v211_ = minutes - v210_ * 60
	return string.format(self:getText("ui_hours"), v210_, v211_)
end

-- Local values: isSouthern, month
function I18N:formatPeriod(period, useShort)
	local v215_
	if g_currentMission == nil or g_currentMission.environment == nil then
		v215_ = false
	else
		v215_ = g_currentMission.environment.daylight.latitude < 0
		if period == nil then
			period = g_currentMission.environment.currentPeriod
		end
	end
	if period == nil then
		return nil
	end
	local v216_ = period + 2
	if v215_ then
		v216_ = v216_ + 6
	end
	return self:getText("ui_month" .. (v216_ - 1) % 12 + 1 .. (useShort and "_short" or ""))
end

-- Local values: periodString, daysPerPeriod
function I18N:formatDayInPeriod(dayInPeriod, period, useShort)
	if g_currentMission == nil or g_currentMission.environment == nil then
		return nil
	else
		if dayInPeriod == nil then
			dayInPeriod = g_currentMission.environment.currentDayInPeriod
		end
		if period == nil then
			period = g_currentMission.environment.currentPeriod
		end
		local v221_ = self:formatPeriod(period, useShort)
		if g_currentMission.environment.daysPerPeriod == 1 then
			return v221_
		else
			return string.format("%s %d", v221_, dayInPeriod)
		end
	end
end

-- Local values: locaMonth
function I18N:formatNumMonth(numMonth)
	local v224_ = numMonth == 1 and "ui_month" or "ui_months"
	return string.format("%d %s", numMonth, self:getText(v224_))
end

-- Local values: locaDay
function I18N:formatNumDay(numDay)
	local v227_ = numDay == 1 and "ui_day" or "ui_days"
	return string.format("%d %s", numDay, self:getText(v227_))
end

-- Local values: currentTime, timeHours, timeMinutes, currentTimeText
function I18N:formatCurrentTime()
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		local v228_ = g_currentMission.environment.dayTime / 3600000
		local v229_ = math.floor(v228_)
		local v230_ = (v228_ - v229_) * 60
		local v231_ = math.floor(v230_)
		return string.format("%02d:%02d", v229_, v231_)
	end
end
