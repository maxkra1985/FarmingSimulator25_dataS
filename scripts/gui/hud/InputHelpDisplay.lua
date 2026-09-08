-- Local values: data, old, InputHelpDisplay_mt, inputHelp
local v1_
if InputHelpDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.inputHelp
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible(),
		["vehicle"] = v2_.vehicle
	}
	v2_:delete()
end
InputHelpDisplay = {}
InputHelpDisplay.MAX_NUM_ELEMENTS = 6
InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY = 16
InputHelpDisplay.MAX_SCHEMA_COLLECTION_DEPTH = 5
InputHelpDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH = "dataS/vehicleSchemaOverlays.xml"
local data = Class(InputHelpDisplay, HUDDisplay)
function InputHelpDisplay.new()
	-- upvalues: (copy) data
	local v4_ = InputHelpDisplay:superClass().new(data)
	v4_.vehicle = nil
	v4_.extraHelpTexts = {}
	v4_.helpExtensions = {}
	v4_.infoExtensions = {}
	v4_.skipActions = {}
	local v5_ = HUD.COLOR.BACKGROUND
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.lineBg = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
	v4_.lineBg:setColor(v6_, v7_, v8_, v9_)
	v4_.lineBgLeft = g_overlayManager:createOverlay("gui.shortcutBox1_left", 0, 0, 0, 0)
	v4_.lineBgLeft:setColor(v6_, v7_, v8_, v9_)
	v4_.lineBgScale = g_overlayManager:createOverlay("gui.shortcutBox1_middle", 0, 0, 0, 0)
	v4_.lineBgScale:setColor(v6_, v7_, v8_, v9_)
	v4_.lineBgRight = g_overlayManager:createOverlay("gui.shortcutBox1_right", 0, 0, 0, 0)
	v4_.lineBgRight:setColor(v6_, v7_, v8_, v9_)
	v4_.comboBg = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
	v4_.comboBg:setColor(v6_, v7_, v8_, v9_)
	v4_.comboText = utf8ToUpper(g_i18n:getText("ui_controlsAdvanced"))
	v4_.controlGroupText = utf8ToUpper(g_i18n:getText("ui_controlsControlGroup"))
	v4_.glyphButtonOverlay = GlyphButtonOverlay.new()
	v4_.glyphButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
	v4_.keyButtonOverlay = ButtonOverlay.new()
	v4_.keyButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.8)
	v4_.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v4_.separatorHorizontal:setColor(1, 1, 1, 0.25)
	v4_.separatorVertical = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
	v4_.separatorVertical:setColor(1, 1, 1, 0.25)
	local v10_ = g_inputDisplayManager
	v4_.mouseComboOverlays = {}
	for _, v11_ in ipairs(InputBinding.ORDERED_MOUSE_COMBOS) do
		local v12_ = v11_.controls
		local v13_ = v10_:getControllerSymbolOverlays(v12_, "", "", false)
		local v14_ = {}
		for _, v15_ in ipairs(v13_.buttons) do
			table.insert(v14_, v15_)
		end
		local v16_ = v4_.mouseComboOverlays
		local v17_ = {
			["actionName"] = v12_,
			["overlays"] = v14_,
			["mask"] = v11_.mask
		}
		table.insert(v16_, v17_)
	end
	v4_:updateGamepadComboButtons()
	v4_.vehicle = nil
	v4_.vehicleSchemaOverlays = {}
	v4_.iconSizeX = 0
	v4_.iconSizeY = 0
	v4_.maxSchemaWidth = 0
	g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, v4_.updateGamepadComboButtons, v4_)
	return v4_
end

-- Local values: k, v
function InputHelpDisplay:delete()
	self.lineBg:delete()
	self.lineBgLeft:delete()
	self.lineBgScale:delete()
	self.lineBgRight:delete()
	self.comboBg:delete()
	self.glyphButtonOverlay:delete()
	self.keyButtonOverlay:delete()
	self.separatorHorizontal:delete()
	self.separatorVertical:delete()
	for v19_, v20_ in pairs(self.vehicleSchemaOverlays) do
		v20_:delete()
		self.vehicleSchemaOverlays[v19_] = nil
	end
	g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)
	InputHelpDisplay:superClass().delete(self)
end

