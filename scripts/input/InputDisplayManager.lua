-- Local values: InputDisplayManager_mt, actionBindingsBuffer
InputDisplayManager = {}
local InputDisplayManager_mt = Class(InputDisplayManager)
source("dataS/scripts/input/DisplayActionBinding.lua")
source("dataS/scripts/input/InputHelpElement.lua")
InputDisplayManager.CONTROLLER_SYMBOLS_PATH = "dataS/controllerSymbols.xml"
InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH = "dataS/axisIcons.xml"
InputDisplayManager.SYMBOLS_TEXTURE_CONFIG_PATH = "dataS/menu/controllerSymbols.xml"
InputDisplayManager.AXIS_ICON_BASE_SIZE = 40
InputDisplayManager.SYMBOL_PREFIX_XBOX = "xbox_"
InputDisplayManager.SYMBOL_PREFIX_PS4 = "ps4_"
InputDisplayManager.SYMBOL_PREFIX_PS5 = "ps5_"
InputDisplayManager.SYMBOL_PREFIX_MOUSE = "mouse_"
InputDisplayManager.SYMBOL_PREFIX_SWITCH = "switch_"
InputDisplayManager.SYMBOL_PREFIX_MOBILE = "mobile_"
InputDisplayManager.SYMBOL_PREFIX_STADIA = "stadia_"
InputDisplayManager.AXIS_NAME_X = "X"
InputDisplayManager.AXIS_NAME_Y = "Y"
InputDisplayManager.AXIS_NAME_MOUSE_X = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
InputDisplayManager.AXIS_NAME_MOUSE_Y = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
InputDisplayManager.AXIS_AFFIX_POSITIVE = "(+)"
InputDisplayManager.AXIS_AFFIX_NEGATIVE = "(-)"
InputDisplayManager.MODIFIER_BUTTON_CONCAT = " + "
InputDisplayManager.PLUS_OVERLAY_NAME = "PLUS"
InputDisplayManager.OR_OVERLAY_NAME = "OR"
InputDisplayManager.NO_HELP_ELEMENT = InputHelpElement.new()

-- Upvalues: InputDisplayManager_mt
-- Local values: self, eventsCallback
function InputDisplayManager.new(messageCenter, inputManager, modManager, isConsoleVersion)
	-- upvalues: (copy) InputDisplayManager_mt
	local v6_ = InputDisplayManager_mt
	local v_u_7_ = setmetatable({}, v6_)
	v_u_7_.messageCenter = messageCenter
	v_u_7_.inputManager = inputManager
	v_u_7_.modManager = modManager
	v_u_7_.isConsoleVersion = isConsoleVersion
	v_u_7_.isMobileVersion = GS_IS_MOBILE_VERSION
	messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, v_u_7_.onActionBindingsChanged, v_u_7_)
	inputManager:setEventChangeCallback(function(p8_)
		-- upvalues: (copy) v_u_7_
		v_u_7_:onActionEventsChanged(p8_)
	end)
	v_u_7_.actionList = inputManager:getActionList()
	v_u_7_.actionBindings = inputManager:getActionBindings()
	v_u_7_.eventHelpElements = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}
	v_u_7_.eventComboButtons = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}
	v_u_7_.controllerSymbols = {}
	v_u_7_.plusOverlay = nil
	v_u_7_.orOverlay = nil
	v_u_7_.keyboardKeyOverlay = nil
	v_u_7_.axisIconOverlays = {}
	v_u_7_.buttonIconSize = 45
	v_u_7_.uiScale = 1
	g_overlayManager:addTextureConfigFile(InputDisplayManager.SYMBOLS_TEXTURE_CONFIG_PATH, "controllerSymbols")
	v_u_7_.debugControllerSymbols = false
	return v_u_7_
end

-- Local values: axisIconsXmlFile
function InputDisplayManager:load()
	self.uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)
	self:setDevGamepadLabelMapping()
	self:loadControllerSymbolsAndOverlays()
	local v10_ = loadXMLFile("AxisIcons", InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH)
	if v10_ == 0 then
		Logging.warning("Unable to load axisIcon definition file %q", InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH)
	else
		self:loadAxisIcons(v10_)
		delete(v10_)
	end
	self:loadModAxisIcons()
	addConsoleCommand("gsInputDebugControllerSymbols", "", "consoleCommandShowInputControllerSymbols", self)
end

-- Local values: _, symbol, _, overlay
function InputDisplayManager:delete()
	g_messageCenter:unsubscribeAll(self)
	for _, v12_ in pairs(self.controllerSymbols) do
		v12_.overlay:delete()
	end
	for _, v13_ in pairs(self.axisIconOverlays) do
		v13_:delete()
	end
	self.keyboardKeyOverlay:delete()
end

