-- Local values: DebugBitVectorMap_mt
DebugBitVectorMap = {}
local DebugBitVectorMap_mt = Class(DebugBitVectorMap)

-- Upvalues: DebugBitVectorMap_mt
-- Local values: self
function DebugBitVectorMap.new(customMt)
	-- upvalues: (copy) DebugBitVectorMap_mt
	local v3_ = customMt or DebugBitVectorMap_mt
	local v4_ = setmetatable({}, v3_)
	v4_.radius = 15
	v4_.cellSize = 0.5
	v4_.vertexAligned = false
	v4_.opacity = 0.4
	v4_.valueToColor = {
		[0] = Color.PRESETS.RED:copy(),
		[1] = Color.PRESETS.GREEN:copy(),
		[2] = Color.PRESETS.BLUE:copy()
	}
	v4_.undefinedValueColor = Color.new(0.2, 0.2, 0.2)
	v4_.yOffset = 0.1
	v4_.solid = false
	v4_.pixelPaddingFactor = 0.02
	v4_.displayLegend = true
	return v4_
end

-- Local values: self
function DebugBitVectorMap.newSimple(radius, cellSize, vertexAligned, opacity, yOffset, solid, pixelPaddingFactor, displayLegend)
	local v13_ = DebugBitVectorMap.new()
	v13_.radius = radius or v13_.radius
	v13_.cellSize = cellSize or v13_.cellSize
	v13_.vertexAligned = vertexAligned or v13_.vertexAligned
	v13_.opacity = opacity or v13_.opacity
	v13_.yOffset = yOffset or v13_.yOffset
	v13_.solid = Utils.getNoNil(solid, v13_.solid)
	v13_.pixelPaddingFactor = pixelPaddingFactor or v13_.pixelPaddingFactor
	v13_.displayLegend = Utils.getNoNil(displayLegend, v13_.displayLegend)
	return v13_
end

-- Local values: cx, _, cz, cx, _, cz
function DebugBitVectorMap:draw()
	if self.aiVehicle == nil then
		if self.customFunc ~= nil then
			local v15_, _, v16_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			self:drawAroundCenter(v15_, v16_, self.customFunc)
		end
	elseif not (self.aiVehicle.isDeleted or self.aiVehicle.isDeleting) then
		local v17_, _, v18_ = getWorldTranslation(self.aiVehicle.rootNode)
		self:drawAroundCenter(v17_, v18_, DebugBitVectorMap.aiAreaCheck)
		return
	end
end

function DebugBitVectorMap:createWithAIVehicle(vehicle)
	self.aiVehicle = vehicle
	return self
end

function DebugBitVectorMap:createWithCustomFunc(customFunc)
	self.customFunc = customFunc
	return self
end

function DebugBitVectorMap:setAdditionalDrawInfoFunc(drawInfoFunc)
	self.drawInfoFunc = drawInfoFunc
	return self
end

function DebugBitVectorMap:getColorForValue(value)
	return self.valueToColor[value] or self.undefinedValueColor
end

-- Local values: cellSize, steps, xStep, zStep, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, area, areaTotal, color, legendEntryOffset, fontSize, colorBoxHeight, value, color
function DebugBitVectorMap:drawAroundCenter(x, z, getValueAtAreaFunc)
	local v31_ = self.cellSize
	local v32_ = self.radius / v31_
	local v33_ = math.ceil(v32_) * 2
	local v34_ = x / self.cellSize
	local v35_ = math.floor(v34_) * self.cellSize
	local v36_ = z / self.cellSize
	local v37_ = math.floor(v36_) * self.cellSize
	if self.vertexAligned then
		v35_ = v35_ - self.cellSize * 0.5
		v37_ = v37_ - self.cellSize * 0.5
	end
	for v38_ = 0, v33_ do
		for v39_ = 0, v33_ do
			local v40_ = v35_ + (v38_ - v33_ * 0.5) * v31_
			local v41_ = v37_ + (v39_ - v33_ * 0.5) * v31_
			local v42_ = v35_ + (v38_ + 1 - v33_ * 0.5) * v31_
			local v43_ = v37_ + (v39_ - v33_ * 0.5) * v31_
			local v44_ = v35_ + (v38_ - v33_ * 0.5) * v31_
			local v45_ = v37_ + (v39_ + 1 - v33_ * 0.5) * v31_
			local v46_, v47_ = getValueAtAreaFunc(self, v40_, v41_, v42_, v43_, v44_, v45_)
			if v46_ ~= nil then
				local v48_ = self:getColorForValue(v46_)
				local v49_ = v40_ + v31_ * self.pixelPaddingFactor
				local v50_ = v41_ + v31_ * self.pixelPaddingFactor
				local v51_ = v42_ - v31_ * self.pixelPaddingFactor
				local v52_ = v43_ + v31_ * self.pixelPaddingFactor
				local v53_ = v44_ + v31_ * self.pixelPaddingFactor
				local v54_ = v45_ - v31_ * self.pixelPaddingFactor
				v48_.a = self.opacity
				DebugPlane.renderWithPositions(v49_, 0, v50_, v53_, 0, v54_, v51_, 0, v52_, v48_, true, true, false, false)
				if self.drawInfoFunc ~= nil then
					self.drawInfoFunc(self, (v49_ + v51_) * 0.5, (v50_ + v54_) * 0.5, v46_, v47_)
				end
			end
		end
	end
	if self.displayLegend then
		local v55_ = getTextHeight(0.015, "1") * 0.9
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.01, 0.7, 0.015, "DebugBitVector colors")
		local v56_ = 0 + 0.0165
		for v57_, v58_ in pairs(self.valueToColor) do
			drawFilledRect(0.013, 0.7 - v56_, v55_, v55_, v58_[1], v58_[2], v58_[3], self.opacity)
			renderText(0.013 + v55_ * 1.2, 0.7 - v56_, 0.015, string.format("%d", v57_))
			v56_ = v56_ + 0.015
		end
		drawFilledRect(0.013, 0.7 - v56_, v55_, v55_, self.undefinedValueColor[1], self.undefinedValueColor[2], self.undefinedValueColor[3], self.opacity)
		renderText(0.013 + v55_ * 1.2, 0.7 - v56_, 0.015, "*")
	end
end

function DebugBitVectorMap:aiAreaCheck(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return AIVehicleUtil.getAIAreaOfVehicle(self.aiVehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end
