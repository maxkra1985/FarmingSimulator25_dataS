-- Local values: AISettingsDialog_mt
AISettingsDialog = {}
AISettingsDialog.LINE_COLORS = {}
AISettingsDialog.LINE_COLORS.BOUNDARY = {
	0.0273,
	0.0612,
	0.3324,
	1
}
AISettingsDialog.LINE_COLORS.HEADLAND = {
	0.2122,
	0.5029,
	0.402,
	1
}
AISettingsDialog.LINE_COLORS.STRAIGHT = {
	0.402,
	0.2051,
	0.0144,
	1
}
local AISettingsDialog_mt = Class(AISettingsDialog, MessageDialog)
function AISettingsDialog.register()
	local v2_ = AISettingsDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/AISettingsDialog.xml", "AISettingsDialog", v2_)
	AISettingsDialog.INSTANCE = v2_
end

-- Local values: dialog
function AISettingsDialog.show(aiUserSettings, fieldCourseSettings, vehicle, selectedMode, fieldX, fieldZ, callback, target)
	if AISettingsDialog.INSTANCE ~= nil then
		local v11_ = AISettingsDialog.INSTANCE
		v11_:setCallback(callback, target)
		v11_.aiUserSettings = aiUserSettings
		v11_.fieldCourseSettings = fieldCourseSettings
		v11_.vehicle = vehicle
		v11_.selectedMode = selectedMode
		v11_.fieldX = fieldX
		v11_.fieldZ = fieldZ
		g_gui:showDialog("AISettingsDialog")
	end
end

-- Upvalues: AISettingsDialog_mt
-- Local values: self
function AISettingsDialog.new(target, custom_mt)
	-- upvalues: (copy) AISettingsDialog_mt
	local v14_ = MessageDialog.new(target, custom_mt or AISettingsDialog_mt)
	v14_.ingameMapElement = nil
	v14_.selectedMode = 0
	v14_.fieldCourseUpdateTimer = 0
	v14_.lineWidth = 1 / g_screenHeight
	v14_.elementToSettingMapping = {}
	return v14_
end

-- Local values: aiUserSettings
function AISettingsDialog.createFromExistingGui(gui, guiName)
	AISettingsDialog.register()
	local v16_ = gui.aiUserSettings
	AISettingsDialog.show(v16_)
end

function AISettingsDialog:onGuiSetupFinished()
	AISettingsDialog:superClass().onGuiSetupFinished(self)
	self.templateBinarySetting:unlinkElement()
	self.templateMTOSetting:unlinkElement()
	self.templateSliderSetting:unlinkElement()
	FocusManager:removeElement(self.templateBinarySetting)
	FocusManager:removeElement(self.templateMTOSetting)
	FocusManager:removeElement(self.templateSliderSetting)
	self.modeElement:setTexts({ g_i18n:getText("ai_modeWorker"), g_i18n:getText("ai_modeSteeringAssist") })
end

function AISettingsDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end

function AISettingsDialog:sendCallback()
	self.aiUserSettings:apply(self.fieldCourseSettings, self.selectedMode)
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc(self.selectedMode, self.fieldCourseSettings)
		else
			self.callbackFunc(self.target, self.selectedMode, self.fieldCourseSettings)
		end
	end
	self:close()
end

function AISettingsDialog:delete()
	self.templateBinarySetting:delete()
	self.templateMTOSetting:delete()
	self.templateSliderSetting:delete()
	AISettingsDialog:superClass().delete(self)
end

function AISettingsDialog:update(dt)
	AISettingsDialog:superClass().update(self, dt)
	if self.fieldCourseUpdateTimer > 0 then
		self.fieldCourseUpdateTimer = self.fieldCourseUpdateTimer - dt
		if self.fieldCourseUpdateTimer <= 0 then
			self:updateFieldCourse()
		end
	end
end

-- Local values: mission
function AISettingsDialog:onOpen()
	AISettingsDialog:superClass().onOpen(self)
	self.isOpening = true
	if self.vehicle:getIsAutomaticSteeringAllowed() then
		self.modeElement:setDisabled(false)
	else
		self.selectedMode = AIModeSelection.MODE.WORKER
		self.modeElement:setDisabled(true)
	end
	self.modeElement:setIsChecked(self.selectedMode == AIModeSelection.MODE.STEERING_ASSIST, true)
	self:assignSettingsOptions()
	local v26_ = g_currentMission
	self.ingameMapElement.drawHotspots = false
	self.ingameMapElement:setIngameMap(v26_.hud:getIngameMap())
	self.ingameMapElement:onOpen()
	self:updateSettingsStates()
	self:updateFieldCourse()
	self.isOpening = false
