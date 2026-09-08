-- Local values: wasActive, oldUIScale
local v1_, v2_
if IntroductionHelpHUDUtil == nil then
	v1_ = false
	v2_ = nil
else
	IntroductionHelpHUDUtil.delete()
	v2_ = IntroductionHelpHUDUtil.uiScale
	v1_ = true
end
IntroductionHelpHUDUtil = {}
IntroductionHelpHUDUtil.ARROW_POSITION_TOP = 1
IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM = 2
IntroductionHelpHUDUtil.ARROW_POSITION_LEFT = 3
IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT = 4
function IntroductionHelpHUDUtil.init()
	local v3_ = IntroductionHelpHUDUtil
	local v4_ = g_overlayManager:createOverlay("gui.tourdialogue_side", 0, 0, 0, 0)
	v4_:setColor(0.8148, 0.1779, 0.0052, 1)
	local v5_ = g_overlayManager:createOverlay("gui.tourdialogue_side", 0, 0, 0, 0)
	v5_:setColor(0.8148, 0.1779, 0.0052, 1)
	local v6_ = g_overlayManager:createOverlay("gui.tourdialogue_top", 0, 0, 0, 0)
	v6_:setColor(0.8148, 0.1779, 0.0052, 1)
	local v7_ = g_overlayManager:createOverlay("gui.tourdialogue_top", 0, 0, 0, 0)
	v7_:setColor(0.8148, 0.1779, 0.0052, 1)
	v3_.arrows = {}
	v3_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT] = v4_
	v3_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT] = v5_
	v3_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_TOP] = v6_
	v3_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM] = v7_
	local v8_ = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
	local v9_ = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
	local v10_ = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
	local v11_ = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
	v3_.smallArrows = {}
	v3_.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT] = v8_
	v3_.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT] = v9_
	v3_.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_TOP] = v10_
	v3_.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM] = v11_
	v3_.bgScale = g_overlayManager:createOverlay("gui.tourdialogue_boxMiddle", 0, 0, 0, 0)
	v3_.bgScale:setColor(0.8148, 0.1779, 0.0052, 1)
	v3_.bgLeft = g_overlayManager:createOverlay("gui.tourdialogue_boxLeft", 0, 0, 0, 0)
	v3_.bgLeft:setColor(0.8148, 0.1779, 0.0052, 1)
	v3_.bgRight = g_overlayManager:createOverlay("gui.tourdialogue_boxRight", 0, 0, 0, 0)
	v3_.bgRight:setColor(0.8148, 0.1779, 0.0052, 1)
	v3_.continueText = g_i18n:getText("introduction_continueText")
	v3_.continueTextGamepad = g_i18n:getText("introduction_continueTextGamepad") .. " "
	v3_.glyphElement = InputGlyphElement.new(g_inputDisplayManager, 0, 0)
	v3_.glyphElement:setAction(InputAction.INTRODUCTION_HELP_SKIP)
	v3_.glyphElement:setButtonGlyphColor({
		0.22323,
		0.40724,
		0.00368,
		1
	})
	return v3_
end
function IntroductionHelpHUDUtil.delete()
	local v12_ = IntroductionHelpHUDUtil
	for _, v13_ in pairs(v12_.arrows) do
		v13_:delete()
	end
	for _, v14_ in pairs(v12_.smallArrows) do
		v14_:delete()
	end
	v12_.bgScale:delete()
	v12_.bgLeft:delete()
	v12_.bgRight:delete()
	v12_.glyphElement:delete()
end

