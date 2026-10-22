DocumentationHTMLUtil = {}
DocumentationHTMLUtil.SEASON_PERIOD_NAMES = { "Early Spring", "Mid Spring", "Late Spring", "Early Summer", "Mid Summer", "Late Summer", "Early Autumn", "Mid Autumn", "Late Autumn", "Early Winter", "Mid Winter", "Late Winter" }
function DocumentationHTMLUtil.getCSS()
	return '*, *::before, *::after {\n    box-sizing: border-box;\n}\n\nbody {\n    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;\n    margin: 0;\n    padding: 0;\n    background-color: #f5f5f5;\n    color: #333;\n    line-height: 1.6;\n}\n\n.top-bar {\n    background-color: #2c3e2d;\n    color: #fff;\n    padding: 12px 24px;\n    display: flex;\n    align-items: center;\n    gap: 16px;\n}\n\n.top-bar h1 {\n    margin: 0;\n    font-size: 18px;\n    font-weight: 600;\n}\n\n.top-bar .version {\n    font-size: 13px;\n    opacity: 0.7;\n}\n\n.breadcrumbs {\n    background-color: #fff;\n    border-bottom: 1px solid #e0e0e0;\n    padding: 10px 24px;\n    font-size: 13px;\n    color: #666;\n}\n\n.breadcrumbs a {\n    color: #4a7c3f;\n    text-decoration: none;\n}\n\n.breadcrumbs a:hover {\n    text-decoration: underline;\n}\n\n.breadcrumbs .separator {\n    margin: 0 6px;\n    color: #999;\n}\n\nmain {\n    max-width: 1800px;\n    margin: 24px auto;\n    padding: 0 24px;\n}\n\n.card {\n    background: #fff;\n    border-radius: 8px;\n    box-shadow: 0 1px 3px rgba(0,0,0,0.1);\n    margin-bottom: 20px;\n    overflow: hidden;\n}\n\n.card-header {\n    background-color: #4a7c3f;\n    color: #fff;\n    padding: 12px 20px;\n    font-size: 15px;\n    font-weight: 600;\n}\n\n.card-body {\n    padding: 16px 20px;\n}\n\n.doc-table {\n    width: 100%;\n    border-collapse: collapse;\n    font-size: 14px;\n}\n\n.doc-table th {\n    text-align: left;\n    padding: 10px 12px;\n    background-color: #f8f9fa;\n    border-bottom: 2px solid #e0e0e0;\n    font-weight: 600;\n    color: #555;\n    cursor: pointer;\n    user-select: none;\n    white-space: nowrap;\n}\n\n.doc-table th:hover {\n    background-color: #e8ece8;\n}\n\n.doc-table th .sort-arrow {\n    margin-left: 4px;\n    opacity: 0.4;\n    font-size: 11px;\n}\n\n.doc-table th.sorted-asc .sort-arrow::after {\n    content: " \226\150\178";\n    opacity: 1;\n}\n\n.doc-table th.sorted-desc .sort-arrow::after {\n    content: " \226\150\188";\n    opacity: 1;\n}\n\n.doc-table td {\n    padding: 8px 12px;\n    border-bottom: 1px solid #f0f0f0;\n}\n\n.doc-table tbody tr:hover {\n    background-color: #f8faf8;\n}\n\n.doc-table a {\n    color: #4a7c3f;\n    text-decoration: none;\n    font-weight: 500;\n}\n\n.doc-table a:hover {\n    text-decoration: underline;\n}\n\n.data-table {\n    width: 100%;\n    border-collapse: collapse;\n    font-size: 14px;\n}\n\n.data-table td {\n    padding: 8px 0;\n    border-bottom: 1px solid #f0f0f0;\n}\n\n.data-table td:first-child {\n    font-weight: 500;\n    color: #555;\n    width: 220px;\n}\n\n.data-table td:last-child {\n    color: #333;\n}\n\n.data-table a {\n    color: #4a7c3f;\n    text-decoration: none;\n    font-weight: 500;\n}\n\n.data-table a:hover {\n    text-decoration: underline;\n}\n\n.badge {\n    display: inline-block;\n    padding: 2px 8px;\n    border-radius: 4px;\n    font-size: 12px;\n    font-weight: 600;\n}\n\n.badge-yes {\n    background-color: #d4edda;\n    color: #155724;\n}\n\n.badge-no {\n    background-color: #f8d7da;\n    color: #721c24;\n}\n\n.section-grid {\n    display: grid;\n    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));\n    gap: 20px;\n    margin-bottom: 24px;\n}\n\n.section-card {\n    background: #fff;\n    border-radius: 8px;\n    box-shadow: 0 1px 3px rgba(0,0,0,0.1);\n    padding: 24px;\n    text-align: center;\n    transition: box-shadow 0.2s;\n}\n\n.section-card:hover {\n    box-shadow: 0 4px 12px rgba(0,0,0,0.15);\n}\n\n.section-card h2 {\n    margin: 0 0 8px 0;\n    font-size: 20px;\n    color: #2c3e2d;\n}\n\n.section-card .count {\n    font-size: 36px;\n    font-weight: 700;\n    color: #4a7c3f;\n    margin: 8px 0;\n}\n\n.section-card .desc {\n    color: #666;\n    font-size: 14px;\n    margin-bottom: 16px;\n}\n\n.section-card a {\n    display: inline-block;\n    padding: 8px 20px;\n    background-color: #4a7c3f;\n    color: #fff;\n    text-decoration: none;\n    border-radius: 6px;\n    font-size: 14px;\n    font-weight: 500;\n}\n\n.section-card a:hover {\n    background-color: #3d6935;\n}\n\n.footer {\n    text-align: center;\n    padding: 24px;\n    color: #999;\n    font-size: 12px;\n}\n\n.season-table {\n    width: 100%;\n    border-collapse: collapse;\n    font-size: 13px;\n    text-align: center;\n}\n\n.season-table th, .season-table td {\n    padding: 6px 8px;\n    border: 1px solid #e0e0e0;\n}\n\n.season-table th {\n    background-color: #f8f9fa;\n    font-weight: 600;\n    color: #555;\n}\n\n.season-table td.factor-high {\n    background-color: #d4edda;\n    color: #155724;\n}\n\n.season-table td.factor-low {\n    background-color: #f8d7da;\n    color: #721c24;\n}\n\n.season-table td.factor-neutral {\n    background-color: #fff;\n}\n'
