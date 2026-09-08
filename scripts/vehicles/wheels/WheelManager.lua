-- Local values: WheelManager_mt
WheelManager = {}
WheelManager.DEFAULT_FILENAME = "data/shared/wheels/wheels.xml"
WheelManager.BRAND_TO_SORT_INDEX = {}
WheelManager.BRAND_TO_SORT_INDEX.TRELLEBORG = 1
WheelManager.BRAND_TO_SORT_INDEX.MICHELIN = 2
WheelManager.BRAND_TO_SORT_INDEX.CONTINENTAL = 3
WheelManager.BRAND_TO_SORT_INDEX.MITAS = 4
WheelManager.BRAND_TO_SORT_INDEX.BKT = 5
WheelManager.BRAND_TO_SORT_INDEX.VREDESTEIN = 6
WheelManager.BRAND_TO_SORT_INDEX.NOKIAN = 7
local WheelManager_mt = Class(WheelManager, AbstractManager)

-- Upvalues: WheelManager_mt
function WheelManager.new(customMt)
	-- upvalues: (copy) WheelManager_mt
	return AbstractManager.new(customMt or WheelManager_mt)
end

function WheelManager:initDataStructures()
	self.wheels = {}
	self.wheelsByBasePath = {}
	self.sortedTypedWheels = {}
	self.wheelFilenameToAttributes = {}
end

-- Local values: wheelsXMLFile
function WheelManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	WheelManager:superClass().loadMapData(self)
	self.baseDirectory = baseDirectory
	local v6_ = XMLFile.load("wheelsXML", WheelManager.DEFAULT_FILENAME)
	if v6_ ~= nil then
		self:loadWheelsFromXML(v6_, "wheels", baseDirectory)
		v6_:delete()
	end
	return true
end

