-- Local values: Overlay_mt
Overlay = {}
local Overlay_mt = Class(Overlay)
Overlay.ALIGN_VERTICAL_BOTTOM = 1
Overlay.ALIGN_VERTICAL_MIDDLE = 2
Overlay.ALIGN_VERTICAL_TOP = 3
Overlay.ALIGN_HORIZONTAL_LEFT = 4
Overlay.ALIGN_HORIZONTAL_CENTER = 5
Overlay.ALIGN_HORIZONTAL_RIGHT = 6
Overlay.DEFAULT_UVS = {
	0,
	0,
	0,
	1,
	1,
	0,
	1,
	1
}

-- Upvalues: Overlay_mt
-- Local values: overlayId, self
function Overlay.new(overlayFilename, x, y, width, height, customMt)
	-- upvalues: (copy) Overlay_mt
	local v8_ = overlayFilename == nil and 0 or createImageOverlay(overlayFilename)
	local v9_ = customMt or Overlay_mt
	local v10_ = setmetatable({}, v9_)
	v10_.overlayId = v8_
	v10_.filename = overlayFilename
	v10_.uvs = table.clone(Overlay.DEFAULT_UVS)
	v10_.x = x
	v10_.y = y
	v10_.offsetX = 0
	v10_.offsetY = 0
	v10_.defaultWidth = width
	v10_.width = width
	v10_.defaultHeight = height
	v10_.height = height
	v10_.scaleWidth = 1
	v10_.scaleHeight = 1
	v10_.visible = true
	v10_.alignmentVertical = Overlay.ALIGN_VERTICAL_BOTTOM
	v10_.alignmentHorizontal = Overlay.ALIGN_HORIZONTAL_LEFT
	v10_.invertX = false
	v10_.rotation = 0
	v10_.rotationCenterX = 0
	v10_.rotationCenterY = 0
	v10_.r = 1
	v10_.g = 1
	v10_.b = 1
	v10_.a = 1
	v10_.debugEnabled = nil
	return v10_
end

function Overlay:delete()
	if self.overlayId ~= 0 then
		delete(self.overlayId)
	end
end

function Overlay:setColor(r, g, b, a)
	local v17_ = r or self.r
	local v18_ = g or self.g
	local v19_ = b or self.b
	local v20_ = a or self.a
	if v17_ ~= self.r or (v18_ ~= self.g or (v19_ ~= self.b or v20_ ~= self.a)) then
		self.r = v17_
		self.g = v18_
		self.b = v19_
		self.a = v20_
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

-- Local values: slice
function Overlay:setSliceId(sliceId)
	if self.overlayId ~= 0 then
		local v25_ = g_overlayManager:getSliceInfoById(sliceId)
		if v25_ ~= nil then
			self.uvs = v25_.uvs
			local v26_ = setOverlayUVs
			local v27_ = self.overlayId
			local v28_ = v25_.uvs
			v26_(v27_, unpack(v28_))
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
			local v39_ = setOverlayUVs
			local v40_ = self.overlayId
			local v41_ = self.uvs
			v39_(v40_, unpack(v41_))
		end
	end
end

function Overlay:setRotation(rotation, centerX, centerY)
	if self.rotation ~= rotation or (self.rotationCenterX ~= centerX or self.rotationCenterY ~= centerY) then
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

-- Local values: posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4
function Overlay:render(clipX1, clipY1, clipX2, clipY2)
	if self.visible and (self.overlayId ~= 0 and self.a > 0) then
		local v55_ = self.x + self.offsetX
		local v56_ = self.y + self.offsetY
		local v57_ = self.width
		local v58_ = self.height
		if clipX1 ~= nil then
			local v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_
			v55_, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_ = Overlay.getClippingUVs(self.uvs, v55_, v56_, v57_, v58_, clipX1, clipY1, clipX2, clipY2)
			if v57_ == 0 or (v57_ == nil or (v58_ == 0 or v58_ == nil)) then
				return
			end
			setOverlayUVs(self.overlayId, v59_, v60_, v61_, v62_, v63_, v64_, v65_, v66_)
		end
		renderOverlay(self.overlayId, v55_, v56_, v57_, v58_)
		if clipX1 ~= nil then
			local v67_ = setOverlayUVs
			local v68_ = self.overlayId
			local v69_ = self.uvs
			v67_(v68_, unpack(v69_))
		end
	end
end
Overlay.draw = Overlay.render

