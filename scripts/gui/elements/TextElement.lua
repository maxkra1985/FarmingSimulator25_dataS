TextElement = {}
local TextElement_mt = Class(TextElement, GuiElement)
Gui.registerGuiElement("Text", TextElement)
TextElement.VERTICAL_ALIGNMENT = { TOP = "top", MIDDLE = "middle", BOTTOM = "bottom" }
TextElement.FORMAT = { NONE = 1, TEMPERATURE = 2, CURRENCY = 3, ACCOUNTING = 4, NUMBER = 5, PERCENTAGE = 6 }
TextElement.LAYOUT_MODE = { TRUNCATE = 1, RESIZE = 2, OVERFLOW = 3, CLIP = 4, SCROLLING = 5, FILL = 6 }
TextElement.REGEX_LAST_CHARACTER_ALLOWS_BREAK = "[%s%p\227\128\130]$"
TextElement.REGEX_BREAKING_CHARAKTERS_BEFORE = "[%s]$"
TextElement.REGEX_BREAKING_CHARAKTERS_AFTER = "[%p\227\128\130]$"
function TextElement.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or TextElement_mt)
	self.textColor = { 1, 1, 1, 1 }
	self.textDisabledColor = nil
	self.textSelectedColor = nil
	self.textFocusedColor = nil
	self.textHighlightedColor = nil
	self.textFocusedSelectedColor = nil
	self.textHighlightedSelectedColor = nil
	self.textOffset = { 0, 0 }
	self.textSize = 0.03
	self.textBold = false
	self.textSelectedBold = false
	self.textFocusedBold = false
	self.textHighlightedBold = false
	self.text2Color = { 1, 1, 1, 1 }
	self.text2DisabledColor = nil
	self.text2SelectedColor = nil
	self.text2FocusedColor = nil
	self.text2HighlightedColor = nil
	self.text2Offset = { 0, 0 }
	self.text2FocusedOffset = { 0, 0 }
	self.text2Size = 0
	self.text2Bold = false
	self.text2SelectedBold = false
	self.text2HighlightedBold = false
	self.textUpperCase = false
	self.textLinesPerPage = 0
	self.currentPage = 1
	self.defaultTextSize = self.textSize
	self.defaultText2Size = self.text2Size
	self.textLineHeightScale = RenderText.DEFAULT_LINE_HEIGHT_SCALE
	self.text = ""
	self.textAlignment = RenderText.ALIGN_CENTER
	self.textOriginalAlignment = RenderText.ALIGN_CENTER
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT.MIDDLE
	self.ignoreDisabled = false
	self.firstLineIndentation = nil
	self.format = TextElement.FORMAT.NONE
	self.locaKey = nil
	self.value = nil
	self.formatDecimalPlaces = 0
	self.textMaxWidth = nil
	self.textMinWidth = 0
	self.textMaxNumLines = 1
	self.textAutoWidth = false
	self.textAutoHeight = false
	self.textLayoutMode = TextElement.LAYOUT_MODE.TRUNCATE
	self.textScrollOnFocusOnly = true
	self.textMinSize = 0.01
	self.sourceText = ""
	self.scrollingStartPos = 0
	self.scrollingOffset = 0
	self.scrollingMaxOffset = 0
	self.scrollingClipArea = nil
	self.scrollTime = 0
	self.updatedTextLayoutMode = false
	return self
