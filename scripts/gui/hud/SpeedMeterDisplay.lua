-- Local values: data, old, SpeedMeterDisplay_mt, speedMeter
local v1_
if SpeedMeterDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.speedMeter
	v1_ = {
		["vehicle"] = v2_.vehicle,
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
SpeedMeterDisplay = {}
SpeedMeterDisplay.GAUGE_MODE_RPM = 1
SpeedMeterDisplay.GAUGE_MODE_SPEED = 2
SpeedMeterDisplay.NUMBER_OF_INDICATORS = 24
SpeedMeterDisplay.FUEL_LOW_PERCENTAGE = 0.1
local data = Class(SpeedMeterDisplay, HUDDisplay)
function SpeedMeterDisplay.new()
	-- upvalues: (copy) data
	local v4_ = SpeedMeterDisplay:superClass().new(data)
	v4_.vehicle = nil
	v4_.isVehicleDrawSafe = false
	local v5_ = HUD.COLOR.ACTIVE
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.speedBg = g_overlayManager:createOverlay("gui.speedBg", 0, 0, 0, 0)
	v4_.speedBgScale = g_overlayManager:createOverlay("gui.speedBgScale", 0, 0, 0, 0)
	v4_.speedBgRight = g_overlayManager:createOverlay("gui.speedBgRight", 0, 0, 0, 0)
	v4_.speedIndicatorBg = g_overlayManager:createOverlay("gui.speedGaugeBg", 0, 0, 0, 0)
	v4_.workingHours = g_overlayManager:createOverlay("gui.icon_usage", 0, 0, 0, 0)
	v4_.workingHours:setColor(v6_, v7_, v8_, v9_)
	v4_.cruiseControl = g_overlayManager:createOverlay("gui.icon_tempomat", 0, 0, 0, 0)
	v4_.cruiseControl:setColor(v6_, v7_, v8_, v9_)
	v4_.aiWorkerIcon = g_overlayManager:createOverlay("gui.icon_gps", 0, 0, 0, 0)
	v4_.aiWorkerIcon:setColor(v6_, v7_, v8_, v9_)
	v4_.aiSteeringIcon = g_overlayManager:createOverlay("gui.icon_guidance", 0, 0, 0, 0)
	v4_.aiSteeringIcon:setColor(v6_, v7_, v8_, v9_)
	v4_.fuelIcon = g_overlayManager:createOverlay("gui.icon_fuel", 0, 0, 0, 0)
	v4_.repairIcon = g_overlayManager:createOverlay("gui.icon_repair", 0, 0, 0, 0)
	v4_.bar = ThreePartOverlay.new()
	v4_.bar:setLeftPart("gui.progressbar_left", 0, 0)
	v4_.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	v4_.bar:setRightPart("gui.progressbar_right", 0, 0)
	v4_.bar:setRotation(1.5707963267948966)
	v4_.gearIcon = g_overlayManager:createOverlay("gui.icon_gear", 0, 0, 0, 0)
	v4_.gearBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
	v4_.gearBg:setColor(v6_, v7_, v8_, v9_)
	v4_.gearTexts = { "A", "B", "C" }
	v4_.gearWarningTime = 0
	v4_.lastGaugeValue = 0
	v4_.rpmUnitText = g_i18n:getText("unit_rpmShort")
	v4_.kmhUnitText = g_i18n:getText("unit_kmh")
	v4_.mphUnitText = g_i18n:getText("unit_mph")
	v4_.aiInactiveText = g_i18n:getText("ui_gpsInactive")
	v4_.aiReadyText = g_i18n:getText("ui_gpsReady")
	v4_.aiActiveText = g_i18n:getText("ui_gpsActive")
	return v4_
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

-- Local values: speedBgWidth, speedBgHeight, speedBgRightWidth, speedBgRightHeight, speedGaugeBgWidth, speedGaugeBgHeight, addOffset, x, y, alignment, x, y, alignment, x, y, alignment, x, y, alignment, x, y, alignment, x, y, alignment, x, y, alignment, x, y, alignment, x, y, alignment, x, y, alignment, workingHoursWidth, workingHoursHeight, cruiseControlWidth, cruiseControlHeight, fuelIconWidth, fuelIconHeight, repairWidth, repairHeight, gearWidth, gearHeight, gearBgWidth, gearBgHeight, offsetY, barPartWidth, barPartHeight, barTotalWidth, _, aiIconWidth, aiIconHeight
function SpeedMeterDisplay:storeScaledValues()
	self:setPosition(g_hudAnchorRight, g_hudAnchorBottom)
	local v12_, v13_ = self:scalePixelValuesToScreenVector(232, 232)
	self.speedBg:setDimension(v12_, v13_)
	self.speedBgScale:setDimension(0, v13_)
	local v14_, v15_ = self:scalePixelValuesToScreenVector(23, 232)
	self.speedBgRight:setDimension(v14_, v15_)
	local v16_, v17_ = self:scalePixelValuesToScreenVector(13, 23)
	self.speedIndicatorBg:setDimension(v16_, v17_)
	local v18_, v19_ = self:scalePixelValuesToScreenVector(117, 116)
	self.speedGaugeCenterOffsetX = v18_
	self.speedGaugeCenterOffsetY = v19_
	local v20_, v21_ = self:scalePixelValuesToScreenVector(68, 68)
	self.speedGaugeRadiusX = v20_
	self.speedGaugeRadiusY = v21_
	self.gaugeTextOffsets = {}
	local v22_ = RenderText.ALIGN_LEFT
	local v23_, v24_ = self:scalePixelValuesToScreenVector(-57, -33)
	local v25_ = self.gaugeTextOffsets
	table.insert(v25_, {
		["offsetX"] = v23_,
		["offsetY"] = v24_,
		["alignment"] = v22_
	})
	local v26_ = RenderText.ALIGN_LEFT
	local v27_, v28_ = self:scalePixelValuesToScreenVector(-64, -7)
	local v29_ = self.gaugeTextOffsets
	table.insert(v29_, {
		["offsetX"] = v27_,
		["offsetY"] = v28_,
		["alignment"] = v26_
	})
	local v30_ = RenderText.ALIGN_LEFT
	local v31_, v32_ = self:scalePixelValuesToScreenVector(-60, 19)
	local v33_ = self.gaugeTextOffsets
	table.insert(v33_, {
		["offsetX"] = v31_,
		["offsetY"] = v32_,
		["alignment"] = v30_
	})
	local v34_ = RenderText.ALIGN_LEFT
	local v35_, v36_ = self:scalePixelValuesToScreenVector(-46, 40)
	local v37_ = self.gaugeTextOffsets
	table.insert(v37_, {
		["offsetX"] = v35_,
		["offsetY"] = v36_,
		["alignment"] = v34_
	})
	local v38_ = RenderText.ALIGN_LEFT
	local v39_, v40_ = self:scalePixelValuesToScreenVector(-22, 54)
	local v41_ = self.gaugeTextOffsets
	table.insert(v41_, {
		["offsetX"] = v39_,
		["offsetY"] = v40_,
		["alignment"] = v38_
	})
	local v42_ = RenderText.ALIGN_RIGHT
	local v43_, v44_ = self:scalePixelValuesToScreenVector(22, 54)
	local v45_ = self.gaugeTextOffsets
	table.insert(v45_, {
		["offsetX"] = v43_,
		["offsetY"] = v44_,
		["alignment"] = v42_
	})
	local v46_ = RenderText.ALIGN_RIGHT
	local v47_, v48_ = self:scalePixelValuesToScreenVector(46, 40)
	local v49_ = self.gaugeTextOffsets
	table.insert(v49_, {
		["offsetX"] = v47_,
		["offsetY"] = v48_,
		["alignment"] = v46_
	})
	local v50_ = RenderText.ALIGN_RIGHT
	local v51_, v52_ = self:scalePixelValuesToScreenVector(60, 19)
	local v53_ = self.gaugeTextOffsets
	table.insert(v53_, {
		["offsetX"] = v51_,
		["offsetY"] = v52_,
		["alignment"] = v50_
	})
	local v54_ = RenderText.ALIGN_RIGHT
	local v55_, v56_ = self:scalePixelValuesToScreenVector(64, -7)
	local v57_ = self.gaugeTextOffsets
	table.insert(v57_, {
		["offsetX"] = v55_,
		["offsetY"] = v56_,
		["alignment"] = v54_
	})
	local v58_ = RenderText.ALIGN_RIGHT
	local v59_, v60_ = self:scalePixelValuesToScreenVector(57, -33)
	local v61_ = self.gaugeTextOffsets
	table.insert(v61_, {
		["offsetX"] = v59_,
		["offsetY"] = v60_,
		["alignment"] = v58_
	})
	local v62_, v63_ = self:scalePixelValuesToScreenVector(58, 58)
	self.gaugeTextRadiusX = v62_
	self.gaugeTextRadiusY = v63_
	self.gaugeUnitTextSize = self:scalePixelToScreenHeight(9)
	self.gaugeFactorTextSize = self:scalePixelToScreenHeight(9)
	local v64_, v65_ = self:scalePixelValuesToScreenVector(-64, -50)
	self.gaugeUnitOffsetX = v64_
	self.gaugeUnitOffsetY = v65_
	local v66_, v67_ = self:scalePixelValuesToScreenVector(64, -50)
	self.gaugeFactorOffsetX = v66_
	self.gaugeFactorOffsetY = v67_
	self.speedTextSize = self:scalePixelToScreenHeight(52)
	local v68_, v69_ = self:scalePixelValuesToScreenVector(0, -12)
	self.speedTextOffsetX = v68_
	self.speedTextOffsetY = v69_
	self.speedUnitTextSize = self:scalePixelToScreenHeight(15)
	local v70_, v71_ = self:scalePixelValuesToScreenVector(0, -27)
	self.speedUnitTextOffsetX = v70_
	self.speedUnitTextOffsetY = v71_
	local v72_, v73_ = self:scalePixelValuesToScreenVector(-45, -73)
	self.workingHoursOffsetX = v72_
	self.workingHoursOffsetY = v73_
	local v74_, v75_ = self:scalePixelValuesToScreenVector(30, 30)
	self.workingHours:setDimension(v74_, v75_)
	self.workingHoursTextSize = self:scalePixelToScreenHeight(17)
	local v76_, v77_ = self:scalePixelValuesToScreenVector(35, -64)
	self.workingHoursTextOffsetX = v76_
	self.workingHoursTextOffsetY = v77_
	local v78_, v79_ = self:scalePixelValuesToScreenVector(-39, -43)
	self.workingHoursSeperatorOffsetX = v78_
	self.workingHoursSeperatorOffsetY = v79_
	local v80_, v81_ = self:scalePixelValuesToScreenVector(-30, -100)
	self.cruiseControlOffsetX = v80_
	self.cruiseControlOffsetY = v81_
	local v82_, v83_ = self:scalePixelValuesToScreenVector(30, 30)
	self.cruiseControl:setDimension(v82_, v83_)
	self.cruiseControlTextSize = self:scalePixelToScreenHeight(17)
	local v84_, v85_ = self:scalePixelValuesToScreenVector(2, -94)
	self.cruiseControlTextOffsetX = v84_
	self.cruiseControlTextOffsetY = v85_
	local v86_, v87_ = self:scalePixelValuesToScreenVector(-39, -73)
	self.cruiseControlSeperatorOffsetX = v86_
	self.cruiseControlSeperatorOffsetY = v87_
	self.seperatorWidth = self:scalePixelToScreenWidth(78)
	local v88_, v89_ = self:scalePixelValuesToScreenVector(9, 47)
	self.sectionOffsetX = v88_
	self.sectionOffsetY = v89_
	local v90_, v91_ = self:scalePixelValuesToScreenVector(30, 30)
	self.fuelIcon:setDimension(v90_, v91_)
	local v92_, v93_ = self:scalePixelValuesToScreenVector(-16, 144)
	self.fuelIconOffsetX = v92_
	self.fuelIconOffsetY = v93_
	self.fuelBarScaleWidth = self:scalePixelToScreenWidth(21)
	local v94_, v95_ = self:scalePixelValuesToScreenVector(0, 0)
	self.fuelBarOffsetX = v94_
	self.fuelBarOffsetY = v95_
	local v96_, v97_ = self:scalePixelValuesToScreenVector(-30, 0)
	self.fuelOffsetX = v96_
	self.fuelOffsetY = v97_
	local v98_, v99_ = self:scalePixelValuesToScreenVector(25, 30)
	self.repairIcon:setDimension(v98_, v99_)
	local v100_, v101_ = self:scalePixelValuesToScreenVector(-16, 144)
	self.repairIconOffsetX = v100_
	self.repairIconOffsetY = v101_
	local v102_, v103_ = self:scalePixelValuesToScreenVector(0, 0)
	self.repairBarOffsetX = v102_
	self.repairBarOffsetY = v103_
	self.repairBarScaleWidth = self:scalePixelToScreenWidth(21)
	local v104_, v105_ = self:scalePixelValuesToScreenVector(-30, 0)
	self.repairOffsetX = v104_
	self.repairOffsetY = v105_
	local v106_, v107_ = self:scalePixelValuesToScreenVector(30, 30)
	self.gearIcon:setDimension(v106_, v107_)
	local v108_, v109_ = self:scalePixelValuesToScreenVector(-16, 144)
	self.gearIconOffsetX = v108_
	self.gearIconOffsetY = v109_
	self.gearBarScaleWidth = self:scalePixelToScreenWidth(30)
	local v110_, v111_ = self:scalePixelValuesToScreenVector(-30, 0)
	self.gearOffsetX = v110_
	self.gearOffsetY = v111_
	local v112_, v113_ = self:scalePixelValuesToScreenVector(26, 26)
	self.gearBg:setDimension(v112_, v113_)
	self.gearTextOffsetY = {}
	self.gearTextOffsetY[1] = self:scalePixelToScreenHeight(9)
	self.gearTextOffsetY[2] = self:scalePixelToScreenHeight(37)
	self.gearTextOffsetY[3] = self:scalePixelToScreenHeight(65)
	self.gearGroupTextOffsetY = self:scalePixelToScreenHeight(102)
	self.gearTextSize = self:scalePixelToScreenHeight(12)
	self.gearBgOffsetX = self:scalePixelToScreenWidth(-13)
	local v114_ = self:scalePixelToScreenHeight(-8)
	self.gearBgOffsetY = {}
	self.gearBgOffsetY[1] = self.gearTextOffsetY[1] + v114_
	self.gearBgOffsetY[2] = self.gearTextOffsetY[2] + v114_
	self.gearBgOffsetY[3] = self.gearTextOffsetY[3] + v114_
	local v115_, v116_ = self:scalePixelValuesToScreenVector(6, 6)
	local v117_, _ = self:scalePixelValuesToScreenVector(130, 0)
	self.barMaxScaleWidth = v117_ - 2 * v115_
	self.bar:setLeftPart(nil, v115_, v116_)
	self.bar:setMiddlePart(nil, self.barMaxScaleWidth, v116_)
	self.bar:setRightPart(nil, v115_, v116_)
	local v118_, v119_ = self:scalePixelValuesToScreenVector(30, 30)
	self.aiWorkerIcon:setDimension(v118_, v119_)
	self.aiSteeringIcon:setDimension(v118_, v119_)
	local v120_, v121_ = self:scalePixelValuesToScreenVector(-109, 2)
	self.aiIconOffsetX = v120_
	self.aiIconOffsetY = v121_
	local v122_, v123_ = self:scalePixelValuesToScreenVector(-49, 12)
	self.aiTextOffsetX = v122_
	self.aiTextOffsetY = v123_
	self.aiTextSize = self:scalePixelToScreenHeight(16)
	local v124_, v125_ = self:scalePixelValuesToScreenVector(-114, 34)
	self.aiSeperatorOffsetX = v124_
	self.aiSeperatorOffsetY = v125_
	self.aiSeperatorWidth = self:scalePixelToScreenWidth(100)
end

function SpeedMeterDisplay:update(dt)
	SpeedMeterDisplay:superClass().update(self, dt)
	self.isVehicleDrawSafe = true
end

-- Local values: vehicle, scaleWidth, _, hasFuel, fuelLevel, fuelCapacity, isMotorized, hasRepair, hasGear, posX, posY, selectedAIMode, activeColor, startX, startY, endX, endY, timeSinceLastModeChange, modeName, alpha, aiIcon, text, r, g, b, a, steeringState, gpsTextPosX, gpsTextPosY, sectionPosX, sectionPosY, fuelSectionPosY, fuelPercentage, barScale, repairSectionPosY, damageValue, vehicles, _, subVehicle, barScale, gearSectionPosY
function SpeedMeterDisplay:draw()
	local v129_ = self.vehicle
	if v129_ ~= nil and self.isVehicleDrawSafe then
		local v130_ = 0
		local v131_, v132_, v133_
		if v129_.spec_motorized ~= nil then
			local v134_
			v131_, v132_, v134_ = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(v129_)
			v133_ = v132_ ~= nil
			v130_ = v130_ + self.fuelBarScaleWidth
		else
			v133_ = false
			v131_ = nil
			v132_ = nil
		end
		local v135_
		if v129_.getDamageAmount == nil or v129_:getDamageAmount() == nil then
			v135_ = false
		else
			v130_ = v130_ + self.repairBarScaleWidth
			v135_ = true
		end
		local v136_ = v130_ + self.gearBarScaleWidth
		local v137_, v138_ = self:getPosition()
		self.speedBgRight:setPosition(v137_ - self.speedBgRight.width, v138_)
		self.speedBgScale:setDimension(v136_, nil)
		self.speedBgScale:setPosition(self.speedBgRight.x - self.speedBgScale.width, v138_)
		self.speedBg:setPosition(self.speedBgScale.x - self.speedBg.width, v138_)
		self.speedBg:render()
		self.speedBgScale:render()
		self.speedBgRight:render()
		self:drawSpeedMeter(self.speedBg.x + self.speedGaugeCenterOffsetX, self.speedBg.y + self.speedGaugeCenterOffsetY)
		if v129_.getAIAutomaticSteeringState ~= nil then
			local v139_ = v129_:getAIModeSelection()
			local v140_ = HUD.COLOR.ACTIVE
			local v141_ = v137_ + self.aiSeperatorOffsetX
			local v142_ = v138_ + self.aiSeperatorOffsetY
			local v143_ = v141_ + self.aiSeperatorWidth
			drawLine2D(v141_, v142_, v143_, v142_, g_pixelSizeY, v140_[1], v140_[2], v140_[3], v140_[4])
			local v144_ = g_time - v129_.spec_aiModeSelection.lastModeChangeTime
			if v144_ < 2500 then
				local v145_ = g_i18n:getText(AIModeSelection.MODE_TEXTS[v139_])
				local v146_ = v144_ / 2500 * 3.141592653589793 * 3 - 1.5707963267948966
				local v147_ = math.sin(v146_) * 0.5 + 0.5
				setTextColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], v147_)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v141_ + self.aiSeperatorWidth * 0.5, v138_ + self.aiTextOffsetY, self.aiTextSize, v145_)
			else
				local v148_ = self.aiWorkerIcon
				local v149_ = self.aiInactiveText
				local v150_ = 1
				local v151_ = 1
				local v152_ = 1
				local v153_ = 1
				if v139_ == AIModeSelection.MODE.STEERING_ASSIST then
					v148_ = self.aiSteeringIcon
					local v154_ = v129_:getAIAutomaticSteeringState()
					if v154_ == AIAutomaticSteering.STATE.AVAILABLE then
						v150_ = HUD.COLOR.AVAILABLE[1]
						v151_ = HUD.COLOR.AVAILABLE[2]
						v152_ = HUD.COLOR.AVAILABLE[3]
						v153_ = HUD.COLOR.AVAILABLE[4]
						v149_ = self.aiReadyText
					elseif v154_ == AIAutomaticSteering.STATE.ACTIVE then
						v150_ = HUD.COLOR.ACTIVE[1]
						v151_ = HUD.COLOR.ACTIVE[2]
						v152_ = HUD.COLOR.ACTIVE[3]
						v153_ = HUD.COLOR.ACTIVE[4]
						v149_ = self.aiActiveText
					end
				elseif v129_:getIsAIActive() then
					v150_ = HUD.COLOR.ACTIVE[1]
					v151_ = HUD.COLOR.ACTIVE[2]
					v152_ = HUD.COLOR.ACTIVE[3]
					v153_ = HUD.COLOR.ACTIVE[4]
					v149_ = self.aiActiveText
				end
				local v155_ = v137_ + self.aiTextOffsetX
				local v156_ = v138_ + self.aiTextOffsetY
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(v155_, v156_, self.aiTextSize, v149_)
				v148_:setColor(v150_, v151_, v152_, v153_)
				v148_:setPosition(v137_ + self.aiIconOffsetX, v138_ + self.aiIconOffsetY)
				v148_:render()
			end
			setTextBold(false)
			setTextColor(1, 1, 1, 1)
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
		local v157_ = v137_ + self.sectionOffsetX
		local v158_ = v138_ + self.sectionOffsetY
		if v133_ then
			v157_ = v157_ + self.fuelOffsetX
			local v159_ = v158_ + self.fuelOffsetY
			self.fuelIcon:setPosition(v157_ + self.fuelIconOffsetX, v159_ + self.fuelIconOffsetY)
			self.fuelIcon:render()
			self.bar:setColor(0, 0, 0, 1)
			self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
			self.bar:setPosition(v157_ + self.fuelBarOffsetX, v159_ + self.fuelBarOffsetY)
			self.bar:render()
			local v160_ = v131_ / v132_
			if v160_ > 0 then
				if v160_ > 0.1 then
					self.bar:setColor(1, 0.4287, 0.0006, 1)
				else
					local v161_ = self.bar
					local v162_ = g_time / 300
					local v163_ = math.cos(v162_)
					v161_:setColor(1, 0.1233, 0, (math.abs(v163_)))
				end
				local v164_ = self.barMaxScaleWidth * v160_
				local v165_ = self.barMaxScaleWidth
				local v166_ = math.clamp(v164_, 0, v165_)
				self.bar:setMiddlePart(nil, v166_, nil)
				self.bar:setPosition(v157_ + self.fuelBarOffsetX, v159_ + self.fuelBarOffsetY)
				self.bar:render()
			end
		end
		if v135_ then
			v157_ = v157_ + self.repairOffsetX
			local v167_ = v158_ + self.repairOffsetY
			self.repairIcon:setPosition(v157_ + self.repairIconOffsetX, v167_ + self.repairIconOffsetY)
			self.repairIcon:render()
			self.bar:setColor(0, 0, 0, 1)
			self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
			self.bar:setPosition(v157_ + self.repairBarOffsetX, v167_ + self.repairBarOffsetY)
			self.bar:render()
			local v168_ = v129_.rootVehicle.childVehicles
			local v169_ = 1
			for _, v170_ in ipairs(v168_) do
				if v170_.getDamageShowOnHud ~= nil and v170_:getDamageShowOnHud() then
					local v171_ = 1 - v170_:getDamageAmount()
					v169_ = math.min(v169_, v171_)
				end
			end
			if v169_ > 0 then
				if v169_ > 0.2 then
					self.bar:setColor(0.0097, 0.4287, 0.6445, 1)
				else
					self.bar:setColor(1, 0.1233, 0, 1)
				end
				local v172_ = self.barMaxScaleWidth * v169_
				local v173_ = self.barMaxScaleWidth
				local v174_ = math.clamp(v172_, 0, v173_)
				self.bar:setMiddlePart(nil, v174_, nil)
				self.bar:setPosition(v157_ + self.repairBarOffsetX, v167_ + self.repairBarOffsetY)
				self.bar:render()
			end
		end
		local v175_ = v157_ + self.gearOffsetX
		local v176_ = v158_ + self.gearOffsetY
		self.gearIcon:setPosition(v175_ + self.gearIconOffsetX, v176_ + self.gearIconOffsetY)
		self.gearIcon:render()
		self:drawGearText(v175_, v176_)
	end
