-- Local values: HelpLineManager_mt
HelpLineManager = {}
HelpLineManager.helpLineXMLSchema = nil
source("dataS/scripts/misc/HelpLineActivatable.lua")
local HelpLineManager_mt = Class(HelpLineManager, AbstractManager)
HelpLineManager.ITEM_TYPE = {
	["TEXT"] = "text",
	["IMAGE"] = "image"
}
HelpLineManager.SLICE_PREFIX = "helpline"
HelpLineManager.CUSTOMENV_BASEGAME = ""

-- Upvalues: HelpLineManager_mt
-- Local values: self
function HelpLineManager.new(customMt)
	-- upvalues: (copy) HelpLineManager_mt
	local v3_ = AbstractManager.new(customMt or HelpLineManager_mt)
	HelpLineManager.helpLineXMLSchema = XMLSchema.new("helpLine")
	HelpLineManager.registerHelplineXMLPaths(HelpLineManager.helpLineXMLSchema)
	return v3_
end

function HelpLineManager.registerCategoryXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "category title l10n key")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".page(?)#title", "page title l10n key")
	schema:register(XMLValueType.STRING, basePath .. ".page(?)#id", "page title l10n key")
	schema:register(XMLValueType.FILENAME, basePath .. ".page(?)#iconFilename", "page icon filepath")
	schema:register(XMLValueType.STRING, basePath .. ".page(?)#iconSliceId", "page icon slice id")
	schema:register(XMLValueType.BOOL, basePath .. ".page(?).paragraph(?)#noSpacing", "")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".page(?).paragraph(?).title#text", "paragraph title l10n key")
	schema:register(XMLValueType.L10N_STRING, basePath .. ".page(?).paragraph(?).text#text", "paragraph text l10n key")
	schema:register(XMLValueType.BOOL, basePath .. ".page(?).paragraph(?).text#alignToImage", "")
	schema:register(XMLValueType.FILENAME, basePath .. ".page(?).paragraph(?).image#filename", "paragraph image filepath")
	schema:register(XMLValueType.STRING_LIST, basePath .. ".page(?).paragraph(?).image#uvs", "image uvs")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".page(?).paragraph(?).image#size", "image size", "1024 1024")
	schema:register(XMLValueType.STRING, basePath .. ".page(?).paragraph(?).image#displaySize", "")
	schema:register(XMLValueType.FLOAT, basePath .. ".page(?).paragraph(?).image#heightScale", "", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".page(?).paragraph(?).image#aspectRatio", "", 1)
end

function HelpLineManager.registerHelplineXMLPaths(schema)
	HelpLineManager.registerCategoryXMLPaths(schema, "helpLines.category(?)")
end

function HelpLineManager:initDataStructures()
	self.customEnvironmentNames = { HelpLineManager.CUSTOMENV_BASEGAME }
	self.customEnvironmentToCategory = {}
	self.customEnvironmentToCategory[HelpLineManager.CUSTOMENV_BASEGAME] = {}
	self.idToCategoryPageIndex = {}
	self.categoryNames = {}
	self.triggers = {}
	self.triggerNodeToData = {}
	self.zones = {}
	self.sharedLoadingIds = {}
	self.helpData = nil
	self.idToIndices = {}
end