end
function TextElement:loadFromXML(xmlFile, key)
	local xmlFilename = getXMLFilename(xmlFile)
	local modName, _ = Utils.getModNameAndBaseDirectory(xmlFilename)
	if modName ~= nil then
		self.customEnvironment = modName
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
	local textAlignment = getXMLString(xmlFile, key .. "#textAlignment")
	if textAlignment ~= nil then
		textAlignment = string.lower(textAlignment)
		if textAlignment == "right" then
			self.textAlignment = RenderText.ALIGN_RIGHT
		elseif textAlignment == "center" then
			self.textAlignment = RenderText.ALIGN_CENTER
		else
			self.textAlignment = RenderText.ALIGN_LEFT
		end
		self.textOriginalAlignment = self.textAlignment
	end
	local wrapModeKey = getXMLString(xmlFile, key .. "#textLayoutMode")
	if wrapModeKey ~= nil then
		wrapModeKey = string.lower(wrapModeKey)
		if wrapModeKey == "truncate" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.TRUNCATE
		elseif wrapModeKey == "resize" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.RESIZE
		elseif wrapModeKey == "overflow" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.OVERFLOW
		elseif wrapModeKey == "scrolling" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.SCROLLING
			self.textMaxNumLines = 1
		elseif wrapModeKey == "fill" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.FILL
		end
	end
	self.textScrollOnFocusOnly = Utils.getNoNil(getXMLBool(xmlFile, key .. "#textScrollOnFocusOnly"), self.textScrollOnFocusOnly)
	local textVerticalAlignment = getXMLString(xmlFile, key .. "#textVerticalAlignment") or ""
	local verticalAlignKey = string.upper(textVerticalAlignment)
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT[verticalAlignKey] or self.textVerticalAlignment
	self.ignoreDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreDisabled"), self.ignoreDisabled)
	local text = getXMLString(xmlFile, key .. "#text")
	if text ~= nil then
		if text ~= "" and string.startsWith(text, "$l10n_") then
			local hasColon = string.endsWith(text, ":")
			if hasColon then
				text = utf8Substr(text, 0, utf8Strlen(text) - 1)
			end
			text = g_i18n:getText(text:sub(7), self.customEnvironment)
			if hasColon then
				text = text .. ":"
			end
		end
		self.sourceText = text
		if self.format == TextElement.FORMAT.NONE then
			self:setText(text, false, true)
		end
	end
	self.formatDecimalPlaces = math.max(getXMLInt(xmlFile, key .. "#formatDecimalPlaces") or self.formatDecimalPlaces, 0)
	local format = getXMLString(xmlFile, key .. "#format")
	if format ~= nil then
		format = string.lower(format)
		local f = TextElement.FORMAT.NONE
		if format == "currency" then
			f = TextElement.FORMAT.CURRENCY
		elseif format == "accounting" then
			f = TextElement.FORMAT.ACCOUNTING
		elseif format == "temperature" then
			f = TextElement.FORMAT.TEMPERATURE
		elseif format == "number" then
			f = TextElement.FORMAT.NUMBER
		elseif format == "percentage" then
			f = TextElement.FORMAT.PERCENTAGE
		elseif format == "none" then
			f = TextElement.FORMAT.NONE
		end
		self:setFormat(f)
	end
	self:addCallback(xmlFile, key .. "#onTextChanged", "onTextChangedCallback")
	self:updateSize()
