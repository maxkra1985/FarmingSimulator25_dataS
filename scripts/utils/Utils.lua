Utils = {}
function Utils.getNoNil(value, setTo)
	if value == nil then
		return setTo
	else
		return value
	end
end
function Utils.getNoNilRad(valueDeg, defaultRad)
	if valueDeg == nil then
		return defaultRad
	else
		return math.rad(valueDeg)
	end
end
function Utils.limitTextToWidth(text, textSize, width, trimFront, trimReplaceText)
	local replaceTextWidth = getTextWidth(textSize, trimReplaceText)
	local indexOfFirstCharacter = 1
	local indexOfLastCharacter = utf8Strlen(text)
	if 0 <= width then
		local totalWidth = getTextWidth(textSize, text)
		if width < totalWidth then
			if trimFront then
				indexOfFirstCharacter = getTextLineLength(textSize, text, totalWidth - width + replaceTextWidth)
				text = trimReplaceText .. utf8Substr(text, indexOfFirstCharacter)
			else
				indexOfLastCharacter = getTextLineLength(textSize, text, width - replaceTextWidth)
				text = utf8Substr(text, 0, indexOfLastCharacter) .. trimReplaceText
			end
		end
	end
	return text, indexOfFirstCharacter, indexOfLastCharacter
end
function Utils.getMovedLimitedValue(curVal, maxVal, minVal, speed, dt, inverted)
	local limitF = math.min
	local limitF2 = math.max
	if inverted then
		minVal = maxVal
		maxVal = minVal
	end
	if maxVal < minVal then
		limitF = math.max
		limitF2 = math.min
	elseif maxVal == minVal then
		return minVal
	end
	return limitF2(limitF(curVal + (maxVal - minVal) / speed * dt, maxVal), minVal)
end
function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
	local ret = table.create(numValues)
	for i = 1, numValues do
		ret[i] = Utils.getMovedLimitedValue(currentValues[i], maxValues[i], minValues[i], speed, dt, inverted)
	end
	return ret
end
function Utils.setMovedLimitedValues(values, maxValues, minValues, numValues, speed, dt, inverted)
	local changed = false
	for i = 1, numValues do
		local newValue = Utils.getMovedLimitedValue(values[i], maxValues[i], minValues[i], speed, dt, inverted)
		if newValue == values[i] then
			continue
		end
		changed = true
		values[i] = newValue
	end
	return changed
end
function Utils.removeModDirectory(filename)
	local isMod = false
	local isDlc = false
	local dlcsDirectoryIndex = 0
	if filename == nil then
		printCallstack()
	end
	local filenameLower = string.lower(filename)
	if g_modsDirectory then
		local modsDirLen = g_modsDirectory:len()
		local modsDirLower = string.lower(g_modsDirectory)
		if filenameLower:sub(1, modsDirLen) == modsDirLower then
			filename = filename:sub(modsDirLen + 1)
			isMod = true
		end
		if not isMod and not string.isNilOrWhitespace(g_internalModsDirectory) then
			local internalModsDirLen = g_internalModsDirectory:len()
			if filenameLower:sub(1, internalModsDirLen) == string.lower(g_internalModsDirectory) then
				filename = filename:sub(internalModsDirLen + 1)
				isMod = true
			end
		end
	end
	if not isMod and g_dlcsDirectories ~= nil then
		for i, dlcDirectory in ipairs(g_dlcsDirectories) do
			local dlcsDir = string.lower(dlcDirectory.path)
			local dlcsDirLen = dlcsDir:len()
			if filenameLower:sub(1, dlcsDirLen) == dlcsDir then
				filename = filename:sub(dlcsDirLen + 1)
				dlcsDirectoryIndex = i
				isDlc = true
				return filename, isMod, isDlc, dlcsDirectoryIndex
			end
		end
	end
	return filename, isMod, isDlc, dlcsDirectoryIndex