-- Local values: u1, v1, u2, v2, u3, v3, u4, v4
function Overlay:renderCustom(posX, posY, sizeX, sizeY, r, g, b, a, clipX1, clipY1, clipX2, clipY2, rotation, rotCenterX, rotCenterY)
	if self.overlayId ~= 0 then
		local v86_ = posX or self.x + self.offsetX
		local v87_ = posY or self.y + self.offsetY
		local v88_ = sizeX or self.width
		local v89_ = sizeY or self.height
		if rotation ~= nil then
			setOverlayRotation(self.overlayId, rotation, rotCenterX, rotCenterY)
		end
		if clipX1 ~= nil then
			local v90_, v91_, v92_, v93_, v94_, v95_, v96_, v97_
			v86_, v87_, v88_, v89_, v90_, v91_, v92_, v93_, v94_, v95_, v96_, v97_ = Overlay.getClippingUVs(self.uvs, v86_, v87_, v88_, v89_, clipX1, clipY1, clipX2, clipY2)
			if v88_ == 0 or (v88_ == nil or (v89_ == 0 or v89_ == nil)) then
				return
			end
			setOverlayUVs(self.overlayId, v90_, v91_, v92_, v93_, v94_, v95_, v96_, v97_)
		end
		if r ~= nil or a ~= nil then
			setOverlayColor(self.overlayId, r or self.r, g or self.g, b or self.b, a or self.a)
		end
		renderOverlay(self.overlayId, v86_, v87_, v88_, v89_)
		if r ~= nil or a ~= nil then
			setOverlayColor(self.overlayId, self.r, self.g, self.b, self.a)
		end
		if clipX1 ~= nil then
			local v98_ = setOverlayUVs
			local v99_ = self.overlayId
			local v100_ = self.uvs
			v98_(v99_, unpack(v100_))
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

-- Local values: u1, v1, u2, v2, u3, v3, u4, v4, oldX1, oldY1, oldX2, oldY2, posX2, posY2, ou1, ov1, ou2, ov2, ou3, ov3, ou4, ov4, p1, p2, p3, p4
function Overlay.getClippingUVs(uvs, posX, posY, sizeX, sizeY, clipX1, clipY1, clipX2, clipY2)
	local v118_, v119_, v120_, v121_, v122_, v123_, v124_, v125_ = unpack(uvs)
	local v126_ = sizeX + posX
	local v127_ = sizeY + posY
	local v128_ = posX + sizeX
	local v129_ = posY + sizeY
	local v130_ = math.max(posX, clipX1)
	local v131_ = math.max(posY, clipY1)
	local v132_ = math.min(v128_, clipX2) - v130_
	local v133_ = math.max(v132_, 0)
	local v134_ = math.min(v129_, clipY2) - v131_
	local v135_ = math.max(v134_, 0)
	if v133_ ~= 0 and v135_ ~= 0 then
		local v136_ = (v130_ - posX) / (v126_ - posX)
		local v137_ = (v131_ - posY) / (v127_ - posY)
		local v138_ = (v130_ + v133_ - posX) / (v126_ - posX)
		local v139_ = (v131_ + v135_ - posY) / (v127_ - posY)
		return v130_, v131_, v133_, v135_, (v122_ - v118_) * v136_ + v118_, (v121_ - v119_) * v137_ + v119_, (v122_ - v118_) * v136_ + v118_, (v125_ - v123_) * v139_ + v123_, (v122_ - v118_) * v138_ + v118_, (v121_ - v119_) * v137_ + v119_, (v124_ - v120_) * v138_ + v120_, (v125_ - v123_) * v139_ + v123_
	end
end

-- Local values: scale, scale
function Overlay:setSingleDimension(width, height)
	if width == nil or height == nil then
		if width == nil and height == nil then
			Logging.error("neither width nor height provided")
			printCallstack()
		else
			if width ~= nil then
				local v143_ = width / self.defaultWidth
				self:setDimension(width, self.defaultHeight * v143_)
			end
			if height ~= nil then
				local v144_ = height / self.defaultHeight
				self:setDimension(self.defaultWidth * v144_, height)
			end
		end
	else
		Logging.error("both width and height arguments provided, only provide one of the two or use setDimension() instead")
		printCallstack()
		return
	end
end

function Overlay:getExtends()
	return self.x + self.offsetX, self.y + self.offsetY, self.x + self.offsetX + self.width, self.y + self.offsetY + self.height
end
