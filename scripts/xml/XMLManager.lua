-- Local values: XMLManager_mt, schemaRequiredModNames
XMLManager = {}
XMLManager.EXPORT_DIRECTORY_XSD = "shared/xml/schema/"
XMLManager.EXPORT_DIRECTORY_HTML = "shared/xml/documentation/"
local XMLManager_mt = Class(XMLManager)

-- Upvalues: XMLManager_mt
-- Local values: self
function XMLManager.new(customMt)
	-- upvalues: (copy) XMLManager_mt
	local v3_ = customMt or XMLManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_.schemas = {}
	v4_.files = {}
	v4_.earlyCreateSchemaFunctions = {}
	v4_.earlyInitSchemaFunctions = {}
	v4_.createSchemaFunctions = {}
	v4_.initSchemaFunctions = {}
	return v4_
end

function XMLManager:unloadMapData()
	self.schemas = {}
end

function XMLManager:addSchema(schema)
	local v8_ = self.schemas
	table.insert(v8_, schema)
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
	local v17_ = self.earlyCreateSchemaFunctions
	table.insert(v17_, func)
end

function XMLManager:addCreateSchemaFunction(func)
	local v20_ = self.createSchemaFunctions
	table.insert(v20_, func)
end

-- Local values: _, func
function XMLManager:earlyCreateSchemas()
	for _, v22_ in ipairs(self.earlyCreateSchemaFunctions) do
		v22_()
	end
end

-- Local values: _, func
function XMLManager:createSchemas()
	for _, v24_ in ipairs(self.createSchemaFunctions) do
		v24_()
	end
end

function XMLManager:addEarlyInitSchemaFunction(func)
	local v27_ = self.earlyInitSchemaFunctions
	table.insert(v27_, func)
end

function XMLManager:addInitSchemaFunction(func)
	local v30_ = self.initSchemaFunctions
	table.insert(v30_, func)
end

-- Local values: _, func
function XMLManager:earlyInitSchemas()
	for _, v_u_32_ in ipairs(self.earlyInitSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_32_
			v_u_32_()
		end)
	end
end

-- Local values: _, func
function XMLManager:initSchemas()
	for _, v_u_34_ in ipairs(self.initSchemaFunctions) do
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_34_
			v_u_34_()
		end)
	end
end
local v_u_35_ = {
	["pdlc_macDonPack"] = true,
	["pdlc_nexatPack"] = true,
	["pdlc_plainsAndPrairiesPack"] = true,
	["pdlc_daimlerTruckPack"] = true,
	["pdlc_highlandsFishingPack"] = true,
	["pdlc_vredoPack"] = true,
	["pdlc_skyAgriculturePack"] = true,
	["FS25_precisionFarming"] = true
}

-- Upvalues: schemaRequiredModNames
-- Local values: missingMods, modName, _, modName, _, modName, _, modName, _, deleteFilesInDir, schemasSorted, _, schema, htmlPath, file, _, schema
function XMLManager.consoleCommandGenerateSchemas(_, deleteExisting)
	-- upvalues: (copy) v_u_35_
	if g_xmlManager == nil then
		return
	elseif StartParams.getIsSet("scriptDebug") then
		if getLanguage() == 0 then
			local v37_ = false
			for v38_, _ in pairs(g_modIsLoaded) do
				if v_u_35_[v38_] ~= true and not string.contains(v38_, "testMap") then
					v37_ = true
				end
			end
			for v39_, _ in pairs(v_u_35_) do
				if g_modIsLoaded[v39_] ~= true then
					v37_ = true
				end
			end
			if v37_ then
				Logging.error("XML schema export could not be executed. Mods do not match requirements:")
				for v40_, _ in pairs(g_modIsLoaded) do
					if v_u_35_[v40_] == true or string.contains(v40_, "testMap") then
						print(" - " .. v40_ .. " (ok)")
					else
						printError(" - " .. v40_ .. " (not allowed)")
					end
				end
				for v41_, _ in pairs(v_u_35_) do
					if g_modIsLoaded[v41_] ~= true then
						printError(" - " .. v41_ .. " (missing)")
					end
				end
			else
				if Utils.stringToBoolean(deleteExisting) then
					print("deleting existing xsd and html files")
					local function v46_(p42_)
						local v43_ = getAppBasePath()
						local v44_ = {
							["testing"] = true,
							["i3d-1.6"] = true
						}
						for _, v45_ in Files.new(p42_).files do
							if not (v45_.isDirectory or v44_[Utils.getFilenameInfo(v45_.filename)]) then
								deleteFile(v43_ .. v45_.path)
							end
						end
					end
					v46_(XMLManager.EXPORT_DIRECTORY_XSD)
					v46_(XMLManager.EXPORT_DIRECTORY_HTML)
				end
				local v47_ = {}
				for _, v48_ in ipairs(g_xmlManager.schemas) do
					v48_:generateSchema()
					v48_:generateHTML()
					table.insert(v47_, v48_)
				end
				table.sort(v47_, function(p49_, p50_)
					return p49_.name < p50_.name
				end)
				local v51_ = XMLManager.EXPORT_DIRECTORY_HTML .. "overview.html"
				local v52_ = io.open(v51_, "w")
				v52_:write("<!DOCTYPE html>\n")
				v52_:write("<html>\n")
				v52_:write("  <head>\n")
				v52_:write("    <title>XML Documentation (v" .. g_gameVersionDisplay .. ")</title>\n")
				v52_:write("  </head>\n")
				v52_:write("  <style>\n")
				v52_:write("    li {\n")
				v52_:write("      margin: 5px;\n")
				v52_:write("    }\n")
				v52_:write("    a {\n")
				v52_:write("      text-decoration:none;\n")
				v52_:write("      font-size: 15pt;\n")
				v52_:write("      color: #000000;\n")
				v52_:write("    }\n")
				v52_:write("  </style>\n")
				v52_:write("<body>\n")
				v52_:write("  <h1>Schema Overview</h1>\n")
				v52_:write("  <ul>\n")
				for _, v53_ in ipairs(v47_) do
					v52_:write("   <li><a href=\"" .. v53_.name .. ".html\">" .. v53_.name .. "</a></li>\n")
				end
				v52_:write("  </ul>\n")
				v52_:write("</body>\n")
				v52_:write("</html>\n")
				v52_:close()
			end
		else
			printError("Error: schema export should only be done with the game in english language setting")
			return
		end
	else
		printError("Error: schema export is only available if the game was launched with \'-scriptDebug\'")
		return
	end
end
addConsoleCommand("gsXMLGenerateSchemas", "Generates xml schemas", "XMLManager.consoleCommandGenerateSchemas", nil, "[deleteExisting=false]")
g_xmlManager = XMLManager.new()
