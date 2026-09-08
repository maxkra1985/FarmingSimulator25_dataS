-- Local values: InputGlyphElement_mt
InputGlyphElement = {}
local InputGlyphElement_mt = Class(InputGlyphElement, HUDElement)
InputGlyphElement.GLYPH_OFFSET_X = 2
InputGlyphElement.TEXT_OFFSET_X = 4
InputGlyphElement.DEFAULT_TEXT_SIZE = 12

-- Upvalues: InputGlyphElement_mt
-- Local values: backgroundOverlay, self
function InputGlyphElement.new(inputDisplayManager, baseWidth, baseHeight, customMt)
	-- upvalues: (copy) InputGlyphElement_mt
	local v6_ = Overlay.new(nil, 0, 0, baseWidth, baseHeight)
	local v7_ = InputGlyphElement:superClass().new(v6_, nil, customMt or InputGlyphElement_mt)
	v7_.inputDisplayManager = inputDisplayManager
	v7_.plusOverlay = inputDisplayManager:getPlusOverlay()
	v7_.orOverlay = inputDisplayManager:getOrOverlay()
	v7_.keyboardOverlay = ButtonOverlay.new()
	v7_.keyboardOverlay:setColor(1, 1, 1, 1, 0, 0, 0, 0.8)
	v7_.actionNames = {}
	v7_.actionText = nil
	v7_.displayText = nil
	v7_.actionTextSize = InputGlyphElement.DEFAULT_TEXT_SIZE
	v7_.inputHelpElement = nil
	v7_.buttonOverlays = {}
	v7_.hasButtonOverlays = false
	v7_.separators = {}
	v7_.keyNames = {}
	v7_.hasKeyNames = false
	v7_.isLeftAligned = false
	v7_.color = {
		1,
		1,
		1,
		1
	}
	v7_.buttonColor = {
		1,
		1,
		1,
		1
	}
	v7_.overlayCopies = {}
	v7_.baseWidth = baseWidth
	v7_.baseHeight = baseHeight
	v7_.glyphOffsetX = 0
	v7_.textOffsetX = 0
	v7_.iconSizeX = baseWidth
	v7_.iconSizeY = baseHeight
	local v8_ = baseWidth * 0.5
	local v9_ = baseHeight * 0.5
	v7_.plusIconSizeX = v8_
	v7_.plusIconSizeY = v9_
	local v10_ = baseWidth * 0.5
	local v11_ = baseHeight * 0.5
	v7_.orIconSizeX = v10_
	v7_.orIconSizeY = v11_
	v7_.alignX = 1
	v7_.alignY = 1
	v7_.alignmentOffsetX = 0
	v7_.alignmentOffsetY = 0
	v7_.lowerCase = false
	v7_.upperCase = false
	v7_.bold = false
	v7_:setScale(1, 1)
	g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, v7_.onInputDevicesChanged, v7_)
	return v7_
end

function InputGlyphElement:delete()
	self.keyboardOverlay:delete()
	g_messageCenter:unsubscribeAll(self)
	InputGlyphElement:superClass().delete(self)
end

function InputGlyphElement:setIsLeftAligned(isLeftAligned)
	self.isLeftAligned = isLeftAligned
end

function InputGlyphElement:setScale(widthScale, heightScale)
	InputGlyphElement:superClass().setScale(self, widthScale, heightScale)
	self.glyphOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.GLYPH_OFFSET_X)
	self.textOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.TEXT_OFFSET_X)
	local v18_ = self.baseWidth * widthScale
	local v19_ = self.baseHeight * heightScale
	self.iconSizeX = v18_
	self.iconSizeY = v19_
	local v20_ = self.iconSizeX * 0.5
	local v21_ = self.iconSizeY * 0.5
	self.plusIconSizeX = v20_
	self.plusIconSizeY = v21_
	local v22_ = self.iconSizeX * 0.5
	local v23_ = self.iconSizeY * 0.5
	self.orIconSizeX = v22_
	self.orIconSizeY = v23_
