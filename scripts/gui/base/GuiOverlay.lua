GuiOverlay = {}
GuiOverlay.STATE_NORMAL = 1
GuiOverlay.STATE_DISABLED = 2
GuiOverlay.STATE_FOCUSED = 3
GuiOverlay.STATE_PRESSED = 4
GuiOverlay.STATE_SELECTED = 5
GuiOverlay.STATE_HIGHLIGHTED = 6
GuiOverlay.OVERLAY_STATE_SUFFIXES = { [GuiOverlay.STATE_NORMAL] = "", [GuiOverlay.STATE_DISABLED] = "Disabled", [GuiOverlay.STATE_FOCUSED] = "Focused", [GuiOverlay.STATE_PRESSED] = "Pressed", [GuiOverlay.STATE_SELECTED] = "Selected", [GuiOverlay.STATE_HIGHLIGHTED] = "Highlighted" }
function GuiOverlay:loadOverlay(overlay, overlayName, imageSize, profile, xmlFile, key)
	if overlay.uvs == nil then
		overlay.uvs = Overlay.DEFAULT_UVS
	end
	if overlay.color == nil then
		overlay.color = { 1, 1, 1, 1 }
	end
	if xmlFile ~= nil then
		GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
		GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
		GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
		overlay.sdfWidth = getXMLInt(xmlFile, key .. "#" .. overlayName .. "SdfWidth") or overlay.sdfWidth
	elseif profile ~= nil then
		GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
		GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
		GuiOverlay.loadProfileColors(profile, overlay, overlayName)
		overlay.sdfWidth = profile:getNumber(overlayName .. "SdfWidth", overlay.sdfWidth)
	end
	if overlay.filename == nil then
		return nil
	else
		if overlay.previewFilename == nil then
			overlay.previewFilename = "dataS/menu/black.png"
		end
		return overlay
	end
end
function GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local uvsStateName = overlayName .. stateName .. "UVs"
		local uvs = getXMLString(xmlFile, key .. "#" .. uvsStateName)
		local sliceIdStateName = overlayName .. stateName .. "SliceId"
		local sliceId = getXMLString(xmlFile, key .. "#" .. sliceIdStateName)
		if sliceId ~= nil then
			if sliceId ~= "noSlice" then
				local slice = g_overlayManager:getSliceInfoById(sliceId)
				if slice == nil then
					continue
				end
				overlay["uvs" .. stateName] = table.clone(slice.uvs)
				overlay["filename" .. stateName] = slice.filename
				overlay["sliceId" .. stateName] = sliceId
				local rotation = getXMLInt(xmlFile, key .. "#" .. overlayName .. stateName .. "UVRotation")
				if rotation ~= nil then
					GuiUtils.rotateUVs(overlay["uvs" .. stateName], rotation)
				end
				local invertX = getXMLBool(xmlFile, key .. "#" .. overlayName .. stateName .. "InvertX")
				if invertX then
					GuiUtils.invertUVs(overlay["uvs" .. stateName], true)
				end
			else
				if uvs == nil then
					continue
				end
				overlay["uvs" .. stateName] = GuiUtils.getUVs(uvs, imageSize, overlay["uvs" .. stateName], getXMLInt(xmlFile, key .. "#" .. overlayName .. stateName .. "UVRotation"))
			end
		end
	end
end
function GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local uvsStateName = overlayName .. stateName .. "UVs"
		local uvs = profile:getValue(uvsStateName)
		local sliceIdStateName = overlayName .. stateName .. "SliceId"
		local sliceId = profile:getValue(sliceIdStateName)
		if sliceId ~= nil then
			if sliceId ~= "noSlice" then
				local slice = g_overlayManager:getSliceInfoById(sliceId)
				if slice == nil then
					continue
				end
				overlay["uvs" .. stateName] = table.clone(slice.uvs)
				overlay["filename" .. stateName] = slice.filename
				overlay["sliceId" .. stateName] = sliceId
				local rotation = profile:getNumber(overlayName .. stateName .. "UVRotation")
				if rotation ~= nil then
					GuiUtils.rotateUVs(overlay["uvs" .. stateName], rotation)
				end
				if profile:getBool(overlayName .. stateName .. "InvertX") == true then
					GuiUtils.invertUVs(overlay["uvs" .. stateName], true)
				end
				if profile:getBool(overlayName .. stateName .. "InvertY") == true then
					GuiUtils.invertUVs(overlay["uvs" .. stateName], false)
				end
			else
				if uvs == nil then
					continue
				end
				overlay["uvs" .. stateName] = GuiUtils.getUVs(uvs, imageSize, overlay["uvs" .. stateName], profile:getNumber(overlayName .. "UVRotation"))
				if profile.filename == g_baseUIFilename then
					Logging.warning("Profile %s does not use new slice format", profile.name)
				end
			end
		end
	end