-- Local values: filenameStr, filename, additionalFilename, customEnvironment, categories, prefix, categoryIndex, category, categoryId, pageIndex, page, pageId, getCategoryAndPageIndex, xmlObject, _, key, position, categoryIndex, pageIndex, customEnvironment, trigger, categories, category, page, sharedLoadingId, _, key, position, categoryIndex, pageIndex, customEnvironment, zone
function HelpLineManager:loadMapData(xmlFile, missionInfo)
	HelpLineManager:superClass().loadMapData(self)
	local v11_ = getXMLString(xmlFile, "map.helpline#filename")
	if v11_ == nil then
		Logging.xmlInfo(xmlFile, "No helpline defined for map")
		return false
	end
	local v12_ = Utils.getFilename(v11_, g_currentMission.baseDirectory)
	if v12_ == nil or (v12_ == "" or not fileExists(v12_)) then
		Logging.xmlError(xmlFile, "Could not load helpline config file \'" .. tostring(v11_) .. "\'!")
		return false
	end
	self:loadFromXML(v12_, missionInfo)
	local v13_ = getXMLString(xmlFile, "map.helpline#additionalFilename")
	if v13_ ~= nil then
		self:loadFromXML(Utils.getFilename(v13_, g_currentMission.baseDirectory), missionInfo)
	end
	for v14_, v15_ in pairs(self.customEnvironmentToCategory) do
		local v16_ = string.isNilOrWhitespace(v14_) and "" or v14_ .. "."
		for v17_, v18_ in ipairs(v15_) do
			local v19_ = v18_.id
			if v19_ ~= nil then
				local v20_ = v16_ .. v19_
				if self.idToCategoryPageIndex[v20_] == nil then
					self.idToCategoryPageIndex[v20_] = {
						["customEnvironment"] = v14_,
						["categoryIndex"] = v17_,
						["pageIndex"] = 0
					}
				else
					Logging.xmlWarning(xmlFile, "Category Id \'%s\' already used. Ignoring id for category name \'%s\'!", v20_, v18_.title)
				end
			end
			for v21_, v22_ in ipairs(v18_.pages) do
				local v23_ = v22_.id
				if v23_ ~= nil then
					local v24_ = v16_ .. v23_
					if self.idToCategoryPageIndex[v24_] == nil then
						self.idToCategoryPageIndex[v24_] = {
							["customEnvironment"] = v14_,
							["categoryIndex"] = v17_,
							["pageIndex"] = v21_
						}
					else
						Logging.xmlWarning(xmlFile, "Page Id \'%s\' already used. Ignoring id for page name \'%s\'!", v24_, v22_.title)
					end
				end
			end
		end
	end
	local v25_ = XMLFile.wrap(xmlFile, nil)
	local function v36_(p26_, p27_)
		-- upvalues: (copy) self
		local v28_ = p26_:getFilename()
		local v29_, _ = Utils.getModNameAndBaseDirectory(v28_)
		local v30_ = p26_:getString(p27_ .. "#helpId")
		if v30_ ~= nil then
			local v31_ = self.idToCategoryPageIndex[v30_]
			if v31_ == nil and v29_ ~= nil then
				local v32_ = v29_ .. "." .. v30_
				v31_ = self.idToCategoryPageIndex[v32_]
			end
			if v31_ ~= nil then
				return v31_.categoryIndex, v31_.pageIndex, v29_
			end
			Logging.xmlWarning(p26_, "No help line item defined for helpId \'%s\'", v30_)
			return 1, 1
		end
		local v33_ = p26_:getString(p27_ .. "#categoryId")
		if v33_ == nil then
			return p26_:getInt(p27_ .. "#categoryIndex", 1), p26_:getInt(p27_ .. "#pageIndex", 1), v29_
		end
		local v34_ = self.idToCategoryPageIndex[v33_]
		if v34_ == nil and v29_ ~= nil then
			local v35_ = v29_ .. "." .. v33_
			v34_ = self.idToCategoryPageIndex[v35_]
		end
		if v34_ ~= nil then
			return v34_.categoryIndex, v34_.pageIndex, v29_
		end
		Logging.xmlWarning(p26_, "No help line item defined for categoryId \'%s\'", v33_)
		return 1, 1
	end
	for _, v37_ in v25_:iterator("map.helpline.trigger") do
		local v38_ = v25_:getVector(v37_ .. "#position", nil, 3)
		if v38_ == nil then
			Logging.xmlWarning(v25_, "Missing helpline trigger position for \'%s\'", v37_)
		else
			local v39_, v40_, v41_ = v36_(v25_, v37_)
			local v42_ = {
				["position"] = v38_,
				["categoryIndex"] = v39_,
				["pageIndex"] = v40_
			}
			local v43_ = self.customEnvironmentToCategory[v41_]
			if v43_ == nil then
				Logging.xmlWarning(v25_, "No categories found for custom environment \'%s\' for \'%s\'", v41_, v37_)
			else
				local v44_ = v43_[v42_.categoryIndex]
				if v44_ == nil then
					Logging.xmlWarning(v25_, "Invalid helpline trigger category index \'%d\' for \'%s\'", v39_, v37_)
				elseif v44_.pages[v42_.pageIndex] == nil then
					Logging.xmlWarning(v25_, "Invalid helpline trigger page index \'%d\' for category \'%d\' for \'%s\'", v42_.pageIndex, v39_, v37_)
				else
					local v45_ = g_i3DManager:loadSharedI3DFileAsync("data/objects/helpIcon/icon.i3d", false, false, HelpLineManager.onIconLoaded, self, v42_)
					local v46_ = self.sharedLoadingIds
					table.insert(v46_, v45_)
				end
			end
		end
	end
	for _, v47_ in v25_:iterator("map.helpline.zone") do
		local v48_ = v25_:getVector(v47_ .. "#position", nil, 3)
		if v48_ ~= nil then
			local v49_, v50_, v51_ = v36_(v25_, v47_)
			local v52_ = {
				["position"] = v48_,
				["radius"] = v25_:getFloat(v47_ .. "#radius", 50),
				["categoryIndex"] = v49_,
				["pageIndex"] = v50_,
				["customEnvironment"] = v51_
			}
			local v53_ = self.zones
			table.insert(v53_, v52_)
		end
	end
	v25_:delete()
	self.activatable = HelpLineActivatable.new()
	return true
