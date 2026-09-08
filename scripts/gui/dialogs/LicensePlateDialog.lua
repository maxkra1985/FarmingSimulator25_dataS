-- Local values: LicensePlateDialog_mt
LicensePlateDialog = {}
local LicensePlateDialog_mt = Class(LicensePlateDialog, InfoDialog)
function LicensePlateDialog.register()
	local v2_ = LicensePlateDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/LicensePlateDialog.xml", "LicensePlateDialog", v2_)
	LicensePlateDialog.INSTANCE = v2_
end

-- Local values: dialog
function LicensePlateDialog.show(licensePlateData, callback, target)
	if LicensePlateDialog.INSTANCE ~= nil then
		local v6_ = LicensePlateDialog.INSTANCE
		v6_:setLicensePlateData(licensePlateData)
		v6_:setCallback(callback, target)
		g_gui:showDialog("LicensePlateDialog")
	end
end

-- Upvalues: LicensePlateDialog_mt
-- Local values: self
function LicensePlateDialog.new(target, custom_mt)
	-- upvalues: (copy) LicensePlateDialog_mt
	local v9_ = InfoDialog.new(target, custom_mt or LicensePlateDialog_mt)
	v9_.currentVariation = 1
	v9_.currentColorIndex = 1
	return v9_
end

-- Local values: licensePlateData, callback, target
function LicensePlateDialog.createFromExistingGui(gui, guiName)
	LicensePlateDialog.register()
	local v11_ = gui.licensePlateData
	local v12_ = gui.callbackFunc
	local v13_ = gui.target
	LicensePlateDialog.show(v11_, v12_, v13_)
end

function LicensePlateDialog:delete()
	if self.keyboardButtonTemplate ~= nil then
		self.keyboardButtonTemplate:delete()
	end
	if self.licensePlate ~= nil then
		delete(self.licensePlate.node)
		self.self.licensePlate = nil
	end
	LicensePlateDialog:superClass().delete(self)
end

function LicensePlateDialog:onCreate()
	LicensePlateDialog:superClass().onCreate(self)
	self.keyboardButtonTemplate:unlinkElement()
	FocusManager:removeElement(self.keyboardButtonTemplate)
end

-- Local values: lineSize
function LicensePlateDialog:onGuiSetupFinished()
	LicensePlateDialog:superClass().onGuiSetupFinished(self)
	local v17_ = (self.contentContainer.absSize[1] - self.headerText:getTextWidth()) / 2 - 20 * g_pixelSizeScaledX
	self.topLineLeft:setSize(v17_, nil)
	self.topLineRight:setSize(v17_, nil)
end

function LicensePlateDialog:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self.sceneRender:createScene()
end

function LicensePlateDialog:unloadMapData()
	self.sceneRender:destroyScene()
end

