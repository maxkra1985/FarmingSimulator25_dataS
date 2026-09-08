DensityMapHeightUtil = {}
DensityMapHeightUtil.lastVehiclesInRange = {}
DensityMapHeightUtil.terrainDetailHeightId = nil
DensityMapHeightUtil.typeFirstChannel = nil
DensityMapHeightUtil.typeNumChannels = nil
DensityMapHeightUtil.heightFirstChannel = nil
DensityMapHeightUtil.heightNumChannels = nil
DensityMapHeightUtil.modifiersCache = nil

function DensityMapHeightUtil.initTerrain(currentMission, detailId, detailHeightId)
	DensityMapHeightUtil.terrainDetailHeightId = detailHeightId
	DensityMapHeightUtil.typeFirstChannel = g_densityMapHeightManager.heightTypeFirstChannel
	DensityMapHeightUtil.typeNumChannels = g_densityMapHeightManager.heightTypeNumChannels
	DensityMapHeightUtil.heightFirstChannel = getDensityMapHeightFirstChannel(detailHeightId)
	DensityMapHeightUtil.heightNumChannels = getDensityMapHeightNumChannels(detailHeightId)
	DensityMapHeightUtil.modifiersCache = {}
end
function DensityMapHeightUtil.clearCache()
	DensityMapHeightUtil.lastVehiclesInRange = {}
	DensityMapHeightUtil.terrainDetailHeightId = nil
	DensityMapHeightUtil.typeFirstChannel = nil
	DensityMapHeightUtil.typeNumChannels = nil
	DensityMapHeightUtil.heightFirstChannel = nil
	DensityMapHeightUtil.heightNumChannels = nil
	DensityMapHeightUtil.modifiersCache = nil
end

-- Local values: heightType
function DensityMapHeightUtil.getCanTipToGround(fillTypeIndex)
	if g_densityMapHeightManager:getIsValid() then
		local v3_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
		if v3_ == nil then
			return false
		else
			return v3_.canBeTipped and true or false
		end
	else
		return false
	end
end

-- Local values: heightTypeIndex, fillTypeIndex
function DensityMapHeightUtil.getFillTypeAtLine(sx, sy, sz, ex, ey, ez, radius)
	if g_densityMapHeightManager:getIsValid() then
		local v11_ = getDensityMapHeightTypeAtWorldLine(g_densityMapHeightManager:getTerrainDetailHeightUpdater(), sx, sy, sz, ex, ey, ez, radius)
		local v12_ = g_densityMapHeightManager:getFillTypeIndexByDensityHeightMapIndex(v11_)
		if v12_ ~= nil then
			return v12_
		end
	end
	return FillType.UNKNOWN
end