-- Local values: lineWidth, lineHeight, partWidth, comboWidth, comboHeight, verticalSeparatorHeight, _, overlay, pixelSize, width, height
function InputHelpDisplay:storeScaledValues()
	self:setPosition(g_hudAnchorLeft, g_hudAnchorTop)
	local v22_, v23_ = self:scalePixelValuesToScreenVector(330, 25)
	self.lineBg:setDimension(v22_, v23_)
	local v24_, v25_ = self:scalePixelValuesToScreenVector(340, -25)
	self.helpAnchorOffsetX = v24_
	self.helpAnchorOffsetY = v25_
	local v26_ = self:scalePixelToScreenWidth(6)
	self.lineBgLeft:setDimension(v26_, v23_)
	self.lineBgScale:setDimension(0, v23_)
	self.lineBgRight:setDimension(v26_, v23_)
	local v27_, v28_ = self:scalePixelValuesToScreenVector(330, 50)
	self.comboBg:setDimension(v27_, v28_)
	self.lineOffsetY = self:scalePixelToScreenHeight(5)
	self.textSize = self:scalePixelToScreenHeight(12)
	local v29_, v30_ = self:scalePixelValuesToScreenVector(14, 8)
	self.textOffsetX = v29_
	self.textOffsetY = v30_
	local v31_, v32_ = self:scalePixelValuesToScreenVector(14, 32)
	self.comboTextOffsetX = v31_
	self.comboTextOffsetY = v32_
	local v33_, v34_ = self:scalePixelValuesToScreenVector(0, 24)
	self.comboSeparatorOffsetX = v33_
	self.comboSeparatorOffsetY = v34_
	local v35_, v36_ = self:scalePixelValuesToScreenVector(24, 24)
	self.comboIconWidth = v35_
	self.comboIconHeight = v36_
	self.separatorHorizontal:setDimension(v22_, g_pixelSizeY)
	local v37_ = self:scalePixelToScreenHeight(24)
	self.separatorVertical:setDimension(g_pixelSizeX, v37_)
	self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
	self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
	local v38_, v39_ = self:scalePixelValuesToScreenVector(14, 2)
	self.schemaOffsetX = v38_
	self.schemaOffsetY = v39_
	local v40_, v41_ = self:scalePixelValuesToScreenVector(26, 26)
	self.iconSizeX = v40_
	self.iconSizeY = v41_
	self.maxSchemaWidth = self:scalePixelToScreenWidth(180)
	for _, v42_ in pairs(self.vehicleSchemaOverlays) do
		v42_:resetDimensions()
		local v43_, v44_ = self:scalePixelToScreenVector({ v42_.defaultWidth, v42_.defaultHeight })
		v42_:setDimension(v43_, v44_)
	end
end

