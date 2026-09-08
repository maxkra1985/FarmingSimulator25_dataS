GuiOverlay = {}
GuiOverlay.STATE_NORMAL = 1
GuiOverlay.STATE_DISABLED = 2
GuiOverlay.STATE_FOCUSED = 3
GuiOverlay.STATE_PRESSED = 4
GuiOverlay.STATE_SELECTED = 5
GuiOverlay.STATE_HIGHLIGHTED = 6
GuiOverlay.OVERLAY_STATE_SUFFIXES = {
	[GuiOverlay.STATE_NORMAL] = "",
	[GuiOverlay.STATE_DISABLED] = "Disabled",
	[GuiOverlay.STATE_FOCUSED] = "Focused",
	[GuiOverlay.STATE_PRESSED] = "Pressed",
	[GuiOverlay.STATE_SELECTED] = "Selected",
	[GuiOverlay.STATE_HIGHLIGHTED] = "Highlighted"
}

function GuiOverlay:loadOverlay(overlay, overlayName, imageSize, profile, xmlFile, key)
	if overlay.uvs == nil then
		overlay.uvs = Overlay.DEFAULT_UVS
	end
	if overlay.color == nil then
		overlay.color = {
			1,
			1,
			1,
			1
		}
	end
	if xmlFile == nil then
		if profile ~= nil then
			GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
			GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
			GuiOverlay.loadProfileColors(profile, overlay, overlayName)
			overlay.sdfWidth = profile:getNumber(overlayName .. "SdfWidth", overlay.sdfWidth)
		end
	else
		GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
		GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
		GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
		overlay.sdfWidth = getXMLInt(xmlFile, key .. "#" .. overlayName .. "SdfWidth") or overlay.sdfWidth
	end
	if overlay.filename == nil then
		return nil
	end
	if overlay.previewFilename == nil then
		overlay.previewFilename = "dataS/menu/black.png"
	end
	return overlay
end

-- Local values: _, stateName, uvsStateName, uvs, sliceIdStateName, sliceId, slice, rotation, invertX
function GuiOverlay.loadXMLUVs(xmlFile, key, overlay, overlayName, imageSize)
	for _, v12_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v13_ = overlayName .. v12_ .. "UVs"
		local v14_ = getXMLString(xmlFile, key .. "#" .. v13_)
		local v15_ = overlayName .. v12_ .. "SliceId"
		local v16_ = getXMLString(xmlFile, key .. "#" .. v15_)
		if v16_ == nil or v16_ == "noSlice" then
			if v14_ ~= nil then
				overlay["uvs" .. v12_] = GuiUtils.getUVs(v14_, imageSize, overlay["uvs" .. v12_], getXMLInt(xmlFile, key .. "#" .. overlayName .. v12_ .. "UVRotation"))
			end
		else
			local v17_ = g_overlayManager:getSliceInfoById(v16_)
			if v17_ ~= nil then
				overlay["uvs" .. v12_] = table.clone(v17_.uvs)
				overlay["filename" .. v12_] = v17_.filename
				overlay["sliceId" .. v12_] = v16_
				local v18_ = getXMLInt(xmlFile, key .. "#" .. overlayName .. v12_ .. "UVRotation")
				if v18_ ~= nil then
					GuiUtils.rotateUVs(overlay["uvs" .. v12_], v18_)
				end
				if getXMLBool(xmlFile, key .. "#" .. overlayName .. v12_ .. "InvertX") then
					GuiUtils.invertUVs(overlay["uvs" .. v12_], true)
				end
			end
		end
	end
end

