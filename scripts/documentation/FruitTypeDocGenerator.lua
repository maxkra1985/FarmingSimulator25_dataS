FruitTypeDocGenerator = {}
local FruitTypeDocGenerator_mt = Class(FruitTypeDocGenerator, DocumentationGenerator)
function FruitTypeDocGenerator.new()
	local self = DocumentationGenerator.new(FruitTypeDocGenerator_mt)
	self.name = "Fruit Types"
	self.id = "fruitTypes"
	self.description = "All crops and plants that can be grown on fields"
	return self
end
function FruitTypeDocGenerator:collectData()
	self.items = {}
	for _, fruitTypeDesc in ipairs(g_fruitTypeManager.fruitTypes) do
		local fillType = fruitTypeDesc.fillType
		local item = {}
		item.name = fruitTypeDesc.name
		item.title = fillType ~= nil and fillType.title or fruitTypeDesc.name
		item.index = fruitTypeDesc.index
		item.shownOnMap = fruitTypeDesc.shownOnMap
		item.useForFieldMissions = fruitTypeDesc.useForFieldMissions
		item.isCatchCrop = fruitTypeDesc.isCatchCrop
		item.numGrowthStates = fruitTypeDesc.numGrowthStates or 0
		item.resetsSpray = fruitTypeDesc.resetsSpray
		item.growthRequiresLime = fruitTypeDesc.growthRequiresLime
		item.regrows = fruitTypeDesc.regrows
		item.literPerSqm = fruitTypeDesc.literPerSqm or 0
		item.yieldPerHa = MathUtil.round((fruitTypeDesc.literPerSqm or 0) * 10000 * 2)
		item.cutHeight = fruitTypeDesc.cutHeight
		item.beeYieldBonusPercentage = fruitTypeDesc.beeYieldBonusPercentage or 0
		item.minHarvestingGrowthState = fruitTypeDesc.minHarvestingGrowthState
		item.maxHarvestingGrowthState = fruitTypeDesc.maxHarvestingGrowthState
		item.seedUsagePerSqm = fruitTypeDesc.seedUsagePerSqm or 0
		item.seedsPerHa = MathUtil.round((fruitTypeDesc.seedUsagePerSqm or 0) * 10000)
		item.needsRolling = fruitTypeDesc.needsRolling
		item.allowsSeeding = fruitTypeDesc.allowsSeeding
		item.plantsWeed = fruitTypeDesc.plantsWeed
		item.lowSoilDensityRequired = fruitTypeDesc.lowSoilDensityRequired
		item.increasesSoilDensity = fruitTypeDesc.increasesSoilDensity
		item.consumesLime = fruitTypeDesc.consumesLime
		item.startSprayLevel = fruitTypeDesc.startSprayLevel
		item.minWeederState = fruitTypeDesc.minWeederState
		item.maxWeederState = fruitTypeDesc.maxWeederState
		item.minWeederHoeState = fruitTypeDesc.minWeederHoeState
		item.maxWeederHoeState = fruitTypeDesc.maxWeederHoeState
		item.plantSpacing = fruitTypeDesc.plantSpacing or 0
		item.xmlFilename = DocumentationHTMLUtil.stripBasePath(fruitTypeDesc.xmlFilename)
		item.witheredState = fruitTypeDesc.witheredState
		if item.witheredState ~= nil then
			item.witheredStateName = fruitTypeDesc.growthStateToName[item.witheredState] or tostring(item.witheredState)
		end
		item.cutState = fruitTypeDesc.cutState
		item.cutStateName = fruitTypeDesc.growthStateToName[fruitTypeDesc.cutState] or tostring(fruitTypeDesc.cutState)
		item.mulchedState = fruitTypeDesc.mulchedState
		local _v31 = fruitTypeDesc.mulchedState
		item.mulchedStateName = tostring(fruitTypeDesc.mulchedState)
		item.hasMulching = fruitTypeDesc.mulchedState ~= 0
		item.minPreparingGrowthState = fruitTypeDesc.minPreparingGrowthState
		item.maxPreparingGrowthState = fruitTypeDesc.maxPreparingGrowthState
		item.preparedGrowthState = fruitTypeDesc.preparedGrowthState
		item.requiresPreparation = 0 <= fruitTypeDesc.minPreparingGrowthState
		item.plantingPeriods = {}
		item.harvestPeriods = {}
		item.growthDuration = 0
		local seasonalData = fruitTypeDesc.growthDataSeasonal
		if seasonalData ~= nil and seasonalData.periods ~= nil then
			self:collectSeasonalData(item, seasonalData)
		end
		if fruitTypeDesc.windrowFillType ~= nil then
			item.windrowFillTypeName = fruitTypeDesc.windrowFillType.name
		end
		if fruitTypeDesc.windrowCutFillType ~= nil then
			item.windrowCutFillTypeName = fruitTypeDesc.windrowCutFillType.name
		end
		item.pricePerLiter = 0
		item.economyFactors = {}
		if fillType ~= nil then
			item.pricePerLiter = fillType.pricePerLiter or 0
			item.economyFactors = fillType.economy.factors
		end
		item.sellPriceEasy = MathUtil.round(item.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[1])
		item.sellPriceMedium = MathUtil.round(item.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[2])
		item.sellPriceHard = MathUtil.round(item.pricePerLiter * 1000 * EconomyManager.PRICE_MULTIPLIER[3])
		item.growthStateNames = {}
		item.weederHoeStates = {}
		for i = 1, item.numGrowthStates do
			item.growthStateNames[i] = fruitTypeDesc.growthStateToName[i] or tostring(i)
			local allowWeeder = fruitTypeDesc.minWeederState <= i and i <= fruitTypeDesc.maxWeederState
			local allowHoe = fruitTypeDesc.minWeederHoeState <= i and i <= fruitTypeDesc.maxWeederHoeState
			item.weederHoeStates[i] = { weeder = allowWeeder, hoe = allowHoe }
		end
		table.insert(self.items, item)
	end
	table.sort(self.items, function(a, b)
		return a.name < b.name
	end)
