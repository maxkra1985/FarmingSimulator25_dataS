-- Local values: NavigationMarker_mt
NavigationMarker = {}
local NavigationMarker_mt = Class(NavigationMarker)

-- Upvalues: NavigationMarker_mt
-- Local values: self, uiScale, size, width, height, arrowWidth, arrowHeight, _, textSize
function NavigationMarker.new(customMt)
	-- upvalues: (copy) NavigationMarker_mt
	local v3_ = customMt or NavigationMarker_mt
	local v4_ = setmetatable({}, v3_)
	v4_.isVisible = false
	v4_.worldPosX = 0
	v4_.worldPosY = 0
	v4_.worldPosZ = 0
	local v5_ = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	local v6_ = 50 * v5_
	local v7_, v8_ = getNormalizedScreenValues(v6_, v6_)
	v4_.width = v7_
	v4_.height = v8_
	v4_.overlayMarker = g_overlayManager:createOverlay("gui.navigation_circle", 0, 0, v7_, v8_)
	v4_.overlayMarker:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	v4_.overlayMarker:setColor(0.4564, 0.0176, 0.0194, 1)
	local v9_, v10_ = getNormalizedScreenValues(15 * v5_, 23 * v5_)
	v4_.overlayMarkerArrow = g_overlayManager:createOverlay("gui.navigation_marker", 0, 0, v9_, v10_)
	v4_.overlayMarkerArrow:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
	local _, v11_ = getNormalizedScreenValues(0, v6_ * 0.3)
	v4_.textSize = v11_
	local v12_, v13_ = getNormalizedScreenValues(v6_ * 0.9, v6_ * 0.9)
	v4_.borderX = v12_
	v4_.borderY = v13_
	v4_.minDistance = 3
	return v4_
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

-- Local values: player, x, y, z, distance, diff, fadeFactor, camera, cx, cy, cz, nClip, b, c, a, wx, wy, wz, sx, sy, _sz, clampedX, isClampedX, clampedY, isClampedY, alpha, needArrow, dx, dy, angle
function NavigationMarker:render()
	if self.isVisible then
		new2DLayer()
		if g_localPlayer == nil then
			return
		else
			local v22_, v23_, v24_ = g_localPlayer:getPosition()
			local v25_ = MathUtil.vector3Length(self.worldPosX - v22_, self.worldPosY - v23_, self.worldPosZ - v24_)
			if v25_ >= self.minDistance then
				local v26_ = v25_ - self.minDistance
				local v27_ = MathUtil.lerp(0, 1, (math.min(1, v26_)))
				local v28_ = g_cameraManager:getActiveCamera()
				local v29_, v30_, v31_ = worldToLocal(v28_, self.worldPosX, self.worldPosY, self.worldPosZ)
				local v32_ = getNearClip(v28_)
				if -v32_ < v31_ then
					local v33_ = -v32_
					local v34_ = getFovY(v28_) * 0.5
					local v35_ = v33_ / math.sin(v34_)
					local v36_ = -v33_ * v33_ + v35_ * v35_
					v29_ = math.sqrt(v36_) * math.sign(v29_)
					local v37_ = -v32_
					local v38_ = getFovY(v28_) * 0.5 * g_screenAspectRatio
					local v39_ = v37_ / math.sin(v38_)
					local v40_ = -v37_ * v37_ + v39_ * v39_
					v30_ = math.sqrt(v40_) * math.sign(v30_)
				end
				local v41_ = -v32_
				local v42_ = math.min(v31_, v41_)
				local v43_, v44_, v45_ = localToWorld(v28_, v29_, v30_, v42_)
				local v46_, v47_, _ = project(v43_, v44_, v45_)
				local v48_, v49_
				if v46_ < self.borderX or 1 - self.borderX < v46_ then
					local v50_ = self.borderX
					local v51_ = 1 - self.borderX
					v48_ = math.clamp(v46_, v50_, v51_)
					v49_ = true
				else
					v48_ = v46_
					v49_ = false
				end
				local v52_, v53_
				if v47_ < self.borderY or 1 - self.borderY < v47_ then
					local v54_ = self.borderY
					local v55_ = 1 - self.borderY
					v52_ = math.clamp(v47_, v54_, v55_)
					v53_ = true
				else
					v52_ = v47_
					v53_ = false
				end
				local v56_ = MathUtil.lerp
				local v57_ = g_time / 400
				local v58_ = math.sin(v57_)
				local v59_ = v56_(0.4, 1, (math.abs(v58_)))
				self.overlayMarker:setColor(nil, nil, nil, v59_ * v27_)
				self.overlayMarker:setPosition(v48_, v52_)
				self.overlayMarker:render()
				if v49_ or v53_ then
					local v60_, v61_ = MathUtil.vector2Normalize(v46_ - 0.5, v47_ - 0.5)
					local v62_ = -math.atan2(v60_, v61_) + 1.5707963267948966
					self.overlayMarkerArrow:setColor(nil, nil, nil, v59_ * v27_)
					self.overlayMarkerArrow:setRotation(v62_, self.overlayMarkerArrow.width * 0.5, self.overlayMarkerArrow.height * 0.5)
					self.overlayMarkerArrow:setPosition(v48_ + v60_ * self.width * 0.7, v52_ + v61_ * self.height * 0.7)
					self.overlayMarkerArrow:render()
				end
				setTextColor(1, 1, 1, v59_ * v27_)
				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_CENTER)
				setTextLineHeightScale(0.8)
				setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
				setTextWrapWidth(self.width * 0.1, false)
				renderText(v48_, v52_, self.textSize, g_i18n:formatDistance(v25_))
				setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
				setTextBold(false)
				setTextWrapWidth(0)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
			end
		end
	else
		return
	end
end
