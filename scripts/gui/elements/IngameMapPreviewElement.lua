IngameMapPreviewElement = {}
local IngameMapPreviewElement_mt = Class(IngameMapPreviewElement, GuiElement)
Gui.registerGuiElement("InGameMapPreview", IngameMapPreviewElement)
function IngameMapPreviewElement.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or IngameMapPreviewElement_mt)
	self.ingameMap = nil
	self.drawHotspots = true
	self.layout = IngameMapLayoutPartialscreen.new()
	return self
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
function IngameMapPreviewElement:onOpen()
	IngameMapPreviewElement:superClass().onOpen(self)
	self.ingameMap:setCustomLayout(self.layout)
	local posStartX = self.absPosition[1]
	local posStartY = self.absPosition[2]
	local posEndX = self.absPosition[1] + self.absSize[1]
	local posEndY = self.absPosition[2] + self.absSize[2]
	self.ingameMap:setMapClipArea(posStartX, posStartY, posEndX, posEndY)
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
function IngameMapPreviewElement:drawHotspot(hotspot, smallVersion)
	local ingameMap = self.ingameMap
	local zoom = ingameMap.layout:getIconZoom()
	local scale = ingameMap.uiScale * zoom
	ingameMap:drawHotspot(hotspot, smallVersion, scale)
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
	mapZoom = mapZoom * math.max(self.absSize[1], self.absSize[2])
	if self.layout ~= nil then
		self.layout:setMapZoom(mapZoom)
	end
end
function IngameMapPreviewElement:setMapAlpha(alpha)
	if self.layout ~= nil then
		self.layout:setMapAlpha(alpha)
	end
end
function IngameMapPreviewElement:getMapPosition()
	if self.layout ~= nil then
		return self.layout:getMapPosition()
	else
		return 0, 0
	end
end
function IngameMapPreviewElement:getMapSize()
	if self.layout ~= nil then
		return self.layout:getMapSize()
	else
		return 1, 1
	end
end
function IngameMapPreviewElement:fitToBoundary(minWorldPosX, maxWorldPosX, minWorldPosZ, maxWorldPosZ, boundaryOffsetPercentage)
	if self.layout ~= nil then
		self:setCenterToWorldPosition((minWorldPosX + maxWorldPosX) * 0.5, (minWorldPosZ + maxWorldPosZ) * 0.5)
		local mapExtensionScaleFactor = self.layout.mapExtensionScaleFactor
		self:setMapZoom(1)
		local mapX, mapZ = self:getMapSize()
		local terrainSize = self.layout.worldSizeX
		local boundaryScreenSizeX = (maxWorldPosX - minWorldPosX) / (terrainSize / mapExtensionScaleFactor) * mapX
		local boundaryScreenSizeZ = (maxWorldPosZ - minWorldPosZ) / (terrainSize / mapExtensionScaleFactor) * mapZ
		local screenX = self.absSize[1] * (1 - boundaryOffsetPercentage)
		local screenY = self.absSize[2] * (1 - boundaryOffsetPercentage)
		local mapZoom = math.min(screenX / boundaryScreenSizeX, screenY / boundaryScreenSizeZ)
		self:setMapZoom(mapZoom)
	end
end
