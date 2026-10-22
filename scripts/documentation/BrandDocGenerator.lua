BrandDocGenerator = {}
local BrandDocGenerator_mt = Class(BrandDocGenerator, DocumentationGenerator)
BrandDocGenerator.ALWAYS_USED_BRANDS = { BKT = true, CONTINENTAL = true, ELTEN = true, LELY = true, MICHELIN = true, MITAS = true, NOKIAN = true, OLOFSFORS = true, STRAUSS = true, TRELLEBORG = true }
function BrandDocGenerator.new()
	local self = DocumentationGenerator.new(BrandDocGenerator_mt)
	self.name = "Brands"
	self.id = "brands"
	self.description = "Manufacturer brands referenced by vehicles and other store items"
	return self
end
function BrandDocGenerator:collectData()
	self.items = {}
	local storeItems = g_storeManager:getItems()
	local itemsByBrandIndex = {}
	for _, storeItem in ipairs(storeItems) do
		if storeItem.brandIndex == nil then
			continue
		end
		if storeItem.showInStore then
			if storeItem.isBundleItem then
				continue
			end
			itemsByBrandIndex[storeItem.brandIndex] = itemsByBrandIndex[storeItem.brandIndex] or {}
			table.insert(itemsByBrandIndex[storeItem.brandIndex], storeItem)
		end
	end
	for brandIndex, brand in pairs(g_brandManager.indexToBrand) do
		local referencingItems = itemsByBrandIndex[brandIndex] or {}
		local isAlwaysUsed = BrandDocGenerator.ALWAYS_USED_BRANDS[brand.name] == true
		if #referencingItems ~= 0 or isAlwaysUsed then
			local item = {}
			item.name = brand.name
			item.title = brand.title or brand.name
			item.index = brandIndex
			item.image = DocumentationHTMLUtil.stripBasePath(brand.image)
			item.imageShopOverview = DocumentationHTMLUtil.stripBasePath(brand.imageShopOverview)
			item.imageSource = brand.image
			local iconNetworkPath = DocumentationHTMLUtil.toNetworkPath(item.imageSource)
			if iconNetworkPath ~= nil then
				item.imageSource = DocumentationHTMLUtil.resolvePdlcPath(iconNetworkPath) or item.imageSource
			end
			item.imageShopOverviewSource = brand.imageShopOverview
			local shopNetworkPath = DocumentationHTMLUtil.toNetworkPath(item.imageShopOverviewSource)
			if shopNetworkPath ~= nil then
				item.imageShopOverviewSource = DocumentationHTMLUtil.resolvePdlcPath(shopNetworkPath) or item.imageShopOverviewSource
			end
			item.isMod = brand.isMod == true
			item.isAlwaysUsed = isAlwaysUsed
			item.vehicleCount = 0
			item.handToolCount = 0
			item.placeableCount = 0
			item.otherCount = 0
			item.vehicles = {}
			item.otherItems = {}
			for _, storeItem in ipairs(referencingItems) do
				if storeItem.species == StoreSpecies.VEHICLE then
					item.vehicleCount = item.vehicleCount + 1
					table.insert(item.vehicles, { name = storeItem.name or "Unknown", vehicleType = storeItem.vehicleType or "", category = storeItem.categoryNames ~= nil and storeItem.categoryNames[1] or "", price = storeItem.price or 0, dlcTitle = storeItem.dlcTitle })
				else
					if storeItem.species == StoreSpecies.HANDTOOL then
						item.handToolCount = item.handToolCount + 1
					elseif storeItem.species == StoreSpecies.PLACEABLE then
						item.placeableCount = item.placeableCount + 1
					else
						item.otherCount = item.otherCount + 1
					end
					table.insert(item.otherItems, { name = storeItem.name or "Unknown", species = storeItem.species })
				end
			end
			item.itemCount = item.vehicleCount + item.handToolCount + item.placeableCount + item.otherCount
			table.sort(item.vehicles, function(a, b)
				return a.name < b.name
			end)
			table.sort(item.otherItems, function(a, b)
				return a.name < b.name
			end)
			table.insert(self.items, item)
		end
	end
	table.sort(self.items, function(a, b)
		return utf8ToUpper(a.title) < utf8ToUpper(b.title)
	end)
