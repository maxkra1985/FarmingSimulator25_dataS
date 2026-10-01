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
function MapHotspot.new(customMt)
	local self = setmetatable({}, customMt or MapHotspot_mt)
	self.isVisible = true
	self.isBlinking = false
	self.isPersistent = false
	self.worldX = 0
	self.worldZ = 0
	self.worldRotation = 0
	self.scale = 1
	self.color = { 1, 1, 1, 1 }
	self.lastScreenPositionX = 0
	self.lastScreenPositionY = 0
	self.lastScreenRotation = 0
	self.lastScreenLayout = nil
	self.renderStateChangedListeners = nil
	self.icon = nil
	self.clickArea = nil
	self.forceNoRotation = false
	self.ownerFarmId = AccessHandler.EVERYONE
	return self
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
	if self.icon ~= nil then
		return self.icon.width
	else
		return 0
	end
end
function MapHotspot:getHeight()
	if self.icon ~= nil then
		return self.icon.height
	else
		return 0
	end
end
function MapHotspot:getDimension()
	if self.icon ~= nil then
		return self.icon.width, self.icon.height
	else
		return 0, 0
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
	if self.ownerFarmId ~= AccessHandler.EVERYONE then
		g_currentMission.accessHandler:canFarmAccessOtherId(g_currentMission:getFarmId(), self.ownerFarmId)
	end
	return true
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
function MapHotspot:onRenderStateChanged()
	if self.renderStateChangedListeners ~= nil then
		for _, listener in ipairs(self.renderStateChangedListeners) do
			listener:onMapHotspotRenderStateChanged(self)
		end
	end
end
function MapHotspot:render(x, y, rotation, small)
	local icon = self.icon
	if icon ~= nil then
		if self.forceNoRotation then
			rotation = 0
		end
		local color = self.color
		local a = self.isBlinking and self:getCanBlink() and IngameMap.alpha or 1
		icon:renderCustom(x, y, icon.width, icon.height, color[1], color[2], color[3], a, nil, nil, nil, nil, rotation or 0, icon.width * 0.5, icon.height * 0.5)
	end
	if MapHotspot.DEBUGGING then
		local clickArea = self.clickArea
		if clickArea.areaType == MapHotspot.AREA.CIRCLE then
			local width = self:getWidth()
			local height = self:getHeight()
			local radius = width * (clickArea.radiusFactor or 1)
			drawOutlineCircle2D(x + width * 0.5, y + height * 0.5, radius, 0.001, 40, 1, 0, 0, 1)
		end
	end
end
function MapHotspot:hasMouseOverlap(x, y)
	local areaType = nil
	if self.clickArea ~= nil then
		areaType = self.clickArea.areaType
	end
	if areaType == MapHotspot.AREA.RECTANGLE then
		return self:checkOverlapRectangle(x, y, self.clickArea)
	elseif areaType == MapHotspot.AREA.CIRCLE then
		return self:checkOverlapCircle(x, y, self.clickArea)
	else
		return false, nil
	end
end
function MapHotspot:checkOverlapRectangle(x, y, clickArea)
	local width = self:getWidth()
	local height = self:getHeight()
	local lastX = self.lastScreenPositionX
	local lastY = self.lastScreenPositionY
	local area = clickArea.area
	local startX = lastX + area[1] * width
	local endX = startX + area[3] * width
	local startY = lastY + area[2] * height
	local endY = startY + area[4] * height
	local centerX = lastX + width * 0.5
	local centerY = lastY + height * 0.5
	local rotation = self.lastScreenRotation + clickArea.rotation
	local cosRot = math.cos(-rotation)
	local sinRot = math.sin(-rotation)
	local distanceX = (x - centerX) * g_screenAspectRatio
	local distanceY = y - centerY
	x = centerX + (cosRot * distanceX - sinRot * distanceY) / g_screenAspectRatio
	y = centerY + sinRot * distanceX + cosRot * distanceY
	local isInRange = startX <= x and x <= endX and startY <= y and y <= endY
	local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY) / g_screenAspectRatio
	return isInRange, distance
end
function MapHotspot:checkOverlapCircle(x, y, clickArea)
	local width = self:getWidth()
	local height = self:getHeight()
	local lastX = self.lastScreenPositionX
	local lastY = self.lastScreenPositionY
	local centerX = lastX + width * 0.5
	local centerY = lastY + height * 0.5
	local distanceX = (x - centerX) * g_screenAspectRatio
	local distanceY = y - centerY
	local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY) / g_screenAspectRatio
	local radius = width * (clickArea.radiusFactor or 1)
	local isInRange = distance <= radius
	return isInRange, distance
end
function MapHotspot.getClickArea(area, refSize, rotation)
	local startX = area[1] / refSize[1]
	local startY = area[2] / refSize[2]
	local width = area[3] / refSize[1]
	local height = area[4] / refSize[2]
	return { rotation = rotation, areaType = MapHotspot.AREA.RECTANGLE, area = { startX, startY, width, height } }
end
function MapHotspot.getClickCircle(radiusFactor)
	return { radiusFactor = radiusFactor, areaType = MapHotspot.AREA.CIRCLE }
end
