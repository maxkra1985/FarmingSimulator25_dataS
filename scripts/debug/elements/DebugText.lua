DebugText = {}
local DebugText_mt = Class(DebugText, DebugElement)
function DebugText.new(customMt)
	local self = DebugText:superClass().new(customMt or DebugText_mt)
	self.alignment = RenderText.ALIGN_CENTER
	self.verticalAlignment = RenderText.VERTICAL_ALIGN_MIDDLE
	self.size = 0.1
	self.screenSpaceOffset = nil
	self.node = nil
	return self
end
function DebugText:draw()
	if self.node ~= nil and entityExists(self.node) then
		self.x, self.y, self.z = getWorldTranslation(self.node)
	end
	DebugText.renderAtPosition(self.x, self.y, self.z, self.text, self.color, self.size, self.screenSpaceOffset, self.alignment, self.verticalAlignment)
end
function DebugText.renderAtPosition(x, y, z, text, color, size, screenSpaceYOffset, alignment, verticalAlignment)
	if y == nil then
		if g_terrainNode == nil then
			return
		end
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
	end
	local sx, sy, sz = project(x, y, z)
	if 1 < sz then
		return
	else
		DebugText.renderAtScreenPosition(sx, sy, text, color, size, screenSpaceYOffset, alignment, verticalAlignment)
	end
end
function DebugText.renderAtScreenPosition(x, y, text, color, size, yOffset, alignment, verticalAlignment)
	if x <= -1 or 2 <= x or y <= -1 or 2 <= y then
		return
	end
	size = size or 0.02
	yOffset = yOffset or 0
	local textWidth = getTextWidth(size, text)
	local textHeight = getTextHeight(size, text)
	if x + textWidth < 0 or 1 < x - textWidth or y + textHeight < 0 or 1 < y - textHeight then
		return
	end
	y = y + textHeight - size
	setTextAlignment(alignment or RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(verticalAlignment or RenderText.VERTICAL_ALIGN_BASELINE)
	setTextBold(false)
	setTextColor(0, 0, 0, 0.75)
	renderText(x, y - 0.0015 + yOffset, size, text)
	setTextColor((color or Color.PRESETS.WHITE):unpack())
	renderText(x, y + yOffset, size, text)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	return y - size
end
function DebugText.renderAtNode(node, text, color, size, alignment, verticalAlignment)
	local x, y, z = getWorldTranslation(node)
	DebugText.renderAtPosition(x, y, z, text, color, size, 0, alignment, verticalAlignment)
end
function DebugText:createWithNode(node, text, size, updatePosition)
	local x, y, z = getWorldTranslation(node)
	self:createWithWorldPos(x, y, z, text, size)
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
