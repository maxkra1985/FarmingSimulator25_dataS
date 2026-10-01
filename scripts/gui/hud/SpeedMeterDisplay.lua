local data = nil
if SpeedMeterDisplay ~= nil then
	local old = g_currentMission.hud.speedMeter
	data = {}
	data.vehicle = old.vehicle
	data.uiScale = old.uiScale
	data.isVisible = old:getVisible()
	old:delete()
end
SpeedMeterDisplay = {}
SpeedMeterDisplay.GAUGE_MODE_RPM = 1
SpeedMeterDisplay.GAUGE_MODE_SPEED = 2
SpeedMeterDisplay.NUMBER_OF_INDICATORS = 24
SpeedMeterDisplay.FUEL_LOW_PERCENTAGE = 0.1
local SpeedMeterDisplay_mt = Class(SpeedMeterDisplay, HUDDisplay)
function SpeedMeterDisplay.new()
	local self = SpeedMeterDisplay:superClass().new(SpeedMeterDisplay_mt)
	self.vehicle = nil
	self.isVehicleDrawSafe = false
	local r, g, b, a = unpack(HUD.COLOR.ACTIVE)
	self.speedBg = g_overlayManager:createOverlay("gui.speedBg", 0, 0, 0, 0)
	self.speedBgScale = g_overlayManager:createOverlay("gui.speedBgScale", 0, 0, 0, 0)
	self.speedBgRight = g_overlayManager:createOverlay("gui.speedBgRight", 0, 0, 0, 0)
	self.speedIndicatorBg = g_overlayManager:createOverlay("gui.speedGaugeBg", 0, 0, 0, 0)
	self.workingHours = g_overlayManager:createOverlay("gui.icon_usage", 0, 0, 0, 0)
	self.workingHours:setColor(r, g, b, a)
	self.cruiseControl = g_overlayManager:createOverlay("gui.icon_tempomat", 0, 0, 0, 0)
	self.cruiseControl:setColor(r, g, b, a)
	self.aiWorkerIcon = g_overlayManager:createOverlay("gui.icon_gps", 0, 0, 0, 0)
	self.aiWorkerIcon:setColor(r, g, b, a)
	self.aiSteeringIcon = g_overlayManager:createOverlay("gui.icon_guidance", 0, 0, 0, 0)
	self.aiSteeringIcon:setColor(r, g, b, a)
	self.fuelIcon = g_overlayManager:createOverlay("gui.icon_fuel", 0, 0, 0, 0)
	self.repairIcon = g_overlayManager:createOverlay("gui.icon_repair", 0, 0, 0, 0)
	self.bar = ThreePartOverlay.new()
	self.bar:setLeftPart("gui.progressbar_left", 0, 0)
	self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	self.bar:setRightPart("gui.progressbar_right", 0, 0)
	self.bar:setRotation(1.5707963267948966)
	self.gearIcon = g_overlayManager:createOverlay("gui.icon_gear", 0, 0, 0, 0)
	self.gearBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
	self.gearBg:setColor(r, g, b, a)
	self.gearTexts = { "A", "B", "C" }
	self.gearWarningTime = 0
	self.lastGaugeValue = 0
	self.rpmUnitText = g_i18n:getText("unit_rpmShort")
	self.kmhUnitText = g_i18n:getText("unit_kmh")
	self.mphUnitText = g_i18n:getText("unit_mph")
	self.aiInactiveText = g_i18n:getText("ui_gpsInactive")
	self.aiReadyText = g_i18n:getText("ui_gpsReady")
	self.aiActiveText = g_i18n:getText("ui_gpsActive")
	return self
end
function SpeedMeterDisplay:delete()
	self.speedBg:delete()
	self.speedBgScale:delete()
	self.speedBgRight:delete()
	self.speedIndicatorBg:delete()
	self.workingHours:delete()
	self.cruiseControl:delete()
	self.fuelIcon:delete()
	self.repairIcon:delete()
	self.gearIcon:delete()
	self.gearBg:delete()
	self.bar:delete()
	self.aiWorkerIcon:delete()
	self.aiSteeringIcon:delete()
