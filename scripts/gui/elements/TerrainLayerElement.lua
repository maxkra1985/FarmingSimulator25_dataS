-- Local values: TerrainLayerElement_mt
TerrainLayerElement = {}
local TerrainLayerElement_mt = Class(TerrainLayerElement, GuiElement)
Gui.registerGuiElement("TerrainLayer", TerrainLayerElement)

-- Upvalues: TerrainLayerElement_mt
-- Local values: self
function TerrainLayerElement.new(target, custom_mt)
	-- upvalues: (copy) TerrainLayerElement_mt
	local v4_ = TerrainLayerElement:superClass().new(target, custom_mt or TerrainLayerElement_mt)
	v4_.terrainLayerTextureOverlay = nil
	return v4_
end

function TerrainLayerElement:delete()
	self:destroyOverlay(self.terrainRootNode)
	TerrainLayerElement:superClass().delete(self)
end

function TerrainLayerElement:copyAttributes(src)
	TerrainLayerElement:superClass().copyAttributes(self, src)
	self:setTerrainLayer(src.terrainRootNode, src.layer)
end

-- Local values: displayLayer
function TerrainLayerElement:setTerrainLayer(terrainRootNode, layer)
	if layer ~= nil then
		if self.terrainLayerTextureOverlay == nil then
			self:createOverlay(terrainRootNode)
		end
		local v11_ = getTerrainLayerSubLayer(terrainRootNode, layer, 0)
		setOverlayLayer(self.terrainLayerTextureOverlay, v11_)
		self.layer = layer
	end
end

-- Local values: terrainLayerTexture
function TerrainLayerElement:createOverlay(terrainRootNode)
	self.terrainRootNode = terrainRootNode
	local v14_ = createTerrainLayerTexture(g_terrainNode)
	self.terrainLayerTextureOverlay = createImageOverlayWithTexture(v14_)
	delete(v14_)
end

function TerrainLayerElement:destroyOverlay(terrainRootNode)
	if self.terrainRootNode ~= nil and self.terrainRootNode == terrainRootNode then
		if self.terrainLayerTextureOverlay ~= nil then
			delete(self.terrainLayerTextureOverlay)
			self.terrainLayerTextureOverlay = nil
		end
		self.terrainRootNode = nil
	end
end

-- Local values: posX, posY, sizeX, sizeY, u1, v1, u2, v2, u3, v3, u4, v4, oldX1, oldY1, oldX2, oldY2, posX2, posY2, p1, p2, p3, p4
function TerrainLayerElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self.terrainLayerTextureOverlay ~= nil then
		local v22_ = self.absPosition[1]
		local v23_ = self.absPosition[2]
		local v24_ = self.size[1]
		local v25_ = self.size[2]
		local v26_, v27_, v28_, v29_, v30_, v31_, v32_, v33_, v34_, v35_
		if clipX1 == nil then
			v26_ = v22_
			v27_ = v23_
			v28_ = 0
			v29_ = 0
			v30_ = 1
			v31_ = 0
			v32_ = 1
			v33_ = 1
			v34_ = 1
			v35_ = 0
		else
			local v36_ = v24_ + v22_
			local v37_ = v25_ + v23_
			local v38_ = v22_ + v24_
			local v39_ = v23_ + v25_
			v26_ = math.max(v22_, clipX1)
			v27_ = math.max(v23_, clipY1)
			local v40_ = math.min(v38_, clipX2) - v26_
			v24_ = math.max(v40_, 0)
			local v41_ = math.min(v39_, clipY2) - v27_
			v25_ = math.max(v41_, 0)
			v28_ = (v26_ - v22_) / (v36_ - v22_)
			v29_ = (v27_ - v23_) / (v37_ - v23_)
			v30_ = (v26_ + v24_ - v22_) / (v36_ - v22_)
			v32_ = (v27_ + v25_ - v23_) / (v37_ - v23_)
			v35_ = v29_
			v34_ = v30_
			v33_ = v32_
			v31_ = v28_
		end
		if v31_ ~= v34_ and v35_ ~= v32_ then
			setOverlayUVs(self.terrainLayerTextureOverlay, v31_, v35_, v28_, v32_, v34_, v29_, v30_, v33_)
			renderOverlay(self.terrainLayerTextureOverlay, v26_, v27_, v24_, v25_)
		end
		TerrainLayerElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
	end
end

-- Local values: _, v
function TerrainLayerElement:canReceiveFocus()
	if not self.visible or #self.elements < 1 then
		return false
	end
	for _, v43_ in ipairs(self.elements) do
		if not v43_:canReceiveFocus() then
			return false
		end
	end
	return true
end

-- Local values: _, firstElement
function TerrainLayerElement:getFocusTarget()
	if #self.elements > 0 then
		local _, v45_ = next(self.elements)
		if v45_ then
			return v45_
		end
	end
	return self
end

function TerrainLayerElement:reset()
	self:destroyOverlay(self.terrainRootNode)
end
