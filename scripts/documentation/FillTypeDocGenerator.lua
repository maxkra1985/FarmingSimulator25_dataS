FillTypeDocGenerator = {}
local FillTypeDocGenerator_mt = Class(FillTypeDocGenerator, DocumentationGenerator)
function FillTypeDocGenerator.new()
	local self = DocumentationGenerator.new(FillTypeDocGenerator_mt)
	self.name = "Fill Types"
	self.id = "fillTypes"
	self.description = "All materials, crops, and products that can be stored and transported"
	return self
end
function FillTypeDocGenerator:collectData()
	self.items = {}
	self.categories = {}
	for categoryName, fillTypes in pairs(g_fillTypeManager.categoryNameToFillTypes) do
		for _, fillType in ipairs(fillTypes) do
			if self.categories[fillType.name] == nil then
				self.categories[fillType.name] = {}
			end
			table.insert(self.categories[fillType.name], categoryName)
		end
	end
	for _, fillTypeDesc in ipairs(g_fillTypeManager.fillTypes) do
		if fillTypeDesc.name == "UNKNOWN" then
			continue
		end
		local item = {}
		item.name = fillTypeDesc.name
		item.title = fillTypeDesc.title or fillTypeDesc.name
		item.index = fillTypeDesc.index
		item.unitShort = fillTypeDesc.unitShort or ""
		item.pricePerLiter = fillTypeDesc.pricePerLiter or 0
		item.showOnPriceTable = fillTypeDesc.showOnPriceTable
		item.massPerLiter = fillTypeDesc.massPerLiter or 0.001
		item.maxPhysicalSurfaceAngle = fillTypeDesc.maxPhysicalSurfaceAngle
		item.isBulkType = fillTypeDesc.isBulkType
		item.isPalletType = fillTypeDesc.isPalletType
		item.isBaleType = fillTypeDesc.isBaleType
		item.prioritizedEffectType = fillTypeDesc.prioritizedEffectType
		item.palletFilename = fillTypeDesc.palletFilename ~= nil and DocumentationHTMLUtil.stripBasePath(fillTypeDesc.palletFilename) or nil
		item.economyFactors = fillTypeDesc.economy.factors
		item.categoryNames = self.categories[fillTypeDesc.name] or {}
		table.insert(self.items, item)
	end
	table.sort(self.items, function(a, b)
		return a.name < b.name
	end)
end
function FillTypeDocGenerator:generateItemPage(dir, item)
	local filename = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
	local breadcrumbs = { { text = "Documentation", url = "../../documentation/overview.html" }, { text = "Fill Types", url = _v86 }, {} }
	local _v86 = "overview.html"
	_v86.text = item.title
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(item.title, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s</h2>', DocumentationHTMLUtil.escapeHTML(item.title)))
	local categoriesStr = 0 < #item.categoryNames and table.concat(item.categoryNames, ", ") or "None"
	table.insert(html, DocumentationHTMLUtil.createCard("Overview", DocumentationHTMLUtil.createDataTable({ { "Internal Name", item.name }, { "Display Name", item.title }, { "Unit", item.unitShort }, { "Categories", categoriesStr }, { "Shown on Price Table", item.showOnPriceTable } })))
	local massPerKg = item.massPerLiter * 1000
	local angleInDeg = math.deg(item.maxPhysicalSurfaceAngle or 0)
	table.insert(html, DocumentationHTMLUtil.createCard("Physics", DocumentationHTMLUtil.createDataTable({ { "Mass per Liter", DocumentationHTMLUtil.formatNumber(item.massPerLiter * 1000, "g", 1) }, { "Density (kg/m\194\179)", DocumentationHTMLUtil.formatNumber(massPerKg, "kg/m\194\179", 1) }, { "Max Surface Angle", DocumentationHTMLUtil.formatNumber(angleInDeg, "\194\176", 1) } })))
	table.insert(html, DocumentationHTMLUtil.createCard("Handling", DocumentationHTMLUtil.createDataTable({ { "Bulk Type (tippable)", item.isBulkType }, { "Pallet Type", item.isPalletType }, { "Bale Type", item.isBaleType }, { "Effect Type", item.prioritizedEffectType or "\226\128\148" } })))
	if item.palletFilename ~= nil then
		table.insert(html, DocumentationHTMLUtil.createCard("Pallet", DocumentationHTMLUtil.createDataTable({ { "Pallet XML", item.palletFilename } })))
	end
	table.insert(html, DocumentationHTMLUtil.createCard("Economy", DocumentationHTMLUtil.createDataTable({ { "Base Price per Liter", DocumentationHTMLUtil.formatNumber(item.pricePerLiter, "$", 3) }, { "Base Price per 1000L", DocumentationHTMLUtil.formatNumber(item.pricePerLiter * 1000, "$") } })))
	if item.economyFactors ~= nil and next(item.economyFactors) ~= nil then
		table.insert(html, DocumentationHTMLUtil.createCard("Seasonal Price Factors", DocumentationHTMLUtil.createSeasonTable(item.economyFactors, item.pricePerLiter * 1000)))
	end
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. filename, table.concat(html, "\n"))
end
function FillTypeDocGenerator:generateOverviewPage(dir, sourceLabel, items)
	local qualifiedName = DocumentationGenerator.getOverviewQualifiedName("Fill Types", sourceLabel)
	local breadcrumbs = { { text = "Documentation", url = "../overview.html" }, { text = qualifiedName } }
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(qualifiedName, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s (%d)</h2>', DocumentationHTMLUtil.escapeHTML(qualifiedName), #items))
	table.insert(html, '<div class="card"><div class="card-body">')
	table.insert(html, '<table class="doc-table">')
	table.insert(html, "<thead><tr>")
	table.insert(html, '<th data-sort="string">Name<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Title<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Price/1000L<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Density<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Bulk<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Pallet<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Bale<span class="sort-arrow"></span></th>')
	table.insert(html, "</tr></thead>")
	table.insert(html, "<tbody>")
	for _, item in ipairs(items) do
		local link = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
		local pricePerK = item.pricePerLiter * 1000
		local density = item.massPerLiter * 1000
		table.insert(html, "<tr>")
		table.insert(html, string.format('<td><a href="%s">%s</a></td>', link, DocumentationHTMLUtil.escapeHTML(item.name)))
		table.insert(html, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(item.title)))
		table.insert(html, string.format('<td data-value="%.2f">%s</td>', pricePerK, DocumentationHTMLUtil.formatNumber(pricePerK, "$")))
		table.insert(html, string.format('<td data-value="%.1f">%s</td>', density, DocumentationHTMLUtil.formatNumber(density, "kg/m\194\179", 1)))
		table.insert(html, string.format("<td>%s</td>", item.isBulkType and "Yes" or ""))
		table.insert(html, string.format("<td>%s</td>", item.isPalletType and "Yes" or ""))
		table.insert(html, string.format("<td>%s</td>", item.isBaleType and "Yes" or ""))
		table.insert(html, "</tr>")
	end
	table.insert(html, "</tbody></table>")
	table.insert(html, "</div></div>")
	table.insert(html, DocumentationHTMLUtil.getSortScript())
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. DocumentationHTMLUtil.getOverviewFilename(sourceLabel), table.concat(html, "\n"))
end
