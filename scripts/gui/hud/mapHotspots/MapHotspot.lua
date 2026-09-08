-- Local values: MapHotspot_mt
MapHotspot = {}
MapHotspot.DEBUGGING = false
MapHotspot.CATEGORY_FIELD = 1
MapHotspot.CATEGORY_ANIMAL = 2
MapHotspot.CATEGORY_MISSION = 3
MapHotspot.CATEGORY_TOUR = 4
MapHotspot.CATEGORY_STEERABLE = 5
MapHotspot.CATEGORY_COMBINE = 6
MapHotspot.CATEGORY_TRAILER = 7
MapHotspot.CATEGORY_TOOL = 8
MapHotspot.CATEGORY_UNLOADING = 9
MapHotspot.CATEGORY_LOADING = 10
MapHotspot.CATEGORY_PRODUCTION = 11
MapHotspot.CATEGORY_SHOP = 12
MapHotspot.CATEGORY_OTHER = 13
MapHotspot.CATEGORY_AI = 14
MapHotspot.CATEGORY_PLAYER = 15
MapHotspot.CATEGORY_MAP_UTILITY = 15
MapHotspot.CATEGORY_DEFAULT = MapHotspot.CATEGORY_OTHER
MapHotspot.AREA = {}
MapHotspot.AREA.RECTANGLE = 1
MapHotspot.AREA.CIRCLE = 2
local MapHotspot_mt = Class(MapHotspot)

-- Upvalues: MapHotspot_mt
-- Local values: self
function MapHotspot.new(customMt)
	-- upvalues: (copy) MapHotspot_mt
	local v3_ = customMt or MapHotspot_mt
	local v4_ = setmetatable({}, v3_)
	v4_.isVisible = true
	v4_.isBlinking = false
	v4_.isPersistent = false
	v4_.worldX = 0
	v4_.worldZ = 0
	v4_.worldRotation = 0
	v4_.scale = 1
	v4_.color = {
		1,
		1,
		1,
		1
	}
	v4_.lastScreenPositionX = 0
	v4_.lastScreenPositionY = 0
	v4_.lastScreenRotation = 0
	v4_.lastScreenLayout = nil
	v4_.renderStateChangedListeners = nil
	v4_.icon = nil
	v4_.clickArea = nil
	v4_.forceNoRotation = false
	v4_.ownerFarmId = AccessHandler.EVERYONE
	return v4_
end

function MapHotspot:delete()
	if self.icon ~= nil then
		self.icon:delete()
		self.icon = nil
	end
end

function MapHotspot:getCategory()
	return MapHotspot.CATEGORY_DEFAULT
end

function MapHotspot:getIsPersistent()
	return self.isPersistent
end

function MapHotspot:setPersistent(isPersistent)
	if isPersistent ~= self.isPersistent then
		self:onRenderStateChanged()
	end
	self.isPersistent = isPersistent
end

function MapHotspot:getRenderLast()
	return false
end

function MapHotspot:getSortingValue()
	return 1000
end

function MapHotspot:setVisible(isVisible)
	if isVisible ~= self.isVisible then
		self:onRenderStateChanged()
	end
	self.isVisible = isVisible
end

function MapHotspot:getIsVisible()
	return self.isVisible
end

function MapHotspot:setBlinking(isBlinking)
	self.isBlinking = isBlinking
end

function MapHotspot:setWorldPosition(x, z)
	self.worldX = x
	self.worldZ = z
end

function MapHotspot:getWorldPosition()
	return self.worldX, self.worldZ
end

function MapHotspot:setLastRenderInfo(x, y, rotation, layout)
	self.lastScreenPositionX = x
	self.lastScreenPositionY = y
	self.lastScreenRotation = rotation
	self.lastScreenLayout = layout
end

function MapHotspot:getLastScreenPosition()
	return self.lastScreenPositionX, self.lastScreenPositionY, self.lastScreenRotation
end

function MapHotspot:getLastScreenPositionCenter()
	return self.lastScreenPositionX + self:getWidth() * 0.5, self.lastScreenPositionY + self:getHeight() * 0.5
end

function MapHotspot:setWorldRotation(rotation)
	self.worldRotation = rotation
end

function MapHotspot:getWorldRotation()
	return self.worldRotation
end

function MapHotspot:getWidth()
	return self.icon == nil and 0 or self.icon.width
end

function MapHotspot:getHeight()
	return self.icon == nil and 0 or self.icon.height
end

function MapHotspot:getDimension()
	if self.icon == nil then
		return 0, 0
	else
		return self.icon.width, self.icon.height
	end
end

function MapHotspot:setScale(scale)
	self.scale = scale
	if self.icon ~= nil then
		self.icon:setScale(scale, scale)
	end
end

function MapHotspot:setSelected(isSelected)
	self.isSelected = isSelected
end

function MapHotspot:setOwnerFarmId(farmId)
	if farmId == nil then
		farmId = AccessHandler.EVERYONE
	end
	self.ownerFarmId = farmId
end

function MapHotspot:getCanBeAccessed()
	return self.ownerFarmId == AccessHandler.EVERYONE and true or g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), self.ownerFarmId)
end

function MapHotspot:getCanBlink()
	return true
end

function MapHotspot:setColor(r, g, b)
	self.color[1] = r
	self.color[2] = g
	self.color[3] = b
end

function MapHotspot:getColor()
	return self.color
end

