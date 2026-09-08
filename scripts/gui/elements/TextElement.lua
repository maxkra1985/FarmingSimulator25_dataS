-- Local values: TextElement_mt
TextElement = {}
local TextElement_mt = Class(TextElement, GuiElement)
Gui.registerGuiElement("Text", TextElement)
TextElement.VERTICAL_ALIGNMENT = {
	["TOP"] = "top",
	["MIDDLE"] = "middle",
	["BOTTOM"] = "bottom"
}
TextElement.FORMAT = {
	["NONE"] = 1,
	["TEMPERATURE"] = 2,
	["CURRENCY"] = 3,
	["ACCOUNTING"] = 4,
	["NUMBER"] = 5,
	["PERCENTAGE"] = 6
}
TextElement.LAYOUT_MODE = {
	["TRUNCATE"] = 1,
	["RESIZE"] = 2,
	["OVERFLOW"] = 3,
	["CLIP"] = 4,
	["SCROLLING"] = 5,
	["FILL"] = 6
}
TextElement.REGEX_LAST_CHARACTER_ALLOWS_BREAK = "[%s%p\227\128\130]$"
TextElement.REGEX_BREAKING_CHARAKTERS_BEFORE = "[%s]$"
TextElement.REGEX_BREAKING_CHARAKTERS_AFTER = "[%p\227\128\130]$"

-- Upvalues: TextElement_mt
-- Local values: self
function TextElement.new(target, custom_mt)
	-- upvalues: (copy) TextElement_mt
	local v4_ = GuiElement.new(target, custom_mt or TextElement_mt)
	v4_.textColor = {
		1,
		1,
		1,
		1
	}
	v4_.textDisabledColor = nil
	v4_.textSelectedColor = nil
	v4_.textFocusedColor = nil
	v4_.textHighlightedColor = nil
	v4_.textFocusedSelectedColor = nil
	v4_.textHighlightedSelectedColor = nil
	v4_.textOffset = { 0, 0 }
	v4_.textSize = 0.03
	v4_.textBold = false
	v4_.textSelectedBold = false
	v4_.textFocusedBold = false
	v4_.textHighlightedBold = false
	v4_.text2Color = {
		1,
		1,
		1,
		1
	}
	v4_.text2DisabledColor = nil
	v4_.text2SelectedColor = nil
	v4_.text2FocusedColor = nil
	v4_.text2HighlightedColor = nil
	v4_.text2Offset = { 0, 0 }
	v4_.text2FocusedOffset = { 0, 0 }
	v4_.text2Size = 0
	v4_.text2Bold = false
	v4_.text2SelectedBold = false
	v4_.text2HighlightedBold = false
	v4_.textUpperCase = false
	v4_.textLinesPerPage = 0
	v4_.currentPage = 1
	v4_.defaultTextSize = v4_.textSize
	v4_.defaultText2Size = v4_.text2Size
	v4_.textLineHeightScale = RenderText.DEFAULT_LINE_HEIGHT_SCALE
	v4_.text = ""
	v4_.textAlignment = RenderText.ALIGN_CENTER
	v4_.textOriginalAlignment = RenderText.ALIGN_CENTER
	v4_.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT.MIDDLE
	v4_.ignoreDisabled = false
	v4_.firstLineIndentation = nil
	v4_.format = TextElement.FORMAT.NONE
	v4_.locaKey = nil
	v4_.value = nil
	v4_.formatDecimalPlaces = 0
	v4_.textMaxWidth = nil
	v4_.textMinWidth = 0
	v4_.textMaxNumLines = 1
	v4_.textAutoWidth = false
	v4_.textAutoHeight = false
	v4_.textLayoutMode = TextElement.LAYOUT_MODE.TRUNCATE
	v4_.textScrollOnFocusOnly = true
	v4_.textMinSize = 0.01
	v4_.sourceText = ""
	v4_.scrollingStartPos = 0
	v4_.scrollingOffset = 0
	v4_.scrollingMaxOffset = 0
	v4_.scrollingClipArea = nil
	v4_.scrollTime = 0
	v4_.updatedTextLayoutMode = false
	return v4_
end