end
function Utils.getUniqueId(value, mappingTable, prefix, md5Length)
	if type(md5Length) ~= "number" or md5Length <= 0 or 32 <= md5Length then
		md5Length = nil
	end
	prefix = prefix or ""
	local uniqueId = nil
	local i = 0
	while true do
		local md5 = getMD5(tostring(value) .. tostring(getTime()) .. tostring(i))
		if md5Length == nil then
			break
		end
		uniqueId = prefix .. string.sub(md5, 1, md5Length)
		i = i + 1
		if mappingTable ~= nil and mappingTable[uniqueId] ~= nil then
			continue
		end
		return uniqueId
	end
	uniqueId = prefix .. md5
end
function Utils.getModNameAndBaseDirectory(filename)
	local modName = nil
	local baseDirectory = ""
	local modFilename, isMod, isDlc, dlcsDirectoryIndex = Utils.removeModDirectory(filename)
	if isMod or isDlc then
		local f, l = modFilename:find("/")
		if f ~= nil and (l ~= nil and 1 < f) then
			modName = modFilename:sub(1, f - 1)
			if isDlc then
				baseDirectory = g_dlcsDirectories[dlcsDirectoryIndex].path .. modName .. "/"
				if g_dlcModNameHasPrefix[modName] then
					modName = g_uniqueDlcNamePrefix .. modName
					return modName, baseDirectory
				end
			else
				baseDirectory = g_modNameToDirectory[modName] or g_modsDirectory .. modName .. "/"
			end
		end
	end
	return modName, baseDirectory
end
function Utils.getVersatileRotation(repr, componentNode, dt, posX, posY, posZ, currentAngle, minAngle, maxAngle)
	local vx, vy, vz = getVelocityAtLocalPos(componentNode, posX, posY, posZ)
	local x, _, z = worldDirectionToLocal(getParent(repr), vx, vy, vz)
	local length = MathUtil.vector2Length(x, z)
	local steeringAngle = currentAngle
	if 0.15 < length then
		steeringAngle = math.atan2(x / length, z / length)
		if steeringAngle < -1.5707963267948966 then
			steeringAngle = steeringAngle + 6.283185307179586
		end
	end
	if minAngle ~= nil and (minAngle ~= 0 and (maxAngle ~= nil and maxAngle ~= 0)) then
		if maxAngle < steeringAngle then
			steeringAngle = maxAngle
		elseif steeringAngle < minAngle then
			steeringAngle = minAngle
		end
	end
	steeringAngle = MathUtil.normalizeRotationForShortestPath(steeringAngle, currentAngle)
	if currentAngle < steeringAngle then
		steeringAngle = math.min(currentAngle + 0.003 * dt, steeringAngle)
		return steeringAngle
	else
		steeringAngle = math.max(currentAngle - 0.003 * dt, steeringAngle)
		return steeringAngle
	end
end
function Utils.getYRotationBetweenNodes(node1, node2, offset1, offset2, wrapRotation)
	local dirX1 = 0
	local dirZ1 = 1
	local dirX2 = 0
	local dirZ2 = 1
	if offset1 ~= nil and offset1 ~= 0 then
		dirX1, dirZ1 = MathUtil.getDirectionFromYRotation(offset1)
	end
	if offset2 ~= nil and offset2 ~= 0 then
		dirX2, dirZ2 = MathUtil.getDirectionFromYRotation(offset2)
	end
	local wDirX1, _, wDirZ1 = localDirectionToWorld(node1, dirX1, 0, dirZ1)
	local wDirX2, _, wDirZ2 = localDirectionToWorld(node2, dirX2, 0, dirZ2)
	wDirX1, _, wDirZ1 = worldDirectionToLocal(node1, wDirX1, 0, wDirZ1)
	wDirX2, _, wDirZ2 = worldDirectionToLocal(node1, wDirX2, 0, wDirZ2)
	local dir = 1
	if 0 < wDirX1 - wDirX2 then
		dir = -dir
	end
	local angle = MathUtil.getVectorAngleDifference(wDirX1, 0, wDirZ1, wDirX2, 0, wDirZ2)
	if wrapRotation ~= false and 1.5707963267948966 < math.abs(angle) then
		angle = -(3.141592653589793 - angle)
	end
	return angle * dir