-- Local values: self, bgLeftWidth, bgHeight, bgRightWidth, _, arrowSideWidth, arrowSideHeight, rightArrow, arrowTopWidth, arrowTopHeight, bottomArrow, arrowSmallWidth, arrowSmallHeight, _, arrow, bottomSmallArrow, leftSmallArrow, rightSmallArrow, _, textSize, textOffsetX, textOffsetY, _, messageTextSize, messageTextPaddingX, messageTextPaddingY, messageTextOffsetX, messageTextOffsetY, boxMaxWidth, _, _, messageTextToTextOffsetY, glyphOffsetX, _, glyphWidth, glyphHeight
function IntroductionHelpHUDUtil.setScale(uiScale)
	local v16_ = IntroductionHelpHUDUtil
	v16_.uiScale = uiScale
	local v17_, v18_ = getNormalizedScreenValues(10, 37)
	local v19_, _ = getNormalizedScreenValues(10, 0)
	v16_.bgLeft:setDimension(v17_ * uiScale, v18_ * uiScale)
	v16_.bgScale:setDimension(0, v18_ * uiScale)
	v16_.bgRight:setDimension(v19_ * uiScale, v18_ * uiScale)
	local v20_, v21_ = getNormalizedScreenValues(5, 29)
	v16_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT]:setDimension(v20_ * uiScale, v21_ * uiScale)
	local v22_ = v16_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT]
	v22_:setDimension(v20_ * uiScale, v21_ * uiScale)
	v22_:setRotation(3.141592653589793, v22_.width * 0.5, v22_.height * 0.5)
	local v23_, v24_ = getNormalizedScreenValues(46, 7)
	v16_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_TOP]:setDimension(v23_ * uiScale, v24_ * uiScale)
	local v25_ = v16_.arrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM]
	v25_:setDimension(v23_ * uiScale, v24_ * uiScale)
	v25_:setRotation(3.141592653589793, v25_.width * 0.5, v25_.height * 0.5)
	local v26_, v27_ = getNormalizedScreenValues(6, 6)
	for _, v28_ in pairs(v16_.smallArrows) do
		v28_:setDimension(v26_ * uiScale, v27_ * uiScale)
	end
	local v29_ = v16_.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM]
	v29_:setRotation(3.141592653589793, v29_.width * 0.5, v29_.height * 0.5)
	local v30_ = v16_.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT]
	v30_:setRotation(1.5707963267948966, v30_.width * 0.5, v30_.height * 0.5)
	local v31_ = v16_.smallArrows[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT]
	v31_:setRotation(-1.5707963267948966, v31_.width * 0.5, v31_.height * 0.5)
	v16_.smallArrowsOffset = {}
	v16_.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_TOP] = { getNormalizedScreenValues(20, -5) }
	v16_.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM] = { getNormalizedScreenValues(20, 5) }
	v16_.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_LEFT] = { getNormalizedScreenValues(6, 12) }
	v16_.smallArrowsOffset[IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT] = { getNormalizedScreenValues(-6, 12) }
	local _, v32_ = getNormalizedScreenValues(0, 14)
	v16_.textSize = v32_ * uiScale
	local v33_, v34_ = getNormalizedScreenValues(15, 13)
	local v35_ = v33_ * uiScale
	local v36_ = v34_ * uiScale
	v16_.textOffsetX = v35_
	v16_.textOffsetY = v36_
	local v37_, v38_ = getNormalizedScreenValues(20, 0)
	v16_.borderX = v37_
	v16_.borderY = v38_
	local _, v39_ = getNormalizedScreenValues(0, 14)
	v16_.messageTextSize = v39_ * uiScale
	local v40_, v41_ = getNormalizedScreenValues(15, 15)
	local v42_ = v40_ * uiScale
	local v43_ = v41_ * uiScale
	v16_.messageTextPaddingX = v42_
	v16_.messageTextPaddingY = v43_
	local v44_, v45_ = getNormalizedScreenValues(0, 2)
	local v46_ = v44_ * uiScale
	local v47_ = v45_ * uiScale
	v16_.messageTextOffsetX = v46_
	v16_.messageTextOffsetY = v47_
	local v48_, _ = getNormalizedScreenValues(800, 0)
	v16_.messageBoxMaxWidth = v48_ * uiScale
	local _, v49_ = getNormalizedScreenValues(0, 25)
	v16_.messageTextToTextOffsetY = v49_ * uiScale
	local v50_, _ = getNormalizedScreenValues(10, 0)
	v16_.glyphOffsetX = v50_ * uiScale
	local v51_, v52_ = getNormalizedScreenValues(35, 35)
	v16_.glyphElement:setBaseSize(v51_, v52_)
end

