TestDebugElements = {}
function TestDebugElements.init()
	local v_u_1_ = TestDebugElements
	setEnablePostFx(false)
	executeConsoleCommand("enableNoteRendering true", true)
	v_u_1_.cameraRotCenter = createTransformGroup("cameraRotCenter")
	link(getRootNode(), v_u_1_.cameraRotCenter)
	v_u_1_.camera = createCamera("Test", 1.2217304763960306, 0.001, 1000)
	g_cameraManager:addCamera(v_u_1_.camera, nil, false)
	link(v_u_1_.cameraRotCenter, v_u_1_.camera)
	g_cameraManager:setActiveCamera(v_u_1_.camera)
	setTranslation(v_u_1_.camera, 0, 5, 10)
	setRotation(v_u_1_.camera, -0.5235987755982988, 0, 0)
	v_u_1_.bitVectorMap = createBitVectorMap("bitVectorMapDebugElementsTest")
	loadBitVectorMapNew(v_u_1_.bitVectorMap, 16, 16, 2, false)
	v_u_1_.debugBitVectorMap = DebugBitVectorMap.newSimple(20, 1, false, 0.2)
	v_u_1_.debugBitVectorMap:createWithCustomFunc(function(_, p2_, p3_, _, _, _, _)
		-- upvalues: (copy) v_u_1_
		if p2_ >= 0 and p3_ >= 0 then
			return getBitVectorMapPoint(v_u_1_.bitVectorMap, p2_, p3_, 0, 2)
		end
	end)
	g_debugManager:addElement(v_u_1_.debugBitVectorMap)
	v_u_1_.node = createTransformGroup("debugCubeTest")
	link(getRootNode(), v_u_1_.node)
	setRotation(v_u_1_.node, 0, 3.839724354387525, 0)
	v_u_1_.debugCube = DebugBox.new():setDrawFaces(true):setColorRGBA(0, 0, 1):setText("CubeInstance")
	g_debugManager:addElement(v_u_1_.debugCube)
	v_u_1_.node2 = createTransformGroup("debugCubeTest")
	link(getRootNode(), v_u_1_.node2)
	setTranslation(v_u_1_.node2, -2, 0, 0)
	setRotation(v_u_1_.node2, 0, 3.839724354387525, 0)
	v_u_1_.node3 = createTransformGroup("debugCubeTest")
	link(getRootNode(), v_u_1_.node3)
	setTranslation(v_u_1_.node3, -4, 2, 0)
	v_u_1_.node4 = createTransformGroup("debugCubeTest")
	link(getRootNode(), v_u_1_.node4)
	setTranslation(v_u_1_.node4, 0, 2, 0)
	v_u_1_.node5 = createTransformGroup("debugFlagTest")
	link(getRootNode(), v_u_1_.node5)
	setTranslation(v_u_1_.node5, 5, -1, -4)
	v_u_1_.debugPath = DebugPath.newSimple(DebugUtil.getDebugColor(math.random(10)), false, nil, false):setText("debugPath instance")
	for v4_ = 1, 10 do
		v_u_1_.debugPath:addPoint(v4_ / 2, math.random(), -v4_ * 2 + math.random())
	end
	g_debugManager:addElement(v_u_1_.debugPath)
	g_debugManager:addElement(DebugText.new():createWithNode(v_u_1_.node4, "DebugText", 0.02))
	g_debugManager:addElement(DebugLine.new():createWithStartAndEndPos(8, -2, 3, 15, 4, 5):setColors(Color.PRESETS.RED, Color.PRESETS.BLUE))
	v_u_1_.debugFunc = DebugFunction.new(function(p5_, p6_)
		p5_.dt = p5_.dt + p6_
	end, function(p7_)
		renderText(0.9, 0.14, 0.02, "DebugFunc")
		local v8_ = renderText
		local v9_ = getTime
		v8_(0.9, 0.11, 0.02, (tostring(v9_())))
		local v10_ = renderText
		local v11_ = g_updateLoopIndex
		v10_(0.9, 0.08, 0.02, (tostring(v11_)))
		renderText(0.9, 0.05, 0.02, string.format("%.5f", p7_.dt))
		setNoteNodeText(p7_.noteNode, string.format("%d", p7_.dt / 1000))
	end, function(p12_)
		p12_.dt = 0
		p12_.noteNode = createNoteNode(nil, "noteNode bla bla", 0, 0.3, 0, true)
		link(getRootNode(), p12_.noteNode)
		setTranslation(p12_.noteNode, 0, 3, 0)
	end, function(p13_)
		delete(p13_.noteNode)
	end)
	g_debugManager:addElement(v_u_1_.debugFunc)
	v_u_1_.spline = createSplineFromEditPoints(getRootNode(), {
		-6,
		0,
		5,
		5,
		1,
		5,
		5,
		1,
		-5,
		-5,
		0,
		-4.9
	}, false, false)
	setName(v_u_1_.spline, "spline, instance")
	v_u_1_.debugSpline = DebugSpline.new():createWithNode(v_u_1_.spline, nil, 10, true)
	g_debugManager:addElement(v_u_1_.debugSpline)
	v_u_1_.splineStatic = createSplineFromEditPoints(getRootNode(), {
		-8,
		0,
		5,
		-12,
		3,
		7,
		-15,
		0,
		10
	}, false, true)
	setName(v_u_1_.splineStatic, "spline, static")
	v_u_1_.splineBVTest = createSplineFromEditPoints(getRootNode(), {
		-7,
		0,
		2,
		-5,
		0,
		2
	}, false, false)
	g_debugManager:addElement(DebugSphere.new():createShapeBoundingSphere(v_u_1_.splineBVTest))
	g_debugManager:addElement(DebugPlane.newSimple(false, false, Color.PRESETS.LIMEGREEN, true):createWithPositions(-3, 0, 2, -2, 0.5, 3, -3, 0.5, 4))
	g_debugManager:addElement(DebugPlane.newSimple(false, false, Color.PRESETS.ORANGE, true):createWithPositionsOffset(-4, -2, 2, 2, 0, 1, 1, 0, 2))
	v_u_1_.node6 = createTransformGroup("debugFlagTest2")
	link(getRootNode(), v_u_1_.node6)
	setTranslation(v_u_1_.node6, 7, -1, 8)
	setRotation(v_u_1_.node6, 0, math.random(0, 6.283185307179586), 0)
	g_debugManager:addElement(DebugFlag.new():createWithNode(v_u_1_.node6))
	g_debugManager:addElement(DebugGizmo.new():createWithNode(v_u_1_.node6))
	v_u_1_.debugCylinder = DebugCylinder.new():createWithWorldPos(4, 0, -3, 0.5, 2, Axis.Y):setColorRGBA(1, 1, 0):setText("CylinderInstance")
	g_debugManager:addElement(v_u_1_.debugCylinder)
	v_u_1_.debugPyramid = DebugPyramid.new():setColorRGBA(1, 0, 1):setText("PyramidInstance"):setDrawFaces(true)
	local v14_ = v_u_1_.debugPyramid
	local v15_ = v_u_1_.debugPyramid
	local v16_ = v_u_1_.debugPyramid
	v14_.x = -2
	v15_.y = 1
	v16_.z = 6
	g_debugManager:addElement(v_u_1_.debugPyramid)
	v_u_1_.debugCamera = DebugCamera.new():setColorRGBA(0, 1, 1):setText("CameraInstance")
	local v17_ = v_u_1_.debugCamera
	local v18_ = v_u_1_.debugCamera
	local v19_ = v_u_1_.debugCamera
	v17_.x = 8
	v18_.y = 1
	v19_.z = 0
	g_debugManager:addElement(v_u_1_.debugCamera)
