IKUtil = {}

-- Local values: ikChain, numNodeElements, j, nodeKey, node, minRx, maxRx, minRy, maxRy, minRz, maxRz, damping, localLimits, initTranslation, numPoseElements, j, poseKey, id, pose, i, node
function IKUtil.loadIKChain(xmlFile, key, targetBasenode, chainBasenode, ikTable)
	local v6_ = {
		["id"] = getXMLString(xmlFile, key .. "#id"),
		["target"] = I3DUtil.indexToObject(targetBasenode, getXMLString(xmlFile, key .. "#target")),
		["targetOffset"] = string.getVector(getXMLString(xmlFile, key .. "#targetOffset"), 3)
	}
	if v6_.targetOffset == nil then
		v6_.targetOffset = { 0, 0, 0 }
	end
	v6_.targetRotationOffset = string.getVector(getXMLString(xmlFile, key .. "#targetRotationOffset"), 3)
	if v6_.targetRotationOffset == nil then
		v6_.targetRotationOffset = { 0, 0, 0 }
	else
		local v7_ = v6_.targetRotationOffset
		local v8_ = v6_.targetRotationOffset[1]
		v7_[1] = math.rad(v8_)
		local v9_ = v6_.targetRotationOffset
		local v10_ = v6_.targetRotationOffset[2]
		v9_[2] = math.rad(v10_)
		local v11_ = v6_.targetRotationOffset
		local v12_ = v6_.targetRotationOffset[3]
		v11_[3] = math.rad(v12_)
	end
	v6_.alignToTarget = Utils.getNoNil(getXMLBool(xmlFile, key .. "#alignToTarget"), false)
	local v13_ = getXMLNumOfElements(xmlFile, key .. ".node")
	v6_.nodes = table.create(v13_)
	for v14_ = 1, v13_ do
		local v15_ = key .. string.format(".node(%d)", v14_ - 1)
		local v16_ = I3DUtil.indexToObject(chainBasenode, getXMLString(xmlFile, v15_ .. "#index"))
		if v16_ ~= nil then
			local v17_ = getXMLFloat(xmlFile, v15_ .. "#minRx") or -180
			local v18_ = math.rad(v17_)
			local v19_ = getXMLFloat(xmlFile, v15_ .. "#maxRx") or 180
			local v20_ = math.rad(v19_)
			local v21_ = getXMLFloat(xmlFile, v15_ .. "#minRy") or -180
			local v22_ = math.rad(v21_)
			local v23_ = getXMLFloat(xmlFile, v15_ .. "#maxRy") or 180
			local v24_ = math.rad(v23_)
			local v25_ = getXMLFloat(xmlFile, v15_ .. "#minRz") or -180
			local v26_ = math.rad(v25_)
			local v27_ = getXMLFloat(xmlFile, v15_ .. "#maxRz") or 180
			local v28_ = math.rad(v27_)
			local v29_ = getXMLFloat(xmlFile, v15_ .. "#damping") or 30
			local v30_ = math.rad(v29_)
			local v31_ = Utils.getNoNil(getXMLBool(xmlFile, v15_ .. "#localLimits"), false)
			local v32_ = v14_ == v13_ and { getTranslation(v16_) } or nil
			local v33_ = v6_.nodes
			table.insert(v33_, {
				["node"] = v16_,
				["minRx"] = v18_,
				["maxRx"] = v20_,
				["minRy"] = v22_,
				["maxRy"] = v24_,
				["minRz"] = v26_,
				["maxRz"] = v28_,
				["damping"] = v30_,
				["localLimits"] = v31_,
				["initTranslation"] = v32_
			})
		end
	end
	v6_.rotationNodes = IKUtil.loadRotationNodes(xmlFile, key, chainBasenode, true)
	local v34_ = getXMLNumOfElements(xmlFile, key .. ".pose")
	if v34_ > 0 then
		v6_.poses = {}
		for v35_ = 0, v34_ - 1 do
			local v36_ = key .. string.format(".pose(%d)", v35_)
			local v37_ = getXMLString(xmlFile, v36_ .. "#id")
			if v37_ ~= nil then
				local v38_ = {
					["id"] = v37_,
					["isDefaultPose"] = Utils.getNoNil(getXMLBool(xmlFile, v36_ .. "#isDefaultPose"), false)
				}
				v38_.rotationNodes = IKUtil.loadRotationNodes(xmlFile, v36_, chainBasenode, v38_.isDefaultPose)
				v6_.poses[v37_] = v38_
			end
		end
	end
	if #v6_.nodes <= 0 or (v6_.target == nil or (v6_.id == nil or ikTable[v6_.id] ~= nil)) then
		return nil
	end
	v6_.numIterations = getXMLInt(xmlFile, key .. "#numIterations") or 20
	v6_.numIterationsToApply = getXMLInt(xmlFile, key .. "#numIterationsInit") or v6_.numIterations * 2
	v6_.positionThreshold = getXMLFloat(xmlFile, key .. "#positionThreshold") or 0.005
	v6_.isDirty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isDirtyOnLoad"), false)
	v6_.ikChainSolver = IKChain.new(#v6_.nodes)
	for v39_, v40_ in ipairs(v6_.nodes) do
		v6_.ikChainSolver:setJointTransformGroup(v39_ - 1, v40_.node, v40_.minRx, v40_.maxRx, v40_.minRy, v40_.maxRy, v40_.minRz, v40_.maxRz, v40_.damping, v40_.localLimits)
	end
	v6_.isActive = true
	ikTable[v6_.id] = v6_
	return v6_
end

-- Local values: numRotatioNodes, rotationNodes, i, nodeKey, node, rotConfig, rot
function IKUtil.loadRotationNodes(xmlFile, key, chainBasenode, apply)
	local v45_ = getXMLNumOfElements(xmlFile, key .. ".rotationNode")
	if v45_ == 0 then
		return nil
	end
	local v46_ = {}
	for v47_ = 0, v45_ - 1 do
		local v48_ = key .. string.format(".rotationNode(%d)", v47_)
		local v49_ = I3DUtil.indexToObject(chainBasenode, getXMLString(xmlFile, v48_ .. "#index"))
		if v49_ ~= nil then
			local v50_ = string.getRadians(getXMLString(xmlFile, v48_ .. "#rotation"), 3)
			local v51_ = v50_ or { getRotation(v49_) }
			if apply and v50_ ~= nil then
				setRotation(v49_, unpack(v50_))
			end
			table.insert(v46_, {
				["node"] = v49_,
				["defaultRotation"] = v51_
			})
		end
	end
	return v46_
end

-- Local values: _, rotationNode
function IKUtil.setRotationNodes(rotationNodes)
	for _, v53_ in pairs(rotationNodes) do
		local v54_ = setRotation
		local v55_ = v53_.node
		local v56_ = v53_.defaultRotation
		v54_(v55_, unpack(v56_))
	end
end

-- Local values: ikChain
function IKUtil.deleteIKChain(ikTable, id)
	local v59_ = ikTable[id]
	if v59_ ~= nil then
		v59_.ikChainSolver = nil
	end
	ikTable[id] = nil
end

-- Local values: ikChain, x, y, z, _, rotationNode, rotNode
function IKUtil.setTarget(ikTable, id, target)
	local v63_ = ikTable[id]
	if v63_ ~= nil then
		if target == nil then
			if v63_.defaultTarget ~= nil then
				v63_.target = v63_.defaultTarget
				if v63_.rotationNodes ~= nil then
					IKUtil.setRotationNodes(v63_.rotationNodes)
				end
			end
			if v63_.offsetTargetNode ~= nil then
				delete(v63_.offsetTargetNode)
				v63_.offsetTargetNode = nil
			end
		else
			if v63_.defaultTarget == nil then
				v63_.defaultTarget = v63_.target
			end
			v63_.offsetTargetNode = createTransformGroup("ikOffsetTargetNode")
			link(target.targetNode, v63_.offsetTargetNode)
			if v63_.targetRotationOffset ~= nil then
				setRotation(v63_.offsetTargetNode, v63_.targetRotationOffset[1], v63_.targetRotationOffset[2], v63_.targetRotationOffset[3])
			end
			if v63_.targetOffset ~= nil then
				local v64_, v65_, v66_ = localToLocal(v63_.offsetTargetNode, getParent(v63_.offsetTargetNode), v63_.targetOffset[1], v63_.targetOffset[2], v63_.targetOffset[3])
				setTranslation(v63_.offsetTargetNode, v64_, v65_, v66_)
			end
			v63_.target = v63_.offsetTargetNode
			v63_.actualTargetNode = target.targetNode
			if target.rotationNodes ~= nil and v63_.rotationNodes ~= nil then
				for _, v67_ in pairs(target.rotationNodes) do
					local v68_ = v63_.rotationNodes[v67_.id]
					if v68_ ~= nil then
						local v69_ = setRotation
						local v70_ = v68_.node
						local v71_ = v67_.rotation
						v69_(v70_, unpack(v71_))
					end
				end
			end
			if target.poseId ~= nil then
				IKUtil.setIKChainPose(ikTable, id, target.poseId)
				return
			end
		end
	end
end

-- Local values: _, ikChain
function IKUtil.updateIKChains(ikChains, translateAlignNodes)
	for _, v74_ in pairs(ikChains) do
		if v74_.isDirty and v74_.isActive then
			v74_.isDirty = false
			IKUtil.updateIKChain(v74_, v74_.numIterationsToApply, v74_.positionThreshold, translateAlignNodes)
			v74_.numIterationsToApply = v74_.numIterations
		end
	end
	if VehicleDebug ~= nil and VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		IKUtil.debugDrawChains(ikChains, true)
	end
end

-- Local values: _, ikChain
function IKUtil.debugDrawChains(ikChains, drawLimits)
	for _, v77_ in pairs(ikChains) do
		if v77_.isActive then
			IKUtil.debugDrawChain(v77_, drawLimits)
		end
	end
end

-- Local values: x1, y1, z1, x2, y2, z2, x, y, z, dx, dy, dz, upX, upY, upZ
function IKUtil.debugDrawChain(ikChain, drawLimits)
	local v80_ = drawLimits == nil and true or drawLimits
	ikChain.ikChainSolver:debugDraw(v80_)
	local v81_, v82_, v83_ = getWorldTranslation(ikChain.nodes[1].node)
	local v84_, v85_, v86_ = getWorldTranslation(ikChain.target)
	drawDebugLine(v81_, v82_, v83_, 0, 1, 0, v84_, v85_, v86_, 0, 1, 0)
	DebugGizmo.renderAtNode(ikChain.target, getName(ikChain.target), false, 0.1, false)
	local v87_, v88_, v89_ = localToWorld(ikChain.target, 0, 0, 0)
	local v90_, v91_, v92_ = localDirectionToWorld(ikChain.target, 0, 0, 1)
	local v93_, v94_, v95_ = localDirectionToWorld(ikChain.target, 0, 1, 0)
	DebugGizmo.renderAtPosition(v87_, v88_, v89_, v90_, v91_, v92_, v93_, v94_, v95_, "", false, 0.1, nil, Color.PRESETS.RED)
end

-- Local values: x, y, z, alignNodeData, alignNode
function IKUtil.updateIKChain(ikChain, numIterations, positionThreshold, translateAlignNode)
	local v100_, v101_, v102_ = getWorldTranslation(ikChain.target)
	if ikChain.alignToTarget then
		local v103_ = ikChain.nodes[#ikChain.nodes]
		local v104_ = setTranslation
		local v105_ = v103_.node
		local v106_ = v103_.initTranslation
		v104_(v105_, unpack(v106_))
	end
	ikChain.ikChainSolver:solve(v100_, v101_, v102_, numIterations, positionThreshold)
	if ikChain.alignToTarget and ikChain.isActive then
		local v107_ = ikChain.nodes[#ikChain.nodes].node
		if translateAlignNode then
			setWorldTranslation(v107_, getWorldTranslation(ikChain.target))
		end
		setWorldRotation(v107_, getWorldRotation(ikChain.target))
	end
end

-- Local values: ikChain
function IKUtil.setIKChainDirty(ikTable, id)
	local v110_ = ikTable[id]
	if v110_ ~= nil then
		v110_.isDirty = true
	end
end

-- Local values: ikChain
function IKUtil.setIKChainActive(ikTable, id)
	local v113_ = ikTable[id]
	if v113_ ~= nil then
		v113_.isActive = true
	end
end

-- Local values: ikChain
function IKUtil.setIKChainInactive(ikTable, id)
	local v116_ = ikTable[id]
	if v116_ ~= nil then
		v116_.isActive = false
	end
end

-- Local values: ikChain, pose
function IKUtil.setIKChainPose(ikTable, chainId, poseId)
	local v120_ = ikTable[chainId]
	if v120_ ~= nil and v120_.poses ~= nil then
		local v121_ = v120_.poses[poseId]
		if v121_ ~= nil and v121_.rotationNodes ~= nil then
			IKUtil.setRotationNodes(v121_.rotationNodes)
		end
	end
end

-- Local values: _, ikChain
function IKUtil.getIKChainByTarget(ikTable, targetNode)
	for _, v124_ in pairs(ikTable) do
		if v124_.actualTargetNode == targetNode then
			return v124_
		end
	end
	return nil
end

-- Local values: i, key, ikName, targetNode, target, numRotatioNodes, j, nodeKey, id, rotation
function IKUtil.loadIKChainTargets(xmlFile, baseName, rootNode, targets, i3dMappings)
	local v130_ = 0
	while true do
		local v131_ = string.format(baseName .. ".target(%d)", v130_)
		if not xmlFile:hasProperty(v131_) then
			break
		end
		local v132_ = xmlFile:getValue(v131_ .. "#ikChain")
		local v133_ = xmlFile:getValue(v131_ .. "#targetNode", nil, rootNode, i3dMappings)
		if v133_ == nil then
			Logging.xmlWarning(xmlFile, "Missing targetNode in \'%s\' for chain \'%s\'", v131_, v132_)
		elseif v132_ == nil then
			Logging.xmlWarning(xmlFile, "Missing ikName for target \'%s\'", v131_)
		else
			local v134_ = {
				["ikName"] = v132_,
				["targetNode"] = v133_,
				["targetOffset"] = xmlFile:getValue(v131_ .. "#targetOffset", nil, true),
				["setDirty"] = xmlFile:getValue(v131_ .. "#setDirty", true)
			}
			local v135_ = xmlFile:getNumOfElements(v131_ .. ".rotationNode")
			if v135_ > 0 then
				v134_.rotationNodes = {}
				for v136_ = 0, v135_ - 1 do
					local v137_ = v131_ .. string.format(".rotationNode(%d)", v136_)
					local v138_ = xmlFile:getValue(v137_ .. "#id")
					if v138_ ~= nil then
						local v139_ = xmlFile:getValue(v137_ .. "#rotation", "0 0 0", true)
						local v140_ = v134_.rotationNodes
						table.insert(v140_, {
							["id"] = v138_,
							["rotation"] = v139_
						})
					end
				end
			end
			v134_.poseId = xmlFile:getValue(v131_ .. "#poseId")
			targets[v134_.ikName] = v134_
		end
		v130_ = v130_ + 1
	end
end

function IKUtil.registerIKChainTargetsXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".target(?)#ikChain", "IK chain name")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".target(?)#targetNode", "Target node")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".target(?)#targetOffset", "Target translation offset")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".target(?)#targetRotationOffset", "Target rotation offset")
	schema:register(XMLValueType.BOOL, basePath .. ".target(?)#setDirty", "Is dirty", true)
	schema:register(XMLValueType.INT, basePath .. ".target(?).rotationNode(?)#id", "Rotation node index")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".target(?).rotationNode(?)#rotation", "Rotation node rotation")
	schema:register(XMLValueType.STRING, basePath .. ".target(?)#poseId", "Pose id")
