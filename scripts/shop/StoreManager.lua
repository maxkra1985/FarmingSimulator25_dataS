-- Local values: StoreManager_mt
StoreManager = {}
local StoreManager_mt = Class(StoreManager, AbstractManager)
StoreManager.CATEGORY_TYPE = {
	["NONE"] = "",
	["VEHICLE"] = "VEHICLE",
	["TOOL"] = "TOOL",
	["OBJECT"] = "OBJECT",
	["PLACEABLE"] = "PLACEABLE"
}

-- Upvalues: StoreManager_mt
-- Local values: self
function StoreManager.new(customMt)
	-- upvalues: (copy) StoreManager_mt
	local v3_ = AbstractManager.new(customMt or StoreManager_mt)
	v3_.speciesToSchema = {}
	v3_.indexedSearch = IndexedSearch.new({
		["title"] = 10,
		["brand"] = 5,
		["author"] = 3,
		["dlcTitle"] = 3
	})
	return v3_
end

function StoreManager:initDataStructures()
	self.numOfCategories = 0
	self.numOfPacks = 0
	self.categories = {}
	self.categoryByName = {}
	self.categoryTypes = {}
	self.categoryTypesByName = {}
	self.packs = {}
	self.items = {}
	self.xmlFilenameToItem = {}
	self.modStoreItems = {}
	self.modStorePacks = {}
	self.modConstructionTabs = {}
	self.modCategoryTypes = {}
	self.specTypes = {}
	self.nameToSpecType = {}
	self.vramUsageFunctions = {}
	self.constructionCategoriesByName = {}
	self.constructionCategories = {}
	if self.indexedSearch ~= nil then
		self.indexedSearch:clear()
	end
end

function StoreManager:addSpeciesXMLSchema(species, xmlSchema)
	self.speciesToSchema[species] = xmlSchema
end

-- Local values: categoryXMLFile, _, key, _, key, _, categoryData, packsXMLFile, _, key, name, title, imageFilename, requiredDLC, _, item, _, storeItem, constructionXMLFile, defaultIconFilename, defaultRefSize, _, key, categoryName, title, iconFilename, refSize, iconUVs, iconSliceId, _, tKey, tabName, tabTitle, tabIconFilename, tabRefSize, tabIconUVs, tabIconSliceId, _, item, storeItemsFilename, mapStoreItemsFilename, _, item
function StoreManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	StoreManager:superClass().loadMapData(self)
	local v12_ = XMLFile.load("storeCategoriesXML", "dataS/storeCategories.xml")
	for _, v13_ in v12_:iterator("categories.types.type") do
		self:loadCategoryType(v12_, v13_, nil)
	end
	for _, v14_ in v12_:iterator("categories.category") do
		self:loadCategoryFromXML(v12_, v14_, "", false)
	end
	v12_:delete()
	for _, v15_ in ipairs(self.modCategoryTypes) do
		self:addCategory(v15_.name, v15_.title, v15_.imageFilename, v15_.categoryType, v15_.baseDir, v15_.insertAfter)
	end
	local v_u_16_ = XMLFile.load("storePacksXML", "dataS/storePacks.xml")
	for _, v17_ in v_u_16_:iterator("storePacks.storePack") do
		local v_u_18_ = v_u_16_:getString(v17_ .. "#name")
		local v19_ = v_u_16_:getString(v17_ .. "#title")
		local v20_ = v_u_16_:getString(v17_ .. "#image")
		if v19_ ~= nil and v19_:sub(1, 6) == "$l10n_" then
			v19_ = g_i18n:getText(v19_:sub(7))
		end
		local v21_ = v_u_16_:getString(v17_ .. "#requiredDLC")
		if v21_ == nil or g_modIsLoaded[g_uniqueDlcNamePrefix .. v21_] ~= nil then
			self:addPack(v_u_18_, v19_, v20_, "")
			v_u_16_:iterate(v17_ .. ".storeItem", function(_, p22_)
				-- upvalues: (copy) v_u_16_, (copy) self, (copy) v_u_18_, (copy) baseDirectory
				local v23_ = v_u_16_:getString(p22_)
				self:addPackItem(v_u_18_, Utils.getFilename(v23_, baseDirectory))
			end)
		else
			Logging.devInfo("Ignore storepack \'%s\' because DLC \'%s\' is not loaded", v19_, v21_)
		end
	end
	v_u_16_:delete()
	for _, v24_ in ipairs(self.modStorePacks) do
		self:addPack(v24_.name, v24_.title, v24_.imageFilename, v24_.baseDir)
		for _, v25_ in ipairs(v24_.storeItems) do
			self:addPackItem(v24_.name, v25_)
		end
	end
	if Platform.hasContruction then
		local v26_ = XMLFile.load("constructionXML", "dataS/constructionCategories.xml")
		if v26_ ~= nil then
			local v27_ = v26_:getString("constructionCategories#defaultIconFilename")
			local v28_ = v26_:getVector("constructionCategories#refSize", nil, 2) or { 1024, 1024 }
			for _, v29_ in v26_:iterator("constructionCategories.category") do
				local v30_ = v26_:getString(v29_ .. "#name")
				local v31_ = g_i18n:convertText(v26_:getString(v29_ .. "#title"))
				local v32_ = v26_:getString(v29_ .. "#iconFilename") or v27_
				local v33_ = v26_:getVector(v29_ .. "#refSize", v28_, 2)
				self:addConstructionCategory(v30_, v31_, v32_, GuiUtils.getUVs(v26_:getString(v29_ .. "#iconUVs", "0 0 1 1"), v33_), "", (v26_:getString(v29_ .. "#iconSliceId")))
				for _, v34_ in v26_:iterator(v29_ .. ".tab") do
					local v35_ = v26_:getString(v34_ .. "#name")
					local v36_ = g_i18n:convertText(v26_:getString(v34_ .. "#title"))
					local v37_ = v26_:getString(v34_ .. "#iconFilename") or v27_
					local v38_ = v26_:getVector(v34_ .. "#refSize", v28_, 2)
					self:addConstructionTab(v30_, v35_, v36_, v37_, GuiUtils.getUVs(v26_:getString(v34_ .. "#iconUVs", "0 0 1 1"), v38_), "", (v26_:getString(v34_ .. "#iconSliceId")))
				end
			end
			v26_:delete()
		end
		for _, v39_ in ipairs(self.modConstructionTabs) do
			self:addConstructionTab(v39_.categoryName, v39_.tabName, v39_.tabTitle, v39_.tabIconFilename, v39_.tabIconUVs, "", v39_.tabIconSliceId)
		end
	end
	self:loadItemsFromXML(self:getDefaultStoreItemsFilename(), "", nil)
	if xmlFile ~= nil then
		local v40_ = getXMLString(xmlFile, "map.storeItems#filename")
		if v40_ ~= nil then
			self:loadItemsFromXML(Utils.getFilename(v40_, baseDirectory), baseDirectory, missionInfo.customEnvironment)
		end
	end
	for _, v_u_41_ in ipairs(self.modStoreItems) do
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self, (copy) v_u_41_
			self:loadItem(v_u_41_.xmlFilename, v_u_41_.baseDir, v_u_41_.customEnvironment, v_u_41_.isMod, v_u_41_.isBundleItem, v_u_41_.dlcTitle, v_u_41_.extraContentId)
		end)
	end
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) self
		self.indexedSearch:build()
	end)
	addConsoleCommand("gsStoreItemsReload", "Reloads storeItem data", "consoleCommandReloadStoreItems", self)
	return true
