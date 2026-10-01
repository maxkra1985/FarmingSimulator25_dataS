GuiUtils = {}
function GuiUtils.getNormalizedValues(data, refSize, defaultValue)
	if data ~= nil then
		local parts = data
		local isString = type(data) == "string"
		if isString then
			parts = data:split(" ")
		end
		local values = {}
		for k, part in pairs(parts) do
			local value = part
			if isString then
				local isPixelValue = false
				local isDisplayPixelValue = false
				if string.find(value, "px") ~= nil then
					isPixelValue = true
					value = string.gsub(value, "px", "")
				elseif string.find(value, "dp") ~= nil then
					isDisplayPixelValue = true
					value = string.gsub(value, "dp", "")
				end
				value = tonumber(value)
				if isDisplayPixelValue then
					local s = (k + 1) % 2
					if s == 0 then
						value = value * g_pixelSizeX
					else
						value = value * g_pixelSizeY
					end
				elseif isPixelValue then
					value = value / refSize[(k + 1) % 2 + 1]
				end
			else
				value = value / refSize[(k + 1) % 2 + 1]
			end
			table.insert(values, value)
		end
		if defaultValue ~= nil and #parts < #defaultValue then
			local wrap = #parts
			for i = #parts + 1, #defaultValue do
				table.insert(values, values[(i - 1) % wrap + 1])
			end
		end
		return values
	else
		return defaultValue
	end
end
function GuiUtils.getNormalizedTextSize(str, refSize, defaultValue)
	if str ~= nil then
		local isPixelValue = false
		local isDisplayPixelValue = false
		if string.find(str, "px") ~= nil then
			isPixelValue = true
			str = string.gsub(str, "px", "")
		elseif string.find(str, "dp") ~= nil then
			isDisplayPixelValue = true
			str = string.gsub(str, "dp", "")
		end
		local value = tonumber(str)
		if value == nil then
			printCallstack()
		end
		if isPixelValue then
			return value / (refSize or g_screenHeight)
		end
		if isDisplayPixelValue then
			return value * g_pixelSizeY
		end
	end
	return defaultValue
end
function GuiUtils.getNormalizedValue(str, isXValue, default)
	if str == nil then
		return default
	else
		local number = str
		local isString = type(str) == "string"
		local isPixelSize = false
		local isDisplayPixel = false
		if isString then
			if string.find(str, "px") ~= nil then
				str = string.gsub(str, "px", "")
				isPixelSize = true
			elseif string.find(str, "dp") ~= nil then
				str = string.gsub(str, "dp", "")
				isDisplayPixel = true
			end
			number = tonumber(str)
			if number == nil then
				Logging.warning("GuiUtils.getNormalizedValue: String %q could not be converted to a number", str)
				return default
			end
		end
		local screenSizeValue = 1
		local scalingValue = 1
		if isPixelSize then
			screenSizeValue = isXValue and g_referenceScreenWidth or g_referenceScreenHeight
			scalingValue = isXValue and g_aspectScaleX or g_aspectScaleY
		elseif isDisplayPixel then
			screenSizeValue = isXValue and g_screenWidth or g_screenHeight
		end
		number = number / screenSizeValue * scalingValue
		return number
	end
end
function GuiUtils.getNormalizedScreenValues(values, default)
	if values == nil then
		return default
	else
		local normValues = {}
		local isString = type(values) == "string"
		if isString then
			values = string.split(values, " ")
		end
		for i = 1, #values do
			local defaultVal = default ~= nil and default[i] or default
			normValues[i] = GuiUtils.getNormalizedValue(values[i], i % 2 == 1, defaultVal, true)
		end
		return normValues
	end
end
function GuiUtils.getNormalizedXValue(x, default)
	return GuiUtils.getNormalizedValue(x, true, default)
end
function GuiUtils.getNormalizedYValue(y, default)
	return GuiUtils.getNormalizedValue(y, false, default)
end
function GuiUtils.getColorArray(colorStr, defaultValue)
	return string.getVector(colorStr, 4) or defaultValue
