DocumentationGenerator = {}
local DocumentationGenerator_mt = Class(DocumentationGenerator)
function DocumentationGenerator.new(customMt)
	local self = setmetatable({}, customMt or DocumentationGenerator_mt)
	self.name = "Unknown"
	self.id = "unknown"
	self.description = ""
	self.items = {}
	return self
end
function DocumentationGenerator:collectData()
	Logging.warning("DocumentationGenerator:collectData() not implemented for '%s'", self.name)
end
function DocumentationGenerator:generate(baseDir)
	self:collectData()
	if #self.items == 0 then
		Logging.warning("DocumentationGenerator: No items collected for '%s', skipping generation", self.name)
	else
		local dir = baseDir .. self.id
		createFolder(dir)
		dir = dir .. "/"
		for _, item in ipairs(self.items) do
			self:generateItemPage(dir, item)
		end
		local basegameItems = {}
		local dlcGroups = {}
		for _, item in ipairs(self.items) do
			if item.dlcTitle == nil or item.dlcTitle == "" then
				table.insert(basegameItems, item)
			else
				if dlcGroups[item.dlcTitle] == nil then
					dlcGroups[item.dlcTitle] = {}
				end
				table.insert(dlcGroups[item.dlcTitle], item)
			end
		end
		local sortedDlcTitles = {}
		for label in pairs(dlcGroups) do
			table.insert(sortedDlcTitles, label)
		end
		table.sort(sortedDlcTitles)
		local overviewCount = 0
		if 0 < #basegameItems then
			self:generateOverviewPage(dir, DocumentationHTMLUtil.BASEGAME_GROUP_LABEL, basegameItems)
			overviewCount = overviewCount + 1
		end
		for _, label in ipairs(sortedDlcTitles) do
			self:generateOverviewPage(dir, label, dlcGroups[label])
			overviewCount = overviewCount + 1
		end
		log(string.format("  Generated %d pages for '%s'", #self.items + overviewCount, self.name))
	end
end
function DocumentationGenerator:generateItemPage(dir, item)
	Logging.warning("DocumentationGenerator:generateItemPage() not implemented for '%s'", self.name)
end
function DocumentationGenerator.getOverviewQualifiedName(sectionName, sourceLabel)
	if sourceLabel == nil or sourceLabel == "" or sourceLabel == DocumentationHTMLUtil.BASEGAME_GROUP_LABEL then
		return sectionName
	end
	return sectionName .. " \194\183 " .. sourceLabel
end
function DocumentationGenerator:generateOverviewPage(dir, sourceLabel, items)
	local qualifiedName = DocumentationGenerator.getOverviewQualifiedName(self.name, sourceLabel)
	local breadcrumbs = { { text = "Documentation", url = "../overview.html" }, { text = qualifiedName } }
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(qualifiedName, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s (%d)</h2>', DocumentationHTMLUtil.escapeHTML(qualifiedName), #items))
	table.insert(html, '<div class="card"><div class="card-body">')
	table.insert(html, '<table class="doc-table">')
	table.insert(html, '<thead><tr><th data-sort="string">Name<span class="sort-arrow"></span></th></tr></thead>')
	table.insert(html, "<tbody>")
	for _, item in ipairs(items) do
		local filename = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
		local displayName = item.title or item.name
		table.insert(html, string.format('<tr><td><a href="%s">%s</a></td></tr>', filename, DocumentationHTMLUtil.escapeHTML(displayName)))
	end
	table.insert(html, "</tbody></table>")
	table.insert(html, "</div></div>")
	table.insert(html, DocumentationHTMLUtil.getSortScript())
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. DocumentationHTMLUtil.getOverviewFilename(sourceLabel), table.concat(html, "\n"))
end
function DocumentationGenerator:getSummary()
	return { name = self.name, id = self.id, count = #self.items, description = self.description }
end
