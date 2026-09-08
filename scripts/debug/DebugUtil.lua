DebugUtil = {}
DebugUtil.DEFAULT_RENDERLINE_SCALAR = 1.1
DebugUtil.COLORS = {
	Color.PRESETS.MAGENTA,
	Color.PRESETS.GREENYELLOW,
	Color.PRESETS.CYAN,
	Color.PRESETS.RED,
	Color.PRESETS.BLUE,
	Color.PRESETS.ORANGE,
	Color.PRESETS.GREEN,
	Color.PRESETS.TEAL
}

-- Local values: x, y, z, upX, upY, upZ, dirX, dirY, dirZ
function DebugUtil.drawDebugNode(node, text, alignToGround, offsetY)
	local v5_, v6_, v7_ = getWorldTranslation(node)
	local v8_, v9_, v10_ = localDirectionToWorld(node, 0, 1, 0)
	local v11_, v12_, v13_ = localDirectionToWorld(node, 0, 0, 1)
	DebugUtil.drawDebugGizmoAtWorldPos(v5_, v6_ + (offsetY or 0), v7_, v11_, v12_, v13_, v8_, v9_, v10_, text, alignToGround)
end

-- Local values: x, y, z
function DebugUtil.renderTextAtNode(node, text, textSize)
	local v17_, v18_, v19_ = getWorldTranslation(node)
	Utils.renderTextAtWorldPosition(v17_, v18_, v19_, text, textSize or 0.02)
end

-- Local values: sideX, sideY, sideZ
function DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, text, alignToGround, color)
	local v32_, v33_, v34_ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	if alignToGround then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
	end
	drawDebugLine(x, y, z, 1, 0, 0, x + v32_ * 0.3, y + v33_ * 0.3, z + v34_ * 0.3, 1, 0, 0)
	drawDebugLine(x, y, z, 0, 1, 0, x + upX * 0.3, y + upY * 0.3, z + upZ * 0.3, 0, 1, 0)
	drawDebugLine(x, y, z, 0, 0, 1, x + dirX * 0.3, y + dirY * 0.3, z + dirZ * 0.3, 0, 0, 1)
	if text ~= nil then
		Utils.renderTextAtWorldPosition(x, y, z, tostring(text), getCorrectTextSize(0.012), 0, color)
	end
end

-- Local values: x, y, z, x1, y1, z1, x2, y2, z2, lsx, lsy, lsz, lex, ley, lez, radius
function DebugUtil.drawDebugArea(start, width, height, r, g, b, alignToGround, drawNodes, drawCircle, offsetY)
	local v45_ = offsetY or 0
	local v46_, v47_, v48_ = getWorldTranslation(start)
	local v49_, v50_, v51_ = getWorldTranslation(width)
	local v52_, v53_, v54_ = getWorldTranslation(height)
	local v55_ = v47_ + v45_
	local v56_ = v50_ + v45_
	local v57_ = v53_ + v45_
	DebugUtil.drawDebugAreaRectangle(v46_, v55_, v48_, v49_, v56_, v51_, v52_, v57_, v54_, alignToGround, r, g, b)
	if drawNodes == nil or drawNodes then
		DebugGizmo.renderAtNodeWithOffset(start, 0, v45_, 0, getName(start), false, 1, alignToGround)
		DebugGizmo.renderAtNodeWithOffset(width, 0, v45_, 0, getName(width), false, 1, alignToGround)
		DebugGizmo.renderAtNodeWithOffset(height, 0, v45_, 0, getName(height), false, 1, alignToGround)
	end
	local v58_, v59_, v60_, v61_, v62_, v63_, v64_ = DensityMapHeightUtil.getLineByArea(start, width, height, 0.5)
	local v65_ = v59_ + v45_
	local v66_ = v62_ + v45_
	if alignToGround then
		v65_ = getTerrainHeightAtWorldPos(g_terrainNode, v58_, 0, v60_) + 0.1
		v66_ = getTerrainHeightAtWorldPos(g_terrainNode, v61_, 0, v63_) + 0.1
	end
	if drawCircle == nil or drawCircle then
		drawDebugLine(v58_, v65_, v60_, 1, 1, 1, v61_, v66_, v63_, 1, 1, 1)
		DebugUtil.drawDebugCircle((v58_ + v61_) * 0.5, (v65_ + v66_) * 0.5, (v60_ + v63_) * 0.5, v64_, 20, nil)
	end
end