end

function AISettingsDialog:onClose()
	AISettingsDialog:superClass().onClose(self)
	self.ingameMapElement:onClose()
	self.fieldCourse = nil
	self.aiUserSettings = nil
	self.fieldCourseSettings = nil
	self.vehicle = nil
	self.callbackFunc = nil
	self.target = nil
end

-- Local values: i, settings, firstOption, lastOption, isAlternate, index, settingData, clonedElement, isBinaryElement, option, texts, value, roundedValue, text, i, text, texts, value, text, index2, textElement
function AISettingsDialog:assignSettingsOptions()
	for v29_ = #self.settingsBox.elements, 1, -1 do
		self.settingsBox.elements[v29_]:delete()
		self.settingsBox.elements[v29_] = nil
	end
	self.elementToSettingMapping = {}
	if self.aiUserSettings == nil then
		return
	else
		local v30_ = self.aiUserSettings.settings[self.selectedMode]
		if v30_ ~= nil then
			local v31_ = true
			local v32_ = nil
			local v_u_33_ = nil
			for v34_, v35_ in pairs(v30_) do
				local v36_ = v35_.value
				local v37_
				if type(v36_) == "boolean" then
					v37_ = self.templateBinarySetting:clone(self.settingsBox)
				elseif v35_.useSlider then
					v37_ = self.templateSliderSetting:clone(self.settingsBox)
				else
					v37_ = self.templateMTOSetting:clone(self.settingsBox)
				end
				local v38_ = AISettingsDialog.COLOR_ALTERNATING[v31_]
				v37_:setImageColor(nil, unpack(v38_))
				v_u_33_ = v37_:getDescendantByName("option")
				if v35_.step == nil then
					if v35_.setting.valueTexts == nil then
						if v35_.setting.texts ~= nil then
							v_u_33_:setTexts(v35_.setting.texts)
						end
					else
						for v39_, v40_ in pairs(v35_.setting.valueTexts) do
							if string.endsWith(v40_, v35_.setting.defaultPostFix) then
								local v41_ = v35_.setting.valueTexts
								local v42_ = v35_.setting.defaultPostFix
								local v43_ = -string.len(v42_) - 2
								v41_[v39_] = string.sub(v40_, 1, v43_)
							end
						end
						local v44_ = {}
						if v35_.min == v35_.setting.min and v35_.max == v35_.setting.max then
							v44_ = v35_.setting.valueTexts
							local v45_ = v35_.setting.valueToTextIndex[v35_.defaultValue]
							if v45_ ~= nil then
								v44_[v45_] = v44_[v45_] .. " " .. v35_.setting.defaultPostFix
							end
						else
							for v46_ = v35_.min, v35_.max do
								local v47_ = v35_.setting.valueTexts[v35_.setting.valueToTextIndex[v46_]]
								if v46_ == v35_.defaultValue then
									v47_ = v47_ .. " " .. v35_.setting.defaultPostFix
								end
								table.insert(v44_, v47_)
							end
						end
						v_u_33_:setTexts(v44_)
						if v35_.setting.inputDelay ~= nil then
							v_u_33_.baseScrollDelayDuration = v35_.setting.inputDelay
						end
					end
				else
					local v48_ = {}
					for v49_ = v35_.min, v35_.max + v35_.step, v35_.step do
						local v50_, v51_
						if v35_.step < 1 then
							v50_ = MathUtil.round(v49_, 1)
							v51_ = string.format("%.1f", v50_)
						else
							v50_ = MathUtil.round(v49_, 0)
							v51_ = string.format("%d", v50_)
						end
						if v35_.setting.unitText ~= nil then
							v51_ = v51_ .. " " .. v35_.setting.unitText
						end
						if v35_.setting.defaultPostFix ~= nil and (v35_.defaultValue ~= nil and v50_ == MathUtil.round(v35_.defaultValue, 1)) then
							v51_ = v51_ .. " " .. v35_.setting.defaultPostFix
						end
						table.insert(v48_, v51_)
					end
					v_u_33_:setTexts(v48_)
					if v35_.setting.inputDelay ~= nil then
						v_u_33_.baseScrollDelayDuration = v35_.setting.inputDelay
					end
				end
				self.elementToSettingMapping[v_u_33_] = v35_
				local v52_ = v37_:getDescendantByName("name")
				v52_:setText(v35_.setting.title)
				function v52_.getIsFocused()
					-- upvalues: (copy) v_u_33_
					return v_u_33_:getIsFocused()
				end
				v31_ = not v31_
				if v34_ == 1 then
					v32_ = v_u_33_
				end
			end
			self.settingsBox:invalidateLayout()
			FocusManager:linkElements(self.modeElement, FocusManager.BOTTOM, v32_)
			FocusManager:linkElements(v32_, FocusManager.TOP, self.modeElement)
			FocusManager:linkElements(self.modeElement, FocusManager.TOP, v_u_33_)
			FocusManager:linkElements(v_u_33_, FocusManager.BOTTOM, self.modeElement)
			self:updateSettingsValues()
		end
	end
