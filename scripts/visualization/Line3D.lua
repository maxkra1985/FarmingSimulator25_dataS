Line3D = {}
Line3D.VISUALS_FILENAME = "data/shared/visualization/line.i3d"
local Line3D_mt = Class(Line3D)
function Line3D.new(customMt)
	local self = setmetatable({}, customMt or Line3D_mt)
	self.visNodes = createTransformGroup("line3DVisualizationShapes")
	link(getRootNode(), self.visNodes)
	self.nodeCache = NodeCache.new()
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(Line3D.VISUALS_FILENAME, false, false, Line3D.onVisualsLoaded, self)
	return self
end
function Line3D:onVisualsLoaded(i3dNode)
	if i3dNode ~= nil then
		local line = getChildAt(i3dNode, 0)
		unlink(line)
		self.nodeCache:addTemplate(line)
		delete(i3dNode)
	end
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
function Line3D:visualizeLine(sx, sy, sz, ex, ey, ez, alignToTerrain, color)
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
			setShaderParameter(shape, "emitColor", r, g, b, 1, false)
		end
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
				local px, py, pz = getWorldTranslation(prevBone)
				local sDirX, sDirY, sDirZ = MathUtil.vector3Normalize(x - px, y - py, z - pz)
				setDirection(prevBone, sDirX, sDirY, sDirZ, 0, 1, 0)
			end
			prevBone = currentBone
			currentBoneIndex = currentBoneIndex + 1
			if numBones <= currentBoneIndex then
				currentNode = self.nodeCache:getNodeInstance(1)
				link(self.visNodes, currentNode)
				shape = getChildAt(currentNode, 0)
				if r ~= nil then
					setShaderParameter(shape, "emitColor", r, g, b, 1, false)
				end
				setShapeBoundingSphere(shape, 0, 0, 0, numBones)
				currentBoneIndex = 0
			end
		end
		if prevBone ~= nil and firstBone ~= prevBone then
			local px, py, pz = getWorldTranslation(firstBone)
			local sDirX, sDirY, sDirZ = MathUtil.vector3Normalize(px - x, py - y, pz - z)
			setDirection(prevBone, sDirX, sDirY, sDirZ, 0, 1, 0)
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