function DebugUtil.drawDebugLine(x1, y1, z1, x2, y2, z2, r, g, b, radius, alignToGround)
	local v78_, v79_
	if alignToGround then
		v78_ = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.1
		v79_ = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.1
	else
		v78_ = y1 or 0
		v79_ = y2 or 0
	end
	local v80_ = r or 1
	local v81_ = g or 1
	local v82_ = b or 1
	drawDebugLine(x1, v78_, z1, v80_, v81_, v82_, x2, v79_, z2, v80_, v81_, v82_)
	if radius ~= nil then
		DebugUtil.drawDebugCircle(x1, v78_, z1, radius, 20, nil)
		DebugUtil.drawDebugCircle(x2, v79_, z2, radius, 20, nil)
	end
end

-- Local values: dirX1, dirY1, dirZ1, dirX2, dirY2, dirZ2
function DebugUtil.drawDebugAreaRectangle(x, y, z, x1, y1, z1, x2, y2, z2, alignToGround, r, g, b)
	if alignToGround then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
		y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.1
		y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.1
	end
	drawDebugLine(x, y, z, r, g, b, x1, y1, z1, r, g, b)
	drawDebugLine(x, y, z, r, g, b, x2, y2, z2, r, g, b)
	local v96_ = x1 - x
	local v97_ = y1 - y
	local v98_ = z1 - z
	local v99_ = x2 - x
	local v100_ = y2 - y
	local v101_ = z2 - z
	drawDebugLine(x2, y2, z2, r, g, b, x2 + v96_, y2 + v97_, z2 + v98_, r, g, b)
	drawDebugLine(x1, y1, z1, r, g, b, x1 + v99_, y1 + v100_, z1 + v101_, r, g, b)
end

-- Local values: x2, y2, z2, x3, y3, z3, x4, y4, z4
function DebugUtil.drawDebugPlane(x, y, z, forwardX, forwardY, forwardZ, leftX, leftY, leftZ, width, depth, r, g, b, a)
	local v117_ = x + leftX * width
	local v118_ = y + leftY * width
	local v119_ = z + leftZ * width
	local v120_ = x + forwardX * depth
	local v121_ = y + forwardY * depth
	local v122_ = z + forwardZ * depth
	local v123_ = x + forwardX * depth + leftX * width
	local v124_ = y + forwardY * depth + leftY * width
	local v125_ = z + forwardZ * depth + leftZ * width
	DebugUtil.drawDebugAreaRectangle(x, y, z, v117_, v118_, v119_, v120_, v121_, v122_, false, r, g, b)
	drawDebugTriangle(v120_, v121_, v122_, x, y, z, v117_, v118_, v119_, r, g, b, a, true)
	drawDebugTriangle(v123_, v124_, v125_, v120_, v121_, v122_, v117_, v118_, v119_, r, g, b, a, true)
	drawDebugTriangle(v123_, v124_, v125_, x, y, z, v120_, v121_, v122_, r, g, b, a, true)
	drawDebugTriangle(v123_, v124_, v125_, v117_, v118_, v119_, x, y, z, r, g, b, a, true)
end

-- Local values: x3, y3, z3
function DebugUtil.drawDebugAreaRectangleFilled(x, y, z, x1, y1, z1, x2, y2, z2, alignToGround, r, g, b, a)
	local v140_ = (y1 + y2) / 2
	if alignToGround then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
		y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.1
		y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.1
		v140_ = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z2) + 0.1
	end
	drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
	drawDebugTriangle(x1, y1, z1, x2, y2, z2, x1, v140_, z2, r, g, b, a, false)
end

-- Local values: leftFrontX, leftFrontY, leftFrontZ, rightFrontX, rightFrontY, rightFrontZ, leftBackX, leftBackY, leftBackZ, rightBackX, rightBackY, rightBackZ
function DebugUtil.drawDebugRectangle(node, minX, maxX, minZ, maxZ, yOffset, r, g, b, a, filled)
	local v152_, v153_, v154_ = localToWorld(node, minX, yOffset, maxZ)
	local v155_, v156_, v157_ = localToWorld(node, maxX, yOffset, maxZ)
	local v158_, v159_, v160_ = localToWorld(node, minX, yOffset, minZ)
	local v161_, v162_, v163_ = localToWorld(node, maxX, yOffset, minZ)
	drawDebugLine(v152_, v153_, v154_, r, g, b, v155_, v156_, v157_, r, g, b)
	drawDebugLine(v155_, v156_, v157_, r, g, b, v161_, v162_, v163_, r, g, b)
	drawDebugLine(v161_, v162_, v163_, r, g, b, v158_, v159_, v160_, r, g, b)
	drawDebugLine(v158_, v159_, v160_, r, g, b, v152_, v153_, v154_, r, g, b)
	if filled then
		drawDebugTriangle(v152_, v153_, v154_, v155_, v156_, v157_, v161_, v162_, v163_, r, g, b, a, true)
		drawDebugTriangle(v161_, v162_, v163_, v158_, v159_, v160_, v152_, v153_, v154_, r, g, b, a, true)
	end
