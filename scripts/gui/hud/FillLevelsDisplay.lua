-- Local values: data, old, FillLevelsDisplay_mt, fillLevelsDisplay
local v1_
if FillLevelsDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.fillLevelsDisplay
	v1_ = {
		["vehicle"] = v2_.vehicle,
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
FillLevelsDisplay = {}
FillLevelsDisplay.TYPE_BAR = 1
FillLevelsDisplay.TYPE_STEP = 2
FillLevelsDisplay.MAX_BOXES = 5
FillLevelsDisplay.MAX_NUM_STEPS = 25
local data = Class(FillLevelsDisplay, HUDDisplay)
function FillLevelsDisplay.new()
	-- upvalues: (copy) data
	local v4_ = FillLevelsDisplay:superClass().new(data)
	local v5_ = HUD.COLOR.BACKGROUND
	local v6_, v7_, v8_, v9_ = unpack(v5_)
	v4_.bgScale = g_overlayManager:createOverlay("gui.filltypes_middle", 0, 0, 0, 0)
	v4_.bgScale:setColor(v6_, v7_, v8_, v9_)
	v4_.bgLeft = g_overlayManager:createOverlay("gui.filltypes_left", 0, 0, 0, 0)
	v4_.bgLeft:setColor(v6_, v7_, v8_, v9_)
	v4_.bgRight = g_overlayManager:createOverlay("gui.filltypes_right", 0, 0, 0, 0)
	v4_.bgRight:setColor(v6_, v7_, v8_, v9_)
	v4_.maxWeightIcon = g_overlayManager:createOverlay("gui.vehicleOverview_maxWeight", 0, 0, 0, 0)
	v4_.bar = ThreePartOverlay.new()
	v4_.bar:setLeftPart("gui.progressbar_left", 0, 0)
	v4_.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	v4_.bar:setRightPart("gui.progressbar_right", 0, 0)
	v4_.vehicle = nil
	v4_.fillTypeIcons = {}
	v4_.fillLevelData = {}
	return v4_
end

-- Local values: _, icon
function FillLevelsDisplay:delete()
	self.bgLeft:delete()
	self.bgRight:delete()
	self.bgScale:delete()
	self.maxWeightIcon:delete()
	self.bar:delete()
	for _, v11_ in pairs(self.fillTypeIcons) do
		v11_:delete()
	end
end

-- Local values: posX, posY, bgLeftWidth, bgHeight, bgRightWidth, bgScaleWidth, barPartWidth, barPartHeight, barTotalWidth, _, weightIconWidth, weightIconHeight, _, icon
function FillLevelsDisplay:storeScaledValues()
	local v13_, v14_ = self:scalePixelValuesToScreenVector(0, 236)
	self.offsetX = v13_
	self.offsetY = v14_
	local v15_ = g_hudAnchorRight
	local v16_ = g_hudAnchorBottom
	self:setPosition(v15_, v16_)
	local v17_, v18_ = self:scalePixelValuesToScreenVector(12, 45)
	local v19_ = self:scalePixelToScreenWidth(12)
	local v20_ = self:scalePixelToScreenWidth(290) - v17_ - v19_
	self.bgTotalWidth = v20_ + v17_ + v19_
	self.bgLeft:setDimension(v17_, v18_)
	self.bgRight:setDimension(v19_, v18_)
	self.bgScale:setDimension(v20_, v18_)
	self.bgRight:setPosition(v15_ - self.bgRight.width, nil)
	self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, nil)
	self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, nil)
	self.boxOffsetY = self:scalePixelToScreenHeight(5)
	self.fillTypeTextSize = self:scalePixelToScreenHeight(14)
	self.fillLevelTextSize = self:scalePixelToScreenHeight(14)
	local v21_, v22_ = self:scalePixelValuesToScreenVector(40, 22)
	self.fillTypeTextOffsetX = v21_
	self.fillTypeTextOffsetY = v22_
	local v23_, v24_ = self:scalePixelValuesToScreenVector(-12, 22)
	self.fillLevelTextOffsetX = v23_
	self.fillLevelTextOffsetY = v24_
	self.typeLevelOffsetX = self:scalePixelToScreenWidth(5)
	local v25_, v26_ = self:scalePixelValuesToScreenVector(3, 6)
	local v27_, _ = self:scalePixelValuesToScreenVector(237, 0)
	self.barTotalWidth = v27_
	self.barHeight = v26_
	self.barMinWidth = 2 * v25_
	self.barMaxScaleWidth = v27_ - 2 * v25_
	self.bar:setLeftPart(nil, v25_, v26_)
	self.bar:setMiddlePart(nil, self.barMaxScaleWidth, v26_)
	self.bar:setRightPart(nil, v25_, v26_)
	local v28_, v29_ = self:scalePixelValuesToScreenVector(40, 9)
	self.barOffsetX = v28_
	self.barOffsetY = v29_
	self.barStepOffsetX = self:scalePixelToScreenWidth(3)
	local v30_, v31_ = self:scalePixelValuesToScreenVector(7, 9)
	self.iconOffsetX = v30_
	self.iconOffsetY = v31_
	local v32_, v33_ = self:scalePixelValuesToScreenVector(27, 27)
	self.iconWidth = v32_
	self.iconHeight = v33_
	local v34_, v35_ = self:scalePixelValuesToScreenVector(50, 17)
	self.maxWeightIcon:setDimension(v34_, v35_)
	for _, v36_ in pairs(self.fillTypeIcons) do
		v36_:setDimension(self.iconWidth, self.iconHeight)
	end
	self.helpAnchorPosX = self.bgLeft.x + self:scalePixelToScreenWidth(-15)
	self.helpAnchorPosY = v16_ + self.bgScale.height * 0.5
