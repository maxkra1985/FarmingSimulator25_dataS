Brand = nil
BrandManager = {}
local BrandManager_mt = Class(BrandManager, AbstractManager)
function BrandManager.new(customMt)
	local self = AbstractManager.new(customMt or BrandManager_mt)
	addConsoleCommand("gsBrandUsageList", "Prints a list of all used brands", "consoleCommandBrandUsageList", self)
	return self
end
function BrandManager:initDataStructures()
	self.numOfBrands = 0
	self.nameToIndex = {}
	self.nameToBrand = {}
	self.indexToBrand = {}
	Brand = self.nameToIndex
end
function BrandManager:loadMapData(missionInfo)
	BrandManager:superClass().loadMapData(self)
	local xmlFile = XMLFile.load("brandsXML", "dataS/brands.xml")
	for _, brandKey in xmlFile:iterator("brands.brand") do
		local name = xmlFile:getString(brandKey .. "#name")
		local title = xmlFile:getString(brandKey .. "#title")
		local image = xmlFile:getString(brandKey .. "#image")
		local imageShopOverview = xmlFile:getString(brandKey .. "#imageShopOverview")
		local imageOffset = xmlFile:getFloat(brandKey .. "#imageOffset")
		if title ~= nil and string.startsWith(title, "$l10n_") then
			title = g_i18n:getText(title:sub(7))
		end
		self:addBrand(name, title, image, "", false, imageShopOverview, imageOffset)
	end
	xmlFile:delete()
	return true
end
function BrandManager:addBrand(name, title, imageFilename, baseDir, isMod, imageShopOverview, imageOffset)
	if name == nil or name == "" then
		Logging.warning("Could not register brand. Name is missing or empty!")
		return false
	end
	if title == nil or title == "" then
		Logging.warning("Could not register brand '%s'. Title is missing or empty!", name)
		return false
	end
	if imageFilename == nil or imageFilename == "" then
		Logging.warning("Could not register brand '%s'. Image is missing or empty!", name)
		return false
	end
	if baseDir == nil then
		Logging.warning("Could not register brand '%s'. Base directory not defined!", name)
		return false
	else
		if imageShopOverview == nil then
			imageShopOverview = imageFilename
		end
		name = string.upper(name)
		if ClassUtil.getIsValidIndexName(name) then
			if self.nameToIndex[name] == nil then
				self.numOfBrands = self.numOfBrands + 1
				self.nameToIndex[name] = self.numOfBrands
				local brand = {}
				brand.index = self.numOfBrands
				brand.name = name
				brand.image = Utils.getFilename(imageFilename, baseDir)
				brand.imageShopOverview = Utils.getFilename(imageShopOverview, baseDir)
				brand.title = title
				brand.isMod = isMod
				brand.imageOffset = imageOffset or 0
				self.nameToBrand[name] = brand
				self.indexToBrand[self.numOfBrands] = brand
				return brand
			else
				return nil
			end
		end
		Logging.warning("Invalid brand name '" .. tostring(name) .. "'! Only capital letters allowed!")
		return nil
	end
end
function BrandManager:getBrandByIndex(brandIndex)
	if brandIndex ~= nil then
		return self.indexToBrand[brandIndex]
	else
		return nil
	end
end
function BrandManager:getBrandIconByIndex(brandIndex)
	if brandIndex ~= nil and self.indexToBrand[brandIndex] ~= nil then
		return self.indexToBrand[brandIndex].image
	end
	return nil
end
function BrandManager:getBrandByName(brandName)
	if brandName ~= nil then
		return self.nameToBrand[string.upper(brandName)]
	else
		return nil
	end
end
function BrandManager:getBrandIndexByName(brandName)
	if brandName ~= nil then
		if ClassUtil.getIsValidIndexName(brandName) then
			local brandIndex = self.nameToIndex[string.upper(brandName)]
			if brandIndex == nil then
				local suggestions = Utils.getClosestMatchingString(brandName, table.toList(self.nameToBrand), 3) and string.format(" Did you mean '%s'?", bestMatch) or ""
				Logging.warning("'%s' is an unknown brand!%s Using 'LIZARD' instead!", brandName, suggestions)
				return Brand.LIZARD
			else
				return brandIndex
			end
		end
		Logging.warning("Invalid brand name '" .. brandName .. "'! Only capital letters and underscores allowed. Using Lizard instead.")
		return Brand.LIZARD
	else
		return nil
	end
end
function BrandManager:consoleCommandBrandUsageList()
	local storeItems = g_storeManager:getItems()
	local alwaysUsedBrands = { "BKT", "CONTINENTAL", "ELTEN", "LELY", "MICHELIN", "MITAS", "NOKIAN", "OLOFSFORS", "STRAUSS", "TRELLEBORG" }
	local usedBrands = {}
	local unusedBrands = {}
	for brandIndex, brand in pairs(self.indexToBrand) do
		local found = false
		for _, alwaysUsedBrand in ipairs(alwaysUsedBrands) do
			if alwaysUsedBrand == brand.name then
				table.insert(usedBrands, brand.title)
				found = true
				break
			end
		end
		if not found then
			for _, storeItem in ipairs(storeItems) do
				if storeItem.brandIndex == brandIndex then
					table.insert(usedBrands, brand.title)
					found = true
					break
				end
			end
		end
		if found then
			continue
		end
		table.insert(unusedBrands, brand.title)
	end
	table.sort(usedBrands)
	table.sort(unusedBrands)
	local str = "\n"
	local usedBrandList = table.concat(usedBrands, "\n")
	str = str .. string.format("Brands used in store items (%d):\n", #usedBrands)
	str = str .. usedBrandList
	str = str .. "\n\n\n"
	local unusedBrandList = table.concat(unusedBrands, "\n")
	str = str .. string.format("Brands NOT used in store items (%d):\n", #unusedBrands)
	str = str .. unusedBrandList
	str = str .. "\n\n"
	print(str)
end
g_brandManager = BrandManager.new()