end

-- Local values: ringSpacing, ringY, radialSpacing, radialAngle, lastRingY, lastRingRadius, i, ringRadius, j, radialAngleSin, radialAngleCos, radialPositionX, radialPositionZ, lastRadialPositionX, lastRadialPositionZ, j, radialAngleSin, radialAngleCos, radialPositionX, radialPositionZ
function DebugUtil.drawDebugSphere(x, y, z, radius, radialSegments, rings, color, alignToGround, solid)
	if alignToGround then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
	end
	local v173_ = radius * 2 / (rings + 1)
	local v174_ = y + radius - v173_
	local v175_ = 6.283185307179586 / radialSegments
	local v176_ = y + radius
	drawDebugPoint(x, y, z, color.r, color.g, color.b, color.a, solid)
	local v177_ = 0
	for _ = 1, rings do
		local v178_ = radius ^ 2 - (y - v174_) ^ 2
		local v179_ = math.sqrt(v178_)
		DebugUtil.drawDebugCircle(x, v174_, z, v179_, radialSegments, color, false, false, solid)
		local v180_ = 0
		for _ = 1, radialSegments do
			local v181_ = math.sin(v180_)
			local v182_ = math.cos(v180_)
			local v183_ = x + v182_ * v179_
			local v184_ = z + v181_ * v179_
			local v185_ = x + v182_ * v177_
			local v186_ = z + v181_ * v177_
			drawDebugLine(v185_, v176_, v186_, color[1], color[2], color[3], v183_, v174_, v184_, color[1], color[2], color[3], solid)
			v180_ = v180_ + v175_
		end
		local v187_ = v174_ - v173_
		v176_ = v174_
		v174_ = v187_
		v177_ = v179_
	end
	local v188_ = 0
	for _ = 1, radialSegments do
		local v189_ = math.sin(v188_)
		local v190_ = x + math.cos(v188_) * v177_
		local v191_ = z + v189_ * v177_
		drawDebugLine(v190_, v176_, v191_, color[1], color[2], color[3], x, v174_, z, color[1], color[2], color[3], solid)
		v188_ = v188_ + v175_
	end
end

-- Local values: r, g, b, terrainNode, i, a1, a2, c, s, x1, y1, z1, x2, y2, z2
function DebugUtil.drawDebugCircle(x, y, z, radius, steps, color, alignToTerrain, filled, solid)
	local v201_, v202_, v203_
	if color == nil then
		v201_ = 1
		v202_ = 0
		v203_ = 0
	else
		v201_ = color[1]
		v203_ = color[2]
		v202_ = color[3]
	end
	local v204_ = g_terrainNode
	for v205_ = 1, steps do
		local v206_ = (v205_ - 1) / steps * 2 * 3.141592653589793
		local v207_ = v205_ / steps * 2 * 3.141592653589793
		local v208_ = math.cos(v206_) * radius
		local v209_ = math.sin(v206_) * radius
		local v210_ = x + v208_
		local v211_ = z + v209_
		local v212_ = math.cos(v207_) * radius
		local v213_ = math.sin(v207_) * radius
		local v214_ = x + v212_
		local v215_ = z + v213_
		local v216_, v217_
		if alignToTerrain then
			y = getTerrainHeightAtWorldPos(v204_, x, y, z) + 0.25
			v216_ = getTerrainHeightAtWorldPos(v204_, v210_, y, v211_) + 0.25
			v217_ = getTerrainHeightAtWorldPos(v204_, v214_, y, v215_) + 0.25
		else
			v217_ = y
			v216_ = v217_
			local v218_ = v217_
			v217_ = v216_
			v218_ = v216_
		end
		drawDebugLine(v210_, v216_, v211_, v201_, v203_, v202_, v214_, v217_, v215_, v201_, v203_, v202_, solid)
		if filled then
			drawDebugTriangle(x, y, z, v214_, v217_, v215_, v210_, v216_, v211_, v201_, v203_, v202_, 0.3, solid)
		end
	end
end

