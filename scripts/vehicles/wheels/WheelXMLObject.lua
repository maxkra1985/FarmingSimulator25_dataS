-- Local values: WheelXMLObject_mt
WheelXMLObject = {}
local WheelXMLObject_mt = Class(WheelXMLObject)

-- Upvalues: WheelXMLObject_mt
-- Local values: self, _
function WheelXMLObject.new(xmlFile, baseKey, configIndex, wheelKey, indexToParentIndex)
	-- upvalues: (copy) WheelXMLObject_mt
	local v7_ = WheelXMLObject_mt
	local v8_ = setmetatable({}, v7_)
	v8_.xmlFile = xmlFile
	v8_.baseKey = baseKey
	v8_.configIndex = configIndex
	v8_.baseWheelKey = wheelKey
	v8_.wheelKey = wheelKey
	v8_.indexToParentIndex = indexToParentIndex
	local _, v9_ = Utils.getModNameAndBaseDirectory(v8_.xmlFile.filename)
	v8_.baseDirectory = v9_
	v8_:setXMLLoadKey("")
	return v8_
end

function WheelXMLObject:delete()
	if self.externalXMLFile ~= nil then
		self.externalXMLFile:delete()
		self.externalXMLFile = nil
	end
end

-- Local values: key, value, altKey, parentIndex, altKey, altKey
function WheelXMLObject:getXMLFileAndKey(configIndex, attributeKey, altAttributeKey, ignoreExternalFile)
	local v16_ = self.baseKey
	local v17_ = configIndex - 1
	local v18_ = v16_ .. "(" .. tostring(v17_) .. ")" .. self.wheelKey .. attributeKey
	if self.xmlFile:getString(v18_) ~= nil then
		return self.xmlFile, v18_
	end
	if altAttributeKey ~= nil then
		local v19_ = self.baseKey
		local v20_ = configIndex - 1
		local v21_ = v19_ .. "(" .. tostring(v20_) .. ")" .. self.wheelKey .. altAttributeKey
		if self.xmlFile:getString(v21_) ~= nil then
			return self.xmlFile, v21_
		end
	end
	local v22_ = self.indexToParentIndex[configIndex]
	if v22_ ~= nil then
		return self:getXMLFileAndKey(v22_, attributeKey, altAttributeKey, ignoreExternalFile)
	end
	if self.externalFilename ~= nil and not ignoreExternalFile then
		if self.externalXMLFile == nil and not self:loadExternalXMLFile() then
			return nil
		end
		if self.externalConfigKey ~= nil then
			local v23_ = self.externalConfigKey .. attributeKey
			if self.externalXMLFile:getString(v23_) ~= nil then
				return self.externalXMLFile, v23_
			end
			if altAttributeKey ~= nil then
				local v24_ = self.externalConfigKey .. altAttributeKey
				if self.externalXMLFile:getString(v24_) ~= nil then
					return self.externalXMLFile, v24_
				end
			end
		end
		local v25_ = "wheel.default" .. attributeKey
		if self.externalXMLFile:getString(v25_) ~= nil then
			return self.externalXMLFile, v25_
		end
		if altAttributeKey ~= nil then
			local v26_ = "wheel.default" .. altAttributeKey
			if self.externalXMLFile:getString(v26_) ~= nil then
				return self.externalXMLFile, v26_
			end
		end
	end
	return nil
end

-- Local values: key, parentIndex
function WheelXMLObject:getXMLFileAndPropertyKey(property, configIndex)
	local v30_ = configIndex or self.configIndex
	local v31_ = self.baseKey
	local v32_ = v30_ - 1
	local v33_ = v31_ .. "(" .. tostring(v32_) .. ")" .. self.wheelKey .. property
	if self.xmlFile:hasProperty(v33_) then
		return self.xmlFile, v33_
	end
	local v34_ = self.indexToParentIndex[v30_]
	if v34_ ~= nil then
		return self:getXMLFileAndPropertyKey(property, v34_)
	end
	if self.externalFilename ~= nil then
		if self.externalXMLFile == nil and not self:loadExternalXMLFile() then
			return nil
		end
		if self.externalConfigKey ~= nil then
			local v35_ = self.externalConfigKey .. property
			if self.externalXMLFile:hasProperty(v35_) then
				return self.externalXMLFile, v35_
			end
		end
		local v36_ = "wheel.default" .. property
		if self.externalXMLFile:hasProperty(v36_) then
			return self.externalXMLFile, v36_
		end
	end
	return nil
end
function WheelXMLObject.getValue(p37_, p38_, ...)
	local v39_, v40_ = p37_:getXMLFileAndKey(p37_.configIndex, p38_)
	if v39_ == nil then
		local v41_ = p37_.baseKey
		local v42_ = p37_.configIndex - 1
		local v43_ = v41_ .. "(" .. tostring(v42_) .. ")" .. p37_.wheelKey .. p38_
		return p37_.xmlFile:getValue(v43_, ...)
	elseif v39_:getString(v40_) == "-" then
		return nil
	else
		return v39_:getValue(v40_, ...)
	end
end
function WheelXMLObject.getLocalValue(p44_, p45_, ...)
	local v46_, v47_ = p44_:getXMLFileAndKey(p44_.configIndex, p45_, nil, true)
	if v46_ == nil then
		local v48_ = p44_.baseKey
		local v49_ = p44_.configIndex - 1
		local v50_ = v48_ .. "(" .. tostring(v49_) .. ")" .. p44_.wheelKey .. p45_
		return p44_.xmlFile:getValue(v50_, ...)
	elseif v46_:getString(v47_) == "-" then
		return nil
	else
		return v46_:getValue(v47_, ...)
	end