end
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
	local textAlignment = profile:getValue("textAlignment")
	if textAlignment ~= nil then
		textAlignment = string.lower(textAlignment)
		if textAlignment == "right" then
			self.textAlignment = RenderText.ALIGN_RIGHT
		elseif textAlignment == "center" then
			self.textAlignment = RenderText.ALIGN_CENTER
		else
			self.textAlignment = RenderText.ALIGN_LEFT
		end
		self.textOriginalAlignment = self.textAlignment
	end
	local wrapModeKey = profile:getValue("textLayoutMode")
	if wrapModeKey ~= nil then
		wrapModeKey = string.lower(wrapModeKey)
		if wrapModeKey == "truncate" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.TRUNCATE
		elseif wrapModeKey == "resize" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.RESIZE
		elseif wrapModeKey == "overflow" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.OVERFLOW
		elseif wrapModeKey == "scrolling" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.SCROLLING
			self.textMaxNumLines = 1
		elseif wrapModeKey == "fill" then
			self.textLayoutMode = TextElement.LAYOUT_MODE.FILL
		end
	end
	self.textScrollOnFocusOnly = profile:getBool("textScrollOnFocusOnly", self.textScrollOnFocusOnly)
	local textVerticalAlignment = profile:getValue("textVerticalAlignment", "")
	local verticalAlignKey = string.upper(textVerticalAlignment)
	self.textVerticalAlignment = TextElement.VERTICAL_ALIGNMENT[verticalAlignKey] or self.textVerticalAlignment
	self.formatDecimalPlaces = math.max(profile:getNumber("formatDecimalPlaces", self.formatDecimalPlaces), 0)
	local format = profile:getValue("format")
	if format ~= nil then
		format = string.lower(format)
		local f = TextElement.FORMAT.NONE
		if format == "currency" then
			f = TextElement.FORMAT.CURRENCY
		elseif format == "accounting" then
			f = TextElement.FORMAT.ACCOUNTING
		elseif format == "temperature" then
			f = TextElement.FORMAT.TEMPERATURE
		elseif format == "number" then
			f = TextElement.FORMAT.NUMBER
		elseif format == "percentage" then
			f = TextElement.FORMAT.PERCENTAGE
		elseif format == "none" then
			f = TextElement.FORMAT.NONE
		end
		self:setFormat(f)
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
function TextElement:updateAbsolutePosition()
	TextElement:superClass().updateAbsolutePosition(self)
	local textLayoutMode = self:getTextLayoutMode()
	if (self.textMaxNumLines ~= 1 or textLayoutMode ~= TextElement.LAYOUT_MODE.OVERFLOW and textLayoutMode ~= TextElement.LAYOUT_MODE.SCROLLING) and (not self.textAutoWidth and not self.textAutoHeight) then
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
function TextElement:setTextInternal(text, forceTextSize, skipCallback, doNotUpdateSize)
	if text == nil then
		text = ""
	end
	setTextWidthScale(g_textWidthScale)
	text = tostring(text)
	if self.textUpperCase then
		text = utf8ToUpper(text)
	end
	local textHasChanged = self.sourceText ~= text
	self.sourceText = text
	self.textSize = self.defaultTextSize
	self.text2Size = self.defaultText2Size
	self:updateSize()
	local maxWidth = self.absSize[1]
	if self.textMaxWidth ~= nil then
		maxWidth = self.textMaxWidth
	elseif self.textAutoWidth then
		maxWidth = 1
	end
	local limitVerticalLines = false
	local textLayoutMode = self:getTextLayoutMode()
	setTextBold(self.textBold)
	if textLayoutMode == TextElement.LAYOUT_MODE.RESIZE then
		local textMaxNumLines = self.textMaxNumLines
		if text:find("[ -]") == nil then
			textMaxNumLines = 1
		end
		if 1 < textMaxNumLines then
			setTextWrapWidth(maxWidth, false)
			local lengthWithNoLineLimit = getTextLength(self.textSize, text, 99999)
			while getTextLength(self.textSize, text, textMaxNumLines) < lengthWithNoLineLimit do
				self.textSize = self.textSize - self.defaultTextSize * 0.05
				self.text2Size = self.text2Size - self.defaultText2Size * 0.05
				if self.textSize <= self.textMinSize then
					self.textSize = self.textSize + self.defaultTextSize * 0.05
					self.text2Size = self.text2Size + self.defaultText2Size * 0.05
					if textMaxNumLines == 1 then
						text = Utils.limitTextToWidth(text, self.textSize, maxWidth, false, "...")
						break
					end
					limitVerticalLines = true
					break
				end
			end
		else
			while maxWidth < getTextWidth(self.textSize, text) do
				self.textSize = self.textSize - self.defaultTextSize * 0.05
				self.text2Size = self.text2Size - self.defaultText2Size * 0.05
				if self.textSize <= self.textMinSize then
					self.textSize = self.textSize + self.defaultTextSize * 0.05
					self.text2Size = self.text2Size + self.defaultText2Size * 0.05
					text = Utils.limitTextToWidth(text, self.textSize, maxWidth, false, "...")
					break
				end
			end
		end
		setTextWrapWidth(0)
	elseif textLayoutMode ~= TextElement.LAYOUT_MODE.OVERFLOW then
		if textLayoutMode ~= TextElement.LAYOUT_MODE.SCROLLING and (textLayoutMode == TextElement.LAYOUT_MODE.TRUNCATE or textLayoutMode == TextElement.LAYOUT_MODE.FILL) and self.textMaxNumLines == 1 then
			if textLayoutMode == TextElement.LAYOUT_MODE.TRUNCATE then
				text = Utils.limitTextToWidth(text, self.textSize, maxWidth, false, "...")
			else
				limitVerticalLines = true
			end
		end
	end
	if limitVerticalLines then
		setTextWrapWidth(maxWidth)
		local _, numLines = getTextHeight(self.textSize, text)
		if self.textMaxNumLines < numLines then
			local lastCharAllowsBreak = nil
			while true do
				_, numLines = getTextHeight(self.textSize, text)
				if self.textMaxNumLines >= numLines then
					break
				end
				lastCharAllowsBreak = string.match(text, TextElement.REGEX_LAST_CHARACTER_ALLOWS_BREAK)
				text = utf8Substr(text, 0, utf8Strlen(text) - 1)
			end
			if textLayoutMode == TextElement.LAYOUT_MODE.TRUNCATE then
				text = utf8Substr(text, 0, math.max(utf8Strlen(text) - 3, 0)) .. "..."
			elseif self.textLayoutMode == TextElement.LAYOUT_MODE.FILL then
				if lastCharAllowsBreak == nil then
					while 0 < utf8Strlen(text) do
						local needsBreak = string.match(text, TextElement.REGEX_LAST_CHARACTER_ALLOWS_BREAK)
						if needsBreak then
							local breakOffset = string.match(text, TextElement.REGEX_BREAKING_CHARAKTERS_AFTER) ~= nil and 0 or -1
							text = utf8Substr(text, 0, utf8Strlen(text) + breakOffset)
							if not needsBreak then
								continue
							end
							setTextWrapWidth(0)
							setTextBold(false)
							self.text = text
							if textHasChanged and not skipCallback then
								self:raiseCallback("onTextChangedCallback", self, self.text)
								self:updateScaledWidth(1, 1)
							end
							self:updateSize(forceTextSize)
							return textHasChanged
						end
					end
				end
			end
		end
	end
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
function TextElement:updateFormattedText()
	local text = ""
	local value = self.value
	if value ~= nil then
		local format = self.format
		local decimalPlaces = self.formatDecimalPlaces
		if format == TextElement.FORMAT.NONE then
			text = tostring(value)
		elseif format == TextElement.FORMAT.NUMBER then
			text = g_i18n:formatNumber(value, decimalPlaces)
		elseif format == TextElement.FORMAT.CURRENCY then
			text = g_i18n:formatMoney(value, decimalPlaces, true, true)
		elseif format == TextElement.FORMAT.ACCOUNTING then
			text = g_i18n:formatMoney(value, decimalPlaces, true, false)
		elseif format == TextElement.FORMAT.TEMPERATURE then
			text = g_i18n:formatTemperature(value, decimalPlaces)
		elseif format == TextElement.FORMAT.PERCENTAGE then
			text = g_i18n:formatNumber(value * 100, decimalPlaces) .. "%"
		end
	elseif self.locaKey ~= nil then
		local length = self.locaKey:len()
		if self.locaKey:sub(length, length + 1) == ":" then
			text = g_i18n:getText(self.locaKey:sub(1, length - 1), self.customEnvironment) .. ":"
		else
			text = g_i18n:getText(self.locaKey, self.customEnvironment)
		end
	end
	self:setTextInternal(text)