-- Local values: ox, oy, oz, i, a1, a2, c, s, x1, y1, z1, x2, y2, z2
function DebugUtil.drawDebugCircleAtNode(node, radius, steps, color, vertical, offset)
	local v225_, v226_, v227_
	if offset == nil then
		v225_ = 0
		v226_ = 0
		v227_ = 0
	else
		v227_ = offset[1]
		v225_ = offset[2]
		v226_ = offset[3]
	end
	for v228_ = 1, steps do
		local v229_ = (v228_ - 1) / steps * 2 * 3.141592653589793
		local v230_ = v228_ / steps * 2 * 3.141592653589793
		local v231_ = math.cos(v229_) * radius
		local v232_ = math.sin(v229_) * radius
		local v233_, v234_, v235_
		if vertical then
			v233_, v234_, v235_ = localToWorld(node, v227_ + 0, v225_ + v231_, v226_ + v232_)
		else
			v233_, v234_, v235_ = localToWorld(node, v227_ + v231_, v225_ + 0, v226_ + v232_)
		end
		local v236_ = math.cos(v230_) * radius
		local v237_ = math.sin(v230_) * radius
		local v238_, v239_, v240_
		if vertical then
			v238_, v239_, v240_ = localToWorld(node, v227_ + 0, v225_ + v236_, v226_ + v237_)
		else
			v238_, v239_, v240_ = localToWorld(node, v227_ + v236_, v225_ + 0, v226_ + v237_)
		end
		if color == nil then
			drawDebugLine(v233_, v234_, v235_, 1, 0, 0, v238_, v239_, v240_, 1, 0, 0)
		else
			drawDebugLine(v233_, v234_, v235_, color[1], color[2], color[3], v238_, v239_, v240_, color[1], color[2], color[3])
		end
	end
end

-- Local values: temp
function DebugUtil.drawDebugCubeAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, sizeX, sizeY, sizeZ, r, g, b)
	local v256_ = createTransformGroup("temp_drawDebugCubeAtWorldPos")
	link(getRootNode(), v256_)
	setTranslation(v256_, x, y, z)
	setDirection(v256_, dirX, dirY, dirZ, upX, upY, upZ)
	DebugUtil.drawDebugCube(v256_, sizeX, sizeY, sizeZ, r, g, b)
	delete(v256_)
end

-- Local values: temp
function DebugUtil.drawOverlapBox(x, y, z, rotX, rotY, rotZ, extendX, extendY, extendZ, r, g, b)
	local v269_ = createTransformGroup("temp_drawDebugCubeAtWorldPos")
	link(getRootNode(), v269_)
	setTranslation(v269_, x, y, z)
	setRotation(v269_, rotX, rotY, rotZ)
	DebugUtil.drawDebugCube(v269_, extendX * 2, extendY * 2, extendZ * 2, r, g, b)
	delete(v269_)
end