-- Local values: colors, _
function LicensePlateDialog:onOpen()
	LicensePlateDialog:superClass().onOpen(self)
	self.needsFirstFocusUpdate = true
	local v21_, _ = g_licensePlateManager:getAvailableColors()
	self.changeColorButton.parent:setVisible(#v21_ > 1)
	self.currentCursorPosition = 1
	self.cursorPositions = {}
	self.sceneRender:setVisible(true)
	self:createKeyboards()
	self:updateLicensePlate()
end

function LicensePlateDialog:onClose()
	LicensePlateDialog:superClass().onClose(self)
	self.sceneRender:setVisible(false)
	if self.licensePlate ~= nil then
		self.licensePlate:delete()
		self.licensePlate = nil
	end
end

-- Local values: _, defaultColorIndex, i
function LicensePlateDialog:setLicensePlateData(licensePlateData)
	self.currentVariation = licensePlateData.variation or self.currentVariation
	self.currentCharacters = table.clone(licensePlateData.characters, 5)
	local _, v25_ = g_licensePlateManager:getAvailableColors()
	self.currentColorIndex = licensePlateData.colorIndex or (v25_ or self.currentColorIndex)
	self:updateColorButton()
	self.currentPlacementIndex = licensePlateData.placementIndex or (licensePlateData.defaultPlacementIndex or g_licensePlateManager:getDefaultPlacementIndex())
	if licensePlateData.hasFrontPlate == false then
		self:updatePlacementOptions(LicensePlateManager.PLACEMENT_OPTION.BOTH)
		if self.currentPlacementIndex == LicensePlateManager.PLACEMENT_OPTION.BOTH then
			self.currentPlacementIndex = LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY
		end
	else
		self:updatePlacementOptions()
	end
	for v26_ = 1, #self.textToPlacementIndex do
		if self.textToPlacementIndex[v26_] == self.currentPlacementIndex then
			self.placementOption:setState(v26_)
		end
	end
	self.licensePlateData = licensePlateData
end

function LicensePlateDialog:setCallback(callbackFunction, target, args)
	self.callbackFunction = callbackFunction
	self.target = target
	self.args = args
end

-- Local values: licensePlateData
function LicensePlateDialog:sendCallback(variation, characters, colorIndex, placementIndex)
	local v36_
	if variation == nil or (characters == nil or (colorIndex == nil or placementIndex == nil)) then
		v36_ = nil
	else
		v36_ = {
			["variation"] = variation,
			["characters"] = characters,
			["colorIndex"] = colorIndex,
			["placementIndex"] = placementIndex
		}
	end
	if self.callbackFunction ~= nil then
		if self.target ~= nil then
			self.callbackFunction(self.target, v36_, self.args)
			return
		end
		self.callbackFunction(v36_, self.args)
	end
end

-- Local values: font, updateButtons
function LicensePlateDialog:createKeyboards()
	local v_u_38_ = g_licensePlateManager:getFont()
	local function v46_(p39_, p40_)
		-- upvalues: (copy) v_u_38_, (copy) self
		for v41_ = #p40_.elements, 1, -1 do
			p40_.elements[v41_]:delete()
		end
		local v42_ = v_u_38_.charactersByType[p39_]
		for v43_ = 1, #v42_ do
			local v44_ = self.keyboardButtonTemplate:clone(p40_)
			local v45_ = v42_[v43_]
			v44_.keyboardValue = v45_.value
			v44_:setText(v45_.value)
		end
		p40_:invalidateLayout()
	end
	v46_(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL, self.keyboardAlpha)
	v46_(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL, self.keyboardNumeric)
	v46_(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL, self.keyboardSpecial)
	self:updateFocusLinking(false, false, false)
end

-- Local values: firstAvailableButton, lastAvailableButton, numCols, above, i, button, leftButton, rightButton, topButton, bottomButton, below, i, button, leftButton, rightButton, topButton, index, bottomButton, i, button, leftButton, rightButton, topButton, index
function LicensePlateDialog:updateFocusLinking(alphabetical, numerical, special)
	local v51_ = nil
	FocusManager:linkElements(self.buttonCursorLeft, FocusManager.RIGHT, self.buttonCursorRight)
	FocusManager:linkElements(self.buttonCursorLeft, FocusManager.LEFT, self.buttonCursorLeft)
	FocusManager:linkElements(self.buttonCursorRight, FocusManager.RIGHT, self.buttonCursorRight)
	FocusManager:linkElements(self.buttonCursorRight, FocusManager.LEFT, self.buttonCursorLeft)
	local v52_
	if alphabetical then
		v51_ = v51_ or self.keyboardAlpha.elements[1]
		local v53_ = self.keyboardAlpha.elements
		local v54_ = (#self.keyboardAlpha.elements - 1) / 10
		v52_ = v53_[math.floor(v54_) * 10 + 1]
		for v55_ = 1, #self.keyboardAlpha.elements do
			local v56_ = self.keyboardAlpha.elements[v55_]
			local v57_ = self.keyboardAlpha.elements[v55_ - 1]
			local v58_ = self.keyboardAlpha.elements[v55_ + 1]
			local v59_ = self.keyboardAlpha.elements[v55_ - 10]
			local v60_ = self.keyboardAlpha.elements[v55_ + 10]
			FocusManager:linkElements(v56_, FocusManager.LEFT, v57_ or v56_)
			FocusManager:linkElements(v56_, FocusManager.RIGHT, v58_ or v56_)
			if v59_ == nil then
				if v55_ <= 5 then
					FocusManager:linkElements(v56_, FocusManager.TOP, self.buttonCursorLeft)
				else
					FocusManager:linkElements(v56_, FocusManager.TOP, self.buttonCursorRight)
				end
			else
				FocusManager:linkElements(v56_, FocusManager.TOP, v59_)
			end
			if v60_ == nil then
				local v61_ = self.typeOption
				if numerical then
					v61_ = self.keyboardNumeric.elements[(v55_ - 1) % 10 + 1]
				elseif special then
					v61_ = self.keyboardSpecial.elements[(v55_ - 1) % 10 + 1]
				end
				FocusManager:linkElements(v56_, FocusManager.BOTTOM, v61_)
			else
				FocusManager:linkElements(v56_, FocusManager.BOTTOM, v60_)
			end
		end
	else
		v52_ = nil
	end
	if numerical then
		v51_ = v51_ or self.keyboardNumeric.elements[1]
		v52_ = self.keyboardNumeric.elements[1]
		for v62_ = 1, #self.keyboardNumeric.elements do
			local v63_ = self.keyboardNumeric.elements[v62_]
			local v64_ = self.keyboardNumeric.elements[v62_ - 1]
			local v65_ = self.keyboardNumeric.elements[v62_ + 1]
			local v66_
			if alphabetical then
				local v67_ = (#self.keyboardAlpha.elements - 1) / 10
				local v68_ = math.floor(v67_) * 10 + v62_
				local v69_ = #self.keyboardAlpha.elements
				local v70_ = math.min(v68_, v69_)
				v66_ = self.keyboardAlpha.elements[v70_]
			else
				v66_ = nil
			end
			local v71_ = self.typeOption
			if special then
				v71_ = self.keyboardSpecial.elements[v62_]
			end
			FocusManager:linkElements(v63_, FocusManager.LEFT, v64_ or v63_)
			FocusManager:linkElements(v63_, FocusManager.RIGHT, v65_ or v63_)
			if v66_ == nil then
				if v62_ <= 5 then
					FocusManager:linkElements(v63_, FocusManager.TOP, self.buttonCursorLeft)
				else
					FocusManager:linkElements(v63_, FocusManager.TOP, self.buttonCursorRight)
				end
			else
				FocusManager:linkElements(v63_, FocusManager.TOP, v66_)
			end
			if v71_ ~= nil then
				FocusManager:linkElements(v63_, FocusManager.BOTTOM, v71_)
			end
		end
	end
	if special then
		v51_ = v51_ or self.keyboardSpecial.elements[1]
		v52_ = self.keyboardSpecial.elements[1]
		for v72_ = 1, #self.keyboardSpecial.elements do
			local v73_ = self.keyboardSpecial.elements[v72_]
			local v74_ = self.keyboardSpecial.elements[v72_ - 1]
			local v75_ = self.keyboardSpecial.elements[v72_ + 1]
			local v76_ = nil
			if numerical then
				v76_ = self.keyboardNumeric.elements[v72_]
			elseif alphabetical then
				local v77_ = (#self.keyboardAlpha.elements - 1) / 10
				local v78_ = math.floor(v77_) * 10 + v72_
				local v79_ = #self.keyboardAlpha.elements
				local v80_ = math.min(v78_, v79_)
				v76_ = self.keyboardAlpha.elements[v80_]
			end
			FocusManager:linkElements(v73_, FocusManager.LEFT, v74_ or v73_)
			FocusManager:linkElements(v73_, FocusManager.RIGHT, v75_ or v73_)
			if v76_ == nil then
				if v72_ <= 5 then
					FocusManager:linkElements(v73_, FocusManager.TOP, self.buttonCursorLeft)
				else
					FocusManager:linkElements(v73_, FocusManager.TOP, self.buttonCursorRight)
				end
			else
				FocusManager:linkElements(v73_, FocusManager.TOP, v76_)
			end
			FocusManager:linkElements(v73_, FocusManager.BOTTOM, self.typeOption)
		end
	end
	if v51_ ~= nil then
		FocusManager:linkElements(self.typeOption, FocusManager.TOP, v52_)
		FocusManager:linkElements(self.buttonCursorLeft, FocusManager.BOTTOM, v51_)
		FocusManager:linkElements(self.buttonCursorRight, FocusManager.BOTTOM, v51_)
		if self.needsFirstFocusUpdate or FocusManager:getFocusedElement() ~= nil and FocusManager:getFocusedElement():getIsDisabled() then
			FocusManager:setFocus(v51_)
			self.needsFirstFocusUpdate = false
		end
	end
end

-- Local values: positionInfo, values, value, realIndex, i, _, element, shouldBeDisabled, _, element, shouldBeDisabled, _, element, shouldBeDisabled
function LicensePlateDialog:updateCursor()
	local v82_ = self.cursorPositions[self.currentCursorPosition]
	self.cursorElement:setSize(v82_.width, v82_.height)
	self.cursorElement:setAbsolutePosition(v82_.x, v82_.y)
	local v83_ = self.licensePlate.variations[self.currentVariation].values
	local v84_ = v83_[1]
	local v85_ = 1
	for v86_ = 1, #v83_ do
		if not (v83_[v86_].isStatic or v83_[v86_].locked) then
			if v85_ == self.currentCursorPosition then
				v84_ = v83_[v86_]
				break
			end
			v85_ = v85_ + 1
		end
	end
	for _, v87_ in ipairs(self.keyboardAlpha.elements) do
		local v88_ = not v84_.alphabetical
		if v87_:getIsDisabled() ~= v88_ then
			v87_:setDisabled(v88_)
		end
	end
	for _, v89_ in ipairs(self.keyboardNumeric.elements) do
		local v90_ = not v84_.numerical
		if v89_:getIsDisabled() ~= v90_ then
			v89_:setDisabled(v90_)
		end
	end
	for _, v91_ in ipairs(self.keyboardSpecial.elements) do
		local v92_ = not v84_.special
		if v91_:getIsDisabled() ~= v92_ then
			v91_:setDisabled(v92_)
		end
	end
	self:updateFocusLinking(v84_.alphabetical, v84_.numerical, v84_.special)
end

-- Local values: texts, typeText, i
function LicensePlateDialog:updateVariations()
	local v94_ = g_i18n:getText("ui_licensePlateTypeItem")
	local v95_ = {}
	for v96_ = 1, #self.licensePlate.variations do
		local v97_ = string.format
		table.insert(v95_, v97_(v94_, v96_))
	end
	self.typeOption:setTexts(v95_)
	self.typeOption:setState(self.currentVariation)
end

-- Local values: r, g, b
function LicensePlateDialog:updateColorButton()
	if self.licensePlate ~= nil then
		local v99_ = self.licensePlate
		local v100_ = self.currentColorIndex
		local v101_, v102_, v103_ = unpack(v99_:getColor(v100_))
		self.changeColorButtonImage:setImageColor(nil, math.clamp(v101_, 0, 1), math.clamp(v102_, 0, 1), math.clamp(v103_, 0, 1), 1)
	end
end

-- Local values: values, camera, offsetX, offsetY, lx, ly, lz, plateEdgeX, plateEdgeY, _, _, fontHeight, fontHeightScreen, _, value, valueWidth, node, _, x, y, z, cursorX, cursorY, _
function LicensePlateDialog:updateLicensePlateGraphics()
	self.licensePlate:updateData(self.currentVariation, LicensePlateManager.PLATE_POSITION.BACK, table.concat(self.currentCharacters, ""))
	self.licensePlate:setColorIndex(self.currentColorIndex)
	self:updateColorButton()
	self.sceneRender:setRenderDirty()
	self.sceneRender:setVisible(true)
	local v105_ = g_licensePlateManager:getLicensePlateValues(self.licensePlate, self.currentVariation)
	self.cursorPositions = {}
	local v106_ = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)
	local v107_ = 2 * g_pixelSizeX
	local v108_ = 8 * g_pixelSizeY
	local v109_, v110_, v111_ = localToWorld(self.licensePlate.node, self.licensePlate.width * 0.5, self.licensePlate.height * 0.5, 0)
	local v112_, v113_, _ = projectToCamera(v106_, 3, v109_, v110_, v111_)
	local _, v114_ = self.licensePlate:getFontSize()
	local v115_ = (v113_ - 0.5) * 2 * (v114_ / self.licensePlate.height) * self.sceneRender.size[2] + v108_
	if v105_ ~= nil then
		for _, v116_ in ipairs(v105_) do
			if not (v116_.isStatic or v116_.locked) then
				local v117_ = (v112_ - 0.5) * 2 * (v116_.maxWidthRatio * v114_ / self.licensePlate.width) * self.sceneRender.size[1] + v107_
				local v118_, _ = I3DUtil.indexToObject(self.licensePlate.node, v116_.nodePath)
				local v119_, v120_, v121_ = getWorldTranslation(v118_)
				local v122_, v123_, _ = projectToCamera(v106_, 3, v119_, v120_, v121_)
				local v124_ = v122_ * self.sceneRender.size[1] + self.sceneRender.absPosition[1] - v117_ * 0.5
				local v125_ = v123_ * self.sceneRender.size[2] + self.sceneRender.absPosition[2] - v115_ * 0.5
				local v126_ = self.cursorPositions
				local v127_ = {
					["x"] = v124_,
					["y"] = v125_,
					["width"] = v117_,
					["height"] = v115_,
					["valueIndex"] = v116_.index
				}
				table.insert(v126_, v127_)
			end
		end
	end
	local v128_ = self.currentCursorPosition
	local v129_ = #self.cursorPositions
	self.currentCursorPosition = math.min(v128_, v129_)
	self:updateCursor()
end

function LicensePlateDialog:onCreatePlacementOption(element)
	self.placementOption = element
	self:updatePlacementOptions()
end

-- Local values: texts, index, text
function LicensePlateDialog:updatePlacementOptions(excluded)
	self.textToPlacementIndex = {}
	local v134_ = {}
	for v135_, v136_ in pairs(LicensePlateManager.PLACEMENT_OPTION_TEXT) do
		if v135_ ~= excluded then
			local v137_ = g_i18n
			table.insert(v134_, v137_:getText(v136_))
			self.textToPlacementIndex[#v134_] = v135_
		end
	end
	self.placementOption:setTexts(v134_)
	self.placementOption:setState(1)
end

function LicensePlateDialog:onClickBack()
	self:sendCallback(nil)
	LicensePlateDialog:superClass().onClickBack(self)
end

-- Local values: colors, defaultColorIndex
function LicensePlateDialog:onClickChangeColor()
	local v140_, v141_ = g_licensePlateManager:getAvailableColors()
	local v142_ = table.clone(v140_, math.huge)
	if #v142_ > 1 then
		ColorPickerDialog.show(self.onPickedColor, self, nil, v142_, v141_, nil, nil, nil, true)
	end
	return true
end

function LicensePlateDialog:onPickedColor(colorIndex, args, customColor)
	if colorIndex ~= nil then
		self.currentColorIndex = colorIndex
		self:updateLicensePlateGraphics()
	end
end

function LicensePlateDialog:onClickOk()
	self.currentCharacters = self.licensePlate:validateLicensePlateCharacters(self.currentCharacters)
	self:sendCallback(self.currentVariation, self.currentCharacters, self.currentColorIndex, self.currentPlacementIndex)
	LicensePlateDialog:superClass().onClickOk(self)
end

function LicensePlateDialog:onRenderLoad(scene, overlay)
	setTranslation(scene, 0, -1, 0)
	setName(scene, "LicensePlateDialog_" .. getName(scene))
	self.licensePlaceLinkNode = I3DUtil.indexToObject(scene, "0|0")
end

-- Local values: licensePlate, cameraNode, fovY, tolerance, distanceWidth, distanceHeight, distance
function LicensePlateDialog:updateLicensePlate()
	if self.licensePlaceLinkNode ~= nil then
		local v149_ = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)
		if v149_ ~= nil then
			link(self.licensePlaceLinkNode, v149_.node)
			setTranslation(v149_.node, 0, 0, 0)
			setRotation(v149_.node, 0, 0, 0)
			self.licensePlate = v149_
			if self.currentCharacters == nil then
				self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)
			end
			local v150_ = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)
			if v150_ ~= nil then
				local v151_ = getFovY(v150_)
				local v152_ = self.licensePlate.width / 2 + 0.005
				local v153_ = v151_ / 2
				local v154_ = v152_ / math.tan(v153_) / (self.sceneRender.size[1] / self.sceneRender.size[2] * g_screenAspectRatio)
				local v155_ = self.licensePlate.height / 2 + 0.005
				local v156_ = v151_ / 2
				local v157_ = v155_ / math.tan(v156_)
				local v158_ = math.max(v154_, v157_)
				setTranslation(v150_, 0, 0, v158_)
			end
			self:updateLicensePlateGraphics()
			self:updateVariations()
		end
	end
end

function LicensePlateDialog:onClickKeyboardButton(element)
	self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = element.keyboardValue
	self:updateLicensePlateGraphics()
	self:onClickCursorRight()
end

function LicensePlateDialog:onClickCursorLeft()
	self.currentCursorPosition = self.currentCursorPosition - 1
	if self.currentCursorPosition < 1 then
		self.currentCursorPosition = #self.cursorPositions
	end
	self:updateCursor()
end

function LicensePlateDialog:onClickCursorRight()
	self.currentCursorPosition = self.currentCursorPosition + 1
	if self.currentCursorPosition > #self.cursorPositions then
		self.currentCursorPosition = 1
	end
	self:updateCursor()
end

function LicensePlateDialog:onClickPlacementOptionChanged(selection)
	self.currentPlacementIndex = self.textToPlacementIndex[selection]
end

function LicensePlateDialog:onClickTypeOptionChanged(selection)
	self.currentVariation = selection
	self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)
	self:updateLicensePlateGraphics()
