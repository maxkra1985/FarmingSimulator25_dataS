-- Local values: TramlineSettingsDialog_mt
TramlineSettingsDialog = {}
TramlineSettingsDialog.MOD_DIR = g_currentModDirectory
TramlineSettingsDialog.LINE_COLORS = {}
TramlineSettingsDialog.LINE_COLORS.BOUNDARY = {
	0.0273,
	0.0612,
	0.3324,
	1
}
TramlineSettingsDialog.LINE_COLORS.HEADLAND = {
	0.2122,
	0.5029,
	0.402,
	1
}
TramlineSettingsDialog.LINE_COLORS.STRAIGHT = {
	0.402,
	0.2051,
	0.0144,
	1
}
local TramlineSettingsDialog_mt = Class(TramlineSettingsDialog, MessageDialog)
function TramlineSettingsDialog.register()
	local v2_ = TramlineSettingsDialog.new()
	g_gui:loadGui(TramlineSettingsDialog.MOD_DIR .. "gui/TramlineSettingsDialog.xml", "TramlineSettingsDialog", v2_)
	TramlineSettingsDialog.INSTANCE = v2_
end

-- Local values: dialog
function TramlineSettingsDialog.show(implementWidthIndex, workDirectionIndex, spacingIndex, fieldX, fieldZ, callback)
	if TramlineSettingsDialog.INSTANCE ~= nil then
		local v9_ = TramlineSettingsDialog.INSTANCE
		v9_:setCallback(callback)
		v9_.implementWidthIndex = implementWidthIndex
		v9_.workDirectionIndex = workDirectionIndex
		v9_.spacingIndex = spacingIndex
		v9_.fieldX = fieldX
		v9_.fieldZ = fieldZ
		g_gui:showDialog("TramlineSettingsDialog")
	end
end

-- Upvalues: TramlineSettingsDialog_mt
-- Local values: self
function TramlineSettingsDialog.new(target, custom_mt)
	-- upvalues: (copy) TramlineSettingsDialog_mt
	local v12_ = MessageDialog.new(target, custom_mt or TramlineSettingsDialog_mt)
	v12_.ingameMapElement = nil
	v12_.fieldCourseUpdateTimer = 0
	v12_.lineWidth = 1 / g_screenHeight
	v12_.farmlands = {}
	v12_.farmlandText = g_i18n:getText("contract_farmland")
	v12_.fieldCourseSettings = FieldCourseSettings.new()
	v12_.fieldCourseSettings.implementWidth = 27
	v12_.fieldCourseSettings.numHeadlands = 1
	v12_.fieldCourseSettings.segmentExtendedToBoundary = true
	v12_.fieldCourseSettings.segmentHeadlandReverseLines = true
	v12_.fieldCourseSettings.segmentMinOffset = 3
	v12_.fieldCourseSettings.segmentMinLength = 25
	return v12_
end

-- Local values: aiUserSettings
function TramlineSettingsDialog.createFromExistingGui(gui, guiName)
	TramlineSettingsDialog.register()
	local v14_ = gui.aiUserSettings
	TramlineSettingsDialog.show(v14_)
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
		if self.target == nil then
			self.callbackFunc(applyChanges, self.farmlands, self.implementWidthIndex, self.workDirectionIndex, self.spacingIndex)
		else
			self.callbackFunc(self.target, applyChanges, self.farmlands, self.implementWidthIndex, self.workDirectionIndex, self.spacingIndex)
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
	if self.fieldCourseUpdateTimer > 0 then
		self.fieldCourseUpdateTimer = self.fieldCourseUpdateTimer - dt
		if self.fieldCourseUpdateTimer <= 0 then
			self:updateFieldCourse()
		end
	end
end

-- Local values: mission
function TramlineSettingsDialog:onOpen()
	TramlineSettingsDialog:superClass().onOpen(self)
	self.isOpening = true
	local v25_ = g_currentMission
	self.ingameMapElement.drawHotspots = false
	self.ingameMapElement:setIngameMap(v25_.hud:getIngameMap())
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