-- Local values: xmlFilename, modName, _, textAlignment, wrapModeKey, textVerticalAlignment, verticalAlignKey, text, hasColon, format, f
function TextElement:loadFromXML(xmlFile, key)
	local v8_ = getXMLFilename(xmlFile)
	local v9_, _ = Utils.getModNameAndBaseDirectory(v8_)
	if v9_ ~= nil then
		self.customEnvironment = v9_
	end
	TextElement:superClass().loadFromXML(self, xmlFile, key)
	self.textColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textColor"), self.textColor)
	self.textSelectedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textSelectedColor"), self.textSelectedColor)
	self.text2SelectedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2SelectedColor"), self.text2SelectedColor)
	self.textFocusedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textFocusedColor"), self.textFocusedColor)
	self.text2FocusedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2FocusedColor"), self.text2FocusedColor)
	self.textFocusedSelectedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textFocusedSelectedColor"), self.textFocusedSelectedColor)
	self.textHighlightedSelectedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textHighlightedSelectedColor"), self.textHighlightedSelectedColor)
	self.textHighlightedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textHighlightedColor"), self.textHighlightedColor)
	self.text2HighlightedColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2HighlightedColor"), self.text2HighlightedColor)
	self.textDisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#textDisabledColor"), self.textDisabledColor)
	self.text2DisabledColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2DisabledColor"), self.text2DisabledColor)
	self.text2Color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#text2Color"), self.text2Color)
	self.textOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#textOffset"), self.textOffset)
	self.textFocusedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#textFocusedOffset"), self.textFocusedOffset)
	self.textSelectedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#textSelectedOffset"), self.textSelectedOffset)
	self.textHighlightedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#textHighlightedOffset"), self.textHighlightedOffset)
	self.textPressedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#textPressedOffset"), self.textPressedOffset)
	self.text2Offset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#text2Offset"), self.text2Offset)
	self.text2FocusedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#text2FocusedOffset"), self.text2FocusedOffset)
	self.textSize = GuiUtils.getNormalizedYValue(getXMLString(xmlFile, key .. "#textSize"), self.textSize)
	self.text2Size = GuiUtils.getNormalizedYValue(getXMLString(xmlFile, key .. "#text2Size"), self.text2Size)
	self.textBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textBold"), self.textBold)
	self.textSelectedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textSelectedBold"), self.textSelectedBold)
	self.textFocusedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textFocusedBold"), self.textFocusedBold)
	self.textHighlightedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textHighlightedBold"), self.textHighlightedBold)
	self.textUpperCase = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textUpperCase"), self.textUpperCase)
	self.text2Bold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#text2Bold"), self.text2Bold)
	self.text2SelectedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#text2SelectedBold"), self.text2SelectedBold)
	self.text2HighlightedBold = Utils.getNoNil(getXMLBool(xmlFile, key .. "#text2HighlightedBold"), self.text2HighlightedBold)
	self.textLinesPerPage = getXMLInt(xmlFile, key .. "#textLinesPerPage") or self.textLinesPerPage
	self.textLineHeightScale = getXMLFloat(xmlFile, key .. "#textLineHeightScale") or self.textLineHeightScale
	self.defaultTextSize = self.textSize
	self.defaultText2Size = self.text2Size
	self.textMaxWidth = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key .. "#textMaxWidth"), self.textMaxWidth)
	self.textMinWidth = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key .. "#textMinWidth"), self.textMinWidth)
	self.textMaxNumLines = getXMLInt(xmlFile, key .. "#textMaxNumLines") or self.textMaxNumLines
	self.textAutoWidth = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textAutoWidth"), self.textAutoWidth)
	self.textAutoHeight = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textAutoHeight"), self.textAutoHeight)
	self.textMinSize = GuiUtils.getNormalizedYValue(getXMLString(xmlFile, key .. "#textMinSize"), self.textMinSize)
	local v10_ = getXMLString(xmlFile, key .. "#textAlignment")
	if v10_ ~= nil then
		local v11_ = string.lower(v10_)
		if v11_ == "right" then
			self.textAlignment = RenderText.ALIGN_RIGHT
		elseif v11_ == "center" then
			self.textAlignment = RenderText.ALIGN_CENTER
		else
			self.textAlignment = RenderText.ALIGN_LEFT
		end
		self.textOriginalAlignment = self.textAlignment
	end
	local v12_ = getXMLString(xmlFile, key .. "#textLayoutMode")
	if v12_ ~= nil then
		local v13_ = string.lower(v12_)
		if v13_ == "truncate" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.TRUNCATE
		elseif v13_ == "resize" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.RESIZE
		elseif v13_ == "overflow" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.OVERFLOW
		elseif v13_ == "scrolling" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.SCROLLING
			self.textMaxNumLines = 1
		elseif v13_ == "fill" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.FILL
		end
	end
	self.textScrollOnFocusOnly = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textScrollOnFocusOnly"), self.textScrollOnFocusOnly)
	local v14_ = getXMLString(xmlFile, key .. "#textVerticalAlignment") or ""
	local v15_ = string.upper(v14_)
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT[v15_] or self.textVerticalAlignment
	self.ignoreDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreDisabled"), self.ignoreDisabled)
	local v16_ = getXMLString(xmlFile, key .. "#text")
	if v16_ ~= nil then
		if v16_ ~= "" and string.startsWith(v16_, "$l10n_") then
			local v17_ = string.endsWith(v16_, ":")
			if v17_ then
				v16_ = utf8Substr(v16_, 0, utf8Strlen(v16_) - 1)
			end
			v16_ = g_i18n:getText(v16_:sub(7), self.customEnvironment)
			if v17_ then
				v16_ = v16_ .. ":"
			end
		end
		self.sourceText = v16_
		if self.format == TextElement.FORMAT.NONE then
			self:setText(v16_, false, true)
		end
	end
	local v18_ = getXMLInt(xmlFile, key .. "#formatDecimalPlaces") or self.formatDecimalPlaces
	self.formatDecimalPlaces = math.max(v18_, 0)
	local v19_ = getXMLString(xmlFile, key .. "#format")
	if v19_ ~= nil then
		local v20_ = string.lower(v19_)
		local v21_ = TextElement.FORMAT.NONE
		if v20_ == "currency" then
			v21_ = TextElement.FORMAT.CURRENCY
		elseif v20_ == "accounting" then
			v21_ = TextElement.FORMAT.ACCOUNTING
		elseif v20_ == "temperature" then
			v21_ = TextElement.FORMAT.TEMPERATURE
		elseif v20_ == "number" then
			v21_ = TextElement.FORMAT.NUMBER
		elseif v20_ == "percentage" then
			v21_ = TextElement.FORMAT.PERCENTAGE
		elseif v20_ == "none" then
			v21_ = TextElement.FORMAT.NONE
		end
		self:setFormat(v21_)
	end
	self:addCallback(xmlFile, key .. "#onTextChanged", "onTextChangedCallback")
	self:updateSize()
end