end

function InputGlyphElement:setUpperCase(enableUpperCase)
	self.upperCase = enableUpperCase
	local v26_ = self.lowerCase
	if v26_ then
		v26_ = not enableUpperCase
	end
	self.lowerCase = v26_
	self:updateDisplayText()
end

function InputGlyphElement:setLowerCase(enableLowerCase)
	self.lowerCase = enableLowerCase
	local v29_ = self.upperCase
	if v29_ then
		v29_ = not enableLowerCase
	end
	self.upperCase = v29_
	self:updateDisplayText()
end

function InputGlyphElement:setBold(isBold)
	self.bold = isBold
end

-- Local values: r, g, b, a, bgR, bgG, bgB, bgA
function InputGlyphElement:setKeyboardGlyphColor(color, bgColor)
	local v35_ = nil
	local v36_ = nil
	local v37_ = nil
	local v38_ = nil
	self.color = color
	local v39_, v40_, v41_, v42_
	if color == nil then
		v39_ = nil
		v40_ = nil
		v41_ = nil
		v42_ = nil
	else
		v39_ = color[1]
		v40_ = color[2]
		v41_ = color[3]
		v42_ = color[4]
	end
	if bgColor ~= nil then
		v35_ = bgColor[1]
		v36_ = bgColor[2]
		v37_ = bgColor[3]
		v38_ = bgColor[4]
	end
	self.keyboardOverlay:setColor(v39_, v40_, v41_, v42_, v35_, v36_, v37_, v38_)
end

-- Local values: _, actionName, buttonOverlays, _, overlay
function InputGlyphElement:setButtonGlyphColor(color)
	self.buttonColor = color
	for _, v45_ in ipairs(self.actionNames) do
		local v46_ = self.buttonOverlays[v45_]
		if v46_ ~= nil then
			for _, v47_ in pairs(v46_) do
				v47_:setColor(unpack(color))
			end
		end
	end
end

function InputGlyphElement:onInputDevicesChanged()
	self:setActions(self.actionNames, self.actionText, self.actionTextSize, self.noModifiers)
end

function InputGlyphElement:setAction(actionName, actionText, actionTextSize, noModifiers)
	table.clear(self.actionNames)
	local v54_ = self.actionNames
	table.insert(v54_, actionName)
	self:setActions(self.actionNames, actionText, actionTextSize, noModifiers)
end

