-- Local values: HUDElement_mt
HUDElement = {}
local HUDElement_mt = Class(HUDElement)

-- Upvalues: HUDElement_mt
-- Local values: self
function HUDElement.new(overlay, parentHudElement, customMt)
	-- upvalues: (copy) HUDElement_mt
	local v5_ = customMt or HUDElement_mt
	local v6_ = setmetatable({}, v5_)
	v6_.overlay = overlay
	v6_.children = {}
	v6_.pivotX = 0
	v6_.pivotY = 0
	v6_.defaultPivotX = 0
	v6_.defaultPivotY = 0
	v6_.animation = TweenSequence.NO_SEQUENCE
	v6_.parent = nil
	if parentHudElement then
		parentHudElement:addChild(v6_)
	end
	return v6_
end

-- Local values: k, v
function HUDElement:delete()
	if self.overlay ~= nil then
		self.overlay:delete()
		self.overlay = nil
	end
	if self.parent ~= nil then
		self.parent:removeChild(self)
	end
	self.parent = nil
	for v8_, v9_ in pairs(self.children) do
		v9_.parent = nil
		v9_:delete()
		self.children[v8_] = nil
	end
end

function HUDElement:addChild(childHudElement)
	if childHudElement.parent ~= self then
		if childHudElement.parent ~= nil then
			childHudElement.parent:removeChild(childHudElement)
		end
		local v12_ = self.children
		table.insert(v12_, childHudElement)
		childHudElement.parent = self
	end
end

-- Local values: i, child
function HUDElement:removeChild(childHudElement)
	if childHudElement.parent == self then
		for v15_, v16_ in ipairs(self.children) do
			if v16_ == childHudElement then
				v16_.parent = nil
				table.remove(self.children, v15_)
				return
			end
		end
	end
end

-- Local values: prevX, prevY, moveX, moveY, _, child, childX, childY
function HUDElement:setPosition(x, y)
	local v20_, v21_ = self:getPosition()
	local v22_ = x or v20_
	local v23_ = y or v21_
	self.overlay:setPosition(v22_, v23_)
	if #self.children > 0 then
		local v24_ = v22_ - v20_
		local v25_ = v23_ - v21_
		for _, v26_ in pairs(self.children) do
			local v27_, v28_ = v26_:getPosition()
			v26_:setPosition(v27_ + v24_, v28_ + v25_)
		end
	end
end

function HUDElement:setRotation(rotation, centerX, centerY)
	self.overlay:setRotation(rotation, centerX or self.pivotX, centerY or self.pivotY)
end

function HUDElement:setRotationPivot(pivotX, pivotY)
	local v36_ = pivotX or self.defaultPivotX
	local v37_ = pivotY or self.defaultPivotY
	self.pivotX = v36_
	self.pivotY = v37_
	local v38_ = pivotX or self.defaultPivotX
	local v39_ = pivotY or self.defaultPivotY
	self.defaultPivotX = v38_
	self.defaultPivotY = v39_
end

function HUDElement:getRotationPivot()
	return self.pivotX, self.pivotY
end

function HUDElement:getPosition()
	return self.overlay:getPosition()
end

-- Local values: prevSelfX, prevSelfY, prevScaleWidth, prevScaleHeight, selfX, selfY, changeFactorX, changeFactorY, _, child, childScaleWidth, childScaleHeight, childPrevX, childPrevY, offX, offY, posX, posY
function HUDElement:setScale(scaleWidth, scaleHeight)
	local v45_, v46_ = self:getPosition()
	local v47_, v48_ = self:getScale()
	self.overlay:setScale(scaleWidth, scaleHeight)
	local v49_, v50_ = self:getPosition()
	if #self.children > 0 then
		local v51_ = scaleWidth / v47_
		local v52_ = scaleHeight / v48_
		for _, v53_ in pairs(self.children) do
			local v54_, v55_ = v53_:getScale()
			local v56_, v57_ = v53_:getPosition()
			local v58_ = v56_ - v45_
			local v59_ = v57_ - v46_
			v53_:setPosition(v49_ + v58_ * v51_, v50_ + v59_ * v52_)
			v53_:setScale(v54_ * v51_, v55_ * v52_)
		end
	end
	self.pivotX = self.defaultPivotX * scaleWidth
	self.pivotY = self.defaultPivotY * scaleHeight
end

function HUDElement:getScale()
	return self.overlay:getScale()
end

function HUDElement:setAlignment(vertical, horizontal)
	self.overlay:setAlignment(vertical, horizontal)
end

function HUDElement:setVisible(isVisible)
	if self.overlay ~= nil then
		self.overlay.visible = isVisible
	end
end

function HUDElement:getVisible()
	return self.overlay.visible
end

function HUDElement:getColor()
	return self.overlay.r, self.overlay.g, self.overlay.b, self.overlay.a
end

function HUDElement:getAlpha()
	return self.overlay.a
end

function HUDElement:getWidth()
	return self.overlay.width
end

function HUDElement:getHeight()
	return self.overlay.height
end

function HUDElement:setDimension(width, height)
	self.overlay:setDimension(width, height)
end

function HUDElement:getDimension()
	return self.overlay.width, self.overlay.height
end

function HUDElement:resetDimensions()
	self.overlay:resetDimensions()
	self.pivotX = self.defaultPivotX
	self.pivotY = self.defaultPivotY
end

function HUDElement:setColor(r, g, b, a)
	self.overlay:setColor(r, g, b, a)
end

function HUDElement:setAlpha(alpha)
	self.overlay:setColor(nil, nil, nil, alpha)
end

function HUDElement:setImage(imageFilename)
	self.overlay:setImage(imageFilename)
end

function HUDElement:setUVs(uvs)
	self.overlay:setUVs(uvs)
end

function HUDElement:setSliceId(sliceId)
	self.overlay:setSliceId(sliceId)
end

function HUDElement:update(dt)
	if not self.animation:getFinished() then
		self.animation:update(dt)
	end
end

-- Local values: _, child
function HUDElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self.overlay.visible then
		self.overlay:render(clipX1, clipY1, clipX2, clipY2)
		for _, v96_ in ipairs(self.children) do
			v96_:draw(clipX1, clipY1, clipX2, clipY2)
		end
	end
end

function HUDElement:scalePixelToScreenVector(vector2D)
	return vector2D[1] * self.overlay.scaleWidth * g_aspectScaleX / g_referenceScreenWidth, vector2D[2] * self.overlay.scaleHeight * g_aspectScaleY / g_referenceScreenHeight
end

function HUDElement:scalePixelValuesToScreenVector(width, height)
	return width * self.overlay.scaleWidth * g_aspectScaleX / g_referenceScreenWidth, height * self.overlay.scaleHeight * g_aspectScaleY / g_referenceScreenHeight
end

function HUDElement:scalePixelToScreenHeight(height)
	return height * self.overlay.scaleHeight * g_aspectScaleY / g_referenceScreenHeight
end

function HUDElement:scalePixelToScreenWidth(width)
	return width * self.overlay.scaleWidth * g_aspectScaleX / g_referenceScreenWidth
end

function HUDElement:normalizeUVPivot(uvPivot, size, uvs)
	return self:scalePixelToScreenWidth(uvPivot[1] * size[1] / uvs[3]), self:scalePixelToScreenHeight(uvPivot[2] * size[2] / uvs[4])
end
HUDElement.TEXT_SIZE = {
	["DEFAULT_TITLE"] = "20",
	["DEFAULT_TEXT"] = "16",
	["DEFAULT_TEXT_MOBILE"] = "30"
}
