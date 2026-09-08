-- Local values: DebugPolygon_mt
DebugPolygon = {}
local DebugPolygon_mt = Class(DebugPolygon, DebugElement)

-- Upvalues: DebugPolygon_mt
-- Local values: self
function DebugPolygon.new(customMt)
	-- upvalues: (copy) DebugPolygon_mt
	local v3_ = DebugPolygon:superClass().new(customMt or DebugPolygon_mt)
	v3_.solid = false
	v3_.drawContour = false
	v3_.positions = {}
	return v3_
end

function DebugPolygon:draw()
	DebugPolygon.renderWithPositions(self.positions, self.color, self.solid, self.drawContour)
end

-- Local values: r, g, b, a, i
function DebugPolygon.renderWithPositions(positions, color, solid, drawContour)
	local v9_, v10_, v11_, v12_ = (color or Color.PRESETS.WHITE):unpack()
	local v13_ = Utils.getNoNil(solid, false)
	drawDebugPolygon(positions, v9_, v10_, v11_, v12_, v13_)
	if drawContour then
		for v14_ = 1, #positions, 3 do
			if v14_ + 3 < #positions then
				drawDebugLine(positions[v14_], positions[v14_ + 1], positions[v14_ + 2], v9_, v10_, v11_, positions[v14_ + 3], positions[v14_ + 4], positions[v14_ + 5], v9_, v10_, v11_, v13_)
			else
				drawDebugLine(positions[v14_], positions[v14_ + 1], positions[v14_ + 2], v9_, v10_, v11_, positions[1], positions[2], positions[3], v9_, v10_, v11_, v13_)
			end
		end
	end
end

function DebugPolygon:create(positions)
	self.positions = positions
	return self
end

function DebugPolygon:addPosition(x, y, z)
	local v21_ = self.positions
	table.insert(v21_, x)
	local v22_ = self.positions
	table.insert(v22_, y)
	local v23_ = self.positions
	table.insert(v23_, z)
	return self
end

function DebugPolygon:setDrawContour(drawContour)
	self.drawContour = drawContour
	return self
end