end

-- Local values: _, sharedLoadingId, _, trigger
function HelpLineManager:unloadMapData()
	self.helpData = nil
	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
	for _, v55_ in ipairs(self.sharedLoadingIds) do
		g_i3DManager:releaseSharedI3DFile(v55_)
	end
	for _, v56_ in ipairs(self.triggers) do
		g_currentMission:removeHelpTrigger(v56_.node)
		removeTrigger(v56_.triggerNode)
		delete(v56_.node)
	end
	HelpLineManager:superClass().unloadMapData(self)
end

function HelpLineManager:onIconLoaded(i3dNode, failedReason, trigger)
	if i3dNode ~= 0 then
		trigger.node = i3dNode
		trigger.triggerNode = getChildAt(getChildAt(i3dNode, 0), 0)
		self.triggerNodeToData[trigger.triggerNode] = trigger
		link(getRootNode(), i3dNode)
		addTrigger(trigger.triggerNode, "onIconTrigger", self)
		setWorldTranslation(i3dNode, trigger.position[1], trigger.position[2], trigger.position[3])
		addToPhysics(i3dNode)
		local v60_ = self.triggers
		table.insert(v60_, trigger)
		g_currentMission:addHelpTrigger(trigger.node)
	end
end

-- Local values: data
function HelpLineManager:onIconTrigger(triggerId, otherId, onEnter, onLeave, onStay)
	local v65_ = self.triggerNodeToData[triggerId]
	if v65_ ~= nil then
		if onEnter then
			self.helpData = v65_
			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
			return
		end
		if onLeave then
			self.helpData = nil
			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

-- Local values: customEnvironment, baseDirectory, xmlFile, _, key, category, categories
function HelpLineManager:loadFromXML(filename, missionInfo)
	local v69_, v70_ = Utils.getModNameAndBaseDirectory(filename)
	local v71_ = XMLFile.load("helpLineViewContentXML", filename)
	if v71_ ~= nil then
		for _, v72_ in v71_:iterator("helpLines.category") do
			local v73_ = self:loadCategory(v71_, v72_, missionInfo, v69_, v70_)
			if v73_ ~= nil then
				v69_ = v69_ or HelpLineManager.CUSTOMENV_BASEGAME
				local v74_ = self.customEnvironmentToCategory[v69_]
				if v74_ == nil then
					v74_ = {}
					self.customEnvironmentToCategory[v69_] = v74_
					local v75_ = self.customEnvironmentNames
					table.insert(v75_, v69_)
				end
				table.insert(v74_, v73_)
			end
		end
		v71_:delete()
	end
end

-- Local values: category, categories
function HelpLineManager:addModCategory(xmlFile, key, baseDirectory, customEnvironment)
	local v81_ = self:loadCategory(xmlFile, key, nil, customEnvironment, baseDirectory)
	if v81_ ~= nil then
		local v82_ = self.customEnvironmentToCategory[customEnvironment]
		if v82_ == nil then
			v82_ = {}
			self.customEnvironmentToCategory[customEnvironment] = v82_
			local v83_ = self.customEnvironmentNames
			table.insert(v83_, customEnvironment)
		end
		table.insert(v82_, v81_)
	end
end

-- Local values: category, id, _, pageKey, page
function HelpLineManager:loadCategory(xmlFile, key, missionInfo, customEnvironment, baseDirectory)
	local v90_ = {
		["title"] = xmlFile:getString(key .. "#title"),
		["customEnvironment"] = customEnvironment,
		["pages"] = {}
	}
	local v91_ = xmlFile:getString(key .. "#id")
	if v91_ ~= nil then
		if not string.isNilOrWhitespace(customEnvironment) then
			v91_ = customEnvironment .. "." .. v91_
		end
		v90_.id = v91_
	end
	for _, v92_ in xmlFile:iterator(key .. ".page") do
		local v93_ = self:loadPage(xmlFile, v92_, missionInfo, customEnvironment, baseDirectory)
		local v94_ = v90_.pages
		table.insert(v94_, v93_)
	end
	return v90_
end