end

function LicensePlateDialog:setButtonTexts(okText) end

function LicensePlateDialog:setButtonAction(buttonAction) end

-- Local values: value, charValue
function LicensePlateDialog:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if LicensePlateDialog:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) then
		return true
	end
	if isDown then
		if sym ~= Input.KEY_backspace then
			local v173_ = self:getUnicodeToKeyboardValue(unicode, self.licensePlate.variations[self.currentVariation].values[self.cursorPositions[self.currentCursorPosition].valueIndex])
			if v173_ ~= nil then
				self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = v173_
				self:updateLicensePlateGraphics()
				self:onClickCursorRight()
			end
			return true
		end
		if self.currentCursorPosition > 1 then
			self:onClickCursorLeft()
			return true
		end
	end
	return false
end

-- Local values: text, font, check, result, result, result
function LicensePlateDialog:getUnicodeToKeyboardValue(unicode, value)
	local v_u_176_ = utf8ToUpper(unicodeToUtf8(unicode))
	local v_u_177_ = g_licensePlateManager:getFont()
	local function v181_(p178_)
		-- upvalues: (copy) v_u_177_, (copy) v_u_176_
		local v179_ = v_u_177_.charactersByType[p178_]
		for v180_ = 1, #v179_ do
			if v_u_176_ == utf8ToUpper(v179_[v180_].value) then
				return v179_[v180_].value
			end
		end
		return nil
	end
	if value.alphabetical then
		local v182_ = v181_(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL)
		if v182_ ~= nil then
			return v182_
		end
	end
	if value.numerical then
		local v183_ = v181_(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL)
		if v183_ ~= nil then
			return v183_
		end
	end
	if value.special then
		local v184_ = v181_(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL)
		if v184_ ~= nil then
			return v184_
		end
	end
	return nil
end