-- Local values: _, stateName, uvsStateName, uvs, sliceIdStateName, sliceId, slice, rotation
function GuiOverlay.loadProfileUVs(profile, overlay, overlayName, imageSize)
	for _, v23_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v24_ = profile:getValue(overlayName .. v23_ .. "UVs")
		local v25_ = profile:getValue(overlayName .. v23_ .. "SliceId")
		if v25_ == nil or v25_ == "noSlice" then
			if v24_ ~= nil then
				overlay["uvs" .. v23_] = GuiUtils.getUVs(v24_, imageSize, overlay["uvs" .. v23_], profile:getNumber(overlayName .. "UVRotation"))
				if profile.filename == g_baseUIFilename then
					Logging.warning("Profile %s does not use new slice format", profile.name)
				end
			end
		else
			local v26_ = g_overlayManager:getSliceInfoById(v25_)
			if v26_ ~= nil then
				overlay["uvs" .. v23_] = table.clone(v26_.uvs)
				overlay["filename" .. v23_] = v26_.filename
				overlay["sliceId" .. v23_] = v25_
				local v27_ = profile:getNumber(overlayName .. v23_ .. "UVRotation")
				if v27_ ~= nil then
					GuiUtils.rotateUVs(overlay["uvs" .. v23_], v27_)
				end
				if profile:getBool(overlayName .. v23_ .. "InvertX") == true then
					GuiUtils.invertUVs(overlay["uvs" .. v23_], true)
				end
				if profile:getBool(overlayName .. v23_ .. "InvertY") == true then
					GuiUtils.invertUVs(overlay["uvs" .. v23_], false)
				end
			end
		end
	end
end

-- Local values: _, stateName, colorStateName, color, rotation, isWebOverlay
function GuiOverlay.loadXMLColors(xmlFile, key, overlay, overlayName)
	for _, v32_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v33_ = overlayName .. v32_ .. "Color"
		local v34_ = GuiUtils.getColorGradientArray(getXMLString(xmlFile, key .. "#" .. v33_))
		if v34_ ~= nil then
			overlay["color" .. v32_] = v34_
		end
	end
	local v35_ = getXMLFloat(xmlFile, key .. "#" .. overlayName .. "Rotation")
	if v35_ ~= nil then
		overlay.rotation = math.rad(v35_)
	end
	local v36_ = getXMLBool(xmlFile, key .. "#" .. overlayName .. "IsWebOverlay")
	if v36_ ~= nil then
		overlay.isWebOverlay = v36_
	end
end

-- Local values: _, stateName, colorStateName, color, rotation, isWebOverlay
function GuiOverlay.loadProfileColors(profile, overlay, overlayName)
	for _, v40_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v41_ = overlayName .. v40_ .. "Color"
		local v42_ = GuiUtils.getColorGradientArray(profile:getValue(v41_))
		if v42_ ~= nil then
			overlay["color" .. v40_] = v42_
		end
	end
	local v43_ = profile:getNumber(overlayName .. "Rotation")
	if v43_ ~= nil then
		overlay.rotation = math.rad(v43_)
	end
	local v44_ = profile:getBool(overlayName .. "IsWebOverlay")
	if v44_ ~= nil then
		overlay.isWebOverlay = v44_
	end
end

-- Local values: overlayFilename, _, stateName, filename, previewFilename, _, stateName, filename, maskFilename, _, stateName, filename
function GuiOverlay.loadXMLFilenames(xmlFile, key, overlay, overlayName)
	local v49_ = overlayName .. "Filename"
	for _, v50_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v51_ = getXMLString(xmlFile, key .. "#" .. v49_ .. v50_)
		if v51_ ~= nil then
			overlay["filename" .. v50_] = GuiOverlay.resolveFilename(v51_)
		end
	end
	local v52_ = overlayName .. "PreviewFilename"
	for _, v53_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v54_ = getXMLString(xmlFile, key .. "#" .. v52_ .. v53_)
		if v54_ ~= nil then
			overlay["previewFilename" .. v53_] = GuiOverlay.resolveFilename(v54_)
		end
	end
	local v55_ = overlayName .. "MaskFilename"
	for _, v56_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v57_ = getXMLString(xmlFile, key .. "#" .. v55_ .. v56_)
		if v57_ ~= nil then
			overlay["maskFilename" .. v56_] = GuiOverlay.resolveFilename(v57_)
		end
	end
end