end
function DocumentationHTMLUtil.writeSharedCSS(baseDir)
	local path = baseDir .. "style.css"
	local file = io.open(path, "w")
	if file == nil then
		Logging.error("DocumentationHTMLUtil: Failed to write CSS file '%s'", path)
	else
		file:write(DocumentationHTMLUtil.getCSS())
		file:close()
	end
end
function DocumentationHTMLUtil.getSortScript()
	return "<script>\ndocument.querySelectorAll('.doc-table th[data-sort]').forEach(function(th) {\n    th.addEventListener('click', function() {\n        var table = th.closest('table');\n        var tbody = table.querySelector('tbody');\n        var rows = Array.from(tbody.querySelectorAll('tr'));\n        var colIndex = Array.from(th.parentNode.children).indexOf(th);\n        var sortType = th.getAttribute('data-sort');\n        var isAsc = th.classList.contains('sorted-asc');\n\n        table.querySelectorAll('th').forEach(function(h) {\n            h.classList.remove('sorted-asc', 'sorted-desc');\n        });\n        th.classList.add(isAsc ? 'sorted-desc' : 'sorted-asc');\n\n        rows.sort(function(a, b) {\n            var aVal = a.children[colIndex].getAttribute('data-value') || a.children[colIndex].textContent.trim();\n            var bVal = b.children[colIndex].getAttribute('data-value') || b.children[colIndex].textContent.trim();\n            if (sortType === 'number') {\n                aVal = parseFloat(aVal) || 0;\n                bVal = parseFloat(bVal) || 0;\n                return isAsc ? bVal - aVal : aVal - bVal;\n            }\n            return isAsc ? bVal.localeCompare(aVal) : aVal.localeCompare(bVal);\n        });\n\n        rows.forEach(function(row) { tbody.appendChild(row); });\n    });\n});\n</script>\n"