-- Local values: PS_BUTTON_MAPPING, PS_AXIS_MAPPING, oldGetGamepadButtonLabel, oldGetGamepadAxisLabel
function InputDisplayManager:setDevGamepadLabelMapping()
	if GS_PLATFORM_PLAYSTATION and g_isDevelopmentVersion then
		local v_u_14_ = {
			["A"] = "Cross",
			["B"] = "Circle",
			["X"] = "Square",
			["Y"] = "Triangle",
			["LB"] = "L1",
			["RB"] = "R1",
			["Back"] = "Options",
			["Start"] = "Touch",
			["LS"] = "L3",
			["RS"] = "R3"
		}
		local v_u_15_ = {
			["LT"] = "L2",
			["RT"] = "R2"
		}
		local v_u_16_ = getGamepadButtonLabel
		function getGamepadButtonLabel(p17_, p18_)
			-- upvalues: (copy) v_u_16_, (copy) v_u_14_
			local v19_ = v_u_16_(p17_, p18_)
			return Utils.getNoNil(v_u_14_[v19_], v19_)
		end
		local v_u_20_ = getGamepadAxisLabel
		function getGamepadAxisLabel(p21_, p22_)
			-- upvalues: (copy) v_u_20_, (copy) v_u_15_
			local v23_ = v_u_20_(p21_, p22_)
			return Utils.getNoNil(v_u_15_[v23_], v23_)
		end
	end
end

-- Local values: metadata, xmlFile, filename, i, baseName, prefix, axisName, sliceId, parts, axisSymbolName, _, part
function InputDisplayManager:loadControllerSymbolsAndOverlays()
	local v25_ = g_overlayManager:getConfigMetaData("controllerSymbols")
	if v25_ == nil then
		Logging.warning("No texture config for controller symbols found")
	else
		local v26_ = loadXMLFile("ControllerSymbolsBinding", InputDisplayManager.CONTROLLER_SYMBOLS_PATH)
		local v27_ = v25_.filename
		local v28_ = 0
		while true do
			local v29_ = string.format("controllerSymbols.controllerSymbol(%d)", v28_)
			if not hasXMLProperty(v26_, v29_) then
				break
			end
			local v30_ = getXMLString(v26_, v29_ .. "#prefix") or ""
			local v31_ = getXMLString(v26_, v29_ .. "#name")
			local v32_ = "controllerSymbols." .. getXMLString(v26_, v29_ .. "#sliceId")
			if v31_ ~= nil then
				local v33_ = v31_:trim():split(" ")
				local v34_ = ""
				for _, v35_ in pairs(v33_) do
					if v35_ ~= "" then
						v34_ = v34_ .. v30_ .. v35_
					end
				end
				if self.controllerSymbols[v34_] then
					printWarning("Warning: controller symbol name \'" .. v34_ .. "\' already exists!")
				else
					self:createButtonOverlay(v34_, v27_, v32_)
				end
			end
			v28_ = v28_ + 1
		end
		self.keyboardKeyOverlay = ButtonOverlay.new()
		delete(v26_)
	end
end

-- Local values: iconSizeX, iconSizeY, overlay, symbol
function InputDisplayManager:createButtonOverlay(axisName, filename, sliceId)
	local v40_, v41_ = getNormalizedScreenValues(self.buttonIconSize * self.uiScale, self.buttonIconSize * self.uiScale)
	local v42_ = g_overlayManager:createOverlay(sliceId, 0, 0, v40_, v41_)
	v42_:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)
	self.controllerSymbols[axisName] = {
		["name"] = axisName,
		["filename"] = filename,
		["overlay"] = v42_
	}
	if axisName == InputDisplayManager.PLUS_OVERLAY_NAME then
		self.plusOverlay = v42_
		v42_.width = v40_ * 0.5
		v42_.defaultWidth = v40_ * 0.5
		v42_.height = v41_ * 0.5
		v42_.defaultHeight = v41_ * 0.5
	elseif axisName == InputDisplayManager.OR_OVERLAY_NAME then
		self.orOverlay = v42_
		v42_.width = v40_ * 0.5
		v42_.defaultWidth = v40_ * 0.5
		v42_.height = v41_ * 0.5
		v42_.defaultHeight = v41_ * 0.5
	end
end