end

function AISettingsDialog:updateFieldCourseSettings()
	if self.fieldX ~= nil and self.fieldZ ~= nil then
		self.aiUserSettings:apply(self.fieldCourseSettings, self.selectedMode)
	end
end

function AISettingsDialog:updateFieldCourse()
	if self.vehicle:getCanStartFieldWork() or self.selectedMode ~= AIModeSelection.MODE.WORKER then
		if self.fieldX ~= nil and self.fieldZ ~= nil then
			self:updateFieldCourseSettings()
			if not self.fieldCourseLoading then
				if self.fieldCourse == nil then
					self.fieldCourseLoading = true
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						self.fieldCourseSettings:print()
					end
					FieldCourse.generateUICourseByFieldPosition(self.fieldX, self.fieldZ, self.fieldCourseSettings, function(p55_)
						-- upvalues: (copy) self
						self.fieldCourseLoading = false
						if self.vehicle ~= nil then
							if p55_ == nil then
								self.fieldCourse = nil
							else
								self.fieldCourse = p55_
								self.aiUserSettings:adjustToCourse(p55_, self.selectedMode)
								self:updateSettingsValues()
							end
							self:updateSettingsStates()
							self:updateMapState()
						end
					end)
				else
					self.fieldCourseLoading = true
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						self.fieldCourseSettings:print()
					end
					self.fieldCourse:updateFieldCourseSettings(self.fieldCourseSettings, function(p56_)
						-- upvalues: (copy) self
						self.fieldCourseLoading = false
						if self.vehicle ~= nil then
							if p56_ then
								if self.fieldCourse ~= nil then
									self.aiUserSettings:adjustToCourse(self.fieldCourse, self.selectedMode)
									self:updateSettingsValues()
								end
							else
								self.fieldCourse = nil
							end
							self:updateSettingsStates()
							self:updateMapState()
						end
					end)
				end
			end
		end
		self:updateMapState()
	else
		self.fieldCourse = nil
		self:updateMapState()
	end
end

-- Local values: isVineyardCourse, settingsAvailable, option, settingsData, option, settingsData
function AISettingsDialog:updateSettingsStates()
	local v58_
	if self.fieldCourse == nil then
		v58_ = false
	else
		v58_ = self.fieldCourse.isVineyardCourse
	end
	local v59_
	if self.selectedMode == AIModeSelection.MODE.STEERING_ASSIST then
		v59_ = self.vehicle:getIsAutomaticSteeringAllowed()
	else
		v59_ = self.vehicle:getCanStartFieldWork()
	end
	if v59_ then
		for v60_, v61_ in pairs(self.elementToSettingMapping) do
			v60_:setDisabled(v58_ and not v61_.setting.isVineyardSetting or v61_.setting:getIsDisabled(self.elementToSettingMapping))
		end
	else
		for v62_, v63_ in pairs(self.elementToSettingMapping) do
			v62_:setDisabled(v63_.setting:getIsDisabled(self.elementToSettingMapping))
		end
	end
end

