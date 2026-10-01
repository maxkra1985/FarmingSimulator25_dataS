Overlay = {}
local Overlay_mt = Class(Overlay)
Overlay.ALIGN_VERTICAL_BOTTOM = 1
Overlay.ALIGN_VERTICAL_MIDDLE = 2
Overlay.ALIGN_VERTICAL_TOP = 3
Overlay.ALIGN_HORIZONTAL_LEFT = 4
Overlay.ALIGN_HORIZONTAL_CENTER = 5
Overlay.ALIGN_HORIZONTAL_RIGHT = 6
Overlay.DEFAULT_UVS = { 0, 0, 0, 1, 1, 0, 1, 1 }
function Overlay.new(overlayFilename, x, y, width, height, customMt)
	local overlayId = 0
	if overlayFilename ~= nil then
		overlayId = createImageOverlay(overlayFilename)
	end
	local self = setmetatable({}, customMt or Overlay_mt)
	self.overlayId = overlayId
	self.filename = overlayFilename
	self.uvs = table.clone(Overlay.DEFAULT_UVS)
	self.x = x
	self.y = y
	self.offsetX = 0
	self.offsetY = 0
	self.defaultWidth = width
	self.width = width
	self.defaultHeight = height
	self.height = height
	self.scaleWidth = 1
	self.scaleHeight = 1
	self.visible = true
	self.alignmentVertical = Overlay.ALIGN_VERTICAL_BOTTOM
	self.alignmentHorizontal = Overlay.ALIGN_HORIZONTAL_LEFT
	self.invertX = false
	self.rotation = 0
	self.rotationCenterX = 0
	self.rotationCenterY = 0
	self.r = 1
	self.g = 1
	self.b = 1
	self.a = 1
	self.debugEnabled = nil
	return self
end
function Overlay:delete()
	if self.overlayId ~= 0 then
		delete(self.overlayId)
	end
end
function Overlay:setColor(r, g, b, a)
	r = r or self.r
	g = g or self.g
	b = b or self.b
	a = a or self.a
	if r ~= self.r or g ~= self.g or b ~= self.b or a ~= self.a then
		self.r = r
		self.g = g
		self.b = b
		self.a = a
		if self.overlayId ~= 0 then
			setOverlayColor(self.overlayId, self.r, self.g, self.b, self.a)
		end
	end
end
function Overlay:setUVs(uvs)
	if self.overlayId ~= 0 then
		self.uvs = uvs
		setOverlayUVs(self.overlayId, unpack(uvs))
	end
end
function Overlay:setSliceId(sliceId)
	if self.overlayId ~= 0 then
		local slice = g_overlayManager:getSliceInfoById(sliceId)
		if slice ~= nil then
			self.uvs = slice.uvs
			setOverlayUVs(self.overlayId, unpack(slice.uvs))
		end
	end
end
function Overlay:setPosition(x, y)
	self.x = x or self.x
	self.y = y or self.y
end
function Overlay:getPosition()
	return self.x, self.y
end
function Overlay:setDimension(width, height)
	self.width = width or self.width
	self.height = height or self.height
	self:setAlignment(self.alignmentVertical, self.alignmentHorizontal)
end
function Overlay:resetDimensions()
	self.scaleWidth = 1
	self.scaleHeight = 1
	self:setDimension(self.defaultWidth, self.defaultHeight)
end
function Overlay:setInvertX(invertX)
	if self.invertX ~= invertX then
		self.invertX = invertX
		if self.overlayId ~= 0 then
			if invertX then
				setOverlayUVs(self.overlayId, self.uvs[5], self.uvs[6], self.uvs[7], self.uvs[8], self.uvs[1], self.uvs[2], self.uvs[3], self.uvs[4])
				return
			end
			setOverlayUVs(self.overlayId, unpack(self.uvs))
		end
	end
end
function Overlay:setRotation(rotation, centerX, centerY)
	if self.rotation ~= rotation or self.rotationCenterX ~= centerX or self.rotationCenterY ~= centerY then
		self.rotation = rotation
		self.rotationCenterX = centerX
		self.rotationCenterY = centerY
		if self.overlayId ~= 0 then
			setOverlayRotation(self.overlayId, rotation, centerX, centerY)
		end
	end
end
function Overlay:setScale(scaleWidth, scaleHeight)
	self.width = self.defaultWidth * scaleWidth
	self.height = self.defaultHeight * scaleHeight
	self.scaleWidth = scaleWidth
	self.scaleHeight = scaleHeight
	self:setAlignment(self.alignmentVertical, self.alignmentHorizontal)
end
function Overlay:getScale()
	return self.scaleWidth, self.scaleHeight
end
function Overlay:render(clipX1, clipY1, clipX2, clipY2)
	if self.visible and (self.overlayId ~= 0 and 0 < self.a) then
		local posX = self.x + self.offsetX
		local posY = self.y + self.offsetY
		local sizeX = self.width
		local sizeY = self.height
		if clipX1 ~= nil then
			local u1 = nil
			local v1 = nil
			local u2 = nil
			local v2 = nil
			local u3 = nil
			local v3 = nil
			local u4 = nil
			local v4 = nil
			posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4 = Overlay.getClippingUVs(self.uvs, posX, posY, sizeX, sizeY, clipX1, clipY1, clipX2, clipY2)
			if sizeX == 0 or sizeX == nil or sizeY == 0 or sizeY == nil then
				return
			end
			setOverlayUVs(self.overlayId, u1, v1, u2, v2, u3, v3, u4, v4)
		end
		renderOverlay(self.overlayId, posX, posY, sizeX, sizeY)
		if clipX1 ~= nil then
			setOverlayUVs(self.overlayId, unpack(self.uvs))
		end
	end
