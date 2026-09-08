PlaceableVine = {}

function PlaceableVine.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableFence, specializations)
end

function PlaceableVine.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateVineNode", PlaceableVine.updateVineNode)
	SpecializationUtil.registerFunction(placeableType, "updateVineVisuals", PlaceableVine.updateVineVisuals)
	SpecializationUtil.registerFunction(placeableType, "destroyVineArea", PlaceableVine.destroyVineArea)
	SpecializationUtil.registerFunction(placeableType, "getVineFruitTypeIndex", PlaceableVine.getVineFruitTypeIndex)
	SpecializationUtil.registerFunction(placeableType, "setShakingFactor", PlaceableVine.setShakingFactor)
	SpecializationUtil.registerFunction(placeableType, "harvestVine", PlaceableVine.harvestVine)
	SpecializationUtil.registerFunction(placeableType, "prepareVine", PlaceableVine.prepareVine)
	SpecializationUtil.registerFunction(placeableType, "getVineFruitType", PlaceableVine.getVineFruitType)
	SpecializationUtil.registerFunction(placeableType, "getHasSegmentTargetGrowthState", PlaceableVine.getHasSegmentTargetGrowthState)
	SpecializationUtil.registerFunction(placeableType, "getSegmentSideArea", PlaceableVine.getSegmentSideArea)
	SpecializationUtil.registerFunction(placeableType, "getSectionFactor", PlaceableVine.getSectionFactor)
	SpecializationUtil.registerFunction(placeableType, "getVineAreaByNode", PlaceableVine.getVineAreaByNode)
end

function PlaceableVine.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "doDeletePanel", PlaceableVine.doDeletePanel)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "generateSegmentPoles", PlaceableVine.generateSegmentPoles)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "deleteSegment", PlaceableVine.deleteSegment)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableVine.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getHasParallelSnapping", PlaceableVine.getHasParallelSnapping)
end

function PlaceableVine.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableVine)
	SpecializationUtil.registerEventListener(placeableType, "onCreateSegmentPanel", PlaceableVine)
end

function PlaceableVine.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Vine")
	schema:register(XMLValueType.STRING, basePath .. ".vine#fruitType", "Vine fruit type")
	schema:register(XMLValueType.FLOAT, basePath .. ".vine#width", "Vine width")
	schema:register(XMLValueType.FLOAT, basePath .. ".vine#length", "Vine length")
	schema:register(XMLValueType.FLOAT, basePath .. ".vine#thresholdFactor", "Section work threshold factor")
	schema:register(XMLValueType.INT, basePath .. ".vine#numLODOffsets", "Vine num lod offsets")
	schema:register(XMLValueType.INT, basePath .. ".vine#numSections", "Vine num sub sections")
	schema:register(XMLValueType.INT, basePath .. ".vine.growthStates#previewNodeIndex", "Node index of preview node")
	schema:register(XMLValueType.STRING, basePath .. ".vine.growthStates.growthState(?)#nodeIndex", "Growthstate node index. Relative to panel rootnode")
	schema:register(XMLValueType.INT, basePath .. ".vine.growthStates.growthState(?).foliage(?)#state", "Growthstate")
	schema:register(XMLValueType.INT, basePath .. ".vine.growthStates.growthState(?).foliage(?)#sectionState", "SectionState")
	schema:register(XMLValueType.INT, basePath .. ".vine.resetStates.resetState(?)#state", "Reset state")
	schema:register(XMLValueType.INT, basePath .. ".vine.resetStates.resetState(?)#targetState", "Reset target state")
	schema:register(XMLValueType.FLOAT, basePath .. ".vine.resetStates.resetState(?)#threshold", "Threshold to apply reset")
	schema:setXMLSpecializationType()
end

function PlaceableVine.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Vine")
	schema:register(XMLValueType.INT, basePath .. "#startGrowthState", "Vineyard start growth state")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, fruitTypeName, fruitType
