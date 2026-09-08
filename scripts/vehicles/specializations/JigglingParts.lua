JigglingParts = {}
JigglingParts.JIGGLING_PART_XML_KEY = "vehicle.jigglingParts.jigglingPart(?)"

function JigglingParts.prerequisitesPresent(specializations)
	return true
end
function JigglingParts.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("JigglingParts")
	local v2_ = JigglingParts.JIGGLING_PART_XML_KEY
	v1_:register(XMLValueType.NODE_INDEX, v2_ .. "#node", "Jiggling node")
	v1_:register(XMLValueType.FLOAT, v2_ .. "#speedScale", "Speed scale", 1)
	v1_:register(XMLValueType.STRING, v2_ .. "#shaderParameter", "Shader parameter", "amplFreq")
	v1_:register(XMLValueType.STRING, v2_ .. "#shaderParameterPrev", "Shader parameter previous frame", "prevAmplFreq")
	v1_:register(XMLValueType.INT, v2_ .. "#shaderParameterComponentSpeed", "Shader component speed index", 4)
	v1_:register(XMLValueType.INT, v2_ .. "#shaderParameterComponentAmplitude", "Shader component amplitude index", 1)
	v1_:register(XMLValueType.FLOAT, v2_ .. "#amplitudeScale", "Amplitude scale", 4)
	v1_:register(XMLValueType.INT, v2_ .. "#refNodeIndex", "Ground reference node index")
	v1_:setXMLSpecializationType()
end

function JigglingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadJigglingPartsFromXML", JigglingParts.loadJigglingPartsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "isJigglingPartActive", JigglingParts.isJigglingPartActive)
	SpecializationUtil.registerFunction(vehicleType, "updateJigglingPart", JigglingParts.updateJigglingPart)
end

function JigglingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", JigglingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", JigglingParts)
end

-- Local values: spec, i, key, jigglingPart
function JigglingParts:onLoad(savegame)
	local v6_ = self.spec_jigglingParts
	v6_.parts = {}
	local v7_ = 0
	while true do
		local v8_ = string.format("vehicle.jigglingParts.jigglingPart(%d)", v7_)
		if not self.xmlFile:hasProperty(v8_) then
			break
		end
		local v9_ = {}
		if self:loadJigglingPartsFromXML(v9_, self.xmlFile, v8_) then
			local v10_ = v6_.parts
			table.insert(v10_, v9_)
		end
		v7_ = v7_ + 1
	end
	if #v6_.parts == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", JigglingParts)
	end
end

-- Local values: spec, _, jigglingPart
function JigglingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v13_ = self.spec_jigglingParts
	for _, v14_ in ipairs(v13_.parts) do
		if self:isJigglingPartActive(v14_) then
			self:updateJigglingPart(v14_, dt, true)
		elseif v14_.currentAmplitudeScale > 0 then
			self:updateJigglingPart(v14_, dt, false)
		end
	end
end

function JigglingParts:loadJigglingPartsFromXML(jigglingPart, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	jigglingPart.currentTime = 0
	jigglingPart.currentAmplitudeScale = 0
	jigglingPart.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if jigglingPart.node == nil then
		Logging.xmlWarning(self.xmlFile, "Failed to load node for jiggling part \'%s\'", key)
		return false
	end
	jigglingPart.speedScale = xmlFile:getValue(key .. "#speedScale", 1)
	jigglingPart.shaderParameter = xmlFile:getValue(key .. "#shaderParameter", "amplFreq")
	jigglingPart.shaderParameterPrev = xmlFile:getValue(key .. "#shaderParameterPrev", "prevAmplFreq")
	jigglingPart.shaderParameterComponentSpeed = xmlFile:getValue(key .. "#shaderParameterComponentSpeed", 4)
	jigglingPart.shaderParameterComponentAmplitude = xmlFile:getValue(key .. "#shaderParameterComponentAmplitude", 1)
	jigglingPart.amplitudeScale = xmlFile:getValue(key .. "#amplitudeScale", 4)
	jigglingPart.refNodeIndex = xmlFile:getValue(key .. "#refNodeIndex")
	jigglingPart.values = {
		0,
		0,
		0,
		0
	}
	return true
end

-- Local values: refNode
function JigglingParts:isJigglingPartActive(jigglingPart)
	if jigglingPart.refNodeIndex ~= nil and jigglingPart.refNode == nil then
		if self.getGroundReferenceNodeFromIndex ~= nil then
			local v21_ = self:getGroundReferenceNodeFromIndex(jigglingPart.refNodeIndex)
			if v21_ ~= nil then
				jigglingPart.refNode = v21_
			end
		end
		if jigglingPart.refNode == nil then
			Logging.xmlWarning(self.xmlFile, "Unable to find ground reference node \'%d\' for jiggling part \'%s\'", jigglingPart.refNodeIndex, getName(jigglingPart.node))
		end
		jigglingPart.refNodeIndex = nil
	end
	return (jigglingPart.refNode == nil or self:getIsGroundReferenceNodeActive(jigglingPart.refNode)) and true or false
end

-- Local values: oldX, oldY, oldZ, oldW, x, y, z, w, t
function JigglingParts:updateJigglingPart(jigglingPart, dt, groundContact)
	local v26_ = jigglingPart.values[1]
	local v27_ = jigglingPart.values[2]
	local v28_ = jigglingPart.values[3]
	local v29_ = jigglingPart.values[4]
	local v30_, v31_, v32_, v33_ = getShaderParameter(jigglingPart.node, jigglingPart.shaderParameter)
	local v34_ = jigglingPart.values
	local v35_ = jigglingPart.values
	local v36_ = jigglingPart.values
	local v37_ = jigglingPart.values
	v34_[1] = v30_
	v35_[2] = v31_
	v36_[3] = v32_
	v37_[4] = v33_
	local v38_ = dt / 1000 * jigglingPart.speedScale * self:getLastSpeed() / 20
	jigglingPart.currentTime = jigglingPart.currentTime + v38_
	jigglingPart.values[jigglingPart.shaderParameterComponentSpeed] = jigglingPart.currentTime
	if groundContact and jigglingPart.currentAmplitudeScale < 1 then
		local v39_ = jigglingPart.currentAmplitudeScale + dt / 100
		jigglingPart.currentAmplitudeScale = math.min(v39_, 1)
	elseif not groundContact and jigglingPart.currentAmplitudeScale > 0 then
		local v40_ = jigglingPart.currentAmplitudeScale - dt / 100
		jigglingPart.currentAmplitudeScale = math.max(v40_, 0)
	end
	jigglingPart.values[jigglingPart.shaderParameterComponentAmplitude] = jigglingPart.currentAmplitudeScale * jigglingPart.amplitudeScale
	setShaderParameter(jigglingPart.node, jigglingPart.shaderParameter, jigglingPart.values[1], jigglingPart.values[2], jigglingPart.values[3], jigglingPart.values[4], false)
	setShaderParameter(jigglingPart.node, jigglingPart.shaderParameterPrev, v26_, v27_, v28_, v29_, false)
end
