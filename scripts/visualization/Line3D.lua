Line3D = {}
Line3D.VISUALS_FILENAME = "data/shared/visualization/line.i3d"
Line3D.SHADER_PARAMETER_EMIT_COLOR = "emitColor"
Line3D.SHADER_PARAMETER_SCALE = "scale"
Line3D.BONE_SEGMENT_LENGTH = 1
Line3D.UP_VECTOR = Vector3.new(0, 1, 0)
Line3D.FALLBACK_UP_VECTOR = Vector3.new(0, 0, 1)
Line3D.MAX_UP_VECTOR_DOT = 0.9999
local Line3D_mt = Class(Line3D)
function Line3D.new(customMt)
	local self = setmetatable({}, customMt or Line3D_mt)
	self.visNodes = createTransformGroup("line3DVisualizationShapes")
	link(getRootNode(), self.visNodes)
	self.nodeCache = NodeCache.new()
	self.lineScaleX = 1
	self.lineScaleY = 1
	self.templateLoaded = false
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(Line3D.VISUALS_FILENAME, false, false, Line3D.onVisualsLoaded, self)
	return self
end
function Line3D:onVisualsLoaded(i3dNode)
	if i3dNode ~= nil then
		local line = getChildAt(i3dNode, 0)
		unlink(line)
		self.nodeCache:addTemplate(line)
		self.templateLoaded = true
		delete(i3dNode)
	end
end
function Line3D:getIsLoaded()
	return self.templateLoaded
end
function Line3D:delete()
	if self.visNodes ~= nil then
		delete(self.visNodes)
		self.visNodes = nil
	end
	if self.nodeCache ~= nil then
		self.nodeCache:delete()
		self.nodeCache = nil
	end
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
		self.sharedLoadRequestId = nil
	end
end
function Line3D:setLineScale(scaleX, scaleY)
	self.lineScaleX = math.max(scaleX or 1, 0)
	self.lineScaleY = math.max(scaleY or 1, 0)
end
function Line3D:visualizeLine(sx, sy, sz, ex, ey, ez, alignToTerrain, color)
	if not self.templateLoaded then
		return
	end
	local len = math.round(MathUtil.vector3Length(ex - sx, ey - sy, ez - sz))
	if len == 0 then
		return
	else
		local currentNode = self.nodeCache:getNodeInstance(1)
		link(self.visNodes, currentNode)
		local shape = getChildAt(currentNode, 0)
		setShapeBoundingSphere(shape, 0, 0, 0, 60)
		local r = nil
		local g = nil
		local b = nil
		if color ~= nil then
			r, g, b = color:unpack()
		end
		self:applyShaderParameters(shape, r, g, b)
		local currentBoneIndex = 0
		local numBones = getNumOfChildren(currentNode)
		local stepSize = 1
		local prevBone = nil
		local firstBone = getChildAt(currentNode, 0)
		local x = nil
		local y = nil
		local z = nil
		for step = 0, len do
			if alignToTerrain then
				x, z = MathUtil.vector2Lerp(sx, sz, ex, ez, step / len)
				y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.05
			else
				x, y, z = MathUtil.vector3Lerp(sx, sy, sz, ex, ey, ez, step / len)
			end
			local currentBone = getChildAt(currentNode, currentBoneIndex)
			setWorldTranslation(currentBone, x, y, z)
			setVisibility(currentBone, true)
			if prevBone ~= nil then
				Line3D.setBoneDirection(prevBone, getWorldTranslationVector(prevBone), vector.create(x, y, z))
			end
			prevBone = currentBone
			currentBoneIndex = currentBoneIndex + 1
			if numBones <= currentBoneIndex then
				currentNode = self.nodeCache:getNodeInstance(1)
				link(self.visNodes, currentNode)
				shape = getChildAt(currentNode, 0)
				self:applyShaderParameters(shape, r, g, b)
				setShapeBoundingSphere(shape, 0, 0, 0, numBones)
				currentBoneIndex = 0
			end
		end
		if prevBone ~= nil and firstBone ~= prevBone then
			Line3D.setBoneDirection(prevBone, vector.create(x, y, z), getWorldTranslationVector(firstBone))
		end
		for i = currentBoneIndex, numBones - 1 do
			setVisibility(getChildAt(currentNode, i), false)
		end
	end