-- Local values: rootPath, baseDirectory, prefix, modName, dir, i, baseName, iconName, iconPath, iconFilename, size, iconWidth, iconHeight, iconOverlay
function InputDisplayManager:loadAxisIcons(xmlFile, modPath)
	if xmlFile == nil or xmlFile == 0 then
		Logging.error("InputDisplayManager:loadAxisIcons(): xmlFile nil or 0")
		printCallstack()
	else
		local v46_, v47_, v48_
		if modPath then
			v46_, v47_ = Utils.getModNameAndBaseDirectory(modPath)
			v48_ = "modDesc.axisIcons"
		else
			v48_ = "axisIcons"
			v46_ = ""
			v47_ = ""
		end
		local v49_ = 0
		while true do
			local v50_ = string.format("%s.icon(%d)", v48_, v49_)
			if not hasXMLProperty(xmlFile, v50_) then
				break
			end
			local v51_ = v46_ .. getXMLString(xmlFile, v50_ .. "#name") or ""
			local v52_ = getXMLString(xmlFile, v50_ .. "#filename")
			if v51_ and v52_ then
				local v53_ = Utils.getFilename(v52_, v47_)
				local v54_ = InputDisplayManager.AXIS_ICON_BASE_SIZE * self.uiScale
				local v55_, v56_ = getNormalizedScreenValues(v54_, v54_)
				local v57_ = Overlay.new(v53_, 0, 0, v55_, v56_)
				v57_:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)
				self.axisIconOverlays[v51_] = v57_
			end
			v49_ = v49_ + 1
		end
	end
end

-- Local values: _, modDesc, xmlFile
function InputDisplayManager:loadModAxisIcons()
	for _, v59_ in ipairs(self.modManager:getMods()) do
		local v60_ = loadXMLFile("ModFile", v59_.modFile)
		if v60_ == 0 then
			Logging.error("InputDisplayManager:loadModAxisIcons(): unable to load %q", v59_.modFile)
		else
			self:loadAxisIcons(v60_, v59_.modFile)
			delete(v60_)
		end
	end
end

-- Local values: bindings, addedGamepadBinding, addedGamepadBindingIndex, _, binding, axisRepresented, _, contextBinding, isMouse, isGamepad, shouldSwapGamepadBinding, bindingIsActualGamepad, isActualGamepadCombo
function InputDisplayManager:addContextBindings(contextBindings, action, isContextGamepad, isComboAction)
	local v66_ = self.actionBindings[action]
	local v67_ = -1
	local v68_ = nil
	for _, v69_ in pairs(v66_) do
		if v69_.isActive then
			local v70_ = false
			if not isComboAction then
				for _, v71_ in pairs(contextBindings) do
					if v69_.internalDeviceId == v71_.internalDeviceId and v69_.unmodifiedAxis == v71_.unmodifiedAxis then
						v70_ = true
						break
					end
				end
			end
			if not v70_ then
				local v72_ = not isContextGamepad
				if v72_ then
					v72_ = v69_.isMouse
				end
				local v73_
				if isContextGamepad then
					v73_ = v69_.isGamepad
				else
					v73_ = isContextGamepad
				end
				local v74_
				if v73_ then
					if v68_ == nil then
						v74_ = false
					else
						v74_ = v69_.index < v68_.index
					end
				else
					v74_ = v73_
				end
				if v74_ or self.inputManager:getDeviceByInternalId(v69_.internalDeviceId).category == InputDevice.CATEGORY.GAMEPAD and isComboAction then
					table.remove(contextBindings, v67_)
					v68_ = nil
				end
				if v72_ or v73_ and v68_ == nil then
					table.insert(contextBindings, v69_)
					if v73_ then
						v67_ = #contextBindings
						v68_ = v69_
					end
				end
			end
		end
	end
end

-- Local values: contextBindings
function InputDisplayManager:getActionBindingsForContext(action1, action2, isContextGamepad, isComboAction)
	local v80_ = {}
	self:addContextBindings(v80_, action1, isContextGamepad, isComboAction)
	if action2 then
		self:addContextBindings(v80_, action2, isContextGamepad)
	end
	return v80_
end
local v_u_81_ = {}

-- Upvalues: actionBindingsBuffer
-- Local values: k, bindings1, bindings2, kbBindings, _, bindings, _, binding
function InputDisplayManager:getKeyboardBindings(action1, action2)
	-- upvalues: (copy) v_u_81_
	for v85_ in pairs(v_u_81_) do
		v_u_81_[v85_] = nil
	end
	local v86_ = self.actionBindings[action1]
	if action2 then
		action2 = self.actionBindings[action2]
	end
	local v87_ = v_u_81_
	table.insert(v87_, v86_)
	if action2 ~= nil then
		local v88_ = v_u_81_
		table.insert(v88_, action2)
	end
	local v89_ = {}
	for _, v90_ in ipairs(v_u_81_) do
		for _, v91_ in ipairs(v90_) do
			if v91_.isKeyboard then
				table.insert(v89_, v91_)
			end
		end
	end
	return v89_
end

-- Local values: i, comboAxis, symbolName, symbol
function InputDisplayManager:resolveModifierSymbols(overlays, separators, isComboButtonMapping, firstContextBinding)
	for v97_ = 1, #firstContextBinding.axisNames - 1 do
		local v98_ = firstContextBinding.axisNames[v97_]
		local v99_ = self:getGamepadInputSymbolName(firstContextBinding.internalDeviceId, v98_, false)
		local v100_ = self.controllerSymbols[v99_]
		if v100_ ~= nil then
			local v101_ = v100_.overlay
			table.insert(overlays, v101_)
			table.insert(isComboButtonMapping, true)
			local v102_ = InputHelpElement.SEPARATOR.COMBO_INPUT
			table.insert(separators, v102_)
		end
	end