function PlaceableVine:onLoad(savegame)
	local v_u_11_ = self.spec_vine
	local v_u_12_ = self.xmlFile
	local v13_ = v_u_12_:getValue("placeable.vine#fruitType")
	if v13_ == nil then
		Logging.xmlWarning(v_u_12_, "Missing fruit type name")
		return
	else
		local v_u_14_ = g_fruitTypeManager:getFruitTypeByName(v13_)
		if v_u_14_ == nil then
			Logging.xmlWarning(v_u_12_, "Fruit type \'%s\' not defined", v13_)
		else
			v_u_11_.fruitType = v_u_14_
			v_u_11_.length = v_u_12_:getValue("placeable.vine#length", 1)
			v_u_11_.width = v_u_12_:getValue("placeable.vine#width", 1)
			v_u_11_.thresholdFactor = v_u_12_:getValue("placeable.vine#thresholdFactor", 0.5)
			v_u_11_.numLODOffsets = v_u_12_:getValue("placeable.vine#numLODOffsets", 0)
			local v15_ = v_u_12_:getValue("placeable.vine#numSections", 1)
			v_u_11_.numSections = math.max(v15_, 1)
			v_u_11_.sectionLength = v_u_11_.length / v_u_11_.numSections
			v_u_11_.vineSegments = {}
			v_u_11_.nodes = {}
			v_u_11_.growthStates = {}
			v_u_12_:iterate("placeable.vine.growthStates.growthState", function(_, p16_)
				-- upvalues: (copy) v_u_12_, (copy) v_u_14_, (copy) v_u_11_
				local v17_ = v_u_12_:getValue(p16_ .. "#nodeIndex")
				if v17_ == nil then
					Logging.xmlWarning(v_u_12_, "Missing growth state nodeIndex for \'%s\'", p16_)
					return
				else
					local v_u_18_ = {}
					v_u_12_:iterate(p16_ .. ".foliage", function(_, p19_)
						-- upvalues: (ref) v_u_12_, (ref) v_u_14_, (copy) v_u_18_
						local v20_ = v_u_12_:getValue(p19_ .. "#state")
						if v20_ == nil then
							Logging.xmlWarning(v_u_12_, "Missing foliage state for \'%s\'", p19_)
							return
						elseif v20_ < 0 or v_u_14_.numStateChannels ^ 2 - 1 < v20_ then
							Logging.xmlWarning(v_u_12_, "Invalid foliage state for \'%s\'", p19_)
							return
						else
							local v21_ = v_u_12_:getValue(p19_ .. "#sectionState")
							if v21_ == nil then
								Logging.xmlWarning(v_u_12_, "Missing foliage sectionState for \'%s\'", p19_)
							else
								local v22_ = v_u_18_
								table.insert(v22_, {
									["state"] = v20_,
									["sectionState"] = v21_
								})
							end
						end
					end)
					if #v_u_18_ == 0 then
						Logging.xmlWarning(v_u_12_, "Missing foliage states for growthstate \'%s\'", p16_)
					else
						v_u_11_.growthStates[v17_] = v_u_18_
					end
				end
			end)
			v_u_11_.previewNodeIndex = v_u_12_:getValue("placeable.vine.growthStates#previewNodeIndex", 0)
			v_u_11_.resetStates = {}
			v_u_12_:iterate("placeable.vine.resetStates.resetState", function(_, p23_)
				-- upvalues: (copy) v_u_12_, (copy) v_u_11_
				local v24_ = v_u_12_:getValue(p23_ .. "#state")
				if v24_ == nil then
					Logging.xmlWarning(v_u_12_, "Missing reset state for \'%s\'", p23_)
					return
				else
					local v25_ = v_u_12_:getValue(p23_ .. "#targetState")
					if v25_ == nil then
						Logging.xmlWarning(v_u_12_, "Missing reset target state for \'%s\'", p23_)
						return
					else
						local v26_ = v_u_12_:getValue(p23_ .. "#threshold")
						if v26_ == nil then
							Logging.xmlWarning(v_u_12_, "Missing reset state threshold for \'%s\'", p23_)
						else
							local v27_ = {
								["state"] = v24_,
								["targetState"] = v25_,
								["values"] = {}
							}
							v27_.values[v24_] = 0
							v27_.threshold = v26_
							local v28_ = v_u_11_.resetStates
							table.insert(v28_, v27_)
						end
					end
				end
			end)
			v_u_11_.startGrowthState = nil
			if savegame ~= nil then
				v_u_11_.startGrowthState = savegame.xmlFile:getValue(savegame.key .. ".vine#startGrowthState")
			end
		end
	end
end

-- Local values: spec, data
function PlaceableVine:deleteSegment(superFunc, segment)
	local v32_ = self.spec_vine
	if v32_.vineSegments[segment] ~= nil then
		v32_.vineSegments[segment] = nil
	end
	superFunc(self, segment)
end

