-- Local values: DebugText_mt
DebugText = {}
local DebugText_mt = Class(DebugText, DebugElement)

-- Upvalues: DebugText_mt
-- Local values: self
function DebugText.new(customMt)
	-- upvalues: (copy) DebugText_mt
	local v3_ = DebugText:superClass().new(customMt or DebugText_mt)
	v3_.alignment = RenderText.ALIGN_CENTER
	v3_.verticalAlignment = RenderText.VERTICAL_ALIGN_MIDDLE
	v3_.size = 0.1
	v3_.screenSpaceOffset = nil
	v3_.node = nil
	return v3_
end

function DebugText:draw()
	if self.node ~= nil and entityExists(self.node) then
		local v5_, v6_, v7_ = getWorldTranslation(self.node)
		self.x = v5_
		self.y = v6_
		self.z = v7_
	end
	DebugText.renderAtPosition(self.x, self.y, self.z, self.text, self.color, self.size, self.screenSpaceOffset, self.alignment, self.verticalAlignment)
end

-- Local values: sx, sy, sz
function DebugText.renderAtPosition(x, y, z, text, color, size, screenSpaceYOffset, alignment, verticalAlignment)
	if y == nil then
		if g_terrainNode == nil then
			return
		end
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
	end
	local v17_, v18_, v19_ = project(x, y, z)
	if v19_ <= 1 then
		DebugText.renderAtScreenPosition(v17_, v18_, text, color, size, screenSpaceYOffset, alignment, verticalAlignment)
	end
end

-- Local values: textWidth, textHeight
function DebugText.renderAtScreenPosition(x, y, text, color, size, yOffset, alignment, verticalAlignment)
	if x > -1 and (x < 2 and (y > -1 and y < 2)) then
		local v28_ = size or 0.02
		local v29_ = yOffset or 0
		local v30_ = getTextWidth(v28_, text)
		local v31_ = getTextHeight(v28_, text)
		if x + v30_ >= 0 and (x - v30_ <= 1 and (y + v31_ >= 0 and y - v31_ <= 1)) then
			local v32_ = y + v31_ - v28_
			setTextAlignment(alignment or RenderText.ALIGN_CENTER)
			setTextVerticalAlignment(verticalAlignment or RenderText.VERTICAL_ALIGN_BASELINE)
			setTextBold(false)
			setTextColor(0, 0, 0, 0.75)
			renderText(x, v32_ - 0.0015 + v29_, v28_, text)
			setTextColor((color or Color.PRESETS.WHITE):unpack())
			renderText(x, v32_ + v29_, v28_, text)
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
			setTextAlignment(RenderText.ALIGN_LEFT)
			setTextColor(1, 1, 1, 1)
			return v32_ - v28_
		end
	end
end

-- Local values: x, y, z
function DebugText.renderAtNode(node, text, color, size, alignment, verticalAlignment)
	local v39_, v40_, v41_ = getWorldTranslation(node)
	DebugText.renderAtPosition(v39_, v40_, v41_, text, color, size, 0, alignment, verticalAlignment)
end

-- Local values: x, y, z
function DebugText:createWithNode(node, text, size, updatePosition)
	local v47_, v48_, v49_ = getWorldTranslation(node)
	self:createWithWorldPos(v47_, v48_, v49_, text, size)
	if updatePosition == true then
		self.node = node
	end
	return self
end

function DebugText:createWithWorldPos(x, y, z, text, size)
	self.x = x
	self.y = y
	self.z = z
	self.text = text and tostring(text) or nil
	self.size = size or 0.02
	return self
end
