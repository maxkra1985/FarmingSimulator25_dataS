-- Local values: GuiProfile_mt
GuiProfile = {}
local GuiProfile_mt = Class(GuiProfile)

-- Upvalues: GuiProfile_mt
-- Local values: self
function GuiProfile.new(profiles, traits)
	-- upvalues: (copy) GuiProfile_mt
	local v4_ = GuiProfile_mt
	local v5_ = setmetatable({}, v4_)
	v5_.values = {}
	v5_.name = ""
	v5_.profiles = profiles
	v5_.traits = traits
	v5_.parent = nil
	return v5_
end

-- Local values: name, traitsStr, traitNames, i, traitName, trait, traitValueName, value, numElements, oldFormatCount, i, valueName, valueKey, value, preset
function GuiProfile:loadFromXML(xmlFile, key, presets, isTrait, isVariant)
	local v12_ = getXMLString(xmlFile, key .. "#name")
	if v12_ == nil then
		Logging.xmlWarning(xmlFile, "Missing name for a profile in XML file %s at path %s", getXMLFilename(xmlFile), key)
		return false
	end
	self.name = v12_
	self.isTrait = isTrait or false
	self.parent = getXMLString(xmlFile, key .. "#extends")
	self.isVariant = isVariant
	if self.parent == self.name then
		error("Profile " .. v12_ .. " extends itself")
	end
	if not isTrait then
		local v13_ = getXMLString(xmlFile, key .. "#with")
		if v13_ ~= nil then
			local v14_ = string.split(string.trim(v13_), " ")
			for _, v15_ in ipairs(v14_) do
				local v16_ = self.traits[v15_]
				if v16_ == nil then
					Logging.xmlWarning(xmlFile, "Trait-profile \'%s\' not found for trait \'%s\' at \'%s\'", v15_, self.name, key)
				else
					for v17_, v18_ in pairs(v16_.values) do
						self.values[v17_] = v18_
					end
				end
			end
		end
	end
	local v19_ = 0
	for v20_ = 0, getXMLNumOfChildren(xmlFile, key) - 1 do
		local v21_ = getXMLElementName(xmlFile, string.format("%s.*(%i)", key, v20_))
		local v22_ = key .. string.format(".%s(0)#value", v21_)
		if v21_ == "Value" then
			v21_ = getXMLString(xmlFile, key .. string.format(".Value(%i)#name", v19_))
			v22_ = key .. string.format(".Value(%i)#value", v19_)
			v19_ = v19_ + 1
			Logging.xmlWarning(xmlFile, "Gui profile \'%s\' still uses old format, please convert it to the new one", v21_)
		end
		local v23_ = getXMLString(xmlFile, v22_)
		if v21_ == nil or (v23_ == nil or v21_ == "Variant") then
			break
		end
		if v23_:startsWith("$preset_") then
			local v24_ = string.gsub(v23_, "$preset_", "")
			if presets[v24_] == nil then
				Logging.xmlWarning(xmlFile, "Preset \'%s\' it profile \'%s\' at \'%s\' is not defined", v24_, v12_, v22_)
			else
				v23_ = presets[v24_]
			end
		end
		self.values[v21_] = v23_
	end
	return true
end

-- Local values: ret, parentProfile
function GuiProfile:getValue(name, default)
	if self.values[name .. g_baseUIPostfix] ~= nil and self.values[name .. g_baseUIPostfix] ~= "nil" then
		return self.values[name .. g_baseUIPostfix]
	end
	if self.values[name] ~= nil and self.values[name] ~= "nil" then
		return self.values[name]
	end
	if self.parent ~= nil then
		local v28_
		if self.isVariant then
			v28_ = self.profiles[self.parent]
		else
			v28_ = g_gui:getProfile(self.parent)
		end
		if v28_ ~= nil and v28_ ~= "nil" then
			return v28_:getValue(name, default)
		end
		Logging.warning("Parent-profile \'%s\' not found for profile \'%s\'", self.parent, self.name)
	end
	return default
end

-- Local values: value, ret
function GuiProfile:getBool(name, default)
	local v32_ = self:getValue(name)
	if v32_ ~= nil and v32_ ~= "nil" then
		default = string.lower(v32_) == "true"
	end
	return default
end

-- Local values: value, ret
function GuiProfile:getNumber(name, default)
	local v36_ = self:getValue(name)
	if v36_ ~= nil and v36_ ~= "nil" then
		default = tonumber(v36_)
	end
	return default
end