-- Local values: option, settingData, isBinaryElement, selectedIndex, numTexts, value, roundedValue, selectedIndex, numTexts, value, selectedIndex, index, value
function AISettingsDialog:updateSettingsValues()
	for v65_, v66_ in pairs(self.elementToSettingMapping) do
		local v67_ = v66_.value
		local v68_ = type(v67_) == "boolean"
		if v66_.step == nil then
			if v66_.setting.valueTexts == nil then
				if v66_.setting.texts == nil then
					if v68_ then
						v65_:setIsChecked(v66_.value, self.isOpening)
					end
				else
					local v69_ = 1
					for v70_, v71_ in ipairs(v66_.setting.textMapping) do
						if type(v71_) == "boolean" then
							if v71_ == v66_.value then
								v69_ = v70_
								break
							end
						elseif MathUtil.round(v71_, 2) == MathUtil.round(v66_.value, 2) then
							v69_ = v70_
							break
						end
					end
					if v68_ then
						v65_:setIsChecked(v69_ == 2, self.isOpening)
					else
						v65_:setState(v69_)
					end
				end
			else
				local v72_ = 1
				local v73_ = 1
				if v66_.min == v66_.setting.min and v66_.max == v66_.setting.max then
					v72_ = v66_.setting.valueToTextIndex[v66_.value] or v72_
				else
					for v74_ = v66_.min, v66_.max do
						if v74_ == v66_.value then
							v72_ = v73_
						end
						v73_ = v73_ + 1
					end
				end
				v65_:setState(v72_)
			end
		else
			local v75_ = 0
			local v76_ = 1
			for v77_ = v66_.min, v66_.max + v66_.step, v66_.step do
				local v78_
				if v66_.step < 1 then
					v78_ = MathUtil.round(v77_, 1)
				else
					v78_ = MathUtil.round(v77_, 0)
				end
				v75_ = v75_ + 1
				if v78_ == MathUtil.round(v66_.value, 1) then
					v76_ = v75_
				end
			end
			v65_:setState(v76_)
		end
	end
end

-- Local values: x, _, z, minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ, x, _, z, settings, _, settingData
function AISettingsDialog:updateMapState()
	if self.fieldCourseLoading then
		self.ingameMapElement:setMapAlpha(1)
		if self.fieldCourse == nil then
			local v80_, _, v81_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			self.ingameMapElement:setCenterToWorldPosition(v80_, v81_)
			self.ingameMapElement:setMapZoom(10)
		end
		self.loadingAnimation:setVisible(true)
		self.noFieldFoundText:setVisible(false)
		self.fieldNotSupportedText:setVisible(false)
	elseif self.fieldCourse == nil then
		local v82_, _, v83_ = getWorldTranslation(g_cameraManager:getActiveCamera())
		self.ingameMapElement:setCenterToWorldPosition(v82_, v83_)
		self.ingameMapElement:setMapZoom(10)
		self.ingameMapElement:setMapAlpha(0.25)
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(true)
		self.fieldNotSupportedText:setVisible(false)
	else
		local v84_, v85_, v86_, v87_ = self.fieldCourse.courseField:getBoundingBox()
		self.ingameMapElement:fitToBoundary(v84_, v85_, v86_, v87_, 0.1)
		self.ingameMapElement:setMapAlpha(1)
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(false)
		self.fieldNotSupportedText:setVisible(false)
		if self.fieldCourse.isVineyardCourse and self.selectedMode == AIModeSelection.MODE.WORKER then
			self.fieldNotSupportedText:setVisible(true)
		end
	end
	self.workDirectionArrow:setVisible(false)
	local v88_ = self.aiUserSettings.settings[self.selectedMode]
	for _, v89_ in pairs(v88_) do
		if v89_.setting.identifier == "workDirection" and v89_.value >= 0 then
			self.workDirectionArrow:setVisible(true)
			local v90_ = self.workDirectionArrow
			local v91_ = v89_.value
			v90_:setImageRotation(3.141592653589793 + math.rad(v91_))
		end
	end
end