-- Local values: modifiers, heightTypes, _, heightType, typeFilter, fillType, modifierType, density, typeFilters, heightType, typeFilter, density2
function DensityMapHeightUtil.getFillTypeAtArea(x0, z0, x1, z1, x2, z2)
	local v19_ = DensityMapHeightUtil.modifiersCache.getFillTypeAtArea
	if v19_ == nil then
		v19_ = {
			["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
			["typeFilters"] = {}
		}
		local v20_ = g_densityMapHeightManager:getDensityMapHeightTypes()
		if v20_ ~= nil then
			for _, v21_ in ipairs(v20_) do
				local v22_ = DensityMapFilter.new(v19_.typeModifier)
				v22_:setValueCompareParams(DensityValueCompareType.EQUAL, v21_.index)
				v19_.typeFilters[v21_] = v22_
			end
		end
		DensityMapHeightUtil.modifiersCache.getFillTypeAtArea = v19_
	end
	if not g_densityMapHeightManager:getIsValid() then
		return FillType.UNKNOWN
	end
	local v23_ = FillType.UNKNOWN
	local v24_ = v19_.typeModifier
	v24_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	if v24_:executeGet() > 0 then
		local v25_ = v19_.typeFilters
		for v26_, v27_ in pairs(v25_) do
			if v24_:executeGet(v27_) > 0 then
				return v26_.fillTypeIndex
			end
		end
	end
	return v23_
end

-- Local values: heightType, modifiers, modifierHeight, heightFilter, typeFilter, density, numPixels, totalNumPixels
function DensityMapHeightUtil.getFillLevelAtArea(fillTypeIndex, x0, z0, x1, z1, x2, z2)
	if not g_densityMapHeightManager:getIsValid() then
		return 0, 0, 0
	end
	local v35_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if v35_ == nil then
		return 0, 0, 0
	end
	local v36_ = DensityMapHeightUtil.modifiersCache.getFillLevelAtArea
	if v36_ == nil then
		v36_ = {
			["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		}
		v36_.heightModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST_EXPAND)
		v36_.heightFilter = DensityMapFilter.new(v36_.heightModifier)
		v36_.heightFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v36_.typeFilters = {}
		DensityMapHeightUtil.modifiersCache.getFillLevelAtArea = v36_
	end
	local v37_ = v36_.heightModifier
	local v38_ = v36_.heightFilter
	local v39_ = v36_.typeFilters[fillTypeIndex]
	if v39_ == nil then
		v39_ = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		v39_:setValueCompareParams(DensityValueCompareType.EQUAL, v35_.index)
		v36_.typeFilters[fillTypeIndex] = v39_
	end
	v37_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	local v40_, v41_, v42_ = v37_:executeGet(v38_, v39_)
	return v40_ * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex), v41_, v42_
end

-- Local values: modifiers, modifier, snowFilter
function DensityMapHeightUtil.getValueAtArea(x0, z0, x1, z1, x2, z2, filterSnow)
	local v50_ = DensityMapHeightUtil.modifiersCache.getValueAtArea
	if v50_ == nil then
		v50_ = {
			["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		}
		DensityMapHeightUtil.modifiersCache.getValueAtArea = v50_
		v50_.snowFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		v50_.snowFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.SNOW))
	end
	local v51_ = v50_.heightModifier
	local v52_
	if filterSnow then
		v52_ = v50_.snowFilter
	else
		v52_ = nil
	end
	v51_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	return v51_:executeGet(v52_)
end

-- Local values: height, delta
function DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)
	local v56_, v57_ = getDensityHeightAtWorldPos(DensityMapHeightUtil.terrainDetailHeightId, x, y, z)
	return v56_, v57_
end

function DensityMapHeightUtil.getCollisionHeightAtWorldPos(x, y, z)
	if g_densityMapHeightManager:getIsValid() then
		return getDensityMapCollisionHeightAtWorldPos(g_densityMapHeightManager:getTerrainDetailHeightUpdater(), x, y, z)
	else
		return 0, 0
	end
end

-- Local values: i, _, vehicle, _, component, cx, cy, cz, distSq
function DensityMapHeightUtil.getVehiclesInRange(refVehicle, x, y, z, radiusSq)
	for v66_ = #DensityMapHeightUtil.lastVehiclesInRange, 1, -1 do
		DensityMapHeightUtil.lastVehiclesInRange[v66_] = nil
	end
	for _, v67_ in pairs(g_currentMission.vehicleSystem.vehicles) do
		if v67_ ~= refVehicle and v67_.components ~= nil then
			for _, v68_ in pairs(v67_.components) do
				local v69_, v70_, v71_ = getWorldTranslation(v68_.node)
				if MathUtil.vector3LengthSq(x - v69_, y - v70_, z - v71_) < radiusSq then
					local v72_ = DensityMapHeightUtil.lastVehiclesInRange
					table.insert(v72_, v67_)
					break
				end
			end
		end
	end
	return DensityMapHeightUtil.lastVehiclesInRange
end