end
function TextElement:updateScrollingParameters()
	if self.textLayoutMode == TextElement.LAYOUT_MODE.SCROLLING then
		self:setAbsolutePosition(self.scrollingStartPos)
		self.scrollingOffset = 0
		self.scrollingMaxOffset = math.max(0, self:getTextWidth(true) - self.absSize[1])
		self.scrollingClipArea = self.scrollingClipArea or {}
		self.scrollingClipArea[1] = self.scrollingStartPos
		self.scrollingClipArea[2] = self.absPosition[2]
		self.scrollingClipArea[3] = self.scrollingStartPos + self.absSize[1]
		self.scrollingClipArea[4] = self.absPosition[2] + self.absSize[2]
		if 0 < self.scrollingMaxOffset then
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
	self.textColor = { r, g, b, a }
end
function TextElement:setTextSelectedColor(r, g, b, a)
	self.textSelectedColor = { r, g, b, a }
end
function TextElement:setTextFocusedColor(r, g, b, a)
	self.textFocusedColor = { r, g, b, a }
end
function TextElement:setTextFocusedSelectedColor(r, g, b, a)
	self.textFocusedSelectedColor = { r, g, b, a }
end
function TextElement:setTextHighlightedSelectedColor(r, g, b, a)
	self.textHighlightedSelectedColor = { r, g, b, a }
end
function TextElement:setTextHighlightedColor(r, g, b, a)
	self.textHighlightedColor = { r, g, b, a }
end
function TextElement:getTextColor()
	local retColor = self.textColor
	if self.disabled then
		if not self.ignoreDisabled then
			retColor = self.textDisabledColor
		elseif self:getIsSelected() then
			if self:getIsFocused() then
				retColor = self.textFocusedSelectedColor or self.textSelectedColor
			elseif self:getIsHighlighted() then
				retColor = self.textHighlightedSelectedColor or self.textSelectedColor
			else
				retColor = self.textSelectedColor
			end
		elseif self:getIsFocused() then
			retColor = self.textFocusedColor
		elseif self:getIsHighlighted() then
			retColor = self.textHighlightedColor
		end
	end
	if retColor == nil then
		retColor = self.textColor
	end
	return retColor