-- Local values: isVisible, posX, posY, vehicleControlPosY, inputBinding, inputDisplayManager, pressedComboMaskGamepad, pressedComboMaskMouse, useGamepadButtons, currentPressedMask, isCombo, comboActionStatus, hasComboCommands, eventHelpElements, helpExtensionTotalHeight, i, helpExtension, height, infoExtensionTotalHeight, i, infoExtension, height, ignoreComboButtons, combos, pressedComboMask, numCombos, widthPerCombo, activeColor, iconPosX, k, comboInfo, isPressed, r, g, b, a, numOverlays, spaceX, spacingX, overlayPosX, _, overlay, numElements, k, extension, k, helpElement, buttons, isComboButtonMapping, keys, lineBg, lineHeight, totalWidth, startPosX, startPosX, i, key, keyWidth, width, maxNumElements, k, extension, maxNumElements, k, extension, newPosY, k, text
function InputHelpDisplay:draw(offsetX, offsetY)
	local v48_ = self:getVisible()
	local v49_, v50_ = self:getPosition()
	local v51_ = v49_ + (offsetX or 0)
	local v52_, v53_ = self:drawVehicleSchema(v51_, v50_ + (offsetY or 0), not v48_)
	if not v48_ then
		return
	end
	local v54_ = g_inputBinding
	local v55_ = g_inputDisplayManager
	local v56_, v57_ = v54_:getComboCommandPressedMask()
	local v58_ = GS_IS_CONSOLE_VERSION or v54_:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
	local v59_ = v58_ and v56_ and v56_ or v57_
	local v60_ = v59_ ~= 0
	local v61_ = v55_:getComboHelpElements(v58_)
	local v62_ = next(v61_) ~= nil
	local v63_ = v55_:getEventHelpElements(v59_, v58_)
	if (v63_ == nil or #v63_ == 0) and (not v62_ and v60_) then
		v63_ = v55_:getEventHelpElements(0, v58_)
	end
	table.sort(self.helpExtensions, function(p64_, p65_)
		return p64_.priority < p65_.priority
	end)
	table.sort(self.infoExtensions, function(p66_, p67_)
		if p66_.priority == p67_.priority then
			return (p66_.vehicle == nil or (p67_.vehicle == nil or (p66_.vehicle.lastDistanceToCamera == nil or p67_.vehicle.lastDistanceToCamera == nil))) and true or p66_.vehicle.lastDistanceToCamera < p67_.vehicle.lastDistanceToCamera
		else
			return p66_.priority < p67_.priority
		end
	end)
	local v68_ = 0
	for v69_ = #self.helpExtensions, 1, -1 do
		local v70_ = self.helpExtensions[v69_]
		if v70_.setEventHelpElements ~= nil then
			v70_:setEventHelpElements(self, v63_)
		end
		local v71_ = v70_:getHeight()
		if v71_ > 0 then
			v68_ = v68_ + v71_ + self.lineOffsetY
		else
			table.remove(self.helpExtensions, v69_)
		end
	end
	local v72_ = 0
	for v73_ = #self.infoExtensions, 1, -1 do
		local v74_ = self.infoExtensions[v73_]
		if v74_.setEventHelpElements ~= nil then
			v74_:setEventHelpElements(self, v63_)
		end
		local v75_ = v74_:getHeight()
		if v75_ > 0 then
			v72_ = v72_ + v75_ + self.lineOffsetY
		else
			table.remove(self.infoExtensions, v73_)
		end
	end
	local v76_, v77_
	if v62_ then
		v76_ = true
		local v78_ = v52_ - self.comboBg.height
		self.comboBg:renderCustom(v51_, v78_)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		renderText(v51_ + self.comboTextOffsetX, v78_ + self.comboTextOffsetY, self.textSize, self.comboText)
		self.separatorHorizontal:renderCustom(v51_ + self.comboSeparatorOffsetX, v78_ + self.comboSeparatorOffsetY)
		local v79_ = self.mouseComboOverlays
		if v58_ then
			v79_ = self.gamepadComboOverlays
		else
			v56_ = v57_
		end
		local v80_ = #v79_
		local v81_ = self.comboBg.width / v80_
		local v82_ = HUD.COLOR.ACTIVE
		v77_ = v51_
		for v83_, v84_ in ipairs(v79_) do
			if v61_[v84_.actionName] then
				local v85_ = v84_.mask
				local v86_, v87_, v88_, v89_
				if bit32.band(v56_, v85_) ~= 0 then
					v86_ = v82_[1]
					v87_ = v82_[2]
					v88_ = v82_[3]
					v89_ = v82_[4]
				else
					v86_ = 1
					v87_ = 1
					v88_ = 1
					v89_ = 1
				end
				local v90_ = #v84_.overlays
				local v91_ = (v81_ - self.comboIconWidth * v90_) / (v90_ + 3)
				local v92_ = v51_ + 2 * v91_
				for _, v93_ in ipairs(v84_.overlays) do
					v93_:renderCustom(v92_, v78_, self.comboIconWidth, self.comboIconHeight, v86_, v87_, v88_, v89_)
					v92_ = v92_ + v91_ + self.comboIconWidth
				end
			end
			if v83_ < v80_ then
				v51_ = v51_ + v81_
				self.separatorVertical:renderCustom(v51_, v78_)
			end
		end
		v52_ = v78_ - self.lineOffsetY
	else
		v77_ = v51_
		v76_ = false
	end
	local v94_ = 0
	for _, v95_ in pairs(self.helpExtensions) do
		if v95_.priority <= GS_PRIO_LOW then
			v94_ = v94_ + 1
		end
	end
	if v63_ ~= nil then
		for _, v96_ in ipairs(v63_) do
			if self.skipActions[v96_.actionName] == nil then
				if v96_.actionName == InputAction.SWITCH_IMPLEMENT and v53_ ~= nil then
					local v97_ = v96_.buttons
					local v98_ = v96_.isComboButtonMapping
					local v99_ = v96_.keys
					local v100_ = self.lineBg
					local v101_ = v100_.height
					v53_ = v53_ - v101_
					if #v97_ > 0 then
						local v102_ = self.glyphButtonOverlay:getButtonWidth(v97_, v98_, true, v101_)
						local v103_ = v77_ + v100_.width - v102_
						self.glyphButtonOverlay:renderButton(v97_, v98_, true, v103_, v53_, v101_)
					elseif #v99_ > 0 then
						local v104_ = v77_ + v100_.width
						for v105_ = #v99_, 1, -1 do
							local v106_ = v99_[v105_]
							v104_ = v104_ - (self.keyButtonOverlay:getButtonWidth(v106_, v101_) + g_pixelSizeX)
							self.keyButtonOverlay:renderButton(v106_, v104_, v53_, v101_, true)
						end
					end
				else
					v52_ = self:drawInputHelpElement(v77_, v52_, v96_, v76_) - self.lineOffsetY
				end
				v94_ = v94_ + 1
				if (v96_.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS) < v94_ then
					break
				end
			else
				self.skipActions[v96_.actionName] = nil
			end
		end
	end
	for v107_, v108_ in pairs(self.helpExtensions) do
		if v94_ < (v108_.priority <= GS_PRIO_LOW and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS) then
			v52_ = v108_:draw(self, v77_, v52_) - self.lineOffsetY
			v94_ = v94_ + 1
		end
		self.helpExtensions[v107_] = nil
	end
	for v109_, v110_ in pairs(self.infoExtensions) do
		local v111_ = v110_:draw(self, v77_, v52_)
		if v111_ ~= v52_ then
			v52_ = v111_ - self.lineOffsetY
		end
		self.infoExtensions[v109_] = nil
	end
	for v112_, v113_ in pairs(self.extraHelpTexts) do
		v52_ = self:drawExtraText(v77_, v52_, v113_) - self.lineOffsetY
		self.extraHelpTexts[v112_] = nil
	end
end

-- Local values: lineBg, lineHeight, posY, buttons, isComboButtonMapping, keys, maxWidth, totalWidth, startPosX, startPosX, i, key, keyWidth, width, iconOverlay, iconWidth, iconHeight, textOffsetX, textOffsetY, text
function InputHelpDisplay:drawInputHelpElement(posX, posYTop, helpElement, ignoreComboButtons)
	local v119_ = self.lineBg
	local v120_ = v119_.height
	local v121_ = posYTop - v120_
	v119_:renderCustom(posX, v121_)
	local v122_ = helpElement.buttons
	local v123_ = helpElement.isComboButtonMapping
	local v124_ = helpElement.keys
	local v125_ = v119_.width
	if #v122_ > 0 then
		local v126_ = self.glyphButtonOverlay:getButtonWidth(v122_, v123_, ignoreComboButtons, v120_)
		local v127_ = posX + v119_.width - v126_
		self.glyphButtonOverlay:renderButton(v122_, v123_, ignoreComboButtons, v127_, v121_, v120_)
		v125_ = v125_ - v126_
	elseif #v124_ > 0 then
		local v128_ = posX + v119_.width
		for v129_ = #v124_, 1, -1 do
			local v130_ = v124_[v129_]
			local v131_ = self.keyButtonOverlay:getButtonWidth(v130_, v120_) + g_pixelSizeX
			v128_ = v128_ - v131_
			v125_ = v125_ - v131_
			self.keyButtonOverlay:renderButton(v130_, v128_, v121_, v120_, true)
		end
	end
	local v132_ = helpElement.iconOverlay
	if v132_ ~= nil then
		local v133_ = v120_ / g_screenAspectRatio
		v132_:renderCustom(posX + self.textOffsetX, v121_, v133_, v120_, 1, 1, 1, 1)
		return v121_
	end
	local v134_ = self.textOffsetX
	local v135_ = self.textOffsetY
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	local v136_ = utf8ToUpper(helpElement.text)
	local v137_ = Utils.limitTextToWidth(v136_, self.textSize, v125_ - 2 * v134_, false, "...")
	renderText(posX + v134_, v121_ + v135_, self.textSize, v137_)
	return v121_
end

-- Local values: buttons, isComboButtonMapping, keys, width, startPosX, startPosX, i, key, offset, keyWidth
function InputHelpDisplay:drawInput(posX, posY, height, helpElement, lastButtonCustomOffsetLeft, customButtonInputText)
	local v145_ = helpElement.buttons
	local v146_ = helpElement.isComboButtonMapping
	local v147_ = helpElement.keys
	local v148_ = 0
	if #v145_ <= 0 then
		if #v147_ > 0 then
			for v149_ = #v147_, 1, -1 do
				local v150_ = v147_[v149_]
				local v151_ = v149_ == #v147_ and lastButtonCustomOffsetLeft and lastButtonCustomOffsetLeft or 0
				local v152_ = self.keyButtonOverlay:getButtonWidth(v150_, height, v151_, customButtonInputText)
				local v153_ = posX - v152_
				v148_ = v148_ + v152_ + g_pixelSizeX
				self.keyButtonOverlay:renderButton(v150_, v153_, posY, height, true, nil, nil, nil, nil, v151_, customButtonInputText)
				posX = v153_ - g_pixelSizeX
			end
		end
		return v148_
	end
	local v154_ = self.glyphButtonOverlay:getButtonWidth(v145_, v146_, true, height, lastButtonCustomOffsetLeft, customButtonInputText)
	local v155_ = posX - v154_
	self.glyphButtonOverlay:renderButton(v145_, v146_, true, v155_, posY, height, false, nil, nil, nil, nil, lastButtonCustomOffsetLeft, customButtonInputText)
	return v154_
end

-- Local values: lineBg, posY, textOffsetX, textOffsetY, maxWidth
function InputHelpDisplay:drawExtraText(posX, posYTop, text)
	local v160_ = self.lineBg
	local v161_ = posYTop - v160_.height
	v160_:renderCustom(posX, v161_)
	local v162_ = self.textOffsetX
	local v163_ = self.textOffsetY
	local v164_ = v160_.width - 2 * v162_
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	local v165_ = utf8ToUpper(text)
	local v166_ = Utils.limitTextToWidth(v165_, self.textSize, v164_, false, "...")
	renderText(posX + v162_, v161_ + v163_, self.textSize, v166_)
	return v161_
end

-- Local values: vehicle, minX, maxX, vehicleControlPosY, lineBg, lineHeight, scale, scale, sizeX, _, overlayDesc, overlay, width, height, color, textPosX, textPosY
function InputHelpDisplay:drawVehicleSchema(posX, posY, isShortVersion)
	local v171_ = self.vehicle
	if v171_ == nil or v171_.schemaOverlay == nil then
		return posY, nil
	end
	self:getVehicleSchemaOverlays(v171_.rootVehicle)
	local v172_, v173_ = self:getSchemaDelimiters()
	local v174_
	if isShortVersion then
		v174_ = posY - self.lineBg.height
		local v175_ = v173_ - v172_ + 2 * self.schemaOffsetX - 2 * self.lineBgLeft.width
		self.lineBgScale:setDimension(v175_, nil)
		self.lineBgLeft:setPosition(posX, v174_)
		self.lineBgScale:setPosition(self.lineBgLeft.x + self.lineBgLeft.width, v174_)
		self.lineBgRight:setPosition(self.lineBgScale.x + self.lineBgScale.width, v174_)
		self.lineBgLeft:render()
		self.lineBgScale:render()
		self.lineBgRight:render()
	else
		v174_ = posY - self.comboBg.height
		self.comboBg:renderCustom(posX, v174_)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
		renderText(posX + self.comboTextOffsetX, v174_ + self.comboTextOffsetY, self.textSize, self.controlGroupText)
		self.separatorHorizontal:renderCustom(posX + self.comboSeparatorOffsetX, v174_ + self.comboSeparatorOffsetY)
	end
	local v176_ = v173_ - v172_
	local v177_ = self.maxSchemaWidth >= v176_ and 1 or self.maxSchemaWidth / v176_
	local v178_ = posX - v172_ + self.schemaOffsetX
	local v179_ = v174_ + self.schemaOffsetY
	for _, v180_ in ipairs(self.schemaOverlayEntryCache) do
		if v180_.isUsed then
			local v181_ = v180_.overlay
			local v182_ = v181_.width
			local v183_ = v181_.height
			v181_:setInvertX(v180_.invertX)
			v181_:setPosition(v178_ + v180_.x, v179_ + v180_.y)
			v181_:setRotation(v180_.rotation, 0, 0)
			v181_:setDimension(v182_ * v177_, v183_ * v177_)
			local v184_ = v180_.turnedOn and HUD.COLOR.ACTIVE or HUD.COLOR.DEFAULT
			v181_:setColor(v184_[1], v184_[2], v184_[3], v180_.selected and 1 or 0.5)
			v181_:render()
			if v180_.additionalText ~= nil then
				local v185_ = v178_ + v180_.x + v182_ * v177_ * 0.5
				local v186_ = v179_ + v180_.y + v183_ * v177_ * 0.85
				setTextBold(false)
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v185_, v186_, getCorrectTextSize(0.008), v180_.additionalText)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextColor(1, 1, 1, 1)
			end
			v181_:setDimension(v182_, v183_)
		end
		v180_.isUsed = false
	end
	self.schemaOverlayEntryCacheIndex = 0
	return v179_ - self.lineOffsetY, posY