end

function IKUtil.registerIKChainXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#id", "Chain identifier")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#target", "Target node")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#targetOffset", "Target translation offset", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#targetRotationOffset", "Target rotation offset", "0 0 0")
	schema:register(XMLValueType.BOOL, basePath .. "#alignToTarget", "Align to target", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#index", "Chain node")
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRx", "Min. rotation X", -180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRx", "Max. rotation X", 180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRy", "Min. rotation Y", -180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRy", "Max. rotation Y", 180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#minRz", "Min. rotation Z", -180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#maxRz", "Max. rotation Z", 180)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#damping", "Damping", 30)
	schema:register(XMLValueType.BOOL, basePath .. ".node(?)#localLimits", "Local limits", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".rotationNode(?)#index", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".rotationNode(?)#rotation", "Rotation")
	schema:register(XMLValueType.STRING, basePath .. ".pose(?)#id", "Pose id")
	schema:register(XMLValueType.BOOL, basePath .. ".pose(?)#isDefaultPose", "Is default pose", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".pose(?).rotationNode(?)#index", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".pose(?).rotationNode(?)#rotation", "Rotation")
	schema:register(XMLValueType.INT, basePath .. "#numIterations", "Max. number of iterations", 20)
	schema:register(XMLValueType.INT, basePath .. "#numIterationsInit", "Initial max. number of iterations", "numIterations * 2")
	schema:register(XMLValueType.FLOAT, basePath .. "#positionThreshold", "Position threshold", 0.005)
	schema:register(XMLValueType.BOOL, basePath .. "#isDirtyOnLoad", "Is dirty on load", false)
end
