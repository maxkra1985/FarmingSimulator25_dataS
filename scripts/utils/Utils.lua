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

-- Local values: replaceTextWidth, indexOfFirstCharacter, indexOfLastCharacter, totalWidth
function Utils.limitTextToWidth(text, textSize, width, trimFront, trimReplaceText)
	local v10_ = getTextWidth(textSize, trimReplaceText)
	local v11_ = 1
	local v12_ = utf8Strlen(text)
	if width >= 0 then
		local v13_ = getTextWidth(textSize, text)
		if width < v13_ then
			if trimFront then
				v11_ = getTextLineLength(textSize, text, v13_ - width + v10_)
				text = trimReplaceText .. utf8Substr(text, v11_)
			else
				v12_ = getTextLineLength(textSize, text, width - v10_)
				text = utf8Substr(text, 0, v12_) .. trimReplaceText
			end
		end
	end
	return text, v11_, v12_
end

-- Local values: limitF, limitF2
function Utils.getMovedLimitedValue(curVal, maxVal, minVal, speed, dt, inverted)
	local v20_ = math.min
	local v21_ = math.max
	if inverted then
		local v22_ = minVal
		minVal = maxVal
		maxVal = v22_
	end
	if maxVal < minVal then
		v20_ = math.max
		v21_ = math.min
	elseif maxVal == minVal then
		return minVal
	end
	return v21_(v20_(curVal + (maxVal - minVal) / speed * dt, maxVal), minVal)
end

-- Local values: ret, i
function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
	local v30_ = table.create(numValues)
	for v31_ = 1, numValues do
		v30_[v31_] = Utils.getMovedLimitedValue(currentValues[v31_], maxValues[v31_], minValues[v31_], speed, dt, inverted)
	end
	return v30_
end

-- Local values: changed, i, newValue
function Utils.setMovedLimitedValues(values, maxValues, minValues, numValues, speed, dt, inverted)
	local v39_ = false
	for v40_ = 1, numValues do
		local v41_ = Utils.getMovedLimitedValue(values[v40_], maxValues[v40_], minValues[v40_], speed, dt, inverted)
		if v41_ ~= values[v40_] then
			values[v40_] = v41_
			v39_ = true
		end
	end
	return v39_
end

-- Local values: isMod, isDlc, dlcsDirectoryIndex, filenameLower, modsDirLen, modsDirLower, internalModsDirLen, i, dlcDirectory, dlcsDir, dlcsDirLen
function Utils.removeModDirectory(filename)
	local v43_ = false
	local v44_ = false
	local v45_ = 0
	if filename == nil then
		printCallstack()
	end
	local v46_ = string.lower(filename)
	if g_modsDirectory then
		local v47_ = g_modsDirectory:len()
		if string.lower(g_modsDirectory) == v46_:sub(1, v47_) then
			filename = filename:sub(v47_ + 1)
			v43_ = true
		end
		if not (v43_ or string.isNilOrWhitespace(g_internalModsDirectory)) then
			local v48_ = g_internalModsDirectory:len()
			if v46_:sub(1, v48_) == string.lower(g_internalModsDirectory) then
				filename = filename:sub(v48_ + 1)
				v43_ = true
			end
		end
	end
	if not v43_ and g_dlcsDirectories ~= nil then
		for v49_, v50_ in ipairs(g_dlcsDirectories) do
			local v51_ = string.lower(v50_.path)
			local v52_ = v51_:len()
			if v46_:sub(1, v52_) == v51_ then
				return filename:sub(v52_ + 1), v43_, true, v49_
			end
		end
	end
	return filename, v43_, v44_, v45_
end

-- Local values: uniqueId, i, md5
function Utils.getUniqueId(value, mappingTable, prefix, md5Length)
	if type(md5Length) ~= "number" or (md5Length <= 0 or md5Length >= 32) then
		md5Length = nil
	end
	local v57_ = 0
	local v58_ = prefix or ""
	while true do
		local v59_ = getMD5
		local v60_ = tostring(value)
		local v61_ = getTime
		local v62_ = v59_(v60_ .. tostring(v61_()) .. tostring(v57_))
		local v63_
		if md5Length == nil then
			v63_ = v58_ .. v62_
		else
			v63_ = v58_ .. string.sub(v62_, 1, md5Length)
		end
		v57_ = v57_ + 1
		if mappingTable == nil or mappingTable[v63_] == nil then
			return v63_
		end
	end