end

-- Local values: vehicle, speedGaugeUseMiles, speedGaugeMode, motorizedSpec, lastSpeed, kmh, speedKmh, speed, unitText, value, minGaugeValue, maxGaugeValue, gaugeRounding, motor, fixedLowerLimit, scale, range, stepDistance, minValue, maxValue, pivotX, pivotY, offset, angle, inactiveColor, activeColor, i, rotation, cosRot, sinRot, indicatorPosX, indicatorPosY, indicatorValue, r, g, b, a, i, data, textPosX, textPosY, textValue, text, gaugeUnitPosX, gaugeUnitPosY, gaugeFactorPosX, gaugeFactorPosY, speedPosX, speedPosY, speedUnit, speedUnitPosX, speedUnitPosY, startX, startY, endX, endY, workingHoursPosX, workingHoursPosY, minutes, hours, cruiseControlSpeed, isActive, cruiseControlPosX, cruiseControlPosY
function SpeedMeterDisplay:drawSpeedMeter(centerX, centerY)
	local v180_ = self.vehicle
	if v180_ ~= nil then
		local v181_ = g_gameSettings:getValue(GameSettings.SETTING.USE_MILES)
		local v182_ = g_gameSettings:getValue(GameSettings.SETTING.HUD_SPEED_GAUGE)
		local v183_ = v180_.spec_motorized
		if v183_.forceSpeedHudDisplay then
			v182_ = SpeedMeterDisplay.GAUGE_MODE_SPEED
		elseif v183_.forceRpmHudDisplay then
			v182_ = SpeedMeterDisplay.GAUGE_MODE_RPM
		end
		local v184_ = v180_:getLastSpeed()
		local v185_ = v184_ * v180_.spec_motorized.speedDisplayScale
		local v186_ = math.clamp(v185_, 0, 999)
		local v187_ = v186_ < 0.5 and 0 or v186_
		local v188_ = g_i18n:getSpeed(v187_)
		local v189_ = math.floor(v188_)
		local v190_ = v188_ - v189_
		if math.abs(v190_) > 0.5 then
			v189_ = v189_ + 1
		end
		local v191_ = v180_:getMotor()
		local v192_ = false
		local v193_, v194_, v195_, v196_, v197_
		if v182_ == SpeedMeterDisplay.GAUGE_MODE_RPM then
			v193_ = self.rpmUnitText
			v194_ = v191_:getMinRpm()
			v195_ = v191_:getMaxRpm()
			v196_ = v180_:getMotorRpmReal()
			v197_ = 200
		else
			v193_ = self.kmhUnitText
			local v198_
			if v181_ then
				v193_ = self.mphUnitText
				v198_ = 0.621371
			else
				v198_ = 1
			end
			v195_ = v191_:getMaximumForwardSpeed() * 3.6 * v198_
			v196_ = v184_ * v198_
			v194_ = 0
			v197_ = 5
			v192_ = true
		end
		local v199_ = (v195_ - v194_) / 8 / v197_
		local v200_ = math.ceil(v199_) * v197_
		local v201_ = v194_ / v197_
		local v202_ = math.floor(v201_) * v197_ - v200_
		local v203_ = v195_ / v197_
		local v204_ = math.floor(v203_) * v197_ + v200_
		if not v192_ then
			v194_ = v202_
		end
		self.lastGaugeValue = self.lastGaugeValue * 0.95 + v196_ * 0.05
		local v205_ = self.speedIndicatorBg.width * 0.5
		local v206_ = HUD.COLOR.INACTIVE
		local v207_ = HUD.COLOR.ACTIVE
		for v208_ = SpeedMeterDisplay.NUMBER_OF_INDICATORS, 1, -1 do
			local v209_ = v208_ * 0.17453292519943295 + -0.6108652381980153
			local v210_ = math.cos(v209_)
			local v211_ = math.sin(v209_)
			local v212_ = centerX + v210_ * self.speedGaugeRadiusX - v205_
			local v213_ = centerY + v211_ * self.speedGaugeRadiusY - 0
			self.speedIndicatorBg:setPosition(v212_, v213_)
			self.speedIndicatorBg:setRotation(v209_ - 1.5707963267948966, v205_, 0)
			local v214_ = MathUtil.lerp(v194_, v204_, 1 - v208_ / SpeedMeterDisplay.NUMBER_OF_INDICATORS)
			local v215_, v216_, v217_, v218_
			if v196_ > 0.5 and v214_ < v196_ then
				v215_ = v207_[1]
				v216_ = v207_[2]
				v217_ = v207_[3]
				v218_ = v207_[4]
			else
				v215_ = v206_[1]
				v216_ = v206_[2]
				v217_ = v206_[3]
				v218_ = v206_[4]
			end
			self.speedIndicatorBg:setColor(v215_, v216_, v217_, v218_)
			self.speedIndicatorBg:render()
		end
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_CENTER)
		for v219_ = 1, 10 do
			local v220_ = self.gaugeTextOffsets[v219_]
			local v221_ = centerX + v220_.offsetX
			local v222_ = centerY + v220_.offsetY
			setTextAlignment(v220_.alignment)
			setTextBold(true)
			local v223_ = MathUtil.lerp(v194_, v204_, (v219_ - 1) / 9)
			if v182_ == SpeedMeterDisplay.GAUGE_MODE_RPM then
				v223_ = v223_ / 100
			end
			local v224_ = string.format("%d", v223_)
			renderText(v221_, v222_, self.gaugeUnitTextSize, v224_)
		end
		local v225_ = centerX + self.gaugeUnitOffsetX
		local v226_ = centerY + self.gaugeUnitOffsetY
		setTextRotation(0.5235987755982988, v225_, v226_)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(v207_[1], v207_[2], v207_[3], v207_[4])
		renderText(v225_, v226_, self.gaugeUnitTextSize, v193_)
		setTextColor(1, 1, 1, 1)
		if v182_ == SpeedMeterDisplay.GAUGE_MODE_RPM then
			local v227_ = centerX + self.gaugeFactorOffsetX
			local v228_ = centerY + self.gaugeFactorOffsetY
			setTextRotation(-0.5235987755982988, v227_, v228_)
			renderText(v227_, v228_, self.gaugeFactorTextSize, "x100")
		end
		setTextRotation(0, 0, 0)
		local v229_ = centerX + self.speedTextOffsetX
		local v230_ = centerY + self.speedTextOffsetY
		setTextBold(true)
		renderText(v229_, v230_, self.speedTextSize, string.format("%1d", v189_))
		local v231_ = utf8ToUpper(g_i18n:getSpeedMeasuringUnit())
		local v232_ = centerX + self.speedUnitTextOffsetX
		local v233_ = centerY + self.speedUnitTextOffsetY
		setTextColor(v207_[1], v207_[2], v207_[3], v207_[4])
		renderText(v232_, v233_, self.speedUnitTextSize, v231_)
		setTextColor(1, 1, 1, 1)
		local v234_ = centerX + self.workingHoursSeperatorOffsetX
		local v235_ = centerY + self.workingHoursSeperatorOffsetY
		local v236_ = v234_ + self.seperatorWidth
		drawLine2D(v234_, v235_, v236_, v235_, g_pixelSizeY, v207_[1], v207_[2], v207_[3], v207_[4])
		local v237_ = centerX + self.workingHoursTextOffsetX
		local v238_ = centerY + self.workingHoursTextOffsetY
		if v180_.operatingTime == nil then
			setTextColor(1, 1, 1, 1)
			renderText(v237_, v238_, self.workingHoursTextSize, "-/-")
		else
			local v239_ = v180_.operatingTime / 60000
			local v240_ = v239_ / 60
			local v241_ = math.floor(v240_)
			local v242_ = (v239_ - v241_ * 60) / 6
			local v243_ = math.floor(v242_)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			setTextColor(1, 1, 1, 0.3)
			renderText(v237_, v238_, self.workingHoursTextSize, string.format("%03d.%dh", v241_, v243_))
			setTextColor(1, 1, 1, 1)
			renderText(v237_, v238_, self.workingHoursTextSize, string.format("%d.%dh", v241_, v243_))
		end
		self.workingHours:setPosition(centerX + self.workingHoursOffsetX, centerY + self.workingHoursOffsetY)
		self.workingHours:render()
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v244_ = centerX + self.cruiseControlSeperatorOffsetX
		local v245_ = centerY + self.cruiseControlSeperatorOffsetY
		local v246_ = v244_ + self.seperatorWidth
		drawLine2D(v244_, v245_, v246_, v245_, g_pixelSizeY, v207_[1], v207_[2], v207_[3], v207_[4])
		local v247_, v248_ = self.vehicle:getCruiseControlDisplayInfo()
		local v249_ = string.format("%d", g_i18n:getSpeed(v247_))
		if v248_ then
			setTextColor(v207_[1], v207_[2], v207_[3], v207_[4])
		else
			setTextColor(1, 1, 1, 1)
		end
		local v250_ = centerX + self.cruiseControlTextOffsetX
		local v251_ = centerY + self.cruiseControlTextOffsetY
		renderText(v250_, v251_, self.cruiseControlTextSize, (tostring(v249_)))
		self.cruiseControl:setPosition(centerX + self.cruiseControlOffsetX, centerY + self.cruiseControlOffsetY)
		self.cruiseControl:render()
	end
