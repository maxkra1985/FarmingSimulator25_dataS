-- Local values: ExtendedWeedControl_mt
ExtendedWeedControl = {}
ExtendedWeedControl.MOD_NAME = g_currentModName
ExtendedWeedControl.BASE_DIRECTORY = g_currentModDirectory
local ExtendedWeedControl_mt = Class(ExtendedWeedControl)

-- Upvalues: ExtendedWeedControl_mt
-- Local values: self
function ExtendedWeedControl.new(precisionFarming, customMt)
	-- upvalues: (copy) ExtendedWeedControl_mt
	local v4_ = customMt or ExtendedWeedControl_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.lastUseSpotSpraying = false
	v5_.minOctave1 = 8
	v5_.numOctave1 = 1
	v5_.persistence1 = 0.5
	v5_.minOctave2 = 12
	v5_.numOctave2 = 1
	v5_.persistence2 = 0.5
	if g_server ~= nil then
		addConsoleCommand("pfWeedSetNoiseParameters", "Sets current weed noise parameters", "setWeedNoiseParameters", v5_)
	end
	return v5_
end

-- Local values: noiseFilename
function ExtendedWeedControl:loadFromXML(_, _, baseDirectory, configFileName, mapFilename)
	local v7_ = Utils.getFilename("shared/weedNoise.grle", ExtendedWeedControl.BASE_DIRECTORY)
	self.noiseBitVectorMap = createBitVectorMap("weedNoise")
	if not loadBitVectorMapFromFile(self.noiseBitVectorMap, v7_, 1) then
		loadBitVectorMapNew(self.noiseBitVectorMap, 4096, 4096, 1, false)
		Logging.error("Failed to load weed noise map from %s", v7_)
		return false
	end
	self.noiseFilter = DensityMapFilter.new(self.noiseBitVectorMap, 0, 1)
	self.noiseFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
end

function ExtendedWeedControl:unloadMapData()
	self.noiseFilter = nil
	self.weedFilter = nil
	if self.noiseBitVectorMap ~= nil then
		delete(self.noiseBitVectorMap)
		self.noiseBitVectorMap = nil
	end
	if g_server ~= nil then
		removeConsoleCommand("pfWeedSetNoiseParameters")
	end
end

-- Local values: modifier, perlinNoiseFilter1, perlinNoiseFilter2, noiseValues, _, noiseValue, path
function ExtendedWeedControl:setWeedNoiseParameters(minOctave1, numOctave1, persistence1, minOctave2, numOctave2, persistence2)
	local v16_ = tonumber(minOctave1)
	local v17_ = tonumber(numOctave1)
	local v18_ = tonumber(persistence1)
	local v19_ = tonumber(minOctave2)
	local v20_ = tonumber(numOctave2)
	local v21_ = tonumber(persistence2)
	local v22_ = v16_ or self.minOctave1
	local v23_ = v17_ or self.numOctave1
	local v24_ = v18_ or self.persistence1
	self.minOctave1 = v22_
	self.numOctave1 = v23_
	self.persistence1 = v24_
	local v25_ = v19_ or self.minOctave2
	local v26_ = v20_ or self.numOctave2
	local v27_ = v21_ or self.persistence2
	self.minOctave2 = v25_
	self.numOctave2 = v26_
	self.persistence2 = v27_
	log("Weed Noise Parameters:")
	log(string.format("  minOctave1 %.2f, numOctave1 %.2f, persistence1 %.2f", self.minOctave1, self.numOctave1, self.persistence1))
	log(string.format("  minOctave2 %.2f, numOctave2 %.2f, persistence2 %.2f", self.minOctave2, self.numOctave2, self.persistence2))
	loadBitVectorMapNew(self.noiseBitVectorMap, 4096, 4096, 1, false)
	local v28_ = DensityMapModifier.new(self.noiseBitVectorMap, 0, 1, g_terrainNode)
	local v29_ = PerlinNoiseFilter.new(self.noiseBitVectorMap, self.minOctave1, self.numOctave1, self.persistence1, math.random(0, 1000))
	local v30_ = PerlinNoiseFilter.new(self.noiseBitVectorMap, self.minOctave2, self.numOctave2, self.persistence2, math.random(0, 1000))
	local v31_ = {}
	table.insert(v31_, {
		0,
		750,
		0,
		9000
	})
	table.insert(v31_, {
		750,
		1500,
		0,
		5000
	})
	table.insert(v31_, {
		1500,
		2000,
		0,
		3000
	})
	table.insert(v31_, {
		2000,
		3500,
		0,
		2000
	})
	table.insert(v31_, {
		3500,
		5000,
		0,
		1000
	})
	table.insert(v31_, {
		5000,
		10000,
		0,
		500
	})
	for _, v32_ in ipairs(v31_) do
		v29_:setValueCompareParams(DensityValueCompareType.BETWEEN, v32_[1], v32_[2])
		v30_:setValueCompareParams(DensityValueCompareType.BETWEEN, v32_[3], v32_[4])
		v28_:executeSet(1, v29_, v30_)
	end
	local v33_ = getUserProfileAppPath() .. "weedNoise.grle"
	saveBitVectorMapToFile(self.noiseBitVectorMap, v33_)
	Logging.info("Saved weed noise map to %s", v33_)
