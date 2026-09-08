-- Local values: OverlayManager_mt
OverlayManager = {}
local OverlayManager_mt = Class(OverlayManager)
function OverlayManager.new()
	-- upvalues: (copy) OverlayManager_mt
	local v2_ = OverlayManager_mt
	local v3_ = setmetatable({}, v2_)
	v3_.textureConfigs = {}
	addConsoleCommand("gsOverlayManagerReset", "Deletes all currently loaded texture configurations", "resetConfigurations", v3_)
	g_plainColorSliceId = "gui.colorPreset"
	return v3_
end

-- Local values: xmlFile, directory, textureConfig, imageFilename, imageWidth, imageHeight
function OverlayManager:addTextureConfigFile(filename, prefix, customEnv)
	if customEnv ~= nil then
		prefix = customEnv .. "." .. prefix
	end
	if filename == nil then
		Logging.warning("Filename for texture config file is empty")
		return
	elseif self.textureConfigs[prefix] == nil or g_gui.currentlyReloading then
		local v_u_8_ = XMLFile.load("TextureConfig", filename)
		local v9_ = Utils.getDirectory(filename)
		if v_u_8_ == nil then
			Logging.warning("Failed to load XML file from path \'%s\'", filename)
			return
		else
			local v_u_10_ = {
				["xmlFilename"] = filename
			}
			local v11_ = v_u_8_:getString("texture.meta.filename")
			if v11_ == nil then
				Logging.xmlWarning(v_u_8_, "Missing filename in meta data")
				return
			else
				v_u_10_.imageFilename = v9_ .. v11_
				local v12_ = v_u_8_:getInt("texture.meta.size#width")
				if v12_ == nil then
					Logging.xmlWarning(v_u_8_, "Missing imageWidth in meta data")
					return
				else
					local v13_ = v_u_8_:getInt("texture.meta.size#height")
					if v13_ == nil then
						Logging.xmlWarning(v_u_8_, "Missing imageHeight in meta data")
					else
						v_u_10_.imageSize = { v12_, v13_ }
						v_u_10_.slices = {}
						v_u_8_:iterate("texture.slices.slice", function(p14_, p15_)
							-- upvalues: (copy) v_u_8_, (ref) prefix, (copy) v_u_10_
							local v16_ = {}
							local v17_ = v_u_8_:getString(p15_ .. "#id")
							if v17_ == nil then
								Logging.xmlWarning(v_u_8_, "Missing ID for slice nr. %i", p14_)
								return
							else
								v16_.sliceId = prefix .. "." .. v17_
								local v18_ = v_u_8_:getString(p15_ .. "#uvs")
								if v18_ == nil then
									Logging.xmlWarning(v_u_8_, "Missing UVs for slice with ID %s", v16_.sliceId)
								else
									local v19_ = GuiUtils.getNormalizedScreenValues
									local _, _, v20_, v21_ = unpack(v19_(v18_))
									if v20_ == nil then
										v16_.width = 0
										Logging.xmlWarning(v_u_8_, "Missing width for slice with ID %s", v16_.sliceId)
									else
										v16_.width = GuiUtils.getNormalizedXValue(v20_)
									end
									if v21_ == nil then
										v16_.height = 0
										Logging.xmlWarning(v_u_8_, "Missing height for slice with ID %s", v16_.sliceId)
									else
										v16_.height = GuiUtils.getNormalizedYValue(v21_)
									end
									local v22_ = string.split
									local _, _, v23_, v24_ = unpack(v22_(v18_, " "))
									v16_.uvsStr = v18_
									v16_.size = { v20_, v21_ }
									v16_.sizeStr = v23_ .. " " .. v24_
									v16_.imageSize = v_u_10_.imageSize
									v16_.filename = v_u_10_.imageFilename
									v16_.uvs = GuiUtils.getUVs(v18_, v_u_10_.imageSize, {
										0,
										0,
										0,
										0,
										0,
										0,
										0,
										0
									})
									if v_u_10_.slices[v17_] ~= nil then
										Logging.xmlWarning(v_u_8_, "Duplicate slice ID %s", v16_.sliceId)
									end
									v_u_10_.slices[v17_] = v16_
								end
							end
						end)
						self.textureConfigs[prefix] = v_u_10_
						v_u_8_:delete()
					end
				end
			end
		end
	else
		Logging.warning("Texture config file with prefix \'%s\' already exists", prefix)
		return
	end
end

function OverlayManager:resetConfigurations()
	self.textureConfigs = {}
	Logging.info("OverlayManager: Deleted all texture configurations")
end

-- Local values: identifierSplit, prefix, sliceId, textureConfig, slice, overlay
function OverlayManager:createOverlay(identifier, posX, posY, width, height, customEnv)
	local v33_ = string.split(identifier, ".")
	local v34_ = v33_[1]
	local v35_ = v33_[2]
	if v34_ == nil or v35_ == nil then
		Logging.warning("Identifier \'%s\' does not contain prefix or slice ID", identifier)
		return nil
	end
	if customEnv ~= nil then
		v34_ = customEnv .. "." .. v34_
	end
	local v36_ = self.textureConfigs[v34_]
	if v36_ == nil then
		Logging.warning("No texture config with prefix \'%s\' found", v34_)
		return nil
	end
	local v37_ = v36_.slices[v35_]
	if v37_ == nil then
		Logging.xmlWarning(v36_.xmlFilename, "No slice with ID \'%s\' found in texture config \'%s\'", v35_, v34_)
		return nil
	end
	local v38_ = width or v37_.width
	local v39_ = height or v37_.height
	local v40_ = Overlay.new(v36_.imageFilename, posX or 0, posY or 0, v38_, v39_)
	v40_:setUVs(v37_.uvs)
	return v40_
end

-- Local values: identifierSplit, prefix, sliceId, textureConfig, slice
function OverlayManager:getSliceInfoById(identifier, customEnv)
	if identifier == nil then
		return nil
	end
	local v44_ = string.split(identifier, ".")
	local v45_ = v44_[1]
	local v46_ = v44_[2]
	if v45_ == nil or v46_ == nil then
		Logging.warning("Identifier \'%s\' does not contain prefix or slice ID", identifier)
		return nil
	end
	if customEnv ~= nil then
		v45_ = customEnv .. "." .. v45_
	end
	local v47_ = self.textureConfigs[v45_]
	if v47_ == nil then
		Logging.warning("No texture config with prefix \'%s\' found", v45_)
		return nil
	end
	local v48_ = v47_.slices[v46_]
	if v48_ ~= nil then
		return v48_
	end
	Logging.warning("No slice with ID \'%s\' found in texture config \'%s\'", v46_, v45_)
	return nil
end

-- Local values: textureConfig, metadata
function OverlayManager:getConfigMetaData(configPrefix, customEnv)
	if configPrefix == nil then
		Logging.warning("Texture config prefix is empty")
		return nil
	end
	if customEnv ~= nil then
		configPrefix = customEnv .. "." .. configPrefix
	end
	local v52_ = self.textureConfigs[configPrefix]
	if v52_ ~= nil then
		return {
			["filename"] = v52_.imageFilename,
			["imageSize"] = v52_.imageSize
		}
	end
	Logging.warning("No texture config with prefix \'%s\' found", configPrefix)
	return nil
end
