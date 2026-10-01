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
	local resScale = 1
	local screenWidth = resScale * g_screenWidth
	local screenHeight = resScale * g_screenHeight
	PIXEL_X_SIZE = 1 / screenWidth
	PIXEL_Y_SIZE = 1 / screenHeight
	TOUCH_SIDE_WIDTH, TOUCH_HEIGHT = getNormalizedScreenValues(53, 103)
	CORNER_WIDTH, CORNER_HEIGHT = getNormalizedScreenValues(20, 20)
end
local loadOverlays = function()
	overlays[1] = createImageOverlay("dataS/menu/base/graph_pixel.png")
	if Platform.isMobile then
		overlays[2] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
		overlays[2]:setUVs(GuiUtils.getUVs({ 229, 388, 53, 103 }))
		overlays[4] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
		overlays[4]:setUVs(GuiUtils.getUVs({ 282, 388, -53, 103 }))
		overlays[3] = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)
		overlays[3]:setUVs(GuiUtils.getUVs({ 284, 388, 1, 103 }))
	end
	local roundCornerFilename = "dataS/menu/base/roundCorner.png"
	overlays[5] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[5]:setUVs(GuiUtils.getUVs({ 7, 7, 20, 20 }, { 64, 64 }))
	overlays[6] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[6]:setUVs(GuiUtils.getUVs({ 37, 7, 20, 20 }, { 64, 64 }))
	overlays[7] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[7]:setUVs(GuiUtils.getUVs({ 7, 37, 20, 20 }, { 64, 64 }))
	overlays[8] = Overlay.new("dataS/menu/base/roundCorner.png", 0, 0, 0, 0)
	overlays[8]:setUVs(GuiUtils.getUVs({ 37, 37, 20, 20 }, { 64, 64 }))
	onProfileUiResolutionScalingChanged()
	loadedOverlays = true
end
function deleteDrawingOverlays()
	for _, overlay in pairs(overlays) do
		if type(overlay) == "table" then
			overlay:delete()
		else
			delete(overlay)
		end
	end
	loadedOverlays = false
end
function drawFilledRect(x, y, width, height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	if not loadedOverlays then
		loadOverlays()
	end
	local overlay = overlays[1]
	if width == 0 or height == 0 then
		return
	end
	x, y = GuiUtils.alignToScreenPixels(x, y)
	width, height = GuiUtils.alignToScreenPixels(width, height)
	width = math.max(width, PIXEL_X_SIZE)
	height = math.max(height, PIXEL_Y_SIZE)
	if clipX1 ~= nil then
		local posX2 = x + width
		local posY2 = y + height
		x = math.max(x, clipX1)
		y = math.max(y, clipY1)
		width = math.max(math.min(posX2, clipX2) - x, 0)
		height = math.max(math.min(posY2, clipY2) - y, 0)
		if width == 0 or height == 0 then
			return
		end
	end
	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x, y, width, height)
end
function drawOutlineRect(x, y, width, height, lineWidth, lineHeight, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end
	local overlay = overlays[1]
	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x, y, width, lineHeight)
	renderOverlay(overlay, x, y, lineWidth, height)
	renderOverlay(overlay, x + width - lineWidth, y, lineWidth, height)
	renderOverlay(overlay, x, y + height - lineHeight, width, lineHeight)
end
function drawPoint(x, y, width, height, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end
	local overlay = overlays[1]
	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x - width / 2, y - height / 2, width, height)
