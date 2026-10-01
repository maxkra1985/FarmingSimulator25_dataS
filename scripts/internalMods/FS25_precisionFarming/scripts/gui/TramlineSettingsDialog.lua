TramlineSettingsDialog = {}
TramlineSettingsDialog.MOD_DIR = g_currentModDirectory
TramlineSettingsDialog.LINE_COLORS = {}
TramlineSettingsDialog.LINE_COLORS.BOUNDARY = { 0.0273, 0.0612, 0.3324, 1 }
TramlineSettingsDialog.LINE_COLORS.HEADLAND = { 0.2122, 0.5029, 0.402, 1 }
TramlineSettingsDialog.LINE_COLORS.STRAIGHT = { 0.402, 0.2051, 0.0144, 1 }
local TramlineSettingsDialog_mt = Class(TramlineSettingsDialog, MessageDialog)
function TramlineSettingsDialog.register()
	local tramlineSettingsDialog = TramlineSettingsDialog.new()
	g_gui:loadGui(TramlineSettingsDialog.MOD_DIR .. "gui/TramlineSettingsDialog.xml", "TramlineSettingsDialog", tramlineSettingsDialog)
	TramlineSettingsDialog.INSTANCE = tramlineSettingsDialog
end
function TramlineSettingsDialog.show(implementWidthIndex, workDirectionIndex, spacingIndex, fieldX, fieldZ, callback)
	if TramlineSettingsDialog.INSTANCE ~= nil then
		local dialog = TramlineSettingsDialog.INSTANCE
		dialog:setCallback(callback)
		dialog.implementWidthIndex = implementWidthIndex
		dialog.workDirectionIndex = workDirectionIndex
		dialog.spacingIndex = spacingIndex
		dialog.fieldX = fieldX
		dialog.fieldZ = fieldZ
		g_gui:showDialog("TramlineSettingsDialog")
	end
end
function TramlineSettingsDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or TramlineSettingsDialog_mt)
	self.ingameMapElement = nil
	self.fieldCourseUpdateTimer = 0
	self.lineWidth = 1 / g_screenHeight
	self.farmlands = {}
	self.farmlandText = g_i18n:getText("contract_farmland")
	self.fieldCourseSettings = FieldCourseSettings.new()
	self.fieldCourseSettings.implementWidth = 27
	self.fieldCourseSettings.numHeadlands = 1
	self.fieldCourseSettings.segmentExtendedToBoundary = true
	self.fieldCourseSettings.segmentHeadlandReverseLines = true
	self.fieldCourseSettings.segmentMinOffset = 3
	self.fieldCourseSettings.segmentMinLength = 25
	return self
end
function TramlineSettingsDialog.createFromExistingGui(gui, guiName)
	TramlineSettingsDialog.register()
	local aiUserSettings = gui.aiUserSettings
	TramlineSettingsDialog.show(aiUserSettings)
end
function TramlineSettingsDialog:onGuiSetupFinished()
	TramlineSettingsDialog:superClass().onGuiSetupFinished(self)
end
function TramlineSettingsDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end
function TramlineSettingsDialog:sendCallback(applyChanges)
	self:close()
	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, applyChanges, self.farmlands, self.implementWidthIndex, self.workDirectionIndex, self.spacingIndex)
		else
			self.callbackFunc(applyChanges, self.farmlands, self.implementWidthIndex, self.workDirectionIndex, self.spacingIndex)
		end
	end
	self.callbackFunc = nil
	self.target = nil
end
function TramlineSettingsDialog:delete()
	TramlineSettingsDialog:superClass().delete(self)
end
function TramlineSettingsDialog:update(dt)
	TramlineSettingsDialog:superClass().update(self, dt)
	if 0 < self.fieldCourseUpdateTimer then
		self.fieldCourseUpdateTimer = self.fieldCourseUpdateTimer - dt
		if self.fieldCourseUpdateTimer <= 0 then
			self:updateFieldCourse()
		end
	end
