-- Local values: DebugDensityMap_mt
DebugDensityMap = {}
local DebugDensityMap_mt = Class(DebugDensityMap, DebugElement)

-- Upvalues: DebugDensityMap_mt
-- Local values: self
function DebugDensityMap.new(customMt)
	-- upvalues: (copy) DebugDensityMap_mt
	local v3_ = DebugDensityMap:superClass().new(customMt or DebugDensityMap_mt)
	v3_.textColor = Color.new(1, 1, 1, 1)
	v3_.displayLegend = true
	return v3_
end

-- Local values: self, size
function DebugDensityMap.newFromMap(densityMap, firstChannel, numChannels, radius, yOffset, colors)
	local v10_ = DebugDensityMap.new()
	local v11_ = getDensityMapSize(densityMap)
	v10_.resolution = g_currentMission.terrainSize / v11_
	v10_.firsChannel = firstChannel
	v10_.numChannels = numChannels
	v10_.pixelValueToColor = colors
	v10_.radius = radius
	v10_.yOffset = yOffset or 0.1
	v10_.modifier = DensityMapModifier.new(densityMap, firstChannel, numChannels, g_terrainNode)
	v10_.filter = DensityMapFilter.new(v10_.modifier)
	return v10_
end

function DebugDensityMap:delete() end

function DebugDensityMap:update(dt) end

-- Local values: resolution, colors, radius, steps, visualOffsetX, visualOffsetZ, x, z, _, densityOffsetX, densityOffsetZ, xStep, zStep, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, dStartWorldX, dStartWorldZ, dWidthWorldX, dWidthWorldZ, dHeightWorldX, dHeightWorldZ, i, _, numPixels, _, vStartWorldX, vStartWorldZ, vWidthWorldX, vWidthWorldZ, vHeightWorldX, vHeightWorldZ, color, centerX, centerZ, centerY, legendEntryOffset, fontSize, colorBoxHeight, pixelValue, color
function DebugDensityMap:draw()
	local v13_ = self.resolution
	local v14_ = self.pixelValueToColor
	local v15_ = self.radius / v13_ - v13_ * 0.5
	local v16_ = math.ceil(v15_)
	local v17_ = v13_ * 0.5
	local v18_ = v13_ * 0.5
	local v19_ = self.centerX
	local v20_ = self.centerZ
	if v19_ == nil then
		local v21_
		v19_, v21_, v20_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	end
	local v22_ = v19_ / self.resolution
	local v23_ = math.floor(v22_) * self.resolution
	local v24_ = v20_ / self.resolution
	local v25_ = math.floor(v24_) * self.resolution
	local v26_ = v13_ * 0.1
	local v27_ = v13_ * 0.1
	for v28_ = 1, v16_ do
		for v29_ = 1, v16_ do
			local v30_ = v23_ + (v28_ - v16_ * 0.5) * v13_
			local v31_ = v25_ + (v29_ - v16_ * 0.5) * v13_
			local v32_ = v23_ + (v28_ + 1 - v16_ * 0.5) * v13_
			local v33_ = v25_ + (v29_ - v16_ * 0.5) * v13_
			local v34_ = v23_ + (v28_ - v16_ * 0.5) * v13_
			local v35_ = v25_ + (v29_ + 1 - v16_ * 0.5) * v13_
			local v36_ = v30_ + v26_
			local v37_ = v31_ + v27_
			local v38_ = v32_ - v26_
			local v39_ = v33_ + v27_
			local v40_ = v34_ + v26_
			local v41_ = v35_ - v27_
			self.modifier:setParallelogramWorldCoords(v36_, v37_, v38_, v39_, v40_, v41_, DensityCoordType.POINT_POINT_POINT)
			for v42_ = 0, 2 ^ self.numChannels - 1 do
				self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, v42_)
				local _, v43_, _ = self.modifier:executeGet(self.filter)
				if v43_ > 0 then
					local v44_ = v30_ + v13_ * 0.1 - v17_
					local v45_ = v31_ + v13_ * 0.1 - v18_
					local v46_ = v32_ - v13_ * 0.1 - v17_
					local v47_ = v33_ + v13_ * 0.1 - v18_
					local v48_ = v34_ + v13_ * 0.1 - v17_
					local v49_ = v35_ - v13_ * 0.1 - v18_
					local v50_ = v14_[v42_]
					if v50_ ~= nil then
						self:drawDebugAreaRectangleFilled(v44_, v45_, v46_, v47_, v48_, v49_, v50_)
					end
					local v51_ = (v44_ + v46_) * 0.5
					local v52_ = (v45_ + v49_) * 0.5
					local v53_ = getTerrainHeightAtWorldPos(g_terrainNode, v51_, 0, v52_) + self.yOffset
					Utils.renderTextAtWorldPosition(v51_, v53_, v52_, tostring(v42_), 0.012, 0, self.textColor)
					break
				end
			end
		end
	end
	if self.displayLegend then
		local v54_ = getTextHeight(0.015, "1") * 0.9
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.01, 0.7, 0.015, "DebugDensityMap colors")
		local v55_ = 0 + 0.0165
		for v56_, v57_ in pairs(v14_) do
			local v58_ = drawFilledRect
			local v59_ = 0.7 - v55_
			local v60_ = v57_[1]
			local v61_ = v57_[2]
			local v62_ = v57_[3]
			local v63_ = v57_[4]
			v58_(0.013, v59_, v54_, v54_, v60_, v61_, v62_, (math.max(v63_, 0.5)))
			renderText(0.013 + v54_ * 1.2, 0.7 - v55_, 0.015, string.format("%d", v56_))
			v55_ = v55_ + 0.015
		end
	end
end

function DebugDensityMap:setCenter(x, z)
	self.centerX = x
	self.centerZ = z
end

-- Local values: x3, z3, y, y1, y2, y3, r, g, b, a
function DebugDensityMap:drawDebugAreaRectangleFilled(x, z, x1, z1, x2, z2, color)
	local v75_ = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + self.yOffset
	local v76_ = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + self.yOffset
	local v77_ = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + self.yOffset
	local v78_ = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z2) + self.yOffset
	local v79_, v80_, v81_, v82_ = (color or Color.PRESETS.WHITE):unpack()
	drawDebugTriangle(x, v75_, z, x2, v77_, z2, x1, v76_, z1, v79_, v80_, v81_, v82_, false)
	drawDebugTriangle(x1, v76_, z1, x2, v77_, z2, x1, v78_, z2, v79_, v80_, v81_, v82_, false)
end