end

function StoreManager:unloadMapData()
	StoreManager:superClass().unloadMapData(self)
	removeConsoleCommand("gsStoreItemsReload")
end

function StoreManager:getDefaultStoreItemsFilename()
	return "dataS/storeItems.xml"
end

-- Local values: xmlFile
function StoreManager:loadItemsFromXML(filename, baseDirectory, customEnvironment)
	local v_u_47_ = XMLFile.load("storeItemsXML", filename)
	if v_u_47_ ~= nil then
		v_u_47_:iterate("storeItems.storeItem", function(_, p48_)
			-- upvalues: (copy) v_u_47_, (copy) baseDirectory, (copy) self, (copy) customEnvironment
			local v_u_49_ = v_u_47_:getString(p48_ .. "#xmlFilename")
			local v_u_50_ = v_u_47_:getString(p48_ .. "#extraContentId")
			g_asyncTaskManager:addSubtask(function()
				-- upvalues: (copy) v_u_49_, (ref) baseDirectory, (ref) self, (ref) customEnvironment, (copy) v_u_50_
				local v51_ = ""
				local v52_ = Utils.getFilename(v_u_49_, baseDirectory)
				local v53_, _ = Utils.getModNameAndBaseDirectory(v52_)
				local v54_
				if v53_ == nil then
					v54_ = false
				else
					local v55_ = g_modManager:getModByName(v53_)
					if v55_ ~= nil then
						v51_ = v55_.title
					end
					v54_ = not v55_.isDLC
				end
				self:loadItem(v_u_49_, baseDirectory, customEnvironment, v54_, false, v51_, v_u_50_)
			end, string.format("StoreManager-loadItemsFromXML \'%s\'", v_u_49_))
		end)
		v_u_47_:delete()
	end
end

-- Local values: name, title, insertAfter
function StoreManager:loadCategoryType(xmlFile, key, customEnv)
	local v60_ = xmlFile:getString(key .. "#name")
	local v61_ = xmlFile:getString(key .. "#title")
	local v62_ = xmlFile:getString(key .. "#insertAfter")
	if v61_ ~= nil then
		v61_ = g_i18n:convertText(v61_, customEnv)
	end
	self:addCategoryType(v60_, v61_, v62_)
end

-- Local values: nameUpper, categoryType, needsInsert, insertAfterUpper, k, existingType
function StoreManager:addCategoryType(name, title, insertAfter)
	if string.isNilOrWhitespace(name) then
		Logging.warning("Could not register store category type. Name is missing or empty!")
		return false
	end
	if not ClassUtil.getIsValidIndexName(name) then
		Logging.warning("Could not register store category type \'%s\'. Invalid name for a category type!", name)
		return false
	end
	if string.isNilOrWhitespace(title) then
		Logging.warning("Could not register store category type \'%s\'. Title is missing or empty!", name)
		return false
	end
	local v67_ = string.upper(name)
	if self.categoryTypesByName[v67_] ~= nil then
		Logging.warning("Could not register store category type \'%s\'. Already exists!", name)
		return false
	end
	local v68_ = {
		["name"] = v67_,
		["title"] = title
	}
	local v69_ = true
	if insertAfter ~= nil then
		local v70_ = string.upper(insertAfter)
		for v71_, v72_ in ipairs(self.categoryTypes) do
			if v72_.name == v70_ then
				local v73_ = self.categoryTypes
				local v74_ = v71_ + 1
				table.insert(v73_, v74_, v68_)
				v69_ = false
				break
			end
		end
	end
	if v69_ then
		local v75_ = self.categoryTypes
		table.insert(v75_, v68_)
	end
	self.categoryTypesByName[v67_] = v68_
	return true
end

function StoreManager:getCategoryTypes()
	return self.categoryTypes
end

-- Local values: name, title, imageFilename, categoryType, insertAfter, categoryData
function StoreManager:loadCategoryFromXML(xmlFile, key, baseDir, customEnv, isMod)
	local v83_ = xmlFile:getString(key .. "#name")
	local v84_ = xmlFile:getString(key .. "#title")
	local v85_ = xmlFile:getString(key .. "#image")
	local v86_ = xmlFile:getString(key .. "#type")
	local v87_ = xmlFile:getString(key .. "#insertAfter")
	if v84_ ~= nil then
		v84_ = g_i18n:convertText(v84_, customEnv)
	end
	if isMod then
		local v88_ = self.modCategoryTypes
		table.insert(v88_, {
			["name"] = v83_,
			["title"] = v84_,
			["imageFilename"] = v85_,
			["categoryType"] = v86_,
			["baseDir"] = baseDir,
			["insertAfter"] = v87_
		})
	else
		self:addCategory(v83_, v84_, v85_, v86_, baseDir, v87_)
	end
end

-- Local values: categoryTypeNameUpper, categoryType, nameUpper, category, needsInsert, insertAfterUpper, k, existingCategory, index, _category
function StoreManager:addCategory(name, title, imageFilename, categoryTypeName, baseDir, insertAfter)
	if string.isNilOrWhitespace(name) then
		Logging.warning("Could not register store category. Name is missing or empty!")
		return false
	end
	if not ClassUtil.getIsValidIndexName(name) then
		Logging.warning("Could not register store category \'%s\'. Invalid name for a category!", name)
		return false
	end
	if string.isNilOrWhitespace(title) then
		Logging.warning("Could not register store category \'%s\'. Title is missing or empty!", name)
		return false
	end
	if string.isNilOrWhitespace(imageFilename) then
		Logging.warning("Could not register store category \'%s\'. Image is missing or empty!", name)
		return false
	end
	if baseDir == nil then
		Logging.warning("Could not register store category \'%s\'. Basedirectory not defined!", name)
		return false
	end
	if string.isNilOrWhitespace(categoryTypeName) then
		Logging.warning("Could not register store category \'%s\'. CategoryType is missing or empty!", name)
		return false
	end
	local v96_ = string.upper(categoryTypeName)
	if self.categoryTypesByName[v96_] == nil then
		Logging.warning("Could not register store category \'%s\'. CategoryType \'%s\' is not defined!", name, categoryTypeName)
		return false
	end
	local v97_ = string.upper(name)
	if GS_PLATFORM_SWITCH and name == "COINS" then
		return false
	end
	if self.categoryByName[v97_] ~= nil then
		Logging.warning("Could not register store category \'%s\'. Already exists!", name)
		return false
	end
	local v98_ = {
		["name"] = v97_,
		["title"] = title,
		["image"] = Utils.getFilename(imageFilename, baseDir),
		["type"] = v96_,
		["orderId"] = #self.categories
	}
	local v99_ = true
	if insertAfter ~= nil then
		local v100_ = string.upper(insertAfter)
		for v101_, v102_ in ipairs(self.categories) do
			if v102_.name == v100_ then
				local v103_ = self.categories
				local v104_ = v101_ + 1
				table.insert(v103_, v104_, v98_)
				v99_ = false
				for v105_, v106_ in ipairs(self.categories) do
					v106_.orderId = v105_
				end
				break
			end
		end
	end
	if v99_ then
		local v107_ = self.categories
		table.insert(v107_, v98_)
	end
	self.categoryByName[v97_] = v98_
	return true
