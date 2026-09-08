-- Local values: BrandManager_mt
Brand = nil
BrandManager = {}
local BrandManager_mt = Class(BrandManager, AbstractManager)

-- Upvalues: BrandManager_mt
-- Local values: self
function BrandManager.new(customMt)
	-- upvalues: (copy) BrandManager_mt
	local v3_ = AbstractManager.new(customMt or BrandManager_mt)
	addConsoleCommand("gsBrandUsageList", "Prints a list of all used brands", "consoleCommandBrandUsageList", v3_)
	return v3_
end

function BrandManager:initDataStructures()
	self.numOfBrands = 0
	self.nameToIndex = {}
	self.nameToBrand = {}
	self.indexToBrand = {}
	Brand = self.nameToIndex
end

-- Local values: xmlFile, _, brandKey, name, title, image, imageShopOverview, imageOffset
function BrandManager:loadMapData(missionInfo)
	BrandManager:superClass().loadMapData(self)
	local v6_ = XMLFile.load("brandsXML", "dataS/brands.xml")
	for _, v7_ in v6_:iterator("brands.brand") do
		local v8_ = v6_:getString(v7_ .. "#name")
		local v9_ = v6_:getString(v7_ .. "#title")
		local v10_ = v6_:getString(v7_ .. "#image")
		local v11_ = v6_:getString(v7_ .. "#imageShopOverview")
		local v12_ = v6_:getFloat(v7_ .. "#imageOffset")
		if v9_ ~= nil and string.startsWith(v9_, "$l10n_") then
			v9_ = g_i18n:getText(v9_:sub(7))
		end
		self:addBrand(v8_, v9_, v10_, "", false, v11_, v12_)
	end
	v6_:delete()
	return true
end

-- Local values: brand
function BrandManager:addBrand(name, title, imageFilename, baseDir, isMod, imageShopOverview, imageOffset)
	if name == nil or name == "" then
		Logging.warning("Could not register brand. Name is missing or empty!")
		return false
	end
	if title == nil or title == "" then
		Logging.warning("Could not register brand \'%s\'. Title is missing or empty!", name)
		return false
	end
	if imageFilename == nil or imageFilename == "" then
		Logging.warning("Could not register brand \'%s\'. Image is missing or empty!", name)
		return false
	end
	if baseDir == nil then
		Logging.warning("Could not register brand \'%s\'. Base directory not defined!", name)
		return false
	end
	if imageShopOverview == nil then
		imageShopOverview = imageFilename
	end
	local v21_ = string.upper(name)
	if not ClassUtil.getIsValidIndexName(v21_) then
		Logging.warning("Invalid brand name \'" .. tostring(v21_) .. "\'! Only capital letters allowed!")
		return nil
	end
	if self.nameToIndex[v21_] ~= nil then
		return nil
	end
	self.numOfBrands = self.numOfBrands + 1
	self.nameToIndex[v21_] = self.numOfBrands
	local v22_ = {
		["index"] = self.numOfBrands,
		["name"] = v21_,
		["image"] = Utils.getFilename(imageFilename, baseDir),
		["imageShopOverview"] = Utils.getFilename(imageShopOverview, baseDir),
		["title"] = title,
		["isMod"] = isMod,
		["imageOffset"] = imageOffset or 0
	}
	self.nameToBrand[v21_] = v22_
	self.indexToBrand[self.numOfBrands] = v22_
	return v22_
end

function BrandManager:getBrandByIndex(brandIndex)
	if brandIndex == nil then
		return nil
	else
		return self.indexToBrand[brandIndex]
	end
end

function BrandManager:getBrandIconByIndex(brandIndex)
	if brandIndex == nil or self.indexToBrand[brandIndex] == nil then
		return nil
	else
		return self.indexToBrand[brandIndex].image
	end
end

function BrandManager:getBrandByName(brandName)
	if brandName == nil then
		return nil
	else
		return self.nameToBrand[string.upper(brandName)]
	end
end

-- Local values: brandIndex, bestMatch, suggestions
function BrandManager:getBrandIndexByName(brandName)
	if brandName == nil then
		return nil
	end
	if not ClassUtil.getIsValidIndexName(brandName) then
		Logging.warning("Invalid brand name \'" .. brandName .. "\'! Only capital letters and underscores allowed. Using Lizard instead.")
		return Brand.LIZARD
	end
	local v31_ = self.nameToIndex[string.upper(brandName)]
	if v31_ ~= nil then
		return v31_
	end
	local v32_ = Utils.getClosestMatchingString(brandName, table.toList(self.nameToBrand), 3)
	local v33_ = v32_ and string.format(" Did you mean \'%s\'?", v32_) or ""
	Logging.warning("\'%s\' is an unknown brand!%s Using \'LIZARD\' instead!", brandName, v33_)
	return Brand.LIZARD
end

-- Local values: storeItems, alwaysUsedBrands, usedBrands, unusedBrands, brandIndex, brand, found, _, alwaysUsedBrand, _, storeItem, str, usedBrandList, unusedBrandList
function BrandManager:consoleCommandBrandUsageList()
	local v35_ = g_storeManager:getItems()
	local v36_ = {
		"BKT",
		"CONTINENTAL",
		"ELTEN",
		"LELY",
		"MICHELIN",
		"MITAS",
		"NOKIAN",
		"OLOFSFORS",
		"STRAUSS",
		"TRELLEBORG"
	}
	local v37_ = {}
	local v38_ = {}
	for v39_, v40_ in pairs(self.indexToBrand) do
		local v41_ = false
		for _, v42_ in ipairs(v36_) do
			if v42_ == v40_.name then
				local v43_ = v40_.title
				table.insert(v37_, v43_)
				v41_ = true
				break
			end
		end
		if not v41_ then
			for _, v44_ in ipairs(v35_) do
				if v44_.brandIndex == v39_ then
					local v45_ = v40_.title
					table.insert(v37_, v45_)
					v41_ = true
					break
				end
			end
		end
		if not v41_ then
			local v46_ = v40_.title
			table.insert(v38_, v46_)
		end
	end
	table.sort(v37_)
	table.sort(v38_)
	local v47_ = table.concat(v37_, "\n")
	local v48_ = (("\n" .. string.format("Brands used in store items (%d):\n", #v37_)) .. v47_) .. "\n\n\n"
	local v49_ = table.concat(v38_, "\n")
	local v50_ = ((v48_ .. string.format("Brands NOT used in store items (%d):\n", #v38_)) .. v49_) .. "\n\n"
	print(v50_)
end
g_brandManager = BrandManager.new()
