FillPlaneUtil = {}

function FillPlaneUtil.registerFillPlaneXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Node")
	schema:register(XMLValueType.FLOAT, key .. "#capacity", "Visual capacity of the fill plane")
	schema:register(XMLValueType.FLOAT, key .. "#maxDelta", "Max. heap size above above input surface [m]", 1)
	schema:register(XMLValueType.ANGLE, key .. "#maxAllowedHeapAngle", "Max. allowed heap surface slope angle [deg]", 35)
	schema:register(XMLValueType.FLOAT, key .. "#maxSurfaceDistanceError", "Max. allowed distance from input mesh surface to created fill plane mesh [m]", 0.05)
	schema:register(XMLValueType.FLOAT, key .. "#maxSubDivEdgeLength", "Max. length of sub division edges [m]", 0.9)
	schema:register(XMLValueType.FLOAT, key .. "#syncMaxSubDivEdgeLength", "Max. length of sub division edges used to sync in multiplayer [m]", 1.35)
	schema:register(XMLValueType.BOOL, key .. "#allSidePlanes", "All side planes", true)
	schema:register(XMLValueType.BOOL, key .. "#retessellateTop", "Retessellate top plane for better triangulation quality", false)
	schema:register(XMLValueType.BOOL, key .. "#changeColor", "Fillplane supports color change", false)
end

-- Local values: maxDelta, maxAllowedHeapAngle, maxPhysicalSurfaceAngle, maxSurfaceDistanceError, maxSubDivEdgeLength, syncMaxSubDivEdgeLength, allSidePlanes, retessellateTop, fillPlane
function FillPlaneUtil.createFromXML(xmlFile, key, baseNode, capacity)
	if baseNode == nil then
		Logging.xmlWarning(xmlFile, "Missing node for fillplane for \'%s\'", key)
		return nil
	else
		local v7_ = xmlFile:getValue(key .. "#maxDelta", 1)
		local v8_ = xmlFile:getValue(key .. "#capacity", capacity)
		local v9_ = xmlFile:getValue(key .. "#maxAllowedHeapAngle", 35)
		local v10_ = xmlFile:getValue(key .. "#maxSurfaceDistanceError", 0.05)
		local v11_ = xmlFile:getValue(key .. "#maxSubDivEdgeLength", 0.9)
		local v12_ = xmlFile:getValue(key .. "#syncMaxSubDivEdgeLength", 1.35)
		local v13_ = xmlFile:getValue(key .. "#allSidePlanes", true)
		local v14_ = xmlFile:getValue(key .. "#retessellateTop", false)
		local v15_ = createFillPlaneShape(baseNode, "fillPlane", v8_, v7_, v9_, 0.6108652381980153, v10_, v11_, v12_, v13_, v14_)
		if v15_ == 0 or v15_ == nil then
			Logging.xmlWarning(xmlFile, "Failed to create fillplane for \'%s\'", key)
			return nil
		else
			link(baseNode, v15_)
			return v15_
		end
	end
end

-- Local values: fillPlaneMaterial
function FillPlaneUtil.assignDefaultMaterialsFromTerrain(fillPlane, terrainRootNodeId)
	if getHasClassId(fillPlane, ClassIds.SHAPE) then
		local v18_ = g_materialManager:getBaseMaterialByName("fillPlane")
		if v18_ == nil then
			Logging.error("Failed to assign material to fillplane. Base Material \'fillPlane\' not found!")
			printCallstack()
			return false
		else
			setMaterial(fillPlane, v18_, 0)
			g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(fillPlane, terrainRootNodeId, true, true, true)
			return true
		end
	else
		Logging.error("Failed to assign material to fillplane %q, node is not of type SHAPE", getName(fillPlane))
		printCallstack()
		return false
	end
end

-- Local values: textureArrayIndex
function FillPlaneUtil.setFillType(fillPlane, fillTypeIndex)
	local v21_ = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillTypeIndex)
	if v21_ ~= nil then
		setShaderParameter(fillPlane, "fillTypeId", v21_ - 1, 0, 0, 0, false)
	end
end