end

function InputHelpDisplay:addSkipAction(actionName)
	self.skipActions[actionName] = true
end

function InputHelpDisplay:addHelpText(text)
	if self:getVisible() then
		local v191_ = self.extraHelpTexts
		table.insert(v191_, text)
	end
end

function InputHelpDisplay:addHelpExtension(extension)
	if self:getVisible() then
		table.addElement(self.helpExtensions, extension)
	end
end

function InputHelpDisplay:addInfoExtension(extension)
	if self:getVisible() then
		table.addElement(self.infoExtensions, extension)
	end
end

function InputHelpDisplay:removeInfoExtension(extension)
	table.removeElement(self.infoExtensions, extension)
end

function InputHelpDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end

-- Local values: inputDisplayManager, _, combo, actionName, helpElement, overlays, _, button
function InputHelpDisplay:updateGamepadComboButtons()
	local v201_ = g_inputDisplayManager
	self.gamepadComboOverlays = {}
	for _, v202_ in ipairs(InputBinding.ORDERED_GAMEPAD_COMBOS) do
		local v203_ = v202_.controls
		local v204_ = v201_:getControllerSymbolOverlays(v203_, "", "", false)
		local v205_ = {}
		for _, v206_ in ipairs(v204_.buttons) do
			table.insert(v205_, v206_)
		end
		local v207_ = self.gamepadComboOverlays
		local v208_ = {
			["actionName"] = v203_,
			["overlays"] = v205_,
			["mask"] = v202_.mask
		}
		table.insert(v207_, v208_)
	end