-- Local values: previewSegment, isPreviewSegment, spec, segmentData, _, data
function PlaceableVine:generateSegmentPoles(superFunc, segment, sync)
	if segment ~= self:getPreviewSegment() then
		local v37_ = self.spec_vine
		local v38_ = v37_.vineSegments[segment]
		if v38_ ~= nil then
			for _, v39_ in ipairs(v38_) do
				g_currentMission.vineSystem:removeElement(self, v39_.node, v37_.width, v37_.length)
				v37_.nodes[v39_.node] = nil
			end
		end
		v37_.vineSegments[segment] = {}
	end
	superFunc(self, segment, sync)
end

-- Local values: spec, disableShadows, node, data, x, _, z, dirX, _, dirZ, normX, _, normZ, sizeHalfX, nodeIndex, foliageStates, stateNode, i, lodNode, j, lodChildNode, lodX, lodY, lodZ, distanceFactor, uvOffset, maxState, maxPixels, sectionLength, i, startX, startZ, widthX, widthZ, heightX, heightZ, stateNode, growthStateData, _, foliageData, state, value, i, section, states, i
function PlaceableVine:onCreateSegmentPanel(isPreview, segment, panel, poleIndex, dy, pole)
	local v47_ = self.spec_vine
	if not getAllowFoliageShadows() then
		local function v49_(p48_)
			if getHasClassId(p48_, ClassIds.SHAPE) then
				setShapeCastShadowmap(p48_, false)
			end
		end
		I3DUtil.iterateRecursively(panel, v49_)
		if pole ~= nil then
			I3DUtil.iterateRecursively(pole, v49_)
		end
	end
	if isPreview then
		local v50_ = getChildAt(panel, 1)
		for v51_ = 0, getNumOfChildren(v50_) - 1 do
			setVisibility(getChildAt(v50_, v51_), v51_ == v47_.previewNodeIndex)
		end
	else
		local v52_ = getChildAt(panel, 0)
		local v53_ = {
			["node"] = v52_,
			["poleIndex"] = poleIndex
		}
		v47_.nodes[v52_] = v53_
		local v54_ = v47_.vineSegments[segment]
		table.insert(v54_, v53_)
		local v55_, _, v56_ = getWorldTranslation(panel)
		local v57_, _, v58_ = localDirectionToWorld(panel, 0, 0, 1)
		local v59_, v60_ = MathUtil.vector2Normalize(v57_, v58_)
		local v61_, _, v62_ = MathUtil.crossProduct(v59_, 0, v60_, 0, 1, 0)
		local v63_, v64_ = MathUtil.vector2Normalize(v61_, v62_)
		local v65_ = v47_.width * 0.5
		v53_.growthStates = {}
		for v66_, v67_ in pairs(v47_.growthStates) do
			local v68_ = I3DUtil.indexToObject(panel, v66_)
			if v68_ == nil then
				Logging.warning("Failed to get vine panel growth state node (\'%s\')", v66_)
				return
			end
			v53_.growthStates[v68_] = {
				["foliageStates"] = v67_,
				["value"] = 0,
				["sectionStates"] = {}
			}
			setVisibility(v68_, false)
			for v69_ = 0, getNumOfChildren(v68_) - 1 do
				local v70_ = getChildAt(v68_, v69_)
				if getNumOfChildren(v70_) > 1 then
					for v71_ = 0, getNumOfChildren(v70_) - 1 do
						local v72_ = getChildAt(v70_, v71_)
						local v73_, v74_, v75_ = getTranslation(v72_)
						local v76_ = v74_ + v75_ / v47_.length * -dy
						setTranslation(v72_, v73_, v76_, v75_)
						if v47_.numLODOffsets > 0 and getHasShaderParameter(v72_, "uvOffset") then
							local v77_ = math.random(0, v47_.numLODOffsets - 1) * (1 / v47_.numLODOffsets)
							setShaderParameter(v72_, "uvOffset", v77_, 0, 0, 0, false)
						end
					end
				end
			end
		end
		v53_.sections = {}
		v53_.growthValues = {}
		local v78_ = v47_.sectionLength
		local v79_ = 0
		local v80_ = 1
		for v81_ = 1, v47_.numSections do
			local v82_ = v55_ + v59_ * v78_ * (v81_ - 1) + v63_ * -v65_
			local v83_ = v56_ + v60_ * v78_ * (v81_ - 1) + v64_ * -v65_
			local v84_ = v82_ + v63_ * v47_.width
			local v85_ = v83_ + v64_ * v47_.width
			local v86_ = v82_ + v59_ * v78_
			local v87_ = v83_ + v60_ * v78_
			v53_.sections[v81_] = {
				v82_,
				v83_,
				v84_,
				v85_,
				v86_,
				v87_
			}
			v53_.growthValues[v81_] = {
				["totalArea"] = 0,
				["values"] = {}
			}
			for _, v88_ in pairs(v53_.growthStates) do
				for _, v89_ in ipairs(v88_.foliageStates) do
					v53_.growthValues[v81_].values[v89_.state] = 0
				end
			end
			v53_.growthValues[v81_].totalArea = FSDensityMapUtil.updateVineAreaValues(v47_.fruitType.index, v82_, v83_, v84_, v85_, v86_, v87_, v53_.growthValues[v81_].values)
			for v90_, v91_ in pairs(v53_.growthValues[v81_].values) do
				if v79_ < v91_ then
					v80_ = v90_
					v79_ = v91_
				end
			end
		end
		if not self.isLoadingFromSavegameXML or v47_.startGrowthState ~= nil then
			if v47_.startGrowthState ~= nil then
				v80_ = v47_.startGrowthState
			end
			for v92_ = 1, v47_.numSections do
				local v93_ = v53_.sections[v92_]
				FSDensityMapUtil.createVineArea(v47_.fruitType.index, v93_[1], v93_[2], v93_[3], v93_[4], v93_[5], v93_[6], v80_)
			end
		end
		g_currentMission.vineSystem:addElement(self, v52_, v47_.width, v47_.length)
		self:updateVineNode(v52_, false)
	end