end
function FruitTypeDocGenerator:collectSeasonalData(item, seasonalData)
	for period = 1, 12 do
		local periodInfo = seasonalData.periods[period]
		if periodInfo == nil then
			continue
		end
		item.plantingPeriods[period] = periodInfo.plantingAllowed == true
		item.harvestPeriods[period] = periodInfo.isHarvestable == true
	end
	local minDuration = nil
	for period = 1, 12 do
		if item.plantingPeriods[period] then
			local state = 1
			for offset = 1, 24 do
				local currentPeriod = (period + offset - 1) % 12 + 1
				local periodInfo = seasonalData.periods[currentPeriod]
				if periodInfo == nil then
					break
				end
				local mapping = periodInfo.growthMapping
				state = mapping[state]
				if item.harvestPeriods[currentPeriod] and (minDuration == nil or offset < minDuration) then
					minDuration = offset
				end
			end
		end
	end
	item.growthDuration = minDuration or 0
end
function FruitTypeDocGenerator:generateItemPage(dir, item)
	local filename = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
	local breadcrumbs = { { text = "Documentation", url = "../../documentation/overview.html" }, { text = "Fruit Types", url = _v168 }, {} }
	local _v168 = "overview.html"
	_v168.text = item.title
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(item.title, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s</h2>', DocumentationHTMLUtil.escapeHTML(item.title)))
	table.insert(html, DocumentationHTMLUtil.createCard("Overview", DocumentationHTMLUtil.createDataTable({ { "Internal Name", item.name }, { "Display Name", item.title }, { "Shown on Map", item.shownOnMap }, { "Catch Crop", item.isCatchCrop }, { "Used for Field Missions", item.useForFieldMissions }, { "Regrows after Harvest", item.regrows } })))
	local growthRows = { { "Growth Stages (" .. tostring(item.numGrowthStates) .. ")", table.concat(item.growthStateNames, ", ") }, { "Harvest States", string.format("%s \226\128\147 %s", item.growthStateNames[item.minHarvestingGrowthState] or tostring(item.minHarvestingGrowthState or 0), item.growthStateNames[item.maxHarvestingGrowthState] or tostring(item.maxHarvestingGrowthState or 0)) }, { "Withers", item.witheredState ~= nil } }
	if item.witheredState ~= nil then
		table.insert(growthRows, { "Withered State", item.witheredStateName })
	end
	if 0 < item.growthDuration then
		table.insert(growthRows, { "Growth Duration (seasonal)", tostring(item.growthDuration) .. " periods" })
	end
	table.insert(growthRows, { "Resets Spray on Growth", item.resetsSpray })
	table.insert(growthRows, { "Requires Lime for Growth", item.growthRequiresLime })
	table.insert(html, DocumentationHTMLUtil.createCard("Growth", DocumentationHTMLUtil.createDataTable(growthRows)))
	if next(item.plantingPeriods) ~= nil or next(item.harvestPeriods) ~= nil then
		local seasonalRows = {}
		if next(item.plantingPeriods) ~= nil then
			table.insert(seasonalRows, { "Planting", item.plantingPeriods })
		end
		if next(item.harvestPeriods) ~= nil then
			table.insert(seasonalRows, { "Harvest", item.harvestPeriods })
		end
		table.insert(html, DocumentationHTMLUtil.createCard("Seasonal Windows", DocumentationHTMLUtil.createSeasonBoolTable(seasonalRows)))
	end
	local fieldWorkRows = { { "Benefits from Plowing", item.lowSoilDensityRequired }, { "Increases Soil Density (plowing recommended after harvest)", item.increasesSoilDensity }, { "Requires Cultivation after Harvest", item.requiresPreparation } }
	if item.requiresPreparation then
		local prepStateName = item.growthStateNames[item.preparedGrowthState] or tostring(item.preparedGrowthState)
		table.insert(fieldWorkRows, { "Prepared State", prepStateName })
	end
	table.insert(fieldWorkRows, { "Leaves Stubble (mulchable)", item.hasMulching })
	if item.hasMulching then
		table.insert(fieldWorkRows, { "Mulched State", item.mulchedStateName })
	end
	table.insert(html, DocumentationHTMLUtil.createCard("Field Work", DocumentationHTMLUtil.createDataTable(fieldWorkRows)))
	table.insert(html, DocumentationHTMLUtil.createCard("Yield & Seeding", DocumentationHTMLUtil.createDataTable({ { "Yield per Hectare (full)", DocumentationHTMLUtil.formatNumber(item.yieldPerHa, "l") }, { "Liters per m\194\178", DocumentationHTMLUtil.formatNumber(item.literPerSqm, "l", 4) }, { "Seed Usage per Hectare", DocumentationHTMLUtil.formatNumber(item.seedsPerHa, "l") }, { "Plant Spacing", DocumentationHTMLUtil.formatNumber(item.plantSpacing * 100, "cm", 1) }, { "Cut Height", DocumentationHTMLUtil.formatNumber(item.cutHeight, "m", 2) }, { "Bee Yield Bonus", DocumentationHTMLUtil.formatNumber(item.beeYieldBonusPercentage, "%") }, { "Needs Rolling", item.needsRolling }, { "Plants Weed on Seeding", item.plantsWeed } })))
	table.insert(html, DocumentationHTMLUtil.createCard("Soil", DocumentationHTMLUtil.createDataTable({ { "Consumes Lime", item.consumesLime }, { "Start Spray Level", tostring(item.startSprayLevel or 0) } })))
	if item.windrowFillTypeName ~= nil then
		local windrowRows = { { "Windrow Fill Type", item.windrowFillTypeName } }
		if item.windrowCutFillTypeName ~= nil then
			table.insert(windrowRows, { "Windrow Cut Fill Type", item.windrowCutFillTypeName })
		end
		table.insert(html, DocumentationHTMLUtil.createCard("Windrow", DocumentationHTMLUtil.createDataTable(windrowRows)))
	end
	local economyContent = DocumentationHTMLUtil.createDataTable({ { "Base Price per Liter", DocumentationHTMLUtil.formatNumber(item.pricePerLiter, "$", 3) }, { "Base Price per 1000L", DocumentationHTMLUtil.formatNumber(item.pricePerLiter * 1000, "$") }, { "Sell Price / 1000L (Easy)", DocumentationHTMLUtil.formatNumber(item.sellPriceEasy, "$") }, { "Sell Price / 1000L (Medium)", DocumentationHTMLUtil.formatNumber(item.sellPriceMedium, "$") }, { "Sell Price / 1000L (Hard)", DocumentationHTMLUtil.formatNumber(item.sellPriceHard, "$") } })
	if item.economyFactors ~= nil and next(item.economyFactors) ~= nil then
		economyContent = economyContent .. '<h4 style="margin: 16px 0 8px 0; font-size: 14px; color: #555;">Seasonal Price Factors</h4>'
		economyContent = economyContent .. DocumentationHTMLUtil.createSeasonTable(item.economyFactors, item.pricePerLiter * 1000)
	end
	table.insert(html, DocumentationHTMLUtil.createCard("Economy", economyContent))
	if 0 < item.numGrowthStates then
		table.insert(html, DocumentationHTMLUtil.createCard("Weeding", self:createWeederHoeTable(item)))
	end
	if item.xmlFilename ~= "" then
		table.insert(html, DocumentationHTMLUtil.createCard("Source", DocumentationHTMLUtil.createDataTable({ { "Config File", item.xmlFilename } })))
	end
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. filename, table.concat(html, "\n"))
end
function FruitTypeDocGenerator:createWeederHoeTable(item)
	local html = {}
	table.insert(html, '<table class="season-table">')
	table.insert(html, "<thead><tr><th></th>")
	for i = 1, item.numGrowthStates do
		local stateName = item.growthStateNames[i] or tostring(i)
		table.insert(html, string.format('<th title="State %d">%s</th>', i, DocumentationHTMLUtil.escapeHTML(stateName)))
	end
	table.insert(html, "</tr></thead>")
	table.insert(html, '<tr><td style="font-weight:600; text-align:left;">Weeder</td>')
	for i = 1, item.numGrowthStates do
		local state = item.weederHoeStates[i]
		if state ~= nil then
			if state.weeder then
				table.insert(html, '<td class="factor-high">W</td>')
			else
				table.insert(html, '<td class="factor-neutral">\226\128\148</td>')
			end
		end
	end
	table.insert(html, "</tr>")
	table.insert(html, '<tr><td style="font-weight:600; text-align:left;">Hoe</td>')
	for i = 1, item.numGrowthStates do
		local state = item.weederHoeStates[i]
		if state ~= nil then
			if state.hoe then
				table.insert(html, '<td class="factor-high">H</td>')
			else
				table.insert(html, '<td class="factor-neutral">\226\128\148</td>')
			end
		end
	end
	table.insert(html, "</tr>")
	table.insert(html, "</table>")
	return table.concat(html, "\n")
