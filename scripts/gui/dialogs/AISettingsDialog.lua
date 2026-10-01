AISettingsDialog = {}
AISettingsDialog.LINE_COLORS = {}
AISettingsDialog.LINE_COLORS.BOUNDARY = { 0.0273, 0.0612, 0.3324, 1 }
AISettingsDialog.LINE_COLORS.HEADLAND = { 0.2122, 0.5029, 0.402, 1 }
AISettingsDialog.LINE_COLORS.STRAIGHT = { 0.402, 0.2051, 0.0144, 1 }
local AISettingsDialog_mt = Class(AISettingsDialog, MessageDialog)
function AISettingsDialog.register()
	local aiSettingsDialog = AISettingsDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/AISettingsDialog.xml", "AISettingsDialog", aiSettingsDialog)
	AISettingsDialog.INSTANCE = aiSettingsDialog
end
function AISettingsDialog.show(aiUserSettings, fieldCourseSettings, vehicle, selectedMode, fieldX, fieldZ, callback, target)
	if AISettingsDialog.INSTANCE ~= nil then
		local dialog = AISettingsDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog.aiUserSettings = aiUserSettings
		dialog.fieldCourseSettings = fieldCourseSettings
		dialog.vehicle = vehicle
		dialog.selectedMode = selectedMode
		dialog.fieldX = fieldX
		dialog.fieldZ = fieldZ
		g_gui:showDialog("AISettingsDialog")
	end
end
function AISettingsDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or AISettingsDialog_mt)
	self.ingameMapElement = nil
	self.selectedMode = 0
	self.fieldCourseUpdateTimer = 0
	self.lineWidth = 1 / g_screenHeight
	self.elementToSettingMapping = {}
	return self
end
function AISettingsDialog.createFromExistingGui(gui, guiName)
	AISettingsDialog.register()
	local aiUserSettings = gui.aiUserSettings
	AISettingsDialog.show(aiUserSettings)
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
		if self.target ~= nil then
			self.callbackFunc(self.target, self.selectedMode, self.fieldCourseSettings)
		else
			self.callbackFunc(self.selectedMode, self.fieldCourseSettings)
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
	if 0 < self.fieldCourseUpdateTimer then
		self.fieldCourseUpdateTimer = self.fieldCourseUpdateTimer - dt
		if self.fieldCourseUpdateTimer <= 0 then
			self:updateFieldCourse()
		end
	end