end

-- Local values: accumSymbolName, _, name, symbol, i
function InputDisplayManager:resolveAccumulatedSymbolPermutations(overlays, isComboButtonMapping, symbolNames, permLength)
	if permLength == 0 then
		local v108_ = ""
		for _, v109_ in ipairs(symbolNames) do
			v108_ = v108_ .. v109_
		end
		local v110_ = self.controllerSymbols[v108_]
		if v110_ ~= nil then
			local v111_ = v110_.overlay
			table.insert(overlays, v111_)
			table.insert(isComboButtonMapping, false)
			return
		end
	else
		for v112_ = 1, permLength do
			local v113_ = symbolNames[v112_]
			local v114_ = symbolNames[permLength]
			symbolNames[permLength] = v113_
			symbolNames[v112_] = v114_
			self:resolveAccumulatedSymbolPermutations(overlays, isComboButtonMapping, symbolNames, permLength - 1)
			local v115_ = symbolNames[v112_]
			local v116_ = symbolNames[permLength]
			symbolNames[permLength] = v115_
			symbolNames[v112_] = v116_
		end
	end
end

-- Local values: accumSymbols, _, binding, symbolName, isAxisInput, isDuplicateName, _, knownName, symbol
function InputDisplayManager:resolveUnmodifiedSymbols(overlays, isComboButtonMapping, contextBindings, isContextGamepad, accumulateSymbols)
	local v123_ = nil
	for _, v124_ in pairs(contextBindings) do
		local v125_
		if isContextGamepad then
			local v126_ = v124_.isAnalog
			v125_ = self:getGamepadInputSymbolName(v124_.internalDeviceId, v124_.unmodifiedAxis, v126_)
		else
			v125_ = self:getMouseInputSymbolName(v124_.axisNames)
		end
		if accumulateSymbols and v125_ ~= nil then
			if v123_ == nil then
				v123_ = { v125_ }
			else
				local v127_ = false
				for _, v128_ in ipairs(v123_) do
					if v128_ == v125_ then
						v127_ = true
						break
					end
				end
				if not v127_ then
					table.insert(v123_, v125_)
				end
			end
		else
			local v129_ = self.controllerSymbols[v125_]
			if v129_ ~= nil then
				local v130_ = v129_.overlay
				table.insert(overlays, v130_)
				table.insert(isComboButtonMapping, false)
			end
		end
	end
	if accumulateSymbols and v123_ ~= nil then
		self:resolveAccumulatedSymbolPermutations(overlays, isComboButtonMapping, v123_, #v123_)
	end
end

-- Local values: prevCount, afterCount, _
function InputDisplayManager:addRegularSymbols(overlays, separators, isComboButtonMapping, accumulateSymbols, contextBindings, isContextGamepad, ignoreComboButtons)
	if #contextBindings > 0 then
		if not ignoreComboButtons and isContextGamepad then
			self:resolveModifierSymbols(overlays, separators, isComboButtonMapping, contextBindings[1])
		end
		local v139_ = #overlays
		self:resolveUnmodifiedSymbols(overlays, isComboButtonMapping, contextBindings, isContextGamepad, accumulateSymbols)
		local v140_ = #overlays
		if v139_ ~= v140_ then
			for _ = 1, v140_ - v139_ - 1 do
				local v141_ = InputHelpElement.SEPARATOR.ANY_INPUT
				table.insert(separators, v141_)
			end
		end
	end
end

-- Local values: binding, _, inputAxisName, symbolName, symbol, symbolName, _
function InputDisplayManager:addComboSymbols(overlays, separators, isComboButtonMapping, contextBindings, isContextGamepad)
	local v148_ = #contextBindings == 1
	assert(v148_, "Number of bindings for a combo action must always be 1, check code and configuration!")
	local v149_ = contextBindings[1]
	if isContextGamepad then
		for _, v150_ in ipairs(v149_.axisNames) do
			local v151_ = self:getGamepadInputSymbolName(v149_.internalDeviceId, v150_, false)
			local v152_ = self.controllerSymbols[v151_]
			if v152_ ~= nil then
				local v153_ = v152_.overlay
				table.insert(overlays, v153_)
				table.insert(isComboButtonMapping, true)
			end
		end
	else
		local v154_ = self:getMouseInputSymbolName(v149_.axisNames, false)
		local v155_ = self.controllerSymbols[v154_].overlay
		table.insert(overlays, v155_)
		table.insert(isComboButtonMapping, true)
	end
	for _ = 1, #overlays - 1 do
		local v156_ = InputHelpElement.SEPARATOR.COMBO_INPUT
		table.insert(separators, v156_)
	end
end

-- Local values: action1, action2, isGamepadComboAction, isMouseComboAction, isComboAction, isContextGamepad
function InputDisplayManager:getControllerSymbolOverlays(actionName1, actionName2, text, ignoreComboButtons, customBinding)
	local v163_ = self.inputManager:getActionByName(actionName1)
	local v164_ = self.inputManager:getActionByName(actionName2)
	local v165_ = InputBinding.GAMEPAD_COMBOS[actionName1] ~= nil
	local v166_ = InputBinding.MOUSE_COMBOS[actionName1] ~= nil
	local v167_ = v165_ or v166_
	local v168_ = self.isConsoleVersion or (self.isMobileVersion or (self.inputManager:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD and true or v165_))
	if customBinding ~= nil then
		return self:makeHelpElementForBinding(v163_, customBinding)
	end
	if v168_ then
		v168_ = not v166_
	end
	return self:makeHelpElement(v163_, v164_, text, v167_, v168_, ignoreComboButtons)
end

-- Local values: accumulateSymbols, allDpad, _, binding, allMouseWheel, _, binding
function InputDisplayManager.requireSymbolAccumulation(action1, action2, contextBindings)
	local v172_ = action1:isFullAxis() and not action2
	if v172_ then
		action2 = v172_
	elseif action2 then
		action2 = action2:isFullAxis()
	end
	if not action2 then
		local v173_ = true
		for _, v174_ in pairs(contextBindings) do
			if v173_ then
				v173_ = InputBinding.getIsDPadInput(v174_.axisNames)
			end
		end
		action2 = action2 or v173_
	end
	if not action2 then
		local v175_ = true
		for _, v176_ in pairs(contextBindings) do
			if v175_ then
				v175_ = InputBinding.getIsMouseWheelInput(v176_.axisNames)
			end
		end
		action2 = action2 or v175_
	end
	return action2
end

-- Local values: contextBindings, separators, overlays, isComboButtonMapping, accumulateSymbols, keys, kbBindings, modifierHash, _, binding, _, key, isModifierKey, helpElement, action2Name
function InputDisplayManager:makeHelpElement(action1, action2, text, isComboAction, isContextGamepad, ignoreComboButtons, customAxisIcon, priority)
	local v186_ = self:getActionBindingsForContext(action1, action2, isContextGamepad, isComboAction)
	local v187_ = {}
	local v188_ = {}
	local v189_ = {}
	if #v186_ > 0 then
		if isComboAction then
			self:addComboSymbols(v188_, v187_, v189_, v186_, isContextGamepad)
		else
			self:addRegularSymbols(v188_, v187_, v189_, InputDisplayManager.requireSymbolAccumulation(action1, action2, v186_), v186_, isContextGamepad, ignoreComboButtons)
		end
	end
	local v190_ = {}
	if #v188_ < 1 and not isContextGamepad then
		local v191_ = self:getKeyboardBindings(action1, action2)
		local v192_ = {}
		for _, v193_ in ipairs(v191_) do
			for _, v194_ in ipairs(v193_.axisNames) do
				local v195_ = v193_.modifierAxisSet[v194_] ~= nil
				if not (v195_ and v192_[v194_]) then
					local v196_ = KeyboardHelper.getDisplayKeyName
					local v197_ = Input[v194_]
					table.insert(v190_, v196_(v197_))
					if v195_ then
						v192_[v194_] = true
					end
				end
			end
		end
	end
	local v198_ = InputDisplayManager.NO_HELP_ELEMENT
	if #v188_ > 0 or #v190_ > 0 then
		local v199_ = action2 == nil and "" or (action2.name or "")
		v198_ = InputHelpElement.new(action1.name, v199_, v188_, v190_, v187_, v189_, text, not ignoreComboButtons, customAxisIcon, priority)
	end
	return v198_
end

-- Local values: contextBindings, separators, overlays, isComboButtonMapping, accumulateSymbols, keys, modifierHash, _, key, isModifierKey, helpElement
function InputDisplayManager:makeHelpElementForBinding(action, binding)
	local v203_ = { binding }
	local v204_ = {}
	local v205_ = {}
	local v206_ = {}
	if not binding.isKeyboard then
		self:addRegularSymbols(v205_, v204_, v206_, InputDisplayManager.requireSymbolAccumulation(action, nil, v203_), v203_, binding.isGamepad)
	end
	local v207_ = {}
	if #v205_ < 1 then
		local v208_ = {}
		for _, v209_ in ipairs(binding.axisNames) do
			local v210_ = binding.modifierAxisSet[v209_] ~= nil
			if not (v210_ and v208_[v209_]) then
				local v211_ = KeyboardHelper.getDisplayKeyName
				local v212_ = Input[v209_]
				table.insert(v207_, v211_(v212_))
				if v210_ then
					v208_[v209_] = true
				end
			end
		end
	end
	local v213_ = InputDisplayManager.NO_HELP_ELEMENT
	if #v205_ > 0 or #v207_ > 0 then
		v213_ = InputHelpElement.new(action.name, nil, v205_, v207_, v204_, v206_)
	end
	return v213_
end

function InputDisplayManager:onActionEventsChanged(displayActionEvents)
	self:storeEventHelpElements(displayActionEvents)
	self:storeComboHelpElements(displayActionEvents)
end

-- Local values: action1, action2
function InputDisplayManager.sortEventHelpElements(helpElem1, helpElem2)
	if helpElem1.priority == helpElem2.priority then
		if helpElem1.actionName == "" or helpElem2.actionName == "" then
			return helpElem2.actionName == ""
		else
			local v218_ = g_inputBinding:getActionByName(helpElem1.actionName)
			local v219_ = g_inputBinding:getActionByName(helpElem2.actionName)
			if v218_.primaryKeyboardInput == nil then
				return helpElem1.text < helpElem2.text
			elseif v219_.primaryKeyboardInput == nil then
				return false
			else
				return v218_.primaryKeyboardInput < v219_.primaryKeyboardInput
			end
		end
	else
		return helpElem1.priority < helpElem2.priority
	end
end
function InputDisplayManager.sortEventHelpElementsGamepad()
	-- failed to decompile
end

-- Local values: helpMode, modeHelpElements, isContextGamepad, _, actionEvent, action, event, inlineModifierButtons, actionComboMask, maskHelpElements, axisIcon, helpElement, sortFunc, _, maskHelpElements
function InputDisplayManager:storeEventHelpElements(displayActionEvents)
	self.eventHelpElements = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}
	for v222_, v223_ in pairs(self.eventHelpElements) do
		local v224_ = v222_ == GS_INPUT_HELP_MODE_GAMEPAD
		for _, v225_ in ipairs(displayActionEvents) do
			local v226_ = v225_.action
			local v227_ = v225_.event
			local v228_ = v225_.inlineModifierButtons or v222_ == GS_INPUT_HELP_MODE_KEYBOARD
			local v229_ = 0
			if v224_ then
				if not v228_ then
					v229_ = v226_.comboMaskGamepad
				end
			else
				v229_ = v226_.comboMaskMouse
			end
			local v230_ = v223_[v229_]
			if not v230_ then
				v230_ = {}
				v223_[v229_] = v230_
			end
			local v231_ = not v227_.contextDisplayIconName or self.axisIconOverlays[v227_.contextDisplayIconName]
			if not v231_ then
				printWarning("Warning: Could not resolve axis icon name \'" .. v227_.contextDisplayIconName .. "\'. Check vehicle and axis icon configurations.")
			end
			local v232_ = self:makeHelpElement(v226_, nil, v227_.contextDisplayText, false, v224_, not v228_, v231_, v227_.displayPriority)
			if v232_ ~= InputDisplayManager.NO_HELP_ELEMENT then
				table.insert(v230_, v232_)
			end
		end
		local v233_ = InputDisplayManager.sortEventHelpElements
		if v224_ then
			v233_ = InputDisplayManager.sortEventHelpElementsGamepad
		end
		for _, v234_ in pairs(v223_) do
			table.sort(v234_, v233_)
		end
	end