end
function GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local colorStateName = overlayName .. stateName .. "Color"
		local color = GuiUtils.getColorGradientArray(getXMLString(xmlFile, key .. "#" .. colorStateName))
		if color == nil then
			continue
		end
		overlay["color" .. stateName] = color
	end
	local rotation = getXMLFloat(xmlFile, key .. "#" .. overlayName .. "Rotation")
	if rotation ~= nil then
		overlay.rotation = math.rad(rotation)
	end
	local isWebOverlay = getXMLBool(xmlFile, key .. "#" .. overlayName .. "IsWebOverlay")
	if isWebOverlay ~= nil then
		overlay.isWebOverlay = isWebOverlay
	end
end
function GuiOverlay.loadProfileColors(profile, overlay, overlayName)
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local colorStateName = overlayName .. stateName .. "Color"
		local color = GuiUtils.getColorGradientArray(profile:getValue(colorStateName))
		if color == nil then
			continue
		end
		overlay["color" .. stateName] = color
	end
	local rotation = profile:getNumber(overlayName .. "Rotation")
	if rotation ~= nil then
		overlay.rotation = math.rad(rotation)
	end
	local isWebOverlay = profile:getBool(overlayName .. "IsWebOverlay")
	if isWebOverlay ~= nil then
		overlay.isWebOverlay = isWebOverlay
	end