end

-- Local values: modName, baseDirectory, modFilename, isMod, isDlc, dlcsDirectoryIndex, f, l
function Utils.getModNameAndBaseDirectory(filename)
	local v65_ = nil
	local v66_ = ""
	local v67_, v68_, v69_, v70_ = Utils.removeModDirectory(filename)
	if v68_ or v69_ then
		local v71_, v72_ = v67_:find("/")
		if v71_ ~= nil and (v72_ ~= nil and v71_ > 1) then
			v65_ = v67_:sub(1, v71_ - 1)
			if v69_ then
				v66_ = g_dlcsDirectories[v70_].path .. v65_ .. "/"
				if g_dlcModNameHasPrefix[v65_] then
					return g_uniqueDlcNamePrefix .. v65_, v66_
				end
			else
				v66_ = g_modNameToDirectory[v65_] or g_modsDirectory .. v65_ .. "/"
			end
		end
	end
	return v65_, v66_
end

-- Local values: vx, vy, vz, x, _, z, length, steeringAngle
function Utils.getVersatileRotation(repr, componentNode, dt, posX, posY, posZ, currentAngle, minAngle, maxAngle)
	local v82_, v83_, v84_ = getVelocityAtLocalPos(componentNode, posX, posY, posZ)
	local v85_, _, v86_ = worldDirectionToLocal(getParent(repr), v82_, v83_, v84_)
	local v87_ = MathUtil.vector2Length(v85_, v86_)
	local v88_
	if v87_ > 0.15 then
		local v89_ = v85_ / v87_
		local v90_ = v86_ / v87_
		v88_ = math.atan2(v89_, v90_)
		if v88_ < -1.5707963267948966 then
			v88_ = v88_ + 6.283185307179586
		end
	else
		v88_ = currentAngle
	end
	if minAngle == nil or (minAngle == 0 or (maxAngle == nil or maxAngle == 0)) then
		minAngle = v88_
	elseif maxAngle < v88_ then
		minAngle = maxAngle
	elseif v88_ >= minAngle then
		minAngle = v88_
	end
	local v91_ = MathUtil.normalizeRotationForShortestPath(minAngle, currentAngle)
	if currentAngle < v91_ then
		local v92_ = currentAngle + 0.003 * dt
		return math.min(v92_, v91_)
	else
		local v93_ = currentAngle - 0.003 * dt
		return math.max(v93_, v91_)
	end
end

-- Local values: dirX1, dirZ1, dirX2, dirZ2, wDirX1, _, wDirZ1, wDirX2, _, wDirZ2, dir, angle
function Utils.getYRotationBetweenNodes(node1, node2, offset1, offset2, wrapRotation)
	local v99_ = 0
	local v100_ = 1
	local v101_, v102_
	if offset1 == nil or offset1 == 0 then
		v101_ = 0
		v102_ = 1
	else
		v101_, v102_ = MathUtil.getDirectionFromYRotation(offset1)
	end
	if offset2 ~= nil and offset2 ~= 0 then
		v99_, v100_ = MathUtil.getDirectionFromYRotation(offset2)
	end
	local v103_, _, v104_ = localDirectionToWorld(node1, v101_, 0, v102_)
	local v105_, _, v106_ = localDirectionToWorld(node2, v99_, 0, v100_)
	local v107_, _, v108_ = worldDirectionToLocal(node1, v103_, 0, v104_)
	local v109_, _, v110_ = worldDirectionToLocal(node1, v105_, 0, v106_)
	local v111_ = 1
	if v107_ - v109_ > 0 then
		v111_ = -v111_
	end
	local v112_ = MathUtil.getVectorAngleDifference(v107_, 0, v108_, v109_, 0, v110_)
	if wrapRotation ~= false and math.abs(v112_) > 1.5707963267948966 then
		v112_ = -(3.141592653589793 - v112_)
	end
	return v112_ * v111_
end

