GuiUtils = {}

-- Local values: parts, isString, values, k, part, value, isPixelValue, isDisplayPixelValue, s, wrap, i
function GuiUtils.getNormalizedValues(data, refSize, defaultValue)
	if data == nil then
		return defaultValue
	end
	local v4_ = type(data) == "string"
	if v4_ then
		data = data:split(" ")
	end
	local v5_ = {}
	for v6_, v11_ in pairs(data) do
		local v8_
		if v4_ then
			local v9_ = false
			local v10_ = false
			local v11_
			if string.find(v11_, "px") == nil then
				if string.find(v11_, "dp") ~= nil then
					v11_ = string.gsub(v11_, "dp", "")
					v10_ = true
				end
			else
				v11_ = string.gsub(v11_, "px", "")
				v9_ = true
			end
			v8_ = tonumber(v11_)
			if v10_ then
				if (v6_ + 1) % 2 == 0 then
					v8_ = v8_ * g_pixelSizeX
				else
					v8_ = v8_ * g_pixelSizeY
				end
			elseif v9_ then
				v8_ = v8_ / refSize[(v6_ + 1) % 2 + 1]
			end
		else
			v8_ = v11_ / refSize[(v6_ + 1) % 2 + 1]
		end
		table.insert(v5_, v8_)
	end
	if defaultValue ~= nil and #defaultValue > #data then
		local v12_ = #data
		for v13_ = #data + 1, #defaultValue do
			local v14_ = v5_[(v13_ - 1) % v12_ + 1]
			table.insert(v5_, v14_)
		end
	end
	return v5_
end

-- Local values: isPixelValue, isDisplayPixelValue, value
function GuiUtils.getNormalizedTextSize(str, refSize, defaultValue)
	if str ~= nil then
		local v18_ = false
		local v19_ = false
		if string.find(str, "px") == nil then
			if string.find(str, "dp") ~= nil then
				str = string.gsub(str, "dp", "")
				v19_ = true
			end
		else
			str = string.gsub(str, "px", "")
			v18_ = true
		end
		local v20_ = tonumber(str)
		if v20_ == nil then
			printCallstack()
		end
		if v18_ then
			return v20_ / (refSize or g_screenHeight)
		end
		if v19_ then
			return v20_ * g_pixelSizeY
		end
	end
	return defaultValue
end

-- Local values: number, isString, isPixelSize, isDisplayPixel, screenSizeValue, scalingValue
function GuiUtils.getNormalizedValue(str, isXValue, default)
	if str == nil then
		return default
	end
	local v24_ = false
	local v25_ = false
	local v26_
	if type(str) == "string" then
		if string.find(str, "px") == nil then
			if string.find(str, "dp") ~= nil then
				str = string.gsub(str, "dp", "")
				v25_ = true
			end
		else
			str = string.gsub(str, "px", "")
			v24_ = true
		end
		v26_ = tonumber(str)
		if v26_ == nil then
			Logging.warning("GuiUtils.getNormalizedValue: String %q could not be converted to a number", str)
			return default
		end
	else
		v26_ = str
	end
	local v27_ = 1
	local v28_ = 1
	if v24_ then
		v27_ = isXValue and g_referenceScreenWidth or g_referenceScreenHeight
		v28_ = isXValue and g_aspectScaleX or g_aspectScaleY
	elseif v25_ then
		v27_ = isXValue and g_screenWidth or g_screenHeight
	end
	return v26_ / v27_ * v28_
end

-- Local values: normValues, isString, i, defaultVal
function GuiUtils.getNormalizedScreenValues(values, default)
	if values == nil then
		return default
	end
	local v31_ = {}
	if type(values) == "string" then
		values = string.split(values, " ")
	end
	for v32_ = 1, #values do
		local v33_
		if default == nil then
			v33_ = default
		else
			v33_ = default[v32_] or default
		end
		v31_[v32_] = GuiUtils.getNormalizedValue(values[v32_], v32_ % 2 == 1, v33_, true)
	end
	return v31_
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

