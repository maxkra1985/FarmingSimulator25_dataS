-- Local values: WheelVisualPart_mt
WheelVisualPart = {}
local WheelVisualPart_mt = Class(WheelVisualPart)

-- Upvalues: WheelVisualPart_mt
-- Local values: self
function WheelVisualPart.new(name, visualWheel, linkNode, customMt)
	-- upvalues: (copy) WheelVisualPart_mt
	local v6_ = customMt or WheelVisualPart_mt
	local v7_ = setmetatable({}, v6_)
	v7_.name = name
	v7_.visualWheel = visualWheel
	v7_.linkNode = linkNode
	return v7_
end

function WheelVisualPart:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
	end
end

-- Local values: visualPartXMLFile, rootName, i, materialKey, materialXMLFile, _, material, material
function WheelVisualPart:loadFromXML(xmlObject, key)
	self.filename = xmlObject:getValue(key .. "#filename")
	if self.filename == nil then
		return false
	end
	self.filename = Utils.getFilename(self.filename, self.visualWheel.baseDirectory)
	if self.filename:contains(".xml") then
		local v12_ = XMLFile.load("visualPartXML", self.filename)
		if v12_ == nil then
			xmlObject:xmlWarning(key .. "#filename", "Unable to load visual wheel part from xml file \'%s\'!", self.filename)
			return false
		end
		local v13_ = v12_:getRootName()
		self.filename = v12_:getString(v13_ .. ".file#name")
		if self.filename == nil then
			Logging.xmlError(v12_, "Unable to load visual wheel part from xml file. Missing file definition.")
			return false
		end
		self.filename = Utils.getFilename(self.filename, self.visualWheel.baseDirectory)
		if self.filename == nil then
			Logging.xmlError(v12_, "Unable to load visual wheel part from xml file. Unknown i3d file.")
			return false
		end
		if self.visualWheel.isLeft then
			self.indexPath = v12_:getString(v13_ .. ".file#leftNode")
		else
			self.indexPath = v12_:getString(v13_ .. ".file#rightNode")
		end
		if self.indexPath == nil then
			Logging.xmlError(v12_, "Unable to load visual wheel part from xml file. Missing node definition.")
			return false
		end
		v12_:delete()
	end
	if self.visualWheel.isLeft then
		self.indexPath = xmlObject:getValueAlternative(key .. "#nodeLeft", key .. "#node", self.indexPath)
	else
		self.indexPath = xmlObject:getValueAlternative(key .. "#nodeRight", key .. "#node", self.indexPath)
	end
	self.widthAndDiam = xmlObject:getValue(key .. "#widthAndDiam", nil, true)
	self.offset = xmlObject:getValue(key .. "#offset", 0)
	self.scale = xmlObject:getValue(key .. "#scale", nil, true)
	self.holeScale = xmlObject:getValue(key .. "#holeScale")
	self.mass = xmlObject:getValue(key .. "#mass")
	self.isInverted = xmlObject:getValue(key .. "#isInverted", false)
	self.materials = {}
	local v14_ = 0
	while true do
		local v15_ = string.format("%s.material(%d)", key, v14_)
		local v16_, _ = xmlObject:getXMLFileAndPropertyKey(v15_)
		if v16_ == nil then
			break
		end
		local v17_ = VehicleMaterial.new(self.visualWheel.baseDirectory)
		if v17_:loadFromXML(xmlObject, v15_, self.visualWheel.vehicle.customEnvironment) then
			local v18_ = self.materials
			table.insert(v18_, v17_)
		end
		v14_ = v14_ + 1
	end
	local v19_ = VehicleMaterial.new(self.visualWheel.baseDirectory)
	if v19_:loadShortFromXML(xmlObject, key, self.visualWheel.vehicle.customEnvironment) then
		v19_.targetMaterialSlotName = v19_.targetMaterialSlotName or self:getDefaultMaterialSlotName()
		local v20_ = self.materials
		table.insert(v20_, v19_)
	end
	self.sharedLoadRequestId = self.visualWheel.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onPartI3DLoaded, self)
	return true
end

-- Local values: _, material
function WheelVisualPart:postLoad()
	for _, v22_ in ipairs(self.materials) do
		v22_:apply(self.node)
	end
