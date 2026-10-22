PlaceableDocGenerator = {}
local PlaceableDocGenerator_mt = Class(PlaceableDocGenerator, DocumentationGenerator)
function PlaceableDocGenerator.new()
	local self = DocumentationGenerator.new(PlaceableDocGenerator_mt)
	self.name = "Placeables"
	self.id = "placeables"
	self.description = "Buildings, production facilities, and other placeable objects"
	return self
end
function PlaceableDocGenerator:collectData()
	self.items = {}
	for _, storeItem in ipairs(g_storeManager:getItems()) do
		if storeItem.species == StoreSpecies.PLACEABLE and storeItem.showInStore then
			local item = {}
			item.name = storeItem.name or "Unknown"
			item.title = storeItem.name or "Unknown"
			item.price = storeItem.price or 0
			item.dailyUpkeep = storeItem.dailyUpkeep or 0
			item.canBeSold = storeItem.canBeSold
			item.lifetime = storeItem.lifetime or 0
			item.categoryNames = storeItem.categoryNames or {}
			local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
			item.brandName = brand ~= nil and brand.title or ""
			item.functions = storeItem.functions or {}
			item.xmlFilename = DocumentationHTMLUtil.stripBasePath(storeItem.xmlFilename)
			item.dlcTitle = storeItem.dlcTitle
			item.imageFilename = storeItem.imageFilename
			local networkPath = DocumentationHTMLUtil.toNetworkPath(item.imageFilename)
			if networkPath ~= nil then
				item.imageFilename = DocumentationHTMLUtil.resolvePdlcPath(networkPath) or item.imageFilename
			end
			table.insert(self.items, item)
		end
	end
	table.sort(self.items, function(a, b)
		return a.name < b.name
	end)
end
function PlaceableDocGenerator:generateItemPage(dir, item)
	local filename = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
	local sourceLabel = item.dlcTitle or DocumentationHTMLUtil.BASEGAME_GROUP_LABEL
	local breadcrumbs = { { text = "Documentation", url = "../../documentation/overview.html" }, _v90, {} }
	local _v90 = {}
	_v90.text = DocumentationGenerator.getOverviewQualifiedName("Placeables", sourceLabel)
	local _v140 = DocumentationHTMLUtil.getOverviewFilename(sourceLabel)
	_v90.url = _v140
	_v140.text = item.title
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(item.title, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s</h2>', DocumentationHTMLUtil.escapeHTML(item.title)))
	local shopImageUrl = DocumentationHTMLUtil.getImageRelativeURL(item.imageFilename, dir)
	if shopImageUrl ~= "" then
		table.insert(html, string.format('<div class="card"><div class="card-body" style="text-align:center; background-color:#e8ece8; padding:24px;"><img src="%s" alt="%s" style="max-width:480px; max-height:320px;"></div></div>', shopImageUrl, DocumentationHTMLUtil.escapeHTML(item.title)))
	end
	local categoriesStr = 0 < #item.categoryNames and table.concat(item.categoryNames, ", ") or "\226\128\148"
	local overviewRows = { { "Name", item.name }, { "Brand", item.brandName ~= "" and item.brandName or "\226\128\148" }, { "Categories", categoriesStr } }
	if item.dlcTitle ~= nil then
		table.insert(overviewRows, { "DLC", item.dlcTitle })
	end
	table.insert(html, DocumentationHTMLUtil.createCard("Overview", DocumentationHTMLUtil.createDataTable(overviewRows)))
	local func = { { "Purchase Price", DocumentationHTMLUtil.formatNumber(item.price, "$") }, { "Daily Upkeep", DocumentationHTMLUtil.formatNumber(item.dailyUpkeep, "$/day") }, { "Lifetime (in-game hours)", DocumentationHTMLUtil.formatNumber(item.lifetime, "h") }, { "Can Be Sold", item.canBeSold } }
	table.insert(html, DocumentationHTMLUtil.createCard("Economy", DocumentationHTMLUtil.createDataTable(func)))
	if 0 < #item.functions then
		local functionsHTML = '<ul style="margin: 0; padding-left: 20px;">'
		for _, func in ipairs(item.functions) do
			functionsHTML = functionsHTML .. string.format("<li>%s</li>", DocumentationHTMLUtil.escapeHTML(tostring(func)))
		end
		functionsHTML = functionsHTML .. "</ul>"
		table.insert(html, DocumentationHTMLUtil.createCard("Functions", functionsHTML))
	end
	table.insert(html, DocumentationHTMLUtil.createCard("Source", DocumentationHTMLUtil.createDataTable({ { "XML File", item.xmlFilename } })))
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. filename, table.concat(html, "\n"))
end
function PlaceableDocGenerator:generateOverviewPage(dir, sourceLabel, items)
	local qualifiedName = DocumentationGenerator.getOverviewQualifiedName("Placeables", sourceLabel)
	local breadcrumbs = { { text = "Documentation", url = "../overview.html" }, { text = qualifiedName } }
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(qualifiedName, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s (%d)</h2>', DocumentationHTMLUtil.escapeHTML(qualifiedName), #items))
	table.insert(html, '<div class="card"><div class="card-body">')
	table.insert(html, '<table class="doc-table">')
	table.insert(html, "<thead><tr>")
	table.insert(html, '<th data-sort="string">Name<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Brand<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Price<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Daily Upkeep<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Category<span class="sort-arrow"></span></th>')
	table.insert(html, "</tr></thead>")
	table.insert(html, "<tbody>")
	for _, item in ipairs(items) do
		local link = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
		local category = 0 < #item.categoryNames and item.categoryNames[1] or ""
		table.insert(html, "<tr>")
		table.insert(html, string.format('<td><a href="%s">%s</a></td>', link, DocumentationHTMLUtil.escapeHTML(item.title)))
		table.insert(html, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(item.brandName)))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.price, DocumentationHTMLUtil.formatNumber(item.price, "$")))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.dailyUpkeep, DocumentationHTMLUtil.formatNumber(item.dailyUpkeep, "$")))
		table.insert(html, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(category)))
		table.insert(html, "</tr>")
	end
	table.insert(html, "</tbody></table>")
	table.insert(html, "</div></div>")
	table.insert(html, DocumentationHTMLUtil.getSortScript())
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. DocumentationHTMLUtil.getOverviewFilename(sourceLabel), table.concat(html, "\n"))
end