end

-- Local values: schemaName
function InputHelpDisplay:getSchemaOverlayForState(schemaOverlayData, isImplement, iconOverride)
	local v212_ = schemaOverlayData.schemaName
	local v213_ = v212_ == "DEFAULT_IMPLEMENT" and "IMPLEMENT" or (v212_ == "DEFAULT_VEHICLE" and "VEHICLE" or v212_)
	if not v213_ or (v213_ == "" or self.vehicleSchemaOverlays[v213_] == nil) then
		v213_ = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.IMPLEMENT or VehicleSchemaOverlayData.SCHEMA_OVERLAY.VEHICLE
	end
	return self.vehicleSchemaOverlays[v213_]
end

-- Local values: minX, maxX, _, overlayDesc, overlay, cosRot, sinRot, offX, dx, dy, x, dx2, dx3, dx4
function InputHelpDisplay:getSchemaDelimiters()
	local v215_ = -math.huge
	local v216_ = math.huge
	for _, v217_ in ipairs(self.schemaOverlayEntryCache) do
		if not v217_.isUsed then
			break
		end
		local v218_ = v217_.overlay
		local v219_ = v217_.rotation
		local v220_ = math.cos(v219_)
		local v221_ = v217_.rotation
		local v222_ = math.sin(v221_)
		local v223_ = v217_.invisibleBorderLeft * v218_.width
		local v224_ = v218_.width + (v217_.invisibleBorderRight + v217_.invisibleBorderLeft) * v218_.width
		local v225_ = v218_.height
		local v226_ = v217_.x + v223_ * v220_
		local v227_ = v224_ * v220_
		local v228_ = -v225_ * v222_
		local v229_ = v227_ + v228_
		local v230_ = v226_ + v227_
		local v231_ = v226_ + v228_
		local v232_ = v226_ + v229_
		v215_ = math.max(v215_, v226_, v230_, v231_, v232_)
		local v233_ = v226_ + v227_
		local v234_ = v226_ + v228_
		local v235_ = v226_ + v229_
		v216_ = math.min(v216_, v226_, v233_, v234_, v235_)
	end
	return v216_, v215_
