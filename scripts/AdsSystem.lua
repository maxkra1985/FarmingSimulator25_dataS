-- Local values: AdsSystem_mt
AdsSystem = {}
local AdsSystem_mt = Class(AdsSystem)
AdsSystem.OCCLUSION_GROUP = {}
AdsSystem.OCCLUSION_GROUP.UI = 0
function AdsSystem.new()
	-- upvalues: (copy) AdsSystem_mt
	local v2_ = AdsSystem_mt
	local v3_ = setmetatable({}, v2_)
	v3_.groups = {}
	local v4_ = 0
	for v5_, v6_ in pairs(AdsSystem.OCCLUSION_GROUP) do
		if v4_ == 32 then
			Logging.warning("AdsSystem: Occclusion group limit (32) reached!")
			break
		end
		v3_.groups[v6_] = {
			["id"] = v6_,
			["name"] = v5_,
			["regions"] = {},
			["isActive"] = false
		}
		v4_ = v4_ + 1
	end
	if g_isDevelopmentVersion then
		addConsoleCommand("gsAdsSystemShowOcclusionRegions", "Renders occlusion areas", "consoleCommandShowOcclusionRegions", v3_)
		addConsoleCommand("gsAdsSystemDecalsToggle", "Toggle ad decals visibility in the map", "consoleCommandToggleDecals", v3_)
	else
		AdsSystem.consoleCommandShowOcclusionRegions = nil
		AdsSystem.consoleCommandToggleDecals = nil
	end
	v3_.renderOcclusionRegions = false
	return v3_
end

function AdsSystem:delete()
	removeConsoleCommand("gsAdsSystemShowOcclusionRegions")
	removeConsoleCommand("gsAdsSystemDecalsToggle")
	self.groups = {}
end

-- Local values: _, group, groupId, k, region, minX, minY, maxX, maxY, offsetX, offsetY
function AdsSystem:drawDebug()
	for _, v9_ in pairs(self.groups) do
		local v10_ = v9_.id
		if adsGetIsOcclusionRegionGroupActive(v10_) then
			for v11_, _ in ipairs(v9_.regions) do
				local v12_, v13_, v14_, v15_ = adsGetOcclusionRegion(v10_, v11_ - 1)
				drawFilledRect(v12_, v13_, v14_ - v12_, v15_ - v13_, 1, 0, 0, 0.3, nil, nil, nil, nil)
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_LEFT)
				local v16_ = 5 * g_pixelSizeX
				local v17_ = 5 * g_pixelSizeY
				local v18_ = renderText
				local v19_ = v12_ + v16_
				local v20_ = v13_ + v17_
				local v21_ = v9_.name
				v18_(v19_, v20_, 0.02, (tostring(v21_)))
			end
		end
	end
end

-- Local values: group
function AdsSystem:clearGroupRegion(groupId)
	local v24_ = self.groups[groupId]
	if v24_ == nil then
		Logging.warning("AdsSystem: GroupId \'%s\' not defined!", (tostring(groupId)))
		return false
	end
	v24_.regions = {}
	adsClearOcclusionRegionGroup(groupId)
	return true
end

-- Local values: group, region
function AdsSystem:addGroupRegion(groupId, x, y, width, height)
	local v31_ = self.groups[groupId]
	if v31_ == nil then
		Logging.warning("AdsSystem: GroupId \'%s\' not defined!", (tostring(groupId)))
		return false
	end
	if #v31_.regions == 4 then
		Logging.warning("AdsSystem: Region limit (4) per group already reached!")
		return false
	end
	local v32_ = v31_.regions
	table.insert(v32_, {
		["x"] = x,
		["y"] = y,
		["width"] = width,
		["height"] = height
	})
	adsAddOcclusionRegion(groupId, x, y, x + width, y + height)
	return true
end

-- Local values: group
function AdsSystem:setGroupActive(groupId, isActive)
	local v36_ = self.groups[groupId]
	if v36_ == nil then
		Logging.warning("AdsSystem: GroupId \'%s\' not defined!", (tostring(groupId)))
		return false
	end
	v36_.isActive = isActive
	adsSetIsOcclusionRegionGroupActive(groupId, isActive)
	return false
end

function AdsSystem:consoleCommandShowOcclusionRegions()
	self.renderOcclusionRegions = not self.renderOcclusionRegions
	if self.renderOcclusionRegions then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
	return string.format("ShowOcclusionRegions=%s", self.renderOcclusionRegions)
end

-- Local values: adDecalMatchString, searchPaths, filenameFormat, decal, clonedDecal
function AdsSystem:consoleCommandToggleDecals()
	self.adDecalsHidden = not self.adDecalsHidden
	self.decals = self.decals or {}
	if self.adDecalsHidden then
		local v_u_39_ = "_(%dx%d)Panel.*Decal"
		local v_u_40_ = { "data/maps/mapEU/textures/shared/billboards", "data/maps/textures/shared/props/billboards" }
		local v_u_41_ = "%{dir}s/ad%{size}s_%{index}02d_diffuse.png"
		I3DUtil.iterateRecursively(getRootNode(), function(p42_)
			-- upvalues: (copy) self, (copy) v_u_40_, (copy) v_u_39_, (copy) v_u_41_
			if getHasClassId(p42_, ClassIds.SHAPE) then
				local v43_ = string.match(getName(p42_), "_(%dx%d)Panel.*Decal")
				if v43_ ~= nil then
					local v44_ = clone(p42_, true, false, false)
					self.decals[p42_] = v44_
					setVisibility(p42_, false)
					local v45_ = getMaterial(v44_, 0)
					for _, v46_ in ipairs(v_u_40_) do
						for v47_ = 1, 4 do
							local v48_ = (p42_ % 4 + v47_) % 4
							local v49_ = string.namedFormat("%{dir}s/ad%{size}s_%{index}02d_diffuse.png", "dir", v46_, "size", v43_, "index", v48_)
							if fileExists(v49_) then
								local v50_ = setMaterialDiffuseMapFromFile(v45_, v49_, false, true, false)
								setMaterial(v44_, v50_, 0)
								return
							end
						end
					end
					Logging.warning("No replacement texture found for ad size %s for node %q", v43_, I3DUtil.getNodePath(p42_))
				end
			end
		end)
	else
		for v51_, v52_ in pairs(self.decals) do
			delete(v52_)
			setVisibility(v51_, true)
		end
		self.decals = nil
	end
	return string.format("adDecalsHidden=%s", self.adDecalsHidden)
end
