-- Local values: FillPlane_mt
FillPlane = {}
local FillPlane_mt = Class(FillPlane)

-- Upvalues: FillPlane_mt
-- Local values: self
function FillPlane.new(customMt)
	-- upvalues: (copy) FillPlane_mt
	local v3_ = customMt or FillPlane_mt
	local v4_ = setmetatable({}, v3_)
	v4_.node = nil
	v4_.maxCapacity = 0
	v4_.moveMinY = 0
	v4_.moveMaxY = 0
	v4_.loaded = false
	v4_.colorChange = false
	return v4_
end

function FillPlane:delete() end

-- Local values: fillPlaneNode, x, y, z, rotX, _, _
function FillPlane:load(components, xmlFile, xmlNode, i3dMappings)
	local v10_ = xmlFile:getValue(xmlNode .. "#node", nil, components, i3dMappings)
	if v10_ == nil then
		return false
	end
	self.node = v10_
	local v11_, v12_, v13_ = getTranslation(self.node)
	self.moveMinY = xmlFile:getValue(xmlNode .. "#minY", v12_)
	self.moveMaxY = xmlFile:getValue(xmlNode .. "#maxY", v12_)
	self.colorChange = xmlFile:getValue(xmlNode .. "#colorChange", false)
	if self.colorChange and not getHasShaderParameter(self.node, "colorScale") then
		Logging.warning("Fillplane \'%s\' has no shader parameter \'colorScale\'. Disabled color change!", getName(self.node))
		self.colorChange = false
	end
	if self.moveMinY > self.moveMaxY then
		local v14_ = self.moveMaxY
		local v15_ = self.moveMinY
		self.moveMinY = v14_
		self.moveMaxY = v15_
		Logging.warning("Fillplane \'%s\' has inverted moveMinY and moveMaxY values. Switched values!", getName(self.node))
	end
	self.loaded = true
	setTranslation(self.node, v11_, self.moveMinY, v13_)
	local v16_, _, _ = getRotation(self.node)
	self.rotMinX = xmlFile:getValue(xmlNode .. "#minRotX", v16_)
	self.rotMaxX = xmlFile:getValue(xmlNode .. "#maxRotX", v16_)
	self.changeVisibility = xmlFile:getValue(xmlNode .. "#changeVisibility", false)
	setVisibility(self.node, not self.changeVisibility)
	return true
end

-- Local values: y, x, oldY, z, rotX
function FillPlane:setState(state)
	if not self.loaded then
		return false
	end
	local v19_ = MathUtil.lerp(self.moveMinY, self.moveMaxY, state)
	local v20_, v21_, v22_ = getTranslation(self.node)
	setTranslation(self.node, v20_, v19_, v22_)
	local v23_ = MathUtil.lerp(self.rotMinX, self.rotMaxX, state)
	setRotation(self.node, v23_, 0, 0)
	setVisibility(self.node, not self.changeVisibility or state > 0)
	return v21_ ~= v19_
end

function FillPlane:setFillType(fillTypeIndex)
	if self.loaded and FillPlaneUtil.assignDefaultMaterialsFromTerrain(self.node, g_terrainNode) then
		FillPlaneUtil.setFillType(self.node, fillTypeIndex)
		setShaderParameter(self.node, "isCustomShape", 1, 0, 0, 0, false)
	end
end

function FillPlane:setColorScale(colorScale)
	if self.loaded then
		setShaderParameter(self.node, "colorScale", colorScale[1], colorScale[2], colorScale[3], 0, false)
	end
end

function FillPlane.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Fill plane node")
	schema:register(XMLValueType.FLOAT, basePath .. "#minY", "Fill plane min y")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxY", "Fill plane max y")
	schema:register(XMLValueType.ANGLE, basePath .. "#minRotX", "Fill plane min rotation x")
	schema:register(XMLValueType.ANGLE, basePath .. "#maxRotX", "Fill plane max rotation x")
	schema:register(XMLValueType.BOOL, basePath .. "#changeVisibility", "Hide node if state is zero")
	schema:register(XMLValueType.BOOL, basePath .. "#colorChange", "Fill plane color change", false)
end
