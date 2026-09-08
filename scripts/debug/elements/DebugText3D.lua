-- Local values: DebugText3D_mt
DebugText3D = {}
local DebugText3D_mt = Class(DebugText3D, DebugElement)

-- Upvalues: DebugText3D_mt
-- Local values: self
function DebugText3D.new(customMt)
	-- upvalues: (copy) DebugText3D_mt
	local v3_ = DebugText3D:superClass().new(customMt or DebugText3D_mt)
	v3_.alignment = RenderText.ALIGN_CENTER
	v3_.verticalAlignment = RenderText.VERTICAL_ALIGN_MIDDLE
	v3_.size = 0.1
	return v3_
end

function DebugText3D:draw()
	DebugText3D.renderAtPosition(self.x, self.y, self.z, self.rx, self.ry, self.rz, self.text, self.color, self.size, self.alignment, self.verticalAlignment)
end

function DebugText3D.renderAtPosition(x, y, z, rx, ry, rz, text, color, size, alignment, verticalAlignment)
	setTextAlignment(alignment or RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(verticalAlignment or RenderText.VERTICAL_ALIGN_BASELINE)
	setTextBold(false)
	setTextColor((color or Color.PRESETS.WHITE):unpack())
	renderText3D(x, y, z, rx, ry, rz, size, text)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
end

-- Local values: x, y, z, rx, ry, rz
function DebugText3D.renderAtNode(node, text, color, size, alignment, verticalAlignment)
	local v22_, v23_, v24_ = getWorldTranslation(node)
	local v25_, v26_, v27_ = getWorldRotation(node)
	DebugText3D.renderAtPosition(v22_, v23_, v24_, v25_, v26_, v27_, text, color, size, alignment, verticalAlignment)
end

-- Local values: x, y, z, rx, ry, rz
function DebugText3D:createWithNode(node, text, size)
	local v32_, v33_, v34_ = getWorldTranslation(node)
	local v35_, v36_, v37_ = getWorldRotation(node)
	self:createWithWorldPos(v32_, v33_, v34_, v35_, v36_, v37_, text, size)
	return self
end

function DebugText3D:createWithWorldPos(x, y, z, rx, ry, rz, text, size)
	self.x = x
	self.y = y
	self.z = z
	self.rx = rx
	self.ry = ry
	self.rz = rz
	self.text = text
	self.size = size or 0.02
	return self
end