end

-- Local values: helpMode, _, isContextGamepad, _, actionEvent, action, _, binding, isPrimaryGamepad, isMouse, comboActionName
function InputDisplayManager:storeComboHelpElements(displayActionEvents)
	self.eventComboButtons = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}
	for v237_, _ in pairs(self.eventHelpElements) do
		local v238_ = v237_ == GS_INPUT_HELP_MODE_GAMEPAD
		for _, v239_ in ipairs(displayActionEvents) do
			local v240_ = v239_.action
			for _, v241_ in pairs(self.actionBindings[v240_]) do
				local v242_ = v238_ and v241_.isActive
				if v242_ then
					v242_ = v241_.isGamepad
				end
				local v243_ = not v238_
				if v243_ then
					v243_ = v241_.isMouse
				end
				if v242_ and not v239_.inlineModifierButtons or v243_ then
					local v244_ = self.inputManager:getComboActionNameForAxisSet(v241_.modifierAxisSet)
					if v244_ then
						self.eventComboButtons[v237_][v244_] = true
					end
				end
			end
		end
	end
end

-- Local values: helpMode, comboHelpElements, eventHelpElement, _, helpElements, _, element
function InputDisplayManager:getEventHelpElementForAction(inputActionName)
	local v247_ = self.inputManager:getInputHelpMode()
	local v248_ = self.eventHelpElements[v247_]
	local v249_ = nil
	for _, v250_ in pairs(v248_) do
		for _, v251_ in pairs(v250_) do
			if v251_.actionName == inputActionName then
				v249_ = v251_
				break
			end
		end
	end
	return v249_