-- Local values: currentProfileIndex
function Utils.getPerformanceClassIndex(profileClass)
	local v114_ = string.lower(profileClass)
	local v115_ = GS_PROFILE_LOW
	if v114_ == "very low" then
		return GS_PROFILE_VERY_LOW
	end
	if v114_ == "low" then
		return GS_PROFILE_LOW
	end
	if v114_ == "medium" then
		return GS_PROFILE_MEDIUM
	end
	if v114_ == "high" then
		return GS_PROFILE_HIGH
	end
	if v114_ == "very high" then
		return GS_PROFILE_VERY_HIGH
	end
	if v114_ == "ultra" then
		return GS_PROFILE_ULTRA
	end
	print("ERROR: performanceClass \'" .. v114_ .. "\' not recognized; using LOW")
	return v115_
end

-- Local values: currentProfileClass
function Utils.getPerformanceClassFromIndex(profileClassIndex)
	return profileClassIndex == GS_PROFILE_VERY_LOW and "Very Low" or (profileClassIndex == GS_PROFILE_MEDIUM and "Medium" or (profileClassIndex == GS_PROFILE_HIGH and "High" or (profileClassIndex == GS_PROFILE_VERY_HIGH and "Very High" or (profileClassIndex == GS_PROFILE_ULTRA and "Ultra" or "Low"))))
end
function Utils.getPerformanceClassId()
	return Utils.getPerformanceClassIndex(getPerformanceClass())
end

-- Local values: state, i
function Utils.getStateFromValues(values, steps, value)
	local v120_ = #values
	for v121_ = 1, #values do
		if value <= values[v121_] + steps * 0.5 then
			return v121_
		end
	end
	return v120_
end

-- Local values: index, threshold, k, val
function Utils.getValueIndex(targetValue, values)
	local v124_ = 1
	for v125_, v126_ in pairs(values) do
		if targetValue < v126_ - 0.0001 then
			break
		end
		v124_ = v125_
	end
	return v124_
end
function Utils.getNumTimeScales()
	local v127_ = #Platform.gameplay.timeScaleSettings
	if g_addTestCommands then
		v127_ = v127_ + #Platform.gameplay.timeScaleDevSettings
	end
	return v127_
end

-- Local values: timeScaleSettings, speed
function Utils.getTimeScaleString(timeScaleIndex)
	local v129_ = Platform.gameplay.timeScaleSettings
	local v130_ = Utils.getTimeScaleFromIndex(timeScaleIndex)
	if v130_ == 1 then
		return g_i18n:getText("ui_realTime")
	elseif #v129_ < timeScaleIndex then
		return string.format("%dx (dev only)", v130_)
	elseif v130_ < 1 then
		return string.format("%0.2fx", v130_)
	else
		return string.format("%dx", v130_)
	end
end

-- Local values: timeScaleSettings, timeScaleDevSettings, i, i
function Utils.getTimeScaleIndex(timeScale)
	local v132_ = Platform.gameplay.timeScaleSettings
	if g_addTestCommands then
		local v133_ = Platform.gameplay.timeScaleDevSettings
		for v134_ = #v133_, 1, -1 do
			if v133_[v134_] <= timeScale then
				return v134_ + #v132_
			end
		end
	end
	for v135_ = #v132_, 1, -1 do
		if v132_[v135_] <= timeScale then
			return v135_
		end
	end
	return 3
end