end
function DocumentationHTMLUtil.getHTMLHeader(title, breadcrumbs, cssRelPath)
	local html = {}
	table.insert(html, "<!DOCTYPE html>")
	table.insert(html, '<html lang="en">')
	table.insert(html, "<head>")
	table.insert(html, '  <meta charset="UTF-8">')
	table.insert(html, '  <meta name="viewport" content="width=device-width, initial-scale=1.0">')
	local gameTitle = DocumentationHTMLUtil.escapeHTML(g_gameTitle or "")
	table.insert(html, string.format("  <title>%s \226\128\148 %s Documentation</title>", DocumentationHTMLUtil.escapeHTML(title), gameTitle))
	table.insert(html, string.format('  <link rel="stylesheet" href="%s">', cssRelPath))
	table.insert(html, "</head>")
	table.insert(html, "<body>")
	table.insert(html, '<div class="top-bar">')
	table.insert(html, string.format("  <h1>%s \226\128\148 Documentation</h1>", gameTitle))
	table.insert(html, string.format('  <span class="version">v%s</span>', g_gameVersionDisplay or ""))
	table.insert(html, "</div>")
	if breadcrumbs ~= nil and 0 < #breadcrumbs then
		table.insert(html, '<div class="breadcrumbs">')
		for i, crumb in ipairs(breadcrumbs) do
			if 1 < i then
				table.insert(html, '<span class="separator">\226\128\186</span>')
			end
			if crumb.url ~= nil then
				table.insert(html, string.format('<a href="%s">%s</a>', crumb.url, DocumentationHTMLUtil.escapeHTML(crumb.text)))
			else
				table.insert(html, DocumentationHTMLUtil.escapeHTML(crumb.text))
			end
		end
		table.insert(html, "</div>")
	end
	table.insert(html, "<main>")
	return table.concat(html, "\n")
end
function DocumentationHTMLUtil.getHTMLFooter()
	local html = {}
	table.insert(html, "</main>")
	table.insert(html, '<div class="footer">')
	table.insert(html, string.format("  Generated for %s v%s \226\128\148 %s", DocumentationHTMLUtil.escapeHTML(g_gameTitle or ""), g_gameVersionDisplay or "", getDate("%Y-%m-%d %H:%M")))
	table.insert(html, "</div>")
	table.insert(html, "</body>")
	table.insert(html, "</html>")
	return table.concat(html, "\n")
end
function DocumentationHTMLUtil.createCard(title, contentHTML)
	local html = {}
	table.insert(html, '<div class="card">')
	table.insert(html, string.format('  <div class="card-header">%s</div>', DocumentationHTMLUtil.escapeHTML(title)))
	table.insert(html, '  <div class="card-body">')
	table.insert(html, contentHTML)
	table.insert(html, "  </div>")
	table.insert(html, "</div>")
	return table.concat(html, "\n")
end
function DocumentationHTMLUtil.createDataTable(rows)
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
			value = DocumentationHTMLUtil.escapeHTML(tostring(value))
		end
		table.insert(html, string.format("  <tr><td>%s</td><td>%s</td></tr>", DocumentationHTMLUtil.escapeHTML(label), value))
	end
	table.insert(html, "</table>")
	return table.concat(html, "\n")
