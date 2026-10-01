NavigationMarker = {}
local NavigationMarker_mt = Class(NavigationMarker)
function NavigationMarker.new(customMt)
	local self = setmetatable({}, customMt or NavigationMarker_mt)
	self.isVisible = false
	self.worldPosX = 0
	self.worldPosY = 0
	self.worldPosZ = 0
	local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local size = 50 * uiScale
	local width, height = getNormalizedScreenValues(size, size)
	self.width = width
	self.height = height
	self.overlayMarker = g_overlayManager:createOverlay("gui.navigation_circle", 0, 0, width, height)
	self.overlayMarker:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	self.overlayMarker:setColor(0.4564, 0.0176, 0.0194, 1)
	local arrowWidth, arrowHeight = getNormalizedScreenValues(15 * uiScale, 23 * uiScale)
	self.overlayMarkerArrow = g_overlayManager:createOverlay("gui.navigation_marker", 0, 0, arrowWidth, arrowHeight)
	self.overlayMarkerArrow:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	local _, textSize = getNormalizedScreenValues(0, size * 0.3)
	self.textSize = textSize
	self.borderX, self.borderY = getNormalizedScreenValues(size * 0.9, size * 0.9)
	self.minDistance = 3
	return self
end
function NavigationMarker:delete()
	self.overlayMarker:delete()
	self.overlayMarkerArrow:delete()
end
function NavigationMarker:setVisibility(isVisible)
	self.isVisible = isVisible
end
function NavigationMarker:setWorldPosition(x, y, z)
	self.worldPosX = x
	self.worldPosY = y
	self.worldPosZ = z
end
function NavigationMarker:render()
	if not self.isVisible then
		return
	end
	new2DLayer()
	local player = g_localPlayer
	if player == nil then
		return
	end
	local x, y, z = g_localPlayer:getPosition()
	local distance = MathUtil.vector3Length(self.worldPosX - x, self.worldPosY - y, self.worldPosZ - z)
	if distance < self.minDistance then
		return
	else
		local diff = distance - self.minDistance
		local fadeFactor = MathUtil.lerp(0, 1, math.min(1, diff))
		local camera = g_cameraManager:getActiveCamera()
		local cx, cy, cz = worldToLocal(camera, self.worldPosX, self.worldPosY, self.worldPosZ)
		local nClip = getNearClip(camera)
		if -nClip < cz then
			local b = -nClip
			local c = b / math.sin(getFovY(camera) * 0.5)
			local a = math.sqrt(-b * b + c * c)
			cx = a * math.sign(cx)
			b = -nClip
			c = b / math.sin(getFovY(camera) * 0.5 * g_screenAspectRatio)
			a = math.sqrt(-b * b + c * c)
			cy = a * math.sign(cy)
		end
		cz = math.min(cz, -nClip)
		local wx, wy, wz = localToWorld(camera, cx, cy, cz)
		local sx, sy, _sz = project(wx, wy, wz)
		local clampedX = sx
		local isClampedX = false
		if sx < self.borderX or 1 - self.borderX < sx then
			clampedX = math.clamp(sx, self.borderX, 1 - self.borderX)
			isClampedX = true
		end
		local clampedY = sy
		local isClampedY = false
		if sy < self.borderY or 1 - self.borderY < sy then
			clampedY = math.clamp(sy, self.borderY, 1 - self.borderY)
			isClampedY = true
		end
		local alpha = MathUtil.lerp(0.4, 1, math.abs(math.sin(g_time / 400)))
		self.overlayMarker:setColor(nil, nil, nil, alpha * fadeFactor)
		self.overlayMarker:setPosition(clampedX, clampedY)
		self.overlayMarker:render()
		local needArrow = isClampedX or isClampedY
		if needArrow then
			local dx, dy = MathUtil.vector2Normalize(sx - 0.5, sy - 0.5)
			local angle = -math.atan2(dx, dy) + 1.5707963267948966
			self.overlayMarkerArrow:setColor(nil, nil, nil, alpha * fadeFactor)
			self.overlayMarkerArrow:setRotation(angle, self.overlayMarkerArrow.width * 0.5, self.overlayMarkerArrow.height * 0.5)
			self.overlayMarkerArrow:setPosition(clampedX + dx * self.width * 0.7, clampedY + dy * self.height * 0.7)
			self.overlayMarkerArrow:render()
		end
		setTextColor(1, 1, 1, alpha * fadeFactor)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextLineHeightScale(0.8)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		setTextWrapWidth(self.width * 0.1, false)
		renderText(clampedX, clampedY, self.textSize, g_i18n:formatDistance(distance))
		setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
		setTextBold(false)
		setTextWrapWidth(0)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	end
end