-- Local values: textAlignment, wrapModeKey, textVerticalAlignment, verticalAlignKey, format, f
function TextElement:loadProfile(profile, applyProfile)
	TextElement:superClass().loadProfile(self, profile, applyProfile)
	self.textColor = GuiUtils.getColorArray(profile:getValue("textColor"), self.textColor)
	self.textSelectedColor = GuiUtils.getColorArray(profile:getValue("textSelectedColor"), self.textSelectedColor)
	self.textFocusedColor = GuiUtils.getColorArray(profile:getValue("textFocusedColor"), self.textFocusedColor)
	self.textFocusedSelectedColor = GuiUtils.getColorArray(profile:getValue("textFocusedSelectedColor"), self.textFocusedSelectedColor)
	self.textHighlightedSelectedColor = GuiUtils.getColorArray(profile:getValue("textHighlightedSelectedColor"), self.textHighlightedSelectedColor)
	self.textHighlightedColor = GuiUtils.getColorArray(profile:getValue("textHighlightedColor"), self.textHighlightedColor)
	self.textDisabledColor = GuiUtils.getColorArray(profile:getValue("textDisabledColor"), self.textDisabledColor)
	self.text2Color = GuiUtils.getColorArray(profile:getValue("text2Color"), self.text2Color)
	self.text2SelectedColor = GuiUtils.getColorArray(profile:getValue("text2SelectedColor"), self.text2SelectedColor)
	self.text2FocusedColor = GuiUtils.getColorArray(profile:getValue("text2FocusedColor"), self.text2FocusedColor)
	self.text2HighlightedColor = GuiUtils.getColorArray(profile:getValue("text2HighlightedColor"), self.text2HighlightedColor)
	self.text2DisabledColor = GuiUtils.getColorArray(profile:getValue("text2DisabledColor"), self.text2DisabledColor)
	self.textSize = GuiUtils.getNormalizedYValue(profile:getValue("textSize"), self.textSize)
	self.textOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("textOffset"), self.textOffset)
	self.textFocusedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("textFocusedOffset"), self.textFocusedOffset)
	self.textSelectedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("textSelectedOffset"), self.textSelectedOffset)
	self.textHighlightedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("textHighlightedOffset"), self.textHighlightedOffset)
	self.textPressedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("textPressedOffset"), self.textPressedOffset)
	self.text2Size = GuiUtils.getNormalizedYValue(profile:getValue("text2Size"), self.text2Size)
	self.text2Offset = GuiUtils.getNormalizedScreenValues(profile:getValue("text2Offset"), self.text2Offset)
	self.text2FocusedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("text2FocusedOffset"), self.text2FocusedOffset)
	self.textBold = profile:getBool("textBold", self.textBold)
	self.textSelectedBold = profile:getBool("textSelectedBold", self.textSelectedBold)
	self.textFocusedBold = profile:getBool("textFocusedBold", self.textFocusedBold)
	self.textHighlightedBold = profile:getBool("textHighlightedBold", self.textHighlightedBold)
	self.text2Bold = profile:getBool("text2Bold", self.text2Bold)
	self.text2SelectedBold = profile:getBool("text2SelectedBold", self.text2SelectedBold)
	self.text2HighlightedBold = profile:getBool("text2HighlightedBold", self.text2HighlightedBold)
	self.textUpperCase = profile:getBool("textUpperCase", self.textUpperCase)
	self.textLinesPerPage = profile:getNumber("textLinesPerPage", self.textLinesPerPage)
	self.textLineHeightScale = profile:getNumber("textLineHeightScale", self.textLineHeightScale)
	self.textMaxWidth = GuiUtils.getNormalizedXValue(profile:getValue("textMaxWidth"), self.textMaxWidth)
	self.textMinWidth = GuiUtils.getNormalizedXValue(profile:getValue("textMinWidth"), self.textMinWidth)
	self.textMaxNumLines = profile:getNumber("textMaxNumLines", self.textMaxNumLines)
	self.textAutoWidth = profile:getBool("textAutoWidth", self.textAutoWidth)
	self.textAutoHeight = profile:getBool("textAutoHeight", self.textAutoHeight)
	self.textMinSize = GuiUtils.getNormalizedYValue(profile:getValue("textMinSize"), self.textMinSize)
	self.defaultTextSize = self.textSize
	self.defaultText2Size = self.text2Size
	self.ignoreDisabled = profile:getBool("ignoreDisabled", self.ignoreDisabled)
	local v25_ = profile:getValue("textAlignment")
	if v25_ ~= nil then
		local v26_ = string.lower(v25_)
		if v26_ == "right" then
			self.textAlignment = RenderText.ALIGN_RIGHT
		elseif v26_ == "center" then
			self.textAlignment = RenderText.ALIGN_CENTER
		else
			self.textAlignment = RenderText.ALIGN_LEFT
		end
		self.textOriginalAlignment = self.textAlignment
	end
	local v27_ = profile:getValue("textLayoutMode")
	if v27_ ~= nil then
		local v28_ = string.lower(v27_)
		if v28_ == "truncate" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.TRUNCATE
		elseif v28_ == "resize" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.RESIZE
		elseif v28_ == "overflow" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.OVERFLOW
		elseif v28_ == "scrolling" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.SCROLLING
			self.textMaxNumLines = 1
		elseif v28_ == "fill" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.FILL
		end
	end
	self.textScrollOnFocusOnly = profile:getBool("textScrollOnFocusOnly", self.textScrollOnFocusOnly)
	local v29_ = profile:getValue("textVerticalAlignment", "")
	local v30_ = string.upper(v29_)
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT[v30_] or self.textVerticalAlignment
	local v31_ = profile:getNumber("formatDecimalPlaces", self.formatDecimalPlaces)
	self.formatDecimalPlaces = math.max(v31_, 0)
	local v32_ = profile:getValue("format")
	if v32_ ~= nil then
		local v33_ = string.lower(v32_)
		local v34_ = TextElement.FORMAT.NONE
		if v33_ == "currency" then
			v34_ = TextElement.FORMAT.CURRENCY
		elseif v33_ == "accounting" then
			v34_ = TextElement.FORMAT.ACCOUNTING
		elseif v33_ == "temperature" then
			v34_ = TextElement.FORMAT.TEMPERATURE
		elseif v33_ == "number" then
			v34_ = TextElement.FORMAT.NUMBER
		elseif v33_ == "percentage" then
			v34_ = TextElement.FORMAT.PERCENTAGE
		elseif v33_ == "none" then
			v34_ = TextElement.FORMAT.NONE
		end
		self:setFormat(v34_)
	end
	if applyProfile then
		self:updateSize()
	end
end