end

function StoreManager:getCategoryByName(name)
	if name == nil then
		return nil
	else
		return self.categoryByName[string.upper(name)]
	end
end

-- Local values: category
function StoreManager:addConstructionCategory(name, title, iconFilename, iconUVs, baseDir, iconSliceId)
	local v117_ = string.upper(name)
	if self.constructionCategoriesByName[v117_] == nil then
		local v118_ = {
			["name"] = v117_,
			["title"] = title,
			["iconFilename"] = Utils.getFilename(iconFilename, baseDir),
			["iconUVs"] = iconUVs,
			["iconSliceId"] = iconSliceId,
			["tabs"] = {},
			["index"] = #self.constructionCategories + 1
		}
		local v119_ = self.constructionCategories
		table.insert(v119_, v118_)
		self.constructionCategoriesByName[v117_] = v118_
	else
		Logging.warning("Construction category \'%s\' already exists.", v117_)
	end
end

function StoreManager:getConstructionCategoryByName(name)
	if name == nil then
		return nil
	else
		return self.constructionCategoriesByName[string.upper(name)]
	end
end

-- Local values: category
function StoreManager:addConstructionTab(categoryName, name, title, iconFilename, iconUVs, baseDir, iconSliceId)
	local v130_ = self:getConstructionCategoryByName(categoryName)
	if v130_ ~= nil then
		local v131_ = v130_.tabs
		local v132_ = {
			["name"] = string.upper(name),
			["title"] = title,
			["iconFilename"] = Utils.getFilename(iconFilename, baseDir),
			["iconUVs"] = iconUVs,
			["iconSliceId"] = iconSliceId,
			["index"] = #v130_.tabs + 1
		}
		table.insert(v131_, v132_)
	end
end

-- Local values: category, i, tab
function StoreManager:getConstructionTabByName(name, categoryName)
	local v136_ = self:getConstructionCategoryByName(categoryName)
	if v136_ == nil or name == nil then
		return nil
	end
	local v137_ = string.upper(name)
	for _, v138_ in ipairs(v136_.tabs) do
		if v138_.name == v137_ then
			return v138_
		end
	end
	return nil
end

function StoreManager:getConstructionCategories()
	return self.constructionCategories
end

function StoreManager:addVRamUsageFunction(func)
	local v142_ = self.vramUsageFunctions
	table.insert(v142_, func)
end

-- Local values: specType
function StoreManager:addSpecType(name, profile, loadFunc, getValueFunc, species, relatedConfigurations, configDataFunc)
	if ClassUtil.getIsValidIndexName(name) then
		if self.nameToSpecType == nil then
			printCallstack()
		end
		if self.nameToSpecType[name] == nil then
			local v151_ = {
				["name"] = name,
				["profile"] = profile,
				["loadFunc"] = loadFunc,
				["getValueFunc"] = getValueFunc,
				["species"] = species or StoreSpecies.VEHICLE,
				["relatedConfigurations"] = relatedConfigurations,
				["configDataFunc"] = configDataFunc
			}
			self.nameToSpecType[name] = v151_
			local v152_ = self.specTypes
			table.insert(v152_, v151_)
		else
			printError("Error: spec type name \'" .. name .. "\' is already in use!")
		end
	else
		printWarning("Warning: \'" .. tostring(name) .. "\' is no valid name for a spec type!")
		return
	end
end

function StoreManager:getSpecTypes()
	return self.specTypes
end

function StoreManager:getSpecTypeByName(name)
	if ClassUtil.getIsValidIndexName(name) then
		return self.nameToSpecType[name]
	end
	printWarning("Warning: \'" .. tostring(name) .. "\' is no valid name for a spec type!")
end

-- Local values: i
function StoreManager:getSpecTypeByProfile(profile)
	for v158_ = 1, #self.specTypes do
		if self.specTypes[v158_].profile == profile then
			return self.specTypes[v158_]
		end
	end
	return nil
end

-- Local values: otherItem, isUnlocked, author, customEnvironment, mod, brand, brandName
function StoreManager:addItem(storeItem)
	local v161_ = self.xmlFilenameToItem[storeItem.xmlFilenameLower]
	if v161_ ~= nil then
		if v161_.isBundleItem and not storeItem.isBundleItem then
			v161_.isBundleItem = storeItem.isBundleItem
			v161_.showInStore = storeItem.showInStore
		end
		return false
	end
	local v162_ = self.items
	table.insert(v162_, storeItem)
	storeItem.id = #self.items
	self.xmlFilenameToItem[storeItem.xmlFilenameLower] = storeItem
	local v163_ = (storeItem.extraContentId == nil or g_extraContentSystem == nil) and true or g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)
	if not storeItem.isBundleItem and (v163_ and (storeItem.showInStore and (storeItem.species == StoreSpecies.VEHICLE or storeItem.species == StoreSpecies.HANDTOOL))) then
		local v164_ = ""
		local v165_ = storeItem.customEnvironment
		if storeItem.isMod then
			local v166_ = g_modManager.nameToMod[v165_]
			if v166_ ~= nil and v166_.author ~= nil then
				v164_ = v166_.author
			end
		end
		local v167_ = g_brandManager:getBrandByIndex(storeItem.brandIndex)
		local v168_ = storeItem.brandNameRaw or ""
		if v167_ ~= nil and v167_.name ~= "NONE" then
			v168_ = v167_.title
		end
		self.indexedSearch:addDocument({
			["title"] = storeItem.name,
			["brand"] = v168_,
			["author"] = v164_,
			["dlcTitle"] = storeItem.dlcTitle
		}, storeItem)
	end
	return true
end

-- Local values: item, numItems
function StoreManager:removeItemByIndex(index)
	local v171_ = self.items[index]
	if v171_ ~= nil then
		self.xmlFilenameToItem[v171_.xmlFilenameLower] = nil
		local v172_ = #self.items
		if index < v172_ then
			self.items[index] = self.items[v172_]
			self.items[index].id = index
		end
		table.remove(self.items, v172_)
	end
end

function StoreManager:getItems()
	return self.items
end

function StoreManager:getItemByIndex(index)
	if index == nil then
		return nil
	else
		return self.items[index]
	end
end

function StoreManager:getItemByXMLFilename(xmlFilename)
	if xmlFilename == nil then
		return nil
	else
		return self.xmlFilenameToItem[string.lower(xmlFilename)]
	end
end

function StoreManager:getIsItemUnlocked(storeItem)
	return storeItem ~= nil and (storeItem.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)) and true or false
end