-- Local values: self, arrow, smallArrow, bgPosX, bgPosY, textSize, textWidth, bgWidth, bgHeight, arrowX, arrowY, minX, maxX, offset
function IntroductionHelpHUDUtil.drawHelp(x, y, text, arrowPosition)
	if not g_gui:getIsGuiVisible() then
		local v57_ = IntroductionHelpHUDUtil
		local v58_ = v57_.arrows[arrowPosition]
		local v59_ = v57_.smallArrows[arrowPosition]
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(true)
		local v60_ = utf8ToUpper(text)
		local v61_ = v57_.textSize
		local v62_ = getTextWidth(v61_, v60_) + 2 * v57_.textOffsetX
		local v63_ = v57_.bgLeft.height
		local v64_ = nil
		local v65_ = nil
		local v66_ = g_hudAnchorLeft
		local v67_ = g_hudAnchorRight
		local v68_
		if arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_TOP then
			local v69_ = x - v58_.width * 0.5
			local v70_ = v67_ - v58_.width
			v64_ = math.clamp(v69_, v66_, v70_)
			y = y - v58_.height
			local v71_ = x - v62_ * 0.5
			local v72_ = v67_ - v62_
			x = math.clamp(v71_, v66_, v72_)
			v68_ = y - v63_
		elseif arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_BOTTOM then
			local v73_ = x - v58_.width * 0.5
			local v74_ = v67_ - v58_.width
			v64_ = math.clamp(v73_, v66_, v74_)
			local v75_ = x - v62_ * 0.5
			local v76_ = v67_ - v62_
			x = math.clamp(v75_, v66_, v76_)
			v68_ = y + v58_.height
		elseif arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_LEFT then
			local v77_ = v67_ - v62_ - v58_.width
			v64_ = math.clamp(x, v66_, v77_)
			local v78_ = y - v58_.height * 0.5
			x = v64_ + v58_.width - g_pixelSizeX
			v68_ = y - v63_ * 0.5
			y = v78_
		elseif arrowPosition == IntroductionHelpHUDUtil.ARROW_POSITION_RIGHT then
			local v79_ = v66_ + v62_
			local v80_ = v67_ - v58_.width
			v64_ = math.clamp(x, v79_, v80_)
			local v81_ = y - v58_.height * 0.5
			x = v64_ - v62_ + g_pixelSizeX
			v68_ = y - v63_ * 0.5
			y = v81_
		else
			v68_ = y
			y = v65_
		end
		v57_.bgLeft:setPosition(x, v68_)
		v57_.bgLeft:render()
		v57_.bgScale:setDimension(v62_ - v57_.bgLeft.width - v57_.bgRight.width, nil)
		v57_.bgScale:setPosition(v57_.bgLeft.x + v57_.bgLeft.width, v57_.bgLeft.y)
		v57_.bgScale:render()
		v57_.bgRight:setPosition(v57_.bgScale.x + v57_.bgScale.width, v57_.bgScale.y)
		v57_.bgRight:render()
		v58_:setPosition(v64_, y)
		v58_:render()
		local v82_ = v57_.smallArrowsOffset[arrowPosition]
		v59_:setPosition(v64_ + v82_[1], y + v82_[2])
		v59_:render()
		setTextColor(1, 1, 1, 1)
		renderText(v57_.bgLeft.x + v57_.textOffsetX, v57_.bgScale.y + v57_.textOffsetY, v61_, v60_)
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
	end
end