end

-- Local values: self, i, sx, sz, value, i
function TestDebugElements.update(dt)
	local v21_ = TestDebugElements
	g_debugManager:update(dt)
	rotate(v21_.cameraRotCenter, 0, 0.003, 0)
	v21_.debugCube:createWithNode(v21_.node)
	rotate(v21_.node, 0.004, 0.005, 0.006)
	rotate(v21_.node5, 0, -0.01, 0)
	if math.random() < 0.1 then
		v21_.debugCube:setColor(DebugUtil.getDebugColor(math.random(10)))
	end
	if g_updateLoopIndex % 40 == 0 then
		for _ = 0, 5 do
			local v22_ = math.random(0, 8) * 2
			local v23_ = math.random(0, 8) * 2
			local v24_ = math.random(0, 2)
			setBitVectorMapParallelogram(v21_.bitVectorMap, v22_, v23_, 1.5, 0, 0, 1.5, 0, 2, v24_)
		end
	end
	local v25_ = v21_.debugCube
	local v26_ = g_time / 1000
	local v27_ = 1.1 + math.sin(v26_)
	local v28_ = (g_time + 500) / 1000
	v25_:setSize(1, v27_, 1.1 + math.cos(v28_))
	local v29_ = v21_.debugPath
	local v30_ = g_time / 1000
	v29_:setClipDistance(6 + (1 + math.sin(v30_) / 2) * 20)
	if math.random() < 0.005 then
		v21_.debugPath:clear()
		for v31_ = 1, 10 do
			v21_.debugPath:addPoint(v31_ / 2, math.random(), -v31_ * 2 + math.random())
		end
	end
	if v21_.debugFunc ~= nil and g_time > 30000 then
		g_debugManager:removeElement(v21_.debugFunc)
		v21_.debugFunc = nil
	end
