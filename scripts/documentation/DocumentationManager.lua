DocumentationManager = {}
DocumentationManager.EXPORT_DIRECTORY = "../documents/documentation/"
local DocumentationManager_mt = Class(DocumentationManager)
function DocumentationManager.new(customMt)
	local self = setmetatable({}, customMt or DocumentationManager_mt)
	self.generators = {}
	return self
end
function DocumentationManager:addGenerator(generator)
	table.insert(self.generators, generator)
end
function DocumentationManager.validateRequiredMods(exportName)
	local hasMismatch = false
	for modName, _ in pairs(g_modIsLoaded) do
		local isRequired = Platform.documentationRequiredModNames[modName] == true
		local isTestMap = string.contains(modName, "testMap")
		if isRequired or isTestMap then
			continue
		end
		hasMismatch = true
	end
	for modName, _ in pairs(Platform.documentationRequiredModNames) do
		if g_modIsLoaded[modName] == true then
			continue
		end
		hasMismatch = true
	end
	if not hasMismatch then
		return true
	else
		Logging.error("%s could not be executed. Mods do not match requirements:", exportName)
		for modName, _ in pairs(g_modIsLoaded) do
			local isRequired = Platform.documentationRequiredModNames[modName] == true
			local isTestMap = string.contains(modName, "testMap")
			if isRequired or isTestMap then
				print(" - " .. modName .. " (ok)")
			else
				printError(" - " .. modName .. " (not allowed)")
			end
		end
		for modName, _ in pairs(Platform.documentationRequiredModNames) do
			if g_modIsLoaded[modName] == true then
				continue
			end
			printError(" - " .. modName .. " (missing)")
		end
		return false
	end
end
function DocumentationManager.consoleCommandGenerateDocumentation()
	if g_documentationManager == nil then
		return
	elseif not StartParams.getIsSet("scriptDebug") then
		printError("Error: documentation export is only available if the game was launched with '-scriptDebug'")
	elseif getLanguage() ~= 0 then
		printError("Error: documentation export should only be done with the game in english language setting")
	elseif DocumentationManager.validateRequiredMods("Documentation export") then
		local gamePath = getAppBasePath()
		local baseDir = gamePath .. DocumentationManager.EXPORT_DIRECTORY
		createFolder(gamePath .. "../documents")
		createFolder(gamePath .. "../documents/documentation")
		DocumentationHTMLUtil.writeSharedCSS(baseDir)
		for _, generator in ipairs(g_documentationManager.generators) do
			Logging.info("Generating documentation: %s ...", generator.name)
			generator:generate(baseDir)
		end
		g_documentationManager:generateMasterOverview(baseDir)
		Logging.info("Documentation generated in '%s'", baseDir)
	end
end
function DocumentationManager.countItemsForSource(items, sourceLabel)
	local isBasegame = sourceLabel == DocumentationHTMLUtil.BASEGAME_GROUP_LABEL
	local count = 0
	for _, item in ipairs(items) do
		local itemDlc = item.dlcTitle
		local itemIsBasegame = itemDlc == nil or itemDlc == ""
		if isBasegame then
			if itemIsBasegame then
				count = count + 1
			else
				if isBasegame then
					continue
				end
				if itemDlc == sourceLabel then
					count = count + 1
				end
			end
		end
	end
	return count
end
function DocumentationManager:collectSourceLabels()
	local dlcTitlesSet = {}
	for _, generator in ipairs(self.generators) do
		for _, item in ipairs(generator.items) do
			if item.dlcTitle == nil or item.dlcTitle == "" then
				continue
			end
			dlcTitlesSet[item.dlcTitle] = true
		end
	end
	local sortedDlcTitles = {}
	for title in pairs(dlcTitlesSet) do
		table.insert(sortedDlcTitles, title)
	end
	table.sort(sortedDlcTitles)
	local labels = { DocumentationHTMLUtil.BASEGAME_GROUP_LABEL }
	for _, title in ipairs(sortedDlcTitles) do
		table.insert(labels, title)
	end
	return labels
end
DocumentationManager.SECTION_DISPLAY_ORDER = { vehicles = 1, placeables = 2, brands = 3, fruitTypes = 4, fillTypes = 5 }
function DocumentationManager.getSectionDisplayRank(generatorId, registrationIndex)
	local rank = DocumentationManager.SECTION_DISPLAY_ORDER[generatorId]
	if rank ~= nil then
		return rank
	else
		local fallbackBase = 1000
		return fallbackBase + registrationIndex
	end
end
function DocumentationManager:appendOverviewGroup(html, sourceLabel)
	local cards = {}
	for registrationIndex, generator in ipairs(self.generators) do
		local count = DocumentationManager.countItemsForSource(generator.items, sourceLabel)
		if 0 < count then
			table.insert(cards, { count = count, name = generator.name, id = generator.id, description = generator.description, rank = DocumentationManager.getSectionDisplayRank(generator.id, registrationIndex) })
		end
	end
	if #cards == 0 then
		return
	else
		table.sort(cards, function(a, b)
			return a.rank < b.rank
		end)
		table.insert(html, string.format('<h3 style="margin: 32px 0 16px 0;">%s</h3>', DocumentationHTMLUtil.escapeHTML(sourceLabel)))
		table.insert(html, '<div class="section-grid">')
		for _, card in ipairs(cards) do
			table.insert(html, '<div class="section-card">')
			table.insert(html, string.format("  <h2>%s</h2>", DocumentationHTMLUtil.escapeHTML(card.name)))
			table.insert(html, string.format('  <div class="count">%d</div>', card.count))
			table.insert(html, string.format('  <div class="desc">%s</div>', DocumentationHTMLUtil.escapeHTML(card.description)))
			table.insert(html, string.format('  <a href="%s/%s">Browse</a>', card.id, DocumentationHTMLUtil.getOverviewFilename(sourceLabel)))
			table.insert(html, "</div>")
		end
		table.insert(html, "</div>")
	end
end
function DocumentationManager:generateMasterOverview(baseDir)
	local breadcrumbs = { { text = "Documentation" } }
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader("Documentation Overview", breadcrumbs, "style.css"))
	table.insert(html, '<h2 style="margin-bottom: 24px;">Documentation Overview</h2>')
	for _, sourceLabel in ipairs(self:collectSourceLabels()) do
		self:appendOverviewGroup(html, sourceLabel)
	end
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(baseDir .. "overview.html", table.concat(html, "\n"))
end
g_documentationManager = DocumentationManager.new()
g_documentationManager:addGenerator(FruitTypeDocGenerator.new())
g_documentationManager:addGenerator(FillTypeDocGenerator.new())
g_documentationManager:addGenerator(PlaceableDocGenerator.new())
g_documentationManager:addGenerator(VehicleDocGenerator.new())
g_documentationManager:addGenerator(BrandDocGenerator.new())
addConsoleCommand("gsGenerateDocumentation", "Generates HTML documentation for marketing", "DocumentationManager.consoleCommandGenerateDocumentation", nil)
