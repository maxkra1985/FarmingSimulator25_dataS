Marker3D = {}
Marker3D.VISUALS_FILENAME = "data/shared/visualization/marker.i3d"
Marker3D.SHADER_PARAMETER_EMIT_COLOR = "emitColor"
local Marker3D_mt = Class(Marker3D)
function Marker3D.new(customMt)
	local self = setmetatable({}, customMt or Marker3D_mt)
	self.visNodes = createTransformGroup("marker3DVisualizationShapes")
	link(getRootNode(), self.visNodes)
	self.nodeCache = NodeCache.new()
	self.scale = 1
	self.templateLoaded = false
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(Marker3D.VISUALS_FILENAME, false, false, Marker3D.onVisualsLoaded, self)
	return self
end
function Marker3D:onVisualsLoaded(i3dNode)
	if i3dNode == nil then
		return
	else
		local marker = getChildAt(i3dNode, 0)
		unlink(marker)
		self.nodeCache:addTemplate(marker)
		self.templateLoaded = true
		delete(i3dNode)
	end
end
function Marker3D:getIsLoaded()
	return self.templateLoaded
end
function Marker3D:delete()
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
function Marker3D:setScale(scale)
	self.scale = math.max(scale or 1, 0)
end
function Marker3D:visualizeMarker(x, y, z, color)
	if not self.templateLoaded then
		return nil
	end
	local markerNode = self.nodeCache:getNodeInstance(1)
	if markerNode == nil then
		return nil
	else
		link(self.visNodes, markerNode)
		setWorldTranslation(markerNode, x, y, z)
		setScale(markerNode, self.scale, self.scale, self.scale)
		setVisibility(markerNode, true)
		if color ~= nil then
			local red, green, blue = color:unpack()
			self:applyEmitColor(markerNode, red, green, blue)
		end
		return markerNode
	end
end
function Marker3D:clearVisualization()
	if self.visNodes == nil then
		return
	else
		local numChildren = getNumOfChildren(self.visNodes)
		for i = numChildren - 1, 0, -1 do
			local child = getChildAt(self.visNodes, i)
			unlink(child)
			self.nodeCache:returnNodeToCache(child)
		end
	end
end
function Marker3D:applyEmitColor(markerNode, red, green, blue)
	if getHasShaderParameter(markerNode, Marker3D.SHADER_PARAMETER_EMIT_COLOR) then
		setShaderParameter(markerNode, Marker3D.SHADER_PARAMETER_EMIT_COLOR, red, green, blue, 1, false)
	else
		if 0 < getNumOfChildren(markerNode) then
			local shape = getChildAt(markerNode, 0)
			if getHasShaderParameter(shape, Marker3D.SHADER_PARAMETER_EMIT_COLOR) then
				setShaderParameter(shape, Marker3D.SHADER_PARAMETER_EMIT_COLOR, red, green, blue, 1, false)
			end
		end
	end
end
