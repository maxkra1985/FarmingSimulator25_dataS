VehicleDocGenerator = {}
local VehicleDocGenerator_mt = Class(VehicleDocGenerator, DocumentationGenerator)
function VehicleDocGenerator.new()
	local self = DocumentationGenerator.new(VehicleDocGenerator_mt)
	self.name = "Vehicles"
	self.id = "vehicles"
	self.description = "All drivable vehicles and attachable implements available in the shop"
	return self
end
function VehicleDocGenerator:collectData()
	self.items = {}
	for _, storeItem in ipairs(g_storeManager:getItems()) do
		if storeItem.species == StoreSpecies.VEHICLE and storeItem.showInStore then
			if storeItem.isBundleItem then
				continue
			end
			local item = {}
			item.name = storeItem.name or "Unknown"
			item.title = item.name
			item.vehicleType = storeItem.vehicleType or ""
			item.price = storeItem.price or 0
			item.dailyUpkeep = storeItem.dailyUpkeep or 0
			item.runningLeasingFactor = storeItem.runningLeasingFactor or 0
			item.lifetime = storeItem.lifetime or 0
			item.canBeSold = storeItem.canBeSold
			item.hasLicensePlates = storeItem.hasLicensePlates == true
			item.categoryNames = storeItem.categoryNames or {}
			item.brandIndex = storeItem.brandIndex
			local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
			item.brandName = brand ~= nil and brand.title or ""
			item.brandInternalName = brand ~= nil and brand.name or ""
			item.imageSource = storeItem.imageFilename
			local networkPath = DocumentationHTMLUtil.toNetworkPath(item.imageSource)
			if networkPath ~= nil then
				item.imageSource = DocumentationHTMLUtil.resolvePdlcPath(networkPath) or item.imageSource
			end
			item.functions = storeItem.functions or {}
			item.dlcTitle = storeItem.dlcTitle
			item.xmlFilename = DocumentationHTMLUtil.stripBasePath(storeItem.xmlFilename)
			local specs = storeItem.specs or {}
			item.power = specs.power
			item.maxSpeed = specs.maxSpeed
			item.speedLimit = specs.speedLimit
			item.workingWidthRaw = specs.workingWidth
			item.weightRaw = specs.weight
			item.weight = VehicleDocGenerator.extractWeightKg(item.weightRaw)
			if type(item.workingWidthRaw) == "table" then
				item.workingWidth = item.workingWidthRaw.width
			elseif type(item.workingWidthRaw) == "number" then
				item.workingWidth = item.workingWidthRaw
			end
			table.insert(self.items, item)
		end
	end
	table.sort(self.items, function(a, b)
		if a.brandName == b.brandName then
			return a.name < b.name
		else
			return a.brandName < b.brandName
		end
	end)
end
function VehicleDocGenerator.createRichDataTable(rows)
	local html = {}
	table.insert(html, '<table class="data-table">')
	for _, row in ipairs(rows) do
		local label = row[1] or ""
		local value = row[2]
		if value == nil then
			value = "\226\128\148"
		elseif type(value) == "boolean" then
			if value then
				value = '<span class="badge badge-yes">Yes</span>'
			else
				value = '<span class="badge badge-no">No</span>'
			end
		else
			value = tostring(value)
		end
		table.insert(html, string.format("  <tr><td>%s</td><td>%s</td></tr>", DocumentationHTMLUtil.escapeHTML(label), value))
	end
	table.insert(html, "</table>")
	return table.concat(html, "\n")
end
function VehicleDocGenerator.extractWeightKg(weightData)
	if weightData == nil then
		return nil
	elseif type(weightData) == "number" then
		return weightData
	else
		if type(weightData) == "table" then
			if weightData.storeDataMin ~= nil then
				return weightData.storeDataMin
			end
			if weightData.componentMass ~= nil then
				return weightData.componentMass
			end
		end
		return nil
	end