end

-- Local values: overlay, entry
function InputHelpDisplay:getVehicleSchemaOverlays(vehicle)
	local v238_ = self:getSchemaOverlayForState(vehicle.schemaOverlay, false)
	local v239_ = self:getOrCreateEntry()
	v239_.isUsed = true
	v239_.overlay = v238_
	v239_.additionalText = vehicle:getAdditionalSchemaText()
	v239_.x = 0
	v239_.y = 0
	v239_.rotation = 0
	v239_.invertX = false
	v239_.invisibleBorderRight = vehicle.schemaOverlay.invisibleBorderRight
	v239_.invisibleBorderLeft = vehicle.schemaOverlay.invisibleBorderLeft
	v239_.turnedOn = vehicle:getUseTurnedOnSchema()
	v239_.selected = vehicle:getIsSelected()
	self:collectVehicleSchemaDisplayOverlays(1, vehicle, vehicle, v238_, 0, 0, 0, false)
	return v238_.height
end

-- Local values: attachedImplements, _, implement, object, selected, turnedOn, jointDesc, invertX, overlay, baseY, baseX, rot, offsetX, offsetY, rotatedX, rotatedY, isLowered, widthOffset, heightOffset, additionalText, entry
function InputHelpDisplay:collectVehicleSchemaDisplayOverlays(depth, vehicle, rootVehicle, parentOverlay, x, y, rotation, invertingX)
	if vehicle.getAttachedImplements ~= nil then
		local v249_ = vehicle:getAttachedImplements()
		for _, v250_ in pairs(v249_) do
			local v251_ = v250_.object
			if v251_ ~= nil and v251_.schemaOverlay ~= nil then
				local v252_ = v251_:getIsSelected()
				local v253_ = v251_:getUseTurnedOnSchema()
				local v254_ = vehicle.schemaOverlay.attacherJoints[v250_.jointDescIndex]
				if v254_ ~= nil then
					local v255_ = invertingX ~= v254_.invertX
					local v256_ = self:getSchemaOverlayForState(v251_.schemaOverlay, true)
					local v257_ = y + v254_.y * parentOverlay.height
					local v258_
					if v255_ then
						v258_ = x + v254_.x * parentOverlay.width
					else
						v258_ = x - v256_.width + (1 - v254_.x) * parentOverlay.width
					end
					local v259_ = rotation + v254_.rotation
					local v260_
					if v255_ then
						v260_ = -v251_.schemaOverlay.offsetX * v256_.width
					else
						v260_ = v251_.schemaOverlay.offsetX * v256_.width
					end
					local v261_ = v251_.schemaOverlay.offsetY * v256_.height
					local v262_ = v260_ * math.cos(v259_) - v261_ * math.sin(v259_)
					local v263_ = v260_ * math.sin(v259_) + v261_ * math.cos(v259_)
					local v264_ = v258_ - v262_
					local v265_ = v257_ - v263_
					local v266_
					if v251_.getIsLowered == nil then
						v266_ = false
					else
						v266_ = v251_:getIsLowered(true)
					end
					if not v266_ then
						local v267_, v268_ = getNormalizedScreenValues(v254_.liftedOffsetX, v254_.liftedOffsetY)
						v264_ = v264_ + v267_
						v265_ = v265_ + v268_ * 0.5
					end
					local v269_ = v251_:getAdditionalSchemaText()
					local v270_ = self:getOrCreateEntry()
					v270_.isUsed = true
					v270_.overlay = v256_
					v270_.additionalText = v269_
					v270_.x = v264_
					v270_.y = v265_
					v270_.rotation = v259_
					v270_.invertX = not v255_
					v270_.invisibleBorderRight = v251_.schemaOverlay.invisibleBorderRight
					v270_.invisibleBorderLeft = v251_.schemaOverlay.invisibleBorderLeft
					v270_.turnedOn = v253_
					v270_.selected = v252_
					if depth <= InputHelpDisplay.MAX_SCHEMA_COLLECTION_DEPTH then
						self:collectVehicleSchemaDisplayOverlays(depth + 1, v251_, rootVehicle, v256_, v264_, v265_, v259_, v255_)
					end
				end
			end
		end
	end
