-- Local values: Line3D_mt
Line3D = {}
Line3D.VISUALS_FILENAME = "data/shared/visualization/line.i3d"
local Line3D_mt = Class(Line3D)

-- Upvalues: Line3D_mt
-- Local values: self
function Line3D.new(customMt)
	-- upvalues: (copy) Line3D_mt
	local v3_ = customMt or Line3D_mt
	local v4_ = setmetatable({}, v3_)
	v4_.visNodes = createTransformGroup("line3DVisualizationShapes")
	link(getRootNode(), v4_.visNodes)
	v4_.nodeCache = NodeCache.new()
	v4_.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(Line3D.VISUALS_FILENAME, false, false, Line3D.onVisualsLoaded, v4_)
	return v4_
end

-- Local values: line
function Line3D:onVisualsLoaded(i3dNode)
	if i3dNode ~= nil then
		local v7_ = getChildAt(i3dNode, 0)
		unlink(v7_)
		self.nodeCache:addTemplate(v7_)
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

-- Local values: len, currentNode, shape, r, g, b, currentBoneIndex, numBones, stepSize, prevBone, firstBone, x, y, z, step, currentBone, px, py, pz, sDirX, sDirY, sDirZ, px, py, pz, sDirX, sDirY, sDirZ, i
function Line3D:visualizeLine(sx, sy, sz, ex, ey, ez, alignToTerrain, color)
	local v18_ = MathUtil.vector3Length(ex - sx, ey - sy, ez - sz)
	local v19_ = math.round(v18_)
	if v19_ ~= 0 then
		local v20_ = self.nodeCache:getNodeInstance(1)
		link(self.visNodes, v20_)
		local v21_ = getChildAt(v20_, 0)
		setShapeBoundingSphere(v21_, 0, 0, 0, 60)
		local v22_, v23_, v24_
		if color == nil then
			v22_ = nil
			v23_ = nil
			v24_ = nil
		else
			v22_, v23_, v24_ = color:unpack()
			setShaderParameter(v21_, "emitColor", v22_, v23_, v24_, 1, false)
		end
		local v25_ = getNumOfChildren(v20_)
		local v26_ = getChildAt(v20_, 0)
		local v27_ = 0
		local v28_ = nil
		local v29_ = nil
		local v30_ = nil
		local v31_ = nil
		for v32_ = 0, v19_ do
			if alignToTerrain then
				v29_, v31_ = MathUtil.vector2Lerp(sx, sz, ex, ez, v32_ / v19_)
				v30_ = getTerrainHeightAtWorldPos(g_terrainNode, v29_, 0, v31_) + 0.05
			else
				v29_, v30_, v31_ = MathUtil.vector3Lerp(sx, sy, sz, ex, ey, ez, v32_ / v19_)
			end
			local v33_ = getChildAt(v20_, v27_)
			setWorldTranslation(v33_, v29_, v30_, v31_)
			setVisibility(v33_, true)
			if v28_ ~= nil then
				local v34_, v35_, v36_ = getWorldTranslation(v28_)
				local v37_, v38_, v39_ = MathUtil.vector3Normalize(v29_ - v34_, v30_ - v35_, v31_ - v36_)
				setDirection(v28_, v37_, v38_, v39_, 0, 1, 0)
			end
			v27_ = v27_ + 1
			if v25_ <= v27_ then
				v20_ = self.nodeCache:getNodeInstance(1)
				link(self.visNodes, v20_)
				local v40_ = getChildAt(v20_, 0)
				if v22_ ~= nil then
					setShaderParameter(v40_, "emitColor", v22_, v23_, v24_, 1, false)
				end
				setShapeBoundingSphere(v40_, 0, 0, 0, v25_)
				v28_ = v33_
				v27_ = 0
			else
				v28_ = v33_
			end
		end
		if v28_ ~= nil and v26_ ~= v28_ then
			local v41_, v42_, v43_ = getWorldTranslation(v26_)
			local v44_, v45_, v46_ = MathUtil.vector3Normalize(v41_ - v29_, v42_ - v30_, v43_ - v31_)
			setDirection(v28_, v44_, v45_, v46_, 0, 1, 0)
		end
		for v47_ = v27_, v25_ - 1 do
			setVisibility(getChildAt(v20_, v47_), false)
		end
	end
end

-- Local values: numChildren, i, child
function Line3D:clearVisualization()
	if self.visNodes ~= nil then
		local v49_ = getNumOfChildren(self.visNodes)
		if v49_ ~= 0 then
			for v50_ = v49_ - 1, 0, -1 do
				local v51_ = getChildAt(self.visNodes, v50_)
				unlink(v51_)
				self.nodeCache:returnNodeToCache(v51_)
			end
		end
	end
end
