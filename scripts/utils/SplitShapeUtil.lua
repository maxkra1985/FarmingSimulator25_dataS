-- Local values: originalSplitFunc
local originalSplitFunc = splitShape
SplitShapeUtil = {}
SplitShapeUtil.SPLIT_SHAPES = {}
SplitShapeUtil.callbackFunc = nil
SplitShapeUtil.callbackTarget = nil

-- Local values: splitData, target, callbackFunc
function SplitShapeUtil.onSplitShapeCallback(unused, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	local v9_ = SplitShapeUtil.SPLIT_SHAPES
	table.insert(v9_, {
		["shape"] = shape,
		["isBelow"] = isBelow,
		["isAbove"] = isAbove,
		["minY"] = minY,
		["maxY"] = maxY,
		["minZ"] = minZ,
		["maxZ"] = maxZ
	})
	local v10_ = SplitShapeUtil.callbackTarget
	v10_[SplitShapeUtil.callbackFunc](v10_, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
end

-- Upvalues: originalSplitFunc
-- Local values: tx, ty, tz, rx, ry, rz, data, parts
function SplitShapeUtil.splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, callback, target)
	-- upvalues: (copy) originalSplitFunc
	if entityExists(shape) and getHasClassId(shape, ClassIds.MESH_SPLIT_SHAPE) then
		local v25_, v26_, v27_ = getWorldTranslation(shape)
		local v28_, v29_, v30_ = getWorldRotation(shape)
		local v31_ = {
			["shape"] = shape,
			["splitTypeIndex"] = getSplitType(shape),
			["volume"] = getVolume(shape),
			["x"] = v25_,
			["y"] = v26_,
			["z"] = v27_,
			["rx"] = v28_,
			["ry"] = v29_,
			["rz"] = v30_,
			["alreadySplit"] = getIsSplitShapeSplit(shape)
		}
		if target == nil then
			local v32_ = string.split(callback, ".")
			if #v32_ == 2 then
				target = _G[v32_[1]]
				callback = v32_[2]
			end
		end
		SplitShapeUtil.callbackFunc = callback
		SplitShapeUtil.callbackTarget = target
		SplitShapeUtil.SPLIT_SHAPES = {}
		originalSplitFunc(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "onSplitShapeCallback", SplitShapeUtil)
		g_messageCenter:publish(MessageType.SPLIT_SHAPE, v31_, SplitShapeUtil.SPLIT_SHAPES)
	end
end
function _G.splitShape(p33_, p34_, p35_, p36_, p37_, p38_, p39_, p40_, p41_, p42_, p43_, p44_, p45_, p46_)
	SplitShapeUtil.splitShape(p33_, p34_, p35_, p36_, p37_, p38_, p39_, p40_, p41_, p42_, p43_, p44_, p45_, p46_)
end

-- Local values: localX, localY, localZ, cx, cy, cz, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ, lengthBelow, lengthAbove, minMaxY, minMaxZ, centerX, centerY, centerZ, radius
function SplitShapeUtil.getTreeOffsetPosition(shapeId, x, y, z, maxRadius, minLength)
	local v53_, v54_, v55_ = worldToLocal(shapeId, x, y, z)
	local v56_, v57_, v58_ = localToWorld(shapeId, v53_ - maxRadius * 0.5, v54_, v55_ - maxRadius * 0.5)
	local v59_, v60_, v61_ = localDirectionToWorld(shapeId, 0, 1, 0)
	local v62_, v63_, v64_ = localDirectionToWorld(shapeId, 0, 0, 1)
	local v65_, v66_, v67_, v68_ = testSplitShape(shapeId, v56_, v57_, v58_, v59_, v60_, v61_, v62_, v63_, v64_, maxRadius, maxRadius)
	if v65_ == nil then
		return nil
	end
	if minLength ~= nil then
		local v69_, v70_ = getSplitShapePlaneExtents(shapeId, v56_, v57_, v58_, v59_, v60_, v61_)
		if v69_ ~= nil and v69_ < minLength then
			return nil
		end
		if v70_ ~= nil and v70_ < minLength then
			return nil
		end
	end
	local v71_ = (v65_ + v66_) * 0.5
	local v72_ = (v67_ + v68_) * 0.5
	local v73_, v74_, v75_ = localToWorld(shapeId, v53_ - maxRadius * 0.5 + v72_, v54_, v55_ - maxRadius * 0.5 + v71_)
	local v76_ = v66_ - v65_
	local v77_ = v68_ - v67_
	return v73_, v74_, v75_, v59_, v60_, v61_, math.max(v76_, v77_) * 0.5
end

-- Local values: dir2X, dir2Y, dir2Z, rootNode, startNode, endNode, linkNode, tensionBelt, beltShapeId, _, _, wx, wy, wz, rx, ry, rz
function SplitShapeUtil.createTreeBelt(beltData, shapeId, tx, ty, tz, sx, sy, sz, upX, upY, upZ, hookOffset, ignoreYDirection, spacing)
	if beltData ~= nil then
		local v92_, v93_, v94_ = MathUtil.vector3Normalize(sx - tx, sy - ty, sz - tz)
		local v95_ = spacing or 0.0025
		local v96_ = createTransformGroup("rootNode")
		link(getRootNode(), v96_)
		setTranslation(v96_, tx, ty, tz)
		setDirection(v96_, v92_, ignoreYDirection and 0 or v93_, v94_, upX, upY, upZ)
		local v97_ = createTransformGroup("startNode")
		link(v96_, v97_)
		setTranslation(v97_, -v95_ * 0.5, 0, hookOffset)
		setRotation(v97_, -1.5707963267948966, 0, -1.5707963267948966)
		local v98_ = createTransformGroup("endNode")
		link(v97_, v98_)
		setTranslation(v98_, 0, 0, v95_)
		setRotation(v98_, 0, 0, 0)
		local v99_ = createTransformGroup("linkNode")
		link(v97_, v99_)
		setTranslation(v99_, 0, 0, v95_ * 0.5)
		setRotation(v99_, 0, 0, 0)
		local v100_ = TensionBeltGeometryConstructor.new()
		v100_:setWidth(beltData.width)
		v100_:setMaterial(beltData.material.materialId)
		v100_:setUVscale(beltData.material.uvScale)
		v100_:setMaxEdgeLength(0.1)
		v100_:setFixedPoints(v97_, v98_)
		v100_:setGeometryBias(0.005)
		v100_:setLinkNode(v99_)
		v100_:addShape(shapeId, -100, 100, -100, 100)
		local v101_, _, _ = v100_:finalize()
		local v102_, v103_, v104_ = getWorldTranslation(v101_)
		local v105_, v106_, v107_ = getWorldRotation(v101_)
		link(getRootNode(), v101_)
		setWorldTranslation(v101_, v102_, v103_, v104_)
		setWorldRotation(v101_, v105_, v106_, v107_)
		delete(v96_)
		return v101_
	end
	Logging.error("Failed to create tree belt. Missing beltData.")
end

-- Local values: i, ret
function SplitShapeUtil.getSplitShapeId(node)
	if getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
		return node
	end
	for v109_ = 0, getNumOfChildren(node) - 1 do
		local v110_ = SplitShapeUtil.getSplitShapeId(getChildAt(node, v109_))
		if v110_ ~= nil then
			return v110_
		end
	end
	return nil
end