end

-- Local values: entry
function InputHelpDisplay:getOrCreateEntry()
	if self.schemaOverlayEntryCache == nil then
		self.schemaOverlayEntryCache = table.create(10)
		self.schemaOverlayEntryCacheIndex = 0
	end
	self.schemaOverlayEntryCacheIndex = self.schemaOverlayEntryCacheIndex + 1
	local v272_ = self.schemaOverlayEntryCache[self.schemaOverlayEntryCacheIndex]
	if v272_ == nil then
		v272_ = {
			["isUsed"] = false,
			["overlay"] = nil,
			["additionalText"] = nil,
			["x"] = 0,
			["y"] = 0,
			["rotation"] = 0,
			["invertX"] = false,
			["invisibleBorderRight"] = 0,
			["invisibleBorderLeft"] = 0,
			["turnedOn"] = false,
			["selected"] = false
		}
		local v273_ = self.schemaOverlayEntryCache
		table.insert(v273_, v272_)
	end
	return v272_
end

-- Local values: xmlFile, _, modDesc
function InputHelpDisplay:loadVehicleSchemaOverlays()
	local v275_ = loadXMLFile("VehicleSchemaDisplayOverlays", InputHelpDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH)
	self:loadVehicleSchemaOverlaysFromXML(v275_)
	delete(v275_)
	for _, v276_ in ipairs(g_modManager:getActiveMods()) do
		local v277_ = loadXMLFile("InputHelpDisplay ModFile", v276_.modFile)
		if v277_ ~= 0 then
			self:loadVehicleSchemaOverlaysFromXML(v277_, v276_.modFile)
			delete(v277_)
		end
	end