-- Local values: self, posX, posY, messageTextPaddingX, messageTextPaddingY, glyphWidth, glyphOffsetX, maxTextWidth, textSize, height, _, width, boxPosX, boxPosY, boxWidth, boxHeight, color
function IntroductionHelpHUDUtil.drawMessage(text, glyphElement)
	if not g_gui:getIsGuiVisible() then
		local v85_ = IntroductionHelpHUDUtil
		local v86_ = 0.5
		local v87_ = v85_.messageTextPaddingX
		local v88_ = v85_.messageTextPaddingY
		local v89_ = v85_.glyphOffsetX
		local v90_ = glyphElement == nil and 0 or glyphElement:getWidth()
		local v91_ = v85_.messageBoxMaxWidth - 2 * v87_ - v90_
		local v92_ = v85_.messageTextSize
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
		setTextWrapWidth(v91_)
		local v93_, _ = getTextHeight(v92_, text)
		local v94_ = getTextWidth(v92_, text)
		local v95_ = 0.5 - v87_ - v94_ * 0.5 - v90_ * 0.5 - v89_ * 0.5
		local v96_ = 0.9 - v88_ - v93_ * 0.5
		local v97_ = v94_ + 2 * v87_ + v90_ + v89_
		local v98_ = v93_ + 2 * v88_
		local v99_ = HUD.COLOR.BACKGROUND_DARK
		drawFilledRectRound(v95_, v96_, v97_, v98_, 0.5, v99_[1], v99_[2], v99_[3], v99_[4])
		renderText(0.5 - v90_ * 0.5, 0.9 + v85_.messageTextOffsetY, v92_, text)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		setTextWrapWidth(0)
		if glyphElement ~= nil then
			glyphElement:setPosition(v86_ + v94_ * 0.5 - v90_ * 0.5 + v89_, v96_ + (v98_ - glyphElement:getHeight()) * 0.5)
			glyphElement:draw()
		end
	end
end

-- Local values: self, skipText, posX, posY, messageTextPaddingX, messageTextPaddingY, messageBoxMaxWidth, messageTextSize, glyphElement, glyphWidth, glyphOffsetX, inputMode, textHeight, skipTextWidth, skipTextHeight, _, boxWidth, boxHeight, textWidth, boxPosX, boxPosY, color, textPosX, textPosY, skipPosX, skipPosY
function IntroductionHelpHUDUtil.drawSkipMessage(text)
	if not g_gui:getIsGuiVisible() then
		local v101_ = IntroductionHelpHUDUtil
		local v102_ = v101_.continueText
		local v103_ = v101_.messageTextPaddingX
		local v104_ = v101_.messageTextPaddingY
		local v105_ = v101_.messageBoxMaxWidth - 2 * v103_
		local v106_ = v101_.messageTextSize
		local v107_ = 0
		local v108_ = v101_.glyphOffsetX
		local v109_
		if g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD then
			v102_ = v101_.continueTextGamepad
			v109_ = v101_.glyphElement
		else
			v109_ = nil
		end
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		setTextWrapWidth(v105_)
		local v110_ = 0
		local v111_ = getTextWidth(v106_, v102_)
		local v112_, _ = getTextHeight(v106_, v102_)
		local v113_
		if v109_ == nil then
			v113_ = v111_
		else
			v107_ = v109_:getWidth()
			v113_ = v111_ + v107_ + v108_
		end
		local v114_
		if text == nil then
			v114_ = v112_
		else
			local v115_ = getTextWidth(v106_, text)
			local v116_
			v110_, v116_ = getTextHeight(v106_, text)
			v113_ = math.max(v113_, v115_)
			v114_ = v112_ + v110_ + v101_.messageTextToTextOffsetY
		end
		local v117_ = v113_ + 2 * v103_
		local v118_ = v114_ + 2 * v104_
		local v119_ = 0.5 - v117_ * 0.5
		local v120_ = 0.55 - v118_ * 0.5
		local v121_ = HUD.COLOR.BACKGROUND_DARK
		drawFilledRectRound(v119_, v120_, v117_, v118_, 0.5, v121_[1], v121_[2], v121_[3], v121_[4])
		if text ~= nil then
			local v122_ = v120_ + v118_ - v104_ - v110_ * 0.5
			renderText(0.5, v122_, v106_, text)
		end
		setTextBold(false)
		local v123_ = 0.5 - v107_ * 0.5
		local v124_ = v120_ + v104_ + v112_ * 0.5 + v101_.messageTextOffsetY
		renderText(v123_, v124_, v106_, v102_)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		setTextWrapWidth(0)
		if v109_ ~= nil then
			v109_:setPosition(v123_ + v111_ * 0.5, v120_ + (v118_ - v109_:getHeight()) * 0.5)
			v109_:draw()
		end
	end
end
if v1_ then
	IntroductionHelpHUDUtil.init()
	IntroductionHelpHUDUtil.setScale(v2_)
	log("Reloaded IntroductionHelpHUDUtil")
end