function TextElement:copyAttributes(src)
	TextElement:superClass().copyAttributes(self, src)
	self.text = src.text
	self.format = src.format
	self.locaKey = src.locaKey
	self.value = src.value
	self.formatDecimalPlaces = src.formatDecimalPlaces
	self.sourceText = src.sourceText
	self.textColor = table.clone(src.textColor)
	if src.textSelectedColor ~= nil then
		self.textSelectedColor = table.clone(src.textSelectedColor)
	end
	if src.textFocusedColor ~= nil then
		self.textFocusedColor = table.clone(src.textFocusedColor)
	end
	if src.textFocusedSelectedColor ~= nil then
		self.textFocusedSelectedColor = table.clone(src.textFocusedSelectedColor)
	end
	if src.textHighlightedColor ~= nil then
		self.textHighlightedColor = table.clone(src.textHighlightedColor)
	end
	if src.textHighlightedSelectedColor ~= nil then
		self.textHighlightedSelectedColor = table.clone(src.textHighlightedSelectedColor)
	end
	if src.textDisabledColor ~= nil then
		self.textDisabledColor = table.clone(src.textDisabledColor)
	end
	self.text2Color = table.clone(src.text2Color)
	if src.text2SelectedColor ~= nil then
		self.text2SelectedColor = table.clone(src.text2SelectedColor)
	end
	if src.text2FocusedColor ~= nil then
		self.text2FocusedColor = table.clone(src.text2FocusedColor)
	end
	if src.text2HighlightedColor ~= nil then
		self.text2HighlightedColor = table.clone(src.text2HighlightedColor)
	end
	if src.text2DisabledColor ~= nil then
		self.text2DisabledColor = table.clone(src.text2DisabledColor)
	end
	self.textSize = src.textSize
	self.textOffset = table.clone(src.textOffset)
	if src.textFocusedOffset ~= nil then
		self.textFocusedOffset = table.clone(src.textFocusedOffset)
	end
	if src.textSelectedOffset ~= nil then
		self.textSelectedOffset = table.clone(src.textSelectedOffset)
	end
	if src.textHighlightedOffset ~= nil then
		self.textHighlightedOffset = table.clone(src.textHighlightedOffset)
	end
	if src.textPressedOffset ~= nil then
		self.textPressedOffset = table.clone(src.textPressedOffset)
	end
	self.text2Size = src.text2Size
	self.text2Offset = table.clone(src.text2Offset)
	self.text2FocusedOffset = table.clone(src.text2FocusedOffset)
	self.ignoreDisabled = src.ignoreDisabled
	self.textMaxWidth = src.textMaxWidth
	self.textMinWidth = src.textMinWidth
	self.textMaxNumLines = src.textMaxNumLines
	self.textAutoWidth = src.textAutoWidth
	self.textAutoHeight = src.textAutoHeight
	self.textLayoutMode = src.textLayoutMode
	self.textScrollOnFocusOnly = src.textScrollOnFocusOnly
	self.textMinSize = src.textMinSize
	self.textBold = src.textBold
	self.textSelectedBold = src.textSelectedBold
	self.textFocusedBold = src.textFocusedBold
	self.textHighlightedBold = src.textHighlightedBold
	self.text2Bold = src.text2Bold
	self.text2SelectedBold = src.text2SelectedBold
	self.text2HighlightedBold = src.text2HighlightedBold
	self.textUpperCase = src.textUpperCase
	self.textLinesPerPage = src.textLinesPerPage
	self.textAlignment = src.textAlignment
	self.textOriginalAlignment = src.textOriginalAlignment
	self.currentPage = src.currentPage
	self.defaultTextSize = src.defaultTextSize
	self.defaultText2Size = src.defaultText2Size
	self.textLineHeightScale = src.textLineHeightScale
	self.textVerticalAlignment = src.textVerticalAlignment
	self.onTextChangedCallback = src.onTextChangedCallback
end

function TextElement:delete()
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self)
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self)
	TextElement:superClass().delete(self)
end

function TextElement:setTextSize(size)
	self.textSize = size
	self:updateSize()
end

function TextElement:setAbsolutePosition(x, y)
	TextElement:superClass().setAbsolutePosition(self, x, y)
	if not self.ignoreStartPositionUpdate then
		self.scrollingStartPos = self.absPosition[1]
	end
end

function TextElement:setDisabled(isDisabled)
	TextElement:superClass().setDisabled(self, isDisabled)
	self:updateScrollingLayoutMode()
end

-- Local values: textLayoutMode
function TextElement:updateAbsolutePosition()
	TextElement:superClass().updateAbsolutePosition(self)
	local v46_ = self:getTextLayoutMode()
	if (self.textMaxNumLines ~= 1 or v46_ ~= TextElement.LAYOUT_MODE.OVERFLOW and v46_ ~= TextElement.LAYOUT_MODE.SCROLLING) and not (self.textAutoWidth or self.textAutoHeight) then
		self:setTextInternal(self.sourceText, nil, true)
	end
	if not self.ignoreStartPositionUpdate then
		self.scrollingStartPos = self.absPosition[1]
		self:updateScrollingParameters()
	end
end

function TextElement:setText(text, forceTextSize, isInitializing, forceScrollingParameterUpdate)
	self.locaKey = nil
	self.value = nil
	self.format = TextElement.FORMAT.NONE
	if self:setTextInternal(text, forceTextSize, isInitializing) or forceScrollingParameterUpdate then
		self.scrollTime = 0
		self:updateScrollingParameters()
	end
end

