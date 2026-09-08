-- Local values: overlays, loadedOverlays, PIXEL, TOUCH_LEFT, TOUCH_MIDDLE, TOUCH_RIGHT, ROUND_CORNER_TOP_LEFT, ROUND_CORNER_TOP_RIGHT, ROUND_CORNER_BOTTOM_LEFT, ROUND_CORNER_BOTTOM_RIGHT, PIXEL_X_SIZE, PIXEL_Y_SIZE, TOUCH_HEIGHT, TOUCH_SIDE_WIDTH, loadOverlays, alignHorizontalToScreenPixels
local overlays = {}
local loadedOverlays = false
local PIXEL = 1
local TOUCH_LEFT = 2
local TOUCH_MIDDLE = 3
local TOUCH_RIGHT = 4
local ROUND_CORNER_TOP_LEFT = 5
local ROUND_CORNER_TOP_RIGHT = 6
local ROUND_CORNER_BOTTOM_LEFT = 7
local ROUND_CORNER_BOTTOM_RIGHT = 8
local PIXEL_X_SIZE = nil
local PIXEL_Y_SIZE = nil
local TOUCH_HEIGHT = nil
local TOUCH_SIDE_WIDTH = nil
function onProfileUiResolutionScalingChanged()
	-- upvalues: (ref) PIXEL_X_SIZE, (ref) PIXEL_Y_SIZE, (ref) TOUCH_SIDE_WIDTH, (ref) TOUCH_HEIGHT
	local v15_ = 1
	local v16_ = v15_ * g_screenWidth
	local v17_ = v15_ * g_screenHeight
	PIXEL_X_SIZE = 1 / v16_
	PIXEL_Y_SIZE = 1 / v17_
	local v18_, v19_ = getNormalizedScreenValues(53, 103)
	TOUCH_SIDE_WIDTH = v18_
	TOUCH_HEIGHT = v19_
	local v20_, v21_ = getNormalizedScreenValues(20, 20)
	CORNER_WIDTH = v20_
	CORNER_HEIGHT = v21_
end
local function v_u_22_()
	-- upvalues: (copy) overlays, (ref) loadedOverlays, (copy) PIXEL, (copy) TOUCH_LEFT, (copy) TOUCH_RIGHT, (copy) TOUCH_MIDDLE, (copy) ROUND_CORNER_TOP_LEFT, (copy) ROUND_CORNER_TOP_RIGHT, (copy) ROUND_CORNER_BOTTOM_LEFT, (copy) ROUND_CORNER_BOTTOM_RIGHT
	overlays[1] = createImageOverlay("dataS/menu/base/graph_pixel.png")
	if Platform.isMobile then
		overlays[2] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
		overlays[2]:setUVs(GuiUtils.getUVs({
			229,
			388,
			53,
			103
		}))
		overlays[4] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
		overlays[4]:setUVs(GuiUtils.getUVs({
			282,
			388,
			-53,
			103
		}))
		overlays[3] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
		overlays[3]:setUVs(GuiUtils.getUVs({
			284,
			388,
			1,
			103
		}))
	end
	overlays[5] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[5]:setUVs(GuiUtils.getUVs({
		7,
		7,
		20,
		20
	}, { 64, 64 }))
	overlays[6] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[6]:setUVs(GuiUtils.getUVs({
		37,
		7,
		20,
		20
	}, { 64, 64 }))
	overlays[7] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[7]:setUVs(GuiUtils.getUVs({
		7,
		37,
		20,
		20
	}, { 64, 64 }))
	overlays[8] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[8]:setUVs(GuiUtils.getUVs({
		37,
		37,
		20,
		20
	}, { 64, 64 }))
	onProfileUiResolutionScalingChanged()
	loadedOverlays = true