end
function DocumentationHTMLUtil.createSeasonTable(factors, basePrice)
	local html = {}
	table.insert(html, '<table class="season-table">')
	table.insert(html, "<thead><tr><th></th>")
	for _, name in ipairs(DocumentationHTMLUtil.SEASON_PERIOD_NAMES) do
		table.insert(html, string.format("<th>%s</th>", name))
	end
	table.insert(html, "</tr></thead>")
	table.insert(html, '<tr><td style="font-weight:600; text-align:left;">Factor</td>')
	for period = 1, 12 do
		local factor = factors[period] or 1
		local cssClass = "factor-neutral"
		if 1.05 < factor then
			cssClass = "factor-high"
		elseif factor < 0.95 then
			cssClass = "factor-low"
		end
		table.insert(html, string.format('<td class="%s">%.2f</td>', cssClass, factor))
	end
	table.insert(html, "</tr>")
	if basePrice ~= nil and 0 < basePrice then
		table.insert(html, '<tr><td style="font-weight:600; text-align:left;">$/1000L</td>')
		for period = 1, 12 do
			local factor = factors[period] or 1
			local price = basePrice * factor
			local cssClass = "factor-neutral"
			if 1.05 < factor then
				cssClass = "factor-high"
			elseif factor < 0.95 then
				cssClass = "factor-low"
			end
			table.insert(html, string.format('<td class="%s">$%d</td>', cssClass, MathUtil.round(price)))
		end
		table.insert(html, "</tr>")
	end
	table.insert(html, "</table>")
	return table.concat(html, "\n")
end
function DocumentationHTMLUtil.stripBasePath(path)
	if path == nil or path == "" then
		return ""
	end
	local normalizedPath = string.gsub(path, "\\", "/")
	local basePath = getAppBasePath()
	if basePath ~= nil and basePath ~= "" then
		local normalizedBase = string.gsub(basePath, "\\", "/")
		if string.sub(normalizedPath, 1, string.len(normalizedBase)) == normalizedBase then
			return "$" .. string.sub(normalizedPath, string.len(normalizedBase) + 1)
		end
	end
	if g_modsDirectory ~= nil and g_modsDirectory ~= "" then
		local normalizedModsDir = string.gsub(g_modsDirectory, "\\", "/")
		if string.sub(normalizedPath, 1, string.len(normalizedModsDir)) == normalizedModsDir then
			return "$modDir$/" .. string.sub(normalizedPath, string.len(normalizedModsDir) + 1)
		end
	end
	if g_dlcsDirectories ~= nil then
		for _, dlcDir in ipairs(g_dlcsDirectories) do
			local dlcPath = string.gsub(dlcDir.path, "\\", "/")
			if string.sub(normalizedPath, 1, string.len(dlcPath)) == dlcPath then
				return "$pdlcDir$/" .. string.sub(normalizedPath, string.len(dlcPath) + 1)
			end
		end
	end
	return path
end
function DocumentationHTMLUtil.createSeasonBoolTable(rows)
	local html = {}
	table.insert(html, '<table class="season-table">')
	table.insert(html, "<thead><tr><th></th>")
	for _, name in ipairs(DocumentationHTMLUtil.SEASON_PERIOD_NAMES) do
		table.insert(html, string.format("<th>%s</th>", name))
	end
	table.insert(html, "</tr></thead>")
	for _, row in ipairs(rows) do
		local label = row[1]
		local values = row[2]
		table.insert(html, string.format('<tr><td style="font-weight:600; text-align:left;">%s</td>', DocumentationHTMLUtil.escapeHTML(label)))
		for period = 1, 12 do
			if values[period] then
				table.insert(html, '<td class="factor-high">\226\156\147</td>')
			else
				table.insert(html, '<td class="factor-neutral">\226\128\148</td>')
			end
		end
		table.insert(html, "</tr>")
	end
	table.insert(html, "</table>")
	return table.concat(html, "\n")