end

-- Local values: rootPath, baseDirectory, prefix, modName, dir, atlasPath, imageSize, i, baseName, baseOverlayName, uvString, uvs, sizeString, size, overlayName, atlasFileName, schemaOverlay
function InputHelpDisplay:loadVehicleSchemaOverlaysFromXML(xmlFile, modPath)
	local v281_, v282_, v283_
	if modPath then
		v281_, v282_ = Utils.getModNameAndBaseDirectory(modPath)
		v283_ = "modDesc.vehicleSchemaOverlays"
	else
		v283_ = "vehicleSchemaOverlays"
		v281_ = ""
		v282_ = ""
	end
	local v284_ = getXMLString(xmlFile, v283_ .. "#filename")
	local v285_ = string.getVector(getXMLString(xmlFile, v283_ .. "#imageSize"), 2) or { 1024, 1024 }
	local v286_ = 0
	while true do
		local v287_ = string.format("%s.overlay(%d)", v283_, v286_)
		if not hasXMLProperty(xmlFile, v287_) then
			break
		end
		local v288_ = getXMLString(xmlFile, v287_ .. "#name")
		local v289_ = getXMLString(xmlFile, v287_ .. "#uvs") or string.format("0px 0px %ipx %ipx", v285_[1], v285_[2])
		local v290_ = GuiUtils.getUVs(v289_, v285_)
		local v291_ = getXMLString(xmlFile, v287_ .. "#size") or "26px 26px"
		local v292_ = GuiUtils.getNormalizedValues(v291_, { 1, 1 })
		if v288_ then
			local v293_ = v281_ .. v288_
			local v294_ = Utils.getFilename(v284_, v282_)
			local v295_ = Overlay.new(v294_, 0, 0, v292_[1], v292_[2])
			v295_:setUVs(v290_)
			self.vehicleSchemaOverlays[v293_] = v295_
		end
		v286_ = v286_ + 1
	end
end

-- Local values: posX, posY
function InputHelpDisplay:getHelpAnchorPosition(typeId)
	local v297_, v298_ = self:getPosition()
	return v297_ + self.helpAnchorOffsetX, v298_ + self.helpAnchorOffsetY
end
if v1_ ~= nil then
	local v299_ = InputHelpDisplay.new()
	v299_:loadVehicleSchemaOverlays()
	v299_:setScale(v1_.uiScale)
	v299_:setVisible(v1_.isVisible)
	v299_:setVehicle(v1_.vehicle)
	g_currentMission.hud.inputHelp = v299_
	g_currentMission.hud.displayComponents.inputHelp = v299_
	Logging.info("Reloaded InputHelpDisplay")
end