end

-- Local values: previewSegment, isPreviewSegment, spec, segmentData, k, data
function PlaceableVine:doDeletePanel(superFunc, segment, segmentIndex, poleIndex)
	if segment == nil or #segment.poles < poleIndex then
		return
	end
	if segment ~= self:getPreviewSegment() then
		local v99_ = self.spec_vine
		local v100_ = v99_.vineSegments[segment]
		if v100_ ~= nil then
			for v101_, v102_ in ipairs(v100_) do
				if v102_.poleIndex == poleIndex then
					v99_.nodes[v102_.node] = nil
					table.remove(v100_, v101_)
					g_currentMission.vineSystem:removeElement(self, v102_.node, v99_.width, v99_.length)
					self:destroyVineArea(v102_)
					break
				end
			end
		end
	end
	superFunc(self, segment, segmentIndex, poleIndex)
end

-- Local values: fruitDesc, isPlantingSeason
function PlaceableVine:getCanBePlacedAt(superFunc, x, y, z, farmId)
	if g_fruitTypeManager:getFruitTypeByIndex(self:getVineFruitTypeIndex()):getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod) then
		return superFunc(self, x, y, z)
	else
		return false, string.format(g_i18n:getText("warning_theSelectedFruitTypeCantBePlantedInThisPeriod"), g_i18n:formatPeriod())
	end
end

function PlaceableVine:getHasParallelSnapping(superFunc)
	return true
end

-- Local values: spec, i, section
function PlaceableVine:destroyVineArea(data)
	local v110_ = self.spec_vine
	if self.isServer then
		for v111_ = 1, v110_.numSections do
			local v112_ = data.sections[v111_]
			FSDensityMapUtil.destroyVineArea(v110_.fruitType.index, v112_[1], v112_[2], v112_[3], v112_[4], v112_[5], v112_[6])
		end
	end
end

function PlaceableVine:getVineFruitTypeIndex()
	return self.spec_vine.fruitType.index
end

