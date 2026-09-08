-- Local values: RollingGateAnimation_mt
RollingGateAnimation = {}
local RollingGateAnimation_mt = Class(RollingGateAnimation)

-- Upvalues: RollingGateAnimation_mt
-- Local values: self
function RollingGateAnimation.new(customMt)
	-- upvalues: (copy) RollingGateAnimation_mt
	local v3_ = customMt or RollingGateAnimation_mt
	local v4_ = setmetatable({}, v3_)
	v4_.state = 0
	return v4_
end

-- Local values: lastTime, minTime, maxTime, segments, _, segmentKey, segment, splinePosition, segmentData, lastSegment, segmentData
function RollingGateAnimation:load(xmlFile, key, rootNodes, i3dMapping)
	self.splineNode = xmlFile:getValue(key .. "#splineNode", nil, rootNodes, i3dMapping)
	if self.splineNode == nil then
		Logging.xmlWarning(xmlFile, "Missing splineNode for rolling gate animation \'%s\'!", key)
		return false
	end
	if not getHasClassId(getGeometry(self.splineNode), ClassIds.SPLINE) then
		Logging.xmlWarning(xmlFile, "Node \'%s\' is not a spline for rolling gate animation \'%s\'!", getName(self.splineNode), key)
		return false
	end
	setVisibility(self.splineNode, false)
	self.referenceFrame = xmlFile:getValue(key .. "#referenceFrame", nil, rootNodes, i3dMapping)
	if self.referenceFrame == nil then
		Logging.xmlWarning(xmlFile, "Missing referenceFrame for rolling gate animation \'%s\'!", key)
		return false
	end
	self.isInverted = xmlFile:getValue(key .. "#isInverted", false)
	self.maxOpeningDistance = xmlFile:getValue(key .. "#maxOpeningDistance")
	self.splineLength = getSplineLength(self.splineNode)
	self.segmentsByLength = {}
	local v10_ = math.huge
	local v11_ = -math.huge
	local v12_ = nil
	local v13_ = {}
	for _, v14_ in xmlFile:iterator(key .. ".segment") do
		local v15_ = {
			["node"] = xmlFile:getValue(v14_ .. "#node", nil, rootNodes, i3dMapping)
		}
		if v15_.node ~= nil then
			v15_.length = xmlFile:getValue(v14_ .. "#length", 0.1)
			v15_.lineAlignmentStartNode = xmlFile:getValue(v14_ .. ".lineAlignment#startNode", nil, rootNodes, i3dMapping)
			v15_.lineAlignmentEndNode = xmlFile:getValue(v14_ .. ".lineAlignment#endNode", nil, rootNodes, i3dMapping)
			local v16_ = self:getSplineTime(v15_.node)
			if (v12_ or v16_) < v16_ and #v13_ > 0 then
				local v17_ = {
					["minTime"] = v10_,
					["maxTime"] = v11_,
					["totalLength"] = v11_ - v10_ + v13_[#v13_].length / self.splineLength,
					["segments"] = v13_
				}
				local v18_ = self.segmentsByLength
				table.insert(v18_, v17_)
				v13_ = {}
				v10_ = math.huge
				v11_ = -math.huge
			end
			local v19_ = v13_[#v13_]
			if v19_ ~= nil then
				v19_.length = calcDistanceFrom(v19_.node, v15_.node)
			end
			table.insert(v13_, v15_)
			v10_ = math.min(v10_, v16_)
			v11_ = math.max(v11_, v16_)
			v12_ = v16_
		end
	end
	if #v13_ > 0 then
		local v20_ = {
			["minTime"] = v10_,
			["maxTime"] = v11_,
			["totalLength"] = v11_ - v10_ + v13_[#v13_].length / self.splineLength,
			["segments"] = v13_
		}
		local v21_ = self.segmentsByLength
		table.insert(v21_, v20_)
	end
	return true
end

-- Local values: _, segmentData, time, _, segment, _, _, _, nextTime, wx, wy, wz, lx, ly, lz, _, ny, nz, _, sy, sz, _, ey, ez, intersect, iy, iz, normlineDirY, normlineDirZ, dy, dz, length, upX, upY, upZ, tx, ty, tz, dx, dy, dz, length, upX, upY, upZ
function RollingGateAnimation:setState(state)
	local v24_ = math.clamp(state, 0, 1)
	for _, v25_ in ipairs(self.segmentsByLength) do
		local v26_
		if self.isInverted then
			v26_ = v25_.maxTime - v24_ * (self.maxOpeningDistance or v25_.totalLength)
		else
			v26_ = v25_.maxTime + v24_ * (self.maxOpeningDistance or 1 - v25_.maxTime)
		end
		for _, v27_ in pairs(v25_.segments) do
			local _, _, _, v28_ = getSplinePositionWithDistance(self.splineNode, v26_, v27_.length, false, 0.001)
			local v29_ = v28_ == v26_ and 0 or v28_
			local v30_ = math.max(v26_, 0.001)
			local v31_, v32_, v33_ = getSplinePosition(self.splineNode, v30_)
			local v34_, v35_, v36_ = worldToLocal(getParent(v27_.node), v31_, v32_, v33_)
			setTranslation(v27_.node, v34_, v35_, v36_)
			if v27_.lineAlignmentStartNode == nil or v27_.lineAlignmentEndNode == nil then
				local v37_, v38_, v39_ = getSplinePosition(self.splineNode, v29_)
				local v40_ = v37_ - v31_
				local v41_ = v38_ - v32_
				local v42_ = v39_ - v33_
				local v43_ = MathUtil.vector3Length(v40_, v41_, v42_)
				if v43_ > 0.001 then
					local v44_ = v40_ / v43_
					local v45_ = v41_ / v43_
					local v46_ = v42_ / v43_
					local v47_, v48_, v49_ = worldDirectionToLocal(getParent(v27_.node), v44_, v45_, v46_)
					local v50_, v51_, v52_ = localDirectionToLocal(self.referenceFrame, getParent(v27_.node), 0, 1, 0)
					setDirection(v27_.node, v47_, v48_, v49_, v50_, v51_, v52_)
				end
			else
				local _, v53_, v54_ = getTranslation(v27_.node)
				local _, v55_, v56_ = localToLocal(v27_.lineAlignmentStartNode, getParent(v27_.node), 0, 0, 0)
				local _, v57_, v58_ = localToLocal(v27_.lineAlignmentEndNode, getParent(v27_.node), 0, 0, 0)
				local v59_, v60_, v61_ = MathUtil.getCircleLineIntersection(v53_, v54_, v27_.length, v55_, v56_, v57_, v58_, false)
				if not v59_ then
					local v62_, v63_ = MathUtil.vector2Normalize(v57_ - v55_, v58_ - v56_)
					v60_, v61_ = MathUtil.projectOnLine(v53_, v54_, v55_, v56_, v62_, v63_)
				end
				local v64_ = v60_ - v53_
				local v65_ = v61_ - v54_
				local v66_ = MathUtil.vector2Length(v64_, v65_)
				if v66_ > 0 then
					local v67_ = v64_ / v66_
					local v68_ = v65_ / v66_
					local v69_, v70_, v71_ = localDirectionToLocal(self.referenceFrame, getParent(v27_.node), 0, 1, 0)
					setDirection(v27_.node, 0, v67_, v68_, v69_, v70_, v71_)
				end
			end
			v26_ = v29_
		end
	end
	self.state = v24_
end

-- Local values: minDistance, minDistanceTime, i, sx, sy, sz, distance
function RollingGateAnimation:getClosestSplineTime(startTime, endTime, resolution, x, y, z)
	local v79_ = math.huge
	local v80_ = 0
	for v81_ = startTime, endTime, resolution do
		local v82_, v83_, v84_ = getSplinePosition(self.splineNode, v81_)
		local v85_ = MathUtil.vector3Length(x - v82_, y - v83_, z - v84_)
		if v85_ < v79_ then
			v80_ = v81_
			v79_ = v85_
		end
	end
	return v80_
end

-- Local values: x, y, z, splineLength, minDistanceTime1, minDistanceTime2, minDistanceTime3
function RollingGateAnimation:getSplineTime(node)
	local v88_, v89_, v90_ = getWorldTranslation(node)
	local v91_ = getSplineLength(self.splineNode)
	local v92_ = self:getClosestSplineTime(0, v91_, 0.15 / v91_, v88_, v89_, v90_)
	local v93_ = v92_ - 0.15
	local v94_ = math.max(v93_, 0)
	local v95_ = v92_ + 0.15
	local v96_ = self:getClosestSplineTime(v94_, math.min(v95_, v91_), 0.01 / v91_, v88_, v89_, v90_)
	local v97_ = v96_ - 0.01
	local v98_ = math.max(v97_, 0)
	local v99_ = v96_ + 0.01
	return self:getClosestSplineTime(v98_, math.min(v99_, v91_), 0.001 / v91_, v88_, v89_, v90_)
end

function RollingGateAnimation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#splineNode", "Spline Node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#referenceFrame", "Reference Frame")
	schema:register(XMLValueType.BOOL, basePath .. "#isInverted", "Gate is inverted", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxOpeningDistance", "Gate opening distance in spline time [0-1]", "automatically based on gate length, so it is fully open")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".segment(?)#node", "Node of the segment")
	schema:register(XMLValueType.FLOAT, basePath .. ".segment(?)#length", "Length of the segment")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".segment(?).lineAlignment#startNode", "Start node of the line to align to")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".segment(?).lineAlignment#endNode", "End node of the line to align to")
end