-- Local values: items, storeItem, _, storeItem, categoryAllowed, _, filterCategoryName, _, storeItemCategoryName, desc, value, _maxValue, specMin, specMax, configDatas, _, configData, _, configurationName, configItems, configIndex, configData
function StoreManager:getItemsByCombinationData(combinationData)
	local v181_ = {}
	if combinationData.xmlFilename == nil then
		for _, v182_ in ipairs(self.items) do
			if self:getIsItemUnlocked(v182_) then
				local v183_
				if combinationData.filterCategories == nil then
					v183_ = true
				else
					v183_ = false
					if v182_.categoryNames ~= nil then
						for _, v184_ in ipairs(combinationData.filterCategories) do
							for _, v185_ in ipairs(v182_.categoryNames) do
								if string.upper(v184_) == v185_ then
									v183_ = true
									break
								end
							end
						end
					end
				end
				if v183_ then
					if combinationData.filterSpec == nil then
						table.insert(v181_, {
							["storeItem"] = v182_
						})
					else
						local v186_ = self:getSpecTypeByName(combinationData.filterSpec)
						if v186_ ~= nil and v186_.species == v182_.species then
							StoreItemUtil.loadSpecsFromXML(v182_)
							local v187_, _ = v186_.getValueFunc(v182_, nil, nil, nil, true, true)
							if v187_ ~= nil then
								local v188_ = combinationData.filterSpecMin
								local v189_ = combinationData.filterSpecMax
								if combinationData.filterSpec == "weight" then
									v188_ = v188_ / 1000
									v189_ = v189_ / 1000
								end
								if v188_ <= v187_ and v187_ <= v189_ then
									table.insert(v181_, {
										["storeItem"] = v182_
									})
								elseif v186_.configDataFunc == nil then
									if v186_.relatedConfigurations ~= nil and v182_.configurations ~= nil then
										for _, v190_ in ipairs(v186_.relatedConfigurations) do
											if v182_.configurations[v190_] ~= nil then
												for v191_ = 1, #v182_.configurations[v190_] do
													local v192_ = {
														[v190_] = v191_
													}
													local v193_ = v186_.getValueFunc(v182_, nil, v192_, nil, true, true)
													if v188_ <= v193_ and v193_ <= v189_ then
														table.insert(v181_, {
															["storeItem"] = v182_,
															["configData"] = v192_
														})
													end
												end
											end
										end
									end
								else
									local v194_ = v186_.configDataFunc(v182_)
									if v194_ ~= nil then
										for _, v195_ in ipairs(v194_) do
											if v188_ <= v195_.value and v195_.value <= v189_ then
												local v196_ = {
													["storeItem"] = v182_,
													["configData"] = {
														[v195_.name] = v195_.index
													}
												}
												table.insert(v181_, v196_)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	else
		local v197_ = self.xmlFilenameToItem[string.lower(combinationData.customXMLFilename)]
		if v197_ == nil then
			v197_ = self.xmlFilenameToItem[string.lower(combinationData.xmlFilename)]
			if v197_ == nil then
				Logging.warning("Could not find combination vehicle \'%s\'", combinationData.xmlFilename)
			end
		end
		if self:getIsItemUnlocked(v197_) then
			table.insert(v181_, {
				["storeItem"] = v197_
			})
			return v181_
		end
	end
	return v181_
end

-- Local values: items, _, item
function StoreManager:getItemByCustomEnvironment(customEnvironment)
	local v200_ = {}
	for _, v201_ in ipairs(self.items) do
		if v201_.customEnvironment == customEnvironment then
			table.insert(v200_, v201_)
		end
	end
	return v200_
end

function StoreManager:addModStoreItem(xmlFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle)
	local v209_ = self.modStoreItems
	table.insert(v209_, {
		["xmlFilename"] = xmlFilename,
		["baseDir"] = baseDir,
		["customEnvironment"] = customEnvironment,
		["isMod"] = isMod,
		["isBundleItem"] = isBundleItem,
		["dlcTitle"] = dlcTitle
	})
end

