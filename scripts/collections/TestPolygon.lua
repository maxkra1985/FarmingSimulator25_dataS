TestPolygon = {}
function TestPolygon.init()
	local v1_ = TestPolygon
	setEnablePostFx(false)
	v1_.camera = createCamera("Test", 1.2217304763960306, 0.001, 1000)
	g_cameraManager:addCamera(v1_.camera, nil, false)
	link(getRootNode(), v1_.camera)
	g_cameraManager:setActiveCamera(v1_.camera)
	setTranslation(v1_.camera, 0, 2, 0)
	setRotation(v1_.camera, -1.5707963267948966, 0, 0)
	v1_.debugPolygon = DebugPolygon.new()
	v1_.debugPoint = DebugPoint.new()
	v1_.debugCircle = DebugCircle.new()
	v1_.generatePolygon()
end
function TestPolygon.generatePolygon()
	local v2_ = TestPolygon
	g_debugManager:removeGroup("default")
	local v3_ = {
		math.random(),
		0,
		math.random(),
		math.random(),
		0,
		-math.random(),
		-math.random(),
		0,
		-math.random(),
		-math.random(),
		0,
		math.random(),
		math.random(),
		0,
		math.random()
	}
	v2_.debugPolygon:create(v3_):setColor(Color.new(1, 1, 1, 0.2)):addToManager()
	v2_.polygon = Polygon2D.new()
	v2_.polygon:setVerticesFromXYZ(v3_)
	local v4_, v5_, v6_, v7_ = v2_.polygon:getBoundingBox()
	local v8_ = v2_.polygon:getConvexHull()
	v2_.hullVis = DebugPath.new()
	for v9_ = 1, #v8_ - 1, 2 do
		DebugPoint.new():createWithWorldPos(v8_[v9_], 0, v8_[v9_ + 1]):setColor(Color.PRESETS.YELLOW):addToManager()
		v2_.hullVis:addPoint(v8_[v9_], 0, v8_[v9_ + 1])
	end
	v2_.hullVis:addPoint(v8_[1], 0, v8_[2])
	v2_.hullVis:setColor(Color.new(0, 0, 1, 0.2)):addToManager()
	local v10_ = MathUtil.randomFloat(v4_ * 1.1, v5_ * 1.1)
	local v11_ = MathUtil.randomFloat(v6_ * 1.1, v7_ * 1.1)
	v2_.pointX = v10_
	v2_.pointZ = v11_
	v2_.debugPoint:createWithWorldPos(v2_.pointX, 0.03, v2_.pointZ):setColor(Color.PRESETS.BLUE):addToManager()
	if v2_.polygon:getIsPosInside(v2_.pointX, v2_.pointZ) then
		v2_.debugPoint:setColor(Color.PRESETS.GREEN)
	else
		v2_.debugPoint:setColor(Color.PRESETS.RED)
	end
	local v12_ = MathUtil.randomFloat(0, v5_ * 0.9)
	local v13_ = math.abs(v12_)
	v2_.debugCircle:createWithWorldPos(v2_.pointX, 0.03, v2_.pointZ, v13_):addToManager()
	if v2_.polygon:getIsCircleIntersecting(v2_.pointX, v2_.pointZ, v13_) then
		v2_.debugCircle:setColor(Color.PRESETS.GREEN)
	else
		v2_.debugCircle:setColor(Color.PRESETS.RED)
	end
	if v2_.polygon:getIsCircleInside(v2_.pointX, v2_.pointZ, v13_) then
		DebugText.new():createWithWorldPos(v2_.pointX + 0.1, 0, v2_.pointZ, "inside"):addToManager()
	end
	local v14_ = MathUtil.randomFloat(0, v5_ * 2)
	local v15_ = MathUtil.randomFloat(0, v5_ * 2)
	local v16_ = MathUtil.randomFloat(0, v5_ * 2)
	local v17_ = MathUtil.randomFloat(0, v5_ * 2)
	DebugLine.new():createWithStartAndEndPos(v14_, 0.03, v15_, v16_, 0.03, v17_):setColor(v2_.polygon:getIsLineSegmentIntersecting(v14_, v15_, v16_, v17_) and Color.PRESETS.RED or Color.PRESETS.GREEN):addToManager()
end

-- Local values: self
function TestPolygon.update(dt)
	local v18_ = TestPolygon
	if g_updateLoopIndex % 300 == 0 then
		v18_.generatePolygon()
	end
end
function TestPolygon.draw()
	g_debugManager:drawPreUI()
	g_debugManager:drawPostUI()
end

function TestPolygon.mouseEvent(posX, posY, isDown, isUp, button) end

function TestPolygon.keyEvent(unicode, sym, modifier, isDown) end