end
function SpeedMeterDisplay:storeScaledValues()
	self:setPosition(g_hudAnchorRight, g_hudAnchorBottom)
	local speedBgWidth, speedBgHeight = self:scalePixelValuesToScreenVector(232, 232)
	self.speedBg:setDimension(speedBgWidth, speedBgHeight)
	self.speedBgScale:setDimension(0, speedBgHeight)
	local speedBgRightWidth, speedBgRightHeight = self:scalePixelValuesToScreenVector(23, 232)
	self.speedBgRight:setDimension(speedBgRightWidth, speedBgRightHeight)
	local speedGaugeBgWidth, speedGaugeBgHeight = self:scalePixelValuesToScreenVector(13, 23)
	self.speedIndicatorBg:setDimension(speedGaugeBgWidth, speedGaugeBgHeight)
	self.speedGaugeCenterOffsetX, self.speedGaugeCenterOffsetY = self:scalePixelValuesToScreenVector(117, 116)
	self.speedGaugeRadiusX, self.speedGaugeRadiusY = self:scalePixelValuesToScreenVector(68, 68)
	self.gaugeTextOffsets = {}
	local addOffset = function(x, y, alignment)
		x, y = self:scalePixelValuesToScreenVector(x, y)
		table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	end
	local x = -57
	local y = -33
	local alignment = RenderText.ALIGN_LEFT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = -64
	local y = -7
	local alignment = RenderText.ALIGN_LEFT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = -60
	local y = 19
	local alignment = RenderText.ALIGN_LEFT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = -46
	local y = 40
	local alignment = RenderText.ALIGN_LEFT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = -22
	local y = 54
	local alignment = RenderText.ALIGN_LEFT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = 22
	local y = 54
	local alignment = RenderText.ALIGN_RIGHT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = 46
	local y = 40
	local alignment = RenderText.ALIGN_RIGHT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = 60
	local y = 19
	local alignment = RenderText.ALIGN_RIGHT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = 64
	local y = -7
	local alignment = RenderText.ALIGN_RIGHT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	local x = 57
	local y = -33
	local alignment = RenderText.ALIGN_RIGHT
	x, y = self:scalePixelValuesToScreenVector(x, y)
	table.insert(self.gaugeTextOffsets, { offsetX = x, offsetY = y, alignment = alignment })
	self.gaugeTextRadiusX, self.gaugeTextRadiusY = self:scalePixelValuesToScreenVector(58, 58)
	self.gaugeUnitTextSize = self:scalePixelToScreenHeight(9)
	self.gaugeFactorTextSize = self:scalePixelToScreenHeight(9)
	self.gaugeUnitOffsetX, self.gaugeUnitOffsetY = self:scalePixelValuesToScreenVector(-64, -50)
	self.gaugeFactorOffsetX, self.gaugeFactorOffsetY = self:scalePixelValuesToScreenVector(64, -50)
	self.speedTextSize = self:scalePixelToScreenHeight(52)
	self.speedTextOffsetX, self.speedTextOffsetY = self:scalePixelValuesToScreenVector(0, -12)
	self.speedUnitTextSize = self:scalePixelToScreenHeight(15)
	self.speedUnitTextOffsetX, self.speedUnitTextOffsetY = self:scalePixelValuesToScreenVector(0, -27)
	self.workingHoursOffsetX, self.workingHoursOffsetY = self:scalePixelValuesToScreenVector(-45, -73)
	local workingHoursWidth, workingHoursHeight = self:scalePixelValuesToScreenVector(30, 30)
	self.workingHours:setDimension(workingHoursWidth, workingHoursHeight)
	self.workingHoursTextSize = self:scalePixelToScreenHeight(17)
	self.workingHoursTextOffsetX, self.workingHoursTextOffsetY = self:scalePixelValuesToScreenVector(35, -64)
	self.workingHoursSeperatorOffsetX, self.workingHoursSeperatorOffsetY = self:scalePixelValuesToScreenVector(-39, -43)
	self.cruiseControlOffsetX, self.cruiseControlOffsetY = self:scalePixelValuesToScreenVector(-30, -100)
	local cruiseControlWidth, cruiseControlHeight = self:scalePixelValuesToScreenVector(30, 30)
	self.cruiseControl:setDimension(cruiseControlWidth, cruiseControlHeight)
	self.cruiseControlTextSize = self:scalePixelToScreenHeight(17)
	self.cruiseControlTextOffsetX, self.cruiseControlTextOffsetY = self:scalePixelValuesToScreenVector(2, -94)
	self.cruiseControlSeperatorOffsetX, self.cruiseControlSeperatorOffsetY = self:scalePixelValuesToScreenVector(-39, -73)
	self.seperatorWidth = self:scalePixelToScreenWidth(78)
	self.sectionOffsetX, self.sectionOffsetY = self:scalePixelValuesToScreenVector(9, 47)
	local fuelIconWidth, fuelIconHeight = self:scalePixelValuesToScreenVector(30, 30)
	self.fuelIcon:setDimension(fuelIconWidth, fuelIconHeight)
	self.fuelIconOffsetX, self.fuelIconOffsetY = self:scalePixelValuesToScreenVector(-16, 144)
	self.fuelBarScaleWidth = self:scalePixelToScreenWidth(21)
	self.fuelBarOffsetX, self.fuelBarOffsetY = self:scalePixelValuesToScreenVector(0, 0)
	self.fuelOffsetX, self.fuelOffsetY = self:scalePixelValuesToScreenVector(-30, 0)
	local repairWidth, repairHeight = self:scalePixelValuesToScreenVector(25, 30)
	self.repairIcon:setDimension(repairWidth, repairHeight)
	self.repairIconOffsetX, self.repairIconOffsetY = self:scalePixelValuesToScreenVector(-16, 144)
	self.repairBarOffsetX, self.repairBarOffsetY = self:scalePixelValuesToScreenVector(0, 0)
	self.repairBarScaleWidth = self:scalePixelToScreenWidth(21)
	self.repairOffsetX, self.repairOffsetY = self:scalePixelValuesToScreenVector(-30, 0)
	local gearWidth, gearHeight = self:scalePixelValuesToScreenVector(30, 30)
	self.gearIcon:setDimension(gearWidth, gearHeight)
	self.gearIconOffsetX, self.gearIconOffsetY = self:scalePixelValuesToScreenVector(-16, 144)
	self.gearBarScaleWidth = self:scalePixelToScreenWidth(30)
	self.gearOffsetX, self.gearOffsetY = self:scalePixelValuesToScreenVector(-30, 0)
	local gearBgWidth, gearBgHeight = self:scalePixelValuesToScreenVector(26, 26)
	self.gearBg:setDimension(gearBgWidth, gearBgHeight)
	self.gearTextOffsetY = {}
	self.gearTextOffsetY[1] = self:scalePixelToScreenHeight(9)
	self.gearTextOffsetY[2] = self:scalePixelToScreenHeight(37)
	self.gearTextOffsetY[3] = self:scalePixelToScreenHeight(65)
	self.gearGroupTextOffsetY = self:scalePixelToScreenHeight(102)
	self.gearTextSize = self:scalePixelToScreenHeight(12)
	self.gearBgOffsetX = self:scalePixelToScreenWidth(-13)
	local offsetY = self:scalePixelToScreenHeight(-8)
	self.gearBgOffsetY = {}
	self.gearBgOffsetY[1] = self.gearTextOffsetY[1] + offsetY
	self.gearBgOffsetY[2] = self.gearTextOffsetY[2] + offsetY
	self.gearBgOffsetY[3] = self.gearTextOffsetY[3] + offsetY
	local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(6, 6)
	local barTotalWidth, _ = self:scalePixelValuesToScreenVector(130, 0)
	self.barMaxScaleWidth = barTotalWidth - 2 * barPartWidth
	self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
	self.bar:setMiddlePart(nil, self.barMaxScaleWidth, barPartHeight)
	self.bar:setRightPart(nil, barPartWidth, barPartHeight)
	local aiIconWidth, aiIconHeight = self:scalePixelValuesToScreenVector(30, 30)
	self.aiWorkerIcon:setDimension(aiIconWidth, aiIconHeight)
	self.aiSteeringIcon:setDimension(aiIconWidth, aiIconHeight)
	self.aiIconOffsetX, self.aiIconOffsetY = self:scalePixelValuesToScreenVector(-109, 2)
	self.aiTextOffsetX, self.aiTextOffsetY = self:scalePixelValuesToScreenVector(-49, 12)
	self.aiTextSize = self:scalePixelToScreenHeight(16)
	self.aiSeperatorOffsetX, self.aiSeperatorOffsetY = self:scalePixelValuesToScreenVector(-114, 34)
	self.aiSeperatorWidth = self:scalePixelToScreenWidth(100)