end
function AISettingsDialog:onOpen()
	AISettingsDialog:superClass().onOpen(self)
	self.isOpening = true
	if not self.vehicle:getIsAutomaticSteeringAllowed() then
		self.selectedMode = AIModeSelection.MODE.WORKER
		self.modeElement:setDisabled(true)
	else
		self.modeElement:setDisabled(false)
	end
	self.modeElement:setIsChecked(self.selectedMode == AIModeSelection.MODE.STEERING_ASSIST, true)
	self:assignSettingsOptions()
	local mission = g_currentMission
	self.ingameMapElement.drawHotspots = false
	self.ingameMapElement:setIngameMap(mission.hud:getIngameMap())
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
function AISettingsDialog:assignSettingsOptions()
	for i = #self.settingsBox.elements, 1, -1 do
		self.settingsBox.elements[i]:delete()
		self.settingsBox.elements[i] = nil
	end
	self.elementToSettingMapping = {}
	if self.aiUserSettings == nil then
		return
	end
	local settings = self.aiUserSettings.settings[self.selectedMode]
	if settings == nil then
		return
	else
		local firstOption = nil
		local lastOption = nil
		local isAlternate = true
		for index, settingData in pairs(settings) do
			local clonedElement = nil
			local isBinaryElement = type(settingData.value) == "boolean"
			if isBinaryElement then
				clonedElement = self.templateBinarySetting:clone(self.settingsBox)
			elseif settingData.useSlider then
				clonedElement = self.templateSliderSetting:clone(self.settingsBox)
			else
				clonedElement = self.templateMTOSetting:clone(self.settingsBox)
			end
			clonedElement:setImageColor(nil, unpack(AISettingsDialog.COLOR_ALTERNATING[isAlternate]))
			local option = clonedElement:getDescendantByName("option")
			if settingData.step ~= nil then
				local texts = {}
				for value = settingData.min, settingData.max + settingData.step, settingData.step do
					local roundedValue = nil
					local text = nil
					if settingData.step < 1 then
						roundedValue = MathUtil.round(value, 1)
						text = string.format("%.1f", roundedValue)
					else
						roundedValue = MathUtil.round(value, 0)
						text = string.format("%d", roundedValue)
					end
					if settingData.setting.unitText ~= nil then
						text = text .. " " .. settingData.setting.unitText
					end
					if settingData.setting.defaultPostFix ~= nil and (settingData.defaultValue ~= nil and roundedValue == MathUtil.round(settingData.defaultValue, 1)) then
						text = text .. " " .. settingData.setting.defaultPostFix
					end
					table.insert(texts, text)
				end
				option:setTexts(texts)
				if settingData.setting.inputDelay ~= nil then
					option.baseScrollDelayDuration = settingData.setting.inputDelay
				end
			elseif settingData.setting.valueTexts ~= nil then
				for i, text in pairs(settingData.setting.valueTexts) do
					if string.endsWith(text, settingData.setting.defaultPostFix) then
						settingData.setting.valueTexts[i] = string.sub(text, 1, -string.len(settingData.setting.defaultPostFix) - 2)
					end
				end
				local texts = {}
				if settingData.min ~= settingData.setting.min or settingData.max ~= settingData.setting.max then
					for value = settingData.min, settingData.max do
						local text = settingData.setting.valueTexts[settingData.setting.valueToTextIndex[value]]
						if value == settingData.defaultValue then
							text = text .. " " .. settingData.setting.defaultPostFix
						end
						table.insert(texts, text)
					end
				else
					texts = settingData.setting.valueTexts
					local index2 = settingData.setting.valueToTextIndex[settingData.defaultValue]
					if index2 ~= nil then
						texts[index2] = texts[index2] .. " " .. settingData.setting.defaultPostFix
					end
				end
				option:setTexts(texts)
				if settingData.setting.inputDelay ~= nil then
					option.baseScrollDelayDuration = settingData.setting.inputDelay
				end
			elseif settingData.setting.texts ~= nil then
				option:setTexts(settingData.setting.texts)
			end
			self.elementToSettingMapping[option] = settingData
			local textElement = clonedElement:getDescendantByName("name")
			textElement:setText(settingData.setting.title)
			function textElement.getIsFocused()
				return option:getIsFocused()
			end
			isAlternate = not isAlternate
			if index == 1 then
				firstOption = option
			end
			lastOption = option
		end
		self.settingsBox:invalidateLayout()
		FocusManager:linkElements(self.modeElement, FocusManager.BOTTOM, firstOption)
		FocusManager:linkElements(firstOption, FocusManager.TOP, self.modeElement)
		FocusManager:linkElements(self.modeElement, FocusManager.TOP, lastOption)
		FocusManager:linkElements(lastOption, FocusManager.BOTTOM, self.modeElement)
		self:updateSettingsValues()
	end
end
function AISettingsDialog:updateFieldCourseSettings()
	if self.fieldX ~= nil and self.fieldZ ~= nil then
		self.aiUserSettings:apply(self.fieldCourseSettings, self.selectedMode)
	end