end

function FillLevelsDisplay:update(dt)
	FillLevelsDisplay:superClass().update(self, dt)
	if self.vehicle ~= nil then
		self:updateFillLevelData()
	end
end

-- Local values: posX, posY, _, data, height
function FillLevelsDisplay:draw()
	FillLevelsDisplay:superClass().draw(self)
	local v40_, v41_ = self:getPosition()
	if g_currentMission.hud.speedMeter:getVisible() then
		v40_ = v40_ + self.offsetX
		v41_ = v41_ + self.offsetY
	end
	for _, v42_ in ipairs(self.fillLevelData) do
		if v42_.isValid then
			v41_ = v41_ + self:drawFillLevel(v40_, v41_, v42_) + self.boxOffsetY
			v42_.isValid = false
		end
	end
end

-- Local values: barBgColor, activeColor, icon, scale, fillTypeText, textLength, maxWidth, text, numSteps, _, numFilledSteps, fractialStep, numOffsets, barWidth, barScaleWidth, barPosX, barPosY, i, scale, fillTypeText, textLength, maxWidth, text, weightIconPosX, weightIconPosY
function FillLevelsDisplay:drawFillLevel(posX, posY, data)
	local v47_ = HUD.COLOR.BACKGROUND_DARK
	local v48_ = HUD.COLOR.ACTIVE
	self.bgRight:setPosition(nil, posY)
	self.bgLeft:setPosition(nil, posY)
	self.bgScale:setPosition(nil, posY)
	self.bgRight:render()
	self.bgLeft:render()
	self.bgScale:render()
	local v49_ = self.fillTypeIcons[data.fillType]
	if v49_ ~= nil then
		v49_:setPosition(self.bgLeft.x + self.iconOffsetX, self.bgLeft.y + self.iconOffsetY)
		v49_:render()
	end
	if data.typeId == FillLevelsDisplay.TYPE_BAR then
		self.bar:setColor(v47_[1], v47_[2], v47_[3], v47_[4])
		self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
		self.bar:setPosition(self.bgLeft.x + self.barOffsetX, self.bgLeft.y + self.barOffsetY)
		self.bar:render()
		local v50_ = data.capacity <= 0 and 0 or data.fillLevel / data.capacity
		if v50_ > 0 then
			self.bar:setColor(v48_[1], v48_[2], v48_[3], v48_[4])
			self.bar:setMiddlePart(nil, self.barMaxScaleWidth * v50_, nil)
			self.bar:setPosition(self.bar.x, self.bar.y)
			self.bar:render()
		end
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX + self.fillLevelTextOffsetX, self.bgLeft.y + self.fillLevelTextOffsetY, self.fillLevelTextSize, data.fillLevelText)
		local v51_ = data.customFillTypeText
		if v51_ == nil and data.fillType ~= FillType.UNKNOWN then
			v51_ = g_fillTypeManager:getFillTypeTitleByIndex(data.fillType)
		end
		if v51_ ~= nil then
			if data.infoText ~= nil then
				v51_ = v51_ .. " (" .. data.infoText .. ")"
			end
			local v52_ = getTextWidth(self.fillLevelTextSize, data.fillLevelText)
			local v53_ = self.bgTotalWidth - v52_ - self.fillTypeTextOffsetX
			local v54_ = self.fillLevelTextOffsetX
			local v55_ = v53_ - math.abs(v54_) - self.typeLevelOffsetX
			local v56_ = Utils.limitTextToWidth(v51_, self.fillTypeTextSize, v55_, false, "...")
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(self.bgLeft.x + self.fillTypeTextOffsetX, self.bgLeft.y + self.fillTypeTextOffsetY, self.fillTypeTextSize, v56_)
			setTextBold(false)
		end
	elseif data.typeId == FillLevelsDisplay.TYPE_STEP then
		local v57_ = data.capacity
		local v58_, _ = math.modf(v57_)
		local v59_ = data.fillLevel
		local v60_, v61_ = math.modf(v59_)
		local v62_ = v60_ + 1
		local v63_ = FillLevelsDisplay.MAX_NUM_STEPS
		local v64_ = math.clamp(v58_, 1, v63_)
		local v65_ = v64_ - 1
		local v66_ = (self.barTotalWidth - self.barStepOffsetX * v65_ - self.barMinWidth * v64_) / v64_
		self.bar:setMiddlePart(nil, v66_, nil)
		local v67_ = self.bgLeft.x + self.barOffsetX
		local v68_ = self.bgLeft.y + self.barOffsetY
		for v69_ = 1, v64_ do
			self.bar:setColor(v47_[1], v47_[2], v47_[3], v47_[4])
			self.bar:setPosition(v67_, v68_)
			self.bar:setMiddlePart(nil, v66_, nil)
			self.bar:render()
			local v70_ = 0
			local v71_
			if v69_ == v62_ then
				v71_ = v61_
			else
				v71_ = v69_ < v62_ and 1 or v70_
			end
			if v71_ > 0 then
				self.bar:setColor(v48_[1], v48_[2], v48_[3], v48_[4])
				self.bar:setMiddlePart(nil, v66_ * v71_, nil)
				self.bar:render()
			end
			v67_ = v67_ + self.barMinWidth + v66_ + self.barStepOffsetX
		end
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX + self.fillLevelTextOffsetX, self.bgLeft.y + self.fillLevelTextOffsetY, self.fillLevelTextSize, data.fillLevelText)
		local v72_ = data.customFillTypeText
		if v72_ == nil and data.fillType ~= FillType.UNKNOWN then
			v72_ = g_fillTypeManager:getFillTypeTitleByIndex(data.fillType)
		end
		if v72_ ~= nil then
			local v73_ = getTextWidth(self.fillLevelTextSize, data.fillLevelText)
			local v74_ = self.bgTotalWidth - v73_ - self.fillTypeTextOffsetX
			local v75_ = self.fillLevelTextOffsetX
			local v76_ = v74_ - math.abs(v75_) - self.typeLevelOffsetX
			local v77_ = Utils.limitTextToWidth(v72_, self.fillTypeTextSize, v76_, false, "...")
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(self.bgLeft.x + self.fillTypeTextOffsetX, self.bgLeft.y + self.fillTypeTextOffsetY, self.fillTypeTextSize, v77_)
			setTextBold(false)
		end
	end
	if data.maxReached then
		local v78_ = self.bgLeft.x + self.barOffsetX + self.barTotalWidth * 0.5 - self.maxWeightIcon.width * 0.5
		local v79_ = self.bgLeft.y + self.barOffsetY + self.barHeight * 0.5 - self.maxWeightIcon.height * 0.5
		self.maxWeightIcon:setPosition(v78_, v79_)
		self.maxWeightIcon:render()
	end
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	return self.bgScale.height
end

function FillLevelsDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end

-- Local values: _, v
function FillLevelsDisplay:resetFillTypes()
	for _, v83_ in pairs(self.fillTypeIcons) do
		v83_:delete()
	end
	table.clear(self.fillTypeIcons)
end

-- Local values: k, data, value, precision, formattedNumber, rounded, fillTypeDesc
function FillLevelsDisplay:updateFillLevelData()
	self.vehicle:getFillLevelInformation(self)
	for _, v85_ in ipairs(self.fillLevelData) do
		if not v85_.isValid then
			break
		end
		if v85_.capacity > 0 or v85_.fillLevel > 0 then
			if v85_.typeId == FillLevelsDisplay.TYPE_BAR then
				local v86_ = v85_.capacity <= 0 and 0 or v85_.fillLevel / v85_.capacity
				local v87_ = v85_.precision or 0
				local v88_
				if v87_ > 0 then
					local v89_ = MathUtil.round(v85_.fillLevel, v87_)
					v88_ = string.format("%d%s%0" .. v87_ .. "d", math.floor(v89_), g_i18n.decimalSeparator, (v89_ - math.floor(v89_)) * 10 ^ v87_)
				else
					v88_ = string.format("%d", MathUtil.round(v85_.fillLevel))
				end
				local v90_ = g_fillTypeManager:getFillTypeByIndex(v85_.fillType)
				local v91_ = string.format
				local v92_ = v90_.unitShort or ""
				local v93_ = 100 * v86_
				v85_.fillLevelText = v91_("%s%s (%d%%)", v88_, v92_, (math.floor(v93_)))
			elseif v85_.typeId == FillLevelsDisplay.TYPE_STEP then
				local v94_ = string.format
				local v95_ = v85_.fillLevel
				v85_.fillLevelText = v94_("%d / %d", math.ceil(v95_), v85_.capacity)
			end
		end
	end