-- Local values: textHasChanged, maxWidth, limitVerticalLines, textLayoutMode, textMaxNumLines, lengthWithNoLineLimit, _, numLines, lastCharAllowsBreak, needsBreak, breakOffset
function TextElement:setTextInternal(text, forceTextSize, skipCallback, doNotUpdateSize)
	local v56_ = text == nil and "" or text
	setTextWidthScale(g_textWidthScale)
	local v57_ = tostring(v56_)
	if self.textUpperCase then
		v57_ = utf8ToUpper(v57_)
	end
	local v58_ = self.sourceText ~= v57_
	self.sourceText = v57_
	self.textSize = self.defaultTextSize
	self.text2Size = self.defaultText2Size
	self:updateSize()
	local v59_ = self.absSize[1]
	local v60_
	if self.textMaxWidth == nil then
		v60_ = self.textAutoWidth and 1 or v59_
	else
		v60_ = self.textMaxWidth
	end
	local v61_ = false
	local v62_ = self:getTextLayoutMode()
	setTextBold(self.textBold)
	if v62_ == TextElement.LAYOUT_MODE.RESIZE then
		local v63_ = self.textMaxNumLines
		local v64_ = v57_:find("[ -]") == nil and 1 or v63_
		if v64_ > 1 then
			setTextWrapWidth(v60_, false)
			local v65_ = getTextLength(self.textSize, v57_, 99999)
			while getTextLength(self.textSize, v57_, v64_) < v65_ do
				self.textSize = self.textSize - self.defaultTextSize * 0.05
				self.text2Size = self.text2Size - self.defaultText2Size * 0.05
				if self.textSize <= self.textMinSize then
					self.textSize = self.textSize + self.defaultTextSize * 0.05
					self.text2Size = self.text2Size + self.defaultText2Size * 0.05
					if v64_ == 1 then
						v57_ = Utils.limitTextToWidth(v57_, self.textSize, v60_, false, "...")
					else
						v61_ = true
					end
					break
				end
			end
		else
			while v60_ < getTextWidth(self.textSize, v57_) do
				self.textSize = self.textSize - self.defaultTextSize * 0.05
				self.text2Size = self.text2Size - self.defaultText2Size * 0.05
				if self.textSize <= self.textMinSize then
					self.textSize = self.textSize + self.defaultTextSize * 0.05
					self.text2Size = self.text2Size + self.defaultText2Size * 0.05
					v57_ = Utils.limitTextToWidth(v57_, self.textSize, v60_, false, "...")
					break
				end
			end
		end
		setTextWrapWidth(0)
	elseif v62_ ~= TextElement.LAYOUT_MODE.OVERFLOW and (v62_ ~= TextElement.LAYOUT_MODE.SCROLLING and (v62_ == TextElement.LAYOUT_MODE.TRUNCATE or v62_ == TextElement.LAYOUT_MODE.FILL)) then
		if self.textMaxNumLines == 1 and v62_ == TextElement.LAYOUT_MODE.TRUNCATE then
			v57_ = Utils.limitTextToWidth(v57_, self.textSize, v60_, false, "...")
		else
			v61_ = true
		end
	end
	if v61_ then
		setTextWrapWidth(v60_)
		local _, v66_ = getTextHeight(self.textSize, v57_)
		if self.textMaxNumLines < v66_ then
			local v67_ = nil
			while true do
				local _, v68_ = getTextHeight(self.textSize, v57_)
				if self.textMaxNumLines >= v68_ then
					break
				end
				v67_ = string.match(v57_, TextElement.REGEX_LAST_CHARACTER_ALLOWS_BREAK)
				v57_ = utf8Substr(v57_, 0, utf8Strlen(v57_) - 1)
			end
			if v62_ == TextElement.LAYOUT_MODE.TRUNCATE then
				local v69_ = utf8Substr
				local v70_ = utf8Strlen(v57_) - 3
				v57_ = v69_(v57_, 0, (math.max(v70_, 0))) .. "..."
			elseif self.textLayoutMode == TextElement.LAYOUT_MODE.FILL and v67_ == nil then
				while utf8Strlen(v57_) > 0 do
					local v71_ = string.match(v57_, TextElement.REGEX_LAST_CHARACTER_ALLOWS_BREAK)
					local v72_ = v71_ and string.match(v57_, TextElement.REGEX_BREAKING_CHARAKTERS_AFTER) ~= nil and 0 or -1
					v57_ = utf8Substr(v57_, 0, utf8Strlen(v57_) + v72_)
					if v71_ then
						break
					end
				end
			end
		end
		setTextWrapWidth(0)
	end
	setTextBold(false)
	self.text = v57_
	if v58_ and not skipCallback then
		self:raiseCallback("onTextChangedCallback", self, self.text)
		self:updateScaledWidth(1, 1)
	end
	self:updateSize(forceTextSize)
	return v58_
end

function TextElement:getText()
	return self.sourceText
end

function TextElement:setValue(value)
	self.value = value
	self:updateFormattedText()
end

function TextElement:getValue()
	return self.value
end

function TextElement:setFormat(format)
	if format == nil then
		format = TextElement.FORMAT.NONE
	end
	if self.format ~= format then
		if self.format == TextElement.FORMAT.TEMPERATURE then
			g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self)
		elseif format == TextElement.FORMAT.CURRENCY or format == TextElement.FORMAT.ACCOUNTING then
			g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self)
		end
		self.format = format
		self:updateFormattedText()
		if format == TextElement.FORMAT.TEMPERATURE then
			g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.onFormatUnitChanged, self)
			return
		end
		if format == TextElement.FORMAT.CURRENCY or format == TextElement.FORMAT.ACCOUNTING then
			g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.onFormatUnitChanged, self)
		end
	end
end

function TextElement:setLocaKey(key)
	self.locaKey = key
	self.format = TextElement.FORMAT.NONE
	self.value = nil
	self:updateFormattedText()
end

