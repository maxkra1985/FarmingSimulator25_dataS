HandToolStorable = {}

-- Local values: basePath
function HandToolStorable.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolStorable")
	xmlSchema:register(XMLValueType.STRING, "handTool.storable.holderType(?)#type", "The type of holder that can be used", nil, true)
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.storable.holderType(?)#node", "The node used to orient the tool in the holder")
	xmlSchema:setXMLSpecializationType()
end

function HandToolStorable.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "getHolsterNodeByType", HandToolStorable.getHolsterNodeByType)
end

function HandToolStorable.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolStorable)
end

function HandToolStorable.prerequisitesPresent(specializations)
	return true
end

-- Local values: spec, _, key, holderType, holderNode
function HandToolStorable:onLoad(xmlFile)
	local v6_ = self.spec_storable
	v6_.holderHolsterNodes = {}
	for _, v7_ in xmlFile:iterator("handTool.storable.holderType") do
		local v8_ = xmlFile:getValue(v7_ .. "#type", nil)
		if v8_ == nil then
			Logging.xmlError(xmlFile, "HandToolStorable has a holder type with a missing type!")
		else
			local v9_ = xmlFile:getValue(v7_ .. "#node", nil, self.components, self.i3dMappings)
			if v9_ ~= nil then
				v6_.holderHolsterNodes[v8_] = v9_
			end
		end
	end
end

-- Local values: spec
function HandToolStorable:getHolsterNodeByType(typeName)
	local v12_ = self.spec_storable
	if v12_.holderHolsterNodes == nil then
		return nil
	else
		return v12_.holderHolsterNodes[typeName]
	end
end