end
function Utils.getPerformanceClassIndex(profileClass)
	profileClass = string.lower(profileClass)
	local currentProfileIndex = GS_PROFILE_LOW
	if profileClass == "very low" then
		currentProfileIndex = GS_PROFILE_VERY_LOW
		return currentProfileIndex
	elseif profileClass == "low" then
		currentProfileIndex = GS_PROFILE_LOW
		return currentProfileIndex
	elseif profileClass == "medium" then
		currentProfileIndex = GS_PROFILE_MEDIUM
		return currentProfileIndex
	elseif profileClass == "high" then
		currentProfileIndex = GS_PROFILE_HIGH
		return currentProfileIndex
	elseif profileClass == "very high" then
		currentProfileIndex = GS_PROFILE_VERY_HIGH
		return currentProfileIndex
	elseif profileClass == "ultra" then
		currentProfileIndex = GS_PROFILE_ULTRA
		return currentProfileIndex
	else
		print("ERROR: performanceClass '" .. profileClass .. "' not recognized; using LOW")
		return currentProfileIndex
	end
end
function Utils.getPerformanceClassFromIndex(profileClassIndex)
	local currentProfileClass = "Low"
	if profileClassIndex == GS_PROFILE_VERY_LOW then
		currentProfileClass = "Very Low"
		return currentProfileClass
	elseif profileClassIndex == GS_PROFILE_MEDIUM then
		currentProfileClass = "Medium"
		return currentProfileClass
	elseif profileClassIndex == GS_PROFILE_HIGH then
		currentProfileClass = "High"
		return currentProfileClass
	elseif profileClassIndex == GS_PROFILE_VERY_HIGH then
		currentProfileClass = "Very High"
		return currentProfileClass
	else
		if profileClassIndex == GS_PROFILE_ULTRA then
			currentProfileClass = "Ultra"
		end
		return currentProfileClass
	end
end
function Utils.getPerformanceClassId()
	return Utils.getPerformanceClassIndex(getPerformanceClass())
end
function Utils.getStateFromValues(values, steps, value)
	local state = #values
	for i = 1, #values do
		if value <= values[i] + steps * 0.5 then
			state = i
			return state
		end
	end
	return state
end
function Utils.getValueIndex(targetValue, values)
	local index = 1
	local threshold = 0.0001
	for k, val in pairs(values) do
		if targetValue < val - 0.0001 then
			break
		end
		index = k
	end
	return index
end
function Utils.getNumTimeScales()
	local timeScaleSettings = Platform.gameplay.timeScaleSettings
	local numSettings = #timeScaleSettings
	if g_addTestCommands then
		local timeScaleDevSettings = Platform.gameplay.timeScaleDevSettings
		numSettings = numSettings + #timeScaleDevSettings
	end
	return numSettings
end
function Utils.getTimeScaleString(timeScaleIndex)
	local timeScaleSettings = Platform.gameplay.timeScaleSettings
	local speed = Utils.getTimeScaleFromIndex(timeScaleIndex)
	if speed == 1 then
		return g_i18n:getText("ui_realTime")
	elseif #timeScaleSettings < timeScaleIndex then
		return string.format("%dx (dev only)", speed)
	elseif speed < 1 then
		return string.format("%0.2fx", speed)
	else
		return string.format("%dx", speed)
	end
end
function Utils.getTimeScaleIndex(timeScale)
	local timeScaleSettings = Platform.gameplay.timeScaleSettings
	if g_addTestCommands then
		local timeScaleDevSettings = Platform.gameplay.timeScaleDevSettings
		for i = #timeScaleDevSettings, 1, -1 do
			if timeScaleDevSettings[i] <= timeScale then
				return i + #timeScaleSettings
			end
		end
	end
	for i = #timeScaleSettings, 1, -1 do
		if timeScaleSettings[i] <= timeScale then
			return i
		end
	end
	return 3