end
function BrandDocGenerator.getSpeciesLabel(species)
	if species == StoreSpecies.VEHICLE then
		return "Vehicle"
	elseif species == StoreSpecies.HANDTOOL then
		return "Hand Tool"
	elseif species == StoreSpecies.PLACEABLE then
		return "Placeable"
	elseif species == StoreSpecies.ANIMAL then
		return "Animal"
	elseif species == StoreSpecies.OBJECT then
		return "Object"
	else
		return "Other"
	end
end
function BrandDocGenerator:getBrandIconURL(dir, item)
	return DocumentationHTMLUtil.getImageRelativeURL(item.imageSource, dir)
end
function BrandDocGenerator:generateItemPage(dir, item)
	local filename = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
	local iconUrl = self:getBrandIconURL(dir, item)
	local breadcrumbs = { { text = "Documentation", url = "../../documentation/overview.html" }, { text = "Brands", url = _v219 }, {} }
	local _v219 = "overview.html"
	_v219.text = item.title
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(item.title, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s</h2>', DocumentationHTMLUtil.escapeHTML(item.title)))
	if iconUrl ~= "" then
		table.insert(html, string.format('<div class="card"><div class="card-body" style="text-align:center; background-color:#e8ece8; padding:24px;"><img src="%s" alt="%s" style="max-width:320px; max-height:160px;"></div></div>', iconUrl, DocumentationHTMLUtil.escapeHTML(item.title)))
	end
	local overviewRows = { { "Internal Name", item.name }, { "Display Name", item.title }, { "Total Store Items", tostring(item.itemCount) }, { "Vehicles", tostring(item.vehicleCount) }, { "Hand Tools", tostring(item.handToolCount) }, { "Placeables", tostring(item.placeableCount) }, { "Mod Brand", item.isMod } }
	if item.isAlwaysUsed then
		table.insert(overviewRows, { "Always Marked as Used", true })
	end
	table.insert(html, DocumentationHTMLUtil.createCard("Overview", DocumentationHTMLUtil.createDataTable(overviewRows)))
	if 0 < #item.vehicles then
		local vehicleTable = {}
		table.insert(vehicleTable, '<table class="doc-table">')
		table.insert(vehicleTable, "<thead><tr>")
		table.insert(vehicleTable, "<th>Name</th>")
		table.insert(vehicleTable, "<th>Type</th>")
		table.insert(vehicleTable, "<th>Category</th>")
		table.insert(vehicleTable, "<th>Price</th>")
		table.insert(vehicleTable, "<th>DLC</th>")
		table.insert(vehicleTable, "</tr></thead><tbody>")
		for _, vehicle in ipairs(item.vehicles) do
			local vehicleLink = "../vehicles/" .. VehicleDocGenerator.getItemFilename({ name = vehicle.name, brandName = item.title })
			table.insert(vehicleTable, "<tr>")
			table.insert(vehicleTable, string.format('<td><a href="%s">%s</a></td>', vehicleLink, DocumentationHTMLUtil.escapeHTML(vehicle.name)))
			table.insert(vehicleTable, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(vehicle.vehicleType)))
			table.insert(vehicleTable, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(vehicle.category)))
			table.insert(vehicleTable, string.format("<td>%s</td>", DocumentationHTMLUtil.formatNumber(vehicle.price, "$")))
			table.insert(vehicleTable, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(vehicle.dlcTitle or "")))
			table.insert(vehicleTable, "</tr>")
		end
		table.insert(vehicleTable, "</tbody></table>")
		table.insert(html, DocumentationHTMLUtil.createCard("Vehicles", table.concat(vehicleTable, "\n")))
	end
	if 0 < #item.otherItems then
		local otherHTML = '<ul style="margin: 0; padding-left: 20px;">'
		for _, otherItem in ipairs(item.otherItems) do
			otherHTML = otherHTML .. string.format('<li>%s <span style="color:#888;">(%s)</span></li>', DocumentationHTMLUtil.escapeHTML(otherItem.name), DocumentationHTMLUtil.escapeHTML(BrandDocGenerator.getSpeciesLabel(otherItem.species)))
		end
		otherHTML = otherHTML .. "</ul>"
		table.insert(html, DocumentationHTMLUtil.createCard("Other Store Items", otherHTML))
	end
	local sourceRows = {}
	if item.image ~= "" then
		table.insert(sourceRows, { "Icon", item.image })
	end
	if item.imageShopOverview ~= "" and item.imageShopOverview ~= item.image then
		table.insert(sourceRows, { "Shop Overview Icon", item.imageShopOverview })
	end
	if 0 < #sourceRows then
		table.insert(html, DocumentationHTMLUtil.createCard("Source", DocumentationHTMLUtil.createDataTable(sourceRows)))
	end
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. filename, table.concat(html, "\n"))
end
function BrandDocGenerator:generateOverviewPage(dir, sourceLabel, items)
	local qualifiedName = DocumentationGenerator.getOverviewQualifiedName("Brands", sourceLabel)
	local breadcrumbs = { { text = "Documentation", url = "../overview.html" }, { text = qualifiedName } }
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(qualifiedName, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s (%d)</h2>', DocumentationHTMLUtil.escapeHTML(qualifiedName), #items))
	table.insert(html, '<p style="margin: 0 0 16px 0; color:#666;">Only brands that are referenced by at least one in-game store item (or are part of the always-used allowlist such as tire manufacturers) are listed here.</p>')
	table.insert(html, '<div class="card"><div class="card-body">')
	table.insert(html, '<table class="doc-table">')
	table.insert(html, "<thead><tr>")
	table.insert(html, "<th>Icon</th>")
	table.insert(html, '<th data-sort="string">Name<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Internal Name<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Vehicles<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Hand Tools<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Placeables<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Total Items<span class="sort-arrow"></span></th>')
	table.insert(html, "</tr></thead>")
	table.insert(html, "<tbody>")
	for _, item in ipairs(items) do
		local link = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
		local iconUrl = self:getBrandIconURL(dir, item)
		local iconCell = "\226\128\148"
		if iconUrl ~= "" then
			iconCell = string.format('<a href="%s"><img src="%s" alt="" style="max-height:32px; max-width:80px;"></a>', link, iconUrl)
		end
		table.insert(html, "<tr>")
		table.insert(html, string.format('<td style="background-color:#e8ece8; text-align:center;">%s</td>', iconCell))
		table.insert(html, string.format('<td><a href="%s">%s</a></td>', link, DocumentationHTMLUtil.escapeHTML(item.title)))
		table.insert(html, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(item.name)))
		table.insert(html, string.format('<td data-value="%d">%d</td>', item.vehicleCount, item.vehicleCount))
		table.insert(html, string.format('<td data-value="%d">%d</td>', item.handToolCount, item.handToolCount))
		table.insert(html, string.format('<td data-value="%d">%d</td>', item.placeableCount, item.placeableCount))
		table.insert(html, string.format('<td data-value="%d">%d</td>', item.itemCount, item.itemCount))
		table.insert(html, "</tr>")
	end
	table.insert(html, "</tbody></table>")
	table.insert(html, "</div></div>")
	table.insert(html, DocumentationHTMLUtil.getSortScript())
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. DocumentationHTMLUtil.getOverviewFilename(sourceLabel), table.concat(html, "\n"))
end