end
function WheelXMLObject.getValueAlternative(p51_, p52_, p53_, ...)
	local v54_, v55_ = p51_:getXMLFileAndKey(p51_.configIndex, p52_, p53_)
	if v54_ == nil then
		local v56_ = p51_.baseKey
		local v57_ = p51_.configIndex - 1
		local v58_ = v56_ .. "(" .. tostring(v57_) .. ")" .. p51_.wheelKey .. p52_
		return p51_.xmlFile:getValue(v58_, ...)
	elseif v54_:getString(v55_) == "-" then
		return nil
	else
		return v54_:getValue(v55_, ...)
	end
end
function WheelXMLObject.getValueStatic(p59_, p60_, p61_, p62_, p63_, p64_, ...)
	local v65_ = p59_ - 1
	local v66_ = p62_ .. "(" .. tostring(v65_) .. ")" .. p63_ .. p64_
	local v67_ = p61_:getString(v66_)
	if v67_ == nil then
		local v68_ = p60_[p59_]
		if v68_ ~= nil then
			return WheelXMLObject.getValueStatic(v68_, p60_, p61_, p62_, p63_, p64_, ...)
		end
		local v69_ = p59_ - 1
		return p61_:getValue(p62_ .. "(" .. tostring(v69_) .. ")" .. p63_ .. p64_, ...)
	elseif v67_ == "-" then
		return nil
	else
		return p61_:getValue(v66_, ...)
	end
end
function WheelXMLObject.xmlWarning(p70_, p71_, p72_, ...)
	local v73_ = Logging.xmlWarning
	local v74_ = p70_.xmlFile
	local v75_ = p70_.baseKey
	local v76_ = p70_.configIndex - 1
	v73_(v74_, p72_ .. " (" .. v75_ .. "(" .. tostring(v76_) .. ")" .. p70_.wheelKey .. p71_ .. ")", ...)
end

-- Local values: baseKey
function WheelXMLObject:checkDeprecatedXMLElements(oldAttributeKey, newAttribute)
	local v80_ = self.baseKey
	local v81_ = self.configIndex - 1
	local v82_ = v80_ .. "(" .. tostring(v81_) .. ")" .. self.wheelKey
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v82_ .. oldAttributeKey, v82_ .. newAttribute)
end

-- Local values: filename, configId
function WheelXMLObject:setXMLLoadKey(key, alternativeFilename)
	self.wheelKey = self.baseWheelKey .. key
	local v86_ = self:getLocalValue("#filename", alternativeFilename)
	if v86_ == nil or v86_ == "" then
		if self.externalXMLFile ~= nil then
			self.externalXMLFile:delete()
			self.externalXMLFile = nil
		end
		self.externalFilename = nil
		self.externalConfigId = nil
	else
		self:setExternalFilename(v86_, (self:getLocalValue("#configId", "default")))
	end
end

function WheelXMLObject:setExternalFilename(externalFilename, configId)
	local v90_ = Utils.getFilename(externalFilename, self.baseDirectory)
	if v90_ ~= self.externalFilename or configId ~= self.externalConfigId then
		self.externalFilename = v90_
		self.externalConfigId = configId
		if self.externalXMLFile ~= nil then
			self.externalXMLFile:delete()
			self.externalXMLFile = nil
		end
		self.externalWheelName = nil
	end
end

-- Local values: xmlFile
function WheelXMLObject:loadExternalXMLFile()
	if self.externalXMLFile ~= nil then
		self.externalXMLFile:delete()
		self.externalXMLFile = nil
	end
	local v_u_92_ = XMLFile.load("wheelXML", self.externalFilename, Wheels.xmlSchema)
	if v_u_92_ == nil then
		self.externalFilename = nil
		self.externalXMLFile = nil
		self.externalConfigId = nil
		return false
	else
		self.externalXMLFile = v_u_92_
		self.externalWheelName = self.externalXMLFile:getValue("wheel.metadata#name")
		v_u_92_:iterate("wheel.configurations.configuration", function(_, p93_)
			-- upvalues: (copy) v_u_92_, (copy) self
			if v_u_92_:getValue(p93_ .. "#id") == self.externalConfigId then
				self.externalConfigKey = p93_
			end
		end)
		return true
	end
end
WheelXMLObject.wheelMassCache = {}

-- Local values: vehicleXMLMass, mass, mass, name, _, i, keyAdditional, xmlFile, _
function WheelXMLObject:cacheWheelMass()
	local v95_ = self:getLocalValue(".physics#mass", nil)
	if v95_ ~= nil then
		return v95_
	end
	if self.externalFilename == nil then
		return 0.1
	end
	if WheelXMLObject.wheelMassCache[self.externalFilename] == nil then
		WheelXMLObject.wheelMassCache[self.externalFilename] = {}
	end
	local v96_ = WheelXMLObject.wheelMassCache[self.externalFilename][self.externalConfigId]
	if v96_ ~= nil then
		return v96_
	end
	local v97_ = self:getValue(".physics#mass", 0.1)
	for v98_, _ in pairs(WheelVisual.PARTS) do
		local v99_ = 0
		while true do
			local v100_ = string.format(".%s(%d)", v98_, v99_)
			local v101_, _ = self:getXMLFileAndPropertyKey(v100_)
			if v101_ == nil then
				break
			end
			v97_ = v97_ + self:getValue(v100_ .. "#mass", 0)
			v99_ = v99_ + 1
		end
	end
	if self.externalFilename == nil or self.externalConfigId == nil then
		return 0
	end
	WheelXMLObject.wheelMassCache[self.externalFilename][self.externalConfigId] = v97_
	return v97_
end