function MapHotspot:addRenderStateChangedListener(listener)
	if self.renderStateChangedListeners == nil then
		self.renderStateChangedListeners = {}
	end
	table.addElement(self.renderStateChangedListeners, listener)
end

function MapHotspot:removeRenderStateChangedListener(listener)
	if self.renderStateChangedListeners ~= nil then
		table.removeElement(self.renderStateChangedListeners, listener)
		if #self.renderStateChangedListeners == 0 then
			self.renderStateChangedListeners = {}
		end
	end
end

-- Local values: _, listener
function MapHotspot:onRenderStateChanged()
	if self.renderStateChangedListeners ~= nil then
		for _, v48_ in ipairs(self.renderStateChangedListeners) do
			v48_:onMapHotspotRenderStateChanged(self)
		end
	end
end

-- Local values: icon, color, a, clickArea, width, height, radius
function MapHotspot:render(x, y, rotation, small)
	local v53_ = self.icon
	if v53_ ~= nil then
		local v54_ = self.forceNoRotation and 0 or rotation
		local v55_ = self.color
		local v56_ = self.isBlinking and self:getCanBlink() and (IngameMap.alpha or 1) or 1
		v53_:renderCustom(x, y, v53_.width, v53_.height, v55_[1], v55_[2], v55_[3], v56_, nil, nil, nil, nil, v54_ or 0, v53_.width * 0.5, v53_.height * 0.5)
	end
	if MapHotspot.DEBUGGING then
		local v57_ = self.clickArea
		if v57_.areaType == MapHotspot.AREA.CIRCLE then
			local v58_ = self:getWidth()
			local v59_ = self:getHeight()
			local v60_ = v58_ * (v57_.radiusFactor or 1)
			drawOutlineCircle2D(x + v58_ * 0.5, y + v59_ * 0.5, v60_, 0.001, 40, 1, 0, 0, 1)
		end
	end
end

-- Local values: areaType
function MapHotspot:hasMouseOverlap(x, y)
	local v64_
	if self.clickArea == nil then
		v64_ = nil
	else
		v64_ = self.clickArea.areaType
	end
	if v64_ == MapHotspot.AREA.RECTANGLE then
		return self:checkOverlapRectangle(x, y, self.clickArea)
	elseif v64_ == MapHotspot.AREA.CIRCLE then
		return self:checkOverlapCircle(x, y, self.clickArea)
	else
		return false, nil
	end
end

-- Local values: width, height, lastX, lastY, area, startX, endX, startY, endY, centerX, centerY, rotation, cosRot, sinRot, distanceX, distanceY, isInRange, distance
function MapHotspot:checkOverlapRectangle(x, y, clickArea)
	local v69_ = self:getWidth()
	local v70_ = self:getHeight()
	local v71_ = self.lastScreenPositionX
	local v72_ = self.lastScreenPositionY
	local v73_ = clickArea.area
	local v74_ = v71_ + v73_[1] * v69_
	local v75_ = v74_ + v73_[3] * v69_
	local v76_ = v72_ + v73_[2] * v70_
	local v77_ = v76_ + v73_[4] * v70_
	local v78_ = v71_ + v69_ * 0.5
	local v79_ = v72_ + v70_ * 0.5
	local v80_ = self.lastScreenRotation + clickArea.rotation
	local v81_ = -v80_
	local v82_ = math.cos(v81_)
	local v83_ = -v80_
	local v84_ = math.sin(v83_)
	local v85_ = (x - v78_) * g_screenAspectRatio
	local v86_ = y - v79_
	local v87_ = v78_ + (v82_ * v85_ - v84_ * v86_) / g_screenAspectRatio
	local v88_ = v79_ + v84_ * v85_ + v82_ * v86_
	local v89_
	if v74_ <= v87_ and (v87_ <= v75_ and v76_ <= v88_) then
		v89_ = v88_ <= v77_
	else
		v89_ = false
	end
	local v90_ = v85_ * v85_ + v86_ * v86_
	return v89_, math.sqrt(v90_) / g_screenAspectRatio
end

-- Local values: width, height, lastX, lastY, centerX, centerY, distanceX, distanceY, distance, radius, isInRange
function MapHotspot:checkOverlapCircle(x, y, clickArea)
	local v95_ = self:getWidth()
	local v96_ = self:getHeight()
	local v97_ = self.lastScreenPositionX
	local v98_ = self.lastScreenPositionY
	local v99_ = v97_ + v95_ * 0.5
	local v100_ = v98_ + v96_ * 0.5
	local v101_ = (x - v99_) * g_screenAspectRatio
	local v102_ = y - v100_
	local v103_ = v101_ * v101_ + v102_ * v102_
	local v104_ = math.sqrt(v103_) / g_screenAspectRatio
	return v104_ <= v95_ * (clickArea.radiusFactor or 1), v104_
end

-- Local values: startX, startY, width, height
function MapHotspot.getClickArea(area, refSize, rotation)
	local v108_ = area[1] / refSize[1]
	local v109_ = area[2] / refSize[2]
	local v110_ = area[3] / refSize[1]
	local v111_ = area[4] / refSize[2]
	return {
		["areaType"] = MapHotspot.AREA.RECTANGLE,
		["area"] = {
			v108_,
			v109_,
			v110_,
			v111_
		},
		["rotation"] = rotation
	}
end

function MapHotspot.getClickCircle(radiusFactor)
	return {
		["areaType"] = MapHotspot.AREA.CIRCLE,
		["radiusFactor"] = radiusFactor
	}
end
