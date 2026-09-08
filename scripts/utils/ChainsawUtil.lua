ChainsawUtil = {}

-- Local values: splitTypeName, splitType, range, farm, split0, split1, type0, type1, dynamicSplit, isTree, cutTreeCount, treeCuttingsample, sizeX, sizeY, sizeZ, _, _, bvVolume, split0, split1, type0, type1, dynamicSplit, staticSplit, isTree, treeCuttingsample, sizeX, sizeY, sizeZ, _, _, bvVolume, distY, distZ, zx, zy, zz, angle, scale0, scale1, nx2, ny2, nz2, yx2, yy2, yz2, cx, cy, cz, jx, jy, jz, constr, jointIndex, ax, ay, az, cutTreeCount
function ChainsawUtil.cutSplitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, farmId)
	local v14_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(shape))
	local v15_ = v14_ == nil and "" or v14_.name
	if getRigidBodyType(shape) == RigidBodyType.STATIC then
		g_densityMapHeightManager:setCollisionMapAreaDirty(x - 5, z - 5, x + 5, z + 5, true)
		g_currentMission.aiSystem:setAreaDirty(x - 5, x + 5, z - 5, z + 5)
	end
	local v16_ = g_farmManager:getFarmById(farmId)
	if math.abs(ny) < 0.866 then
		ChainsawUtil.curSplitShapes = {}
		g_currentMission:removeKnownSplitShape(shape)
		ChainsawUtil.shapeBeingCut = shape
		ChainsawUtil.fromTree = getRigidBodyType(shape) == RigidBodyType.STATIC
		splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "ChainsawUtil.cutSplitShapeCallback", nil)
		g_treePlantManager:removingSplitShape(shape)
		if #ChainsawUtil.curSplitShapes == 2 then
			local v17_ = ChainsawUtil.curSplitShapes[1]
			local v18_ = ChainsawUtil.curSplitShapes[2]
			local v19_ = getRigidBodyType(v17_.shape)
			local v20_ = getRigidBodyType(v18_.shape)
			local v21_ = nil
			local v22_ = false
			if v19_ == RigidBodyType.STATIC and v20_ == RigidBodyType.DYNAMIC then
				v17_ = v18_
				v22_ = true
			elseif v20_ == RigidBodyType.STATIC and v19_ == RigidBodyType.DYNAMIC then
				v22_ = true
			else
				v17_ = v21_
			end
			if v22_ then
				if v16_ ~= nil then
					local v23_ = v16_.stats:updateStats("cutTreeCount", 1)
					g_achievementManager:tryUnlock("CutTreeFirst", v23_)
					g_achievementManager:tryUnlock("CutTree", v23_)
					if v15_ ~= "" then
						v16_.stats:updateTreeTypesCut(v15_)
					end
				end
				local v24_ = g_currentMission.cuttingSounds.tree
				local v25_, v26_, v27_, _, _ = getSplitShapeStats(v17_.shape)
				local v28_ = v25_ == nil and 0 or v25_ * v26_ * v27_
				if v24_ ~= nil and (v24_.soundNode ~= nil and v28_ > 1) then
					g_soundManager:playSample(v24_)
					setTranslation(v24_.soundNode, x, y, z)
					return
				end
			end
		end
	else
		ChainsawUtil.curSplitShapes = {}
		g_currentMission:removeKnownSplitShape(shape)
		ChainsawUtil.shapeBeingCut = shape
		ChainsawUtil.fromTree = getRigidBodyType(shape) == RigidBodyType.STATIC
		splitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, cutSizeY, cutSizeZ, "ChainsawUtil.cutSplitShapeCallback", nil)
		g_treePlantManager:removingSplitShape(shape)
		if #ChainsawUtil.curSplitShapes == 2 then
			local v29_ = ChainsawUtil.curSplitShapes[1]
			local v30_ = ChainsawUtil.curSplitShapes[2]
			local v31_ = getRigidBodyType(v29_.shape)
			local v32_ = getRigidBodyType(v30_.shape)
			local v33_ = nil
			local v34_ = nil
			local v35_ = false
			if v31_ == RigidBodyType.STATIC and v32_ == RigidBodyType.DYNAMIC then
				local v36_ = v29_
				v29_ = v30_
				v30_ = v36_
				v35_ = true
			elseif v32_ == RigidBodyType.STATIC and v31_ == RigidBodyType.DYNAMIC then
				v35_ = true
			else
				v29_ = v33_
				v30_ = v34_
			end
			if v35_ then
				local v37_ = g_currentMission.cuttingSounds.tree
				local v38_, v39_, v40_, _, _ = getSplitShapeStats(v29_.shape)
				local v41_ = v38_ == nil and 0 or v38_ * v39_ * v40_
				if v37_ ~= nil and (v37_.soundNode ~= nil and v41_ > 1) then
					g_soundManager:playSample(v37_)
					setTranslation(v37_.soundNode, x, y, z)
				end
			end
			if v29_ ~= nil then
				local v42_ = v29_.minY + (v29_.maxY - v29_.minY) * 0.75
				local v43_ = (v29_.minZ + v29_.maxZ) * 0.5
				local v44_, v45_, v46_ = MathUtil.crossProduct(nx, ny, nz, yx, yy, yz)
				local v47_ = 0.6427876096865393
				if v29_.isBelow then
					v47_ = -v47_
				end
				local v48_ = nx * 0.7659825218948272 + yx * v47_
				local v49_ = ny * 0.7659825218948272 + yy * v47_
				local v50_ = nz * 0.7659825218948272 + yz * v47_
				local v51_, v52_, v53_ = MathUtil.crossProduct(v44_, v45_, v46_, v48_, v49_, v50_)
				local v54_ = x + yx * v42_ - v51_ * cutSizeY * 0.1
				local v55_ = y + yy * v42_ - v52_ * cutSizeY * 0.1
				local v56_ = z + yz * v42_ - v53_ * cutSizeY * 0.1
				g_currentMission:removeKnownSplitShape(v30_.shape)
				ChainsawUtil.shapeBeingCut = v30_.shape
				splitShape(v30_.shape, v54_, v55_, v56_, v48_, v49_, v50_, v51_, v52_, v53_, cutSizeY * 1.1, cutSizeZ, "ChainsawUtil.cutSplitShapeCallbackCutJoint", nil)
				g_treePlantManager:removingSplitShape(v30_.shape)
				local v57_ = x + yx * v42_ + v44_ * v43_
				local v58_ = y + yy * v42_ + v45_ * v43_
				local v59_ = z + yz * v42_ + v46_ * v43_
				local v60_ = JointConstructor.new()
				v60_:setActors(0, v29_.shape)
				v60_:setJointWorldAxes(nx, ny, nz, nx, ny, nz)
				v60_:setJointWorldNormals(yx, yy, yz, yx, yy, yz)
				v60_:setJointWorldPositions(v57_, v58_, v59_, v57_, v58_, v59_)
				v60_:setRotationLimit(0, 0, 0)
				v60_:setTranslationLimit(0, false, 0, 0)
				v60_:setEnableCollision(true)
				local v61_ = v60_:finalize()
				local v62_, v63_, v64_ = MathUtil.crossProduct(0, 0.8, 0, yx, yy, yz)
				setAngularVelocity(v29_.shape, v62_, v63_, v64_)
				g_treePlantManager:addTreeCutJoint(v61_, v29_.shape, nx, ny, nz, 0.7853981633974483, 2000)
				if v16_ ~= nil then
					local v65_ = v16_.stats:updateStats("cutTreeCount", 1)
					g_achievementManager:tryUnlock("CutTreeFirst", v65_)
					g_achievementManager:tryUnlock("CutTree", v65_)
					if v15_ ~= "" then
						v16_.stats:updateTreeTypesCut(v15_)
					end
				end
			end
		end
	end
end

function ChainsawUtil.cutSplitShapeCallback(unused, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	g_currentMission:addKnownSplitShape(shape)
	g_treePlantManager:addingSplitShape(shape, ChainsawUtil.shapeBeingCut, ChainsawUtil.fromTree)
	local v73_ = ChainsawUtil.curSplitShapes
	table.insert(v73_, {
		["shape"] = shape,
		["isBelow"] = isBelow,
		["isAbove"] = isAbove,
		["minY"] = minY,
		["maxY"] = maxY,
		["minZ"] = minZ,
		["maxZ"] = maxZ
	})
end

function ChainsawUtil.cutSplitShapeCallbackCutJoint(unused, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
	g_currentMission:addKnownSplitShape(shape)
	g_treePlantManager:addingSplitShape(shape, ChainsawUtil.shapeBeingCut, true)
end