end
function Line3D:visualizePolyline(points, alignToTerrain, color, closed, terrainOffset)
	if not self.templateLoaded then
		return
	end
	local numPoints = #points
	if numPoints < 2 then
		return
	end
	terrainOffset = terrainOffset or 0.05
	local numSegments = numPoints - 1
	if closed then
		numSegments = numPoints
	end
	local segmentLengths, totalLength = Line3D.getPolylineSegmentLengths(points, numPoints, numSegments)
	local numSteps = math.round(totalLength / Line3D.BONE_SEGMENT_LENGTH)
	if numSteps == 0 then
		return
	else
		local stepLength = totalLength / numSteps
		local currentNode = self.nodeCache:getNodeInstance(1)
		link(self.visNodes, currentNode)
		local shape = getChildAt(currentNode, 0)
		setShapeBoundingSphere(shape, 0, 0, 0, 60)
		local r = nil
		local g = nil
		local b = nil
		if color ~= nil then
			r, g, b = color:unpack()
		end
		self:applyShaderParameters(shape, r, g, b)
		local currentBoneIndex = 0
		local numBones = getNumOfChildren(currentNode)
		local segmentIndex = 1
		local segmentStartDistance = 0
		local prevBone = nil
		local prevPosition = nil
		local beforePrevPosition = nil
		for step = 0, numSteps do
			local stepDistance = step * stepLength
			while segmentIndex < numSegments do
				if segmentStartDistance + segmentLengths[segmentIndex] < stepDistance then
					segmentStartDistance = segmentStartDistance + segmentLengths[segmentIndex]
					segmentIndex = segmentIndex + 1
				end
			end
			local nextIndex = segmentIndex + 1
			if numPoints < nextIndex then
				nextIndex = 1
			end
			local fromPoint = points[segmentIndex]
			local segmentLength = segmentLengths[segmentIndex]
			local alpha = 0
			if 0 < segmentLength then
				alpha = math.clamp((stepDistance - segmentStartDistance) / segmentLength, 0, 1)
			end
			local position = fromPoint + (points[nextIndex] - fromPoint) * alpha
			if alignToTerrain then
				local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, position.x, 0, position.z) + terrainOffset
				position = vector.create(position.x, terrainHeight, position.z)
			end
			local currentBone = getChildAt(currentNode, currentBoneIndex)
			setWorldTranslationVector(currentBone, position)
			setVisibility(currentBone, true)
			if prevBone ~= nil then
				Line3D.setBoneDirection(prevBone, prevPosition, position)
				beforePrevPosition = prevPosition
			end
			prevBone = currentBone
			prevPosition = position
			currentBoneIndex = currentBoneIndex + 1
			if numBones <= currentBoneIndex then
				currentNode = self.nodeCache:getNodeInstance(1)
				link(self.visNodes, currentNode)
				shape = getChildAt(currentNode, 0)
				self:applyShaderParameters(shape, r, g, b)
				setShapeBoundingSphere(shape, 0, 0, 0, numBones)
				currentBoneIndex = 0
			end
		end
		if prevBone ~= nil and beforePrevPosition ~= nil then
			Line3D.setBoneDirection(prevBone, prevPosition, beforePrevPosition)
		end
		for i = currentBoneIndex, numBones - 1 do
			setVisibility(getChildAt(currentNode, i), false)
		end
	end
end
function Line3D:clearVisualization()
	if self.visNodes == nil then
		return
	else
		local numChildren = getNumOfChildren(self.visNodes)
		if numChildren ~= 0 then
			for i = numChildren - 1, 0, -1 do
				local child = getChildAt(self.visNodes, i)
				unlink(child)
				self.nodeCache:returnNodeToCache(child)
			end
		end
	end
end
function Line3D:applyShaderParameters(shape, r, g, b)
	if r ~= nil and getHasShaderParameter(shape, Line3D.SHADER_PARAMETER_EMIT_COLOR) then
		setShaderParameter(shape, Line3D.SHADER_PARAMETER_EMIT_COLOR, r, g, b, 1, false)
	end
	if getHasShaderParameter(shape, Line3D.SHADER_PARAMETER_SCALE) then
		setShaderParameter(shape, Line3D.SHADER_PARAMETER_SCALE, self.lineScaleX, self.lineScaleY, 1, 0, false)
	end
end
function Line3D.getPolylineSegmentLengths(points, numPoints, numSegments)
	local segmentLengths = {}
	local totalLength = 0
	for i = 1, numSegments do
		local nextIndex = i + 1
		if numPoints < nextIndex then
			nextIndex = 1
		end
		local length = vector.magnitude(points[nextIndex] - points[i])
		segmentLengths[i] = length
		totalLength = totalLength + length
	end
	return segmentLengths, totalLength
end
function Line3D.setBoneDirection(bone, fromPosition, toPosition)
	local direction = toPosition - fromPosition
	if vector.dot(direction, direction) == 0 then
		direction = Line3D.UP_VECTOR
	end
	local normalizedDirection = vector.normalize(direction)
	local upVector = Line3D.UP_VECTOR
	if Line3D.MAX_UP_VECTOR_DOT < math.abs(vector.dot(normalizedDirection, upVector)) then
		upVector = Line3D.FALLBACK_UP_VECTOR
	end
	setDirectionVector(bone, normalizedDirection, upVector)
end