end
function SpeedMeterDisplay:update(dt)
	SpeedMeterDisplay:superClass().update(self, dt)
	self.isVehicleDrawSafe = true
end
function SpeedMeterDisplay:draw()
	local vehicle = self.vehicle
	if vehicle == nil or not self.isVehicleDrawSafe then
		return
	end
	local scaleWidth = 0
	local _ = nil
	local hasFuel = false
	local fuelLevel = nil
	local fuelCapacity = nil
	local isMotorized = vehicle.spec_motorized ~= nil
	if isMotorized then
		fuelLevel, fuelCapacity, _ = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
		hasFuel = fuelCapacity ~= nil
		scaleWidth = scaleWidth + self.fuelBarScaleWidth
	end
	local hasRepair = false
	if vehicle.getDamageAmount ~= nil and vehicle:getDamageAmount() ~= nil then
		hasRepair = true
		scaleWidth = scaleWidth + self.repairBarScaleWidth
	end
	local hasGear = true
	scaleWidth = scaleWidth + self.gearBarScaleWidth
	local posX, posY = self:getPosition()
	self.speedBgRight:setPosition(posX - self.speedBgRight.width, posY)
	self.speedBgScale:setDimension(scaleWidth, nil)
	self.speedBgScale:setPosition(self.speedBgRight.x - self.speedBgScale.width, posY)
	self.speedBg:setPosition(self.speedBgScale.x - self.speedBg.width, posY)
	self.speedBg:render()
	self.speedBgScale:render()
	self.speedBgRight:render()
	self:drawSpeedMeter(self.speedBg.x + self.speedGaugeCenterOffsetX, self.speedBg.y + self.speedGaugeCenterOffsetY)
	if vehicle.getAIAutomaticSteeringState ~= nil then
		local selectedAIMode = vehicle:getAIModeSelection()
		local activeColor = HUD.COLOR.ACTIVE
		local startX = posX + self.aiSeperatorOffsetX
		local startY = posY + self.aiSeperatorOffsetY
		local endX = startX + self.aiSeperatorWidth
		drawLine2D(startX, startY, endX, startY, g_pixelSizeY, activeColor[1], activeColor[2], activeColor[3], activeColor[4])
		local timeSinceLastModeChange = g_time - vehicle.spec_aiModeSelection.lastModeChangeTime
		if timeSinceLastModeChange < 2500 then
			local modeName = g_i18n:getText(AIModeSelection.MODE_TEXTS[selectedAIMode])
			local alpha = math.sin(timeSinceLastModeChange / 2500 * 3.141592653589793 * 3 - 1.5707963267948966) * 0.5 + 0.5
			setTextColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], alpha)
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(startX + self.aiSeperatorWidth * 0.5, posY + self.aiTextOffsetY, self.aiTextSize, modeName)
		else
			local aiIcon = self.aiWorkerIcon
			local text = self.aiInactiveText
			local r = 1
			local g = 1
			local b = 1
			local a = 1
			if selectedAIMode == AIModeSelection.MODE.STEERING_ASSIST then
				aiIcon = self.aiSteeringIcon
				local steeringState = vehicle:getAIAutomaticSteeringState()
				if steeringState == AIAutomaticSteering.STATE.AVAILABLE then
					r = HUD.COLOR.AVAILABLE[1]
					g = HUD.COLOR.AVAILABLE[2]
					b = HUD.COLOR.AVAILABLE[3]
					a = HUD.COLOR.AVAILABLE[4]
					text = self.aiReadyText
				elseif steeringState == AIAutomaticSteering.STATE.ACTIVE then
					r = HUD.COLOR.ACTIVE[1]
					g = HUD.COLOR.ACTIVE[2]
					b = HUD.COLOR.ACTIVE[3]
					a = HUD.COLOR.ACTIVE[4]
					text = self.aiActiveText
				end
			elseif vehicle:getIsAIActive() then
				r = HUD.COLOR.ACTIVE[1]
				g = HUD.COLOR.ACTIVE[2]
				b = HUD.COLOR.ACTIVE[3]
				a = HUD.COLOR.ACTIVE[4]
				text = self.aiActiveText
			end
			local gpsTextPosX = posX + self.aiTextOffsetX
			local gpsTextPosY = posY + self.aiTextOffsetY
			setTextColor(1, 1, 1, 1)
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(gpsTextPosX, gpsTextPosY, self.aiTextSize, text)
			aiIcon:setColor(r, g, b, a)
			aiIcon:setPosition(posX + self.aiIconOffsetX, posY + self.aiIconOffsetY)
			aiIcon:render()
		end
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
	local sectionPosX = posX + self.sectionOffsetX
	local sectionPosY = posY + self.sectionOffsetY
	if hasFuel then
		sectionPosX = sectionPosX + self.fuelOffsetX
		local fuelSectionPosY = sectionPosY + self.fuelOffsetY
		self.fuelIcon:setPosition(sectionPosX + self.fuelIconOffsetX, fuelSectionPosY + self.fuelIconOffsetY)
		self.fuelIcon:render()
		self.bar:setColor(0, 0, 0, 1)
		self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
		self.bar:setPosition(sectionPosX + self.fuelBarOffsetX, fuelSectionPosY + self.fuelBarOffsetY)
		self.bar:render()
		local fuelPercentage = fuelLevel / fuelCapacity
		if 0 < fuelPercentage then
			if 0.1 < fuelPercentage then
				self.bar:setColor(1, 0.4287, 0.0006, 1)
			else
				self.bar:setColor(1, 0.1233, 0, math.abs(math.cos(g_time / 300)))
			end
			local barScale = math.clamp(self.barMaxScaleWidth * fuelPercentage, 0, self.barMaxScaleWidth)
			self.bar:setMiddlePart(nil, barScale, nil)
			self.bar:setPosition(sectionPosX + self.fuelBarOffsetX, fuelSectionPosY + self.fuelBarOffsetY)
			self.bar:render()
		end
	end
	if hasRepair then
		sectionPosX = sectionPosX + self.repairOffsetX
		local repairSectionPosY = sectionPosY + self.repairOffsetY
		self.repairIcon:setPosition(sectionPosX + self.repairIconOffsetX, repairSectionPosY + self.repairIconOffsetY)
		self.repairIcon:render()
		self.bar:setColor(0, 0, 0, 1)
		self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
		self.bar:setPosition(sectionPosX + self.repairBarOffsetX, repairSectionPosY + self.repairBarOffsetY)
		self.bar:render()
		local damageValue = 1
		local vehicles = vehicle.rootVehicle.childVehicles
		for _, subVehicle in ipairs(vehicles) do
			if subVehicle.getDamageShowOnHud == nil then
				continue
			end
			if subVehicle:getDamageShowOnHud() then
				damageValue = math.min(damageValue, 1 - subVehicle:getDamageAmount())
			end
		end
		if 0 < damageValue then
			if 0.2 < damageValue then
				self.bar:setColor(0.0097, 0.4287, 0.6445, 1)
			else
				self.bar:setColor(1, 0.1233, 0, 1)
			end
			local barScale = math.clamp(self.barMaxScaleWidth * damageValue, 0, self.barMaxScaleWidth)
			self.bar:setMiddlePart(nil, barScale, nil)
			self.bar:setPosition(sectionPosX + self.repairBarOffsetX, repairSectionPosY + self.repairBarOffsetY)
			self.bar:render()
		end
	end
	sectionPosX = sectionPosX + self.gearOffsetX
	local gearSectionPosY = sectionPosY + self.gearOffsetY
	self.gearIcon:setPosition(sectionPosX + self.gearIconOffsetX, gearSectionPosY + self.gearIconOffsetY)
	self.gearIcon:render()
	self:drawGearText(sectionPosX, gearSectionPosY)