-- Local values: height, width, isDoubleAction, i, actionName, actionName2, helpElement, buttonOverlays, j, _, overlay, j, _, key, _, buttonOverlays, i, _, _, keyNames, _, key, keyWidth
function InputGlyphElement:setActions(actionNames, actionText, actionTextSize, noModifiers, customBinding)
	self.actionNames = actionNames
	self.actionText = actionText
	self.actionTextSize = actionTextSize or InputGlyphElement.DEFAULT_TEXT_SIZE
	self.noModifiers = noModifiers
	self:updateDisplayText()
	local v61_ = self:getHeight()
	local v62_ = #actionNames == 2
	local v63_ = 0
	for v64_, v65_ in ipairs(actionNames) do
		local v66_
		if v62_ then
			v66_ = actionNames[v64_ + 1]
		else
			v66_ = nil
		end
		local v67_ = self.inputDisplayManager:getControllerSymbolOverlays(v65_, v66_, "", noModifiers, customBinding)
		local v68_ = v67_.buttons
		self.separators = v67_.separators
		if self.buttonOverlays[v65_] == nil then
			self.buttonOverlays[v65_] = {}
		else
			for v69_ = 1, #self.buttonOverlays[v65_] do
				self.buttonOverlays[v65_][v69_] = nil
			end
		end
		self.hasButtonOverlays = false
		if #v68_ > 0 then
			for _, v70_ in ipairs(v68_) do
				local v71_ = self.buttonOverlays[v65_]
				table.insert(v71_, v70_)
				self.hasButtonOverlays = true
			end
		end
		if self.keyNames[v65_] == nil then
			self.keyNames[v65_] = {}
		else
			for v72_ = 1, #self.keyNames[v65_] do
				self.keyNames[v65_][v72_] = nil
			end
		end
		self.hasKeyNames = false
		if #v67_.keys > 0 then
			for _, v73_ in ipairs(v67_.keys) do
				local v74_ = self.keyNames[v65_]
				table.insert(v74_, v73_)
				self.hasKeyNames = true
			end
		end
		if v62_ then
			break
		end
	end
	if self.hasButtonOverlays then
		for _, v75_ in pairs(self.buttonOverlays) do
			for v76_, _ in ipairs(v75_) do
				if v76_ > 1 then
					v63_ = v63_ + self.plusIconSizeX + self.glyphOffsetX
				end
				v63_ = v63_ + self.iconSizeX + (v76_ < #v75_ and (self.glyphOffsetX or 0) or 0)
			end
		end
	elseif self.hasKeyNames then
		for _, v77_ in pairs(self.keyNames) do
			for _, v78_ in ipairs(v77_) do
				v63_ = v63_ + self.keyboardOverlay:getButtonWidth(v78_, v61_)
			end
		end
	end
	self:setDimension(v63_, v61_)
end

function InputGlyphElement:updateDisplayText()
	if self.actionText ~= nil then
		self.displayText = self.actionText
		if self.upperCase then
			self.displayText = utf8ToUpper(self.actionText)
			return
		end
		if self.lowerCase then
			self.displayText = utf8ToLower(self.actionText)
		end
	end
end

-- Local values: width, _, actionName, i, _, separatorType, separatorWidth, padding, _, actionName, keyNames, i, key, padding, keyWidth
function InputGlyphElement:getGlyphWidth()
	local v81_ = 0
	if self.hasButtonOverlays then
		for _, v82_ in ipairs(self.actionNames) do
			if self.buttonOverlays[v82_] ~= nil then
				for v83_, _ in ipairs(self.buttonOverlays[v82_]) do
					if v83_ > 1 and self:getDrawSeparator() then
						local v84_ = self.separators[v83_ - 1]
						local v85_ = 0
						if v84_ == InputHelpElement.SEPARATOR.COMBO_INPUT then
							v85_ = self.plusIconSizeX
						elseif v84_ == InputHelpElement.SEPARATOR.ANY_INPUT then
							v85_ = self.orIconSizeX
						end
						v81_ = v81_ + v85_ + self.glyphOffsetX
					end
					local v86_ = v83_ < #self.buttonOverlays[v82_] and (self.glyphOffsetX or 0) or 0
					v81_ = v81_ + self.iconSizeX + v86_
				end
			end
		end
		return v81_
	else
		if self.hasKeyNames then
			for _, v87_ in ipairs(self.actionNames) do
				local v88_ = self.keyNames[v87_]
				if v88_ ~= nil then
					for v89_, v90_ in ipairs(v88_) do
						local v91_ = v89_ < #self.keyNames[v87_] and (self.glyphOffsetX or 0) or 0
						v81_ = v81_ + self.keyboardOverlay:getButtonWidth(v90_, self.iconSizeY) + v91_
					end
				end
			end
		end
		return v81_
	end
end

function InputGlyphElement:getPositionOffset()
	return 0, 0
end

function InputGlyphElement:getDrawSeparator()
	return true
end

-- Local values: posX, posY, offsetX, offsetY, totalGlyphWidth, _, actionName, _, actionName, keyNames, i, key, padding
function InputGlyphElement:draw(clipX1, clipY1, clipX2, clipY2)
	if #self.actionNames ~= 0 and self.overlay:getIsVisible() then
		InputGlyphElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
		local v97_, v98_ = self:getPosition()
		local v99_, v100_ = self:getPositionOffset()
		local v101_ = self:getGlyphWidth()
		local v102_ = v97_ + v99_
		local v103_ = v98_ + v100_
		if not self.isLeftAligned then
			v102_ = v102_ + self.overlay.width - v101_
		end
		if self.hasButtonOverlays then
			for _, v104_ in ipairs(self.actionNames) do
				if self.buttonOverlays[v104_] ~= nil then
					v102_ = self:drawControllerButtons(self.buttonOverlays[v104_], v102_, v103_, clipX1, clipY1, clipX2, clipY2)
				end
			end
		elseif self.hasKeyNames then
			for _, v105_ in ipairs(self.actionNames) do
				local v106_ = self.keyNames[v105_]
				if v106_ ~= nil then
					for v107_, v108_ in ipairs(v106_) do
						local v109_ = v107_ < #v106_ and (self.glyphOffsetX or 0) or 0
						v102_ = v102_ + self.keyboardOverlay:renderButton(v108_, v102_, v103_, self.iconSizeY, true, clipX1, clipY1, clipX2, clipY2) + v109_
					end
				end
			end
		end
		if self.actionText ~= nil then
			self:drawActionText(v102_, v103_, clipX1, clipY1, clipX2, clipY2)
		end
	end
end

-- Local values: color, i, overlay, separatorType, separatorOverlay, separatorWidth, separatorHeight, overlayPosX, overlayPosY, overlayPosX, overlayPosY, padding
function InputGlyphElement:drawControllerButtons(buttonOverlays, posX, posY, clipX1, clipY1, clipX2, clipY2)
	local v118_ = self.buttonColor
	for v119_, v120_ in ipairs(buttonOverlays) do
		if v119_ > 1 and self:getDrawSeparator() then
			local v121_ = self.separators[v119_ - 1]
			local v122_ = self.orOverlay
			local v123_ = 0
			local v124_ = 0
			if v121_ == InputHelpElement.SEPARATOR.COMBO_INPUT then
				v122_ = self.plusOverlay
				v123_ = self.plusIconSizeX
				v124_ = self.plusIconSizeY
			elseif v121_ == InputHelpElement.SEPARATOR.ANY_INPUT then
				v123_ = self.orIconSizeX
				v124_ = self.orIconSizeY
			end
			v122_:renderCustom(posX, posY + (self.iconSizeY - v124_) * 0.5, v123_, v124_, v118_[1], v118_[2], v118_[3], v118_[4], clipX1, clipY1, clipX2, clipY2)
			posX = posX + v123_ + self.glyphOffsetX
		end
		v120_:renderCustom(posX, posY, self.iconSizeX, self.iconSizeY, v118_[1], v118_[2], v118_[3], v118_[4], clipX1, clipY1, clipX2, clipY2)
		local v125_ = v119_ < #buttonOverlays and (self.glyphOffsetX or 0) or 0
		posX = posX + self.iconSizeX + v125_
	end
	return posX
end

function InputGlyphElement:drawActionText(posX, posY, clipX1, clipY1, clipX2, clipY2)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(self.bold)
	local v133_ = setTextColor
	local v134_ = self.color
	v133_(unpack(v134_))
	if clipX1 ~= nil then
		setTextClipArea(clipX1, clipY1, clipX2, clipY2)
	end
	renderText(posX + self.textOffsetX, posY + self.actionTextSize * 0.5, self.actionTextSize, self.displayText)
	if clipX1 ~= nil then
		setTextClipArea(0, 0, 1, 1)
	end
end

function InputGlyphElement:setBaseSize(baseWidth, baseHeight)
	self.baseWidth = baseWidth
	self.baseHeight = baseHeight
	self.iconSizeX = baseWidth
	self.iconSizeY = baseHeight
	local v138_ = baseWidth * 0.5
	local v139_ = baseHeight * 0.5
	self.plusIconSizeX = v138_
	self.plusIconSizeY = v139_
	local v140_ = baseWidth * 0.5
	local v141_ = baseHeight * 0.5
	self.orIconSizeX = v140_
	self.orIconSizeY = v141_
	self:setDimension(baseWidth, baseHeight)
end