end
function TramlineSettingsDialog:onOpen()
	TramlineSettingsDialog:superClass().onOpen(self)
	self.isOpening = true
	local mission = g_currentMission
	self.ingameMapElement.drawHotspots = false
	self.ingameMapElement:setIngameMap(mission.hud:getIngameMap())
	self.ingameMapElement:onOpen()
	self.okButton:setDisabled(true)
	self:updateSettingsValues()
	self:updateFieldCourse()
	self.isOpening = false
end
function TramlineSettingsDialog:onClose()
	TramlineSettingsDialog:superClass().onClose(self)
	self.ingameMapElement:onClose()
	self.fieldCourse = nil
	self.fieldCourseLoading = false
end
function TramlineSettingsDialog:updateSettingsValues()
	local tramlineMap = g_precisionFarming.tramlineMap
	if tramlineMap ~= nil then
		self.implementWidthOption:setTexts(tramlineMap.implementWidthTexts)
		self.workDirectionOption:setTexts(tramlineMap.workDirectionTexts)
		self.spacingOption:setTexts(tramlineMap.spacingTexts)
	end
	self.implementWidthOption:setState(self.implementWidthIndex)
	self.workDirectionOption:setState(self.workDirectionIndex)
	self.spacingOption:setState(self.spacingIndex)
	self.implementWidthOption.parent:setImageColor(nil, unpack(TramlineSettingsDialog.COLOR_ALTERNATING[false]))
	self.workDirectionOption.parent:setImageColor(nil, unpack(TramlineSettingsDialog.COLOR_ALTERNATING[true]))
	self.spacingOption.parent:setImageColor(nil, unpack(TramlineSettingsDialog.COLOR_ALTERNATING[false]))
end
function TramlineSettingsDialog:updateFieldCourse()
	local tramlineMap = g_precisionFarming.tramlineMap
	if tramlineMap ~= nil then
		if 1 < self.implementWidthIndex then
			local implementWidth = tramlineMap.implementWidths[self.implementWidthIndex]
			self.fieldCourseSettings.implementWidth = implementWidth
		else
			self.fieldCourseSettings.implementWidth = tramlineMap.implementWidths[2]
		end
		local workDirection = tramlineMap.workDirectionTextToDeg[self.workDirectionIndex]
		self.fieldCourseSettings.workDirection = math.rad(workDirection)
	end
	if self.fieldX ~= nil and (self.fieldZ ~= nil and not self.fieldCourseLoading) then
		if self.fieldCourse == nil then
			self.fieldCourseLoading = true
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self.fieldCourseSettings:print()
			end
			FieldCourse.generateUICourseByFieldPosition(self.fieldX, self.fieldZ, self.fieldCourseSettings, function(fieldCourse)
				self.fieldCourseLoading = false
				if self.callbackFunc == nil then
					return
				else
					if fieldCourse ~= nil then
						self.fieldCourse = fieldCourse
					else
						self.fieldCourse = nil
					end
					self:updateMapState()
					self:updateFarmlands()
				end
			end)
		else
			self.fieldCourseLoading = true
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self.fieldCourseSettings:print()
			end
			self.fieldCourse:updateFieldCourseSettings(self.fieldCourseSettings, function(success)
				self.fieldCourseLoading = false
				if self.callbackFunc == nil then
					return
				else
					if not success then
						self.fieldCourse = nil
					end
					self:updateMapState()
					self:updateFarmlands()
				end
			end)
		end
	end
	self:updateMapState()
