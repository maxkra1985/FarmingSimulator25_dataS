-- Local values: rasterize
CropRowAdjustedNodes = {}

function CropRowAdjustedNodes.prerequisitesPresent(specializations)
	return true
end
function CropRowAdjustedNodes.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("CropRowAdjustedNodes")
	v1_:register(XMLValueType.FLOAT, "vehicle.cropRowAdjustedNodes#maxUpdateDistance", "If the player is more than this distance away the nodes will no longer be updated", 100)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.cropRowAdjustedNodes.adjustedNode(?)#node", "Row adjusted node")
	v1_:register(XMLValueType.INT, "vehicle.cropRowAdjustedNodes.adjustedNode(?)#transAxis", "Translation Axis", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.cropRowAdjustedNodes.adjustedNode(?)#minTrans", "Min. translation value", -0.25)
	v1_:register(XMLValueType.FLOAT, "vehicle.cropRowAdjustedNodes.adjustedNode(?)#maxTrans", "Max. translation value", 0.25)
	v1_:register(XMLValueType.FLOAT, "vehicle.cropRowAdjustedNodes.adjustedNode(?)#moveSpeed", "Move speed (m/sec)", 0.25)
	v1_:register(XMLValueType.BOOL, "vehicle.cropRowAdjustedNodes.adjustedNode(?)#betweenRows", "Defines if the node is aligned on the rows or the middle between the rows", true)
	v1_:register(XMLValueType.STRING, "vehicle.cropRowAdjustedNodes.adjustedNode(?)#fruitTypes", "List of supported fruit types separated by a whitespace", "maize potato sunflower")
	v1_:register(XMLValueType.FLOAT, "vehicle.cropRowAdjustedNodes.adjustedNode(?).foldable#minLimit", "Fold min. time", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.cropRowAdjustedNodes.adjustedNode(?).foldable#maxLimit", "Fold max. time", 1)
	v1_:setXMLSpecializationType()
end

function CropRowAdjustedNodes.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCropRowAdjustedNodeFromXML", CropRowAdjustedNodes.loadCropRowAdjustedNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateCropRowAdjustedNode", CropRowAdjustedNodes.updateCropRowAdjustedNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsCropRowAdjustedNodeActive", CropRowAdjustedNodes.getIsCropRowAdjustedNodeActive)
end

function CropRowAdjustedNodes.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CropRowAdjustedNodes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", CropRowAdjustedNodes)
end

-- Local values: spec
function CropRowAdjustedNodes:onLoad(savegame)
	local v_u_5_ = self.spec_cropRowAdjustedNodes
	v_u_5_.adjustedNodes = {}
	self.xmlFile:iterate("vehicle.cropRowAdjustedNodes.adjustedNode", function(_, p6_)
		-- upvalues: (copy) self, (copy) v_u_5_
		local v7_ = {}
		if self:loadCropRowAdjustedNodeFromXML(self.xmlFile, p6_, v7_) then
			local v8_ = v_u_5_.adjustedNodes
			table.insert(v8_, v7_)
		end
	end)
	if #v_u_5_.adjustedNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", CropRowAdjustedNodes)
	else
		v_u_5_.maxUpdateDistance = self.xmlFile:getValue("vehicle.cropRowAdjustedNodes#maxUpdateDistance", 100)
	end
end

-- Local values: spec, _, adjustedNode
function CropRowAdjustedNodes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v11_ = self.spec_cropRowAdjustedNodes
	if self.currentUpdateDistance < v11_.maxUpdateDistance then
		for _, v12_ in pairs(v11_.adjustedNodes) do
			self:updateCropRowAdjustedNode(v12_, dt)
		end
	end
end

-- Local values: fruitTypesStr, fruitTypes, _, fruitTypeName, fruitType
function CropRowAdjustedNodes:loadCropRowAdjustedNodeFromXML(xmlFile, key, adjustedNode)
	adjustedNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if adjustedNode.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node in \'%s\'", key)
	else
		adjustedNode.referenceFrame = createTransformGroup("cropRowAdjustedNodeRefFrame")
		link(getParent(adjustedNode.node), adjustedNode.referenceFrame)
		setTranslation(adjustedNode.referenceFrame, getTranslation(adjustedNode.node))
		setRotation(adjustedNode.referenceFrame, getRotation(adjustedNode.node))
		adjustedNode.startTrans = { getTranslation(adjustedNode.node) }
		adjustedNode.curTrans = { getTranslation(adjustedNode.node) }
		adjustedNode.transAxis = xmlFile:getValue(key .. "#transAxis", 1)
		adjustedNode.minTrans = xmlFile:getValue(key .. "#minTrans", -0.25)
		adjustedNode.maxTrans = xmlFile:getValue(key .. "#maxTrans", 0.25)
		adjustedNode.moveSpeed = xmlFile:getValue(key .. "#moveSpeed", 0.25) / 1000
		adjustedNode.betweenRows = xmlFile:getValue(key .. "#betweenRows", true)
		adjustedNode.fruitTypes = {}
		local v17_ = xmlFile:getValue(key .. "#fruitTypes", "maize potato sunflower")
		if v17_ ~= nil then
			local v18_ = v17_:split(" ")
			for _, v19_ in pairs(v18_) do
				local v20_ = g_fruitTypeManager:getFruitTypeByName(v19_)
				if v20_ ~= nil then
					adjustedNode.fruitTypes[v20_.index] = true
				end
			end
		end
		if next(adjustedNode.fruitTypes) ~= nil then
			adjustedNode.foldMinLimit = xmlFile:getValue(key .. ".foldable#minLimit", 0)
			adjustedNode.foldMaxLimit = xmlFile:getValue(key .. ".foldable#maxLimit", 1)
			return true
		end
		Logging.xmlWarning(xmlFile, "Missing fruit types in \'%s\'", key)
	end
	return false
end
CropRowAdjustedNodes.MAX_ACTIVE_ANGLE = 0.17453292519943295

-- Local values: wasActive, wx, _, wz, fruitTypeIndex, _, fruitTypeDesc, spacing, snapAngle, x, z, spacing, terrainSize, betweenRows, halfMapSize, rasteredX, rasteredZ, rasteredX1, rasteredZ1, wx2, _, wz2, x, z, spacing, terrainSize, betweenRows, halfMapSize, rasteredX, rasteredZ, rasteredX2, rasteredZ2, normlineDirX, normlineDirZ, yRot, lineX, lineZ, signedDistance, transX, difference, difference, direction, limit
function CropRowAdjustedNodes:updateCropRowAdjustedNode(adjustedNode, dt)
	local v24_ = adjustedNode.isActive
	adjustedNode.isActive = self:getIsCropRowAdjustedNodeActive(adjustedNode)
	if adjustedNode.isActive then
		local v25_, _, v26_ = getWorldTranslation(adjustedNode.referenceFrame)
		local v27_, _ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(v25_, v26_)
		if adjustedNode.fruitTypes[v27_] == nil then
			adjustedNode.isActive = false
			return
		end
		local v28_ = g_fruitTypeManager:getFruitTypeByIndex(v27_).plantSpacing
		local v29_ = g_currentMission.terrainSize
		local v30_ = adjustedNode.betweenRows
		local v31_ = v29_ * 0.5
		if v30_ then
			v31_ = v31_ - v28_ * 0.5
		end
		local v32_ = v25_ + v31_
		local v33_ = v26_ + v31_
		local v34_ = MathUtil.round(v32_ / v28_) * v28_
		local v35_ = MathUtil.round(v33_ / v28_) * v28_
		local v36_ = -v31_ + v34_
		local v37_ = -v31_ + v35_
		local v38_, _, v39_ = localToWorld(adjustedNode.referenceFrame, 0, 0, 10)
		local v40_ = g_currentMission.terrainSize
		local v41_ = adjustedNode.betweenRows
		local v42_ = v40_ * 0.5
		if v41_ then
			v42_ = v42_ - v28_ * 0.5
		end
		local v43_ = v38_ + v42_
		local v44_ = v39_ + v42_
		local v45_ = MathUtil.round(v43_ / v28_) * v28_
		local v46_ = MathUtil.round(v44_ / v28_) * v28_
		local v47_ = -v42_ + v45_
		local v48_ = -v42_ + v46_
		local v49_, v50_ = MathUtil.vector2Normalize(v47_ - v36_, v48_ - v37_)
		local v51_ = MathUtil.getYRotationFromDirection(v49_, v50_)
		local v52_ = MathUtil.round(v51_ / 1.5707963267948966) * 1.5707963267948966
		local v53_, v54_ = MathUtil.getDirectionFromYRotation(v52_)
		local v55_ = v36_ - v53_
		local v56_ = v37_ - v54_
		local v57_ = -MathUtil.getSignedDistanceToLineSegment2D(v25_, v26_, v55_, v56_, v53_, v54_, v28_ + 1)
		local v58_ = adjustedNode.startTrans[adjustedNode.transAxis] + adjustedNode.minTrans
		local v59_ = adjustedNode.startTrans[adjustedNode.transAxis] + adjustedNode.maxTrans
		adjustedNode.targetTrans = math.clamp(v57_, v58_, v59_)
		local v60_ = adjustedNode.targetTrans - adjustedNode.curTrans[adjustedNode.transAxis]
		if math.abs(v60_) > 0.001 then
			adjustedNode.isDirty = true
		end
	elseif v24_ then
		adjustedNode.targetTrans = adjustedNode.startTrans[adjustedNode.transAxis]
		adjustedNode.isDirty = true
	end
	if adjustedNode.isDirty then
		local v61_ = adjustedNode.curTrans
		local v62_ = adjustedNode.curTrans
		local v63_ = adjustedNode.curTrans
		local v64_, v65_, v66_ = getTranslation(adjustedNode.node)
		v61_[1] = v64_
		v62_[2] = v65_
		v63_[3] = v66_
		local v67_ = adjustedNode.targetTrans - adjustedNode.curTrans[adjustedNode.transAxis]
		if math.abs(v67_) > 0.001 then
			local v68_ = math.sign(v67_)
			local v69_ = v68_ > 0 and math.min or math.max
			adjustedNode.curTrans[adjustedNode.transAxis] = v69_(adjustedNode.curTrans[adjustedNode.transAxis] + v68_ * adjustedNode.moveSpeed * dt, adjustedNode.targetTrans)
			setTranslation(adjustedNode.node, adjustedNode.curTrans[1], adjustedNode.curTrans[2], adjustedNode.curTrans[3])
			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(adjustedNode.node)
				return
			end
		else
			adjustedNode.isDirty = false
		end
	end
end

-- Local values: spec_foldable, foldAnimTime, dx, _, dz, yRot
function CropRowAdjustedNodes:getIsCropRowAdjustedNodeActive(adjustedNode)
	local v72_ = self.spec_foldable
	if v72_ ~= nil then
		local v73_ = v72_.foldAnimTime
		if v73_ ~= nil and (adjustedNode.foldMaxLimit < v73_ or v73_ < adjustedNode.foldMinLimit) then
			return false
		end
	end
	if self.getIsLowered == nil or not self:getIsLowered() then
		return false
	end
	local v74_, _, v75_ = localDirectionToWorld(adjustedNode.referenceFrame, 0, 0, 1)
	local v76_ = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(v74_, v75_)) % 1.5707963267948966
	return math.abs(v76_) < CropRowAdjustedNodes.MAX_ACTIVE_ANGLE or math.abs(v76_) > 1.5708 - CropRowAdjustedNodes.MAX_ACTIVE_ANGLE
end