end

-- Local values: dataItem, k, data, fillTypeDesc, iconOverlay
function FillLevelsDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached, typeId, customFillTypeText, infoText)
	local v105_ = typeId or FillLevelsDisplay.TYPE_BAR
	local v106_ = nil
	for _, v107_ in ipairs(self.fillLevelData) do
		if not v107_.isValid then
			v107_.capacity = 0
			v107_.fillLevel = 0
			v106_ = v107_
			break
		end
		if v107_.fillType == fillType and (v107_.typeId == v105_ and v107_.infoText == infoText) then
			v106_ = v107_
			break
		end
	end
	if v106_ == nil and #self.fillLevelData < FillLevelsDisplay.MAX_BOXES then
		v106_ = {
			["fillLevel"] = 0,
			["capacity"] = 0
		}
		local v108_ = self.fillLevelData
		table.insert(v108_, v106_)
	end
	if v106_ ~= nil then
		v106_.isValid = true
		v106_.customFillTypeText = customFillTypeText
		v106_.infoText = infoText
		v106_.typeId = v105_
		v106_.fillType = fillType
		v106_.fillLevel = v106_.fillLevel + fillLevel
		v106_.capacity = v106_.capacity + capacity
		v106_.precision = precision
		v106_.maxReached = maxReached
		if self.fillTypeIcons[fillType] == nil then
			local v109_ = g_fillTypeManager:getFillTypeByIndex(fillType)
			local v110_ = Overlay.new(v109_.hudOverlayFilename, 0, 0, self.iconWidth, self.iconHeight)
			self.fillTypeIcons[fillType] = v110_
		end
	end
end

-- Local values: posX, posY
function FillLevelsDisplay:getHelpAnchorPosition()
	local v112_ = self.helpAnchorPosX
	local v113_ = self.helpAnchorPosY
	if g_currentMission.hud.speedMeter:getVisible() then
		v112_ = v112_ + self.offsetX
		v113_ = v113_ + self.offsetY
	end
	return v112_, v113_
end
if v1_ ~= nil then
	local v114_ = FillLevelsDisplay.new()
	v114_:setScale(v1_.uiScale)
	v114_:setVisible(v1_.isVisible)
	v114_:setVehicle(v1_.vehicle)
	g_currentMission.hud.fillLevelsDisplay = v114_
	g_currentMission.hud.displayComponents.fillLevelsDisplay = v114_
	Logging.info("Reloaded FillLevelsDisplay")
end