-- Local values: i, pos1, pos2, x1, y1, x2, y2
function AISettingsDialog:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, positions, color)
	for v100_ = 1, #positions - 1 do
		local v101_ = positions[v100_]
		local v102_ = positions[v100_ + 1]
		local v103_ = ((v101_[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local v104_ = (1 - ((v101_[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		local v105_ = ((v102_[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local v106_ = (1 - ((v102_[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		drawLine2D(v103_, v104_, v105_, v106_, self.lineWidth, color[1], color[2], color[3], color[4])
	end
end

-- Local values: posX, posY, sizeX, sizeZ, fieldCourseSettings, boundary, _, segment, i, segment
function AISettingsDialog:onDrawPostIngameMapHotspots(element, ingameMap)
	local v109_, v110_ = self.ingameMapElement:getMapPosition()
	local v111_, v112_ = self.ingameMapElement:getMapSize()
	if self.fieldCourse ~= nil and self.fieldCourse.courseField ~= nil then
		local v113_ = self.fieldCourseSettings
		self:drawLineOnMap(ingameMap, v109_, v110_, v111_, v112_, self.fieldCourse.courseField.fieldRootBoundary.boundaryLine, AISettingsDialog.LINE_COLORS.BOUNDARY)
		for _, v114_ in ipairs(self.fieldCourse.segments) do
			if v114_.isHeadlandSegment or v114_.isIslandSegment then
				if v113_.workHeadlands then
					self:drawLineOnMap(ingameMap, v109_, v110_, v111_, v112_, v114_.positions, AISettingsDialog.LINE_COLORS.HEADLAND)
				end
			elseif v113_.skipNumLines == 0 then
				self:drawLineOnMap(ingameMap, v109_, v110_, v111_, v112_, v114_.positions, AISettingsDialog.LINE_COLORS.STRAIGHT)
			end
		end
		if v113_.skipNumLines > 0 then
			for v115_ = #self.fieldCourse.segments, 1, -1 do
				local v116_ = self.fieldCourse.segments[v115_]
				if v116_.lineGroupIndex ~= nil and (v116_.offsetLineIndex - 1) % (v113_.skipNumLines + 1) == 0 then
					self:drawLineOnMap(ingameMap, v109_, v110_, v111_, v112_, v116_.positions, AISettingsDialog.LINE_COLORS.STRAIGHT)
				end
			end
		end
	end
end

function AISettingsDialog:onClickMode(state, element)
	self.selectedMode = state == 2 and AIModeSelection.MODE.STEERING_ASSIST or AIModeSelection.MODE.WORKER
	self:assignSettingsOptions()
	self:updateFieldCourse()
	self:updateSettingsStates()
end

-- Local values: settingData, settingFunction
function AISettingsDialog:onClickOption(state, element)
	local v121_ = self.elementToSettingMapping[element]
	local v122_ = v121_.callback
	if v122_ ~= nil then
		if v122_(v121_.target, element.texts[element:getState()], element:getState()) then
			self.fieldCourseUpdateTimer = 1000
			self:updateMapState()
		else
			self:updateFieldCourseSettings()
		end
		if v121_.setting:onSettingsChanged(v121_, self.elementToSettingMapping) then
			self:updateSettingsValues()
		end
		self:updateSettingsStates()
	end
end

-- Local values: settingData, settingFunction
function AISettingsDialog:onClickBinary(state, element)
	local v125_ = self.elementToSettingMapping[element]
	local v126_ = v125_.callback
	if v126_ ~= nil then
		if v126_(v125_.target, element:getIsChecked(), element:getIsChecked() and 2 or 1) then
			self.fieldCourseUpdateTimer = 1000
			self:updateMapState()
		else
			self:updateFieldCourseSettings()
		end
		if v125_.setting:onSettingsChanged(v125_, self.elementToSettingMapping) then
			self:updateSettingsValues()
		end
		self:updateSettingsStates()
	end
end

function AISettingsDialog:onClickOk(state, element)
	self:sendCallback()
end

function AISettingsDialog:onClickReset(state, element)
	self.fieldCourseSettings:reset(self.vehicle)
	self.aiUserSettings:reinitialize(self.fieldCourseSettings, true)
	self:assignSettingsOptions()
	self:updateFieldCourse()
	self:updateSettingsStates()
end
AISettingsDialog.COLOR_ALTERNATING = {
	[true] = {
		0.02956,
		0.02956,
		0.02956,
		0.6
	},
	[false] = {
		0.02956,
		0.02956,
		0.02956,
		0.2
	}
}