end
function FruitTypeDocGenerator:generateOverviewPage(dir, sourceLabel, items)
	local qualifiedName = DocumentationGenerator.getOverviewQualifiedName("Fruit Types", sourceLabel)
	local breadcrumbs = { { text = "Documentation", url = "../overview.html" }, { text = qualifiedName } }
	local html = {}
	table.insert(html, DocumentationHTMLUtil.getHTMLHeader(qualifiedName, breadcrumbs, "../style.css"))
	table.insert(html, string.format('<h2 style="margin-bottom: 16px;">%s (%d)</h2>', DocumentationHTMLUtil.escapeHTML(qualifiedName), #items))
	table.insert(html, '<div class="card"><div class="card-body">')
	table.insert(html, '<table class="doc-table">')
	table.insert(html, "<thead><tr>")
	table.insert(html, '<th data-sort="string">Name<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Yield/ha<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Seeds/ha<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Stages<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Spacing<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Easy<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Medium<span class="sort-arrow"></span></th>')
	table.insert(html, '<th data-sort="number">Hard<span class="sort-arrow"></span></th>')
	table.insert(html, "</tr></thead>")
	table.insert(html, "<tbody>")
	for _, item in ipairs(items) do
		local link = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
		local spacingCm = item.plantSpacing * 100
		table.insert(html, "<tr>")
		table.insert(html, string.format('<td><a href="%s">%s</a></td>', link, DocumentationHTMLUtil.escapeHTML(item.title)))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.yieldPerHa, DocumentationHTMLUtil.formatNumber(item.yieldPerHa, "l")))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.seedsPerHa, DocumentationHTMLUtil.formatNumber(item.seedsPerHa, "l")))
		table.insert(html, string.format('<td data-value="%d">%d</td>', item.numGrowthStates, item.numGrowthStates))
		table.insert(html, string.format('<td data-value="%.1f">%s</td>', spacingCm, DocumentationHTMLUtil.formatNumber(spacingCm, "cm", 1)))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.sellPriceEasy, DocumentationHTMLUtil.formatNumber(item.sellPriceEasy, "$")))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.sellPriceMedium, DocumentationHTMLUtil.formatNumber(item.sellPriceMedium, "$")))
		table.insert(html, string.format('<td data-value="%d">%s</td>', item.sellPriceHard, DocumentationHTMLUtil.formatNumber(item.sellPriceHard, "$")))
		table.insert(html, "</tr>")
	end
	table.insert(html, "</tbody></table>")
	table.insert(html, "</div></div>")
	table.insert(html, self:createWeederHoeOverviewTable())
	table.insert(html, DocumentationHTMLUtil.getSortScript())
	table.insert(html, DocumentationHTMLUtil.getHTMLFooter())
	DocumentationHTMLUtil.writeFile(dir .. DocumentationHTMLUtil.getOverviewFilename(sourceLabel), table.concat(html, "\n"))