end
function AISettingsDialog:updateFieldCourse()
	if not self.vehicle:getCanStartFieldWork() and self.selectedMode == AIModeSelection.MODE.WORKER then
		self.fieldCourse = nil
		self:updateMapState()
		return
	end
	if self.fieldX ~= nil and self.fieldZ ~= nil then
		self:updateFieldCourseSettings()
		if not self.fieldCourseLoading then
			if self.fieldCourse == nil then
				self.fieldCourseLoading = true
				if VehicleDebug.state == VehicleDebug.DEBUG_AI then
					self.fieldCourseSettings:print()
				end
				FieldCourse.generateUICourseByFieldPosition(self.fieldX, self.fieldZ, self.fieldCourseSettings, function(fieldCourse)
					self.fieldCourseLoading = false
					if self.vehicle == nil then
						return
					else
						if fieldCourse ~= nil then
							self.fieldCourse = fieldCourse
							self.aiUserSettings:adjustToCourse(fieldCourse, self.selectedMode)
							self:updateSettingsValues()
						else
							self.fieldCourse = nil
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
				self.fieldCourse:updateFieldCourseSettings(self.fieldCourseSettings, function(success)
					self.fieldCourseLoading = false
					if self.vehicle == nil then
						return
					else
						if not success then
							self.fieldCourse = nil
						elseif self.fieldCourse ~= nil then
							self.aiUserSettings:adjustToCourse(self.fieldCourse, self.selectedMode)
							self:updateSettingsValues()
						end
						self:updateSettingsStates()
						self:updateMapState()
					end
				end)
			end
		end
	end
	self:updateMapState()
end
function AISettingsDialog:updateSettingsStates()
	local isVineyardCourse = false
	if self.fieldCourse ~= nil then
		isVineyardCourse = self.fieldCourse.isVineyardCourse
	end
	local settingsAvailable = true
	if self.selectedMode == AIModeSelection.MODE.STEERING_ASSIST then
		settingsAvailable = self.vehicle:getIsAutomaticSteeringAllowed()
	else
		settingsAvailable = self.vehicle:getCanStartFieldWork()
	end
	if not settingsAvailable then
		for option, settingsData in pairs(self.elementToSettingMapping) do
			option:setDisabled(settingsData.setting:getIsDisabled(self.elementToSettingMapping))
		end
	else
		for option, settingsData in pairs(self.elementToSettingMapping) do
			option:setDisabled(isVineyardCourse and not settingsData.setting.isVineyardSetting or settingsData.setting:getIsDisabled(self.elementToSettingMapping))
		end
	end
end
function AISettingsDialog:updateSettingsValues()
	for option, settingData in pairs(self.elementToSettingMapping) do
		local isBinaryElement = type(settingData.value) == "boolean"
		if settingData.step ~= nil then
			local selectedIndex = 1
			local numTexts = 0
			for value = settingData.min, settingData.max + settingData.step, settingData.step do
				local roundedValue = nil
				if settingData.step < 1 then
					roundedValue = MathUtil.round(value, 1)
				else
					roundedValue = MathUtil.round(value, 0)
				end
				numTexts = numTexts + 1
				if roundedValue == MathUtil.round(settingData.value, 1) then
					selectedIndex = numTexts
				end
			end
			option:setState(selectedIndex)
		elseif settingData.setting.valueTexts ~= nil then
			local selectedIndex = 1
			local numTexts = 1
			if settingData.min ~= settingData.setting.min or settingData.max ~= settingData.setting.max then
				for value = settingData.min, settingData.max do
					if value == settingData.value then
						selectedIndex = numTexts
					end
					numTexts = numTexts + 1
				end
			else
				selectedIndex = settingData.setting.valueToTextIndex[settingData.value] or selectedIndex
			end
			option:setState(selectedIndex)
		elseif settingData.setting.texts ~= nil then
			local selectedIndex = 1
			for index, value in ipairs(settingData.setting.textMapping) do
				if type(value) == "boolean" then
					if value == settingData.value then
						selectedIndex = index
						break
					end
				elseif MathUtil.round(value, 2) == MathUtil.round(settingData.value, 2) then
					selectedIndex = index
					break
				end
				if isBinaryElement then
					option:setIsChecked(selectedIndex == 2, self.isOpening)
				else
					option:setState(selectedIndex)
				end
			end
		elseif isBinaryElement then
			option:setIsChecked(settingData.value, self.isOpening)
		end
	end
end
function AISettingsDialog:updateMapState()
	if self.fieldCourseLoading then
		self.ingameMapElement:setMapAlpha(1)
		if self.fieldCourse == nil then
			local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
			self.ingameMapElement:setCenterToWorldPosition(x, z)
			self.ingameMapElement:setMapZoom(10)
		end
		self.loadingAnimation:setVisible(true)
		self.noFieldFoundText:setVisible(false)
		self.fieldNotSupportedText:setVisible(false)
	elseif self.fieldCourse ~= nil then
		local minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ = self.fieldCourse.courseField:getBoundingBox()
		self.ingameMapElement:fitToBoundary(minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ, 0.1)
		self.ingameMapElement:setMapAlpha(1)
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(false)
		self.fieldNotSupportedText:setVisible(false)
		if self.fieldCourse.isVineyardCourse and self.selectedMode == AIModeSelection.MODE.WORKER then
			self.fieldNotSupportedText:setVisible(true)
		end
	else
		local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
		self.ingameMapElement:setCenterToWorldPosition(x, z)
		self.ingameMapElement:setMapZoom(10)
		self.ingameMapElement:setMapAlpha(0.25)
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(true)
		self.fieldNotSupportedText:setVisible(false)
	end
	self.workDirectionArrow:setVisible(false)
	local settings = self.aiUserSettings.settings[self.selectedMode]
	for _, settingData in pairs(settings) do
		if settingData.setting.identifier == "workDirection" and 0 <= settingData.value then
			self.workDirectionArrow:setVisible(true)
			self.workDirectionArrow:setImageRotation(3.141592653589793 + math.rad(settingData.value))
		end
	end
end
function AISettingsDialog:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, positions, color)
	for i = 1, #positions - 1 do
		local pos1 = positions[i]
		local pos2 = positions[i + 1]
		local x1 = ((pos1[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local y1 = (1 - ((pos1[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		local x2 = ((pos2[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local y2 = (1 - ((pos2[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		drawLine2D(x1, y1, x2, y2, self.lineWidth, color[1], color[2], color[3], color[4])
	end
end
function AISettingsDialog:onDrawPostIngameMapHotspots(element, ingameMap)
	local posX, posY = self.ingameMapElement:getMapPosition()
	local sizeX, sizeZ = self.ingameMapElement:getMapSize()
	if self.fieldCourse ~= nil and self.fieldCourse.courseField ~= nil then
		local fieldCourseSettings = self.fieldCourseSettings
		local boundary = self.fieldCourse.courseField.fieldRootBoundary.boundaryLine
		self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, boundary, AISettingsDialog.LINE_COLORS.BOUNDARY)
		for _, segment in ipairs(self.fieldCourse.segments) do
			if segment.isHeadlandSegment or segment.isIslandSegment then
				if fieldCourseSettings.workHeadlands then
					self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, AISettingsDialog.LINE_COLORS.HEADLAND)
				end
			else
				if fieldCourseSettings.skipNumLines == 0 then
					self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, AISettingsDialog.LINE_COLORS.STRAIGHT)
				end
			end
		end
		if 0 < fieldCourseSettings.skipNumLines then
			for i = #self.fieldCourse.segments, 1, -1 do
				local segment = self.fieldCourse.segments[i]
				if segment.lineGroupIndex == nil then
					continue
				end
				if (segment.offsetLineIndex - 1) % (fieldCourseSettings.skipNumLines + 1) == 0 then
					self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, AISettingsDialog.LINE_COLORS.STRAIGHT)
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
function AISettingsDialog:onClickOption(state, element)
	local settingData = self.elementToSettingMapping[element]
	local settingFunction = settingData.callback
	if settingFunction ~= nil then
		if settingFunction(settingData.target, element.texts[element:getState()], element:getState()) then
			self.fieldCourseUpdateTimer = 1000
			self:updateMapState()
		else
			self:updateFieldCourseSettings()
		end
		if settingData.setting:onSettingsChanged(settingData, self.elementToSettingMapping) then
			self:updateSettingsValues()
		end
		self:updateSettingsStates()
	end
end
function AISettingsDialog:onClickBinary(state, element)
	local settingData = self.elementToSettingMapping[element]
	local settingFunction = settingData.callback
	if settingFunction ~= nil then
		if settingFunction(settingData.target, element:getIsChecked(), element:getIsChecked() and 2 or 1) then
			self.fieldCourseUpdateTimer = 1000
			self:updateMapState()
		else
			self:updateFieldCourseSettings()
		end
		if settingData.setting:onSettingsChanged(settingData, self.elementToSettingMapping) then
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
AISettingsDialog.COLOR_ALTERNATING = { [true] = { 0.02956, 0.02956, 0.02956, 0.6 }, [false] = { 0.02956, 0.02956, 0.02956, 0.2 } }