function WheelManager:loadWheelsFromXML(xmlFile, key, baseDirectory)
	xmlFile:iterate(key .. ".wheel", function(_, p11_)
		-- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) self
		local v12_ = {
			["path"] = xmlFile:getString(p11_ .. "#filename")
		}
		if v12_.path == nil then
			Logging.xmlWarning(xmlFile, "Missing filename for wheel \'%s\'", p11_)
			return
		else
			v12_.path = Utils.getFilename(v12_.path, baseDirectory)
			v12_.radius = xmlFile:getFloat(p11_ .. "#radius")
			if v12_.radius == nil then
				Logging.xmlWarning(xmlFile, "Missing radius for wheel \'%s\'", p11_)
				return
			else
				v12_.width = xmlFile:getFloat(p11_ .. "#width")
				if v12_.width == nil then
					Logging.xmlWarning(xmlFile, "Missing width for wheel \'%s\'", p11_)
				else
					v12_.category = xmlFile:getString(p11_ .. "#category", "UNKNOWN")
					v12_.allowMixture = xmlFile:getBool(p11_ .. "#allowMixture", true)
					v12_.priority = xmlFile:getFloat(p11_ .. "#priority", 1)
					v12_.filename = Utils.getFilenameFromPath(v12_.path)
					v12_.filename = string.split(v12_.filename, ".")[1]
					v12_.basePath = Utils.getDirectory(v12_.path)
					local v13_ = v12_.basePath:split("/")
					v12_.wheelBrand = g_brandManager:getBrandByName(v13_[#v13_ - 2]) or g_brandManager:getBrandByIndex(Brand.NONE)
					v12_.wheelName = v13_[#v13_ - 1] or "Unknown"
					if self.wheelFilenameToAttributes[v12_.filename] == nil then
						self.wheelFilenameToAttributes[v12_.filename] = {
							["baseFilename"] = v12_.path,
							["radius"] = v12_.radius,
							["width"] = v12_.width
						}
					else
						local v14_ = self.wheelFilenameToAttributes[v12_.filename]
						local v15_ = v12_.radius - v14_.radius
						if math.abs(v15_) > 0.001 then
							Logging.xmlWarning(xmlFile, "Invalid radius for wheel \'%s\'. Does not equal the default radius for this tire size. (Base: %.3f from %s)", v12_.path, v14_.radius, v14_.baseFilename)
						end
						local v16_ = v12_.width - v14_.width
						if math.abs(v16_) > 0.001 then
							Logging.xmlWarning(xmlFile, "Invalid width for wheel \'%s\'. Does not equal the default width for this tire size. (Base: %.3f from %s)", v12_.path, v14_.width, v14_.baseFilename)
						end
					end
					local v17_ = self.wheels
					table.insert(v17_, v12_)
					if self.wheelsByBasePath[v12_.basePath] == nil then
						self.wheelsByBasePath[v12_.basePath] = {}
						local v18_ = self.sortedTypedWheels
						local v19_ = self.wheelsByBasePath[v12_.basePath]
						table.insert(v18_, v19_)
					end
					local v20_ = self.wheelsByBasePath[v12_.basePath]
					table.insert(v20_, v12_)
				end
			end
		end
	end)
	table.sort(self.sortedTypedWheels, function(p21_, p22_)
		if p21_[1].wheelBrand.name == p22_[1].wheelBrand.name then
			if p21_[1].priority == p22_[1].priority then
				return p21_[1].wheelName < p22_[1].wheelName
			else
				return p21_[1].priority > p22_[1].priority
			end
		else
			return p21_[1].wheelBrand.name < p22_[1].wheelBrand.name
		end
	end)
end

-- Local values: tireCombinations, indexByBrand, dimensionIndex, dimensionCombination, _, wheels, wheelsAllowed, brandFound, wheelFound, _, whitelistedCombination, _, name, tireCombination, wheelIndex, dimension, _, wheel, isMixed, numWheels, firstWheel, _, wheel, isAllowed, numConfigurationsByBrand, i, combination, i, otherCombination, isEqual, i, sortIndex
function WheelManager:getTiresForDimensionCombinations(dimensionCombinations, tireCategories, whitelistedCombinations, numDynamicConfigurations, customBrandOrder)
	local v29_ = {}
	local v30_ = {}
	for _, v31_ in ipairs(dimensionCombinations) do
		for _, v32_ in ipairs(self.sortedTypedWheels) do
			local v33_
			if #whitelistedCombinations > 0 then
				local v34_ = false
				local v35_ = false
				for _, v36_ in pairs(whitelistedCombinations) do
					if v36_.brand == v32_[1].wheelBrand then
						v34_ = true
						for _, v37_ in ipairs(v36_.names) do
							if v37_ == v32_[1].wheelName then
								v35_ = true
							end
						end
					end
				end
				v33_ = not v34_ or v34_ and v35_
			else
				v33_ = true
			end
			if v33_ then
				local v38_ = {
					["wheels"] = {},
					["wheelBrand"] = nil,
					["wheelSaveId"] = ""
				}
				for v39_, v40_ in ipairs(v31_) do
					for _, v41_ in ipairs(v32_) do
						if v41_.filename == v40_ and (tireCategories == nil or tireCategories[v41_.category] == true) then
							v38_.wheels[v39_] = v41_
							break
						end
						if v40_ == "-" then
							v38_.wheels[v39_] = {}
						end
					end
				end
				local v42_ = table.size(v38_.wheels)
				local v43_
				if v42_ > 0 and v42_ ~= #v31_ then
					self:fillCombinationWithMixedTires(v31_, v38_, tireCategories, whitelistedCombinations)
					v43_ = true
				else
					v43_ = false
				end
				if table.size(v38_.wheels) == #v31_ then
					local v44_ = nil
					for _, v45_ in pairs(v38_.wheels) do
						if v45_.wheelBrand ~= nil then
							v44_ = v45_
						end
					end
					local v46_ = v44_ ~= nil
					if numDynamicConfigurations ~= math.huge then
						local v47_ = 0
						for _, v48_ in ipairs(v29_) do
							if v48_.wheelBrand == v44_.wheelBrand then
								v47_ = v47_ + 1
								if numDynamicConfigurations <= v47_ then
									v46_ = false
									break
								end
							end
						end
					end
					if v43_ then
						for _, v49_ in ipairs(v29_) do
							local v50_ = true
							for v51_ = 1, #v38_.wheels do
								if v38_.wheels[v51_].path ~= v49_.wheels[v51_].path then
									v50_ = false
									break
								end
							end
							if v50_ then
								v46_ = false
							end
						end
					end
					if v46_ then
						v30_[v44_.wheelBrand] = (v30_[v44_.wheelBrand] or 0) + 1
						v38_.index = v30_[v44_.wheelBrand]
						v38_.wheelBrand = v44_.wheelBrand
						v38_.wheelSaveId = v44_.wheelBrand.name .. "_" .. v44_.wheelName
						local v52_ = 0
						if customBrandOrder ~= nil then
							v52_ = customBrandOrder[v44_.wheelBrand.name] or v52_
						end
						if v52_ == 0 then
							v52_ = 100 + (WheelManager.BRAND_TO_SORT_INDEX[v44_.wheelBrand.name] or math.huge)
						end
						v38_.sortIndex = v52_ + v38_.index * 0.01
						table.insert(v29_, v38_)
					end
				end
			end
		end
	end
	table.sort(v29_, function(p53_, p54_)
		return p53_.sortIndex < p54_.sortIndex
	end)
	return v29_
end

-- Local values: firstWheel, wheelBrand, wheelName, limitedTireNames, foundBrand, _, whitelistedCombination, _, name, _, wheels, wheelIndex, dimension, _, wheel, isAllowed, _, name
function WheelManager:fillCombinationWithMixedTires(dimensionCombination, tireCombination, tireCategories, whitelistedCombinations)
	local v60_ = tireCombination.wheels[next(tireCombination.wheels)]
	if not v60_.allowMixture then
		return
	end
	local v61_ = v60_.wheelBrand
	local v62_ = v60_.wheelName
	local v63_ = nil
	if #whitelistedCombinations > 0 then
		local v64_ = false
		for _, v65_ in pairs(whitelistedCombinations) do
			if v65_.brand == v61_ then
				v64_ = true
				for _, v66_ in ipairs(v65_.names) do
					if v66_ == v62_ then
						v63_ = v65_.names
					end
				end
			end
		end
		if v63_ == nil and v64_ then
			return
		end
	end
	for _, v67_ in ipairs(self.sortedTypedWheels) do
		for v68_, v69_ in ipairs(dimensionCombination) do
			if tireCombination.wheels[v68_] == nil then
				for _, v70_ in ipairs(v67_) do
					if v70_.allowMixture and (v70_.filename == v69_ and (v70_.wheelBrand == v61_ and (tireCategories == nil or (tireCategories[v70_.category] == true or v63_ ~= nil)))) then
						local v71_ = v63_ == nil
						if v63_ ~= nil then
							for _, v72_ in ipairs(v63_) do
								if v72_ == v70_.wheelName then
									v71_ = true
									break
								end
							end
						end
						if v71_ then
							tireCombination.wheels[v68_] = v70_
						end
					end
				end
			end
		end
	end
end

-- Local values: _, wheels, _, wheel
function WheelManager:getWheelRadiusAndWidthFromDimension(dimension)
	for _, v75_ in ipairs(self.sortedTypedWheels) do
		for _, v76_ in ipairs(v75_) do
			if v76_.filename == dimension then
				return v76_.radius, v76_.width
			end
		end
	end
	return nil, nil
end

-- Local values: _, wheels, _, wheel
function WheelManager:getWheelRadiusAndWidthFromFilename(filename)
	for _, v79_ in ipairs(self.sortedTypedWheels) do
		for _, v80_ in ipairs(v79_) do
			if v80_.path == filename then
				return v80_.radius, v80_.width
			end
		end
	end
	return nil, nil
end
g_wheelManager = WheelManager.new()