-- Local values: x, y, z, up1X, up1Y, up1Z, upX, upY, upZ, dirX, dirY, dirZ
function DebugUtil.drawDebugCube(node, sizeX, sizeY, sizeZ, r, g, b, offsetX, offsetY, offsetZ)
	local v280_ = sizeX * 0.5
	local v281_ = sizeY * 0.5
	local v282_ = sizeZ * 0.5
	local v283_ = r or 1
	local v284_ = g or 1
	local v285_ = b or 1
	local v286_, v287_, v288_ = localToWorld(node, offsetX or 0, offsetY or 0, offsetZ or 0)
	local v289_, v290_, v291_ = localDirectionToWorld(node, 1, 0, 0)
	local v292_, v293_, v294_ = localDirectionToWorld(node, 0, 1, 0)
	local v295_, v296_, v297_ = localDirectionToWorld(node, 0, 0, 1)
	local v298_ = v289_ * v280_
	local v299_ = v290_ * v280_
	local v300_ = v291_ * v280_
	local v301_ = v292_ * v281_
	local v302_ = v293_ * v281_
	local v303_ = v294_ * v281_
	local v304_ = v295_ * v282_
	local v305_ = v296_ * v282_
	local v306_ = v297_ * v282_
	drawDebugLine(v286_ + v298_ - v304_ - v301_, v287_ + v299_ - v305_ - v302_, v288_ + v300_ - v306_ - v303_, v283_, v284_, v285_, v286_ + v298_ - v304_ + v301_, v287_ + v299_ - v305_ + v302_, v288_ + v300_ - v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ - v298_ - v304_ - v301_, v287_ - v299_ - v305_ - v302_, v288_ - v300_ - v306_ - v303_, v283_, v284_, v285_, v286_ - v298_ - v304_ + v301_, v287_ - v299_ - v305_ + v302_, v288_ - v300_ - v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ + v298_ + v304_ - v301_, v287_ + v299_ + v305_ - v302_, v288_ + v300_ + v306_ - v303_, v283_, v284_, v285_, v286_ + v298_ + v304_ + v301_, v287_ + v299_ + v305_ + v302_, v288_ + v300_ + v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ - v298_ + v304_ - v301_, v287_ - v299_ + v305_ - v302_, v288_ - v300_ + v306_ - v303_, v283_, v284_, v285_, v286_ - v298_ + v304_ + v301_, v287_ - v299_ + v305_ + v302_, v288_ - v300_ + v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ + v298_ - v304_ + v301_, v287_ + v299_ - v305_ + v302_, v288_ + v300_ - v306_ + v303_, v283_, v284_, v285_, v286_ - v298_ - v304_ + v301_, v287_ - v299_ - v305_ + v302_, v288_ - v300_ - v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ - v298_ - v304_ + v301_, v287_ - v299_ - v305_ + v302_, v288_ - v300_ - v306_ + v303_, v283_, v284_, v285_, v286_ - v298_ + v304_ + v301_, v287_ - v299_ + v305_ + v302_, v288_ - v300_ + v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ - v298_ + v304_ + v301_, v287_ - v299_ + v305_ + v302_, v288_ - v300_ + v306_ + v303_, v283_, v284_, v285_, v286_ + v298_ + v304_ + v301_, v287_ + v299_ + v305_ + v302_, v288_ + v300_ + v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ + v298_ + v304_ + v301_, v287_ + v299_ + v305_ + v302_, v288_ + v300_ + v306_ + v303_, v283_, v284_, v285_, v286_ + v298_ - v304_ + v301_, v287_ + v299_ - v305_ + v302_, v288_ + v300_ - v306_ + v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ + v298_ - v304_ - v301_, v287_ + v299_ - v305_ - v302_, v288_ + v300_ - v306_ - v303_, v283_, v284_, v285_, v286_ - v298_ - v304_ - v301_, v287_ - v299_ - v305_ - v302_, v288_ - v300_ - v306_ - v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ - v298_ - v304_ - v301_, v287_ - v299_ - v305_ - v302_, v288_ - v300_ - v306_ - v303_, v283_, v284_, v285_, v286_ - v298_ + v304_ - v301_, v287_ - v299_ + v305_ - v302_, v288_ - v300_ + v306_ - v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ - v298_ + v304_ - v301_, v287_ - v299_ + v305_ - v302_, v288_ - v300_ + v306_ - v303_, v283_, v284_, v285_, v286_ + v298_ + v304_ - v301_, v287_ + v299_ + v305_ - v302_, v288_ + v300_ + v306_ - v303_, v283_, v284_, v285_)
	drawDebugLine(v286_ + v298_ + v304_ - v301_, v287_ + v299_ + v305_ - v302_, v288_ + v300_ + v306_ - v303_, v283_, v284_, v285_, v286_ + v298_ - v304_ - v301_, v287_ + v299_ - v305_ - v302_, v288_ + v300_ - v306_ - v303_, v283_, v284_, v285_)
end

-- Local values: halfWidth
function DebugUtil.drawSimpleDebugCube(x, y, z, width, r, g, b)
	local v314_ = width * 0.5
	drawDebugLine(x - v314_, y - v314_, z - v314_, r, g, b, x + v314_, y - v314_, z - v314_, r, g, b)
	drawDebugLine(x - v314_, y - v314_, z - v314_, r, g, b, x - v314_, y + v314_, z - v314_, r, g, b)
	drawDebugLine(x - v314_, y - v314_, z - v314_, r, g, b, x - v314_, y - v314_, z + v314_, r, g, b)
	drawDebugLine(x + v314_, y + v314_, z + v314_, r, g, b, x - v314_, y + v314_, z + v314_, r, g, b)
	drawDebugLine(x + v314_, y + v314_, z + v314_, r, g, b, x + v314_, y - v314_, z + v314_, r, g, b)
	drawDebugLine(x + v314_, y + v314_, z + v314_, r, g, b, x + v314_, y + v314_, z - v314_, r, g, b)
	drawDebugLine(x - v314_, y - v314_, z + v314_, r, g, b, x + v314_, y - v314_, z + v314_, r, g, b)
	drawDebugLine(x - v314_, y - v314_, z + v314_, r, g, b, x - v314_, y + v314_, z + v314_, r, g, b)
	drawDebugLine(x - v314_, y + v314_, z - v314_, r, g, b, x - v314_, y + v314_, z + v314_, r, g, b)
	drawDebugLine(x - v314_, y + v314_, z - v314_, r, g, b, x + v314_, y + v314_, z - v314_, r, g, b)
	drawDebugLine(x + v314_, y - v314_, z - v314_, r, g, b, x + v314_, y + v314_, z - v314_, r, g, b)
	drawDebugLine(x + v314_, y - v314_, z - v314_, r, g, b, x + v314_, y - v314_, z + v314_, r, g, b)
	drawDebugPoint(x, y, z, r, g, b, 1)
end