end
function SpeedMeterDisplay:drawSpeedMeter(centerX, centerY)
	local vehicle = self.vehicle
	if vehicle == nil then
		return
	else
		local speedGaugeUseMiles = g_gameSettings:getValue(GameSettings.SETTING.USE_MILES)
		local speedGaugeMode = g_gameSettings:getValue(GameSettings.SETTING.HUD_SPEED_GAUGE)
		local motorizedSpec = vehicle.spec_motorized
		if motorizedSpec.forceSpeedHudDisplay then
			speedGaugeMode = SpeedMeterDisplay.GAUGE_MODE_SPEED
		elseif motorizedSpec.forceRpmHudDisplay then
			speedGaugeMode = SpeedMeterDisplay.GAUGE_MODE_RPM
		end
		local lastSpeed = vehicle:getLastSpeed()
		local kmh = math.clamp(lastSpeed * vehicle.spec_motorized.speedDisplayScale, 0, 999)
		if kmh < 0.5 then
			kmh = 0
		end
		local speedKmh = g_i18n:getSpeed(kmh)
		local speed = math.floor(speedKmh)
		if 0.5 < math.abs(speedKmh - speed) then
			speed = speed + 1
		end
		local unitText = nil
		local value = nil
		local minGaugeValue = nil
		local maxGaugeValue = nil
		local gaugeRounding = nil
		local motor = vehicle:getMotor()
		local fixedLowerLimit = false
		if speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
			unitText = self.rpmUnitText
			minGaugeValue = motor:getMinRpm()
			maxGaugeValue = motor:getMaxRpm()
			gaugeRounding = 200
			value = vehicle:getMotorRpmReal()
		else
			unitText = self.kmhUnitText
			local scale = 1
			if speedGaugeUseMiles then
				scale = 0.621371
				unitText = self.mphUnitText
			end
			minGaugeValue = 0
			maxGaugeValue = motor:getMaximumForwardSpeed() * 3.6 * scale
			gaugeRounding = 5
			fixedLowerLimit = true
			value = lastSpeed * scale
		end
		local range = maxGaugeValue - minGaugeValue
		local stepDistance = math.ceil(range / 8 / gaugeRounding) * gaugeRounding
		local minValue = math.floor(minGaugeValue / gaugeRounding) * gaugeRounding - stepDistance
		local maxValue = math.floor(maxGaugeValue / gaugeRounding) * gaugeRounding + stepDistance
		if fixedLowerLimit then
			minValue = minGaugeValue
		end
		self.lastGaugeValue = self.lastGaugeValue * 0.95 + value * 0.05
		local pivotX = self.speedIndicatorBg.width * 0.5
		local pivotY = 0
		local offset = -0.6108652381980153
		local angle = 0.17453292519943295
		local inactiveColor = HUD.COLOR.INACTIVE
		local activeColor = HUD.COLOR.ACTIVE
		for i = SpeedMeterDisplay.NUMBER_OF_INDICATORS, 1, -1 do
			local rotation = i * 0.17453292519943295 + -0.6108652381980153
			local cosRot = math.cos(rotation)
			local sinRot = math.sin(rotation)
			local indicatorPosX = centerX + cosRot * self.speedGaugeRadiusX - pivotX
			local indicatorPosY = centerY + sinRot * self.speedGaugeRadiusY - 0
			self.speedIndicatorBg:setPosition(indicatorPosX, indicatorPosY)
			self.speedIndicatorBg:setRotation(rotation - 1.5707963267948966, pivotX, 0)
			local indicatorValue = MathUtil.lerp(minValue, maxValue, 1 - i / SpeedMeterDisplay.NUMBER_OF_INDICATORS)
			local r = nil
			local g = nil
			local b = nil
			local a = nil
			if 0.5 < value then
				if indicatorValue < value then
					r = activeColor[1]
					g = activeColor[2]
					b = activeColor[3]
					a = activeColor[4]
				else
					r = inactiveColor[1]
					g = inactiveColor[2]
					b = inactiveColor[3]
					a = inactiveColor[4]
				end
			end
			self.speedIndicatorBg:setColor(r, g, b, a)
			self.speedIndicatorBg:render()
		end
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_CENTER)
		for i = 1, 10 do
			local data = self.gaugeTextOffsets[i]
			local textPosX = centerX + data.offsetX
			local textPosY = centerY + data.offsetY
			setTextAlignment(data.alignment)
			setTextBold(true)
			local textValue = MathUtil.lerp(minValue, maxValue, (i - 1) / 9)
			if speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
				textValue = textValue / 100
			end
			local text = string.format("%d", textValue)
			renderText(textPosX, textPosY, self.gaugeUnitTextSize, text)
		end
		local gaugeUnitPosX = centerX + self.gaugeUnitOffsetX
		local gaugeUnitPosY = centerY + self.gaugeUnitOffsetY
		setTextRotation(0.5235987755982988, gaugeUnitPosX, gaugeUnitPosY)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
		renderText(gaugeUnitPosX, gaugeUnitPosY, self.gaugeUnitTextSize, unitText)
		setTextColor(1, 1, 1, 1)
		if speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
			local gaugeFactorPosX = centerX + self.gaugeFactorOffsetX
			local gaugeFactorPosY = centerY + self.gaugeFactorOffsetY
			setTextRotation(-0.5235987755982988, gaugeFactorPosX, gaugeFactorPosY)
			renderText(gaugeFactorPosX, gaugeFactorPosY, self.gaugeFactorTextSize, "x100")
		end
		setTextRotation(0, 0, 0)
		local speedPosX = centerX + self.speedTextOffsetX
		local speedPosY = centerY + self.speedTextOffsetY
		setTextBold(true)
		renderText(speedPosX, speedPosY, self.speedTextSize, string.format("%1d", speed))
		local speedUnit = utf8ToUpper(g_i18n:getSpeedMeasuringUnit())
		local speedUnitPosX = centerX + self.speedUnitTextOffsetX
		local speedUnitPosY = centerY + self.speedUnitTextOffsetY
		setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
		renderText(speedUnitPosX, speedUnitPosY, self.speedUnitTextSize, speedUnit)
		setTextColor(1, 1, 1, 1)
		local startX = centerX + self.workingHoursSeperatorOffsetX
		local startY = centerY + self.workingHoursSeperatorOffsetY
		local endX = startX + self.seperatorWidth
		local endY = startY
		drawLine2D(startX, startY, endX, endY, g_pixelSizeY, activeColor[1], activeColor[2], activeColor[3], activeColor[4])
		local workingHoursPosX = centerX + self.workingHoursTextOffsetX
		local workingHoursPosY = centerY + self.workingHoursTextOffsetY
		if vehicle.operatingTime ~= nil then
			local minutes = vehicle.operatingTime / 60000
			local hours = math.floor(minutes / 60)
			minutes = math.floor((minutes - hours * 60) / 6)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			setTextColor(1, 1, 1, 0.3)
			renderText(workingHoursPosX, workingHoursPosY, self.workingHoursTextSize, string.format("%03d.%dh", hours, minutes))
			setTextColor(1, 1, 1, 1)
			renderText(workingHoursPosX, workingHoursPosY, self.workingHoursTextSize, string.format("%d.%dh", hours, minutes))
		else
			setTextColor(1, 1, 1, 1)
			renderText(workingHoursPosX, workingHoursPosY, self.workingHoursTextSize, "-/-")
		end
		self.workingHours:setPosition(centerX + self.workingHoursOffsetX, centerY + self.workingHoursOffsetY)
		self.workingHours:render()
		setTextAlignment(RenderText.ALIGN_LEFT)
		startX = centerX + self.cruiseControlSeperatorOffsetX
		startY = centerY + self.cruiseControlSeperatorOffsetY
		endX = startX + self.seperatorWidth
		endY = startY
		drawLine2D(startX, startY, endX, endY, g_pixelSizeY, activeColor[1], activeColor[2], activeColor[3], activeColor[4])
		local cruiseControlSpeed, isActive = self.vehicle:getCruiseControlDisplayInfo()
		cruiseControlSpeed = string.format("%d", g_i18n:getSpeed(cruiseControlSpeed))
		if isActive then
			setTextColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
		else
			setTextColor(1, 1, 1, 1)
		end
		local cruiseControlPosX = centerX + self.cruiseControlTextOffsetX
		local cruiseControlPosY = centerY + self.cruiseControlTextOffsetY
		renderText(cruiseControlPosX, cruiseControlPosY, self.cruiseControlTextSize, tostring(cruiseControlSpeed))
		self.cruiseControl:setPosition(centerX + self.cruiseControlOffsetX, centerY + self.cruiseControlOffsetY)
		self.cruiseControl:render()
	end