-- Local values: overlayFilename, _, stateName, filename, previewFilename, _, stateName, filename, maskFilename, _, stateName, filename
function GuiOverlay.loadProfileFilenames(profile, overlay, overlayName)
	local v61_ = overlayName .. "Filename"
	for _, v62_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v63_ = profile:getValue(v61_ .. v62_)
		if v63_ ~= nil then
			overlay["filename" .. v62_] = GuiOverlay.resolveFilename(v63_)
		end
	end
	local v64_ = overlayName .. "PreviewFilename"
	for _, v65_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v66_ = profile:getValue(v64_ .. v65_)
		if v66_ ~= nil then
			overlay["previewFilename" .. v65_] = GuiOverlay.resolveFilename(v66_)
		end
	end
	local v67_ = overlayName .. "MaskFilename"
	for _, v68_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v69_ = profile:getValue(v67_ .. v68_)
		if v69_ ~= nil then
			overlay["maskFilename" .. v68_] = GuiOverlay.resolveFilename(v69_)
		end
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

-- Local values: imageOverlay
function GuiOverlay.createOverlay(overlay, filename)
	if overlay.overlay ~= nil and (overlay.filename == filename or filename == nil) then
		return overlay
	end
	GuiOverlay.deleteOverlay(overlay)
	if filename ~= nil then
		overlay.filename = filename
	end
	if overlay.filename ~= nil then
		local v73_
		if overlay.isWebOverlay == nil or (not overlay.isWebOverlay or overlay.isWebOverlay and not overlay.filename:startsWith("http")) then
			v73_ = createImageOverlay(overlay.filename)
		else
			v73_ = createWebImageOverlay(overlay.filename, overlay.previewFilename)
		end
		if v73_ ~= 0 then
			overlay.overlay = v73_
			GuiOverlay.createStateOverlays(overlay)
			if overlay.sdfWidth ~= nil then
				setOverlaySignedDistanceFieldWidth(v73_, overlay.sdfWidth)
			end
		end
	end
	overlay.rotation = overlay.rotation or 0
	overlay.alpha = overlay.alpha or 1
	return overlay
end

-- Local values: state, stateName, imageOverlay, overlayMask
function GuiOverlay.createStateOverlays(overlay)
	for v75_, v76_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		local v77_ = nil
		local v78_ = nil
		if v75_ ~= GuiOverlay.STATE_NORMAL then
			if overlay["filename" .. v76_] ~= nil then
				if overlay.isWebOverlay and (overlay.filename:startsWith("http") and overlay["previewFilename" .. v76_] ~= nil) then
					v77_ = createWebImageOverlay(overlay["filename" .. v76_], overlay["previewFilename" .. v76_])
				else
					v77_ = createImageOverlay(overlay["filename" .. v76_])
				end
			end
			if v77_ ~= 0 then
				overlay["overlay" .. v76_] = v77_
			end
		end
		if overlay["maskFilename" .. v76_] ~= nil then
			v78_ = createOverlayTextureFromFile(overlay["maskFilename" .. v76_])
		end
		if v78_ ~= nil and v78_ ~= 0 then
			overlay["overlayMask" .. v76_] = v78_
		end
	end
end

-- Local values: state, stateName
function GuiOverlay.copyOverlay(overlay, overlaySrc, overrideFilename)
	overlay.alpha = overlaySrc.alpha
	overlay.isWebOverlay = overlaySrc.isWebOverlay
	overlay.sdfWidth = overlaySrc.sdfWidth
	for _, v82_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		overlay["filename" .. v82_] = overlaySrc["filename" .. v82_]
		overlay["maskFilename" .. v82_] = overlaySrc["maskFilename" .. v82_]
		overlay["previewFilename" .. v82_] = overlaySrc["previewFilename" .. v82_]
		overlay["rotation" .. v82_] = overlaySrc["rotation" .. v82_]
		local v83_ = "uvs" .. v82_
		local v84_ = overlaySrc["uvs" .. v82_]
		if v84_ then
			v84_ = table.clone(overlaySrc["uvs" .. v82_])
		end
		overlay[v83_] = v84_
		local v85_ = "color" .. v82_
		local v86_ = overlaySrc["color" .. v82_]
		if v86_ then
			v86_ = table.copyIndex(overlaySrc["color" .. v82_])
		end
		overlay[v85_] = v86_
	end
	overlay.sliceId = overlaySrc.sliceId
	overlay.filename = overrideFilename or overlay.filename
	return GuiOverlay.createOverlay(overlay)