-- Local values: text, value, format, decimalPlaces, length
function TextElement:updateFormattedText()
	local v82_ = ""
	local v83_ = self.value
	if v83_ == nil then
		if self.locaKey ~= nil then
			local v84_ = self.locaKey:len()
			if self.locaKey:sub(v84_, v84_ + 1) == ":" then
				v82_ = g_i18n:getText(self.locaKey:sub(1, v84_ - 1), self.customEnvironment) .. ":"
			else
				v82_ = g_i18n:getText(self.locaKey, self.customEnvironment)
			end
		end
	else
		local v85_ = self.format
		local v86_ = self.formatDecimalPlaces
		if v85_ == TextElement.FORMAT.NONE then
			v82_ = tostring(v83_)
		elseif v85_ == TextElement.FORMAT.NUMBER then
			v82_ = g_i18n:formatNumber(v83_, v86_)
		elseif v85_ == TextElement.FORMAT.CURRENCY then
			v82_ = g_i18n:formatMoney(v83_, v86_, true, true)
		elseif v85_ == TextElement.FORMAT.ACCOUNTING then
			v82_ = g_i18n:formatMoney(v83_, v86_, true, false)
		elseif v85_ == TextElement.FORMAT.TEMPERATURE then
			v82_ = g_i18n:formatTemperature(v83_, v86_)
		elseif v85_ == TextElement.FORMAT.PERCENTAGE then
			v82_ = g_i18n:formatNumber(v83_ * 100, v86_) .. "%"
		end
	end
	self:setTextInternal(v82_)
end

function TextElement:updateScrollingParameters()
	if self.textLayoutMode == TextElement.LAYOUT_MODE.SCROLLING then
		self:setAbsolutePosition(self.scrollingStartPos)
		self.scrollingOffset = 0
		local v88_ = self:getTextWidth(true) - self.absSize[1]
		self.scrollingMaxOffset = math.max(0, v88_)
		self.scrollingClipArea = self.scrollingClipArea or {}
		self.scrollingClipArea[1] = self.scrollingStartPos
		self.scrollingClipArea[2] = self.absPosition[2]
		self.scrollingClipArea[3] = self.scrollingStartPos + self.absSize[1]
		self.scrollingClipArea[4] = self.absPosition[2] + self.absSize[2]
		if self.scrollingMaxOffset > 0 then
			self.textAlignment = RenderText.ALIGN_LEFT
			return
		end
		self.textAlignment = self.textOriginalAlignment
	end
end

function TextElement:onFormatUnitChanged()
	self:updateFormattedText()
end

function TextElement:setFirstLineIndentation(indentation)
	self.firstLineIndentation = indentation
end

function TextElement:setTextColor(r, g, b, a)
	self.textColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setTextSelectedColor(r, g, b, a)
	self.textSelectedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setTextFocusedColor(r, g, b, a)
	self.textFocusedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setTextFocusedSelectedColor(r, g, b, a)
	self.textFocusedSelectedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setTextHighlightedSelectedColor(r, g, b, a)
	self.textHighlightedSelectedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setTextHighlightedColor(r, g, b, a)
	self.textHighlightedColor = {
		r,
		g,
		b,
		a
	}
end

-- Local values: retColor
function TextElement:getTextColor()
	local v123_ = self.textColor
	if self.disabled and not self.ignoreDisabled then
		v123_ = self.textDisabledColor
	elseif self:getIsSelected() then
		if self:getIsFocused() then
			v123_ = self.textFocusedSelectedColor or self.textSelectedColor
		elseif self:getIsHighlighted() then
			v123_ = self.textHighlightedSelectedColor or self.textSelectedColor
		else
			v123_ = self.textSelectedColor
		end
	elseif self:getIsFocused() then
		v123_ = self.textFocusedColor
	elseif self:getIsHighlighted() then
		v123_ = self.textHighlightedColor
	end
	if v123_ == nil then
		v123_ = self.textColor
	end
	return v123_
end

function TextElement:setText2Color(r, g, b, a)
	self.text2Color = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setText2SelectedColor(r, g, b, a)
	self.text2SelectedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setText2FocusedColor(r, g, b, a)
	self.text2FocusedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:setText2HighlightedColor(r, g, b, a)
	self.text2HighlightedColor = {
		r,
		g,
		b,
		a
	}
end

function TextElement:getText2Color()
	if self.disabled and not self.ignoreDisabled then
		return self.text2DisabledColor
	elseif self:getIsSelected() then
		return self.text2SelectedColor
	elseif self:getIsFocused() then
		return self.text2FocusedColor
	elseif self:getIsHighlighted() then
		return self.text2HighlightedColor
	else
		return self.text2Color
	end
end

-- Local values: width
function TextElement:getTextWidth(useSourceText)
	setTextBold(self.textBold)
	local v147_ = getTextWidth(self.textSize, self.text)
	if useSourceText then
		v147_ = getTextWidth(self.textSize, self.sourceText)
	end
	setTextBold(false)
	if self:getTextLayoutMode() ~= TextElement.LAYOUT_MODE.OVERFLOW and (self.textLayoutMode ~= TextElement.LAYOUT_MODE.SCROLLING and not self.textAutoWidth) then
		local v148_ = self.absSize[1]
		v147_ = math.min(v147_, v148_)
	end
	return v147_
end

-- Local values: height, numLines
function TextElement:getTextHeight(includeNegativeSpacing)
	if self.textMaxNumLines > 1 then
		if self.textMaxWidth == nil then
			setTextWrapWidth(self.absSize[1])
		else
			setTextWrapWidth(self.textMaxWidth)
		end
	end
	setTextBold(self.textBold)
	setTextFirstLineIndentation(self.firstLineIndentation or 0)
	setTextLineHeightScale(self.textLineHeightScale)
	local v151_, v152_ = getTextHeight(self.textSize, self.text)
	if includeNegativeSpacing == true and v152_ > 0 then
		v151_ = v151_ + v151_ / v152_ * 0.1
	end
	setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
	setTextFirstLineIndentation(0)
	setTextBold(false)
	setTextWrapWidth(0)
	return v151_, v152_
end