end
function TestDebugElements.draw()
	local v32_ = TestDebugElements
	g_debugManager:drawPreUI()
	DebugBox.renderAtPosition(-5.5, -2, -1, 0, 1, 0, 0, 0, 1, 0.5, 2, 0.2, Color.PRESETS.RED, false, "staticCall 1", nil, false)
	DebugBox.renderAtPosition(3.5, 1, 1, 0, 1, 0, 0, 0, 1, 0.5, 2, 0.2, Color.PRESETS.GREEN, false, "staticCall\n2", nil, true)
	DebugBox.renderWithStartAndEndNode(v32_.node2, v32_.node4, Color.PRESETS.LIGHTGRAY, false, "BoxStartAndEndNode", nil, true)
	DebugCircle.renderAtPosition(1, -2, 2, 3, Color.PRESETS.DARKORANGE, nil, nil, nil, true, "a Kreis, Hann")
	DebugCircle.renderAtPosition(-4, -3, 4, 2, Color.PRESETS.OLIVE, nil, nil, nil, false)
	DebugCircle.renderAtPosition(-5, -3, 0, 1.5, Color.PRESETS.BLUE)
	DebugPlane.renderWithPositions(-5, 0, -2, -7, 0, -3, -5, 0, -5, Color.PRESETS.DARKMAGENTA, false, true, true, false, "plane")
	v32_.debugPathPoints = v32_.debugPathPoints or {
		{ -3, -2, 0 },
		{ 3, -1, 1 },
		{ 5, -2, 0 },
		{ 2, -2, 0 },
		{ 2, -2, -20 },
		{ 3, 5, -22 }
	}
	DebugPath.renderPath(v32_.debugPathPoints, nil, false, nil, false, 12)
	DebugFlag.renderAtPosition(-7, -2, -8, 0.5, 0, Color.PRESETS.LIGHTGREEN, "Flag\nText")
	DebugPoint.renderAtPosition(5, 3, 4, Color.PRESETS.DARKRED, true, "DebugPoint")
	DebugLine.renderBetweenNodes(v32_.node2, v32_.node3, Color.PRESETS.MAGENTA, false, "debugLine\nnodeToNode")
	v32_.debugInfoTableData = v32_.debugInfoTableData or {
		{
			["title"] = "Title 1",
			["content"] = {
				{
					["name"] = "T1V1",
					["value"] = 0.5
				}
			}
		},
		{
			["title"] = "Title 2",
			["content"] = {
				{
					["name"] = "T2V1",
					["value"] = "bla bla bla"
				},
				{
					["name"] = "T2V2 long name",
					["value"] = "Hansi with custom color",
					["color"] = Color.new(1, 0, 0, 0.1)
				},
				{
					["name"] = "T2V3 size factor",
					["value"] = "Jochen with custom size",
					["sizeFactor"] = 0.7
				}
			}
		}
	}
	DebugInfoTable.renderAtPosition(-7, 1, -3, v32_.debugInfoTableData, nil, nil, nil, 0.3, Color.PRESETS.INDIGO)
	DebugSphere.renderAtPosition(-5, 0, 5, 1.5, Color.PRESETS.GREEN, nil, nil, nil, "sphere")
	DebugGizmo.renderAtPosition(2, 3, 4, 0, 1, 0, 0.5, 0, 0.5, "Gizmo static", false, nil, nil, Color.PRESETS.CYAN, nil)
	DebugSpline.renderForNode(v32_.splineStatic, Color.PRESETS.BROWN, "static spline", 15, true)
	DebugFlag.renderAtNode(v32_.node5, nil, nil, Color.PRESETS.FIREBRICK, "flag at node")
	if v32_.debugPolygonVertices == nil then
		v32_.debugPolygonVertices = {
			1,
			0,
			0,
			0.5,
			0,
			-0.8660254037844386,
			-0.5,
			0,
			-0.8660254037844386,
			-1,
			0,
			0,
			-0.5,
			0,
			0.8660254037844386,
			0.5,
			0,
			0.8660254037844386
		}
		for v33_ = 1, #v32_.debugPolygonVertices, 3 do
			v32_.debugPolygonVertices[v33_] = v32_.debugPolygonVertices[v33_] - 3
			v32_.debugPolygonVertices[v33_ + 2] = v32_.debugPolygonVertices[v33_ + 2] - 4
		end
	end
	DebugPolygon.renderWithPositions(v32_.debugPolygonVertices, Color.PRESETS.LAVENDER, true)
	DebugCylinder.renderAtPosition(-3, -2, -7, 0.5, 2, Axis.Y, Color.PRESETS.OLIVE, nil, false, false, "CylinderStatic")
	DebugPyramid.renderAtPosition(6, -1, -5, 0, 1, 0, 0, 0, 1, 1, 1.5, 1, Color.PRESETS.LAVENDER, false, "Pyramid\nstatic", nil, true)
	DebugCamera.renderAtPosition(8, 3, -2, 0, 1, 0, 0, 0, 1, 1, 1, 1, Color.PRESETS.CYAN, false, "Camera\nstatic", nil, false)
	g_debugManager:drawPostUI()
end

function TestDebugElements.mouseEvent(posX, posY, isDown, isUp, button) end

function TestDebugElements.keyEvent(unicode, sym, modifier, isDown) end