end
function DocumentationHTMLUtil.sanitizeFilename(name)
	if name == nil then
		return "unknown"
	else
		local sanitized = utf8ToLower(name)
		sanitized = string.gsub(sanitized, "[^%w%-_]", "_")
		return sanitized
	end
end
function DocumentationHTMLUtil.formatNumber(value, unit, decimals)
	if value == nil or value == 0 then
		return "\226\128\148"
	end
	decimals = decimals or 2
	local formatted = string.format("%." .. decimals .. "f", value)
	if unit ~= nil then
		return formatted .. " " .. unit
	else
		return formatted
	end
end
DocumentationHTMLUtil.BASEGAME_GROUP_LABEL = "Basegame"
function DocumentationHTMLUtil.getOverviewFilename(sourceLabel)
	if sourceLabel == nil or sourceLabel == "" or sourceLabel == DocumentationHTMLUtil.BASEGAME_GROUP_LABEL then
		return "overview.html"
	end
	return "overview_" .. DocumentationHTMLUtil.sanitizeFilename(sourceLabel) .. ".html"
end
function DocumentationHTMLUtil.escapeHTML(str)
	if str == nil then
		return ""
	else
		str = tostring(str)
		str = string.gsub(str, "&", "&amp;")
		str = string.gsub(str, "<", "&lt;")
		str = string.gsub(str, ">", "&gt;")
		str = string.gsub(str, '"', "&quot;")
		str = string.gsub(str, "'", "&#39;")
		return str
	end