end
function Utils.getTimeScaleFromIndex(timeScaleIndex)
	local timeScaleSettings = Platform.gameplay.timeScaleSettings
	timeScaleIndex = math.max(timeScaleIndex, 1)
	if g_addTestCommands and #timeScaleSettings < timeScaleIndex then
		local timeScaleDevSettings = Platform.gameplay.timeScaleDevSettings
		return timeScaleDevSettings[timeScaleIndex - #timeScaleSettings]
	end
	return timeScaleSettings[timeScaleIndex]
end
function Utils.getMasterVolumeIndex(masterVolume)
	masterVolume = masterVolume + 0.01
	local masterVolumeIndex = 1
	if 1 <= masterVolume then
		masterVolumeIndex = 11
		return masterVolumeIndex
	elseif 0.9 <= masterVolume then
		masterVolumeIndex = 10
		return masterVolumeIndex
	elseif 0.8 <= masterVolume then
		masterVolumeIndex = 9
		return masterVolumeIndex
	elseif 0.7 <= masterVolume then
		masterVolumeIndex = 8
		return masterVolumeIndex
	elseif 0.6 <= masterVolume then
		masterVolumeIndex = 7
		return masterVolumeIndex
	elseif 0.5 <= masterVolume then
		masterVolumeIndex = 6
		return masterVolumeIndex
	elseif 0.4 <= masterVolume then
		masterVolumeIndex = 5
		return masterVolumeIndex
	elseif 0.3 <= masterVolume then
		masterVolumeIndex = 4
		return masterVolumeIndex
	elseif 0.2 <= masterVolume then
		masterVolumeIndex = 3
		return masterVolumeIndex
	else
		if 0.1 <= masterVolume then
			masterVolumeIndex = 2
		end
		return masterVolumeIndex
	end
end
function Utils.getMasterVolumeFromIndex(masterVolumeIndex)
	if 1 <= masterVolumeIndex and masterVolumeIndex <= 10 then
		return (masterVolumeIndex - 1) * 0.1
	end
	return 1
end
function Utils.getUIScaleIndex(uiScale)
	uiScale = uiScale + 0.01
	local uiScaleIndex = 1
	local currentScale = 0.55
	while currentScale < uiScale do
		uiScaleIndex = uiScaleIndex + 1
		currentScale = currentScale + 0.05
	end
	return uiScaleIndex
end
function Utils.getUIScaleFromIndex(uiScaleIndex)
	if 1 <= uiScaleIndex then
		return (uiScaleIndex - 1) * 0.05 + 0.5
	else
		return 1
	end
end
function Utils.getRecordingVolumeIndex(volume)
	volume = volume + 0.01
	if 1.5 <= volume then
		return 12
	elseif 1.4 <= volume then
		return 11
	elseif 1.3 <= volume then
		return 10
	elseif 1.2 <= volume then
		return 9
	elseif 1.1 <= volume then
		return 8
	elseif 1 <= volume then
		return 7
	elseif 0.9 <= volume then
		return 6
	elseif 0.8 <= volume then
		return 5
	elseif 0.7 <= volume then
		return 4
	elseif 0.6 <= volume then
		return 3
	elseif 0 < volume then
		return 2
	else
		return 1
	end
end
function Utils.getRecordingVolumeFromIndex(index)
	if index == 1 then
		return -1
	else
		return (index - 2) * 0.1 + 0.5
	end
end
function Utils.getFilename(filename, baseDir)
	if filename == nil then
		return nil
	end
	if type(filename) ~= "string" then
		Logging.warning("Invalid type for filename in Utils.getFilename")
		printCallstack()
		return nil
	end
	if string.find(filename, "\\", nil, true) then
		Logging.warning("backslash in filepath %q. This is not compatible with consoles", filename)
		printCallstack()
		filename = string.gsub(filename, "\\", "/")
	end
	if filename:sub(1, 1) == "$" then
		return g_gameBasePath .. filename:sub(2), false
	end
	if baseDir == nil or baseDir == "" then
		return filename, false
	end
	if filename == "" then
		return filename, true
	else
		return baseDir .. filename, true
	end
end
function Utils.getFilenameFromPath(path)
	path = path:gsub("\\", "/")
	local elems = path:split("/")
	return elems[#elems]
end
function Utils.getDirectory(filePath)
	filePath = filePath:gsub("\\", "/")
	local elems = filePath:split("/")
	if 0 < #elems then
		return table.concat(elems, "/", 1, #elems - 1) .. "/"
	else
		return filePath
	end
end
function Utils.getDirectoryName(directoryPath)
	directoryPath = directoryPath:gsub("\\", "/")
	if not string.endsWith(directoryPath, "/") then
		directoryPath = directoryPath .. "/"
	end
	local elems = directoryPath:split("/")
	if 1 < #elems then
		return elems[#elems - 1]
	else
		return nil
	end
end
function Utils.resolveRelativePath(path)
	while true do
		local formatIdentifier = string.match(path, "/[%a%d_]+/%.%./")
		if formatIdentifier == nil then
			break
		end
		path = string.gsub(path, formatIdentifier, "/")
	end
	if string.contains(path, "%.%./") then
		return nil
	else
		return path
	end
end
function Utils.getPathIsValid(path)
	if string.contains(path, "\\") and not string.startsWith(path, "\\\\?/GLOBALROOT/") then
		return false, "backslashes"
	end
	return true
end
function Utils.getMaxJointForceLimit(forceLimit1, forceLimit2)
	if forceLimit1 < 0 or forceLimit2 < 0 then
		return -1
	end
	return math.max(forceLimit1, forceLimit2)
end
function Utils.appendedFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function(...)
			oldFunc(...)
			newFunc(...)
		end
	else
		return newFunc
	end
end
function Utils.prependedFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function(...)
			newFunc(...)
			oldFunc(...)
		end
	else
		return newFunc
	end
end
function Utils.overwrittenFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function(...)
			return newFunc(self, oldFunc, ...)
		end
	else
		return function(...)
			return newFunc(self, nil, ...)
		end
	end
end
function Utils.shuffle(t)
	local n = #t
	while 2 < n do
		local k = math.random(n)
		t[n] = t[k]
		t[k] = t[n]
		n = n - 1
	end
end
function Utils.getFilenameInfo(filename, excludePath)
	local cleanFilename = filename
	local pos, _, extension = string.find(filename, "([^.]*)$")
	if pos == 1 then
		extension = nil
	else
		cleanFilename = string.sub(filename, 1, pos - 2)
		if excludePath ~= nil and excludePath then
			local lastSlash = cleanFilename:find("/[^/]*$")
			if lastSlash ~= nil then
				cleanFilename = string.sub(cleanFilename, lastSlash + 1)
			end
		end
	end
	return cleanFilename, extension
end
function Utils.stringToBoolean(booleanString)
	local boolValue = booleanString ~= nil and string.lower(booleanString) == "true"
	return boolValue
end
function Utils.parseConsoleParameter(str)
	if str == nil then
		return nil
	elseif str ~= "nil" then
		return str
	else
		return nil
	end
end
function Utils.getMinuteOfDayFromTime(value)
	if value ~= nil then
		local sepPos = string.find(value, ":")
		if sepPos ~= nil then
			local hours = tonumber(string.sub(value, 0, sepPos - 1))
			local minutes = tonumber(string.sub(value, sepPos + 1))
			if hours ~= nil and (minutes ~= nil and (hours <= 24 and minutes < 60)) then
				return hours * 60 + minutes
			end
		end
	end
	return nil
end
function Utils.formatTime(timeInMinutes)
	local timeHoursF = timeInMinutes / 60 + 0.0001
	local timeHours = math.floor(timeHoursF)
	local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
	return string.format("%02d:%02d", timeHours, timeMinutes)
end
function Utils.renderMultiColumnText(x, y, textSize, texts, spacingX, aligns)
	for i, text in ipairs(texts) do
		local align = aligns ~= nil and aligns[i] or RenderText.ALIGN_LEFT
		setTextAlignment(align)
		local w = getTextWidth(textSize, text)
		if align == RenderText.ALIGN_RIGHT then
			renderText(x + w, y, textSize, text)
		elseif align == RenderText.ALIGN_CENTER then
			renderText(x + w * 0.5, y, textSize, text)
		else
			renderText(x, y, textSize, text)
		end
		x = x + w + spacingX
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
end
function Utils.getCoinToss()
	return 0.5 <= math.random()
end
function Utils.getNormallyDistributedRandomVariables(mean, sigmaSq)
	local u = nil
	local v = nil
	local q = -1
	while not (1 <= q) do
		if q <= 0 then
			break
		end
		local p = math.sqrt(-2 * math.log(q) / 1 / q)
		local x1 = u * p
		local x2 = v * p
		local sigma = math.sqrt(sigmaSq)
		return mean + sigma * x1, mean + sigma * x2
	end
	u = -1 + 2 * math.random()
	v = -1 + 2 * math.random()
	q = u ^ 2 + v ^ 2
end
function Utils.getIntersectionOfLinearMovementAndTerrain(node, speed)
	local cx = nil
	local cy = nil
	local cz = nil
	local x0, y0, z0 = getWorldTranslation(node)
	local dx, dy, dz = localDirectionToWorld(node, 0, -1, 0)
	local vx = dx * speed
	local vy = dy * speed
	local vz = dz * speed
	local stepT = 1 / speed
	local maxT = 50 / speed
	for t = 2 * stepT, maxT, stepT do
		local x = x0 + vx * t
		local z = z0 + vz * t
		local y = y0 + vy * t - 4.905 * t * t
		local h = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		if y <= h then
			cx = x
			cy = h
			cz = z
			return cx, cy, cz
		end
		if VehicleDebug.state == VehicleDebug.DEBUG then
			drawDebugPoint(x, y, z, 0, 0, 1, 1)
		end
	end
	return cx, cy, cz
end
function Utils.clearBit(bitMask, bit)
	local bitFlag = 2 ^ bit
	return bit32.band(bitMask, bit32.bnot(bitFlag))
end
function Utils.setBit(bitMask, bit)
	local bitFlag = 2 ^ bit
	return bit32.bor(bitMask, bitFlag)
end
function Utils.isBitSet(bitMask, bit)
	local bitFlag = 2 ^ bit
	return bit32.band(bitMask, bitFlag) ~= 0
end
function Utils.clearFlags(bitMask, ...)
	return bit32.band(bitMask, bit32.bnot(bit32.bor(...)))
end
function Utils.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, r, g, b, a)
	local sx, sy, sz = project(x, y, z)
	if -1 < sx and (sx < 2 and (-1 < sy and (sy < 2 and sz <= 1))) then
		textSize = textSize or 0.02
		local textWidth = getTextWidth(textSize, text)
		local textHeight = getTextHeight(textSize, text)
		if sx + textWidth < 0 or 1 < sx - textWidth or sy + textHeight < 0 or 1 < sy - textHeight then
			return
		end
		if type(r) == "table" then
			r, g, b, a = unpack(r)
		end
		textOffset = textOffset or 0
		sy = sy + textHeight - textSize
		r = r or 0.5
		g = g or 1
		b = b or 0.5
		a = a or 1
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(false)
		setTextColor(0, 0, 0, 0.75)
		renderText(sx, sy - 0.0015 + textOffset, textSize, text)
		setTextColor(r, g, b, a)
		renderText(sx, sy + textOffset, textSize, text)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
	end
end
function Utils.getGreenRedBlendedColor(factor)
	local r = math.min(2 * factor, 1)
	local g = math.min(2 * (1 - factor), 1)
	return r, g, 0, 1
end
function Utils.maskToFormat(textMask)
	textMask = textMask:gsub("%%", "=")
	local textFormatStr = ""
	local textFormatPrecision = 0
	local isLeadingNumber = true
	local numDigits = 0
	for i = 1, textMask:len() do
		if textMask:sub(i, i) == "0" then
			numDigits = numDigits + 1
		else
			if 0 < numDigits then
				textFormatStr = textFormatStr .. string.format(isLeadingNumber and "%%%dd" or "%%0%dd", numDigits)
				textFormatPrecision = numDigits
				numDigits = 0
				isLeadingNumber = false
			end
			textFormatStr = textFormatStr .. textMask:sub(i, i)
		end
	end
	if 0 < numDigits then
		textFormatStr = textFormatStr .. string.format(isLeadingNumber and "%%%dd" or "%%0%dd", numDigits)
		textFormatPrecision = numDigits
	end
	textFormatStr = textFormatStr:gsub("=", "%%%%")
	if isLeadingNumber then
		textFormatPrecision = 0
	end
	return textFormatStr, textFormatPrecision
end
function Utils.getClosestMatchingString(str, listOfStrings, maxDistance, caseSensitive)
	maxDistance = maxDistance or math.huge
	if not caseSensitive then
		str = utf8ToUpper(str)
	end
	local bestMatch = nil
	local bestMatchLevenshteinDistance = math.huge
	for _, str2 in ipairs(listOfStrings) do
		local levenshteinDistance = getLevenshteinDistance(str, caseSensitive and str2 or utf8ToUpper(str2))
		if levenshteinDistance < maxDistance and levenshteinDistance < bestMatchLevenshteinDistance then
			bestMatch = str2
			bestMatchLevenshteinDistance = levenshteinDistance
			if levenshteinDistance ~= 0 then
				continue
			end
			return bestMatch, bestMatchLevenshteinDistance
		end
	end
end
function Utils.getNumOfWords(str)
	local _, count = string.gsub(str, "(%w+)", "")
	return count
end
function Utils.getVersionParts(versionStr)
	local versionParts = string.split(versionStr, ".")
	for i, part in ipairs(versionParts) do
		versionParts[i] = tonumber(string.match(part, "%d+")) or 0
	end
	return versionParts
end
function Utils.compareVersions(version1, version2)
	for k, numberV1 in ipairs(version1) do
		if #version2 < k then
			break
		end
		if version2[k] < numberV1 then
			return 1
		end
		if numberV1 < version2[k] then
			return -1
		end
	end
	return 0
end
function Utils.compareVersionStrings(version1, version2)
	local versionParts1 = Utils.getVersionParts(version1)
	local versionParts2 = Utils.getVersionParts(version2)
	return Utils.compareVersions(versionParts1, versionParts2)
end
function Utils.naturalSort(tbl, keyFn)
	local getNaturalSortKey = function(value)
		assert(type(value) == "string" or type(value) == "number", "Utils.naturalSort key must be a string or number, got " .. type(value))
		local s = string.lower(tostring(value))
		local key = {}
		local i = 1
		while i <= #s do
			local chunk = string.match(s, "^%d+", i)
			if chunk ~= nil then
				key[#key + 1] = tonumber(chunk)
				i = i + #chunk
			else
				chunk = string.match(s, "^%D+", i)
				if chunk == nil then
					break
				end
				key[#key + 1] = chunk
				i = i + #chunk
			end
		end
		return key
	end
	local decorated = {}
	for i, v in ipairs(tbl) do
		decorated[i] = { index = i, value = v, key = getNaturalSortKey(keyFn(v)) }
	end
	table.sort(decorated, function(a, b)
		local keyA = a.key
		local keyB = b.key
		for i = 1, math.min(#keyA, #keyB) do
			local va = keyA[i]
			local vb = keyB[i]
			if va == vb then
				continue
			end
			local ta = type(va)
			local tb = type(vb)
			if ta ~= tb then
				return ta == "number"
			else
				return va < vb
			end
		end
		if #keyA ~= #keyB then
			return #keyA < #keyB
		else
			return a.index < b.index
		end
	end)
	for i, entry in ipairs(decorated) do
		tbl[i] = entry.value
	end
	return tbl
end
