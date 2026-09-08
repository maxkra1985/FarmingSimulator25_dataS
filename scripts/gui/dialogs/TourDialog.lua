-- Local values: TourDialog_mt
TourDialog = {}
local TourDialog_mt = Class(TourDialog, MessageDialog)
function TourDialog.register()
	local v2_ = TourDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/TourDialog.xml", "TourDialog", v2_)
	TourDialog.INSTANCE = v2_
end

-- Local values: dialog
function TourDialog.show(title, text, controlGlyphs, callback, target)
	if TourDialog.INSTANCE ~= nil then
		local v8_ = TourDialog.INSTANCE
		v8_.controlGlyphs = controlGlyphs or {}
		v8_:setTitle(title)
		v8_:setText(text)
		v8_:setCallback(callback, target)
		v8_:updateSize()
		g_gui:showDialog("TourDialog")
	end
end

-- Upvalues: TourDialog_mt
-- Local values: self
function TourDialog.new(target, custom_mt)
	-- upvalues: (copy) TourDialog_mt
	local v11_ = MessageDialog.new(target, custom_mt or TourDialog_mt)
	v11_.buttonAction = InputAction.MENU_ACCEPT
	v11_.isBackAllowed = false
	v11_.inputDelay = 250
	v11_.defaultTitle = "Guided Tour"
	v11_.controlGlyphs = {}
	v11_.lastInputHelpMode = GS_INPUT_HELP_MODE_TOUCH
	return v11_
end

-- Local values: title, text, controlGlyphs, callback, target
function TourDialog.createFromExistingGui(gui, guiName)
	TourDialog.register()
	local v13_ = gui.title
	local v14_ = gui.tourText
	local v15_ = gui.controlGlyphs
	local v16_ = gui.onOk
	local v17_ = gui.target
	TourDialog.show(v13_, v14_, v15_, v16_, v17_)
end

function TourDialog:setTitle(title)
	if self.dialogTitleElement ~= nil then
		self.dialogTitleElement:setText(Utils.getNoNil(title, self.defaultTitle))
	end
end

function TourDialog:setText(text)
	TourDialog:superClass().setText(self, text)
	self.tourText = text
end

function TourDialog:setCallback(onOk, target)
	self.onOk = onOk
	self.target = target
end

-- Local values: i, inputItem, controlGlyph, icon1, icon2, isAccelerateAction, dialogTextElement, textHeight, inputBoxSize, spacing, isUsingGamepad, contentSize, dialogHeight, tourTextPos
function TourDialog:updateSize()
	for v26_, _ in pairs(self.inputItems) do
		local v27_ = self.controlGlyphs[v26_]
		if v27_ == nil then
			self.inputItems[v26_]:setVisible(false)
		else
			self.inputItems[v26_]:setVisible(true)
			self.description[v26_]:setText(v27_.text)
			local v28_ = self.icon1[v26_]
			local v29_ = self.icon2[v26_]
			if v27_.buttons[2] == nil then
				v28_ = self.icon2[v26_]
				v29_ = self.icon1[v26_]
			end
			v28_:setVisible(v27_.buttons[1] ~= nil)
			if v27_.buttons[1] ~= nil then
				v28_:setImageFilename(v27_.buttons[1].filename)
				local v30_ = v27_.buttons[1].uvs
				v28_:setImageUVs(nil, unpack(v30_))
			end
			if v27_.actionName == "AXIS_ACCELERATE_VEHICLE" and true or v27_.actionName == "AXIS_BRAKE_VEHICLE" then
				self.iconSeparator[v26_]:applyProfile("tourDialogItemIconSeparator")
			else
				self.iconSeparator[v26_]:applyProfile("tourDialogItemIconPlus")
			end
			self.iconSeparator[v26_]:setVisible(v27_.buttons[2] ~= nil)
			v29_:setVisible(v27_.buttons[2] ~= nil)
			if v27_.buttons[2] ~= nil then
				v29_:setImageFilename(v27_.buttons[2].filename)
				local v31_ = v27_.buttons[2].uvs
				v29_:setImageUVs(nil, unpack(v31_))
			end
		end
	end
	local v32_ = self.dialogTextElement
	local v33_ = v32_:getTextHeight()
	self.dialogTextElement:setSize(nil, v33_)
	local v34_ = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD
	local v35_ = self.inputItems[1].absSize[2]
	local v36_, v37_
	if v34_ and #self.controlGlyphs > 0 then
		v36_ = 30 * g_pixelSizeY
		v37_ = v35_ * #self.controlGlyphs + v36_
	else
		v37_ = 0
		v36_ = 0
	end
	self.inputBox:setVisible(v34_)
	local v38_ = v37_ + v33_ + v32_.margin[2] + v32_.margin[4]
	self.dialogElement:setSize(nil, v38_)
	self.dialogElement:updateAbsolutePosition()
	if v34_ then
		local v39_ = self.dialogTextElement.position
		self.inputBox:setPosition(nil, v39_[2] - v36_ - v33_)
		self.inputBox:setSize(nil, v35_ * #self.controlGlyphs)
		self.dialogElement:updateAbsolutePosition()
	end
end

function TourDialog:acceptDialog(inputAction, force)
	if inputAction ~= self.buttonAction and not force or self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.onOk ~= nil then
		if self.target == nil then
			self.onOk(self.args)
		else
			self.onOk(self.target, self.args)
		end
	end
	return false
end

function TourDialog:onClickOk()
	return self:acceptDialog(self.buttonAction, false)
end

-- Local values: newInputHelpMode
function TourDialog:update(dt)
	TourDialog:superClass().update(self, dt)
	local v46_ = g_inputBinding:getInputHelpMode()
	if v46_ ~= self.lastInputHelpMode then
		self.lastInputHelpMode = v46_
		self:updateSize()
	end
end

function TourDialog:inputEvent(action, value, eventUsed)
	local v51_ = TourDialog:superClass().inputEvent(self, action, value, eventUsed)
	if Platform.isAndroid and (self.inputDisableTime <= 0 and action == InputAction.MENU_BACK) then
		self:onClickOk()
		v51_ = true
	end
	return v51_
end