end

-- Local values: helpMode, elements
function InputDisplayManager:getEventHelpElements(pressedComboMask, isContextGamepad)
	local v255_ = isContextGamepad and GS_INPUT_HELP_MODE_GAMEPAD or GS_INPUT_HELP_MODE_KEYBOARD
	return self.eventHelpElements[v255_][pressedComboMask]
end

-- Local values: helpMode
function InputDisplayManager:getComboHelpElements(isContextGamepad)
	local v258_ = isContextGamepad and GS_INPUT_HELP_MODE_GAMEPAD or GS_INPUT_HELP_MODE_KEYBOARD
	return self.eventComboButtons[v258_]
end

-- Local values: prefix, gamepadName
function InputDisplayManager:getPrefix(internalDeviceId)
	local v260_ = ""
	if GS_PLATFORM_XBOX then
		return InputDisplayManager.SYMBOL_PREFIX_XBOX
	end
	if GS_PLATFORM_SWITCH then
		return InputDisplayManager.SYMBOL_PREFIX_SWITCH
	end
	if GS_PLATFORM_SWITCH2 then
		return InputDisplayManager.SYMBOL_PREFIX_SWITCH
	end
	if GS_PLATFORM_PLAYSTATION then
		if internalDeviceId == 0 and GS_PLATFORM_ID == PlatformId.PS5 then
			return InputDisplayManager.SYMBOL_PREFIX_PS5
		end
	else
		if GS_IS_MOBILE_VERSION then
			v260_ = InputDisplayManager.SYMBOL_PREFIX_MOBILE
		end
		if internalDeviceId ~= nil then
			local v261_ = getGamepadName(internalDeviceId)
			if v261_ == InputDevice.NAMES.XBOX_GAMEPAD or v261_ == InputDevice.NAMES.XINPUT_GAMEPAD then
				return InputDisplayManager.SYMBOL_PREFIX_XBOX
			end
			if v261_ == InputDevice.NAMES.PS_GAMEPAD then
				return InputDisplayManager.SYMBOL_PREFIX_PS4
			end
			if v261_ == InputDevice.NAMES.PS5_GAMEPAD then
				return InputDisplayManager.SYMBOL_PREFIX_PS5
			end
			if v261_ == InputDevice.NAMES.STADIA_GAMEPAD then
				return InputDisplayManager.SYMBOL_PREFIX_STADIA
			end
			if v261_ == InputDevice.NAMES.SWITCH_GAMEPAD then
				v260_ = InputDisplayManager.SYMBOL_PREFIX_SWITCH
			end
		end
	end
	return v260_