-- Local values: page, iconSliceId, id, _, paragraphKey, paragraph, filename, heightScale, aspectRatio, size, uvs, displaySize
function HelpLineManager:loadPage(xmlFile, key, missionInfo, customEnvironment, baseDirectory)
	local v99_ = {
		["title"] = xmlFile:getString(key .. "#title"),
		["customEnvironment"] = customEnvironment,
		["baseDirectory"] = baseDirectory,
		["iconFilename"] = xmlFile:getString(key .. "#iconFilename")
	}
	local v100_ = xmlFile:getString(key .. "#iconSliceId")
	if v100_ ~= nil and v100_ ~= "" then
		if not string.contains(v100_, "%.") then
			v100_ = HelpLineManager.SLICE_PREFIX .. "." .. v100_
		end
		v99_.iconSliceId = v100_
	end
	local v101_ = xmlFile:getString(key .. "#id")
	if v101_ ~= nil then
		if customEnvironment ~= nil then
			v101_ = customEnvironment .. "." .. v101_
		end
		v99_.id = v101_
	end
	v99_.paragraphs = {}
	for _, v102_ in xmlFile:iterator(key .. ".paragraph") do
		local v103_ = {
			["title"] = xmlFile:getString(v102_ .. ".title#text"),
			["text"] = xmlFile:getString(v102_ .. ".text#text"),
			["alignToImage"] = xmlFile:getBool(v102_ .. ".text#alignToImage"),
			["customEnvironment"] = customEnvironment,
			["noSpacing"] = xmlFile:getBool(v102_ .. "#noSpacing")
		}
		local v104_ = xmlFile:getString(v102_ .. ".image#filename")
		if v104_ ~= nil then
			local v105_ = xmlFile:getFloat(v102_ .. ".image#heightScale", 1)
			local v106_ = xmlFile:getFloat(v102_ .. ".image#aspectRatio", 1)
			local v107_ = string.getVector(xmlFile:getString(v102_ .. ".image#size"), 2) or { 1024, 1024 }
			v103_.image = {
				["filename"] = v104_,
				["uvs"] = GuiUtils.getUVs(xmlFile:getString(v102_ .. ".image#uvs", "0 0 1 1"), v107_),
				["size"] = v107_,
				["heightScale"] = v105_,
				["aspectRatio"] = v106_,
				["displaySize"] = GuiUtils.getNormalizedScreenValues(xmlFile:getString(v102_ .. ".image#displaySize"))
			}
		end
		local v108_ = v99_.paragraphs
		table.insert(v108_, v103_)
	end
	return v99_
end

-- Local values: translated
function HelpLineManager:convertText(text, customEnv)
	local v111_ = g_i18n:convertText(text, customEnv)
	return string.gsub(v111_, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
end

function HelpLineManager:getCategories(customEnvironment)
	local v114_ = customEnvironment or HelpLineManager.CUSTOMENV_BASEGAME
	return self.customEnvironmentToCategory[v114_]
end

function HelpLineManager:getCustomEnvironmentNames()
	return self.customEnvironmentNames
end

-- Local values: categories
function HelpLineManager:getCategory(customEnvironment, categoryIndex)
	if categoryIndex == nil then
		return nil
	else
		local v119_ = customEnvironment or HelpLineManager.CUSTOMENV_BASEGAME
		local v120_ = self.customEnvironmentToCategory[v119_]
		if v120_ == nil then
			return nil
		else
			return v120_[categoryIndex]
		end
	end
end

-- Local values: nearestDistance, categoryIndex, pageIndex, _, zone, a, b, c, distance
function HelpLineManager:getContextBasedHelp(x, y, z)
	local v125_ = math.huge
	local v126_ = nil
	local v127_ = nil
	for _, v128_ in ipairs(self.zones) do
		local v129_ = v128_.position
		local v130_, v131_, v132_ = unpack(v129_)
		local v133_ = MathUtil.vector3Length(v130_ - x, v131_ - y, v132_ - z)
		if v133_ <= v128_.radius and v133_ < v125_ then
			v126_ = v128_.categoryIndex
			v127_ = v128_.pageIndex
		end
	end
	return v126_, v127_
end

-- Local values: categoryIndex, _
function HelpLineManager:getIsContextBasedHelpAvailable(x, y, z)
	local v138_, _ = self:getContextBasedHelp(x, y, z)
	return v138_ ~= nil
end

-- Local values: categoryIndex, pageIndex
function HelpLineManager:openContextBasedHelp(x, y, z)
	local v143_, v144_ = self:getContextBasedHelp(x, y, z)
	g_gui:showGui("InGameMenu")
	g_messageCenter:publish(MessageType.GUI_INGAME_OPEN_HELP_SCREEN, v143_, v144_)
end
g_helpLineManager = HelpLineManager.new()
