-- Local values: DensityMapNodePolygon_mt
DensityMapNodePolygon = {}
local DensityMapNodePolygon_mt = Class(DensityMapNodePolygon)

-- Upvalues: DensityMapNodePolygon_mt
-- Local values: self
function DensityMapNodePolygon.new(customMt)
	-- upvalues: (copy) DensityMapNodePolygon_mt
	local v3_ = customMt or DensityMapNodePolygon_mt
	local v4_ = setmetatable({}, v3_)
	v4_.nodes = {}
	return v4_
end

function DensityMapNodePolygon:saveToXMLFile(xmlFile, key) end

function DensityMapNodePolygon:loadFromXMLFile(xmlFile, key)
	return true
end

function DensityMapNodePolygon:addNode(node)
	local v7_ = self.nodes
	table.insert(v7_, node)
end

-- Local values: polygon3DVertices, _, node, x, y, z
function DensityMapNodePolygon:getVerticesAs3DCoordinates(worldY, worldYFunc)
	local v9_ = table.create(#self.nodes * 3)
	for _, v10_ in ipairs(self.nodes) do
		local v11_, v12_, v13_ = getWorldTranslation(v10_)
		table.insert(v9_, v11_)
		table.insert(v9_, v12_)
		table.insert(v9_, v13_)
	end
	return v9_
end

-- Local values: worldX, worldZ, numNodes, i, x, _, z
function DensityMapNodePolygon:getCenter()
	local v15_ = 0
	local v16_ = 0
	local v17_ = #self.nodes
	if v17_ > 0 then
		for v18_ = 1, #self.nodes do
			local v19_, _, v20_ = getWorldTranslation(self.nodes[v18_])
			v15_ = v15_ + v19_
			v16_ = v16_ + v20_
		end
		v15_ = v15_ / v17_
		v16_ = v16_ / v17_
	end
	return v15_, v16_
end

-- Local values: vertices, _, node, x, y, z
function DensityMapNodePolygon:drawDebug()
	local v22_ = {}
	for _, v23_ in ipairs(self.nodes) do
		local v24_, v25_, v26_ = getWorldTranslation(v23_)
		table.insert(v22_, v24_)
		table.insert(v22_, v25_)
		table.insert(v22_, v26_)
	end
	drawDebugPolygon(v22_, 1, 0, 0, 1, false)
end

-- Local values: _, node, x, _, z
function DensityMapNodePolygon:applyToModifier(modifier)
	modifier:clearPolygonPoints()
	for _, v29_ in ipairs(self.nodes) do
		local v30_, _, v31_ = getWorldTranslation(v29_)
		modifier:addPolygonPointWorldCoords(v30_, v31_)
	end
end

-- Local values: polygon, _, nodeKey, node
function DensityMapNodePolygon.createFromXMLFile(xmlFile, key, components, i3dMappings)
	if not xmlFile:hasProperty(key .. ".polygon.node") then
		return nil
	end
	local v36_ = DensityMapNodePolygon.new()
	for _, v37_ in xmlFile:iterator(key .. ".polygon.node") do
		local v38_ = xmlFile:getValue(v37_ .. "#node", nil, components, i3dMappings)
		if v38_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid node for DensityMapNodePolygon in \'%s\'", v37_)
			return
		end
		v36_:addNode(v38_)
	end
	if #v36_.nodes >= 3 then
		return v36_
	end
	Logging.xmlWarning(xmlFile, "Too few polygon nodes defined. A polygon needs at least 3 nodes. \'%s\'", key)
	return nil
end

function DensityMapNodePolygon.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".polygon.node(?)#node", "Polygon node", nil, false)
end