end

function InputDisplayManager:getPlusOverlay()
	return self.plusOverlay
end

function InputDisplayManager:getOrOverlay()
	return self.orOverlay
end

function InputDisplayManager:getKeyboardKeyOverlay()
	return self.keyboardKeyOverlay
end

-- Local values: action, contextBinding, internalDeviceId, bindings, lowestIndex, _, binding, fitsContext
function InputDisplayManager:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, isGamepad)
	local v269_ = axisComponent or Binding.AXIS_COMPONENT.POSITIVE
	local v270_ = self.inputManager:getActionByName(inputActionName)
	local v271_ = nil
	local v272_ = nil
	local v273_ = self.actionBindings[v270_]
	local v274_ = math.huge
	if v273_ == nil then
		return "", -1
	else
		for _, v275_ in ipairs(v273_) do
			local v276_
			if v275_.isGamepad and isGamepad then
				v276_ = isGamepad
			else
				v276_ = v275_.isKeyboard
				if v276_ then
					v276_ = not isGamepad
				end
			end
			if v275_.isActive and (v275_.index < v274_ and (v276_ and v275_.axisComponent == v269_)) then
				v272_ = v275_.internalDeviceId
				v274_ = v275_.index
				v271_ = v275_
			end
		end
		if v271_ then
			return v271_.axisNames[1], v272_
		else
			return "", -1
		end
	end
end

-- Local values: axisName, internalDeviceId, symbolName, overlay, guiOverlay
function InputDisplayManager:getGamepadInputActionOverlay(inputActionName, axisComponent)
	local v280_, v281_ = self:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, true)
	local v282_ = self:getGamepadInputSymbolName(v281_, v280_, false)
	if v282_ == nil or v282_ == "" then
		return nil
	end
	if self.controllerSymbols[v282_] == nil then
		Logging.devWarning("Controller symbol name \'%s\' is not defined in controllerSymbols.xml", v282_)
		return nil
	end
	local v283_ = self.controllerSymbols[v282_].overlay
	local v284_ = {
		["uvs"] = v283_.uvs,
		["color"] = {
			v283_.r,
			v283_.g,
			v283_.b,
			v283_.a
		},
		["filename"] = v283_.filename
	}
	GuiOverlay.createOverlay(v284_)
	return v284_
