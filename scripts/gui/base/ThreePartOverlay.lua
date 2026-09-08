-- Local values: ThreePartOverlay_mt
ThreePartOverlay = {}
if g_threePartTest ~= nil then
	g_threePartTest:delete()
	g_threePartTest = nil
end
local ThreePartOverlay_mt = Class(ThreePartOverlay)

-- Upvalues: ThreePartOverlay_mt
-- Local values: self
function ThreePartOverlay.new(custom_mt)
	-- upvalues: (copy) ThreePartOverlay_mt
	local v3_ = custom_mt or ThreePartOverlay_mt
	local v4_ = setmetatable({}, v3_)
	v4_.dirX = 1
	v4_.dirY = 0
	return v4_
end

function ThreePartOverlay:delete()
	if self.leftPart ~= nil then
		self.leftPart:delete()
		self.leftPart = nil
	end
	if self.middlePart ~= nil then
		self.middlePart:delete()
		self.middlePart = nil
	end
	if self.rightPart ~= nil then
		self.rightPart:delete()
		self.rightPart = nil
	end
end

function ThreePartOverlay:setLeftPart(sliceId, width, height)
	if sliceId ~= nil then
		if self.leftPart == nil then
			self.leftPart = g_overlayManager:createOverlay(sliceId, 0, 0, width, height)
		else
			self.leftPart:setSliceId(sliceId)
		end
	end
	if self.leftPart ~= nil then
		self.leftPart:setDimension(width, height)
	end
end

function ThreePartOverlay:setMiddlePart(sliceId, width, height)
	if sliceId ~= nil then
		if self.middlePart ~= nil then
			self.middlePart:delete()
		end
		self.middlePart = g_overlayManager:createOverlay(sliceId, 0, 0, width, height)
	end
	if self.middlePart ~= nil then
		self.middlePart:setDimension(width, height)
	end
end

function ThreePartOverlay:setRightPart(sliceId, width, height)
	if sliceId ~= nil then
		if self.rightPart ~= nil then
			self.rightPart:delete()
		end
		self.rightPart = g_overlayManager:createOverlay(sliceId, 0, 0, width, height)
	end
	if self.rightPart ~= nil then
		self.rightPart:setDimension(width, height)
	end
end

function ThreePartOverlay:setColor(r, g, b, a)
	if self.leftPart ~= nil then
		self.leftPart:setColor(r, g, b, a)
	end
	if self.middlePart ~= nil then
		self.middlePart:setColor(r, g, b, a)
	end
	if self.rightPart ~= nil then
		self.rightPart:setColor(r, g, b, a)
	end
end

function ThreePartOverlay:setPosition(x, y)
	self.x = x or self.x
	self.y = y or self.y
end

function ThreePartOverlay:setRotation(rotation)
	self.rotation = rotation + 1.5707963267948966
	if self.leftPart ~= nil then
		self.leftPart:setRotation(rotation, 0, 0)
	end
	if self.middlePart ~= nil then
		self.middlePart:setRotation(rotation, 0, 0)
	end
	if self.rightPart ~= nil then
		self.rightPart:setRotation(rotation, 0, 0)
	end
	local v28_ = self.rotation
	self.dirX = math.sin(v28_)
	local v29_ = self.rotation
	self.dirY = -math.cos(v29_)
end

-- Local values: x, y
function ThreePartOverlay:render()
	local v31_ = self.x
	local v32_ = self.y
	if self.leftPart ~= nil then
		self.leftPart:setPosition(v31_, v32_)
		self.leftPart:render()
		v31_ = v31_ + self.dirX * self.leftPart.width
		v32_ = v32_ + self.dirY * self.leftPart.width * g_screenAspectRatio
	end
	if self.middlePart ~= nil then
		self.middlePart:setPosition(v31_, v32_)
		self.middlePart:render()
		v31_ = v31_ + self.dirX * self.middlePart.width
		v32_ = v32_ + self.dirY * self.middlePart.width * g_screenAspectRatio
	end
	if self.rightPart ~= nil then
		self.rightPart:setPosition(v31_, v32_)
		self.rightPart:render()
	end
end
function ThreePartOverlay.renderTest()
	if g_threePartTest == nil then
		g_threePartTest = ThreePartOverlay.new()
		local v33_, v34_ = getNormalizedScreenValues(25, 25)
		g_threePartTest:setLeftPart("gui.progressbar_left", v33_, v34_)
		local v35_, v36_ = getNormalizedScreenValues(500, 25)
		g_threePartTest:setMiddlePart("gui.progressbar_middle", v35_, v36_)
		local v37_, v38_ = getNormalizedScreenValues(25, 25)
		g_threePartTest:setRightPart("gui.progressbar_right", v37_, v38_)
		g_threePartTest:setPosition(0.5, 0.5)
		g_threePartTest:setColor(1, 1, 1, 1)
		g_threePartTest:setRotation(-2.0943951023931953)
	end
	g_threePartTest:render()
	drawPoint(0.5, 0.5, g_pixelSizeX, g_pixelSizeY, 1, 0, 0, 1)
end