-- Local values: spec, data, startX, startZ, widthX, widthZ, heightX, heightZ, _, resetState, totalArea, factor, i, section, stateNode, growthStateData, _, foliageData
function PlaceableVine:updateVineNode(node, isGrowing)
	local v117_ = self.spec_vine
	local v118_ = v117_.nodes[node]
	if v118_ == nil then
		return
	end
	if not entityExists(node) then
		return
	end
	if isGrowing then
		local v119_, v120_, v121_, v122_, v123_, v124_ = self:getVineAreaByNode(node)
		for _, v125_ in ipairs(v117_.resetStates) do
			local v126_ = FSDensityMapUtil.updateVineAreaValues(v117_.fruitType.index, v119_, v120_, v121_, v122_, v123_, v124_, v125_.values)
			local v127_ = v126_ <= 0 and 0 or v125_.values[v125_.state] / v126_
			if self.isServer and (v127_ < 1 and v125_.threshold < v127_) then
				FSDensityMapUtil.resetVineArea(v117_.fruitType.index, v119_, v120_, v121_, v122_, v123_, v124_, v125_.targetState)
				break
			end
		end
	end
	v118_.totalArea = 0
	if v118_.growthValues == nil then
		v118_.growthValues = {}
	end
	for v128_ = 1, v117_.numSections do
		local v129_ = v118_.sections[v128_]
		if v118_.growthValues[v128_] == nil then
			v118_.growthValues[v128_] = {
				["totalArea"] = 0,
				["values"] = {}
			}
			for _, v130_ in pairs(v118_.growthStates) do
				for _, v131_ in ipairs(v130_.foliageStates) do
					v118_.growthValues[v128_].values[v131_.state] = 0
				end
			end
		end
		v118_.growthValues[v128_].totalArea = FSDensityMapUtil.updateVineAreaValues(v117_.fruitType.index, v129_[1], v129_[2], v129_[3], v129_[4], v129_[5], v129_[6], v118_.growthValues[v128_].values)
	end
	self:updateVineVisuals(v118_)
end

-- Local values: spec, maxValue, growthStateNode, stateNode, growthStateData, i, maxSectionValue, _, foliageState, value, sectionStates
function PlaceableVine:updateVineVisuals(data)
	local v134_ = self.spec_vine
	local v135_ = 0
	local v136_ = nil
	for v137_, v138_ in pairs(data.growthStates) do
		setVisibility(v137_, false)
		v138_.value = 0
		for v139_ = 1, v134_.numSections do
			v138_.sectionStates[v139_] = 1
			local v140_ = 0
			for _, v141_ in ipairs(v138_.foliageStates) do
				local v142_ = data.growthValues[v139_].values[v141_.state]
				v138_.value = v138_.value + v142_
				if v140_ <= v142_ then
					v138_.sectionStates[v139_] = v141_.sectionState
					v140_ = v142_
				end
			end
		end
		if v135_ < v138_.value then
			if v136_ ~= nil then
				setVisibility(v136_, false)
			end
			v135_ = v138_.value
			setVisibility(v137_, true)
			local v143_ = v138_.sectionStates
			I3DUtil.setShaderParameterRec(v137_, "hideSectionStates", v143_[1], v143_[2], v143_[3], v134_.sectionLength)
			v136_ = v137_
		end
	end
end

-- Local values: spec, data, needsUpdate, i, factor, section, area, totalArea, weedFactor, sprayFactor, plowFactor
function PlaceableVine:harvestVine(node, startX, startY, startZ, currentX, currentY, currentZ, callback, target)
	if self.isServer then
		local v154_ = self.spec_vine
		local v155_ = v154_.nodes[node]
		if v155_ ~= nil then
			local v156_ = false
			for v157_ = 1, v154_.numSections do
				if self:getSectionFactor(node, v157_, startX, startY, startZ, currentX, currentY, currentZ) > v154_.thresholdFactor then
					local v158_ = v155_.sections[v157_]
					local v159_, v160_, v161_, v162_, v163_ = FSDensityMapUtil.updateVineCutArea(v154_.fruitType.index, v158_[1], v158_[2], v158_[3], v158_[4], v158_[5], v158_[6])
					if v159_ > 0 then
						callback(target, self, v159_, v160_, v161_, v162_, v163_, v154_.sectionLength)
						v156_ = true
					end
				end
			end
			if v156_ then
				self:updateVineNode(node, false)
			end
		end
	else
		return
	end
end

-- Local values: spec, data, stateNode, _
function PlaceableVine:setShakingFactor(node, worldX, worldY, worldZ, intensity)
	local v170_ = self.spec_vine.nodes[node]
	if v170_ ~= nil then
		for v171_, _ in pairs(v170_.growthStates) do
			I3DUtil.setShaderParameterRec(v171_, "harvestPosition", worldX, worldY, worldZ, intensity)
		end
	end
end