end
function VehicleDocGenerator:generateItemPage(dir, item)
	local filename = VehicleDocGenerator.getItemFilename(item)
	local shopImageUrl = DocumentationHTMLUtil.getImageRelativeURL(item.imageSource, dir)
	item.shopImageUrl = shopImageUrl
	local sourceLabel = item.dlcTitle or DocumentationHTMLUtil.BASEGAME_GROUP_LABEL
	local breadcrumbs = { { text = "Documentation", url = "../../documentation/overview.html" }, _v224, {} }
	local _v224 = {}
	_v224.text = DocumentationGenerator.getOverviewQualifiedName("Vehicles", sourceLabel)
	local _v67 = DocumentationHTMLUtil.getOverviewFilename(sourceLabel)
	_v224.url = _v67
	_v67.text = item.title
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(item.title, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s</h2>', DocumentationHTMLUtil.escapeHTML(item.title)))
	if shopImageUrl ~= "" then
		table.insert(html, string.format('<div class="card"><div class="card-body" style="text-align:center; background-color:#e8ece8; padding:24px;"><img src="%s" alt="%s" style="max-width:480px; max-height:320px;"></div></div>', shopImageUrl, DocumentationHTMLUtil.escapeHTML(item.title)))
	end
	local categoriesStr = 0 < #item.categoryNames and table.concat(item.categoryNames, ", ") or "\226\128\148"
	local brandCell = "\226\128\148"
	if item.brandName ~= "" then
		local brandLink = "../brands/" .. DocumentationHTMLUtil.sanitizeFilename(item.brandInternalName) .. ".html"
		brandCell = string.format('<a href="%s">%s</a>', brandLink, DocumentationHTMLUtil.escapeHTML(item.brandName))
	end
	local overviewRows = { { "Name", item.name }, { "Brand", brandCell }, { "Vehicle Type", item.vehicleType ~= "" and item.vehicleType or "\226\128\148" }, { "Categories", categoriesStr } }
	if item.dlcTitle ~= nil then
		table.insert(overviewRows, { "DLC", item.dlcTitle })
	end
	table.insert(html, DocumentationHTMLUtil.createCard("Overview", VehicleDocGenerator.createRichDataTable(overviewRows)))
	table.insert(html, DocumentationHTMLUtil.createCard("Economy", DocumentationHTMLUtil.createDataTable({ { "Purchase Price", DocumentationHTMLUtil.formatNumber(item.price, "$") }, { "Daily Upkeep", DocumentationHTMLUtil.formatNumber(item.dailyUpkeep, "$/day") }, { "Running Leasing Factor", DocumentationHTMLUtil.formatNumber(item.runningLeasingFactor, nil, 4) }, { "Lifetime (in-game hours)", DocumentationHTMLUtil.formatNumber(item.lifetime, "h") }, { "Can Be Sold", item.canBeSold }, { "Has License Plates", item.hasLicensePlates } })))
	local specRows = {}
	if item.power ~= nil then
		table.insert(specRows, { "Engine Power", DocumentationHTMLUtil.formatNumber(item.power, "hp", 0) })
	end
	if item.maxSpeed ~= nil then
		table.insert(specRows, { "Max. Speed", DocumentationHTMLUtil.formatNumber(item.maxSpeed, "km/h", 0) })
	end
	if item.speedLimit ~= nil then
		table.insert(specRows, { "Working Speed", DocumentationHTMLUtil.formatNumber(item.speedLimit, "km/h", 0) })
	end
	if item.workingWidth ~= nil then
		table.insert(specRows, { "Working Width", DocumentationHTMLUtil.formatNumber(item.workingWidth, "m", 1) })
	end
	if item.weight ~= nil then
		table.insert(specRows, { "Weight", DocumentationHTMLUtil.formatNumber(item.weight, "kg", 0) })
	end
	if 0 < #specRows then
		table.insert(html, DocumentationHTMLUtil.createCard("Specifications", DocumentationHTMLUtil.createDataTable(specRows)))
	end
	if 0 < #item.functions then
		local functionsHTML = '<ul style="margin: 0; padding-left: 20px;">'
		for _, func in ipairs(item.functions) do
			functionsHTML = functionsHTML .. string.format("<li>%s</li>", DocumentationHTMLUtil.escapeHTML(tostring(func)))
		end
		functionsHTML = functionsHTML .. "</ul>"
		table.insert(html, DocumentationHTMLUtil.createCard("Functions", functionsHTML))
	end
	if item.xmlFilename ~= "" then
		table.insert(html, DocumentationHTMLUtil.createCard("Source", DocumentationHTMLUtil.createDataTable({ { "XML File", item.xmlFilename } })))
	end
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. filename, table.concat(html, "\n"))
end
function VehicleDocGenerator.getItemFilename(item)
	local base = DocumentationHTMLUtil.sanitizeFilename(item.name)
	if item.brandName ~= nil and item.brandName ~= "" then
		base = DocumentationHTMLUtil.sanitizeFilename(item.brandName) .. "_" .. base
	end
	return base .. ".html"
end
function VehicleDocGenerator:generateOverviewPage(dir, sourceLabel, items)
	local qualifiedName = DocumentationGenerator.getOverviewQualifiedName("Vehicles", sourceLabel)
	local breadcrumbs = { { text = "Documentation", url = "../overview.html" }, { text = qualifiedName } }
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(qualifiedName, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s (%d)</h2>', DocumentationHTMLUtil.escapeHTML(qualifiedName), #items))
	table.insert(html, '<div class="card"><div class="card-body">')
	table.insert(html, '<table class="doc-table">')
	table.insert(html, "<thead><tr>")
	table.insert(html, '<th data-sort="string">Name<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Brand<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Type<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Price<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="string">Category<span class="sort-arrow"></span></th>')
	table.insert(html, "</tr></thead>")
	table.insert(html, "<tbody>")
	for _, item in ipairs(items) do
		local link = VehicleDocGenerator.getItemFilename(item)
		local category = 0 < #item.categoryNames and item.categoryNames[1] or ""
		local brandCell = nil
		if item.brandName ~= "" then
			local brandLink = "../brands/" .. DocumentationHTMLUtil.sanitizeFilename(item.brandInternalName) .. ".html"
			brandCell = string.format('<a href="%s">%s</a>', brandLink, DocumentationHTMLUtil.escapeHTML(item.brandName))
		else
			brandCell = "\226\128\148"
		end
		table.insert(html, "<tr>")
		table.insert(html, string.format('<td><a href="%s">%s</a></td>', link, DocumentationHTMLUtil.escapeHTML(item.title)))
		table.insert(html, string.format('<td data-value="%s">%s</td>', DocumentationHTMLUtil.escapeHTML(item.brandName), brandCell))
		table.insert(html, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(item.vehicleType)))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.price, DocumentationHTMLUtil.formatNumber(item.price, "$")))
		table.insert(html, string.format("<td>%s</td>", DocumentationHTMLUtil.escapeHTML(category)))
		table.insert(html, "</tr>")
	end
	table.insert(html, "</tbody></table>")
	table.insert(html, "</div></div>")
	table.insert(html, DocumentationHTMLUtil.getSortScript())
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. DocumentationHTMLUtil.getOverviewFilename(sourceLabel), table.concat(html, "\n"))
end