-- Local values: state, xOffset, yOffset
function TextElement:getTextOffset()
	local v154_ = self:getOverlayState()
	local v155_ = self.textOffset[1]
	local v156_ = self.textOffset[2]
	if v154_ == GuiOverlay.STATE_FOCUSED and self.textFocusedOffset ~= nil then
		return self.textFocusedOffset[1], self.textFocusedOffset[2]
	end
	if v154_ == GuiOverlay.STATE_SELECTED and self.textSelectedOffset ~= nil then
		return self.textSelectedOffset[1], self.textSelectedOffset[2]
	end
	if v154_ == GuiOverlay.STATE_HIGHLIGHTED and self.textHighlightedOffset ~= nil then
		return self.textHighlightedOffset[1], self.textHighlightedOffset[2]
	end
	if v154_ == GuiOverlay.STATE_PRESSED and self.textPressedOffset ~= nil then
		v155_ = self.textPressedOffset[1]
		v156_ = self.textPressedOffset[2]
	end
	return v155_, v156_
end

-- Local values: xOffset, yOffset, state
function TextElement:getText2Offset()
	local v158_ = self.text2Offset[1]
	local v159_ = self.text2Offset[2]
	local v160_ = self:getOverlayState()
	if v160_ == GuiOverlay.STATE_FOCUSED or (v160_ == GuiOverlay.STATE_PRESSED or (v160_ == GuiOverlay.STATE_SELECTED or v160_ == GuiOverlay.STATE_HIGHLIGHTED)) then
		v158_ = self.text2FocusedOffset[1]
		v159_ = self.text2FocusedOffset[2]
	end
	return v158_, v159_
end

function TextElement:getIsScrollingAllowed()
	return not self.textScrollOnFocusOnly or self:getIsFocused() or (self:getIsHighlighted() or self:getIsSelected())
end

function TextElement:getTextLayoutMode()
	if self.textLayoutMode == TextElement.LAYOUT_MODE.SCROLLING and not self:getIsScrollingAllowed() then
		return TextElement.LAYOUT_MODE.TRUNCATE
	else
		return self.textLayoutMode
	end
end

function TextElement:getDoRenderText()
	return true
end

-- Local values: xPos
function TextElement:getTextPositionX()
	local v164_ = self.absPosition[1]
	if self.textAlignment == RenderText.ALIGN_CENTER then
		return v164_ + self.absSize[1] * 0.5
	end
	if self.textAlignment == RenderText.ALIGN_RIGHT then
		v164_ = v164_ + self.absSize[1]
	end
	return v164_
end

-- Local values: yPos
function TextElement:getTextPositionY(lineHeight, totalHeight)
	local v168_ = self.absPosition[2]
	if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.TOP then
		return v168_ + self.absSize[2] - lineHeight
	elseif self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.MIDDLE then
		return v168_ + (self.absSize[2] + totalHeight) * 0.5 - lineHeight
	else
		return v168_ + totalHeight - lineHeight
	end
end

-- Local values: lineHeight, totalHeight, xPos, yPos
function TextElement:getTextPosition(text)
	local v171_ = getTextHeight(self.textSize, utf8ToUpper(utf8Substr(text, 0, 1) or ""))
	local v172_ = getTextHeight(self.textSize, text)
	return self:getTextPositionX(), self:getTextPositionY(v171_, v172_)
end

-- Local values: currentTextLayoutMode, scrollLengthFactor, scrollDuration, alpha
function TextElement:update(dt)
	TextElement:superClass().update(self, dt)
	if self.textLayoutMode == TextElement.LAYOUT_MODE.SCROLLING then
		local v175_ = self:getTextLayoutMode()
		self:updateScrollingLayoutMode()
		if v175_ == TextElement.LAYOUT_MODE.SCROLLING then
			if self.scrollingMaxOffset > 0 then
				local v176_ = 9000 * ((self.scrollingMaxOffset / self.absSize[1] - 1) * 0.5 + 1)
				self.scrollTime = self.scrollTime + dt
				if v176_ <= self.scrollTime then
					self.scrollTime = -v176_
				end
				local v177_ = MathUtil.smoothstep
				local v178_ = self.scrollTime
				local v179_ = v177_(0.2, 0.8, math.abs(v178_) / v176_)
				self.scrollingOffset = self.scrollingMaxOffset * v179_
			end
			if self.absPosition[1] ~= self.scrollingStartPos - self.scrollingOffset then
				self.ignoreStartPositionUpdate = true
				self:setAbsolutePosition(self.scrollingStartPos - self.scrollingOffset, nil)
				self.ignoreStartPositionUpdate = false
			end
		end
	end
end