end
Overlay.draw = Overlay.render
function Overlay:renderCustom(posX, posY, sizeX, sizeY, r, g, b, a, clipX1, clipY1, clipX2, clipY2, rotation, rotCenterX, rotCenterY)
	if self.overlayId ~= 0 then
		posX = posX or self.x + self.offsetX
		posY = posY or self.y + self.offsetY
		sizeX = sizeX or self.width
		sizeY = sizeY or self.height
		if rotation ~= nil then
			setOverlayRotation(self.overlayId, rotation, rotCenterX, rotCenterY)
		end
		if clipX1 ~= nil then
			local u1 = nil
			local v1 = nil
			local u2 = nil
			local v2 = nil
			local u3 = nil
			local v3 = nil
			local u4 = nil
			local v4 = nil
			posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4 = Overlay.getClippingUVs(self.uvs, posX, posY, sizeX, sizeY, clipX1, clipY1, clipX2, clipY2)
			if sizeX == 0 or sizeX == nil or sizeY == 0 or sizeY == nil then
				return
			end
			setOverlayUVs(self.overlayId, u1, v1, u2, v2, u3, v3, u4, v4)
		end
		if r ~= nil or a ~= nil then
			setOverlayColor(self.overlayId, r or self.r, g or self.g, b or self.b, a or self.a)
		end
		renderOverlay(self.overlayId, posX, posY, sizeX, sizeY)
		if r ~= nil or a ~= nil then
			setOverlayColor(self.overlayId, self.r, self.g, self.b, self.a)
		end
		if clipX1 ~= nil then
			setOverlayUVs(self.overlayId, unpack(self.uvs))
		end
		if rotation ~= nil then
			setOverlayRotation(self.overlayId, 0, rotCenterX, rotCenterY)
		end
	end
end
function Overlay:setAlignment(vertical, horizontal)
	if vertical == Overlay.ALIGN_VERTICAL_TOP then
		self.offsetY = -self.height
	elseif vertical == Overlay.ALIGN_VERTICAL_MIDDLE then
		self.offsetY = -self.height * 0.5
	else
		self.offsetY = 0
	end
	self.alignmentVertical = vertical or Overlay.ALIGN_VERTICAL_BOTTOM
	if horizontal == Overlay.ALIGN_HORIZONTAL_RIGHT then
		self.offsetX = -self.width
	elseif horizontal == Overlay.ALIGN_HORIZONTAL_CENTER then
		self.offsetX = -self.width * 0.5
	else
		self.offsetX = 0
	end
	self.alignmentHorizontal = horizontal or Overlay.ALIGN_HORIZONTAL_LEFT
end
function Overlay:setIsVisible(visible)
	self.visible = visible
end
Overlay.setVisible = Overlay.setIsVisible
function Overlay:getIsVisible()
	return self.visible
end
Overlay.getVisible = Overlay.getIsVisible
function Overlay:setImage(overlayFilename)
	if self.filename ~= overlayFilename then
		if self.overlayId ~= 0 then
			delete(self.overlayId)
		end
		self.filename = overlayFilename
		self.overlayId = createImageOverlay(overlayFilename)
	end
end
function Overlay.getClippingUVs(uvs, posX, posY, sizeX, sizeY, clipX1, clipY1, clipX2, clipY2)
	local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(uvs)
	local oldX1 = posX
	local oldY1 = posY
	local oldX2 = sizeX + posX
	local oldY2 = sizeY + posY
	local posX2 = posX + sizeX
	local posY2 = posY + sizeY
	posX = math.max(posX, clipX1)
	posY = math.max(posY, clipY1)
	sizeX = math.max(math.min(posX2, clipX2) - posX, 0)
	sizeY = math.max(math.min(posY2, clipY2) - posY, 0)
	if sizeX == 0 or sizeY == 0 then
		return
	end
	local ou1 = u1
	local ov1 = v1
	local ou2 = u2
	local ov2 = v2
	local ou3 = u3
	local ov3 = v3
	local ou4 = u4
	local ov4 = v4
	local p1 = (posX - oldX1) / (oldX2 - oldX1)
	local p2 = (posY - oldY1) / (oldY2 - oldY1)
	local p3 = (posX + sizeX - oldX1) / (oldX2 - oldX1)
	local p4 = (posY + sizeY - oldY1) / (oldY2 - oldY1)
	u1 = (ou3 - ou1) * p1 + ou1
	v1 = (ov2 - ov1) * p2 + ov1
	u2 = (ou3 - ou1) * p1 + ou1
	v2 = (ov4 - ov3) * p4 + ov3
	u3 = (ou3 - ou1) * p3 + ou1
	v3 = (ov2 - ov1) * p2 + ov1
	u4 = (ou4 - ou2) * p3 + ou2
	v4 = (ov4 - ov3) * p4 + ov3
	return posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4
end
function Overlay:setSingleDimension(width, height)
	if width ~= nil and height ~= nil then
		Logging.error("both width and height arguments provided, only provide one of the two or use setDimension() instead")
		printCallstack()
		return
	end
	if width == nil and height == nil then
		Logging.error("neither width nor height provided")
		printCallstack()
		return
	end
	if width ~= nil then
		local scale = width / self.defaultWidth
		self:setDimension(width, self.defaultHeight * scale)
	end
	if height ~= nil then
		local scale = height / self.defaultHeight
		self:setDimension(self.defaultWidth * scale, height)
	end
end
function Overlay:getExtends()
	return self.x + self.offsetX, self.y + self.offsetY, self.x + self.offsetX + self.width, self.y + self.offsetY + self.height
end