-- Local values: heightType, fixedFillTypeAreas, area, fixedFillTypeArea, validFillType, availableFillType, _, x1, _, z1, x2, _, z2, x3, _, z3, convertingFillTypesAreas, area, convertingArea, x1, _, z1, x2, _, z2, x3, _, z3, fillToGroundScale, terrainUpdater, _, area, xs, ys, zs, xw, yw, zw, xh, yh, zh, allowPropagation, x, y, z, terrainUpdater, lineLength, maxDistSq, x, y, z, vehiclesInRange, _, vehicleInRange, tipOcclusionAreas, _, area, xs, ys, zs, xw, yw, zw, xh, yh, zh, xV, yV, zV, dropped, terrainUpdater, litersToTip
function DensityMapHeightUtil.tipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas, applyChanges)
	if not g_densityMapHeightManager:getIsValid() then
		return 0, 0
	end
	local v89_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if v89_ == nil then
		return 0, 0
	end
	if occlusionAreas == nil and (vehicle ~= nil and vehicle.getTipOcclusionAreas ~= nil) then
		occlusionAreas = vehicle:getTipOcclusionAreas()
	end
	if radius == nil then
		local v90_ = getDensityMapMaxHeight(DensityMapHeightUtil.terrainDetailHeightId)
		local v91_ = v89_.maxSurfaceAngle
		radius = v90_ / math.tan(v91_)
	end
	local v92_ = innerRadius == nil and 0 or innerRadius
	local v93_ = lineOffset == nil and 0 or lineOffset
	if limitToLineHeight == nil then
		limitToLineHeight = false
	end
	local v94_ = applyChanges == nil and true or applyChanges
	if delta < 0 then
		useOcclusionAreas = false
	end
	if delta > 0 then
		local v95_ = g_densityMapHeightManager:getFixedFillTypesAreas()
		if v95_ ~= nil then
			for v96_, v97_ in pairs(v95_) do
				if v96_ ~= nil and v97_ ~= nil then
					local v98_ = false
					for v99_, _ in pairs(v97_.fillTypes) do
						if v99_ == fillTypeIndex then
							v98_ = true
						end
					end
					if v96_ ~= nil and not v98_ then
						local v100_, _, v101_ = getWorldTranslation(v96_.start)
						local v102_, _, v103_ = getWorldTranslation(v96_.width)
						local v104_, _, v105_ = getWorldTranslation(v96_.height)
						if MathUtil.hasRectangleLineIntersection2D(v100_, v101_, v102_ - v100_, v103_ - v101_, v104_ - v100_, v105_ - v101_, sx, sz, ex - sx, ez - sz) then
							return 0, 0
						end
					end
				end
			end
		end
		local v106_ = g_densityMapHeightManager:getConvertingFillTypesAreas()
		if v106_ ~= nil then
			for v107_, v108_ in pairs(v106_) do
				if v107_ ~= nil and v108_ ~= nil then
					local v109_, _, v110_ = getWorldTranslation(v107_.start)
					local v111_, _, v112_ = getWorldTranslation(v107_.width)
					local v113_, _, v114_ = getWorldTranslation(v107_.height)
					if MathUtil.hasRectangleLineIntersection2D(v109_, v110_, v111_ - v109_, v112_ - v110_, v113_ - v109_, v114_ - v110_, sx, sz, ex - sx, ez - sz) then
						if v108_.fillTypes[fillTypeIndex] ~= true then
							return 0, 0
						end
						fillTypeIndex = v108_.fillTypeTarget
						v89_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
						if v89_ == nil then
							return 0, 0
						end
					end
				end
			end
		end
	end
	local v115_ = g_densityMapHeightManager.fillToGroundScale * v89_.fillToGroundScale
	if useOcclusionAreas ~= nil and useOcclusionAreas then
		if occlusionAreas ~= nil then
			local v116_ = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
			if v116_ ~= nil then
				for _, v117_ in pairs(occlusionAreas) do
					local v118_, v119_, v120_ = getWorldTranslation(v117_.start)
					local v121_, v122_, v123_ = getWorldTranslation(v117_.width)
					local v124_, v125_, v126_ = getWorldTranslation(v117_.height)
					local v127_ = v117_.allowPropagation
					if v127_ == nil then
						v127_ = false
					end
					addDensityMapHeightOcclusionArea(v116_, v118_, v119_, v120_, v121_ - v118_, v122_ - v119_, v123_ - v120_, v124_ - v118_, v125_ - v119_, v126_ - v120_, v127_)
					if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
						local v128_ = v121_ + (v124_ - v118_)
						local v129_ = v122_ + (v125_ - v119_)
						local v130_ = v123_ + (v126_ - v120_)
						drawDebugTriangle(v118_, v119_, v120_, v121_, v122_, v123_, v124_, v125_, v126_, 1, 0, 0, 0.5, false)
						drawDebugTriangle(v128_, v129_, v130_, v124_, v125_, v126_, v121_, v122_, v123_, 1, 0, 0, 0.5, false)
						drawDebugTriangle(v124_, v125_, v126_, v121_, v122_, v123_, v118_, v119_, v120_, 1, 0, 0, 0.5, false)
						drawDebugTriangle(v121_, v122_, v123_, v124_, v125_, v126_, v128_, v129_, v130_, 1, 0, 0, 0.5, false)
					end
				end
			end
		end
		local v131_ = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
		if v131_ ~= nil then
			local v132_ = (20 + 0.5 * MathUtil.vector3Length(sx - ex, sy - ey, sz - ez) + radius) ^ 2
			local v133_ = 0.5 * (sx + ex)
			local v134_ = 0.5 * (sy + ey)
			local v135_ = 0.5 * (sz + ez)
			local v136_ = DensityMapHeightUtil.getVehiclesInRange(vehicle, v133_, v134_, v135_, v132_)
			if v136_ ~= nil then
				for _, v137_ in pairs(v136_) do
					if v137_.getTipOcclusionAreas ~= nil then
						local v138_ = v137_:getTipOcclusionAreas()
						for _, v139_ in pairs(v138_) do
							local v140_, v141_, v142_ = getWorldTranslation(v139_.start)
							local v143_, v144_, v145_ = getWorldTranslation(v139_.width)
							local v146_, v147_, v148_ = getWorldTranslation(v139_.height)
							addDensityMapHeightOcclusionArea(v131_, v140_, v141_, v142_, v143_ - v140_, v144_ - v141_, v145_ - v142_, v146_ - v140_, v147_ - v141_, v148_ - v142_, false)
							if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
								local v149_ = v143_ + (v146_ - v140_)
								local v150_ = v144_ + (v147_ - v141_)
								local v151_ = v145_ + (v148_ - v142_)
								drawDebugTriangle(v140_, v141_, v142_, v143_, v144_, v145_, v146_, v147_, v148_, 1, 0, 0, 0.5, false)
								drawDebugTriangle(v149_, v150_, v151_, v146_, v147_, v148_, v143_, v144_, v145_, 1, 0, 0, 0.5, false)
								drawDebugTriangle(v146_, v147_, v148_, v143_, v144_, v145_, v140_, v141_, v142_, 1, 0, 0, 0.5, false)
								drawDebugTriangle(v143_, v144_, v145_, v146_, v147_, v148_, v149_, v150_, v151_, 1, 0, 0, 0.5, false)
							end
						end
					end
				end
			end
		end
	end
	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		drawDebugLine(sx, sy, sz, 0, 1, 1, ex, ey, ez, 0, 1, 1)
		drawDebugLine(sx, sy, sz, 0, 1, 1, sx, sy, sz, 0, 1, 1)
		drawDebugLine(ex, ey, ez, 0, 1, 1, ex, ey, ez, 0, 1, 1)
	end
	local v152_ = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
	local v153_
	if v152_ == nil then
		v153_ = 0
	else
		local v154_ = delta * v115_
		if not v94_ then
			local v155_ = g_densityMapHeightManager
			v154_ = math.max(v154_, v155_:getMinValidLiterValue(fillTypeIndex))
		end
		v153_, v93_ = addDensityMapHeightAtWorldLine(v152_, sx, sy, sz, ex, ey, ez, v154_, v89_.index, v92_, radius, limitToLineHeight, v93_, v94_, g_currentMission.tireTrackSystem.tireTrackSystemId)
		if not v94_ then
			v153_ = math.min(v153_, v154_)
		end
	end
	local v156_ = v153_ / v115_
	if math.abs(delta) - math.abs(v156_) >= 0.001 then
		delta = v156_
	end
	return delta, v93_