end
function deleteDrawingOverlays()
	-- upvalues: (copy) overlays, (ref) loadedOverlays
	for _, v23_ in pairs(overlays) do
		if type(v23_) == "table" then
			v23_:delete()
		else
			delete(v23_)
		end
	end
	loadedOverlays = false
end

-- Upvalues: loadedOverlays, loadOverlays, overlays, PIXEL_X_SIZE, PIXEL_Y_SIZE, PIXEL
-- Local values: overlay, posX2, posY2
function drawFilledRect(x, y, width, height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	-- upvalues: (ref) loadedOverlays, (copy) v_u_22_, (copy) overlays, (ref) PIXEL_X_SIZE, (ref) PIXEL_Y_SIZE, (copy) PIXEL
	if not loadedOverlays then
		v_u_22_()
	end
	local v36_ = overlays[1]
	if width ~= 0 and height ~= 0 then
		local v37_, v38_ = GuiUtils.alignToScreenPixels(x, y)
		local v39_, v40_ = GuiUtils.alignToScreenPixels(width, height)
		local v41_ = PIXEL_X_SIZE
		local v42_ = math.max(v39_, v41_)
		local v43_ = PIXEL_Y_SIZE
		local v44_ = math.max(v40_, v43_)
		if clipX1 ~= nil then
			local v45_ = v37_ + v42_
			local v46_ = v38_ + v44_
			v37_ = math.max(v37_, clipX1)
			v38_ = math.max(v38_, clipY1)
			local v47_ = math.min(v45_, clipX2) - v37_
			v42_ = math.max(v47_, 0)
			local v48_ = math.min(v46_, clipY2) - v38_
			v44_ = math.max(v48_, 0)
			if v42_ == 0 or v44_ == 0 then
				return
			end
		end
		setOverlayColor(v36_, r, g, b, a)
		renderOverlay(v36_, v37_, v38_, v42_, v44_)
	end
end

-- Upvalues: loadedOverlays, loadOverlays, overlays, PIXEL
-- Local values: overlay
function drawOutlineRect(x, y, width, height, lineWidth, lineHeight, r, g, b, a)
	-- upvalues: (ref) loadedOverlays, (copy) v_u_22_, (copy) overlays, (copy) PIXEL
	if not loadedOverlays then
		v_u_22_()
	end
	local v59_ = overlays[1]
	setOverlayColor(v59_, r, g, b, a)
	renderOverlay(v59_, x, y, width, lineHeight)
	renderOverlay(v59_, x, y, lineWidth, height)
	renderOverlay(v59_, x + width - lineWidth, y, lineWidth, height)
	renderOverlay(v59_, x, y + height - lineHeight, width, lineHeight)
end

-- Upvalues: loadedOverlays, loadOverlays, overlays, PIXEL
-- Local values: overlay
function drawPoint(x, y, width, height, r, g, b, a)
	-- upvalues: (ref) loadedOverlays, (copy) v_u_22_, (copy) overlays, (copy) PIXEL
	if not loadedOverlays then
		v_u_22_()
	end
	local v68_ = overlays[1]
	setOverlayColor(v68_, r, g, b, a)
	renderOverlay(v68_, x - width / 2, y - height / 2, width, height)
end

-- Upvalues: loadedOverlays, loadOverlays, PIXEL_X_SIZE, TOUCH_HEIGHT, overlays, TOUCH_SIDE_WIDTH, TOUCH_LEFT, TOUCH_MIDDLE, TOUCH_RIGHT
-- Local values: x, x, overlayLeft, overlayMiddle, overlayRight
function drawTouchButton(x, y, width, isPressed, hasBackground, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	-- upvalues: (ref) loadedOverlays, (copy) v_u_22_, (ref) PIXEL_X_SIZE, (ref) TOUCH_HEIGHT, (copy) overlays, (ref) TOUCH_SIDE_WIDTH, (copy) TOUCH_LEFT, (copy) TOUCH_MIDDLE, (copy) TOUCH_RIGHT
	if not loadedOverlays then
		v_u_22_()
	end
	local v81_ = x / PIXEL_X_SIZE
	local v82_ = math.floor(v81_) * PIXEL_X_SIZE
	local v83_ = width / PIXEL_X_SIZE
	local v84_ = math.floor(v83_) * PIXEL_X_SIZE
	local v85_ = y - TOUCH_HEIGHT * 0.5
	if isPressed then
		local v86_ = r * 0.8
		r = math.min(1, v86_)
		local v87_ = g * 0.8
		g = math.min(1, v87_)
		local v88_ = b * 0.8
		b = math.min(1, v88_)
	end
	local v89_ = overlays[2]
	v89_:setPosition(v82_, v85_)
	v89_:setDimension(TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	v89_:setColor(r, g, b, a)
	v89_:render(clipX1, clipY1, clipX2, clipY2)
	local v90_ = overlays[3]
	v90_:setPosition(v82_ + TOUCH_SIDE_WIDTH, v85_)
	v90_:setDimension(v84_ - 2 * TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	v90_:setColor(r, g, b, a)
	v90_:render(clipX1, clipY1, clipX2, clipY2)
	local v91_ = overlays[4]
	v91_:setPosition(v82_ + v84_ - TOUCH_SIDE_WIDTH, v85_)
	v91_:setDimension(TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	v91_:setColor(r, g, b, a)
	v91_:render(clipX1, clipY1, clipX2, clipY2)
end

-- Upvalues: loadedOverlays, loadOverlays, overlays, PIXEL
-- Local values: deltaX, deltaY, deltaXSq, deltaYSq, length, angle, overlay
function drawLine2D(startX, startY, endX, endY, thickness, r, g, b, a)
	-- upvalues: (ref) loadedOverlays, (copy) v_u_22_, (copy) overlays, (copy) PIXEL
	if not loadedOverlays then
		v_u_22_()
	end
	local v101_ = endX - startX
	local v102_ = (endY - startY) / g_screenAspectRatio
	local v103_ = v101_ * v101_ + v102_ * v102_
	local v104_ = math.sqrt(v103_)
	if v104_ ~= 0 then
		local v105_ = v101_ / v104_
		local v106_ = math.acos(v105_)
		if v102_ < 0 then
			v106_ = 6.283185307179586 - v106_
		end
		local v107_ = overlays[1]
		setOverlayColor(v107_, r, g, b, a)
		setOverlayRotation(v107_, v106_, 0, 0)
		renderOverlay(v107_, startX, startY, v104_, thickness)
		setOverlayRotation(v107_, 0, 0, 0)
	end
end

-- Local values: radiusX, radiusY, startX, startY, angle, i, endX, endY
function drawOutlineCircle2D(x, y, radius, thickness, numSegments, r, g, b, a)
	drawPoint(x, y, 4 * g_pixelSizeX, 4 * g_pixelSizeY, 0, 0, 1, 1)
	local v117_ = radius * g_screenAspectRatio
	local v118_ = x + radius
	local v119_ = 6.283185307179586 / numSegments
	local v120_ = y
	for v121_ = 1, numSegments do
		local v122_ = v119_ * v121_
		local v123_ = x + radius * math.cos(v122_)
		local v124_ = v119_ * v121_
		local v125_ = y + v117_ * math.sin(v124_)
		drawLine2D(v118_, v120_, v123_, v125_, thickness, r, g, b, a)
		v120_ = v125_
		v118_ = v123_
	end
end

-- Upvalues: loadedOverlays, loadOverlays, overlays, ROUND_CORNER_TOP_LEFT, ROUND_CORNER_TOP_RIGHT, ROUND_CORNER_BOTTOM_LEFT, ROUND_CORNER_BOTTOM_RIGHT
-- Local values: cornerWidth, cornerHeight, cornerTopLeft, cornerTopRight, cornerBottomLeft, cornerBottomRight
function drawFilledRectRound(x, y, width, height, scale, r, g, b, a, clipX1, clipY1, clipX2, clipY2, skipScreenPixelAlign)
	-- upvalues: (ref) loadedOverlays, (copy) v_u_22_, (copy) overlays, (copy) ROUND_CORNER_TOP_LEFT, (copy) ROUND_CORNER_TOP_RIGHT, (copy) ROUND_CORNER_BOTTOM_LEFT, (copy) ROUND_CORNER_BOTTOM_RIGHT
	if not loadedOverlays then
		v_u_22_()
	end
	if width ~= 0 and height ~= 0 then
		local v140_ = CORNER_WIDTH * scale
		local v141_ = CORNER_HEIGHT * scale
		if not skipScreenPixelAlign then
			v140_, v141_ = GuiUtils.alignToScreenPixels(CORNER_WIDTH * scale, CORNER_HEIGHT * scale)
			x, y = GuiUtils.alignToScreenPixels(x, y)
			width, height = GuiUtils.alignToScreenPixels(width, height)
		end
		local v142_ = v140_ * 2
		local v143_ = math.max(width, v142_)
		local v144_ = v141_ * 2
		local v145_ = math.max(height, v144_)
		drawFilledRect(x, y + v141_, v140_, v145_ - 2 * v141_, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
		drawFilledRect(x + v140_, y, v143_ - 2 * v140_, v145_, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
		drawFilledRect(x + v143_ - v140_, y + v141_, v140_, v145_ - 2 * v141_, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
		local v146_ = overlays[5]
		v146_:setPosition(x, y + v145_ - v141_)
		v146_:setDimension(v140_, v141_)
		v146_:setColor(r, g, b, a)
		v146_:render(clipX1, clipY1, clipX2, clipY2)
		local v147_ = overlays[6]
		v147_:setPosition(x + v143_ - v140_, y + v145_ - v141_)
		v147_:setDimension(v140_, v141_)
		v147_:setColor(r, g, b, a)
		v147_:render(clipX1, clipY1, clipX2, clipY2)
		local v148_ = overlays[7]
		v148_:setPosition(x, y)
		v148_:setDimension(v140_, v141_)
		v148_:setColor(r, g, b, a)
		v148_:render(clipX1, clipY1, clipX2, clipY2)
		local v149_ = overlays[8]
		v149_:setPosition(x + v143_ - v140_, y)
		v149_:setDimension(v140_, v141_)
		v149_:setColor(r, g, b, a)
		v149_:render(clipX1, clipY1, clipX2, clipY2)
	end
end

-- Local values: startPos, endPos
function drawDashedLine(x, y, width, height, dashLength, gapLength, r, g, b, a, isHorizontal)
	local v161_ = 0
	if not isHorizontal then
		while math.abs(v161_) < height do
			if dashLength <= 0 then
				::l11::
				local v162_ = v161_ + dashLength
				local v163_ = -height
				v165_ = math.max(v162_, v163_)
				goto l12
			end
			local v164_ = v161_ + dashLength
			local v165_ = math.min(v164_, height)
			if not v165_ then
				goto l11
			end
			::l12::
			drawLine2D(x, y + v161_, x, y + v165_, width * g_screenAspectRatio, r, g, b, a)
			v161_ = v165_ + gapLength
		end
		goto l4
	end
	while true do
		if math.abs(v161_) >= width then
			::l4::
			return
		end
		if dashLength <= 0 then
			break
		end
		local v166_ = v161_ + dashLength
		v169_ = math.min(v166_, width)
		if not v169_ then
			break
		end
		::l7::
		drawLine2D(x + v161_, y, x + v169_, y, height, r, g, b, a)
		v161_ = v169_ + gapLength
	end
	local v167_ = v161_ + dashLength
	local v168_ = -width
	local v169_ = math.max(v167_, v168_)
	goto l7
end