end
function TextElement:setText2Color(r, g, b, a)
	self.text2Color = { r, g, b, a }
end
function TextElement:setText2SelectedColor(r, g, b, a)
	self.text2SelectedColor = { r, g, b, a }
end
function TextElement:setText2FocusedColor(r, g, b, a)
	self.text2FocusedColor = { r, g, b, a }
end
function TextElement:setText2HighlightedColor(r, g, b, a)
	self.text2HighlightedColor = { r, g, b, a }
end
function TextElement:getText2Color()
	if self.disabled and not self.ignoreDisabled then
		return self.text2DisabledColor
	end
	if self:getIsSelected() then
		return self.text2SelectedColor
	elseif self:getIsFocused() then
		return self.text2FocusedColor
	elseif self:getIsHighlighted() then
		return self.text2HighlightedColor
	else
		return self.text2Color
	end
end
function TextElement:getTextWidth(useSourceText)
	setTextBold(self.textBold)
	local width = getTextWidth(self.textSize, self.text)
	if useSourceText then
		width = getTextWidth(self.textSize, self.sourceText)
	end
	setTextBold(false)
	if self:getTextLayoutMode() ~= TextElement.LAYOUT_MODE.OVERFLOW and (self.textLayoutMode ~= TextElement.LAYOUT_MODE.SCROLLING and not self.textAutoWidth) then
		width = math.min(width, self.absSize[1])
	end
	return width
end
function TextElement:getTextHeight(includeNegativeSpacing)
	if 1 < self.textMaxNumLines then
		if self.textMaxWidth ~= nil then
			setTextWrapWidth(self.textMaxWidth)
		else
			setTextWrapWidth(self.absSize[1])
		end
	end
	setTextBold(self.textBold)
	setTextFirstLineIndentation(self.firstLineIndentation or 0)
	setTextLineHeightScale(self.textLineHeightScale)
	local height, numLines = getTextHeight(self.textSize, self.text)
	if includeNegativeSpacing == true and 0 < numLines then
		height = height + height / numLines * 0.1
	end
	setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
	setTextFirstLineIndentation(0)
	setTextBold(false)
	setTextWrapWidth(0)
	return height, numLines
end
function TextElement:getTextOffset()
	local state = self:getOverlayState()
	local xOffset = self.textOffset[1]
	local yOffset = self.textOffset[2]
	if state == GuiOverlay.STATE_FOCUSED and self.textFocusedOffset ~= nil then
		xOffset = self.textFocusedOffset[1]
		yOffset = self.textFocusedOffset[2]
		return xOffset, yOffset
	end
	if state == GuiOverlay.STATE_SELECTED and self.textSelectedOffset ~= nil then
		xOffset = self.textSelectedOffset[1]
		yOffset = self.textSelectedOffset[2]
		return xOffset, yOffset
	end
	if state == GuiOverlay.STATE_HIGHLIGHTED and self.textHighlightedOffset ~= nil then
		xOffset = self.textHighlightedOffset[1]
		yOffset = self.textHighlightedOffset[2]
		return xOffset, yOffset
	end
	if state == GuiOverlay.STATE_PRESSED and self.textPressedOffset ~= nil then
		xOffset = self.textPressedOffset[1]
		yOffset = self.textPressedOffset[2]
	end
	return xOffset, yOffset
end
function TextElement:getText2Offset()
	local xOffset = self.text2Offset[1]
	local yOffset = self.text2Offset[2]
	local state = self:getOverlayState()
	if state == GuiOverlay.STATE_FOCUSED or state == GuiOverlay.STATE_PRESSED or state == GuiOverlay.STATE_SELECTED or state == GuiOverlay.STATE_HIGHLIGHTED then
		xOffset = self.text2FocusedOffset[1]
		yOffset = self.text2FocusedOffset[2]
	end
	return xOffset, yOffset
end
function TextElement:getIsScrollingAllowed()
	return not self.textScrollOnFocusOnly or self:getIsFocused() or self:getIsHighlighted() or self:getIsSelected()
end
function TextElement:getTextLayoutMode()
	if self.textLayoutMode == TextElement.LAYOUT_MODE.SCROLLING and not self:getIsScrollingAllowed() then
		return TextElement.LAYOUT_MODE.TRUNCATE
	end
	return self.textLayoutMode