end
function GuiUtils.getColorGradientArray(colorStr, defaultValue)
	local data = string.getVector(colorStr)
	if data ~= nil and (#data == 4 or #data == 16) then
		return data
	end
	return defaultValue
end
function GuiUtils.validateUvs(str)
	local parts = string.split(str, " ")
	if #parts ~= 2 and #parts ~= 4 then
		return false, "Needs to be 2- or 4-vector"
	end
	for _, part in ipairs(parts) do
		local number = tonumber(part)
		if number ~= nil and (number < 0 or 1 < number) then
			return false, "Normalized value (without 'px' or 'dp') needs to be between 0 and 1"
		end
		if string.endsWith(part, "px") or string.endsWith(part, "dp") then
			number = tonumber(string.sub(part, 1, #part - 2))
			if number == nil then
				return false, "Missing or invalid number value for 'px' or 'dp' entry"
			else
				if number == math.floor(number) then
					continue
				end
				return false, "px and dp values need to be integers"
			end
		end
		return false, "Invalid format"
	end
	return true
end
function GuiUtils.getUVs(str, ref, defaultValue, rotation)
	if str ~= nil then
		local uvs = GuiUtils.getNormalizedValues(str, ref or { 1024, 1024 })
		if uvs[1] ~= nil then
			local result = { uvs[1], 1 - uvs[2] - uvs[4], uvs[1], 1 - uvs[2], uvs[1] + uvs[3], 1 - uvs[2] - uvs[4], uvs[1] + uvs[3], 1 - uvs[2] }
			if rotation ~= nil then
				GuiUtils.rotateUVs(result, rotation)
			end
			return result
		end
		Logging.devError("GuiUtils.getUVs() Unable to get uvs for '%s'", str)
	end
	return defaultValue
end
function GuiUtils.checkOverlayOverlap(posX, posY, overlayX, overlayY, overlaySizeX, overlaySizeY, hotspot)
	if hotspot ~= nil and #hotspot == 4 then
		return 0 < overlaySizeX and 0 < overlaySizeY and overlayX + hotspot[1] <= posX and posX <= overlayX + overlaySizeX + hotspot[3] and overlayY + hotspot[4] <= posY and posY <= overlayY + overlaySizeY + hotspot[2]
	end
	return 0 < overlaySizeX and 0 < overlaySizeY and overlayX <= posX and posX <= overlayX + overlaySizeX and overlayY <= posY and posY <= overlayY + overlaySizeY
end
function GuiUtils.rotateUVs(uvs, direction)
	local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(uvs)
	if direction == 90 then
		uvs[1] = u3
		uvs[2] = v3
		uvs[3] = u1
		uvs[4] = v1
		uvs[5] = u4
		uvs[6] = v4
		uvs[7] = u2
		uvs[8] = v2
	elseif direction == -90 then
		uvs[1] = u2
		uvs[2] = v2
		uvs[3] = u4
		uvs[4] = v4
		uvs[5] = u1
		uvs[6] = v1
		uvs[7] = u3
		uvs[8] = v3
	elseif direction == 180 then
		uvs[1] = u4
		uvs[2] = v4
		uvs[3] = u3
		uvs[4] = v3
		uvs[5] = u2
		uvs[6] = v2
		uvs[7] = u1
		uvs[8] = v1
	else
		if direction ~= 0 then
			Logging.warning("Wrong rotation parameter")
			printCallstack()
		end
	end
end
function GuiUtils.invertUVs(uvs, isXDirection)
	local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(uvs)
	if isXDirection then
		uvs[1] = u3
		uvs[3] = u4
		uvs[5] = u1
		uvs[7] = u2
	else
		uvs[2] = v2
		uvs[4] = v1
		uvs[6] = v4
		uvs[8] = v3
	end
end
function GuiUtils.alignToScreenPixels(x, y)
	return math.round(x / g_pixelSizeX) * g_pixelSizeX, math.round(y / g_pixelSizeY) * g_pixelSizeY
end
function GuiUtils.alignValueToScreenPixels(value, isXValue)
	if isXValue then
		return math.round(value / g_pixelSizeX) * g_pixelSizeX
	else
		return math.round(value / g_pixelSizeY) * g_pixelSizeY
	end
end
function GuiUtils.hsvToRGB(hue, saturation, value)
	saturation = saturation or 1
	value = value or 1
	local kr = (5 + hue * 6) % 6
	local kg = (3 + hue * 6) % 6
	local kb = (1 + hue * 6) % 6
	local r = value - value * saturation * math.max(math.min(kr, 4 - kr, 1), 0)
	local g = value - value * saturation * math.max(math.min(kg, 4 - kg, 1), 0)
	local b = value - value * saturation * math.max(math.min(kb, 4 - kb, 1), 0)
	return r, g, b
end
function GuiUtils.rgbToHSV(r, g, b)
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	local chroma = max - min
	if chroma == 0 then
		return 0, 0, max
	end
	local saturation = chroma / max
	local rNew = (max - r) / chroma
	local gNew = (max - g) / chroma
	local bNew = (max - b) / chroma
	local hue = nil
	if max == min then
		return nil, saturation, max
	else
		if max == r then
			hue = (bNew - gNew) % 6
		elseif max == g then
			hue = rNew - bNew + 2
		elseif max == b then
			hue = gNew - rNew + 4
		end
		return hue / 6, saturation, max
	end
end
function GuiUtils.linearSRGBToHSV(r, g, b)
	r = math.pow(r, 0.45454545454545453)
	g = math.pow(g, 0.45454545454545453)
	b = math.pow(b, 0.45454545454545453)
	local hue, saturation, value = GuiUtils.rgbToHSV(r, g, b)
	hue = hue * 360
	saturation = saturation * 100
	value = value * 100
	return hue, saturation, value
end
