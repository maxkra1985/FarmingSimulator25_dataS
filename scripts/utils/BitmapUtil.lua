BitmapUtil = {}
BitmapUtil.FORMAT = {}
BitmapUtil.FORMAT.BITMAP = 0
BitmapUtil.FORMAT.GREYMAP = 1
BitmapUtil.FORMAT.PIXELMAP = 2
local v1_ = BitmapUtil
local v13_ = {
	[BitmapUtil.FORMAT.BITMAP] = {
		["extension"] = "pbm",
		["getHeader"] = function(p2_, p3_, _)
			return string.format("P4\n%d %d\n", p2_, p3_)
		end,
		["getPixel"] = function(p4_)
			return string.format("%c", p4_[1])
		end
	},
	[BitmapUtil.FORMAT.GREYMAP] = {
		["extension"] = "pgm",
		["getHeader"] = function(p5_, p6_, p7_)
			return string.format("P5\n%d %d\n%d\n", p5_, p6_, p7_)
		end,
		["getPixel"] = function(p8_)
			return string.format("%c", p8_[1])
		end
	},
	[BitmapUtil.FORMAT.PIXELMAP] = {
		["extension"] = "ppm",
		["getHeader"] = function(p9_, p10_, p11_)
			return string.format("P6\n%d %d\n%d\n", p9_, p10_, p11_)
		end,
		["getPixel"] = function(p12_)
			return string.format("%c%c%c", p12_[1], p12_[2], p12_[3])
		end
	}
}
v1_.FORMAT_TO_PNM = v13_

-- Local values: maxBrightness, pnmFormat, file, pixelsToWrite, concatFunc, clearFunc, pixelIndex
function BitmapUtil.writeBitmapToFile(pixels, width, height, filepath, imageFormat)
	local v19_ = BitmapUtil.FORMAT_TO_PNM[imageFormat]
	if v19_ == nil then
		Logging.error("Invalid image format \'%s\'. Use one of BitmapUtil.FORMAT", imageFormat)
		return false
	end
	local v20_ = string.format("%s.%s", filepath, v19_.extension or "pnm")
	local v21_ = createFile(v20_, FileAccess.WRITE)
	if v21_ == 0 then
		Logging.error("BitmapUtil.writeBitmapToFile(): Unable to create file \'%s\'", v20_)
		return false
	end
	fileWrite(v21_, v19_.getHeader(width, height, 255))
	local v22_ = table.concat
	local v23_ = table.clear
	local v24_ = {}
	for v25_ = 1, #pixels do
		v24_[#v24_ + 1] = v19_.getPixel(pixels[v25_])
		if v25_ % 1025 == 0 then
			fileWrite(v21_, v22_(v24_))
			v23_(v24_)
		end
	end
	if #v24_ > 0 then
		fileWrite(v21_, v22_(v24_))
	end
	delete(v21_)
	Logging.info("Wrote bitmap (width=%d, height=%d) to \'%s\'", width, height, v20_)
	return true
end

-- Local values: pnmFormat, file, maxBrightness, pixelsToWrite, pixelIndex, concatFunc, clearFunc, pixel
function BitmapUtil.writeBitmapToFileFromIterator(iterator, width, height, filepath, imageFormat)
	local v31_ = BitmapUtil.FORMAT_TO_PNM[imageFormat]
	if v31_ == nil then
		Logging.error("Invalid image format \'%s\'. Use one of BitmapUtil.FORMAT", imageFormat)
		return false
	end
	local v32_ = string.format("%s.%s", filepath, v31_.extension or "pnm")
	local v33_ = createFile(v32_, FileAccess.WRITE)
	if v33_ == 0 then
		Logging.error("BitmapUtil.writeBitmapToFileFromIterator(): Unable to create file \'%s\'", v32_)
		return false
	end
	fileWrite(v33_, v31_.getHeader(width, height, 255))
	local v34_ = table.concat
	local v35_ = table.clear
	local v36_ = {}
	local v37_ = 1
	for v38_ in iterator() do
		v36_[#v36_ + 1] = v31_.getPixel(v38_)
		if v37_ % 1025 == 0 then
			fileWrite(v33_, v34_(v36_))
			v35_(v36_)
		end
		v37_ = v37_ + 1
	end
	if #v36_ > 0 then
		fileWrite(v33_, v34_(v36_))
	end
	delete(v33_)
	Logging.info("Wrote bitmap (width=%d, height=%d) to \'%s\'", width, height, v32_)
	return true
end