end

function WheelVisualPart:getDefaultMaterialSlotName()
	if self.name == "innerRim" then
		return "rim_inner_mat"
	end
	if self.name == "outerRim" then
		return "rim_outer_mat"
	end
	if self.name == "additional" then
		return "rim_additional_mat"
	end
	if self.name == "connector" then
		return "rim_bolt_mat"
	end
end

-- Local values: node
function WheelVisualPart:onPartI3DLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		local v26_ = I3DUtil.indexToObject(i3dNode, self.indexPath)
		if v26_ ~= nil then
			self:setNode(v26_)
		end
		delete(i3dNode)
	end
end

-- Local values: direction, scaleX, scaleZY
function WheelVisualPart:setNode(node)
	self.node = node
	link(self.linkNode, self.node)
	local v29_ = self.visualWheel.isLeft and 1 or -1
	setTranslation(self.node, self.offset * v29_, 0, 0)
	if self.scale ~= nil then
		setScale(self.node, self.scale[1], self.scale[2], self.scale[3])
	end
	if self.widthAndDiam ~= nil then
		if self:getHasShaderParameterRec(self.node, "widthAndDiam") then
			self:setShaderParameterRec(self.node, "widthAndDiam", self.widthAndDiam[1], self.widthAndDiam[2], nil, nil)
		else
			local v30_ = MathUtil.inchToM(self.widthAndDiam[1])
			local v31_ = MathUtil.inchToM(self.widthAndDiam[2])
			setScale(self.node, v30_, v31_, v31_)
		end
	end
	if self.holeScale ~= nil and self:getHasShaderParameterRec(self.node, "widthAndDiam") then
		self:setShaderParameterRec(self.node, "widthAndDiam", nil, nil, self.holeScale, 0)
	end
	if self.isInverted then
		setRotation(self.node, 0, 0, 3.141592653589793)
	end
end

-- Local values: numChildren, i
function WheelVisualPart:setShaderParameterRec(node, shaderParameterName, x, y, z, w)
	if getHasClassId(node, ClassIds.SHAPE) then
		setShaderParameter(node, shaderParameterName, x, y, z, w, false, -1)
	end
	for v39_ = 1, getNumOfChildren(node) do
		self:setShaderParameterRec(getChildAt(node, v39_ - 1), shaderParameterName, x, y, z, w)
	end
end

-- Local values: numChildren, i
function WheelVisualPart:getHasShaderParameterRec(node, shaderParameterName)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "widthAndDiam") then
		return true
	end
	for v43_ = 1, getNumOfChildren(node) do
		if self:getHasShaderParameterRec(getChildAt(node, v43_ - 1), shaderParameterName) then
			return true
		end
	end
	return false
end

function WheelVisualPart:getMass()
	return self.mass or 0
end

function WheelVisualPart.registerXMLPaths(schema, key, name)
	schema:register(XMLValueType.STRING, key .. "#filename", name .. " - Path to i3d file")
	schema:register(XMLValueType.STRING, key .. "#node", name .. " - Index in i3d file", "0|0")
	schema:register(XMLValueType.STRING, key .. "#nodeLeft", name .. " - Left index in i3d file", "0|0")
	schema:register(XMLValueType.STRING, key .. "#nodeRight", name .. " - Right index in i3d file", "0|0")
	schema:register(XMLValueType.VECTOR_2, key .. "#widthAndDiam", name .. " - Width and diameter")
	schema:register(XMLValueType.VECTOR_SCALE, key .. "#scale", name .. " - Scale")
	schema:register(XMLValueType.FLOAT, key .. "#holeScale", name .. " - Scale factor for hole in the rim (blue vertex color)")
	schema:register(XMLValueType.FLOAT, key .. "#offset", name .. " - Offset", false)
	schema:register(XMLValueType.FLOAT, key .. "#mass", name .. " - Mass")
	schema:register(XMLValueType.BOOL, key .. "#isInverted", name .. " - Node is inverted", false)
	VehicleMaterial.registerXMLPaths(schema, key .. ".material(?)")
	VehicleMaterial.registerShortXMLPaths(schema, key)
end