end

-- Local values: _, stateName
function GuiOverlay.deleteOverlay(overlay)
	if overlay ~= nil then
		for _, v88_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
			if overlay["overlay" .. v88_] ~= nil then
				delete(overlay["overlay" .. v88_])
				overlay["overlay" .. v88_] = nil
			end
			if overlay["overlayMask" .. v88_] ~= nil then
				delete(overlay["overlayMask" .. v88_])
				overlay["overlayMask" .. v88_] = nil
			end
		end
	end
end

-- Local values: color
function GuiOverlay.getOverlayColor(overlay, state)
	local v91_ = overlay.color
	if state == GuiOverlay.STATE_DISABLED then
		v91_ = overlay.colorDisabled
	elseif state == GuiOverlay.STATE_FOCUSED then
		v91_ = overlay.colorFocused
	elseif state == GuiOverlay.STATE_SELECTED then
		v91_ = overlay.colorSelected
	elseif state == GuiOverlay.STATE_HIGHLIGHTED then
		v91_ = overlay.colorHighlighted
	elseif state == GuiOverlay.STATE_PRESSED then
		v91_ = overlay.colorPressed
		if v91_ == nil then
			v91_ = overlay.colorFocused
		end
	end
	if v91_ == nil then
		v91_ = overlay.color
	end
	return v91_
end

-- Local values: uvs
function GuiOverlay.getOverlayUVs(overlay, state)
	local v94_ = overlay.uvs
	if state == GuiOverlay.STATE_DISABLED then
		v94_ = overlay.uvsDisabled
	elseif state == GuiOverlay.STATE_PRESSED then
		v94_ = overlay.uvsPressed
	elseif state == GuiOverlay.STATE_FOCUSED then
		v94_ = overlay.uvsFocused
	elseif state == GuiOverlay.STATE_SELECTED then
		v94_ = overlay.uvsSelected
	elseif state == GuiOverlay.STATE_HIGHLIGHTED then
		v94_ = overlay.uvsHighlighted
	end
	if v94_ == nil then
		v94_ = overlay.uvs
	end
	return v94_
end