end
function TramlineSettingsDialog:updateFarmlands()
	self.farmlands = {}
	if self.fieldCourse ~= nil then
		local boundary = self.fieldCourse.courseField.fieldRootBoundary.boundaryLine
		local farmlands = g_farmlandManager:getFarmlands()
		for _, farmland in ipairs(farmlands) do
			local x, z = farmland:getIndicatorPosition()
			if FieldCourseUtil.getIsPointInsideBoundary(x, z, boundary) then
				table.insert(self.farmlands, farmland)
			end
		end
	end
	self.okButton:setDisabled(#self.farmlands == 0)
end
function TramlineSettingsDialog:updateMapState()
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
		self.tramlinesDisabledText:setVisible(false)
	elseif self.implementWidthIndex == 1 then
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(false)
		self.fieldNotSupportedText:setVisible(false)
		self.tramlinesDisabledText:setVisible(true)
	elseif self.fieldCourse ~= nil then
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(false)
		self.fieldNotSupportedText:setVisible(false)
		self.tramlinesDisabledText:setVisible(false)
	else
		local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
		self.ingameMapElement:setCenterToWorldPosition(x, z)
		self.ingameMapElement:setMapZoom(10)
		self.ingameMapElement:setMapAlpha(0.25)
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(true)
		self.fieldNotSupportedText:setVisible(false)
		self.tramlinesDisabledText:setVisible(false)
	end
	if self.fieldCourse ~= nil then
		local minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ = self.fieldCourse.courseField:getBoundingBox()
		self.ingameMapElement:fitToBoundary(minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ, 0.1)
		self.ingameMapElement:setMapAlpha(1)
	end
	local tramlineMap = g_precisionFarming.tramlineMap
	if tramlineMap ~= nil then
		local workDirection = tramlineMap.workDirectionTextToDeg[self.workDirectionIndex]
		if 1 < self.workDirectionIndex then
			self.workDirectionArrow:setVisible(true)
			self.workDirectionArrow:setImageRotation(3.141592653589793 + math.rad(workDirection))
			return
		end
		self.workDirectionArrow:setVisible(false)
	end
end
function TramlineSettingsDialog:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, positions, color)
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
function TramlineSettingsDialog:onDrawPostIngameMapHotspots(element, ingameMap)
	local posX, posY = self.ingameMapElement:getMapPosition()
	local sizeX, sizeZ = self.ingameMapElement:getMapSize()
	if self.fieldCourse ~= nil and self.fieldCourse.courseField ~= nil then
		local fieldCourseSettings = self.fieldCourseSettings
		local boundary = self.fieldCourse.courseField.fieldRootBoundary.boundaryLine
		for _, farmland in ipairs(self.farmlands) do
			local farmlandX, farmlandZ = farmland:getIndicatorPosition()
			farmlandX = ((farmlandX / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
			farmlandZ = (1 - ((farmlandZ / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
			setTextColor(1, 1, 1, 1)
			renderText(farmlandX, farmlandZ, 0.01, string.format(self.farmlandText, farmland:getName()))
			setTextAlignment(RenderText.ALIGN_LEFT)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		end
		self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, boundary, TramlineSettingsDialog.LINE_COLORS.BOUNDARY)
		if 1 < self.implementWidthIndex then
			for _, segment in ipairs(self.fieldCourse.segments) do
				if segment.isHeadlandSegment or segment.isIslandSegment then
					if fieldCourseSettings.workHeadlands then
						self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, TramlineSettingsDialog.LINE_COLORS.HEADLAND)
					end
				else
					if fieldCourseSettings.skipNumLines == 0 then
						self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, TramlineSettingsDialog.LINE_COLORS.STRAIGHT)
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
						self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, TramlineSettingsDialog.LINE_COLORS.STRAIGHT)
					end
				end
			end
		end
	end
end
function TramlineSettingsDialog:onClickImplementWidth(state, element)
	self.implementWidthIndex = state
	self.fieldCourseUpdateTimer = 1000
	self:updateMapState()
end
function TramlineSettingsDialog:onClickWorkDirection(state, element)
	self.workDirectionIndex = state
	self.fieldCourseUpdateTimer = 1000
	self:updateMapState()
end
function TramlineSettingsDialog:onClickSpacing(state, element)
	self.spacingIndex = state
end
function TramlineSettingsDialog:onClickOk(state, element)
	self:sendCallback(true)
end
function TramlineSettingsDialog:onClickBack(state, element)
	self:sendCallback(false)
end
TramlineSettingsDialog.COLOR_ALTERNATING = { [true] = { 0.02956, 0.02956, 0.02956, 0.6 }, [false] = { 0.02956, 0.02956, 0.02956, 0.2 } }