-- Local values: xmlFilename, xmlFile, baseXMLName, storeDataXMLKey, speciesStr, species, xmlSchema, xmlName, firstLetter, xmlPathPaths, numParts, isValid, name, params, imageFilename, storeItem, sharedVramUsage, perInstanceVramUsage, ignoreVramUsage, _, func, customSharedVramUsage, customPerInstanceVramUsage, categoryNames, i, category, bundleItemsToAdd, bundleInfo, price, lifetime, dailyUpkeep, runningLeasingFactor, bundleIndex, bundleKey, bundleXmlFile, offset, rotationOffset, rotation, completePath, item, configName, configOptions, itemConfigOptions, j, configName, configOptions, configName, configOptions, preSelectedConfigurations, attachIndex, attachKey, bundleElement0, bundleElement1, attacherJointIndex, inputAttacherJointIndex, brushType, parameters, brushCategoryString, brushCategory, tab, constructionCategory, i
function StoreManager:loadItem(rawXMLFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle, extraContentId, ignoreAdd)
	local v_u_219_ = Utils.getFilename(rawXMLFilename, baseDir)
	local v220_ = loadXMLFile("storeItemXML", v_u_219_)
	if v220_ == 0 then
		return nil
	end
	local v221_ = getXMLRootName(v220_)
	local v222_ = v221_ .. ".storeData"
	local v223_ = getXMLString(v220_, v222_ .. ".species")
	local v224_ = StoreSpecies.getByName(v223_) or StoreSpecies.VEHICLE
	local v225_ = self.speciesToSchema[v224_]
	if v225_ == nil then
		Logging.xmlError(v220_, "Unable to get xml schema for species \'%s\' in \'%s\'", v224_, v_u_219_)
		return nil
	end
	delete(v220_)
	local v_u_226_ = XMLFile.load("storeManagerLoadItemXml", v_u_219_, v225_)
	local v227_ = Utils.getFilenameInfo(v_u_219_, true)
	local v228_ = string.sub(v227_, 1, 1)
	if v228_ ~= string.lower(v228_) then
		Logging.xmlDevWarning(v_u_226_, "Filename is starting with upper case character. Please follow the lower camel case naming convention.")
	end
	if tonumber(v228_) ~= nil then
		Logging.xmlDevWarning(v_u_226_, "Filename is starting with a number. Please start always with a character.")
	end
	local v229_ = v_u_219_:split("/")
	local v230_ = #v229_
	if v230_ >= 4 and (v229_[v230_ - 3] == "vehicles" and string.startsWith(string.lower(v229_[v230_]), string.lower(v229_[v230_ - 2]))) then
		Logging.xmlDevWarning(v_u_226_, "Vehicle filename \'%s\' starts with brand name \'%s\'.", v227_, v229_[v230_ - 2])
	end
	if not v_u_226_:hasProperty(v222_) then
		Logging.xmlError(v_u_226_, "No storeData found. StoreItem will be ignored!")
		v_u_226_:delete()
		return nil
	end
	local v231_ = v_u_226_:getValue(v222_ .. ".name", nil, customEnvironment, true)
	local v232_
	if v231_ == nil then
		Logging.xmlWarning(v_u_226_, "Name missing for storeitem. Ignoring store item!")
		v232_ = false
	else
		v232_ = true
	end
	if v231_ ~= nil then
		local v233_ = v_u_226_:getValue(v222_ .. ".name#params")
		if v233_ ~= nil then
			v231_ = g_i18n:insertTextParams(v231_, v233_, customEnvironment, v_u_226_)
		end
	end
	local v234_ = v_u_226_:getValue(v222_ .. ".image", "")
	if v234_ == "" then
		v234_ = nil
	end
	if v234_ == nil and v_u_226_:getValue(v222_ .. ".showInStore", true) then
		Logging.xmlWarning(v_u_226_, "Image icon is missing for storeitem. Ignoring store item!")
		v232_ = false
	end
	if not v232_ then
		v_u_226_:delete()
		return nil
	end
	local v_u_235_ = {
		["name"] = v231_,
		["extraContentId"] = extraContentId,
		["rawXMLFilename"] = rawXMLFilename,
		["baseDir"] = baseDir,
		["xmlSchema"] = v225_,
		["xmlFilename"] = v_u_219_,
		["xmlFilenameLower"] = string.lower(v_u_219_)
	}
	if v234_ then
		v234_ = Utils.getFilename(v234_, baseDir)
	end
	v_u_235_.imageFilename = v234_
	v_u_235_.species = v224_
	v_u_235_.functions = StoreItemUtil.getFunctionsFromXML(v_u_226_, v222_, customEnvironment)
	v_u_235_.specs = nil
	v_u_235_.brandIndex = StoreItemUtil.getBrandIndexFromXML(v_u_226_, v222_)
	v_u_235_.brandNameRaw = v_u_226_:getValue(v222_ .. ".brand", "")
	v_u_235_.customBrandIcon = v_u_226_:getValue(v222_ .. ".brand#customIcon")
	v_u_235_.customBrandIconOffset = v_u_226_:getValue(v222_ .. ".brand#imageOffset")
	if v_u_235_.customBrandIcon ~= nil then
		v_u_235_.customBrandIcon = Utils.getFilename(v_u_235_.customBrandIcon, baseDir)
	end
	v_u_235_.canBeSold = v_u_226_:getValue(v222_ .. ".canBeSold", true)
	v_u_235_.showInStore = v_u_226_:getValue(v222_ .. ".showInStore", not isBundleItem)
	v_u_235_.isBundleItem = isBundleItem
	v_u_235_.allowLeasing = v_u_226_:getValue(v222_ .. ".allowLeasing", true)
	v_u_235_.maxItemCount = v_u_226_:getValue(v222_ .. ".maxItemCount")
	v_u_235_.rotation = v_u_226_:getValue(v222_ .. ".rotation", 0)
	v_u_235_.spawnRotationOffset = v_u_226_:getValue(v222_ .. ".spawnRotationOffset", nil, true)
	v_u_235_.spawnSizeOffset = v_u_226_:getValue(v222_ .. ".spawnSizeOffset", nil, true)
	v_u_235_.shopDynamicTitle = v_u_226_:getValue(v222_ .. ".shopDynamicTitle", false)
	v_u_235_.shopTranslationOffset = v_u_226_:getValue(v222_ .. ".shopTranslationOffset", nil, true)
	v_u_235_.shopRotationOffset = v_u_226_:getValue(v222_ .. ".shopRotationOffset", nil, true)
	v_u_235_.shopIgnoreLastComponentPositions = v_u_226_:getValue(v222_ .. ".shopIgnoreLastComponentPositions", false)
	v_u_235_.shopInitialLoadingDelay = v_u_226_:getValue(v222_ .. ".shopLoadingDelay#initial")
	v_u_235_.shopConfigLoadingDelay = v_u_226_:getValue(v222_ .. ".shopLoadingDelay#config")
	v_u_235_.shopHeight = v_u_226_:getValue(v222_ .. ".shopHeight", 0)
	v_u_235_.financeCategory = v_u_226_:getValue(v222_ .. ".financeCategory")
	v_u_235_.shopFoldingState = v_u_226_:getValue(v222_ .. ".shopFoldingState", 0)
	v_u_235_.shopFoldingTime = v_u_226_:getValue(v222_ .. ".shopFoldingTime")
	local v236_, v237_, v238_ = StoreItemUtil.getVRamUsageFromXML(v_u_226_, v222_)
	for _, v239_ in ipairs(self.vramUsageFunctions) do
		local v240_, v241_ = v239_(v_u_226_)
		v236_ = v236_ + v240_
		v237_ = v237_ + v241_
	end
	v_u_235_.sharedVramUsage = v236_
	v_u_235_.perInstanceVramUsage = v237_
	v_u_235_.ignoreVramUsage = v238_
	v_u_235_.dlcTitle = dlcTitle
	v_u_235_.isMod = isMod
	v_u_235_.customEnvironment = customEnvironment
	v_u_235_.categoryNames = {}
	local v242_ = v_u_226_:getValue(v222_ .. ".category")
	if v242_ ~= nil then
		for v243_ = 1, #v242_ do
			local v244_ = self:getCategoryByName(v242_[v243_])
			if v244_ == nil then
				local v245_ = Logging.xmlWarning
				local v246_ = v242_[v243_]
				v245_(v_u_226_, "Invalid category \'%s\' in store data!", (tostring(v246_)))
			else
				local v247_ = v_u_235_.categoryNames
				local v248_ = v244_.name
				table.insert(v247_, v248_)
			end
		end
	end
	if #v_u_235_.categoryNames == 0 then
		if v_u_235_.showInStore then
			Logging.xmlWarning(v_u_226_, "No categories defined in store data! Using \'misc\' instead!")
		end
		local v249_ = v_u_235_.categoryNames
		table.insert(v249_, "MISC")
	end
	v_u_235_.categoryName = v_u_235_.categoryNames[1]
	if v224_ == StoreSpecies.VEHICLE then
		local v250_, v251_ = ConfigurationUtil.getConfigurationsFromXML(g_vehicleConfigurationManager, v_u_226_, v221_, baseDir, customEnvironment, isMod, v_u_235_)
		v_u_235_.configurations = v250_
		v_u_235_.defaultConfigurationIds = v251_
		v_u_235_.subConfigurations = ConfigurationUtil.getSubConfigurationsFromConfigurations(g_vehicleConfigurationManager, v_u_235_.configurations)
		v_u_235_.configurationSets = ConfigurationUtil.getConfigurationSetsFromXML(v_u_235_, v_u_226_, v221_, baseDir, customEnvironment, isMod)
		v_u_235_.hasLicensePlates = v_u_226_:hasProperty("vehicle.licensePlates.licensePlate(0)")
	elseif v224_ == StoreSpecies.PLACEABLE then
		local v252_, v253_ = ConfigurationUtil.getConfigurationsFromXML(g_placeableConfigurationManager, v_u_226_, v221_, baseDir, customEnvironment, isMod, v_u_235_)
		v_u_235_.configurations = v252_
		v_u_235_.defaultConfigurationIds = v253_
	end
	v_u_235_.price = v_u_226_:getValue(v222_ .. ".price", 0)
	if v_u_235_.price < 0 then
		Logging.xmlWarning(v_u_226_, "Price has to be greater than 0. Using default 10.000 instead!")
		v_u_235_.price = 10000
	end
	v_u_235_.dailyUpkeep = v_u_226_:getValue(v222_ .. ".dailyUpkeep", 0)
	v_u_235_.runningLeasingFactor = v_u_226_:getValue(v222_ .. ".runningLeasingFactor", EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
	v_u_235_.lifetime = v_u_226_:getValue(v222_ .. ".lifetime", 600)
	if v_u_235_.lifetime <= 0 then
		Logging.xmlWarning(v_u_226_, "Lifetime has to be greater than 0. Using default 600 instead!")
		v_u_235_.lifetime = 600
	end
	v_u_226_:iterate("handTool.storeData.storePacks.storePack", function(_, p254_)
		-- upvalues: (ref) v_u_226_, (copy) self, (copy) v_u_219_
		self:addPackItem(v_u_226_:getValue(p254_), v_u_219_)
	end)
	v_u_226_:iterate("vehicle.storeData.storePacks.storePack", function(_, p255_)
		-- upvalues: (ref) v_u_226_, (copy) self, (copy) v_u_219_
		self:addPackItem(v_u_226_:getValue(p255_), v_u_219_)
	end)
	local v256_ = {}
	if v_u_226_:hasProperty(v222_ .. ".bundleElements") then
		local v257_ = 0
		local v258_ = 0
		local v259_ = 0
		local v260_ = {
			["bundleItems"] = {},
			["attacherInfo"] = {}
		}
		local v261_ = math.huge
		for _, v262_ in v_u_226_:iterator(v222_ .. ".bundleElements.bundleElement") do
			local v263_ = v_u_226_:getValue(v262_ .. ".xmlFilename")
			local v264_ = v_u_226_:getValue(v262_ .. ".offset", "0 0 0", true)
			local v265_ = v_u_226_:getValue(v262_ .. ".rotationOffset", "0 0 0", true)
			local v266_ = v_u_226_:getValue(v262_ .. ".yRotation", 0)
			v265_[2] = v265_[2] + v266_
			if v263_ ~= nil then
				local v_u_267_ = self:getItemByXMLFilename((Utils.getFilename(v263_, baseDir)))
				if v_u_267_ == nil then
					v_u_267_ = self:loadItem(v263_, baseDir, customEnvironment, isMod, true, dlcTitle, nil, true)
					table.insert(v256_, v_u_267_)
				end
				if v_u_267_ ~= nil then
					v257_ = v257_ + v_u_267_.price
					v258_ = v258_ + v_u_267_.dailyUpkeep
					v259_ = v259_ + v_u_267_.runningLeasingFactor
					local v268_ = v_u_267_.lifetime
					v261_ = math.min(v261_, v268_)
					if v_u_267_.configurations ~= nil then
						v_u_235_.configurations = v_u_235_.configurations or {}
						for v269_, v270_ in pairs(v_u_267_.configurations) do
							if v_u_235_.configurations[v269_] == nil then
								v_u_235_.configurations[v269_] = table.clone(v270_, 5)
							else
								local v271_ = v_u_235_.configurations[v269_]
								for v272_ = 1, #v270_ do
									if v271_[v272_] == nil then
										v271_[v272_] = v270_[v272_]
									else
										v271_[v272_].price = v271_[v272_].price + v270_[v272_].price
									end
								end
							end
						end
					end
					if v_u_267_.defaultConfigurationIds ~= nil then
						v_u_235_.defaultConfigurationIds = v_u_235_.defaultConfigurationIds or {}
					end
					if v_u_267_.subConfigurations ~= nil then
						v_u_235_.subConfigurations = v_u_235_.subConfigurations or {}
						for v273_, v274_ in pairs(v_u_267_.subConfigurations) do
							v_u_235_.subConfigurations[v273_] = v274_
						end
					end
					if v_u_267_.configurationSets ~= nil then
						v_u_235_.configurationSets = v_u_235_.configurationSets or {}
						for v275_, v276_ in pairs(v_u_267_.configurationSets) do
							v_u_235_.configurationSets[v275_] = v276_
						end
					end
					local v_u_277_ = {}
					v_u_226_:iterate(v262_ .. ".configurations.configuration", function(_, p278_)
						-- upvalues: (ref) v_u_226_, (ref) v_u_267_, (copy) v_u_277_, (copy) v_u_235_
						local v279_ = v_u_226_:getValue(p278_ .. "#name")
						local v280_ = v_u_226_:getValue(p278_ .. "#value")
						if v280_ == nil then
							local v281_ = v_u_226_:getValue(p278_ .. "#saveId")
							if v_u_267_.configurations ~= nil then
								local v282_ = v_u_267_.configurations[v279_]
								if v282_ ~= nil then
									for v283_ = 1, #v282_ do
										if v282_[v283_].saveId == v281_ then
											v280_ = v282_[v283_].index
											break
										end
									end
								end
							end
						end
						if v279_ ~= nil and v280_ ~= nil then
							local v284_ = v_u_226_:getValue(p278_ .. "#allowChange", false)
							local v285_ = v_u_226_:getValue(p278_ .. "#hideOption", false)
							if not v_u_226_:getValue(p278_ .. "#disableOption", false) then
								v_u_277_[v279_] = {
									["configValue"] = v280_,
									["allowChange"] = v284_,
									["hideOption"] = v285_
								}
								return
							end
							local v286_ = v_u_235_.configurations[v279_]
							if v286_ ~= nil then
								for v287_ = 1, #v286_ do
									if v287_ == v280_ then
										v286_[v287_].isSelectable = not v286_[v287_].isSelectable
									end
								end
							end
						end
					end)
					v_u_235_.hasLicensePlates = v_u_235_.hasLicensePlates or v_u_267_.hasLicensePlates
					local v288_ = v260_.bundleItems
					local v289_ = {
						["item"] = v_u_267_,
						["xmlFilename"] = v_u_267_.xmlFilename,
						["offset"] = v264_,
						["rotationOffset"] = v265_,
						["rotation"] = 0,
						["price"] = v_u_267_.price,
						["preSelectedConfigurations"] = v_u_277_
					}
					table.insert(v288_, v289_)
				end
			end
		end
		for _, v290_ in v_u_226_:iterator(v222_ .. ".attacherInfo.attach") do
			local v291_ = v_u_226_:getValue(v290_ .. "#bundleElement0")
			local v292_ = v_u_226_:getValue(v290_ .. "#bundleElement1")
			local v293_ = v_u_226_:getValue(v290_ .. "#attacherJointIndex")
			local v294_ = v_u_226_:getValue(v290_ .. "#inputAttacherJointIndex")
			if v291_ ~= nil and (v292_ ~= nil and (v293_ ~= nil and v294_ ~= nil)) then
				local v295_ = v260_.attacherInfo
				table.insert(v295_, {
					["bundleElement0"] = v291_,
					["bundleElement1"] = v292_,
					["attacherJointIndex"] = v293_,
					["inputAttacherJointIndex"] = v294_
				})
			end
		end
		v_u_235_.price = v257_
		v_u_235_.dailyUpkeep = v258_
		v_u_235_.runningLeasingFactor = v259_
		v_u_235_.lifetime = v261_
		v_u_235_.bundleInfo = v260_
	end
	if Platform.hasContruction then
		if v_u_226_:hasProperty(v222_ .. ".brush") and v_u_235_.showInStore then
			local v296_ = v_u_226_:getValue(v222_ .. ".brush.type")
			if v296_ ~= nil and v296_ ~= "none" then
				if g_constructionBrushTypeManager:getClassObjectByTypeName(v296_) == nil then
					Logging.xmlError(v_u_226_, "Unknown brush type %q", v296_)
					printf("Available brush types: %s", table.concat(table.toList(g_constructionBrushTypeManager:getBrushTypes()), ", "))
				end
				local v_u_297_ = {}
				v_u_226_:iterate(v222_ .. ".brush.parameters.parameter", function(p298_, p299_)
					-- upvalues: (ref) v_u_226_, (copy) baseDir, (copy) v_u_297_
					local v300_ = v_u_226_:getValue(p299_)
					if v_u_226_:getValue(p299_ .. "#isFilename", false) then
						v300_ = Utils.getFilename(v300_, baseDir)
					end
					v_u_297_[p298_] = v300_
				end)
				local v301_ = v_u_226_:getValue(v222_ .. ".brush.category")
				if v301_ == nil then
					Logging.xmlWarning(v_u_226_, "Unknown brush category \'%s\'", v301_)
				else
					local v302_ = self:getConstructionCategoryByName(v301_)
					if v302_ == nil then
						Logging.xmlWarning(v_u_226_, "Missing brush category: %s", v222_ .. ".brush.category")
					else
						local v303_ = self:getConstructionTabByName(v_u_226_:getValue(v222_ .. ".brush.tab"), v302_.name)
						if v303_ == nil then
							Logging.xmlWarning(v_u_226_, "Missing brush tab")
						else
							v_u_235_.brush = {
								["type"] = v296_,
								["parameters"] = v_u_297_,
								["category"] = v302_,
								["tab"] = v303_
							}
						end
					end
				end
			end
		elseif v_u_235_.species == StoreSpecies.PLACEABLE and v_u_235_.showInStore then
			local v304_ = self.constructionCategories[1]
			if v304_ == nil then
				Logging.xmlDevWarning(v_u_226_, "Construction category not found for \'%s\'", v222_)
			else
				v_u_235_.brush = {
					["type"] = "placeable",
					["parameters"] = {},
					["category"] = v304_,
					["tab"] = v304_.tabs[1]
				}
			end
		end
	end
	if not ignoreAdd then
		self:addItem(v_u_235_)
		for v305_ = 1, #v256_ do
			self:addItem(v256_[v305_])
		end
	end
	v_u_226_:delete()
	return v_u_235_
end

function StoreManager:addPack(name, title, imageFilename, baseDir)
	if name == nil or name == "" then
		printWarning("Warning: Could not register store pack. Name is missing or empty!")
		return false
	end
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is no valid name for a store pack!")
		return false
	end
	if title == nil or title == "" then
		printWarning("Warning: Could not register store pack. Title is missing or empty!")
		return false
	end
	if imageFilename == nil or imageFilename == "" then
		printWarning("Warning: Could not register store pack. Image is missing or empty!")
		return false
	end
	if baseDir == nil then
		printWarning("Warning: Could not register store pack. Basedirectory not defined!")
		return false
	end
	local v311_ = string.upper(name)
	if self.packs[v311_] ~= nil then
		return false
	end
	self.numOfPacks = self.numOfPacks + 1
	self.packs[v311_] = {
		["name"] = v311_,
		["title"] = title,
		["image"] = Utils.getFilename(imageFilename, baseDir),
		["baseDir"] = baseDir,
		["orderId"] = self.numOfPacks,
		["items"] = {}
	}
	return true
end

function StoreManager:addModConstructionTab(categoryName, tabName, tabTitle, tabIconFilename, tabRefSize, tabIconUVs, baseDir, tabIconSliceId)
	local v321_ = self.modConstructionTabs
	table.insert(v321_, {
		["categoryName"] = categoryName,
		["tabName"] = tabName,
		["tabTitle"] = tabTitle,
		["tabIconFilename"] = tabIconFilename,
		["tabRefSize"] = tabRefSize,
		["tabIconUVs"] = tabIconUVs,
		["tabIconSliceId"] = tabIconSliceId,
		["baseDir"] = baseDir
	})
end

function StoreManager:addModStorePack(name, title, imageFilename, baseDir, storeItems)
	local v328_ = self.modStorePacks
	table.insert(v328_, {
		["name"] = name,
		["title"] = title,
		["imageFilename"] = imageFilename,
		["baseDir"] = baseDir,
		["storeItems"] = storeItems or {}
	})
end

function StoreManager:addPackItem(name, itemFilename)
	if name == nil or name == "" then
		Logging.warning("Could not add pack item. Name is missing or empty.")
		return
	elseif self.packs[name] == nil then
		Logging.warning("Could not add pack item. Pack \'%s\' does not exist.", name)
		return
	elseif itemFilename == nil or itemFilename == "" then
		Logging.warning("Could not add pack item to \'%s\'. Item filename is missing.", name)
	else
		local v332_ = self.packs[name].items
		table.insert(v332_, itemFilename)
	end
end

function StoreManager:getPacks()
	return self.packs
end

-- Local values: pack
function StoreManager:getPackItems(name)
	local v336_ = self.packs[name]
	if v336_ == nil then
		return nil
	else
		return v336_.items
	end
end

function StoreManager:search(text, callback)
	return self.indexedSearch:search(text, callback)
end

-- Local values: i, item
function StoreManager:consoleCommandReloadStoreItems()
	for v341_, v342_ in ipairs(self.items) do
		self.items[v341_] = self:loadItem(v342_.rawXMLFilename, v342_.baseDir, v342_.customEnvironment, v342_.isMod, v342_.isBundleItem, v342_.dlcTitle, v342_.extraContentId, true)
		if self.items[v341_] ~= nil then
			self.xmlFilenameToItem[self.items[v341_].xmlFilenameLower] = self.items[v341_]
		end
	end
	g_messageCenter:publish(MessageType.STORE_ITEMS_RELOADED)
end

function StoreManager.registerStoreCategoriesXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Store category name identifier")
	schema:register(XMLValueType.STRING, basePath .. "#title", "Store category title")
	schema:register(XMLValueType.STRING, basePath .. "#image", "Store category image")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Store category type")
	schema:register(XMLValueType.STRING, basePath .. "#insertAfter", "Store category should be inserted after this category")
end

-- Local values: speciesDefaultValue, speciesDefaultValues
function StoreManager.registerStoreDataXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".storeData.name", "Name of store item", nil, true)
	schema:register(XMLValueType.STRING, basePath .. ".storeData.name#params", "Parameters to add to name")
	local v347_ = StoreSpecies.getName(StoreSpecies.VEHICLE)
	local v348_ = StoreSpecies.getAllOrderedByName()
	schema:register(XMLValueType.STRING, basePath .. ".storeData.species", "Store species", v347_, false, v348_)
	schema:register(XMLValueType.STRING, basePath .. ".storeData.image", "Path to store icon", nil, true)
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brand", "Brand identifier", "LIZARD")
	schema:registerAutoCompletionDataSource(basePath .. ".storeData.brand", "$dataS/brands.xml", "brands.brand#name")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brand#customIcon", "Custom brand icon to display in the shop config screen")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brand#imageOffset", "Offset of custom brand icon")
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.canBeSold", "Defines of the vehicle can be sold", true)
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.showInStore", "Defines of the vehicle is shown in shop", true)
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.allowLeasing", "Defines of the vehicle can be leased", true)
	schema:register(XMLValueType.INT, basePath .. ".storeData.maxItemCount", "Defines the max. amount vehicle of this type")
	schema:register(XMLValueType.ANGLE, basePath .. ".storeData.rotation", "Y rotation of the vehicle", 0)
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.spawnRotationOffset", "Y rotation of the vehicle when spawned at the shop loading places")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".storeData.spawnSizeOffset", "Additional size that is reserved for the tool when spawned at the shop loading places (width, height, length)")
	schema:register(XMLValueType.STRING_LIST, basePath .. ".storeData.category", "Store category name or names (space separated)", "misc")
	schema:registerAutoCompletionDataSource(basePath .. ".storeData.category", "$dataS/storeCategories.xml", "categories.category#name")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.storePacks.storePack(?)", "Store pack")
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.price", "Store price", 10000)
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.dailyUpkeep", "Daily up keep", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.runningLeasingFactor", "Running leasing factor", EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.lifetime", "Lifetime of vehicle used to calculate price drop, in months", 600)
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.shopDynamicTitle", "Vehicle brand icon and vehicle name is dynamically updated based on the selected configuration in the shop", false)
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".storeData.shopTranslationOffset", "Translation offset for shop spawning and store icon", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.shopRotationOffset", "Rotation offset for shop spawning and store icon", "0 0 0")
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.shopIgnoreLastComponentPositions", "If set to true the component positions from last spawning are now reused", false)
	schema:register(XMLValueType.TIME, basePath .. ".storeData.shopLoadingDelay#initial", "Delay of initial shop loading until the vehicle is displayed. (Used e.g. to hide vehicle while components still moving)")
	schema:register(XMLValueType.TIME, basePath .. ".storeData.shopLoadingDelay#config", "Delay of shop loading after config change until the vehicle is displayed. (Used e.g. to hide vehicle while components still moving)")
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.shopHeight", "Height of vehicle for shop placement", 0)
	schema:register(XMLValueType.STRING, basePath .. ".storeData.financeCategory", "Finance category name")
	schema:register(XMLValueType.INT, basePath .. ".storeData.shopFoldingState", "Inverts the shop folding state if set to \'1\'", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.shopFoldingTime", "Defines a custom folding time for the shop")
	schema:register(XMLValueType.INT, basePath .. ".storeData.vertexBufferMemoryUsage", "Vertex buffer memory usage", 0)
	schema:register(XMLValueType.INT, basePath .. ".storeData.indexBufferMemoryUsage", "Index buffer memory usage", 0)
	schema:register(XMLValueType.INT, basePath .. ".storeData.textureMemoryUsage", "Texture memory usage", 0)
	schema:register(XMLValueType.INT, basePath .. ".storeData.instanceVertexBufferMemoryUsage", "Instance vertex buffer memory usage", 0)
	schema:register(XMLValueType.INT, basePath .. ".storeData.instanceIndexBufferMemoryUsage", "Instance index buffer memory usage", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.ignoreVramUsage", "Ignore VRAM usage", false)
	schema:register(XMLValueType.INT, basePath .. ".storeData.audioMemoryUsage", "Audio memory usage", 0)
	schema:register(XMLValueType.STRING, basePath .. ".storeData.bundleElements.bundleElement(?).xmlFilename", "XML filename")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".storeData.bundleElements.bundleElement(?).offset", "Translation offset of vehicle")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.bundleElements.bundleElement(?).rotationOffset", "Rotation offset of vehicle")
	schema:register(XMLValueType.ANGLE, basePath .. ".storeData.bundleElements.bundleElement(?).yRotation", "Y rotation of vehicle")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#name", "Name of configuration")
	schema:register(XMLValueType.INT, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#value", "Configuration index that is forced for this config")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#saveId", "Configuration save id that is forced for this config")
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#allowChange", "Allow change of option", false)
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#hideOption", "Hide the option completely", false)
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.bundleElements.bundleElement(?).configurations.configuration(?)#disableOption", "Disabled this particular config option", false)
	schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#bundleElement0", "First bundle element")
	schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#bundleElement1", "Second bundle element")
	schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#attacherJointIndex", "Attacher joint index")
	schema:register(XMLValueType.INT, basePath .. ".storeData.attacherInfo.attach(?)#inputAttacherJointIndex", "Input attacher joint index")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".storeData.functions.function(?)", "Function description text")
	schema:registerAutoCompletionDataSource(basePath .. ".storeData.functions.function(?)", "dataS/l10n/l10n_en.xml", "l10n.elements.e#k", "$l10n_")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.type", "Brush type")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.category", "Brush category")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.tab", "Brush tab")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.parameters.parameter(?)", "Brush parameter value")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.brush.parameters.parameter(?)#isFilename", "Whether the parameter is a filename")
	schema:register(XMLValueType.ANGLE, basePath .. ".storeData.storeIconRendering.settings#cameraYRot", "Y Rot of camera", "Setting from Icon Generator")
	schema:register(XMLValueType.ANGLE, basePath .. ".storeData.storeIconRendering.settings#cameraXRot", "X Rot of camera", "Setting from Icon Generator")
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.settings#advancedBoundingBox", "Advanced BB is used for icon placement", "Setting from Icon Generator")
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.settings#centerIcon", "Center item on icon", "Setting from Icon Generator")
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.storeIconRendering.settings#zoomFactor", "Camera zoom factor")
	schema:register(XMLValueType.FLOAT, basePath .. ".storeData.storeIconRendering.settings#lightIntensity", "Intensity of light sources", "Setting from Icon Generator")
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.settings#showTriggerMarkers", "Show trigger markers on icon (for placeables)", false)
	schema:register(XMLValueType.BOOL, basePath .. ".storeData.storeIconRendering.objectBundle#useClipPlane", "Clip plane is used")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.storeIconRendering.objectBundle.object(?)#filename", "Path to i3d file")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#node", "Index Path of node to load")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#translation", "Translation", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#rotation", "Rotation", "0 0 0")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".storeData.storeIconRendering.objectBundle.object(?).node(?)#scale", "Scale", "1 1 1")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.storeIconRendering.shaderParameter(?)#name", "Name if shader parameter")
	schema:register(XMLValueType.STRING, basePath .. ".storeData.storeIconRendering.shaderParameter(?)#values", "Values of shader parameter")
end
g_storeManager = StoreManager.new()