end
function FruitTypeDocGenerator:appendToolStateRow(html, item, maxStates, nameColStyle, label, marker, stateKey)
	local subRowStyle = nameColStyle .. " padding-left:20px; color:#666;"
	table.insert(html, string.format('<tr><td style="%s">%s</td>', subRowStyle, label))
	for i = 1, maxStates do
		if item.numGrowthStates < i then
			table.insert(html, '<td style="background-color:#f0f0f0;"></td>')
		else
			local state = item.weederHoeStates[i]
			local stateName = item.growthStateNames[i] or tostring(i)
			local escapedName = DocumentationHTMLUtil.escapeHTML(stateName)
			local isActive = false
			if state ~= nil then
				isActive = state[stateKey]
			end
			if isActive then
				table.insert(html, string.format('<td class="factor-high" title="%s">%s</td>', escapedName, marker))
			else
				table.insert(html, string.format('<td class="factor-neutral" title="%s">\226\128\148</td>', escapedName))
			end
		end
	end
	table.insert(html, "</tr>")
end
function FruitTypeDocGenerator:createWeederHoeOverviewTable()
	local maxStates = 0
	for _, item in ipairs(self.items) do
		if maxStates < item.numGrowthStates then
			maxStates = item.numGrowthStates
		end
	end
	if maxStates == 0 then
		return ""
	else
		local nameColStyle = "background-color:#f0f5ef; border-right:2px solid #4a7c3f; text-align:left;"
		local html = {}
		table.insert(html, '<h2 style="margin: 24px 0 16px 0;">Weeder / Hoe Overview</h2>')
		table.insert(html, '<div class="card"><div class="card-body" style="overflow-x: auto;">')
		table.insert(html, '<table class="season-table" style="min-width: 100%;">')
		table.insert(html, string.format('<thead><tr><th style="%s">Fruit Type</th>', "background-color:#f0f5ef; border-right:2px solid #4a7c3f; text-align:left;"))
		for i = 1, maxStates do
			table.insert(html, string.format("<th>%d</th>", i))
		end
		table.insert(html, "</tr></thead>")
		table.insert(html, "<tbody>")
		for _, item in ipairs(self.items) do
			local link = DocumentationHTMLUtil.sanitizeFilename(item.name) .. ".html"
			table.insert(html, string.format('<tr style="border-top: 2px solid #ccc;"><td colspan="%d" style="background-color:#e8e8e8; font-weight:600; text-align:left; padding-top:10px;"><a href="%s" style="color:#4a7c3f; text-decoration:none;">%s</a></td></tr>', maxStates + 1, link, DocumentationHTMLUtil.escapeHTML(item.title)))
			self:appendToolStateRow(html, item, maxStates, "background-color:#f0f5ef; border-right:2px solid #4a7c3f; text-align:left;", "Weeder", "W", "weeder")
			self:appendToolStateRow(html, item, maxStates, "background-color:#f0f5ef; border-right:2px solid #4a7c3f; text-align:left;", "Hoe", "H", "hoe")
		end
		table.insert(html, "</tbody></table>")
		table.insert(html, "</div></div>")
		return table.concat(html, "\n")
	end
end