-- Local values: timeScaleSettings, timeScaleDevSettings
function Utils.getTimeScaleFromIndex(timeScaleIndex)
	local v137_ = Platform.gameplay.timeScaleSettings
	local v138_ = math.max(timeScaleIndex, 1)
	if g_addTestCommands and #v137_ < v138_ then
		return Platform.gameplay.timeScaleDevSettings[v138_ - #v137_]
	else
		return v137_[v138_]
	end
end

-- Local values: masterVolumeIndex
function Utils.getMasterVolumeIndex(masterVolume)
	local v140_ = masterVolume + 0.01
	return v140_ >= 1 and 11 or (v140_ >= 0.9 and 10 or (v140_ >= 0.8 and 9 or (v140_ >= 0.7 and 8 or (v140_ >= 0.6 and 7 or (v140_ >= 0.5 and 6 or (v140_ >= 0.4 and 5 or (v140_ >= 0.3 and 4 or (v140_ >= 0.2 and 3 or (v140_ >= 0.1 and 2 or 1)))))))))
end

function Utils.getMasterVolumeFromIndex(masterVolumeIndex)
	return (masterVolumeIndex < 1 or masterVolumeIndex > 10) and 1 or (masterVolumeIndex - 1) * 0.1
end

-- Local values: uiScaleIndex, currentScale
function Utils.getUIScaleIndex(uiScale)
	local v143_ = uiScale + 0.01
	local v144_ = 0.55
	local v145_ = 1
	while v144_ < v143_ do
		v145_ = v145_ + 1
		v144_ = v144_ + 0.05
	end
	return v145_
end

function Utils.getUIScaleFromIndex(uiScaleIndex)
	return uiScaleIndex < 1 and 1 or (uiScaleIndex - 1) * 0.05 + 0.5
end

function Utils.getRecordingVolumeIndex(volume)
	local v148_ = volume + 0.01
	return v148_ >= 1.5 and 12 or (v148_ >= 1.4 and 11 or (v148_ >= 1.3 and 10 or (v148_ >= 1.2 and 9 or (v148_ >= 1.1 and 8 or (v148_ >= 1 and 7 or (v148_ >= 0.9 and 6 or (v148_ >= 0.8 and 5 or (v148_ >= 0.7 and 4 or (v148_ >= 0.6 and 3 or (v148_ > 0 and 2 or 1))))))))))
end

function Utils.getRecordingVolumeFromIndex(index)
	return index == 1 and -1 or (index - 2) * 0.1 + 0.5
end

function Utils.getFilename(filename, baseDir)
	if filename == nil then
		return nil
	elseif type(filename) == "string" then
		if string.find(filename, "\\", nil, true) then
			Logging.warning("backslash in filepath %q. This is not compatible with consoles", filename)
			printCallstack()
			filename = string.gsub(filename, "\\", "/")
		end
		if filename:sub(1, 1) == "$" then
			return g_gameBasePath .. filename:sub(2), false
		elseif baseDir == nil or baseDir == "" then
			return filename, false
		elseif filename == "" then
			return filename, true
		else
			return baseDir .. filename, true
		end
	else
		Logging.warning("Invalid type for filename in Utils.getFilename")
		printCallstack()
		return nil
	end
end

-- Local values: elems
function Utils.getFilenameFromPath(path)
	local v153_ = path:gsub("\\", "/"):split("/")
	return v153_[#v153_]
end

-- Local values: elems
function Utils.getDirectory(filePath)
	local v155_ = filePath:gsub("\\", "/")
	local v156_ = v155_:split("/")
	if #v156_ > 0 then
		return table.concat(v156_, "/", 1, #v156_ - 1) .. "/"
	else
		return v155_
	end
end

-- Local values: elems
function Utils.getDirectoryName(directoryPath)
	local v158_ = directoryPath:gsub("\\", "/")
	if not string.endsWith(v158_, "/") then
		v158_ = v158_ .. "/"
	end
	local v159_ = v158_:split("/")
	if #v159_ > 1 then
		return v159_[#v159_ - 1]
	else
		return nil
	end
end

-- Local values: formatIdentifier
function Utils.resolveRelativePath(path)
	while true do
		local v161_ = string.match(path, "/[%a%d_]+/%.%./")
		if v161_ == nil then
			break
		end
		path = string.gsub(path, v161_, "/")
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
	else
		return true
	end
end

function Utils.getMaxJointForceLimit(forceLimit1, forceLimit2)
	return (forceLimit1 < 0 or forceLimit2 < 0) and -1 or math.max(forceLimit1, forceLimit2)
end

function Utils.appendedFunction(oldFunc, newFunc)
	return oldFunc ~= nil and function(...)
		-- upvalues: (copy) oldFunc, (copy) newFunc
		oldFunc(...)
		newFunc(...)
	end or newFunc
end

function Utils.prependedFunction(oldFunc, newFunc)
	return oldFunc ~= nil and function(...)
		-- upvalues: (copy) newFunc, (copy) oldFunc
		newFunc(...)
		oldFunc(...)
	end or newFunc
end

function Utils.overwrittenFunction(oldFunc, newFunc)
	return oldFunc == nil and function(p171_, ...)
		-- upvalues: (copy) newFunc
		return newFunc(p171_, nil, ...)
	end or function(p172_, ...)
		-- upvalues: (copy) newFunc, (copy) oldFunc
		return newFunc(p172_, oldFunc, ...)
	end
end

-- Local values: n, k
function Utils.shuffle(t)
	local v174_ = #t
	while v174_ > 2 do
		local v175_ = math.random(v174_)
		local v176_ = t[v175_]
		local v177_ = t[v174_]
		t[v174_] = v176_
		t[v175_] = v177_
		v174_ = v174_ - 1
	end
end

-- Local values: cleanFilename, pos, _, extension, lastSlash
function Utils.getFilenameInfo(filename, excludePath)
	local v180_, _, v181_ = string.find(filename, "([^.]*)$")
	if v180_ == 1 then
		v181_ = nil
	else
		local v182_ = v180_ - 2
		filename = string.sub(filename, 1, v182_)
		if excludePath ~= nil and excludePath then
			local v183_ = filename:find("/[^/]*$")
			if v183_ ~= nil then
				local v184_ = v183_ + 1
				filename = string.sub(filename, v184_)
			end
		end
	end
	return filename, v181_
end

-- Local values: boolValue
function Utils.stringToBoolean(booleanString)
	local v186_
	if booleanString == nil then
		v186_ = false
	else
		v186_ = string.lower(booleanString) == "true"
	end
	return v186_
end

function Utils.parseConsoleParameter(str)
	if str == nil then
		return nil
	elseif str == "nil" then
		return nil
	else
		return str
	end
end

-- Local values: sepPos, hours, minutes
function Utils.getMinuteOfDayFromTime(value)
	if value ~= nil then
		local v189_ = string.find(value, ":")
		if v189_ ~= nil then
			local v190_ = v189_ - 1
			local v191_ = string.sub(value, 0, v190_)
			local v192_ = tonumber(v191_)
			local v193_ = v189_ + 1
			local v194_ = string.sub(value, v193_)
			local v195_ = tonumber(v194_)
			if v192_ ~= nil and (v195_ ~= nil and (v192_ <= 24 and v195_ < 60)) then
				return v192_ * 60 + v195_
			end
		end
	end
	return nil
end

-- Local values: timeHoursF, timeHours, timeMinutes
function Utils.formatTime(timeInMinutes)
	local v197_ = timeInMinutes / 60 + 0.0001
	local v198_ = math.floor(v197_)
	local v199_ = (v197_ - v198_) * 60
	local v200_ = math.floor(v199_)
	return string.format("%02d:%02d", v198_, v200_)
end

-- Local values: i, text, align, w
function Utils.renderMultiColumnText(x, y, textSize, texts, spacingX, aligns)
	for v207_, v208_ in ipairs(texts) do
		local v209_ = aligns ~= nil and aligns[v207_] or RenderText.ALIGN_LEFT
		setTextAlignment(v209_)
		local v210_ = getTextWidth(textSize, v208_)
		if v209_ == RenderText.ALIGN_RIGHT then
			renderText(x + v210_, y, textSize, v208_)
		elseif v209_ == RenderText.ALIGN_CENTER then
			renderText(x + v210_ * 0.5, y, textSize, v208_)
		else
			renderText(x, y, textSize, v208_)
		end
		x = x + v210_ + spacingX
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
end
function Utils.getCoinToss()
	return math.random() >= 0.5
end

-- Local values: u, v, q, p, x1, x2, sigma
function Utils.getNormallyDistributedRandomVariables(mean, sigmaSq)
	local v213_ = -1
	local v214_ = nil
	local v215_ = nil
	while v213_ >= 1 or v213_ <= 0 do
		v214_ = -1 + 2 * math.random()
		v215_ = -1 + 2 * math.random()
		v213_ = v214_ ^ 2 + v215_ ^ 2
	end
	local v216_ = -2 * math.log(v213_) / 1 / v213_
	local v217_ = math.sqrt(v216_)
	local v218_ = v214_ * v217_
	local v219_ = v215_ * v217_
	local v220_ = math.sqrt(sigmaSq)
	return mean + v220_ * v218_, mean + v220_ * v219_
end

-- Local values: cx, cy, cz, x0, y0, z0, dx, dy, dz, vx, vy, vz, stepT, maxT, t, x, z, y, h
function Utils.getIntersectionOfLinearMovementAndTerrain(node, speed)
	local v223_, v224_, v225_ = getWorldTranslation(node)
	local v226_, v227_, v228_ = localDirectionToWorld(node, 0, -1, 0)
	local v229_ = v226_ * speed
	local v230_ = v227_ * speed
	local v231_ = v228_ * speed
	local v232_ = 1 / speed
	local v233_ = 50 / speed
	local v234_ = nil
	local v235_ = nil
	local v236_ = nil
	for v237_ = 2 * v232_, v233_, v232_ do
		local v238_ = v223_ + v229_ * v237_
		local v239_ = v225_ + v231_ * v237_
		local v240_ = v224_ + v230_ * v237_ - 4.905 * v237_ * v237_
		local v241_ = getTerrainHeightAtWorldPos(g_terrainNode, v238_, 0, v239_)
		if v240_ <= v241_ then
			return v238_, v241_, v239_
		end
		if VehicleDebug.state == VehicleDebug.DEBUG then
			drawDebugPoint(v238_, v240_, v239_, 0, 0, 1, 1)
		end
	end
	return v234_, v235_, v236_
end

-- Local values: bitFlag
function Utils.clearBit(bitMask, bit)
	local v244_ = 2 ^ bit
	local v245_ = bit32.bnot(v244_)
	return bit32.band(bitMask, v245_)
end

-- Local values: bitFlag
function Utils.setBit(bitMask, bit)
	local v248_ = 2 ^ bit
	return bit32.bor(bitMask, v248_)
end

-- Local values: bitFlag
function Utils.isBitSet(bitMask, bit)
	local v251_ = 2 ^ bit
	return bit32.band(bitMask, v251_) ~= 0
end
function Utils.clearFlags(p252_, ...)
	local v253_ = bit32.bor(...)
	local v254_ = bit32.bnot(v253_)
	return bit32.band(p252_, v254_)
end

-- Local values: sx, sy, sz, textWidth, textHeight
function Utils.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, r, g, b, a)
	local v265_, v266_, v267_ = project(x, y, z)
	if v265_ > -1 and (v265_ < 2 and (v266_ > -1 and (v266_ < 2 and v267_ <= 1))) then
		local v268_ = textSize or 0.02
		local v269_ = getTextWidth(v268_, text)
		local v270_ = getTextHeight(v268_, text)
		if v265_ + v269_ < 0 or (v265_ - v269_ > 1 or (v266_ + v270_ < 0 or v266_ - v270_ > 1)) then
			return
		end
		if type(r) == "table" then
			r, g, b, a = unpack(r)
		end
		local v271_ = textOffset or 0
		local v272_ = v266_ + v270_ - v268_
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(false)
		setTextColor(0, 0, 0, 0.75)
		renderText(v265_, v272_ - 0.0015 + v271_, v268_, text)
		setTextColor(r or 0.5, g or 1, b or 0.5, a or 1)
		renderText(v265_, v272_ + v271_, v268_, text)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
	end
end

-- Local values: r, g
function Utils.getGreenRedBlendedColor(factor)
	local v274_ = 2 * factor
	local v275_ = math.min(v274_, 1)
	local v276_ = 2 * (1 - factor)
	return v275_, math.min(v276_, 1), 0, 1
end

-- Local values: textFormatStr, textFormatPrecision, isLeadingNumber, numDigits, i
function Utils.maskToFormat(textMask)
	local v278_ = textMask:gsub("%%", "=")
	local v279_ = 0
	local v280_ = ""
	local v281_ = true
	local v282_ = 0
	for v283_ = 1, v278_:len() do
		if v278_:sub(v283_, v283_) == "0" then
			v279_ = v279_ + 1
		else
			local v284_
			if v279_ > 0 then
				v280_ = v280_ .. string.format(v281_ and "%%%dd" or "%%0%dd", v279_)
				v284_ = 0
				v281_ = false
			else
				v284_ = v279_
				v279_ = v282_
			end
			v280_ = v280_ .. v278_:sub(v283_, v283_)
			v282_ = v279_
			v279_ = v284_
		end
	end
	if v279_ > 0 then
		v280_ = v280_ .. string.format(v281_ and "%%%dd" or "%%0%dd", v279_)
	else
		v279_ = v282_
	end
	return v280_:gsub("=", "%%%%"), v281_ and 0 or v279_
end

-- Local values: bestMatch, bestMatchLevenshteinDistance, _, str2, levenshteinDistance
function Utils.getClosestMatchingString(str, listOfStrings, maxDistance, caseSensitive)
	local v289_ = maxDistance or math.huge
	if not caseSensitive then
		str = utf8ToUpper(str)
	end
	local v290_ = math.huge
	local v291_ = nil
	for _, v292_ in ipairs(listOfStrings) do
		local v293_ = getLevenshteinDistance(str, caseSensitive and v292_ and v292_ or utf8ToUpper(v292_))
		if v293_ < v289_ and v293_ < v290_ then
			if v293_ == 0 then
				v290_ = v293_
				v291_ = v292_
				break
			end
			v291_ = v292_
			v290_ = v293_
		end
	end
	return v291_, v290_
end

-- Local values: _, count
function Utils.getNumOfWords(str)
	local _, v295_ = string.gsub(str, "(%w+)", "")
	return v295_
end

-- Local values: k, numberV1
function Utils.compareVersions(version1, version2)
	for v298_, v299_ in ipairs(version1) do
		if #version2 < v298_ then
			break
		end
		if version2[v298_] < v299_ then
			return 1
		end
		if v299_ < version2[v298_] then
			return -1
		end
	end
	return 0
end

-- Local values: v1, v2, i, part, i, part
function Utils.compareVersionStrings(version1, version2)
	local v302_ = string.split(version1, ".")
	local v303_ = string.split(version2, ".")
	for v304_, v305_ in ipairs(v302_) do
		local v306_ = string.match
		v302_[v304_] = tonumber(v306_(v305_, "%d+")) or 0
	end
	for v307_, v308_ in ipairs(v303_) do
		local v309_ = string.match
		v303_[v307_] = tonumber(v309_(v308_, "%d+")) or 0
	end
	return Utils.compareVersions(v302_, v303_)
end

-- Local values: getNaturalSortKey, decorated, i, v, i, entry
function Utils.naturalSort(tbl, keyFn)
	local function v320_(p312_)
		local v313_ = type(p312_) == "string" and true or type(p312_) == "number"
		local v314_ = "Utils.naturalSort key must be a string or number, got " .. type(p312_)
		assert(v313_, v314_)
		local v315_ = string.lower((tostring(p312_)))
		local v316_ = 1
		local v317_ = {}
		while v316_ <= #v315_ do
			local v318_ = string.match(v315_, "^%d+", v316_)
			if v318_ == nil then
				local v319_ = string.match(v315_, "^%D+", v316_)
				if v319_ == nil then
					break
				end
				v317_[#v317_ + 1] = v319_
				v316_ = v316_ + #v319_
			else
				v317_[#v317_ + 1] = tonumber(v318_)
				v316_ = v316_ + #v318_
			end
		end
		return v317_
	end
	local v321_ = {}
	for v322_, v323_ in ipairs(tbl) do
		v321_[v322_] = {
			["key"] = v320_(keyFn(v323_)),
			["index"] = v322_,
			["value"] = v323_
		}
	end
	table.sort(v321_, function(p324_, p325_)
		local v326_ = p324_.key
		local v327_ = p325_.key
		local v328_ = #v326_
		local v329_ = #v327_
		for v330_ = 1, math.min(v328_, v329_) do
			local v331_ = v326_[v330_]
			local v332_ = v327_[v330_]
			if v331_ ~= v332_ then
				local v333_ = type(v331_)
				if v333_ == type(v332_) then
					return v331_ < v332_
				else
					return v333_ == "number"
				end
			end
		end
		if #v326_ == #v327_ then
			return p324_.index < p325_.index
		else
			return #v326_ < #v327_
		end
	end)
	for v334_, v335_ in ipairs(v321_) do
		tbl[v334_] = v335_.value
	end
	return tbl
end