-- Local values: data
function GuiUtils.getColorGradientArray(colorStr, defaultValue)
	local v42_ = string.getVector(colorStr)
	if v42_ == nil or #v42_ ~= 4 and #v42_ ~= 16 then
		return defaultValue
	else
		return v42_
	end
end

-- Local values: parts, _, part, number
function GuiUtils.validateUvs(str)
	local v44_ = string.split(str, " ")
	if #v44_ ~= 2 and #v44_ ~= 4 then
		return false, "Needs to be 2- or 4-vector"
	end
	for _, v45_ in ipairs(v44_) do
		local v46_ = tonumber(v45_)
		if v46_ == nil then
			if not (string.endsWith(v45_, "px") or string.endsWith(v45_, "dp")) then
				return false, "Invalid format"
			end
			local v47_ = #v45_ - 2
			local v48_ = string.sub(v45_, 1, v47_)
			local v49_ = tonumber(v48_)
			if v49_ == nil then
				return false, "Missing or invalid number value for \'px\' or \'dp\' entry"
			end
			if v49_ ~= math.floor(v49_) then
				return false, "px and dp values need to be integers"
			end
		elseif v46_ < 0 or v46_ > 1 then
			return false, "Normalized value (without \'px\' or \'dp\') needs to be between 0 and 1"
		end
	end
	return true
end

-- Local values: uvs, result
function GuiUtils.getUVs(str, ref, defaultValue, rotation)
	if str ~= nil then
		local v54_ = GuiUtils.getNormalizedValues(str, ref or { 1024, 1024 })
		if v54_[1] ~= nil then
			local v55_ = {
				v54_[1],
				1 - v54_[2] - v54_[4],
				v54_[1],
				1 - v54_[2],
				v54_[1] + v54_[3],
				1 - v54_[2] - v54_[4],
				v54_[1] + v54_[3],
				1 - v54_[2]
			}
			if rotation ~= nil then
				GuiUtils.rotateUVs(v55_, rotation)
			end
			return v55_
		end
		Logging.devError("GuiUtils.getUVs() Unable to get uvs for \'%s\'", str)
	end
	return defaultValue
end

function GuiUtils.checkOverlayOverlap(posX, posY, overlayX, overlayY, overlaySizeX, overlaySizeY, hotspot)
	if hotspot == nil or #hotspot ~= 4 then
		local v63_
		if overlaySizeX > 0 and (overlaySizeY > 0 and (overlayX <= posX and (posX <= overlayX + overlaySizeX and overlayY <= posY))) then
			v63_ = posY <= overlayY + overlaySizeY
		else
			v63_ = false
		end
		return v63_
	else
		local v64_
		if overlaySizeX > 0 and (overlaySizeY > 0 and (overlayX + hotspot[1] <= posX and (posX <= overlayX + overlaySizeX + hotspot[3] and overlayY + hotspot[4] <= posY))) then
			v64_ = posY <= overlayY + overlaySizeY + hotspot[2]
		else
			v64_ = false
		end
		return v64_
	end
end

-- Local values: u1, v1, u2, v2, u3, v3, u4, v4
function GuiUtils.rotateUVs(uvs, direction)
	local v67_, v68_, v69_, v70_, v71_, v72_, v73_, v74_ = unpack(uvs)
	if direction == 90 then
		uvs[1] = v71_
		uvs[2] = v72_
		uvs[3] = v67_
		uvs[4] = v68_
		uvs[5] = v73_
		uvs[6] = v74_
		uvs[7] = v69_
		uvs[8] = v70_
		return
	elseif direction == -90 then
		uvs[1] = v69_
		uvs[2] = v70_
		uvs[3] = v73_
		uvs[4] = v74_
		uvs[5] = v67_
		uvs[6] = v68_
		uvs[7] = v71_
		uvs[8] = v72_
		return
	elseif direction == 180 then
		uvs[1] = v73_
		uvs[2] = v74_
		uvs[3] = v71_
		uvs[4] = v72_
		uvs[5] = v69_
		uvs[6] = v70_
		uvs[7] = v67_
		uvs[8] = v68_
	elseif direction ~= 0 then
		Logging.warning("Wrong rotation parameter")
		printCallstack()
	end