-- Local values: x, y, z, yx, yy, yz, zx, zy, zz
function DebugUtil.drawDebugReferenceAxisFromNode(node)
	if node ~= nil then
		local v316_, v317_, v318_ = getWorldTranslation(node)
		local v319_, v320_, v321_ = localDirectionToWorld(node, 0, 1, 0)
		local v322_, v323_, v324_ = localDirectionToWorld(node, 0, 0, 1)
		DebugUtil.drawDebugReferenceAxis(v316_, v317_, v318_, v319_, v320_, v321_, v322_, v323_, v324_)
	end
end

-- Local values: sideX, sideY, sideZ, length
function DebugUtil.drawDebugReferenceAxis(posX, posY, posZ, upX, upY, upZ, dirX, dirY, dirZ)
	local v334_, v335_, v336_ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	drawDebugLine(posX - v334_ * 0.2, posY - v335_ * 0.2, posZ - v336_ * 0.2, 1, 1, 1, posX + v334_ * 0.2, posY + v335_ * 0.2, posZ + v336_ * 0.2, 1, 0, 0)
	drawDebugLine(posX - upX * 0.2, posY - upY * 0.2, posZ - upZ * 0.2, 1, 1, 1, posX + upX * 0.2, posY + upY * 0.2, posZ + upZ * 0.2, 0, 1, 0)
	drawDebugLine(posX - dirX * 0.2, posY - dirY * 0.2, posZ - dirZ * 0.2, 1, 1, 1, posX + dirX * 0.2, posY + dirY * 0.2, posZ + dirZ * 0.2, 0, 0, 1)
end

-- Local values: x0, z0, y0, x1, z1, y1, x2, z2, y2, x3, z3, y3
function DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, heightOffset, r, g, b, a, fixedHeight)
	local v349_ = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + heightOffset
	local v350_ = x + widthX
	local v351_ = z + widthZ
	local v352_ = getTerrainHeightAtWorldPos(g_terrainNode, v350_, 0, v351_) + heightOffset
	local v353_ = x + heightX
	local v354_ = z + heightZ
	local v355_ = getTerrainHeightAtWorldPos(g_terrainNode, v353_, 0, v354_) + heightOffset
	local v356_ = x + widthX + heightX
	local v357_ = z + widthZ + heightZ
	local v358_ = getTerrainHeightAtWorldPos(g_terrainNode, v356_, 0, v357_) + heightOffset
	if fixedHeight then
		v355_ = heightOffset
		v358_ = v355_
		v352_ = v358_
		v349_ = v352_
		local v359_ = v355_
		v355_ = v349_
		v359_ = v358_
		v358_ = v355_
		v359_ = v352_
		v352_ = v358_
		v359_ = v349_
	end
	drawDebugTriangle(x, v349_, z, v350_, v352_, v351_, v353_, v355_, v354_, r, g, b, a, false)
	drawDebugTriangle(v350_, v352_, v351_, v356_, v358_, v357_, v353_, v355_, v354_, r, g, b, a, false)
	drawDebugTriangle(x, v349_, z, v353_, v355_, v354_, v350_, v352_, v351_, r, g, b, a, false)
	drawDebugTriangle(v353_, v355_, v354_, v356_, v358_, v357_, v350_, v352_, v351_, r, g, b, a, false)
	drawDebugLine(x, v349_, z, r, g, b, v350_, v352_, v351_, r, g, b)
	drawDebugLine(v350_, v352_, v351_, r, g, b, v353_, v355_, v354_, r, g, b)
	drawDebugLine(v353_, v355_, v354_, r, g, b, x, v349_, z, r, g, b)
	drawDebugLine(v350_, v352_, v351_, r, g, b, v356_, v358_, v357_, r, g, b)
	drawDebugLine(v356_, v358_, v357_, r, g, b, v353_, v355_, v354_, r, g, b)
end