end
function GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
	local overlayFilename = overlayName .. "Filename"
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local filename = getXMLString(xmlFile, key .. "#" .. overlayFilename .. stateName)
		if filename == nil then
			continue
		end
		overlay["filename" .. stateName] = GuiOverlay.resolveFilename(filename)
	end
	local previewFilename = overlayName .. "PreviewFilename"
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local filename = getXMLString(xmlFile, key .. "#" .. previewFilename .. stateName)
		if filename == nil then
			continue
		end
		overlay["previewFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
	end
	local maskFilename = overlayName .. "MaskFilename"
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local filename = getXMLString(xmlFile, key .. "#" .. maskFilename .. stateName)
		if filename == nil then
			continue
		end
		overlay["maskFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
	end
end
function GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
	local overlayFilename = overlayName .. "Filename"
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local filename = profile:getValue(overlayFilename .. stateName)
		if filename == nil then
			continue
		end
		overlay["filename" .. stateName] = GuiOverlay.resolveFilename(filename)
	end
	local previewFilename = overlayName .. "PreviewFilename"
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local filename = profile:getValue(previewFilename .. stateName)
		if filename == nil then
			continue
		end
		overlay["previewFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
	end
	local maskFilename = overlayName .. "MaskFilename"
	for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local filename = profile:getValue(maskFilename .. stateName)
		if filename == nil then
			continue
		end
		overlay["maskFilename" .. stateName] = GuiOverlay.resolveFilename(filename)
	end
end
function GuiOverlay.resolveFilename(filename)
	if filename == "g_baseUIFilename" then
		filename = g_baseUIFilename
	elseif filename == "g_baseHUDFilename" then
		filename = g_baseHUDFilename
	elseif filename == "g_iconsUIFilename" then
		filename = g_iconsUIFilename
	end
	if filename ~= nil then
		filename = string.gsub(filename, "$l10nSuffix", g_languageSuffix)
	end
	return filename
end
function GuiOverlay.createOverlay(overlay, filename)
	if overlay.overlay ~= nil and (overlay.filename == filename or filename == nil) then
		return overlay
	end
	GuiOverlay.deleteOverlay(overlay)
	if filename ~= nil then
		overlay.filename = filename
	end
	if overlay.filename ~= nil then
		local imageOverlay = nil
		if overlay.isWebOverlay == nil or not overlay.isWebOverlay or overlay.isWebOverlay and not overlay.filename:startsWith("http") then
			imageOverlay = createImageOverlay(overlay.filename)
		else
			imageOverlay = createWebImageOverlay(overlay.filename, overlay.previewFilename)
		end
		if imageOverlay ~= 0 then
			overlay.overlay = imageOverlay
			GuiOverlay.createStateOverlays(overlay)
			if overlay.sdfWidth ~= nil then
				setOverlaySignedDistanceFieldWidth(imageOverlay, overlay.sdfWidth)
			end
		end
	end
	overlay.rotation = overlay.rotation or 0
	overlay.alpha = overlay.alpha or 1
	return overlay
end
function GuiOverlay.createStateOverlays(overlay)
	for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local imageOverlay = nil
		local overlayMask = nil
		if state ~= GuiOverlay.STATE_NORMAL then
			if overlay["filename" .. stateName] ~= nil and (overlay.isWebOverlay and overlay.filename:startsWith("http")) then
				if overlay["previewFilename" .. stateName] ~= nil then
					imageOverlay = createWebImageOverlay(overlay["filename" .. stateName], overlay["previewFilename" .. stateName])
				else
					imageOverlay = createImageOverlay(overlay["filename" .. stateName])
				end
			end
			if imageOverlay ~= 0 then
				overlay["overlay" .. stateName] = imageOverlay
			end
		end
		if overlay["maskFilename" .. stateName] ~= nil then
			overlayMask = createOverlayTextureFromFile(overlay["maskFilename" .. stateName])
		end
		if overlayMask == nil or overlayMask == 0 then
			continue
		end
		overlay["overlayMask" .. stateName] = overlayMask
	end
end
function GuiOverlay.copyOverlay(overlay, overlaySrc, overrideFilename)
	overlay.alpha = overlaySrc.alpha
	overlay.isWebOverlay = overlaySrc.isWebOverlay
	overlay.sdfWidth = overlaySrc.sdfWidth
	for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		overlay["filename" .. stateName] = overlaySrc["filename" .. stateName]
		overlay["maskFilename" .. stateName] = overlaySrc["maskFilename" .. stateName]
		overlay["previewFilename" .. stateName] = overlaySrc["previewFilename" .. stateName]
		overlay["rotation" .. stateName] = overlaySrc["rotation" .. stateName]
		overlay["uvs" .. stateName] = overlaySrc["uvs" .. stateName] and table.clone(overlaySrc["uvs" .. stateName])
		overlay["color" .. stateName] = overlaySrc["color" .. stateName] and table.copyIndex(overlaySrc["color" .. stateName])
	end
	overlay.sliceId = overlaySrc.sliceId
	overlay.filename = overrideFilename or overlay.filename
	return GuiOverlay.createOverlay(overlay)
end
function GuiOverlay.deleteOverlay(overlay)
	if overlay ~= nil then
		for _, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
			if overlay["overlay" .. stateName] ~= nil then
				delete(overlay["overlay" .. stateName])
				overlay["overlay" .. stateName] = nil
			end
			if overlay["overlayMask" .. stateName] == nil then
				continue
			end
			delete(overlay["overlayMask" .. stateName])
			overlay["overlayMask" .. stateName] = nil
		end
	end
end
function GuiOverlay.getOverlayColor(overlay, state)
	local color = overlay.color
	if state == GuiOverlay.STATE_DISABLED then
		color = overlay.colorDisabled
	elseif state == GuiOverlay.STATE_FOCUSED then
		color = overlay.colorFocused
	elseif state == GuiOverlay.STATE_SELECTED then
		color = overlay.colorSelected
	elseif state == GuiOverlay.STATE_HIGHLIGHTED then
		color = overlay.colorHighlighted
	elseif state == GuiOverlay.STATE_PRESSED then
		color = overlay.colorPressed
		if color == nil then
			color = overlay.colorFocused
		end
	end
	if color == nil then
		color = overlay.color
	end
	return color
end
function GuiOverlay.getOverlayUVs(overlay, state)
	local uvs = overlay.uvs
	if state == GuiOverlay.STATE_DISABLED then
		uvs = overlay.uvsDisabled
	elseif state == GuiOverlay.STATE_PRESSED then
		uvs = overlay.uvsPressed
	elseif state == GuiOverlay.STATE_FOCUSED then
		uvs = overlay.uvsFocused
	elseif state == GuiOverlay.STATE_SELECTED then
		uvs = overlay.uvsSelected
	elseif state == GuiOverlay.STATE_HIGHLIGHTED then
		uvs = overlay.uvsHighlighted
	end
	if uvs == nil then
		uvs = overlay.uvs
	end
	return uvs
end
function GuiOverlay.getOverlay(overlay, currentState)
	local currentOverlay = overlay.overlay
	for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		if currentState == state then
			currentOverlay = overlay["overlay" .. stateName]
			if state == GuiOverlay.STATE_PRESSED then
				if currentOverlay == nil then
					currentOverlay = overlay["overlay" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
					break
				end
				if currentOverlay == nil then
					currentOverlay = overlay.overlay
				end
				return currentOverlay
			end
		end
	end
end
function GuiOverlay.getMaskOverlay(overlay, currentState)
	local currentOverlay = nil
	for state, stateName in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		if currentState == state then
			currentOverlay = overlay["overlayMask" .. stateName]
			if state == GuiOverlay.STATE_PRESSED then
				if currentOverlay == nil then
					currentOverlay = overlay["overlayMask" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
					break
				end
				if currentOverlay == nil then
					currentOverlay = overlay.overlayMask
				end
				return currentOverlay
			end
		end
	end
end
function GuiOverlay.renderOverlay(overlay, posX, posY, sizeX, sizeY, state, clipX1, clipY1, clipX2, clipY2, maskPosX, maskPosY, maskSizeX, maskSizeY)
	local currentOverlay = GuiOverlay.getOverlay(overlay, state)
	if currentOverlay ~= nil then
		local colors = GuiOverlay.getOverlayColor(overlay, state)
		if colors[4] == 0 and colors[8] ~= nil then
			if not overlay.hasCustomRotation then
				local pivotX = sizeX / 2
				local pivotY = sizeY / 2
				if overlay.customPivot ~= nil then
					pivotX = overlay.customPivot[1]
					pivotY = overlay.customPivot[2]
				end
				setOverlayRotation(currentOverlay, overlay.rotation, pivotX, pivotY)
			end
			local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(GuiOverlay.getOverlayUVs(overlay, state))
			local oldX1 = posX
			local oldY1 = posY
			local oldX2 = sizeX + posX
			local oldY2 = sizeY + posY
			local oldSizeX = sizeX
			local oldSizeY = sizeY
			if clipX1 ~= nil then
				local posX2 = posX + sizeX
				local posY2 = posY + sizeY
				posX = math.max(posX, clipX1)
				posY = math.max(posY, clipY1)
				sizeX = math.max(math.min(posX2, clipX2) - posX, 0)
				sizeY = math.max(math.min(posY2, clipY2) - posY, 0)
				if sizeX == 0 or sizeY == 0 then
					return
				end
				local ou1 = u1
				local ov1 = v1
				local ou2 = u2
				local ov2 = v2
				local ou3 = u3
				local ov3 = v3
				local ou4 = u4
				local ov4 = v4
				local p1 = (posX - oldX1) / (oldX2 - oldX1)
				local p2 = (posY - oldY1) / (oldY2 - oldY1)
				local p3 = (posX + sizeX - oldX1) / (oldX2 - oldX1)
				local p4 = (posY + sizeY - oldY1) / (oldY2 - oldY1)
				u1 = (ou3 - ou1) * p1 + ou1
				v1 = (ov2 - ov1) * p2 + ov1
				u2 = (ou3 - ou1) * p1 + ou1
				v2 = (ov4 - ov3) * p4 + ov3
				u3 = (ou3 - ou1) * p3 + ou1
				v3 = (ov2 - ov1) * p2 + ov1
				u4 = (ou4 - ou2) * p3 + ou2
				v4 = (ov4 - ov3) * p4 + ov3
			end
			setOverlayUVs(currentOverlay, u1, v1, u2, v2, u3, v3, u4, v4)
			local mask = GuiOverlay.getMaskOverlay(overlay, state)
			if mask ~= nil then
				maskPosX = maskPosX ~= nil and oldX1 + maskPosX or oldX1
				maskPosY = maskPosY ~= nil and oldY1 + maskPosY or oldY1
				maskSizeX = maskPosX ~= nil and maskSizeX or oldSizeX
				maskSizeY = maskPosY ~= nil and maskSizeY or oldSizeY
				set2DMaskFromTexture(mask, true, maskPosX, maskPosY, maskSizeX, maskSizeY)
			end
			if colors[5] ~= nil then
				setOverlayCornerColor(currentOverlay, 0, colors[1], colors[2], colors[3], colors[4] * overlay.alpha)
				setOverlayCornerColor(currentOverlay, 1, colors[5], colors[6], colors[7], colors[8] * overlay.alpha)
				setOverlayCornerColor(currentOverlay, 2, colors[9], colors[10], colors[11], colors[12] * overlay.alpha)
				setOverlayCornerColor(currentOverlay, 3, colors[13], colors[14], colors[15], colors[16] * overlay.alpha)
			else
				local r, g, b, a = unpack(colors)
				setOverlayColor(currentOverlay, r, g, b, a * overlay.alpha)
			end
			renderOverlay(currentOverlay, posX, posY, sizeX, sizeY)
			if mask ~= nil then
				set2DMaskFromTexture(0, true, 0, 0, 0, 0)
			end
		end
	end
end
function GuiOverlay.copyColors(overlay, source)
	overlay.color = source.color
	overlay.colorDisabled = source.colorDisabled
	overlay.colorFocused = source.colorFocused
	overlay.colorSelected = source.colorSelected
	overlay.colorHighlighted = source.colorHighlighted
	overlay.colorPressed = source.colorPressed
end
function GuiOverlay.setRotation(overlay, rotation, centerX, centerY)
	if overlay.overlay ~= nil then
		setOverlayRotation(overlay.overlay, rotation, centerX, centerY)
		overlay.hasCustomRotation = true
	end
end
function GuiOverlay.setColor(overlay, r, g, b, a)
	overlay.color = { r, g, b, a }
end
function GuiOverlay.setSelectedColor(overlay, r, g, b, a)
	overlay.colorSelected = { r, g, b, a }
end