end

-- Local values: fillLevel, _
function DensityMapHeightUtil.getCanTipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas)
	local v172_, _ = DensityMapHeightUtil.tipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas, false)
	return v172_ ~= 0
end

-- Local values: heightType, modifiers, typeFilter, heightModifier, typeModifier, density
function DensityMapHeightUtil.removeFromGroundByArea(x0, z0, x1, z1, x2, z2, fillTypeIndex)
	if not g_densityMapHeightManager:getIsValid() then
		return 0
	end
	local v180_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if v180_ == nil then
		return 0
	end
	local v181_ = DensityMapHeightUtil.modifiersCache.removeFromGroundByArea
	if v181_ == nil then
		v181_ = {
			["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
			["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
			["typeFilters"] = {}
		}
		DensityMapHeightUtil.modifiersCache.removeFromGroundByArea = v181_
	end
	local v182_ = v181_.typeFilters[v180_]
	if v182_ == nil then
		v182_ = DensityMapFilter.new(v181_.typeModifier)
		v182_:setValueCompareParams(DensityValueCompareType.EQUAL, v180_.index)
		v181_.typeFilters[v180_] = v182_
	end
	local v183_ = v181_.heightModifier
	local v184_ = v181_.typeModifier
	v183_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	v184_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	v184_:executeSet(0, v182_)
	return v183_:executeSetWithStats(0, v182_) * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
end

-- Local values: heightType, newHeightType, modifiers, typeFilter, typeModifier, density
function DensityMapHeightUtil.changeFillTypeAtArea(x0, z0, x1, z1, x2, z2, fillTypeIndex, newFillTypeIndex)
	if not g_densityMapHeightManager:getIsValid() then
		return 0
	end
	local v193_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	local v194_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(newFillTypeIndex)
	if v193_ == nil or v194_ == nil then
		return 0
	end
	local v195_ = DensityMapHeightUtil.modifiersCache.changeFillTypeAtArea
	if v195_ == nil then
		v195_ = {
			["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
			["typeFilters"] = {}
		}
		DensityMapHeightUtil.modifiersCache.changeFillTypeAtArea = v195_
	end
	local v196_ = v195_.typeFilters[v193_]
	if v196_ == nil then
		v196_ = DensityMapFilter.new(v195_.typeModifier)
		v196_:setValueCompareParams(DensityValueCompareType.EQUAL, v193_.index)
		v195_.typeFilters[v193_] = v196_
	end
	local v197_ = v195_.typeModifier
	v197_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	return v197_:executeSetWithStats(v194_.index, v196_) * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
end

-- Local values: modifiers, heightModifier, typeModifier
function DensityMapHeightUtil.clearArea(x0, z0, x1, z1, x2, z2)
	local v204_ = DensityMapHeightUtil.modifiersCache.clearArea
	if v204_ == nil then
		v204_ = {
			["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
			["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		}
		DensityMapHeightUtil.modifiersCache.clearArea = v204_
	end
	local v205_ = v204_.heightModifier
	local v206_ = v204_.typeModifier
	v205_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	v206_:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	v205_:executeSet(0)
	v206_:executeSet(0)
end

-- Local values: terrainDetailHeightId, heightFirstChannel, heightNumChannels, typeFirstChannel, typeNumChannels, heightModifier, typeModifier
function DensityMapHeightUtil.multiModifierAddClearArea(multiModifier, filter1, filter2)
	local v210_ = DensityMapHeightUtil.terrainDetailHeightId
	local v211_ = DensityMapHeightUtil.heightFirstChannel
	local v212_ = DensityMapHeightUtil.heightNumChannels
	local v213_ = DensityMapHeightUtil.typeFirstChannel
	local v214_ = DensityMapHeightUtil.typeNumChannels
	local v215_ = DensityMapModifier.new(v210_, v211_, v212_)
	local v216_ = DensityMapModifier.new(v210_, v213_, v214_)
	multiModifier:addExecuteSet(0, v215_, filter1, filter2)
	multiModifier:addExecuteSet(0, v216_, filter1, filter2)
end

-- Local values: modifiers, heightModifier, typeModifier
function DensityMapHeightUtil.clear(area)
	local v218_ = DensityMapHeightUtil.modifiersCache.clearArea
	if v218_ == nil then
		v218_ = {
			["heightModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
			["typeModifier"] = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		}
		DensityMapHeightUtil.modifiersCache.clearArea = v218_
	end
	local v219_ = v218_.heightModifier
	local v220_ = v218_.typeModifier
	area:applyToModifier(v219_)
	area:applyToModifier(v220_)
	v219_:executeSet(0)
	v220_:executeSet(0)
	v219_:clearPolygonPoints()
	v220_:clearPolygonPoints()
end

-- Local values: heightType
function DensityMapHeightUtil.getDefaultMaxRadius(fillTypeIndex)
	local v222_ = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if v222_ == nil then
		return 0
	end
	local v223_ = getDensityMapMaxHeight(DensityMapHeightUtil.terrainDetailHeightId)
	local v224_ = v222_.maxSurfaceAngle
	return v223_ / math.tan(v224_)
end

function DensityMapHeightUtil.getRoundedHeightValue(height)
	if not g_densityMapHeightManager:getIsValid() then
		return height
	end
	local v226_ = height * g_densityMapHeightManager.heightToDensityValue
	return math.floor(v226_) / g_densityMapHeightManager.heightToDensityValue
end

-- Local values: terrainUpdater, heightTypeIndex
function DensityMapHeightUtil.getHeightTypeDescAtWorldPos(x, y, z, radius)
	local v231_ = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
	local v232_ = getDensityMapHeightTypeAtWorldPos(v231_, x, y, z, radius)
	if v232_ == nil then
		return nil
	else
		return g_densityMapHeightManager:getDensityMapHeightTypeByIndex(v232_)
	end
end

-- Local values: swDirX, swDirY, swDirZ, shDirX, shDirY, shDirZ, swLength, shLength, lsx, lsy, lsz, lex, ley, lez, radius, shrink, shrink
function DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz, radiusOverlap)
	local v243_ = wx - sx
	local v244_ = wy - sy
	local v245_ = wz - sz
	local v246_ = hx - sx
	local v247_ = hy - sy
	local v248_ = hz - sz
	local v249_ = MathUtil.vector3Length(v243_, v244_, v245_)
	local v250_ = MathUtil.vector3Length(v246_, v247_, v248_)
	local v251_ = v246_ / v250_
	local v252_ = v247_ / v250_
	local v253_ = v248_ / v250_
	local v254_ = v243_ / v249_
	local v255_ = v244_ / v249_
	local v256_ = v245_ / v249_
	if v250_ < v249_ then
		local v257_ = v250_ * 0.5
		local v258_ = radiusOverlap ~= nil and radiusOverlap and 0 or v257_
		return sx + v251_ * v250_ * 0.5 + v254_ * v258_, sy + v252_ * v250_ * 0.5 + v255_ * v258_, sz + v253_ * v250_ * 0.5 + v256_ * v258_, wx + v251_ * v250_ * 0.5 - v254_ * v258_, wy + v252_ * v250_ * 0.5 - v255_ * v258_, wz + v253_ * v250_ * 0.5 - v256_ * v258_, v257_
	else
		local v259_ = v249_ * 0.5
		local v260_ = radiusOverlap ~= nil and radiusOverlap and 0 or v259_
		return sx + v254_ * v249_ * 0.5 + v251_ * v260_, sy + v255_ * v249_ * 0.5 + v252_ * v260_, sz + v256_ * v249_ * 0.5 + v253_ * v260_, hx + v254_ * v249_ * 0.5 - v251_ * v260_, hy + v255_ * v249_ * 0.5 - v252_ * v260_, hz + v256_ * v249_ * 0.5 - v253_ * v260_, v259_
	end
end

-- Local values: sx, sy, sz, wx, wy, wz, hx, hy, hz
function DensityMapHeightUtil.getLineByArea(start, width, height, radiusOverlap)
	local v265_, v266_, v267_ = getWorldTranslation(start)
	local v268_, v269_, v270_ = getWorldTranslation(width)
	local v271_, v272_, v273_ = getWorldTranslation(height)
	return DensityMapHeightUtil.getLineByAreaDimensions(v265_, v266_, v267_, v268_, v269_, v270_, v271_, v272_, v273_, radiusOverlap)
end

-- Local values: sx, sy, sz, wx, wy, wz, hx, hy, hz, areas, MAX_AREA_SIZE, distance, dirX, dirY, dirZ, areaSize, numSubareas, i, subStart, subWidth, subHeight
function DensityMapHeightUtil.getAreaPartitions(start, width, height)
	local v277_, v278_, v279_ = getWorldTranslation(start)
	local v280_, v281_, v282_ = getWorldTranslation(width)
	local v283_, v284_, v285_ = getWorldTranslation(height)
	local v286_ = {}
	local v287_ = MathUtil.vector3Length(v283_ - v277_, v284_ - v278_, v285_ - v279_)
	local v288_, v289_, v290_ = MathUtil.vector3Normalize(v283_ - v277_, v284_ - v278_, v285_ - v279_)
	if v287_ <= 4 then
		table.insert(v286_, {
			["start"] = start,
			["width"] = width,
			["height"] = height
		})
		return v286_
	end
	local v291_ = v287_ / 4
	local v292_ = math.ceil(v291_)
	local v293_ = v287_ / v292_
	for v294_ = 1, v292_ do
		local v295_ = createTransformGroup("start" .. v294_)
		local v296_ = createTransformGroup("width" .. v294_)
		local v297_ = createTransformGroup("height" .. v294_)
		link(start, v295_)
		link(width, v296_)
		link(height, v297_)
		setWorldTranslation(v295_, v277_ + v288_ * v293_ * (v294_ - 1), v278_ + v289_ * v293_ * (v294_ - 1), v279_ + v290_ * v293_ * (v294_ - 1))
		setWorldTranslation(v296_, v280_ + v288_ * v293_ * (v294_ - 1), v281_ + v289_ * v293_ * (v294_ - 1), v282_ + v290_ * v293_ * (v294_ - 1))
		setWorldTranslation(v297_, v277_ + v288_ * v293_ * v294_, v278_ + v289_ * v293_ * v294_, v279_ + v290_ * v293_ * v294_)
		table.insert(v286_, {
			["start"] = v295_,
			["width"] = v296_,
			["height"] = v297_
		})
	end
	return v286_
end

-- Local values: steps, realRadius, heightType, r, step, x, y, z, smoothGroundRadius, terrainHeightUpdater, densityHeight, disp_x, disp_z, widthX, widthZ, heightX, heightZ
function DensityMapHeightUtil.smoothAroundLine(node, width, radius, overlap, smoothAmount, resetDisplacement)
	local v304_ = width / (radius * 2 / overlap)
	local v305_ = math.ceil(v304_)
	local v306_ = width / v305_ * 0.5
	local v307_ = nil
	for v308_ = 1, v305_ do
		local v309_, v310_, v311_ = localToWorld(node, -(width * 0.5) + v306_ * 2 * (v308_ - 0.5), 0, 0)
		local v312_ = v306_ * overlap
		v307_ = v307_ or DensityMapHeightUtil.getHeightTypeDescAtWorldPos(v309_, v310_, v311_, v312_)
		if v307_ ~= nil and v307_.allowsSmoothing then
			local v313_ = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
			if v313_ ~= nil then
				local v314_ = DensityMapHeightUtil.getHeightAtWorldPos(v309_, v310_, v311_)
				if v310_ < v314_ then
					smoothDensityMapHeightAtWorldPos(v313_, v309_, v314_ - v307_.collisionBaseOffset, v311_, smoothAmount, v307_.index, 0, v312_, v312_ + 1.2, g_currentMission.tireTrackSystem.tireTrackSystemId)
					if resetDisplacement then
						FSDensityMapUtil.resetDisplacementArea(v309_ - radius * 0.5, v311_ - radius * 0.5, v309_ - radius * 0.5, v311_ + radius * 0.5, v309_ + radius * 0.5, v311_ - radius * 0.5)
					end
					if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
						DebugGizmo.renderAtPosition(v309_, v310_, v311_, 0, 0, 1, 0, 1, 0, "smooth DM", false)
						DebugUtil.drawDebugCircle(v309_, v314_ - v307_.collisionBaseOffset, v311_, v312_, 10)
						if resetDisplacement then
							local v315_, v316_, v317_, v318_, v319_, v320_ = MathUtil.getXZWidthAndHeight(v309_ - radius * 0.5, v311_ - radius * 0.5, v309_ - radius * 0.5, v311_ + radius * 0.5, v309_ + radius * 0.5, v311_ - radius * 0.5)
							DebugUtil.drawDebugParallelogram(v315_, v316_, v317_, v318_, v319_, v320_, 0.1, 1, 0, 0, 1)
						end
					end
				end
			end
		end
	end
end