end
local alignHorizontalToScreenPixels = function(x)
	return math.floor(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
end
function drawTouchButton(x, y, width, isPressed, hasBackground, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	if not loadedOverlays then
		loadOverlays()
	end
	local x = x
	x = math.floor(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
	local x = width
	width = math.floor(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
	y = y - TOUCH_HEIGHT * 0.5
	if isPressed then
		r = math.min(1, r * 0.8)
		g = math.min(1, g * 0.8)
		b = math.min(1, b * 0.8)
	end
	local overlayLeft = overlays[2]
	overlayLeft:setPosition(x, y)
	overlayLeft:setDimension(TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	overlayLeft:setColor(r, g, b, a)
	overlayLeft:render(clipX1, clipY1, clipX2, clipY2)
	local overlayMiddle = overlays[3]
	overlayMiddle:setPosition(x + TOUCH_SIDE_WIDTH, y)
	overlayMiddle:setDimension(width - 2 * TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	overlayMiddle:setColor(r, g, b, a)
	overlayMiddle:render(clipX1, clipY1, clipX2, clipY2)
	local overlayRight = overlays[4]
	overlayRight:setPosition(x + width - TOUCH_SIDE_WIDTH, y)
	overlayRight:setDimension(TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	overlayRight:setColor(r, g, b, a)
	overlayRight:render(clipX1, clipY1, clipX2, clipY2)
end
function drawLine2D(startX, startY, endX, endY, thickness, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end
	local deltaX = endX - startX
	local deltaY = endY - startY
	deltaY = deltaY / g_screenAspectRatio
	local deltaXSq = deltaX * deltaX
	local deltaYSq = deltaY * deltaY
	local length = math.sqrt(deltaXSq + deltaYSq)
	if length == 0 then
		return
	else
		local angle = math.acos(deltaX / length)
		if deltaY < 0 then
			angle = 6.283185307179586 - angle
		end
		local overlay = overlays[1]
		setOverlayColor(overlay, r, g, b, a)
		setOverlayRotation(overlay, angle, 0, 0)
		renderOverlay(overlay, startX, startY, length, thickness)
		setOverlayRotation(overlay, 0, 0, 0)
	end
end
function drawOutlineCircle2D(x, y, radius, thickness, numSegments, r, g, b, a)
	drawPoint(x, y, 4 * g_pixelSizeX, 4 * g_pixelSizeY, 0, 0, 1, 1)
	local radiusY = radius * g_screenAspectRatio
	local startX = x + radius
	local startY = y
	local angle = 6.283185307179586 / numSegments
	for i = 1, numSegments do
		local endX = x + radius * math.cos(angle * i)
		local endY = y + radiusY * math.sin(angle * i)
		drawLine2D(startX, startY, endX, endY, thickness, r, g, b, a)
		startX = endX
		startY = endY
	end
end
function drawFilledRectRound(x, y, width, height, scale, r, g, b, a, clipX1, clipY1, clipX2, clipY2, skipScreenPixelAlign)
	if not loadedOverlays then
		loadOverlays()
	end
	if width == 0 or height == 0 then
		return
	end
	local cornerWidth = CORNER_WIDTH * scale
	local cornerHeight = CORNER_HEIGHT * scale
	if not skipScreenPixelAlign then
		cornerWidth, cornerHeight = GuiUtils.alignToScreenPixels(CORNER_WIDTH * scale, CORNER_HEIGHT * scale)
		x, y = GuiUtils.alignToScreenPixels(x, y)
		width, height = GuiUtils.alignToScreenPixels(width, height)
	end
	width = math.max(width, cornerWidth * 2)
	height = math.max(height, cornerHeight * 2)
	drawFilledRect(x, y + cornerHeight, cornerWidth, height - 2 * cornerHeight, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	drawFilledRect(x + cornerWidth, y, width - 2 * cornerWidth, height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	drawFilledRect(x + width - cornerWidth, y + cornerHeight, cornerWidth, height - 2 * cornerHeight, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	local cornerTopLeft = overlays[5]
	cornerTopLeft:setPosition(x, y + height - cornerHeight)
	cornerTopLeft:setDimension(cornerWidth, cornerHeight)
	cornerTopLeft:setColor(r, g, b, a)
	cornerTopLeft:render(clipX1, clipY1, clipX2, clipY2)
	local cornerTopRight = overlays[6]
	cornerTopRight:setPosition(x + width - cornerWidth, y + height - cornerHeight)
	cornerTopRight:setDimension(cornerWidth, cornerHeight)
	cornerTopRight:setColor(r, g, b, a)
	cornerTopRight:render(clipX1, clipY1, clipX2, clipY2)
	local cornerBottomLeft = overlays[7]
	cornerBottomLeft:setPosition(x, y)
	cornerBottomLeft:setDimension(cornerWidth, cornerHeight)
	cornerBottomLeft:setColor(r, g, b, a)
	cornerBottomLeft:render(clipX1, clipY1, clipX2, clipY2)
	local cornerBottomRight = overlays[8]
	cornerBottomRight:setPosition(x + width - cornerWidth, y)
	cornerBottomRight:setDimension(cornerWidth, cornerHeight)
	cornerBottomRight:setColor(r, g, b, a)
	cornerBottomRight:render(clipX1, clipY1, clipX2, clipY2)
end
function drawDashedLine(x, y, width, height, dashLength, gapLength, r, g, b, a, isHorizontal)
	local startPos = 0
	local endPos = nil
	if isHorizontal then
		while math.abs(startPos) < width do
			endPos = 0 < dashLength and math.min(startPos + dashLength, width) or math.max(startPos + dashLength, -width)
			drawLine2D(x + startPos, y, x + endPos, y, height, r, g, b, a)
			startPos = endPos + gapLength
		end
	else
		while math.abs(startPos) < height do
			endPos = 0 < dashLength and math.min(startPos + dashLength, height) or math.max(startPos + dashLength, -height)
			drawLine2D(x, y + startPos, x, y + endPos, width * g_screenAspectRatio, r, g, b, a)
			startPos = endPos + gapLength
		end
	end
end
