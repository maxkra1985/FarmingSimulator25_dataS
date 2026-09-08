-- Local values: FarmlandHotspot_mt
FarmlandHotspot = {}
local FarmlandHotspot_mt = Class(FarmlandHotspot, MapHotspot)

-- Upvalues: FarmlandHotspot_mt
-- Local values: self, _, textSize
function FarmlandHotspot.new(customMt)
	-- upvalues: (copy) FarmlandHotspot_mt
	local v3_ = MapHotspot.new(customMt or FarmlandHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(60, 60)
	v3_.width = v4_
	v3_.height = v5_
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.miniMapField", 0, 0, v3_.width, v3_.height)
	local v6_ = v3_.icon
	local v7_ = HUD.COLOR.BACKGROUND_DARK
	v6_:setColor(unpack(v7_))
	v3_.clickArea = MapHotspot.getClickCircle(0.667)
	local v8_
	if Platform.isMobile then
		local v9_
		v9_, v8_ = getNormalizedScreenValues(0, 50)
	else
		local v10_
		v10_, v8_ = getNormalizedScreenValues(0, 16)
	end
	v3_.textSize = v8_
	v3_.color = {
		1,
		1,
		1,
		1
	}
	v3_.colorDisabled = {
		0.20156,
		0.20156,
		0.20156,
		1
	}
	v3_.textColor = { 1, 1, 1 }
	v3_.textColorDisabled = {
		0.89627,
		0.92158,
		0.81485,
		0.5
	}
	local _, v11_ = getNormalizedScreenValues(0, 2)
	v3_.textOffsetY = v11_
	v3_.disabled = false
	v3_.isFirstRendering = true
	v3_.name = ""
	return v3_
end

function FarmlandHotspot:getCategory()
	return MapHotspot.CATEGORY_FIELD
end

-- Local values: x, z
function FarmlandHotspot:setFarmland(farmland)
	self.farmland = farmland
	if farmland ~= nil then
		self.name = farmland:getName()
		local v14_, v15_ = farmland:getIndicatorPosition()
		self:setWorldPosition(v14_, v15_)
	end
end

function FarmlandHotspot:getFarmland()
	return self.farmland
end

function FarmlandHotspot:getSortingValue()
	return math.huge
end

function FarmlandHotspot:setOwnerFarmId(farmId)
	FarmlandHotspot:superClass().setOwnerFarmId(self, farmId)
	self.farmId = farmId
	self:updateColors()
end

function FarmlandHotspot:setDisabled(disabled)
	self.disabled = disabled
	if disabled then
		local v21_ = self.icon
		local v22_ = self.colorDisabled
		v21_:setColor(unpack(v22_))
	else
		self:updateColors()
	end
end

-- Local values: farm, color
function FarmlandHotspot:updateColors()
	if self.icon ~= nil then
		if self.farmId == FarmlandManager.NO_OWNER_FARM_ID then
			local v24_ = self.color
			local v25_ = self.color
			local v26_ = self.color
			local v27_ = self.color
			v24_[1] = 1
			v25_[2] = 1
			v26_[3] = 1
			v27_[4] = 1
			local v28_ = self.textColor
			local v29_ = self.textColor
			local v30_ = self.textColor
			v28_[1] = 1
			v29_[2] = 1
			v30_[3] = 1
			local v31_ = self.icon
			local v32_ = HUD.COLOR.BACKGROUND_DARK
			v31_:setColor(unpack(v32_))
		else
			local v33_ = g_farmManager:getFarmById(self.farmId)
			if v33_ ~= nil then
				local v34_ = v33_:getColor()
				if v34_ ~= nil then
					self.icon:setColor(v34_[1], v34_[2], v34_[3], v34_[4])
					self.color[1] = v34_[1]
					self.color[2] = v34_[2]
					self.color[3] = v34_[3]
					self.color[4] = v34_[4]
				end
				local v35_ = self.textColor
				local v36_ = self.textColor
				local v37_ = self.textColor
				v35_[1] = 0
				v36_[2] = 0
				v37_[3] = 0
				return
			end
		end
	end
end

function FarmlandHotspot:getIsVisible()
	if self.farmland == nil or self.farmland.showOnFarmlandsScreen then
		return FarmlandHotspot:superClass().getIsVisible(self)
	else
		return false
	end
end

-- Local values: width, height, radius, icon, a, name, alpha, textSize, yOffset, posX, posY, r, g, b
function FarmlandHotspot:render(x, y, rotation, small)
	if self.isFirstRendering then
		self:setOwnerFarmId(self.farmId)
		self.isFirstRendering = false
	end
	local v43_, v44_ = self:getDimension()
	local v45_ = v43_ * (self.clickArea.radiusFactor or 1)
	if MapHotspot.DEBUGGING and self.clickArea ~= nil then
		drawOutlineCircle2D(x + v43_ * 0.5, y + v44_ * 0.5, v45_, 0.001, 40, 1, 0, 0, 1)
	end
	if not small then
		local v46_ = self.icon
		if v46_ ~= nil then
			local v47_ = self.isBlinking and IngameMap.alpha or 1
			v46_:renderCustom(x, y, v46_.width, v46_.height, nil, nil, nil, v47_)
		end
	end
	local v48_ = self.name
	if v48_ ~= "" then
		local v49_ = self.isBlinking and IngameMap.alpha or 1
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		setTextWrapWidth(0)
		local v50_ = self.textSize * (0.25 + self.scale * 0.75)
		local v51_ = self.textOffsetY * self.scale
		local v52_ = x + v43_ * 0.5
		local v53_ = y + v44_ * 0.5 + v51_
		if small then
			setTextColor(0, 0, 0, v49_)
			renderText(v52_ + g_pixelSizeScaledX, v53_ + g_pixelSizeScaledY, v50_, v48_)
		end
		local v54_ = self.textColor[1]
		local v55_ = self.textColor[2]
		local v56_ = self.textColor[3]
		if small then
			v54_ = self.color[1]
			v55_ = self.color[2]
			v56_ = self.color[3]
		elseif self.disabled then
			local v57_ = self.textColorDisabled
			v54_, v55_, v56_, v49_ = unpack(v57_)
		end
		setTextColor(v54_, v55_, v56_, v49_)
		renderText(v52_, v53_, v50_, v48_)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
	end
end
FarmlandHotspot.getWorldPosition = MapHotspot.getWorldPosition
FarmlandHotspot.getWorldRotation = MapHotspot.getWorldRotation
FarmlandHotspot.setScale = MapHotspot.setScale