end
function TextElement:getDoRenderText()
	return true
end
function TextElement:getTextPositionX()
	local xPos = self.absPosition[1]
	if self.textAlignment == RenderText.ALIGN_CENTER then
		xPos = xPos + self.absSize[1] * 0.5
		return xPos
	else
		if self.textAlignment == RenderText.ALIGN_RIGHT then
			xPos = xPos + self.absSize[1]
		end
		return xPos
	end
end
function TextElement:getTextPositionY(lineHeight, totalHeight)
	local yPos = self.absPosition[2]
	if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.TOP then
		yPos = yPos + self.absSize[2] - lineHeight
		return yPos
	elseif self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.MIDDLE then
		yPos = yPos + (self.absSize[2] + totalHeight) * 0.5 - lineHeight
		return yPos
	else
		yPos = yPos + totalHeight - lineHeight
		return yPos
	end
end
function TextElement:getTextPosition(text)
	local lineHeight = getTextHeight(self.textSize, utf8ToUpper(utf8Substr(text, 0, 1) or ""))
	local totalHeight = getTextHeight(self.textSize, text)
	local xPos = self:getTextPositionX()
	local yPos = self:getTextPositionY(lineHeight, totalHeight)
	return xPos, yPos
end
function TextElement:update(dt)
	TextElement:superClass().update(self, dt)
	if self.textLayoutMode == TextElement.LAYOUT_MODE.SCROLLING then
		local currentTextLayoutMode = self:getTextLayoutMode()
		self:updateScrollingLayoutMode()
		if currentTextLayoutMode == TextElement.LAYOUT_MODE.SCROLLING then
			if 0 < self.scrollingMaxOffset then
				local scrollLengthFactor = self.scrollingMaxOffset / self.absSize[1]
				local scrollDuration = 9000 * ((scrollLengthFactor - 1) * 0.5 + 1)
				self.scrollTime = self.scrollTime + dt
				if scrollDuration <= self.scrollTime then
					self.scrollTime = -scrollDuration
				end
				local alpha = MathUtil.smoothstep(0.2, 0.8, math.abs(self.scrollTime) / scrollDuration)
				self.scrollingOffset = self.scrollingMaxOffset * alpha
			end
			if self.absPosition[1] ~= self.scrollingStartPos - self.scrollingOffset then
				self.ignoreStartPositionUpdate = true
				self:setAbsolutePosition(self.scrollingStartPos - self.scrollingOffset, nil)
				self.ignoreStartPositionUpdate = false
			end
		end
	end