end

-- Local values: axisName, keyId, keyName
function InputDisplayManager:getKeyboardInputActionKey(inputActionName, axisComponent)
	local v288_ = self:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, false)
	if v288_ == "" then
		return nil
	end
	local v289_ = Input[v288_]
	return KeyboardHelper.getDisplayKeyName(v289_)
end

-- Local values: symbolName, prefix, axisId, axisLabel, buttonId, buttonLabel
function InputDisplayManager:getGamepadInputSymbolName(internalDeviceId, axisName, isAxisInput)
	local v293_ = ""
	if internalDeviceId ~= nil and internalDeviceId >= 0 then
		local v294_ = InputDisplayManager:getPrefix(internalDeviceId)
		if isAxisInput then
			local v295_ = Input.axisIdNameToId[axisName]
			if v295_ ~= nil then
				return v294_ .. string.gsub(getGamepadAxisLabel(v295_, internalDeviceId), " ", "")
			end
		else
			local v296_ = Input.buttonIdNameToId[axisName]
			if v296_ ~= nil then
				local v297_ = getGamepadButtonLabel(v296_, internalDeviceId)
				v293_ = v294_ .. string.gsub(v297_, " ", "")
			end
		end
	end
	return v293_
end

-- Local values: symbolName, _, axisName
function InputDisplayManager:getMouseInputSymbolName(axisNames)
	local v299_ = ""
	for _, v300_ in pairs(axisNames) do
		if InputBinding.MOUSE_BUTTONS[v300_] then
			v299_ = v299_ .. InputDisplayManager.SYMBOL_PREFIX_MOUSE .. v300_
		elseif v300_:sub(1, #InputDisplayManager.AXIS_NAME_MOUSE_X) == InputDisplayManager.AXIS_NAME_MOUSE_X then
			v299_ = v299_ .. InputDisplayManager.SYMBOL_PREFIX_MOUSE .. "AxisX"
		elseif v300_:sub(1, #InputDisplayManager.AXIS_NAME_MOUSE_Y) == InputDisplayManager.AXIS_NAME_MOUSE_Y then
			v299_ = v299_ .. InputDisplayManager.SYMBOL_PREFIX_MOUSE .. "AxisY"
		end
	end
	return v299_
end

function InputDisplayManager:onActionBindingsChanged(actionBindings)
	self.actionBindings = actionBindings
end

function InputDisplayManager:draw()
	if self.debugControllerSymbols then
		self:debugRenderControllerSymbols()
	end
end

-- Local values: symbols, posX, posY, width, height, textOffsetX, _, offsetX, offsetY, textSize, maxTextWidth, maxWidth, _, data, overlay
function InputDisplayManager:debugRenderControllerSymbols()
	new2DLayer()
	setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 0.99)
	renderOverlay(GuiElement.debugOverlay, 0, 0, 1, 1)
	local v305_ = self.controllerSymbolsSorted
	local v306_, v307_ = getNormalizedScreenValues(30, 30)
	local v308_, _ = getNormalizedScreenValues(5, 0)
	local v309_, v310_ = getNormalizedScreenValues(20, -45)
	local v311_ = getCorrectTextSize(0.007)
	local v312_ = getNormalizedScreenValues(120, 0)
	setTextWrapWidth(v312_, true)
	setTextColor(1, 1, 1, 1)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	local v313_ = 0.005
	local v314_ = 0.97
	local v315_ = 0
	for _, v316_ in ipairs(v305_) do
		local v317_ = v316_.overlay
		v317_:setPosition(v313_, v314_)
		v317_:setDimension(v306_, v307_)
		v317_:render()
		v317_:resetDimensions()
		local v318_ = getTextWidth
		local v319_ = v316_.name
		v315_ = math.max(v315_, v318_(v311_, v319_))
		renderText(v313_ + v308_ + v306_, v314_, v311_, v316_.name)
		v314_ = v314_ + v310_
		if v314_ < 0 then
			v313_ = v313_ + v306_ + v309_ + v315_
			v314_ = 0.97
			v315_ = 0
		end
	end
	setTextWrapWidth(0)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
end

-- Local values: _, symbol
function InputDisplayManager:consoleCommandShowInputControllerSymbols()
	self.debugControllerSymbols = not self.debugControllerSymbols
	if self.debugControllerSymbols then
		if self.controllerSymbolsSorted == nil then
			self.controllerSymbolsSorted = {}
			for _, v321_ in pairs(self.controllerSymbols) do
				local v322_ = self.controllerSymbolsSorted
				table.insert(v322_, v321_)
			end
			table.sort(self.controllerSymbolsSorted, function(p323_, p324_)
				return p323_.name < p324_.name
			end)
			return
		end
	else
		self.controllerSymbolsSorted = nil
	end
end