-- Local values: x0, z0, y0, x1, z1, y1, x2, z2, y2, x3, z3, y3
function DebugUtil.drawDebugWorldParallelogram(x, z, widthX, widthZ, heightX, heightZ, heightOffset, r, g, b, a, fixedHeight)
	local v372_ = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + heightOffset
	local v373_ = getTerrainHeightAtWorldPos(g_terrainNode, widthX, 0, widthZ) + heightOffset
	local v374_ = getTerrainHeightAtWorldPos(g_terrainNode, heightX, 0, heightZ) + heightOffset
	local v375_ = x + (widthX - x) + (heightX - x)
	local v376_ = z + (widthZ - z) + (heightZ - z)
	local v377_ = getTerrainHeightAtWorldPos(g_terrainNode, v375_, 0, v376_) + heightOffset
	if fixedHeight then
		v374_ = heightOffset
		v377_ = v374_
		v373_ = v377_
		v372_ = v373_
		local v378_ = v374_
		v374_ = v372_
		v378_ = v377_
		v377_ = v374_
		v378_ = v373_
		v373_ = v377_
		v378_ = v372_
	end
	drawDebugTriangle(x, v372_, z, widthX, v373_, widthZ, heightX, v374_, heightZ, r, g, b, a, false)
	drawDebugTriangle(widthX, v373_, widthZ, v375_, v377_, v376_, heightX, v374_, heightZ, r, g, b, a, false)
	drawDebugTriangle(x, v372_, z, heightX, v374_, heightZ, widthX, v373_, widthZ, r, g, b, a, false)
	drawDebugTriangle(heightX, v374_, heightZ, v375_, v377_, v376_, widthX, v373_, widthZ, r, g, b, a, false)
	drawDebugLine(x, v372_, z, r, g, b, widthX, v373_, widthZ, r, g, b)
	drawDebugLine(widthX, v373_, widthZ, r, g, b, heightX, v374_, heightZ, r, g, b)
	drawDebugLine(heightX, v374_, heightZ, r, g, b, x, v372_, z, r, g, b)
	drawDebugLine(widthX, v373_, widthZ, r, g, b, v375_, v377_, v376_, r, g, b)
	drawDebugLine(v375_, v377_, v376_, r, g, b, heightX, v374_, heightZ, r, g, b)
end

-- Local values: x0, _, z0, x1, _, z1, x2, _, z2, x, z, widthX, widthZ, heightX, heightZ
function DebugUtil.drawArea(area, r, g, b, a)
	local v384_, _, v385_ = getWorldTranslation(area.start)
	local v386_, _, v387_ = getWorldTranslation(area.width)
	local v388_, _, v389_ = getWorldTranslation(area.height)
	local v390_, v391_, v392_, v393_, v394_, v395_ = MathUtil.getXZWidthAndHeight(v384_, v385_, v386_, v387_, v388_, v389_)
	DebugUtil.drawDebugParallelogram(v390_, v391_, v392_, v393_, v394_, v395_, r, g, b, a)
end

-- Local values: x, y, z, x2, y2, z2, x3, y3, z3
function DebugUtil.drawCutNodeArea(node, sizeY, sizeZ, r, g, b)
	if node ~= nil then
		local v402_, v403_, v404_ = getWorldTranslation(node)
		local v405_, v406_, v407_ = localToWorld(node, 0, sizeY or 1, 0)
		local v408_, v409_, v410_ = localToWorld(node, 0, 0, sizeZ or 1)
		DebugUtil.drawDebugAreaRectangle(v402_, v403_, v404_, v405_, v406_, v407_, v408_, v409_, v410_, false, r or 0, g or 1, b or 0)
	end
end

-- Local values: debugString, i, j
function DebugUtil.printTableRecursively(inputTable, inputIndent, depth, maxDepth)
	local v415_ = inputIndent or "  "
	local v416_ = depth or 0
	local v417_ = maxDepth or 3
	if v417_ >= v416_ then
		local v418_ = ""
		for v419_, v420_ in pairs(inputTable) do
			print(v415_ .. tostring(v419_) .. " :: " .. tostring(v420_))
			if type(v420_) == "table" then
				DebugUtil.printTableRecursively(v420_, v415_ .. "    ", v416_ + 1, v417_)
			end
		end
		return v418_
	end
end

-- Local values: string1, i, j, string2
function DebugUtil.debugTableToString(inputTable, inputIndent, depth, maxDepth)
	local v425_ = inputIndent or "  "
	local v426_ = depth or 0
	local v427_ = maxDepth or 2
	if v427_ < v426_ then
		return nil
	end
	local v428_ = ""
	for v429_, v430_ in pairs(inputTable) do
		v428_ = v428_ .. string.format("\n%s %s :: %s", v425_, tostring(v429_), (tostring(v430_)))
		if type(v430_) == "table" then
			local v431_ = DebugUtil.debugTableToString(v430_, v425_ .. "    ", v426_ + 1, v427_)
			if v431_ ~= nil then
				v428_ = v428_ .. v431_
			end
		end
	end
	return v428_
end