-- Local values: xOffset, yOffset, maxWidth, text, bold, xPos, yPos, baselineOffset, x2Offset, y2Offset, r, g, b, a, r, g, b, a, x, width, debugWidth, debugHeight
function TextElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self:getDoRenderText() and (self.text ~= nil and self.text ~= "") then
		local v185_, v186_ = self:getTextOffset()
		if self:getTextLayoutMode() == TextElement.LAYOUT_MODE.SCROLLING and self.scrollingMaxOffset > 0 then
			local v187_ = self.scrollingClipArea[1] + v185_
			clipX1 = math.max(v187_, clipX1 or 0)
			local v188_ = self.scrollingClipArea[2] + v186_
			clipY1 = math.max(v188_, clipY1 or 0)
			local v189_ = self.scrollingClipArea[3] + v185_
			clipX2 = math.min(v189_, clipX2 or math.huge)
			local v190_ = self.scrollingClipArea[4] + v186_
			clipY2 = math.min(v190_, clipY2 or math.huge)
		end
		if clipX1 ~= nil then
			setTextClipArea(clipX1, clipY1, clipX2, clipY2)
		end
		setTextAlignment(self.textAlignment)
		local v191_ = self.absSize[1]
		local v192_
		if self.textMaxWidth == nil then
			v192_ = self.textAutoWidth and 1 or v191_
		else
			v192_ = self.textMaxWidth
		end
		if self.textMaxNumLines > 1 then
			setTextWrapWidth(v192_)
		end
		setTextFirstLineIndentation(self.firstLineIndentation or 0)
		setTextLineBounds((self.currentPage - 1) * self.textLinesPerPage, self.textLinesPerPage)
		setTextLineHeightScale(self.textLineHeightScale)
		local v193_ = self.text
		local v194_ = not (self.textBold or self.textSelectedBold and self:getIsSelected()) and (not (self.textHighlightedBold and self:getIsHighlighted()) and self.textFocusedBold)
		if v194_ then
			v194_ = self:getIsFocused()
		end
		setTextBold(v194_)
		local v195_, v196_ = self:getTextPosition(v193_)
		local v197_ = v196_ + self.textSize * 0.1
		if self.text2Size > 0 then
			local v198_, v199_ = self:getText2Offset()
			local v200_ = not self.text2Bold and (not (self.text2SelectedBold and self:getIsSelected()) and self.text2HighlightedBold)
			if v200_ then
				v200_ = self:getIsHighlighted()
			end
			setTextBold(v200_)
			local v201_, v202_, v203_, v204_ = unpack(self:getText2Color())
			setTextColor(v201_, v202_, v203_, v204_ * self.alpha)
			renderText(v195_ + v198_, v197_ + v199_, self.text2Size, v193_)
		end
		local v205_, v206_, v207_, v208_ = unpack(self:getTextColor())
		setTextColor(v205_, v206_, v207_, v208_ * self.alpha)
		renderText(v195_ + v185_, v197_ + v186_, self.textSize, v193_)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
		setTextColor(1, 1, 1, 1)
		setTextLineBounds(0, 0)
		setTextWrapWidth(0)
		setTextFirstLineIndentation(0)
		if clipX1 ~= nil then
			setTextClipArea(0, 0, 1, 1)
		end
		if self.debugEnabled or g_uiDebugEnabled then
			setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 1)
			local v209_ = v195_ + v185_
			if self.textAlignment == RenderText.ALIGN_RIGHT then
				v209_ = v209_ - v192_
			elseif self.textAlignment == RenderText.ALIGN_CENTER then
				v209_ = v209_ - v192_ / 2
			end
			renderOverlay(GuiElement.debugOverlay, v209_, v197_ + v186_, v192_, g_pixelSizeY * 2)
			local v210_ = self:getTextWidth()
			local v211_ = v195_ + v185_
			if self.textAlignment == RenderText.ALIGN_RIGHT then
				v211_ = v211_ - v210_
			elseif self.textAlignment == RenderText.ALIGN_CENTER then
				v211_ = v211_ - v210_ * 0.5
			end
			setOverlayColor(GuiElement.debugOverlay, 0, 1, 0, 1)
			renderOverlay(GuiElement.debugOverlay, v211_, v197_ + v186_, v210_, 1 * g_pixelSizeY)
			setOverlayColor(GuiElement.debugOverlay, 1, 0.5, 0, 1)
			renderOverlay(GuiElement.debugOverlay, v211_, v197_ + v186_ + getTextHeight(self.textSize, v193_) * 0.5, v210_, 1 * g_pixelSizeY)
			setOverlayColor(GuiElement.debugOverlay, 0, 0, 1, 1)
			renderOverlay(GuiElement.debugOverlay, v211_, v197_ + v186_ + getTextHeight(self.textSize, v193_) * 0.75, v210_, 1 * g_pixelSizeY)
			if self:getTextLayoutMode() == TextElement.LAYOUT_MODE.SCROLLING and self.scrollingMaxOffset > 0 then
				local v212_ = self.scrollingClipArea[3] - self.scrollingClipArea[1]
				local v213_ = self.scrollingClipArea[4] - self.scrollingClipArea[2]
				drawOutlineRect(self.scrollingClipArea[1], self.scrollingClipArea[2], v212_, v213_, 2 * g_pixelSizeX, 2 * g_pixelSizeY, 0, 0, 1, 1)
			end
		end
	end
	TextElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

-- Local values: currentTextLayoutMode
function TextElement:updateScrollingLayoutMode()
	local v215_ = self:getTextLayoutMode()
	if self.lastTextLayoutMode ~= v215_ then
		self:setText(self.sourceText, nil, nil, true)
		self.lastTextLayoutMode = v215_
	end
end

-- Local values: width
function TextElement:updateScaledWidth(xScale)
	if self.text ~= nil and (self.text ~= "" and (self.absSize[1] == 0 and self.absSize[2] == 0)) then
		self:setSize(self:getTextWidth() / xScale, self.textSize)
	end
end

-- Local values: width, height, textHeight, numLines, offset, textSize, textWidth
function TextElement:updateSize(forceTextSize)
	local v220_ = nil
	local v221_, _ = self:getTextHeight()
	local v222_
	if self.textAutoWidth and forceTextSize ~= true then
		local v223_ = self:getTextOffset()
		local v224_ = self.textSize
		setTextBold(self.textBold)
		local v225_ = getTextWidth(v224_, self.sourceText)
		setTextBold(false)
		if self.textMaxWidth ~= nil then
			local v226_ = self.textMaxWidth
			v225_ = math.min(v226_, v225_)
		end
		if self.textMinWidth ~= nil then
			local v227_ = self.textMinWidth
			v225_ = math.max(v227_, v225_)
		end
		v222_ = v223_ + v225_
		if v222_ ~= self.size[1] and self.size[2] == 0 then
			v220_ = self.textSize
		end
	else
		v222_ = nil
	end
	if self.textAutoHeight then
		if forceTextSize == true then
			v221_ = v220_
		end
	else
		v221_ = v220_
	end
	if v222_ ~= nil or v221_ ~= nil then
		self:setSize(v222_, v221_)
		if self.parent ~= nil and (self.parent.invalidateLayout ~= nil and self.parent.autoValidateLayout) then
			self.parent:invalidateLayout()
		end
	end
	if self.textLayoutMode == TextElement.LAYOUT_MODE.FILL then
		local v228_ = self.absSize[2] / (self.textSize * self.textLineHeightScale)
		self.textMaxNumLines = math.floor(v228_)
	end
end