end

-- Local values: u1, v1, u2, v2, u3, v3, u4, v4
function GuiUtils.invertUVs(uvs, isXDirection)
	local v77_, v78_, v79_, v80_, v81_, v82_, v83_, v84_ = unpack(uvs)
	if isXDirection then
		uvs[1] = v81_
		uvs[3] = v83_
		uvs[5] = v77_
		uvs[7] = v79_
	else
		uvs[2] = v80_
		uvs[4] = v78_
		uvs[6] = v84_
		uvs[8] = v82_
	end
end

function GuiUtils.alignToScreenPixels(x, y)
	local v87_ = x / g_pixelSizeX
	local v88_ = math.round(v87_) * g_pixelSizeX
	local v89_ = y / g_pixelSizeY
	return v88_, math.round(v89_) * g_pixelSizeY
end

function GuiUtils.alignValueToScreenPixels(value, isXValue)
	if isXValue then
		local v92_ = value / g_pixelSizeX
		return math.round(v92_) * g_pixelSizeX
	else
		local v93_ = value / g_pixelSizeY
		return math.round(v93_) * g_pixelSizeY
	end
end

-- Local values: kr, kg, kb, r, g, b
function GuiUtils.hsvToRGB(hue, saturation, value)
	local v97_ = saturation or 1
	local v98_ = value or 1
	local v99_ = (5 + hue * 6) % 6
	local v100_ = (3 + hue * 6) % 6
	local v101_ = (1 + hue * 6) % 6
	local v102_ = v98_ * v97_
	local v103_ = 4 - v99_
	local v104_ = math.min(v99_, v103_, 1)
	local v105_ = v98_ - v102_ * math.max(v104_, 0)
	local v106_ = v98_ * v97_
	local v107_ = 4 - v100_
	local v108_ = math.min(v100_, v107_, 1)
	local v109_ = v98_ - v106_ * math.max(v108_, 0)
	local v110_ = v98_ * v97_
	local v111_ = 4 - v101_
	local v112_ = math.min(v101_, v111_, 1)
	return v105_, v109_, v98_ - v110_ * math.max(v112_, 0)
end

-- Local values: min, max, chroma, saturation, rNew, gNew, bNew, hue
function GuiUtils.rgbToHSV(r, g, b)
	local v116_ = math.min(r, g, b)
	local v117_ = math.max(r, g, b)
	local v118_ = v117_ - v116_
	if v118_ == 0 then
		return 0, 0, v117_
	end
	local v119_ = v118_ / v117_
	local v120_ = (v117_ - r) / v118_
	local v121_ = (v117_ - g) / v118_
	local v122_ = (v117_ - b) / v118_
	local v123_ = nil
	if v117_ == v116_ then
		return nil, v119_, v117_
	end
	if v117_ == r then
		v123_ = (v122_ - v121_) % 6
	elseif v117_ == g then
		v123_ = v120_ - v122_ + 2
	elseif v117_ == b then
		v123_ = v121_ - v120_ + 4
	end
	return v123_ / 6, v119_, v117_
end

-- Local values: hue, saturation, value
function GuiUtils.linearSRGBToHSV(r, g, b)
	local v127_ = math.pow(r, 0.45454545454545453)
	local v128_ = math.pow(g, 0.45454545454545453)
	local v129_ = math.pow(b, 0.45454545454545453)
	local v130_, v131_, v132_ = GuiUtils.rgbToHSV(v127_, v128_, v129_)
	return v130_ * 360, v131_ * 100, v132_ * 100
end