-- Local values: i, _, valuePair, offset
function DebugUtil.renderTable(posX, posY, textSize, data, nextColumnOffset)
	setTextColor(1, 1, 1, 1)
	setTextBold(false)
	local v437_ = getCorrectTextSize(textSize)
	local v438_ = 0
	for _, v439_ in ipairs(data) do
		local v440_ = v438_ * v437_ * 1.05
		if v439_.name ~= "" then
			setTextAlignment(RenderText.ALIGN_RIGHT)
			local v441_ = renderText
			local v442_ = posY - v440_
			local v443_ = v439_.name
			v441_(posX, v442_, v437_, tostring(v443_) .. ":")
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v444_ = v439_.value
		if type(v444_) == "number" then
			renderText(posX, posY - v440_, v437_, " " .. string.format("%.4f", v439_.value))
		else
			local v445_ = renderText
			local v446_ = posY - v440_
			local v447_ = v439_.value
			v445_(posX, v446_, v437_, " " .. tostring(v447_))
		end
		v438_ = v438_ + 1
		if v439_.newColumn or v439_.columnOffset then
			posX = posX + (v439_.columnOffset or nextColumnOffset)
			v438_ = 0
		end
	end
end

-- Local values: i
function DebugUtil.printListAsTriples(list)
	for v449_ = 1, #list, 3 do
		log(list[v449_], list[v449_ + 1], list[v449_ + 2])
	end
end

function DebugUtil.renderTextLine(x, y, textSize, text, spacingScalar, isBold, color)
	setTextBold(isBold or false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor((color or Color.PRESETS.WHITE):unpack())
	renderText(x, y, textSize, text)
	return DebugUtil.renderNewLine(y, textSize, spacingScalar)
end

function DebugUtil.renderNewLine(y, textSize, spacingScalar)
	return y - textSize * (spacingScalar or DebugUtil.DEFAULT_RENDERLINE_SCALAR)
end

-- Local values: classText, className, classId, i
function DebugUtil.printNodeHierarchy(node, offset, appendType)
	local v463_ = offset or ""
	if appendType then
		local v464_ = ""
		for v465_, v466_ in pairs(ClassIds) do
			if getHasClassId(node, v466_) then
				v464_ = v464_ .. v465_ .. " | "
			end
		end
		if not string.isNilOrWhitespace(v464_) then
			local v467_ = #v464_ - 3
			v464_ = string.sub(v464_, 1, v467_)
		end
		log(string.format("%s%s (%s)", v463_, getName(node), v464_))
	else
		log(string.format("%s%s", v463_, getName(node)))
	end
	for v468_ = 0, getNumOfChildren(node) - 1 do
		DebugUtil.printNodeHierarchy(getChildAt(node, v468_), v463_ .. " ", appendType)
	end
end
function DebugUtil.printCallingFunctionLocation()
	local v469_, v470_ = debug.info(3, "sl")
	print(string.format("%s, line %d", tostring(v469_), v470_))
end

-- Local values: tableIdHex
function DebugUtil.tableToColor(tbl, alpha)
	local v473_ = tostring(tbl):sub(10)
	local v474_ = Color.new
	local v475_ = v473_:sub(-2)
	local v476_ = (tonumber(v475_, 16) or 255) / 255
	local v477_ = v473_:sub(-4, -3)
	local v478_ = (tonumber(v477_, 16) or 255) / 255
	local v479_ = v473_:sub(-6, -5)
	return v474_(v476_, v478_, (tonumber(v479_, 16) or 255) / 255, alpha or 1)
end

function DebugUtil.getDebugColor(index)
	local v481_ = tonumber(index) or math.random(#DebugUtil.COLORS)
	return DebugUtil.COLORS[(v481_ - 1) % #DebugUtil.COLORS + 1]
end

function DebugUtil.isNodeInCameraRange(node, distance, camera)
	return calcDistanceFrom(node, camera or g_cameraManager:getActiveCamera()) < (distance or math.huge)
end

-- Local values: camX, camY, camZ
function DebugUtil.isPositionInCameraRange(x, y, z, distance, camera)
	if distance == nil then
		return true
	end
	local v490_, v491_, v492_ = getWorldTranslation(camera or g_cameraManager:getActiveCamera())
	return MathUtil.vector3Length(x - v490_, y and y - v491_ or 0, z - v492_) < distance
end

-- Local values: parent
function DebugUtil.setNodeEffectivelyVisible(node)
	setVisibility(node, true)
	local v494_ = getParent(node)
	while v494_ ~= 0 do
		setVisibility(v494_, true)
		v494_ = getParent(v494_)
	end
end

-- Local values: cx, cy, cz, dirX, _, dirZ
function DebugUtil.getYRotatationToCamera(x, y, z)
	local v498_, v499_, v500_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v501_, _, v502_ = MathUtil.vector3Normalize(v498_ - x, v499_ - y, v500_ - z)
	return MathUtil.getYRotationFromDirection(v501_, v502_)
end

function DebugUtil.getLuaMemory(differenceTo)
	collectgarbage("collect")
	return collectgarbage("count") - (differenceTo or 0)
end