end
function TextElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self:getDoRenderText() and (self.text ~= nil and self.text ~= "") then
		local xOffset, yOffset = self:getTextOffset()
		if self:getTextLayoutMode() == TextElement.LAYOUT_MODE.SCROLLING and 0 < self.scrollingMaxOffset then
			clipX1 = math.max(self.scrollingClipArea[1] + xOffset, clipX1 or 0)
			clipY1 = math.max(self.scrollingClipArea[2] + yOffset, clipY1 or 0)
			clipX2 = math.min(self.scrollingClipArea[3] + xOffset, clipX2 or math.huge)
			clipY2 = math.min(self.scrollingClipArea[4] + yOffset, clipY2 or math.huge)
		end
		if clipX1 ~= nil then
			setTextClipArea(clipX1, clipY1, clipX2, clipY2)
		end
		setTextAlignment(self.textAlignment)
		local maxWidth = self.absSize[1]
		if self.textMaxWidth ~= nil then
			maxWidth = self.textMaxWidth
		elseif self.textAutoWidth then
			maxWidth = 1
		end
		if 1 < self.textMaxNumLines then
			setTextWrapWidth(maxWidth)
		end
		setTextFirstLineIndentation(self.firstLineIndentation or 0)
		setTextLineBounds((self.currentPage - 1) * self.textLinesPerPage, self.textLinesPerPage)
		setTextLineHeightScale(self.textLineHeightScale)
		local text = self.text
		if not self.textBold and ((not self.textSelectedBold or not self:getIsSelected()) and (not self.textHighlightedBold or not self:getIsHighlighted())) then
			local bold = self.textFocusedBold and self:getIsFocused()
		end
		setTextBold(bold)
		local xPos, yPos = self:getTextPosition(text)
		local baselineOffset = self.textSize * 0.1
		yPos = yPos + baselineOffset
		if 0 < self.text2Size then
			local x2Offset, y2Offset = self:getText2Offset()
			local _v62 = self.text2Bold
			if not _v62 and (not self.text2SelectedBold or not self:getIsSelected()) then
				self:getIsHighlighted()
			end
			bold = _v62
			setTextBold(bold)
			local r, g, b, a = unpack(self:getText2Color())
			setTextColor(r, g, b, a * self.alpha)
			renderText(xPos + x2Offset, yPos + y2Offset, self.text2Size, text)
		end
		local r, g, b, a = unpack(self:getTextColor())
		setTextColor(r, g, b, a * self.alpha)
		renderText(xPos + xOffset, yPos + yOffset, self.textSize, text)
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
			local x = xPos + xOffset
			if self.textAlignment == RenderText.ALIGN_RIGHT then
				x = x - maxWidth
			elseif self.textAlignment == RenderText.ALIGN_CENTER then
				x = x - maxWidth / 2
			end
			renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset, maxWidth, g_pixelSizeY * 2)
			local width = self:getTextWidth()
			x = xPos + xOffset
			if self.textAlignment == RenderText.ALIGN_RIGHT then
				x = x - width
			elseif self.textAlignment == RenderText.ALIGN_CENTER then
				x = x - width * 0.5
			end
			setOverlayColor(GuiElement.debugOverlay, 0, 1, 0, 1)
			renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset, width, 1 * g_pixelSizeY)
			setOverlayColor(GuiElement.debugOverlay, 1, 0.5, 0, 1)
			renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset + getTextHeight(self.textSize, text) * 0.5, width, 1 * g_pixelSizeY)
			setOverlayColor(GuiElement.debugOverlay, 0, 0, 1, 1)
			renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset + getTextHeight(self.textSize, text) * 0.75, width, 1 * g_pixelSizeY)
			if self:getTextLayoutMode() == TextElement.LAYOUT_MODE.SCROLLING and 0 < self.scrollingMaxOffset then
				local debugWidth = self.scrollingClipArea[3] - self.scrollingClipArea[1]
				local debugHeight = self.scrollingClipArea[4] - self.scrollingClipArea[2]
				drawOutlineRect(self.scrollingClipArea[1], self.scrollingClipArea[2], debugWidth, debugHeight, 2 * g_pixelSizeX, 2 * g_pixelSizeY, 0, 0, 1, 1)
			end
		end
	end
	TextElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
function TextElement:updateScrollingLayoutMode()
	local currentTextLayoutMode = self:getTextLayoutMode()
	if self.lastTextLayoutMode ~= currentTextLayoutMode then
		self:setText(self.sourceText, nil, nil, true)
		self.lastTextLayoutMode = currentTextLayoutMode
	end
end
function TextElement:updateScaledWidth(xScale)
	if self.text ~= nil and (self.text ~= "" and (self.absSize[1] == 0 and self.absSize[2] == 0)) then
		local width = self:getTextWidth()
		self:setSize(width / xScale, self.textSize)
	end
end
function TextElement:updateSize(forceTextSize)
	local width = nil
	local height = nil
	local textHeight, numLines = self:getTextHeight()
	if self.textAutoWidth and forceTextSize ~= true then
		local offset = self:getTextOffset()
		local textSize = self.textSize
		setTextBold(self.textBold)
		local textWidth = getTextWidth(textSize, self.sourceText)
		setTextBold(false)
		if self.textMaxWidth ~= nil then
			textWidth = math.min(self.textMaxWidth, textWidth)
		end
		if self.textMinWidth ~= nil then
			textWidth = math.max(self.textMinWidth, textWidth)
		end
		width = offset + textWidth
		if width ~= self.size[1] and self.size[2] == 0 then
			height = self.textSize
		end
	end
	if self.textAutoHeight and forceTextSize ~= true then
		height = textHeight
	end
	if width ~= nil or height ~= nil then
		self:setSize(width, height)
		if self.parent ~= nil and (self.parent.invalidateLayout ~= nil and self.parent.autoValidateLayout) then
			self.parent:invalidateLayout()
		end
	end
	if self.textLayoutMode == TextElement.LAYOUT_MODE.FILL then
		self.textMaxNumLines = math.floor(self.absSize[2] / (self.textSize * self.textLineHeightScale))
	end
end