end

-- Local values: gearName, gearGroupName, _gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning, gearSelectedIndex, gearGroupText, i, alpha, renderBg
function SpeedMeterDisplay:drawGearText(x, y)
	if self.vehicle ~= nil then
		local v255_, v256_, _, v257_, v258_, v259_, v260_, v261_, v262_, v263_ = self.vehicle:getGearInfoToDisplay()
		local v264_ = 1
		local v265_ = ""
		if v255_ == nil or v257_ then
			if v255_ ~= nil and v257_ then
				self.gearTexts[1] = "R"
				self.gearTexts[2] = "N"
				self.gearTexts[3] = "D"
				if v255_ == "N" then
					v264_ = 2
				elseif v255_ == "D" then
					v264_ = 3
				elseif v255_ == "R" then
					v264_ = 1
				end
			end
		else
			v265_ = v256_ or ""
			if v259_ == nil and v258_ == nil then
				self.gearTexts[1] = ""
				self.gearTexts[2] = v255_
				self.gearTexts[3] = ""
				v264_ = 2
			elseif v259_ == nil then
				if v260_ == nil then
					self.gearTexts[1] = v258_
					self.gearTexts[2] = v255_
					self.gearTexts[3] = ""
					v264_ = 2
				else
					self.gearTexts[1] = v260_
					self.gearTexts[2] = v258_
					self.gearTexts[3] = v255_
					v264_ = 3
				end
			elseif v258_ == nil then
				self.gearTexts[1] = v255_
				self.gearTexts[2] = v259_
				self.gearTexts[3] = v261_ or ""
				v264_ = 1
			else
				self.gearTexts[1] = v258_
				self.gearTexts[2] = v255_
				self.gearTexts[3] = v259_
				v264_ = 2
			end
		end
		if v263_ then
			self.gearWarningTime = self.gearWarningTime + g_currentDt
		else
			self.gearWarningTime = 0
		end
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		if v265_ ~= nil then
			renderText(x, y + self.gearGroupTextOffsetY, self.gearTextSize, v265_)
		end
		for v266_ = 1, 3 do
			local v267_ = false
			local v268_
			if v266_ == 2 then
				local v269_ = self.gearWarningTime / 200
				local v270_ = math.cos(v269_)
				v268_ = math.abs(v270_)
			else
				v268_ = 1
			end
			if v264_ == v266_ then
				if v262_ then
					v268_ = v268_ * 0.5
				end
				v267_ = true
			end
			if v267_ then
				self.gearBg:setColor(nil, nil, nil, v268_)
				self.gearBg:setPosition(x + self.gearBgOffsetX, y + self.gearBgOffsetY[v266_])
				self.gearBg:render()
			end
			renderText(x, y + self.gearTextOffsetY[v266_], self.gearTextSize, self.gearTexts[v266_])
		end
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

