-- Local values: InGameMenuTourFrame_mt
InGameMenuTourFrame = {}
local InGameMenuTourFrame_mt = Class(InGameMenuTourFrame, TabbedMenuFrameElement)
function InGameMenuTourFrame.register()
	local v2_ = InGameMenuTourFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuTourFrame.xml", "TourFrame", v2_, true)
end

-- Upvalues: InGameMenuTourFrame_mt
-- Local values: self
function InGameMenuTourFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuTourFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuTourFrame_mt)
	v5_.hasCustomMenuButtons = true
	return v5_
end

-- Local values: newGui
function InGameMenuTourFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuTourFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function InGameMenuTourFrame:delete()
	self.contentItem:delete()
	self.controlItem:delete()
	InGameMenuTourFrame:superClass().delete(self)
end

function InGameMenuTourFrame:initialize()
	InGameMenuTourFrame:superClass().initialize()
	self.contentItem:unlinkElement()
	self.controlItem:unlinkElement()
	self.abortButton = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_abortTour"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonCancel()
		end,
		["profile"] = "buttonCancel"
	}
end

function InGameMenuTourFrame:onFrameOpen()
	InGameMenuTourFrame:superClass().onFrameOpen(self)
	self:updateContents()
	self.layout:registerActionEvents()
	self:updateMenuButtons()
end

function InGameMenuTourFrame:onFrameClose()
	self.layout:removeActionEvents()
	InGameMenuTourFrame:superClass().onFrameClose(self)
end

-- Local values: tour
function InGameMenuTourFrame:updateMenuButtons()
	self.menuButtonInfo = {
		{
			["inputAction"] = InputAction.MENU_BACK
		}
	}
	local v14_ = g_guidedTourManager:getActiveTour()
	if v14_ ~= nil and v14_:getCanAbort() then
		local v15_ = self.menuButtonInfo
		local v16_ = self.abortButton
		table.insert(v15_, v16_)
	end
	self:setMenuButtonInfoDirty()
end

-- Local values: isTourRunning, tour
function InGameMenuTourFrame:onButtonCancel()
	if g_guidedTourManager:getIsTourRunning() and g_guidedTourManager:getActiveTour():getCanAbort() then
		YesNoDialog.show(self.onAbortTourAnswer, self, g_i18n:getText("guidedTour_abort_question"), "")
	end
end

-- Local values: tour
function InGameMenuTourFrame:onAbortTourAnswer(yes)
	if yes then
		local v19_ = g_guidedTourManager:getActiveTour()
		if v19_ ~= nil and v19_:getCanAbort() then
			g_guidedTourManager:abortTour()
			g_gui:changeScreen(nil)
		end
	end
end

-- Local values: inputMode
function InGameMenuTourFrame:update(dt)
	InGameMenuTourFrame:superClass().update(self, dt)
	if g_inputBinding:getInputHelpMode() ~= self.currentInputHelpMode then
		self:updateContents()
	end
end

-- Local values: i, tour, steps, i, step, row, textElement, controlsElement, height, useGamepadButtons, numVisibleControls, _, input, action1, action2, controlItem, glyph, text
function InGameMenuTourFrame:updateContents()
	self.currentInputHelpMode = g_inputBinding:getInputHelpMode()
	for v23_ = #self.layout.elements, 1, -1 do
		self.layout.elements[v23_]:delete()
	end
	self.layout:invalidateLayout()
	local v24_ = g_guidedTourManager:getActiveTour()
	if v24_ ~= nil then
		local v25_ = v24_:getPassedStepsInfo()
		for v26_ = #v25_, 1, -1 do
			local v27_ = v25_[v26_]
			local v28_ = self.contentItem:clone(self.layout)
			local v29_ = v28_:getDescendantByName("text")
			local v30_ = v28_:getDescendantByName("controls")
			v29_:setText(g_i18n:convertText(v27_.text))
			local v31_ = v29_:getTextHeight()
			v29_:setSize(nil, v31_)
			local v32_ = self.currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD
			local v33_ = 0
			if v27_.inputs ~= nil then
				for _, v34_ in ipairs(v27_.inputs) do
					local v35_ = InputAction[v34_.actionName]
					local v36_
					if v34_.actionName2 == nil then
						v36_ = nil
					else
						v36_ = InputAction[v34_.actionName2] or nil
					end
					if not (v34_.keyboardOnly and v32_) and (not v34_.gamepadOnly or v32_) then
						local v37_ = self.controlItem:clone(v30_)
						v33_ = v33_ + 1
						v37_.hasFrame = v33_ > 1
						v37_:getDescendantByName("glyph"):setActions({ v35_, v36_ })
						v37_:getDescendantByName("text"):setText(g_i18n:convertText(v34_.text))
					end
				end
			end
			v30_:setVisible(v33_ > 0)
			if v33_ > 0 then
				v30_:setSize(nil, v33_ * v30_.elements[1].absSize[2])
				v30_:invalidateLayout()
				local v38_ = v30_.absSize[2] - 20 * g_pixelSizeY
				v31_ = math.max(v31_, v38_)
			end
			v28_:setSize(nil, v28_.size[2] + v31_)
		end
		self.layout:invalidateLayout()
	end
end