-- Local values: tramlineMap
function TramlineSettingsDialog:updateSettingsValues()
	local v28_ = g_precisionFarming.tramlineMap
	if v28_ ~= nil then
		self.implementWidthOption:setTexts(v28_.implementWidthTexts)
		self.workDirectionOption:setTexts(v28_.workDirectionTexts)
		self.spacingOption:setTexts(v28_.spacingTexts)
	end
	self.implementWidthOption:setState(self.implementWidthIndex)
	self.workDirectionOption:setState(self.workDirectionIndex)
	self.spacingOption:setState(self.spacingIndex)
	local v29_ = self.implementWidthOption.parent
	local v30_ = TramlineSettingsDialog.COLOR_ALTERNATING[false]
	v29_:setImageColor(nil, unpack(v30_))
	local v31_ = self.workDirectionOption.parent
	local v32_ = TramlineSettingsDialog.COLOR_ALTERNATING[true]
	v31_:setImageColor(nil, unpack(v32_))
	local v33_ = self.spacingOption.parent
	local v34_ = TramlineSettingsDialog.COLOR_ALTERNATING[false]
	v33_:setImageColor(nil, unpack(v34_))
end

-- Local values: tramlineMap, implementWidth, workDirection
function TramlineSettingsDialog:updateFieldCourse()
	local v36_ = g_precisionFarming.tramlineMap
	if v36_ ~= nil then
		if self.implementWidthIndex > 1 then
			local v37_ = v36_.implementWidths[self.implementWidthIndex]
			self.fieldCourseSettings.implementWidth = v37_
		else
			self.fieldCourseSettings.implementWidth = v36_.implementWidths[2]
		end
		local v38_ = v36_.workDirectionTextToDeg[self.workDirectionIndex]
		self.fieldCourseSettings.workDirection = math.rad(v38_)
	end
	if self.fieldX ~= nil and (self.fieldZ ~= nil and not self.fieldCourseLoading) then
		if self.fieldCourse == nil then
			self.fieldCourseLoading = true
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self.fieldCourseSettings:print()
			end
			FieldCourse.generateUICourseByFieldPosition(self.fieldX, self.fieldZ, self.fieldCourseSettings, function(p39_)
				-- upvalues: (copy) self
				self.fieldCourseLoading = false
				if self.callbackFunc ~= nil then
					if p39_ == nil then
						self.fieldCourse = nil
					else
						self.fieldCourse = p39_
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
			self.fieldCourse:updateFieldCourseSettings(self.fieldCourseSettings, function(p40_)
				-- upvalues: (copy) self
				self.fieldCourseLoading = false
				if self.callbackFunc ~= nil then
					if not p40_ then
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

-- Local values: boundary, farmlands, _, farmland, x, z
function TramlineSettingsDialog:updateFarmlands()
	self.farmlands = {}
	if self.fieldCourse ~= nil then
		local v42_ = self.fieldCourse.courseField.fieldRootBoundary.boundaryLine
		local v43_ = g_farmlandManager:getFarmlands()
		for _, v44_ in ipairs(v43_) do
			local v45_, v46_ = v44_:getIndicatorPosition()
			if FieldCourseUtil.getIsPointInsideBoundary(v45_, v46_, v42_) then
				local v47_ = self.farmlands
				table.insert(v47_, v44_)
			end
		end
	end
	self.okButton:setDisabled(#self.farmlands == 0)
end

-- Local values: x, _, z, x, _, z, minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ, tramlineMap, workDirection
function TramlineSettingsDialog:updateMapState()
	if self.fieldCourseLoading then
		self.ingameMapElement:setMapAlpha(1)
		if self.fieldCourse == nil then
			local v49_, _, v50_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			self.ingameMapElement:setCenterToWorldPosition(v49_, v50_)
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
	elseif self.fieldCourse == nil then
		local v51_, _, v52_ = getWorldTranslation(g_cameraManager:getActiveCamera())
		self.ingameMapElement:setCenterToWorldPosition(v51_, v52_)
		self.ingameMapElement:setMapZoom(10)
		self.ingameMapElement:setMapAlpha(0.25)
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(true)
		self.fieldNotSupportedText:setVisible(false)
		self.tramlinesDisabledText:setVisible(false)
	else
		self.loadingAnimation:setVisible(false)
		self.noFieldFoundText:setVisible(false)
		self.fieldNotSupportedText:setVisible(false)
		self.tramlinesDisabledText:setVisible(false)
	end
	if self.fieldCourse ~= nil then
		local v53_, v54_, v55_, v56_ = self.fieldCourse.courseField:getBoundingBox()
		self.ingameMapElement:fitToBoundary(v53_, v54_, v55_, v56_, 0.1)
		self.ingameMapElement:setMapAlpha(1)
	end
	local v57_ = g_precisionFarming.tramlineMap
	if v57_ ~= nil then
		local v58_ = v57_.workDirectionTextToDeg[self.workDirectionIndex]
		if self.workDirectionIndex > 1 then
			self.workDirectionArrow:setVisible(true)
			self.workDirectionArrow:setImageRotation(3.141592653589793 + math.rad(v58_))
			return
		end
		self.workDirectionArrow:setVisible(false)
	end
end

-- Local values: i, pos1, pos2, x1, y1, x2, y2
function TramlineSettingsDialog:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, positions, color)
	for v67_ = 1, #positions - 1 do
		local v68_ = positions[v67_]
		local v69_ = positions[v67_ + 1]
		local v70_ = ((v68_[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local v71_ = (1 - ((v68_[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		local v72_ = ((v69_[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local v73_ = (1 - ((v69_[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		drawLine2D(v70_, v71_, v72_, v73_, self.lineWidth, color[1], color[2], color[3], color[4])
	end
end

-- Local values: posX, posY, sizeX, sizeZ, fieldCourseSettings, boundary, _, farmland, farmlandX, farmlandZ, _, segment, i, segment
function TramlineSettingsDialog:onDrawPostIngameMapHotspots(element, ingameMap)
	local v76_, v77_ = self.ingameMapElement:getMapPosition()
	local v78_, v79_ = self.ingameMapElement:getMapSize()
	if self.fieldCourse ~= nil and self.fieldCourse.courseField ~= nil then
		local v80_ = self.fieldCourseSettings
		local v81_ = self.fieldCourse.courseField.fieldRootBoundary.boundaryLine
		for _, v82_ in ipairs(self.farmlands) do
			local v83_, v84_ = v82_:getIndicatorPosition()
			local v85_ = ((v83_ / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * v78_ + v76_
			local v86_ = (1 - ((v84_ / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * v79_ + v77_
			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
			setTextColor(1, 1, 1, 1)
			renderText(v85_, v86_, 0.01, string.format(self.farmlandText, v82_:getName()))
			setTextAlignment(RenderText.ALIGN_LEFT)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		end
		self:drawLineOnMap(ingameMap, v76_, v77_, v78_, v79_, v81_, TramlineSettingsDialog.LINE_COLORS.BOUNDARY)
		if self.implementWidthIndex > 1 then
			for _, v87_ in ipairs(self.fieldCourse.segments) do
				if v87_.isHeadlandSegment or v87_.isIslandSegment then
					if v80_.workHeadlands then
						self:drawLineOnMap(ingameMap, v76_, v77_, v78_, v79_, v87_.positions, TramlineSettingsDialog.LINE_COLORS.HEADLAND)
					end
				elseif v80_.skipNumLines == 0 then
					self:drawLineOnMap(ingameMap, v76_, v77_, v78_, v79_, v87_.positions, TramlineSettingsDialog.LINE_COLORS.STRAIGHT)
				end
			end
			if v80_.skipNumLines > 0 then
				for v88_ = #self.fieldCourse.segments, 1, -1 do
					local v89_ = self.fieldCourse.segments[v88_]
					if v89_.lineGroupIndex ~= nil and (v89_.offsetLineIndex - 1) % (v80_.skipNumLines + 1) == 0 then
						self:drawLineOnMap(ingameMap, v76_, v77_, v78_, v79_, v89_.positions, TramlineSettingsDialog.LINE_COLORS.STRAIGHT)
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
TramlineSettingsDialog.COLOR_ALTERNATING = {
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