-- Local values: hasVehicle, isMotorized, _, capacity, fuelType, needFuelGauge, fuelGaugeIconSliceId
function SpeedMeterDisplay:setVehicle(vehicle)
	self.vehicle = nil
	local v273_ = vehicle ~= nil
	local v274_
	if v273_ then
		v274_ = vehicle.spec_motorized ~= nil
	else
		v274_ = v273_
	end
	if v273_ and v274_ then
		self.vehicle = vehicle
		local _, v275_, v276_ = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
		if v275_ ~= nil then
			local v277_ = v276_ == FillType.ELECTRICCHARGE and "gui.icon_electricCharge" or (v276_ == FillType.METHANE and "gui.icon_methane" or "gui.icon_fuel")
			self.fuelIcon:setSliceId(v277_)
		end
	end
	self:setVisible(self.vehicle ~= nil)
	self.isVehicleDrawSafe = false
end

-- Local values: fuelType, fillUnitIndex, level, capacity
function SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
	local v279_ = FillType.DIESEL
	local v280_ = vehicle:getConsumerFillUnitIndex(v279_)
	if v280_ == nil then
		v279_ = FillType.ELECTRICCHARGE
		v280_ = vehicle:getConsumerFillUnitIndex(v279_)
		if v280_ == nil then
			v279_ = FillType.METHANE
			v280_ = vehicle:getConsumerFillUnitIndex(v279_)
		end
	end
	return vehicle:getFillUnitFillLevel(v280_), vehicle:getFillUnitCapacity(v280_), v279_
end
if v1_ ~= nil then
	local v281_ = SpeedMeterDisplay.new()
	v281_:setVehicle(v1_.vehicle)
	v281_:setScale(v1_.uiScale)
	v281_:setVisible(v1_.isVisible)
	g_currentMission.hud.speedMeter = v281_
	g_currentMission.hud.displayComponents.speedMeter = v281_
	Logging.info("Reloaded")
end