end

function ExtendedWeedControl:clearWeedArea(modifier, weedFilter)
	modifier:executeSet(0, self.noiseFilter, weedFilter)
end

-- Local values: weedSystem, terrainRootNode, weedMapId, weedFirstChannel, weedNumChannels, weedSparseState, weedDenseState
function ExtendedWeedControl:getWeedModifier()
	if self.weedModifier == nil then
		local v38_ = g_currentMission.weedSystem
		if v38_:getMapHasWeed() then
			local v39_ = g_terrainNode
			local v40_, v41_, v42_ = v38_:getDensityMapData()
			self.weedModifier = DensityMapModifier.new(v40_, v41_, v42_, v39_)
			local v43_ = v38_:getSparseStartState()
			local v44_ = v38_:getDenseStartState()
			self.weedFilterDense = DensityMapFilter.new(v40_, v41_, v42_)
			self.weedFilterDense:setValueCompareParams(DensityValueCompareType.EQUAL, v44_)
			self.weedFilterSparse = DensityMapFilter.new(v40_, v41_, v42_)
			self.weedFilterSparse:setValueCompareParams(DensityValueCompareType.EQUAL, v43_)
		end
	end
	return self.weedModifier
end

function ExtendedWeedControl:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "setSowingWeedArea", function(p47_, p48_, p49_, p50_, p51_, p52_, p53_)
		-- upvalues: (copy) self
		p47_(p48_, p49_, p50_, p51_, p52_, p53_)
		local v54_ = self:getWeedModifier()
		if v54_ ~= nil then
			v54_:setParallelogramWorldCoords(p48_, p49_, p50_, p51_, p52_, p53_, DensityCoordType.POINT_POINT_POINT)
			self:clearWeedArea(v54_, self.weedFilterDense)
			self:clearWeedArea(v54_, self.weedFilterSparse)
		end
	end)
	pfModule:overwriteGameFunction(Sprayer, "processSprayerArea", function(p55_, p56_, p57_, p58_)
		-- upvalues: (copy) self
		local v59_ = self
		local v60_
		if p56_.getIsSpotSprayEnabled == nil then
			v60_ = false
		else
			v60_ = p56_:getIsSpotSprayEnabled()
		end
		v59_.lastUseSpotSpraying = v60_
		return p55_(p56_, p57_, p58_)
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateHerbicideArea", function(_, p61_, p62_, p63_, p64_, p65_, p66_, p67_)
		-- upvalues: (copy) self
		local v68_ = self.lastUseSpotSpraying ~= true
		local v69_ = g_currentMission.weedSystem
		if not v69_:getMapHasWeed() then
			return 0, 0
		end
		local v70_ = FSDensityMapUtil.functionCache.updateHerbicideArea
		if v70_ == nil then
			v70_ = {
				["numChangedPixels"] = {},
				["totalNumPixels"] = {},
				["multiModifiers"] = {},
				["defaultMultiModifiers"] = {}
			}
			FSDensityMapUtil.functionCache.updateHerbicideArea = v70_
		end
		local v71_ = "sprayedTotal"
		if p67_ ~= nil and v70_.multiModifiers[p67_] == nil then
			v70_.multiModifiers[p67_] = {}
		end
		local v72_ = p67_ and v70_.multiModifiers[p67_][v68_] or v70_.defaultMultiModifiers[v68_]
		if v72_ == nil then
			v72_ = DensityMapMultiModifier.new()
			local v73_ = g_terrainNode
			local v74_ = g_currentMission.fieldGroundSystem
			local v75_, v76_, v77_ = v74_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local v78_, v79_, v80_ = v74_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			local v81_, v82_, v83_ = v69_:getDensityMapData()
			local v84_, v85_ = v74_:getSowableRange()
			local v86_ = v69_:getHerbicideReplacements()
			local v87_ = v86_.weed.replacements
			if v86_.custom ~= nil then
				for _, v88_ in ipairs(v86_.custom) do
					local v89_ = v88_.fruitType
					if v89_.terrainDataPlaneId ~= nil then
						local v90_ = DensityMapModifier.new(v89_.terrainDataPlaneId, v89_.startStateChannel, v89_.numStateChannels, v73_)
						local v91_ = DensityMapFilter.new(v89_.terrainDataPlaneId, v89_.startStateChannel, v89_.numStateChannels)
						for v92_, v93_ in pairs(v87_) do
							v91_:setValueCompareParams(DensityValueCompareType.EQUAL, v92_)
							v72_:addExecuteSetWithStats(v71_, v93_, v90_, v91_)
							v71_ = "sprayed"
						end
					end
				end
			end
			local v94_ = DensityMapModifier.new(v78_, v79_, v80_, v73_)
			local v95_ = DensityMapModifier.new(v81_, v82_, v83_, v73_)
			local v96_ = DensityMapFilter.new(v75_, v76_, v77_)
			v96_:setValueCompareParams(DensityValueCompareType.BETWEEN, v84_, v85_)
			for v97_, v98_ in pairs(v87_) do
				if v68_ or v97_ ~= 1 and v97_ ~= 2 then
					local v99_ = DensityMapFilter.new(v81_, v82_, v83_)
					v99_:setValueCompareParams(DensityValueCompareType.EQUAL, v97_)
					for _, v100_ in pairs(g_fruitTypeManager:getFruitTypes()) do
						if v100_.terrainDataPlaneId ~= nil then
							local v101_ = DensityMapFilter.new(v100_.terrainDataPlaneId, v100_.startStateChannel, v100_.numStateChannels)
							v101_:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, v100_.minHarvestingGrowthState - 1)
							v72_:addExecuteSet(p67_, v94_, v101_, v99_)
							v72_:addExecuteSetWithStats(v71_, v98_, v95_, v101_, v99_)
							local v102_ = DensityMapFilter.new(v100_.terrainDataPlaneId, v100_.startStateChannel, v100_.numStateChannels)
							v102_:setValueCompareParams(DensityValueCompareType.EQUAL, v100_.cutState + 1)
							v72_:addExecuteSet(p67_, v94_, v102_, v99_)
							v72_:addExecuteSetWithStats(v71_, v98_, v95_, v102_, v99_)
							if v100_.wheelDestructionState ~= nil and v100_.wheelDestructionState ~= v100_.cutState + 1 then
								local v103_ = DensityMapFilter.new(v100_.terrainDataPlaneId, v100_.startStateChannel, v100_.numStateChannels)
								v103_:setValueCompareParams(DensityValueCompareType.EQUAL, v100_.wheelDestructionState)
								v72_:addExecuteSet(p67_, v94_, v103_, v99_)
								v72_:addExecuteSetWithStats(v71_, v98_, v95_, v103_, v99_)
							end
						end
					end
					v72_:addExecuteSet(p67_, v94_, v96_, v99_)
					v72_:addExecuteSetWithStats(v71_, v98_, v95_, v96_, v99_)
				end
			end
			if p67_ then
				v70_.multiModifiers[p67_][v68_] = v72_
			else
				v70_.defaultMultiModifiers[v68_] = v72_
			end
		end
		local v104_ = v70_.numChangedPixels
		local v105_ = v70_.totalNumPixels
		v72_:updateParallelogramWorldCoords(p61_, p62_, p63_, p64_, p65_, p66_, DensityCoordType.POINT_POINT_POINT)
		v72_:resetStats()
		v72_:execute(nil, v104_, v105_)
		return v104_.sprayedTotal + v104_.sprayed, v105_.sprayedTotal or 0
	end)
	pfModule:overwriteGameFunction(FieldUpdateTask, "prepare", function(p106_, p107_, ...)
		-- upvalues: (copy) self
		p106_(p107_, ...)
		if p107_.weedState ~= nil then
			local v108_ = self:getWeedModifier()
			if v108_ ~= nil then
				p107_.multiModifier:addExecuteSet(0, v108_, self.noiseFilter)
			end
		end
	end)
	pfModule:overwriteGameFunction(FieldState, "update", function(p109_, p110_, p111_, p112_, ...)
		-- upvalues: (copy) self
		p109_(p110_, p111_, p112_, ...)
		local v113_ = g_currentMission.weedSystem
		if v113_:getMapHasWeed() then
			local v114_ = self.fieldStateWeedStateData
			if v114_ == nil then
				local v115_ = g_terrainNode
				local v116_, v117_, v118_ = v113_:getDensityMapData()
				local v119_ = v113_:getFactors()
				v114_ = {
					["weedModifier"] = DensityMapModifier.new(v116_, v117_, v118_, v115_),
					["weedStateFilters"] = {}
				}
				for v120_, _ in pairs(v119_) do
					local v121_ = DensityMapFilter.new(v116_, v117_, v118_)
					v121_:setValueCompareParams(DensityValueCompareType.EQUAL, v120_)
					v114_.weedStateFilters[v121_] = v120_
				end
				self.fieldStateWeedStateData = v114_
			end
			local v122_ = v114_.weedModifier
			local v123_ = v114_.weedStateFilters
			v122_:setParallelogramWorldCoords(p111_ - 10, p112_ - 10, p111_ + 10, p112_ - 10, p111_ - 10, p112_ + 10, DensityCoordType.POINT_POINT_POINT)
			for v124_, v125_ in pairs(v123_) do
				local _, v126_, _ = v122_:executeGet(v124_)
				if v126_ > 0 then
					p110_.weedState = v125_
					p110_.weedFactor = v113_.factors[v125_] or 0
					return
				end
			end
		end
	end)
end