end
function SpeedMeterDisplay:drawGearText(x, y)
	if self.vehicle == nil then
		return
	else
		local gearName, gearGroupName, _gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning = self.vehicle:getGearInfoToDisplay()
		local gearSelectedIndex = 1
		local gearGroupText = ""
		if gearName ~= nil then
			if not isAutomatic then
				gearGroupText = gearGroupName or ""
				if nextGearName == nil then
					if prevGearName == nil then
						self.gearTexts[1] = ""
						self.gearTexts[2] = gearName
						self.gearTexts[3] = ""
						gearSelectedIndex = 2
					elseif nextGearName == nil then
						if prevPrevGearName ~= nil then
							self.gearTexts[1] = prevPrevGearName
							self.gearTexts[2] = prevGearName
							self.gearTexts[3] = gearName
							gearSelectedIndex = 3
						else
							self.gearTexts[1] = prevGearName
							self.gearTexts[2] = gearName
							self.gearTexts[3] = ""
							gearSelectedIndex = 2
						end
					elseif prevGearName == nil then
						self.gearTexts[1] = gearName
						self.gearTexts[2] = nextGearName
						self.gearTexts[3] = nextNextGearName or ""
						gearSelectedIndex = 1
					else
						self.gearTexts[1] = prevGearName
						self.gearTexts[2] = gearName
						self.gearTexts[3] = nextGearName
						gearSelectedIndex = 2
					end
				end
			elseif gearName ~= nil then
				if isAutomatic then
					self.gearTexts[1] = "R"
					self.gearTexts[2] = "N"
					self.gearTexts[3] = "D"
					if gearName == "N" then
						gearSelectedIndex = 2
					elseif gearName == "D" then
						gearSelectedIndex = 3
					elseif gearName == "R" then
						gearSelectedIndex = 1
					end
				end
			end
		end
		if showNeutralWarning then
			self.gearWarningTime = self.gearWarningTime + g_currentDt
		else
			self.gearWarningTime = 0
		end
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		if gearGroupText ~= nil then
			renderText(x, y + self.gearGroupTextOffsetY, self.gearTextSize, gearGroupText)
		end
		for i = 1, 3 do
			local alpha = 1
			local renderBg = false
			if i == 2 then
				alpha = math.abs(math.cos(self.gearWarningTime / 200))
			end
			if gearSelectedIndex == i then
				if isGearChanging then
					alpha = alpha * 0.5
				end
				renderBg = true
			end
			if renderBg then
				self.gearBg:setColor(nil, nil, nil, alpha)
				self.gearBg:setPosition(x + self.gearBgOffsetX, y + self.gearBgOffsetY[i])
				self.gearBg:render()
			end
			renderText(x, y + self.gearTextOffsetY[i], self.gearTextSize, self.gearTexts[i])
		end
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end
function SpeedMeterDisplay:setVehicle(vehicle)
	self.vehicle = nil
	local hasVehicle = vehicle ~= nil
	local isMotorized = hasVehicle and vehicle.spec_motorized ~= nil
	if hasVehicle and isMotorized then
		self.vehicle = vehicle
		local _, capacity, fuelType = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
		local needFuelGauge = capacity ~= nil
		if needFuelGauge then
			local fuelGaugeIconSliceId = "gui.icon_fuel"
			if fuelType == FillType.ELECTRICCHARGE then
				fuelGaugeIconSliceId = "gui.icon_electricCharge"
			elseif fuelType == FillType.METHANE then
				fuelGaugeIconSliceId = "gui.icon_methane"
			end
			self.fuelIcon:setSliceId(fuelGaugeIconSliceId)
		end
	end
	self:setVisible(self.vehicle ~= nil)
	self.isVehicleDrawSafe = false
end
function SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
	local fuelType = FillType.DIESEL
	local fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
	if fillUnitIndex == nil then
		fuelType = FillType.ELECTRICCHARGE
		fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
		if fillUnitIndex == nil then
			fuelType = FillType.METHANE
			fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
		end
	end
	local level = vehicle:getFillUnitFillLevel(fillUnitIndex)
	local capacity = vehicle:getFillUnitCapacity(fillUnitIndex)
	return level, capacity, fuelType
end
if data ~= nil then
	local speedMeter = SpeedMeterDisplay.new()
	speedMeter:setVehicle(data.vehicle)
	speedMeter:setScale(data.uiScale)
	speedMeter:setVisible(data.isVisible)
	g_currentMission.hud.speedMeter = speedMeter
	g_currentMission.hud.displayComponents.speedMeter = speedMeter
	Logging.info("Reloaded")
end
