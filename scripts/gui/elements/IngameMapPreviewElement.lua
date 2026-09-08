-- Local values: IngameMapPreviewElement_mt
IngameMapPreviewElement = {}
local IngameMapPreviewElement_mt = Class(IngameMapPreviewElement, GuiElement)
Gui.registerGuiElement("InGameMapPreview", IngameMapPreviewElement)

-- Upvalues: IngameMapPreviewElement_mt
-- Local values: self
function IngameMapPreviewElement.new(target, custom_mt)
	-- upvalues: (copy) IngameMapPreviewElement_mt
	local v4_ = GuiElement.new(target, custom_mt or IngameMapPreviewElement_mt)
	v4_.ingameMap = nil
	v4_.drawHotspots = true
	v4_.layout = IngameMapLayoutPartialscreen.new()
	return v4_
end

function IngameMapPreviewElement:loadFromXML(xmlFile, key)
	IngameMapPreviewElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onDrawPreIngameMap", "onDrawPreIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMap", "onDrawPostIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMapHotspots", "onDrawPostIngameMapHotspotsCallback")
end

function IngameMapPreviewElement:copyAttributes(src)
	IngameMapElement:superClass().copyAttributes(self, src)
	self.onDrawPreIngameMapCallback = src.onDrawPreIngameMapCallback
	self.onDrawPostIngameMapCallback = src.onDrawPostIngameMapCallback
	self.onDrawPostIngameMapHotspotsCallback = src.onDrawPostIngameMapHotspotsCallback
end

function IngameMapPreviewElement:delete()
	self.ingameMap = nil
	IngameMapPreviewElement:superClass().delete(self)
end

-- Local values: posStartX, posStartY, posEndX, posEndY
function IngameMapPreviewElement:onOpen()
	IngameMapPreviewElement:superClass().onOpen(self)
	self.ingameMap:setCustomLayout(self.layout)
	local v12_ = self.absPosition[1]
	local v13_ = self.absPosition[2]
	local v14_ = self.absPosition[1] + self.absSize[1]
	local v15_ = self.absPosition[2] + self.absSize[2]
	self.ingameMap:setMapClipArea(v12_, v13_, v14_, v15_)
	self.ingameMap.clipHotspots = true
	self.ingameMap:restoreDefaultFilter()
end

function IngameMapPreviewElement:onClose()
	IngameMapPreviewElement:superClass().onClose(self)
	self.ingameMap:setCustomLayout(nil)
	self.ingameMap.clipHotspots = false
	self.ingameMap:setMapClipArea(nil, nil, nil, nil)
end

function IngameMapPreviewElement:draw(clipX1, clipY1, clipX2, clipY2)
	self.layout:setPreviewSize(self.absSize[1], self.absSize[2])
	self.layout:setPreviewPosition(self.absPosition[1], self.absPosition[2])
	self:raiseCallback("onDrawPreIngameMapCallback", self, self.ingameMap)
	self.ingameMap:drawMapOnly()
	self:raiseCallback("onDrawPostIngameMapCallback", self, self.ingameMap)
	if self.drawHotspots then
		self.ingameMap:drawHotspotsOnly()
	end
	self:raiseCallback("onDrawPostIngameMapHotspotsCallback", self, self.ingameMap)
	IngameMapPreviewElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

-- Local values: ingameMap, zoom, scale
function IngameMapPreviewElement:drawHotspot(hotspot, smallVersion)
	local v25_ = self.ingameMap
	local v26_ = v25_.layout:getIconZoom()
	v25_:drawHotspot(hotspot, smallVersion, v25_.uiScale * v26_)
end

function IngameMapPreviewElement:setCenterToWorldPosition(worldPosX, worldPosY)
	self.layout:setCenterToWorldPosition(worldPosX, worldPosY)
end

function IngameMapPreviewElement:setMapZoomByWidthAndHeight(width, height)
	self.layout:setMapZoomByWidthAndHeight(width, height)
end

function IngameMapPreviewElement:setIngameMap(ingameMap)
	self.ingameMap = ingameMap
	if self.ingameMap ~= nil and self.layout ~= nil then
		self.ingameMap:setCustomLayout(self.layout)
	end
end

function IngameMapPreviewElement:setMapZoom(mapZoom)
	local v37_ = self.absSize[1]
	local v38_ = self.absSize[2]
	local v39_ = mapZoom * math.max(v37_, v38_)
	if self.layout ~= nil then
		self.layout:setMapZoom(v39_)
	end
end

function IngameMapPreviewElement:setMapAlpha(alpha)
	if self.layout ~= nil then
		self.layout:setMapAlpha(alpha)
	end
end

function IngameMapPreviewElement:getMapPosition()
	if self.layout == nil then
		return 0, 0
	else
		return self.layout:getMapPosition()
	end
end

function IngameMapPreviewElement:getMapSize()
	if self.layout == nil then
		return 1, 1
	else
		return self.layout:getMapSize()
	end
end

-- Local values: mapExtensionScaleFactor, mapX, mapZ, terrainSize, boundaryScreenSizeX, boundaryScreenSizeZ, screenX, screenY, mapZoom
function IngameMapPreviewElement:fitToBoundary(minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ, boundaryOffsetPercentage)
	if self.layout ~= nil then
		self:setCenterToWorldPosition((minWorldPosX + maxWorldPosX) * 0.5, (minWorldPosZ + maxWorldPosZ) * 0.5)
		local v50_ = self.layout.mapExtensionScaleFactor
		self:setMapZoom(1)
		local v51_, v52_ = self:getMapSize()
		local v53_ = self.layout.worldSizeX
		local v54_ = (maxWorldPosX - minWorldPosX) / (v53_ / v50_) * v51_
		local v55_ = (maxWorldPosZ - minWorldPosZ) / (v53_ / v50_) * v52_
		local v56_ = self.absSize[1] * (1 - boundaryOffsetPercentage)
		local v57_ = self.absSize[2] * (1 - boundaryOffsetPercentage)
		local v58_ = v56_ / v54_
		local v59_ = v57_ / v55_
		self:setMapZoom((math.min(v58_, v59_)))
	end
end