-- Local values: currentOverlay, state, stateName
function GuiOverlay.getOverlay(overlay, currentState)
	local v97_ = overlay.overlay
	for v98_, v99_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		if currentState == v98_ then
			v97_ = overlay["overlay" .. v99_]
			if v98_ == GuiOverlay.STATE_PRESSED and v97_ == nil then
				v97_ = overlay["overlay" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
			end
			break
		end
	end
	if v97_ == nil then
		v97_ = overlay.overlay
	end
	return v97_
end

-- Local values: currentOverlay, state, stateName
function GuiOverlay.getMaskOverlay(overlay, currentState)
	local v102_ = nil
	for v103_, v104_ in pairs(GuiOverlay.OVERLAY_STATE_SUFFIXES) do
		if currentState == v103_ then
			v102_ = overlay["overlayMask" .. v104_]
			if v103_ == GuiOverlay.STATE_PRESSED and v102_ == nil then
				v102_ = overlay["overlayMask" .. GuiOverlay.OVERLAY_STATE_SUFFIXES[GuiOverlay.STATE_FOCUSED]]
			end
			break
		end
	end
	if v102_ == nil then
		v102_ = overlay.overlayMask
	end
	return v102_
end

-- Local values: currentOverlay, colors, pivotX, pivotY, u1, v1, u2, v2, u3, v3, u4, v4, oldX1, oldY1, oldX2, oldY2, oldSizeX, oldSizeY, posX2, posY2, ou1, ov1, ou2, ov2, ou3, ov3, ou4, ov4, p1, p2, p3, p4, mask, r, g, b, a
function GuiOverlay.renderOverlay(overlay, posX, posY, sizeX, sizeY, state, clipX1, clipY1, clipX2, clipY2, maskPosX, maskPosY, maskSizeX, maskSizeY)
	local v119_ = GuiOverlay.getOverlay(overlay, state)
	if v119_ ~= nil then
		local v120_ = GuiOverlay.getOverlayColor(overlay, state)
		if v120_[4] ~= 0 or v120_[8] ~= nil and (v120_[8] ~= 0 or (v120_[12] ~= 0 or v120_[16] ~= 0)) then
			if not overlay.hasCustomRotation then
				local v121_ = sizeX / 2
				local v122_ = sizeY / 2
				if overlay.customPivot ~= nil then
					v121_ = overlay.customPivot[1]
					v122_ = overlay.customPivot[2]
				end
				setOverlayRotation(v119_, overlay.rotation, v121_, v122_)
			end
			local v123_ = GuiOverlay.getOverlayUVs
			local v124_, v125_, v126_, v127_, v128_, v129_, v130_, v131_ = unpack(v123_(overlay, state))
			local v132_ = sizeX + posX
			local v133_ = sizeY + posY
			local v134_, v135_, v136_, v137_, v138_, v139_, v140_, v141_, v142_
			if clipX1 == nil then
				v134_ = v129_
				v135_ = v127_
				v136_ = v126_
				v137_ = posX
				v138_ = sizeY
				v139_ = sizeX
				v140_ = posY
				v141_ = v125_
				v142_ = v124_
			else
				local v143_ = posX + sizeX
				local v144_ = posY + sizeY
				v137_ = math.max(posX, clipX1)
				v140_ = math.max(posY, clipY1)
				local v145_ = math.min(v143_, clipX2) - v137_
				v139_ = math.max(v145_, 0)
				local v146_ = math.min(v144_, clipY2) - v140_
				v138_ = math.max(v146_, 0)
				if v139_ == 0 or v138_ == 0 then
					return
				end
				local v147_ = (v137_ - posX) / (v132_ - posX)
				local v148_ = (v140_ - posY) / (v133_ - posY)
				local v149_ = (v137_ + v139_ - posX) / (v132_ - posX)
				local v150_ = (v140_ + v138_ - posY) / (v133_ - posY)
				v142_ = (v128_ - v124_) * v147_ + v124_
				v141_ = (v127_ - v125_) * v148_ + v125_
				v136_ = (v128_ - v124_) * v147_ + v124_
				v135_ = (v131_ - v129_) * v150_ + v129_
				v128_ = (v128_ - v124_) * v149_ + v124_
				v134_ = (v127_ - v125_) * v148_ + v125_
				v130_ = (v130_ - v126_) * v149_ + v126_
				v131_ = (v131_ - v129_) * v150_ + v129_
			end
			setOverlayUVs(v119_, v142_, v141_, v136_, v135_, v128_, v134_, v130_, v131_)
			local v151_ = GuiOverlay.getMaskOverlay(overlay, state)
			if v151_ ~= nil then
				if maskPosX ~= nil then
					posX = posX + maskPosX or posX
				end
				if maskPosY ~= nil then
					posY = posY + maskPosY or posY
				end
				if posX ~= nil and maskSizeX then
					sizeX = maskSizeX
				end
				if posY ~= nil and maskSizeY then
					sizeY = maskSizeY
				end
				set2DMaskFromTexture(v151_, true, posX, posY, sizeX, sizeY)
			end
			if v120_[5] == nil then
				local v152_, v153_, v154_, v155_ = unpack(v120_)
				setOverlayColor(v119_, v152_, v153_, v154_, v155_ * overlay.alpha)
			else
				setOverlayCornerColor(v119_, 0, v120_[1], v120_[2], v120_[3], v120_[4] * overlay.alpha)
				setOverlayCornerColor(v119_, 1, v120_[5], v120_[6], v120_[7], v120_[8] * overlay.alpha)
				setOverlayCornerColor(v119_, 2, v120_[9], v120_[10], v120_[11], v120_[12] * overlay.alpha)
				setOverlayCornerColor(v119_, 3, v120_[13], v120_[14], v120_[15], v120_[16] * overlay.alpha)
			end
			renderOverlay(v119_, v137_, v140_, v139_, v138_)
			if v151_ ~= nil then
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
	overlay.color = {
		r,
		g,
		b,
		a
	}
end

function GuiOverlay.setSelectedColor(overlay, r, g, b, a)
	overlay.colorSelected = {
		r,
		g,
		b,
		a
	}
end
