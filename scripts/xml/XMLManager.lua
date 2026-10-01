XMLManager = {}
XMLManager.EXPORT_DIRECTORY_XSD = "shared/xml/schema/"
XMLManager.EXPORT_DIRECTORY_HTML = "shared/xml/documentation/"
local XMLManager_mt = Class(XMLManager)
function XMLManager.new(customMt)
	local self = setmetatable({}, customMt or XMLManager_mt)
	self.schemas = {}
	self.files = {}
	self.earlyCreateSchemaFunctions = {}
	self.earlyInitSchemaFunctions = {}
	self.createSchemaFunctions = {}
	self.initSchemaFunctions = {}
	return self
end
function XMLManager:unloadMapData()
	self.schemas = {}
end
function XMLManager:addSchema(schema)
	table.insert(self.schemas, schema)
end
function XMLManager:addFile(file)
	self.files[file.handle] = file
end
function XMLManager:removeFile(file)
	self.files[file.handle] = nil
end
function XMLManager:getFileByHandle(handle)
	return self.files[handle]
end
function XMLManager:addEarlyCreateSchemaFunction(func)
	table.insert(self.earlyCreateSchemaFunctions, func)
end
function XMLManager:addCreateSchemaFunction(func)
	table.insert(self.createSchemaFunctions, func)
end
function XMLManager:earlyCreateSchemas()
	for _, func in ipairs(self.earlyCreateSchemaFunctions) do
		func()
	end
end
function XMLManager:createSchemas()
	for _, func in ipairs(self.createSchemaFunctions) do
		func()
	end
end
function XMLManager:addEarlyInitSchemaFunction(func)
	table.insert(self.earlyInitSchemaFunctions, func)
end
function XMLManager:addInitSchemaFunction(func)
	table.insert(self.initSchemaFunctions, func)
end
function XMLManager:earlyInitSchemas()
	for _, func in ipairs(self.earlyInitSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function()
			func()
		end)
	end
end
function XMLManager:initSchemas()
	for _, func in ipairs(self.initSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function()
			func()
		end)
	end
end
local schemaRequiredModNames = { ["pdlc_macDonPack"] = true, ["pdlc_nexatPack"] = true, ["pdlc_plainsAndPrairiesPack"] = true, ["pdlc_daimlerTruckPack"] = true, ["pdlc_highlandsFishingPack"] = true, ["pdlc_vredoPack"] = true, ["pdlc_skyAgriculturePack"] = true, ["FS25_precisionFarming"] = true }
function XMLManager.consoleCommandGenerateSchemas(_, deleteExisting)
	if g_xmlManager == nil then
		return
	end
	if not StartParams.getIsSet("scriptDebug") then
		printError("Error: schema export is only available if the game was launched with '-scriptDebug'")
		return
	end
	if getLanguage() ~= 0 then
		printError("Error: schema export should only be done with the game in english language setting")
		return
	end
	local missingMods = false
	for modName, _ in pairs(g_modIsLoaded) do
		if schemaRequiredModNames[modName] == true or string.contains(modName, "testMap") then
			continue
		end
		missingMods = true
	end
	for modName, _ in pairs(schemaRequiredModNames) do
		if g_modIsLoaded[modName] == true then
			continue
		end
		missingMods = true
	end
	if missingMods then
		Logging.error("XML schema export could not be executed. Mods do not match requirements:")
		for modName, _ in pairs(g_modIsLoaded) do
			if schemaRequiredModNames[modName] == true or string.contains(modName, "testMap") then
				print(" - " .. modName .. " (ok)")
			else
				printError(" - " .. modName .. " (not allowed)")
			end
		end
		for modName, _ in pairs(schemaRequiredModNames) do
			if g_modIsLoaded[modName] == true then
				continue
			end
			printError(" - " .. modName .. " (missing)")
		end
	else
		if Utils.stringToBoolean(deleteExisting) then
			print("deleting existing xsd and html files")
			local deleteFilesInDir = function(dir)
				local ignore = { ["testing"] = true, ["i3d-1.6"] = true }
				local gamePath = getAppBasePath()
				for _, file in Files.new(dir).files, nil, nil do
					if file.isDirectory then
						continue
					end
					local basename = Utils.getFilenameInfo(file.filename)
					if ignore[basename] then
						continue
					end
					deleteFile(gamePath .. file.path)
				end
			end
			deleteFilesInDir(XMLManager.EXPORT_DIRECTORY_XSD)
			deleteFilesInDir(XMLManager.EXPORT_DIRECTORY_HTML)
		end
		local schemasSorted = {}
		for _, schema in ipairs(g_xmlManager.schemas) do
			schema:generateSchema()
			schema:generateHTML()
			table.insert(schemasSorted, schema)
		end
		table.sort(schemasSorted, function(a, b)
			return a.name < b.name
		end)
		local htmlPath = XMLManager.EXPORT_DIRECTORY_HTML .. "overview.html"
		local file = io.open(htmlPath, "w")
		file:write("<!DOCTYPE html>\n")
		file:write("<html>\n")
		file:write("  <head>\n")
		file:write("    <title>XML Documentation (v" .. g_gameVersionDisplay .. ")</title>\n")
		file:write("  </head>\n")
		file:write("  <style>\n")
		file:write("    li {\n")
		file:write("      margin: 5px;\n")
		file:write("    }\n")
		file:write("    a {\n")
		file:write("      text-decoration:none;\n")
		file:write("      font-size: 15pt;\n")
		file:write("      color: #000000;\n")
		file:write("    }\n")
		file:write("  </style>\n")
		file:write("<body>\n")
		file:write("  <h1>Schema Overview</h1>\n")
		file:write("  <ul>\n")
		for _, schema in ipairs(schemasSorted) do
			file:write('   <li><a href="' .. schema.name .. '.html">' .. schema.name .. "</a></li>\n")
		end
		file:write("  </ul>\n")
		file:write("</body>\n")
		file:write("</html>\n")
		file:close()
	end
end
addConsoleCommand("gsXMLGenerateSchemas", "Generates xml schemas", "XMLManager.consoleCommandGenerateSchemas", nil, "[deleteExisting=false]")
g_xmlManager = XMLManager.new()