-- Local values: spec, data, area, i, factor, section, currentArea, _
function PlaceableVine:prepareVine(node, startX, startY, startZ, currentX, currentY, currentZ)
	if not self.isServer then
		return 0
	end
	local v180_ = self.spec_vine
	local v181_ = v180_.nodes[node]
	if v181_ == nil then
		return 0
	end
	local v182_ = 0
	for v183_ = 1, v180_.numSections do
		if self:getSectionFactor(node, v183_, startX, startY, startZ, currentX, currentY, currentZ) > v180_.thresholdFactor then
			local v184_ = v181_.sections[v183_]
			local v185_, _ = FSDensityMapUtil.updateVinePrepareArea(v180_.fruitType.index, v184_[1], v184_[2], v184_[3], v184_[4], v184_[5], v184_[6])
			v182_ = v182_ + v185_
		end
	end
	if v182_ > 0 then
		self:updateVineNode(node, false)
	end
	return v182_
end

-- Local values: spec, factor, sectionStart, sectionEnd, _, _, localStartZ, _, _, localCurrentZ, checkStart, checkEnd, checkDistance
function PlaceableVine:getSectionFactor(node, i, startX, startY, startZ, currentX, currentY, currentZ)
	local v195_ = self.spec_vine
	local v196_ = 0
	local v197_ = v195_.sectionLength * (i - 1)
	local v198_ = v195_.sectionLength * i
	local _, _, v199_ = worldToLocal(node, startX, startY, startZ)
	local _, _, v200_ = worldToLocal(node, currentX, currentY, currentZ)
	if v200_ < v199_ then
		local v201_ = v200_
		v200_ = v199_
		v199_ = v201_
	end
	if v199_ < v198_ and v197_ < v200_ then
		local v202_ = math.max(v199_, v197_) - math.min(v200_, v198_)
		v196_ = math.abs(v202_) / v195_.sectionLength
	end
	return v196_
end

-- Local values: spec, x, _, z, dirX, _, dirZ, normX, _, normZ, sizeHalfX, startX, startZ, widthX, widthZ, heightX, heightZ
function PlaceableVine:getVineAreaByNode(node)
	local v205_ = self.spec_vine
	local v206_, _, v207_ = getWorldTranslation(node)
	local v208_, _, v209_ = localDirectionToWorld(node, 0, 0, 1)
	local v210_, _, v211_ = MathUtil.crossProduct(v208_, 0, v209_, 0, 1, 0)
	local v212_ = v205_.width * 0.5
	local v213_ = v206_ + v210_ * -v212_
	local v214_ = v207_ + v211_ * -v212_
	return v213_, v214_, v213_ + v210_ * v205_.width, v214_ + v211_ * v205_.width, v213_ + v208_ * v205_.length, v214_ + v209_ * v205_.length
end

function PlaceableVine:getVineFruitType()
	return self.spec_vine.fruitType.index
end

-- Local values: spec, minState, maxState, fruitTypeDesc, data, i, growthValues, j, targetState, area
function PlaceableVine:getHasSegmentTargetGrowthState(segment, fruitTypeIndex, useHarvestStates, usePrepareStates)
	local v221_ = self.spec_vine
	if fruitTypeIndex ~= self.spec_vine.fruitType.index then
		return false
	end
	local v222_ = g_fruitTypeManager:getFruitTypeByIndex(self.spec_vine.fruitType.index)
	local v223_, v224_
	if usePrepareStates then
		v223_ = v222_.witheredState
		v224_ = v222_.witheredState
	else
		if not useHarvestStates then
			return false
		end
		v223_ = v222_.minHarvestingGrowthState
		v224_ = v222_.maxHarvestingGrowthState
	end
	if v223_ == nil or v224_ == nil then
		return false
	end
	local v225_ = v221_.vineSegments[segment]
	if v225_ ~= nil then
		for v226_ = 1, #v225_ do
			local v227_ = v225_[v226_].growthValues
			for v228_ = 1, #v227_ do
				for v229_ = v223_, v224_ do
					if v227_[v228_].values[v229_] > 0 then
						return true
					end
				end
			end
		end
	end
	return false
end

-- Local values: snapDistance, dirX, dirZ, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ
function PlaceableVine:getSegmentSideArea(segment, segmentSide)
	local v233_ = self:getSnapDistance()
	local v234_ = segmentSide or 1
	local v235_, v236_ = MathUtil.vector2Normalize(segment.x2 - segment.x1, segment.z2 - segment.z1)
	return segment.x1 + v236_ * v234_ * v233_ * 0.5, segment.z1 - v235_ * v234_ * v233_ * 0.5, segment.x1 + v236_ * v234_ * v233_ * 0.4, segment.z1 - v235_ * v234_ * v233_ * 0.4, segment.x2 + v236_ * v234_ * v233_ * 0.5, segment.z2 - v235_ * v234_ * v233_ * 0.5
end