end
function DocumentationHTMLUtil.normalizePath(path)
	if path == nil or path == "" then
		return path
	end
	local normalized = string.gsub(path, "\\", "/")
	local isAbsolute = string.sub(normalized, 1, 1) == "/"
	local parts = {}
	for segment in string.gmatch(normalized, "[^/]+") do
		if segment == ".." and 0 < #parts then
			if parts[#parts] ~= ".." then
				local last = parts[#parts]
				if not string.match(last, "^%a:$") then
					table.remove(parts)
				else
					table.insert(parts, segment)
				end
			else
				if segment == "." then
					continue
				end
				table.insert(parts, segment)
			end
		end
	end
	local result = table.concat(parts, "/")
	if isAbsolute then
		result = "/" .. result
	end
	return result
end
local isAbsolutePath = function(path)
	if path == nil or path == "" then
		return false
	end
	if string.sub(path, 1, 1) == "/" or string.sub(path, 1, 1) == "\\" then
		return true
	end
	return string.match(path, "^%a:[/\\]") ~= nil
end
DocumentationHTMLUtil.PDLC_PATH_PREFIX = "$pdlcDir$/"
function DocumentationHTMLUtil.toNetworkPath(path)
	if path == nil or path == "" then
		return nil
	end
	if g_dlcsDirectories == nil then
		return nil
	else
		local normalizedPath = string.gsub(path, "\\", "/")
		for _, dlcDir in ipairs(g_dlcsDirectories) do
			local dlcPath = string.gsub(dlcDir.path, "\\", "/")
			if string.sub(normalizedPath, 1, string.len(dlcPath)) == dlcPath then
				return DocumentationHTMLUtil.PDLC_PATH_PREFIX .. string.sub(normalizedPath, string.len(dlcPath) + 1)
			end
		end
		return nil
	end
end
function DocumentationHTMLUtil.resolvePdlcPath(path)
	if path == nil or path == "" then
		return nil
	end
	local prefix = DocumentationHTMLUtil.PDLC_PATH_PREFIX
	if string.sub(path, 1, string.len(prefix)) ~= prefix then
		return nil
	end
	local remainder = string.sub(path, string.len(prefix) + 1)
	local dlcName, rest = string.match(remainder, "^([^/]+)/(.*)$")
	if dlcName == nil then
		return nil
	else
		local dlcRoot = DocumentationHTMLUtil.normalizePath(getAppBasePath() .. "../dlc/")
		return dlcRoot .. "/" .. dlcName .. "/bin/" .. rest
	end
end
local toAbsolutePath = function(path)
	if path == nil or path == "" then
		return path
	end
	local _v23 = path
	local pdlcResolved = DocumentationHTMLUtil.resolvePdlcPath(_v23)
	if pdlcResolved ~= nil then
		return pdlcResolved
	else
		if string.sub(path, 1, 1) == "/" or string.sub(path, 1, 1) == "\\" then
			if _v23 then
				return path
			else
				return getAppBasePath() .. path
			end
		end
	end
end
local splitPath = function(path)
	local normalized = DocumentationHTMLUtil.normalizePath(path)
	local root = ""
	local drive = string.match(normalized, "^(%a:)/")
	if drive ~= nil then
		root = drive .. "/"
		normalized = string.sub(normalized, #drive + 2)
	elseif string.sub(normalized, 1, 1) == "/" then
		root = "/"
		normalized = string.sub(normalized, 2)
	end
	local segments = {}
	for segment in string.gmatch(normalized, "[^/]+") do
		table.insert(segments, segment)
	end
	return root, segments
end
function DocumentationHTMLUtil.getRelativePath(fromDir, targetPath)
	if fromDir == nil or fromDir == "" or targetPath == nil or targetPath == "" then
		return ""
	end
	local path = fromDir
	if path == nil or path == "" then
		fromDir = path
	else
		local _v46 = path
		local pdlcResolved = DocumentationHTMLUtil.resolvePdlcPath(_v46)
		if pdlcResolved ~= nil then
			fromDir = pdlcResolved
		else
			if string.sub(path, 1, 1) == "/" or string.sub(path, 1, 1) == "\\" then
				if _v46 then
					fromDir = path
				else
					fromDir = getAppBasePath() .. path
				end
				local path = targetPath
				if path == nil or path == "" then
					targetPath = path
				else
					local _v52 = path
					local pdlcResolved = DocumentationHTMLUtil.resolvePdlcPath(_v52)
					if pdlcResolved ~= nil then
						targetPath = pdlcResolved
					else
						if string.sub(path, 1, 1) == "/" or string.sub(path, 1, 1) == "\\" then
							if _v52 then
								targetPath = path
							else
								targetPath = getAppBasePath() .. path
							end
							local fromRoot, fromSegments = splitPath(fromDir)
							local targetRoot, targetSegments = splitPath(targetPath)
							if string.lower(fromRoot) ~= string.lower(targetRoot) then
								return ""
							else
								local commonLength = 0
								local maxCommon = math.min(#fromSegments, #targetSegments)
								for i = 1, maxCommon do
									if string.lower(fromSegments[i]) == string.lower(targetSegments[i]) then
										commonLength = i
									end
								end
								local parts = {}
								for _ = commonLength + 1, #fromSegments do
									table.insert(parts, "..")
								end
								for i = commonLength + 1, #targetSegments do
									table.insert(parts, targetSegments[i])
								end
								return table.concat(parts, "/")
							end
						end
					end
				end
			end
		end
	end
end
function DocumentationHTMLUtil.getImageRelativeURL(sourcePath, destDir)
	if sourcePath == nil or sourcePath == "" then
		return ""
	end
	local extension = string.match(sourcePath, "%.([%w]+)$")
	if extension == nil then
		return ""
	else
		local lowerExt = string.lower(extension)
		if lowerExt ~= "png" and (lowerExt ~= "jpg" and (lowerExt ~= "jpeg" and lowerExt ~= "svg")) then
			return ""
		end
		return DocumentationHTMLUtil.getRelativePath(destDir, sourcePath)
	end
end
function DocumentationHTMLUtil.writeFile(path, content)
	local file = io.open(path, "w")
	if file == nil then
		Logging.error("DocumentationHTMLUtil: Failed to write file '%s'", path)
	else
		file:write(content)
		file:close()
	end
end
