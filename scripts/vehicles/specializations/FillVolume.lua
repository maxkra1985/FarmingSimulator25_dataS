FillVolume = {}
FillVolume.SEND_NUM_BITS = 6
FillVolume.SEND_MAX_SIZE = 15
local v1_ = FillVolume
local v2_ = FillVolume.SEND_NUM_BITS
v1_.SEND_MAX_VALUE = math.pow(2, v2_) - 1
FillVolume.SEND_PRECISION = FillVolume.SEND_MAX_SIZE / FillVolume.SEND_MAX_VALUE

-- Local values: value
function FillVolume.writeStreamCompressedPosition(streamId, position)
	local v5_ = (position + FillVolume.SEND_MAX_SIZE * 0.5) / FillVolume.SEND_MAX_SIZE
	local v6_ = math.clamp(v5_, 0, 1) * FillVolume.SEND_MAX_VALUE
	streamWriteUIntN(streamId, v6_, FillVolume.SEND_NUM_BITS)
end

-- Local values: value, position
function FillVolume.readStreamCompressedPosition(streamId)
	return streamReadUIntN(streamId, FillVolume.SEND_NUM_BITS) / FillVolume.SEND_MAX_VALUE * FillVolume.SEND_MAX_SIZE - FillVolume.SEND_MAX_SIZE * 0.5
end

function FillVolume.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end
function FillVolume.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("fillVolume", g_i18n:getText("configuration_fillVolume"), "fillVolume", VehicleConfigurationItem)
	local v9_ = Vehicle.xmlSchema
	v9_:setXMLSpecializationType("FillVolume")
	v9_:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#node", "Fill volume node")
	v9_:register(XMLValueType.INT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#fillUnitIndex", "Fill unit index")
	v9_:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#fillUnitFactor", "Fill unit factor", 1)
	v9_:register(XMLValueType.BOOL, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#useFullCapacity", "Defines if the fill volume represents the full fill unit capacity when multiple fill volumes are given. If set to \'false\' (default), the fill level is split across the defined volumes. If set to \'true\' all fill up the same.", true)
	v9_:register(XMLValueType.BOOL, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#allSidePlanes", "All side planes", true)
	v9_:register(XMLValueType.BOOL, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#retessellateTop", "Retessellate top plane for better triangulation quality", false)
	v9_:register(XMLValueType.STRING, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#defaultFillType", "Default fill type name")
	v9_:register(XMLValueType.STRING, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#forcedVolumeFillType", "Forced fill type name")
	v9_:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxDelta", "Max. heap size above above input surface [m]", 1)
	v9_:register(XMLValueType.ANGLE, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxAllowedHeapAngle", "Max. allowed heap surface slope angle [deg]", 35)
	v9_:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxSurfaceDistanceError", "Max. allowed distance from input mesh surface to created fill plane mesh [m]", 0.05)
	v9_:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#maxSubDivEdgeLength", "Max. length of sub division edges [m]", 0.9)
	v9_:register(XMLValueType.FLOAT, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?)#syncMaxSubDivEdgeLength", "Max. length of sub division edges used to sync in multiplayer [m]", 1.35)
	v9_:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(?).volumes.volume(?).deformNode(?)#node", "Deformer node")
	FillVolume.registerInfoNodeXMLPaths(v9_, "vehicle.fillVolume.loadInfos.loadInfo(?)")
	FillVolume.registerInfoNodeXMLPaths(v9_, "vehicle.fillVolume.unloadInfos.unloadInfo(?)")
	v9_:register(XMLValueType.INT, "vehicle.fillVolume.heightNodes.heightNode(?)#fillVolumeIndex", "Fill volume index")
	v9_:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.heightNodes.heightNode(?).refNode(?)#node", "Reference node")
	v9_:register(XMLValueType.NODE_INDEX, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#node", "Height node")
	v9_:register(XMLValueType.VECTOR_SCALE, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#baseScale", "Base scale", "1 1 1")
	v9_:register(XMLValueType.VECTOR_3, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#scaleAxis", "Scale axis", "0 0 0")
	v9_:register(XMLValueType.VECTOR_SCALE, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#scaleMax", "Max. scale", "0 0 0")
	v9_:register(XMLValueType.VECTOR_3, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#transAxis", "Translation axis", "0 0 0")
	v9_:register(XMLValueType.VECTOR_TRANS, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#transMax", "Max. translation", "0 0 0")
	v9_:register(XMLValueType.FLOAT, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#minHeight", "Min. fill volume height used for height node", 0)
	v9_:register(XMLValueType.FLOAT, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#heightOffset", "Fill plane height offset", 0)
	v9_:register(XMLValueType.BOOL, "vehicle.fillVolume.heightNodes.heightNode(?).node(?)#orientateToWorldY", "Orientate to world Y", false)
	v9_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p10_, p11_)
		p10_:register(XMLValueType.INT, p11_ .. ".fillVolume#fillVolumeIndex", "Fill Unit index which includes the deformers", 1)
		p10_:register(XMLValueType.VECTOR_N, p11_ .. ".fillVolume#deformerNodeIndices", "Indices of deformer nodes to update")
	end)
	v9_:addDelayedRegistrationFunc("Cylindered:movingPart", function(p12_, p13_)
		p12_:register(XMLValueType.INT, p13_ .. ".fillVolume#fillVolumeIndex", "Fill Unit index which includes the deformers", 1)
		p12_:register(XMLValueType.VECTOR_N, p13_ .. ".fillVolume#deformerNodeIndices", "Indices of deformer nodes to update")
	end)
	v9_:setXMLSpecializationType()
end

function FillVolume.registerInfoNodeXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Info node")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#width", "Info width", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#length", "Info length", 1)
	schema:register(XMLValueType.INT, basePath .. ".node(?)#fillVolumeHeightIndex", "Fill volume height index")
	schema:register(XMLValueType.INT, basePath .. ".node(?)#priority", "Priority", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#minHeight", "Min. height")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#maxHeight", "Max. height")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#minFillLevelPercentage", "Min. fill level percentage")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#maxFillLevelPercentage", "Min. fill level percentage")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#heightForTranslation", "Min. height for translation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translationStart", "Translation start")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".node(?)#translationEnd", "Translation end")
end

function FillVolume.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolume", FillVolume.loadFillVolume)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeInfo", FillVolume.loadFillVolumeInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadFillVolumeHeightNode", FillVolume.loadFillVolumeHeightNode)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeLoadInfo", FillVolume.getFillVolumeLoadInfo)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUnloadInfo", FillVolume.getFillVolumeUnloadInfo)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeIndicesByFillUnitIndex", FillVolume.getFillVolumeIndicesByFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillTypeByFillUnitIndex", FillVolume.setFillVolumeForcedFillTypeByFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "setFillVolumeForcedFillType", FillVolume.setFillVolumeForcedFillType)
	SpecializationUtil.registerFunction(vehicleType, "getFillVolumeUVScrollSpeed", FillVolume.getFillVolumeUVScrollSpeed)
end

function FillVolume.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setMovingToolDirty", FillVolume.setMovingToolDirty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", FillVolume.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", FillVolume.updateExtraDependentParts)
end

function FillVolume.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", FillVolume)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", FillVolume)
end

-- Local values: spec, fillVolumeConfigurationId, configKey, _, mapping, _, fillVolume, _, fillVolume, capacity, i, deformer, fillVolumeMaterial
function FillVolume:onLoad(savegame)
	local v_u_20_ = self.spec_fillVolume
	local v21_ = Utils.getNoNil(self.configurations.fillVolume, 1)
	local v22_ = string.format("vehicle.fillVolume.fillVolumeConfigurations.fillVolumeConfiguration(%d).volumes", v21_ - 1)
	v_u_20_.volumes = {}
	v_u_20_.fillVolumeDeformersByNode = {}
	v_u_20_.fillUnitFillVolumeMapping = {}
	self.xmlFile:iterate(v22_ .. ".volume", function(_, p23_)
		-- upvalues: (copy) self, (copy) v_u_20_
		local v24_ = {}
		if self:loadFillVolume(self.xmlFile, p23_, v24_) then
			local v25_ = v_u_20_.volumes
			table.insert(v25_, v24_)
			v24_.index = #v_u_20_.volumes
		end
	end)
	for _, v26_ in ipairs(v_u_20_.fillUnitFillVolumeMapping) do
		for _, v27_ in ipairs(v26_.fillVolumes) do
			if not v27_.useFullCapacity then
				v27_.fillUnitFactor = v27_.fillUnitFactor / v26_.sumFactors
			end
		end
	end
	for _, v28_ in ipairs(v_u_20_.volumes) do
		v28_.capacity = self:getFillUnitCapacity(v28_.fillUnitIndex) * v28_.fillUnitFactor
		v28_.fillLevel = 0
		v28_.volume = createFillPlaneShape(v28_.baseNode, "fillPlane", v28_.capacity, v28_.maxDelta, v28_.maxSurfaceAngle, v28_.maxPhysicalSurfaceAngle, v28_.maxSurfaceDistanceError, v28_.maxSubDivEdgeLength, v28_.syncMaxSubDivEdgeLength, v28_.allSidePlanes, v28_.retessellateTop)
		if v28_.volume == nil or v28_.volume == 0 then
			local v29_ = printWarning
			local v30_ = getName
			local v31_ = v28_.baseNode
			v29_("Warning: fillVolume \'" .. tostring(v30_(v31_)) .. "\' could not create actual fillVolume in \'" .. self.configFileName .. "\'! Simplifying the mesh could help")
			v28_.volume = nil
		else
			setVisibility(v28_.volume, false)
			for v32_ = #v28_.deformers, 1, -1 do
				local v33_ = v28_.deformers[v32_]
				v33_.polyline = findPolyline(v28_.volume, v33_.posX, v33_.posZ)
				if v33_.polyline == nil and v33_.polyline ~= -1 then
					local v34_ = printWarning
					local v35_ = getName
					local v36_ = v33_.node
					v34_("Warning: Could not find \'polyline\' for \'" .. tostring(v35_(v36_)) .. "\' in \'" .. self.configFileName .. "\'")
					table.remove(v28_.deformers, v32_)
				end
			end
			link(v28_.baseNode, v28_.volume)
			local v37_ = g_materialManager:getBaseMaterialByName("fillPlane")
			if v37_ == nil then
				Logging.error("Failed to assign material to fill volume. Base Material \'fillPlane\' not found!")
			else
				setMaterial(v28_.volume, v37_, 0)
				g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(v28_.volume, g_terrainNode, true, true, true)
			end
			fillPlaneAdd(v28_.volume, 1, 0, 1, 0, 11, 0, 0, 0, 0, 11)
			v28_.heightOffset = getFillPlaneHeightAtLocalPos(v28_.volume, 0, 0)
			fillPlaneAdd(v28_.volume, -1, 0, 1, 0, 11, 0, 0, 0, 0, 11)
		end
	end
	v_u_20_.loadInfos = {}
	self.xmlFile:iterate("vehicle.fillVolume.loadInfos.loadInfo", function(_, p38_)
		-- upvalues: (copy) self, (copy) v_u_20_
		local v39_ = {}
		if self:loadFillVolumeInfo(self.xmlFile, p38_, v39_) then
			local v40_ = v_u_20_.loadInfos
			table.insert(v40_, v39_)
		end
	end)
	v_u_20_.unloadInfos = {}
	self.xmlFile:iterate("vehicle.fillVolume.unloadInfos.unloadInfo", function(_, p41_)
		-- upvalues: (copy) self, (copy) v_u_20_
		local v42_ = {}
		if self:loadFillVolumeInfo(self.xmlFile, p41_, v42_) then
			local v43_ = v_u_20_.unloadInfos
			table.insert(v43_, v42_)
		end
	end)
	v_u_20_.heightNodes = {}
	v_u_20_.fillVolumeIndexToHeightNode = {}
	self.xmlFile:iterate("vehicle.fillVolume.heightNodes.heightNode", function(_, p44_)
		-- upvalues: (copy) self, (copy) v_u_20_
		local v45_ = {}
		if self:loadFillVolumeHeightNode(self.xmlFile, p44_, v45_) then
			local v46_ = v_u_20_.heightNodes
			table.insert(v46_, v45_)
			if v_u_20_.fillVolumeIndexToHeightNode[v45_.fillVolumeIndex] == nil then
				v_u_20_.fillVolumeIndexToHeightNode[v45_.fillVolumeIndex] = {}
			end
			local v47_ = v_u_20_.fillVolumeIndexToHeightNode[v45_.fillVolumeIndex]
			table.insert(v47_, v45_)
		end
	end)
	v_u_20_.lastPositionInfo = { 0, 0 }
	v_u_20_.lastPositionInfoSent = { 0, 0 }
	v_u_20_.availableFillNodes = {}
	v_u_20_.dirtyFlag = self:getNextDirtyFlag()
	if not self.isClient or #v_u_20_.volumes == 0 and #v_u_20_.heightNodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", FillVolume)
	end
end

-- Local values: spec, _, fillVolume
function FillVolume:onDelete()
	local v49_ = self.spec_fillVolume
	if v49_.volumes ~= nil then
		for _, v50_ in ipairs(v49_.volumes) do
			if v50_.volume ~= nil then
				delete(v50_.volume)
			end
			v50_.volume = nil
		end
	end
end

-- Local values: spec
function FillVolume:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v54_ = self.spec_fillVolume
		if streamReadBool(streamId) then
			v54_.lastPositionInfo[1] = FillVolume.readStreamCompressedPosition(streamId)
			v54_.lastPositionInfo[2] = FillVolume.readStreamCompressedPosition(streamId)
		end
	end
end

-- Local values: spec
function FillVolume:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v59_ = self.spec_fillVolume
		local v60_ = streamWriteBool
		local v61_ = v59_.dirtyFlag
		if v60_(streamId, bit32.band(dirtyMask, v61_) ~= 0) then
			FillVolume.writeStreamCompressedPosition(streamId, v59_.lastPositionInfoSent[1])
			FillVolume.writeStreamCompressedPosition(streamId, v59_.lastPositionInfoSent[2])
		end
	end
end

-- Local values: spec, _, fillVolume, _, deformer, posX, posY, posZ, dx, dz, uvScrollSpeedX, uvScrollSpeedY, uvScrollSpeedZ, _, heightNode, fillVolume, baseNode, volumeNode, minHeight, maxHeight, maxHeightWorld, _, refNode, x, _, z, height, _, yw, _, wx1, wy1, wz1, wx2, wy2, wz2, _, node, nodeHeight, sx, sy, sz, tx, ty, tz, wx1, wy1, wz1, wx2, wy2, wz2, wx1, wy1, wz1, wx2, wy2, wz2, _, dy, _, alpha
function FillVolume:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if not self.isClient then
		::l2::
		return
	end
	local v64_ = self.spec_fillVolume
	for _, v65_ in pairs(v64_.volumes) do
		for _, v66_ in ipairs(v65_.deformers) do
			if v66_.isDirty and (v66_.polyline ~= nil and v66_.polyline ~= -1) then
				v66_.isDirty = false
				local v67_, _, v68_ = localToLocal(v66_.node, v66_.baseNode, 0, 0, 0)
				local v69_ = v67_ - v66_.posX
				if math.abs(v69_) > 0.0001 then
					::l11::
					v66_.lastPosX = v67_
					v66_.lastPosZ = v68_
					local v70_ = v67_ - v66_.initPos[1]
					local v71_ = v68_ - v66_.initPos[3]
					setPolylineTranslation(v65_.volume, v66_.polyline, v70_, v71_)
				else
					local v72_ = v68_ - v66_.posZ
					if math.abs(v72_) > 0.0001 then
						goto l11
					end
				end
			end
		end
		local v73_, v74_, v75_ = self:getFillVolumeUVScrollSpeed(v65_.index)
		if v73_ ~= 0 or (v74_ ~= 0 or v75_ ~= 0) then
			v65_.uvPosition[1] = v65_.uvPosition[1] + v73_ * (dt / 1000)
			v65_.uvPosition[2] = v65_.uvPosition[2] + v74_ * (dt / 1000)
			v65_.uvPosition[3] = v65_.uvPosition[3] + v75_ * (dt / 1000)
			setShaderParameter(v65_.volume, "uvOffset", v65_.uvPosition[1], v65_.uvPosition[2], v65_.uvPosition[3], 0, false)
		end
	end
	for _, v76_ in pairs(v64_.heightNodes) do
		if v76_.isDirty then
			v76_.isDirty = false
			local v77_ = v64_.volumes[v76_.fillVolumeIndex]
			local v78_ = v77_.baseNode
			local v79_ = v77_.volume
			if v78_ ~= nil and v79_ ~= nil then
				local v80_ = math.huge
				local v81_ = -math.huge
				local v82_ = -math.huge
				for _, v83_ in pairs(v76_.refNodes) do
					local v84_, _, v85_ = localToLocal(v83_.refNode, v78_, 0, 0, 0)
					local v86_ = getFillPlaneHeightAtLocalPos(v79_, v84_, v85_)
					if not MathUtil.isNan(v86_) then
						local v87_ = v86_ - v77_.heightOffset
						v80_ = math.min(v80_, v87_)
						v81_ = math.max(v81_, v87_)
						local _, v88_, _ = localToWorld(v78_, v84_, v87_, v85_)
						v82_ = math.max(v82_, v88_)
						if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
							local v89_, v90_, v91_ = localToWorld(v78_, v84_, v77_.heightOffset, v85_)
							local v92_, v93_, v94_ = localToWorld(v78_, v84_, v87_, v85_)
							drawDebugLine(v89_, v90_, v91_, 0, 1, 0, v92_, v93_, v94_, 0, 1, 0, false)
							Utils.renderTextAtWorldPosition(v92_, v93_, v94_, string.format("Height: %.2fm", v87_), 0.01)
						end
					end
				end
				v76_.currentMinHeight = v80_
				v76_.currentMaxHeight = v81_
				v76_.currentMaxHeightWorld = v82_
				for _, v95_ in pairs(v76_.nodes) do
					local v96_ = v80_ + v95_.heightOffset
					local v97_ = v95_.minHeight
					local v98_ = math.max(v96_, v97_)
					local v99_ = v95_.scaleAxis[1] * v98_
					local v100_ = v95_.scaleAxis[2] * v98_
					local v101_ = v95_.scaleAxis[3] * v98_
					if v95_.scaleMax[1] > 0 then
						local v102_ = v95_.scaleMax[1]
						v99_ = math.min(v102_, v99_)
					end
					if v95_.scaleMax[2] > 0 then
						local v103_ = v95_.scaleMax[2]
						v100_ = math.min(v103_, v100_)
					end
					if v95_.scaleMax[3] > 0 then
						local v104_ = v95_.scaleMax[3]
						v101_ = math.min(v104_, v101_)
					end
					local v105_ = v95_.transAxis[1] * v98_
					local v106_ = v95_.transAxis[2] * v98_
					local v107_ = v95_.transAxis[3] * v98_
					if v95_.transMax[1] > 0 then
						local v108_ = v95_.transMax[1]
						v105_ = math.min(v108_, v105_)
					end
					if v95_.transMax[2] > 0 then
						local v109_ = v95_.transMax[2]
						v106_ = math.min(v109_, v106_)
					end
					if v95_.transMax[3] > 0 then
						local v110_ = v95_.transMax[3]
						v107_ = math.min(v110_, v107_)
					end
					setScale(v95_.node, v95_.baseScale[1] + v99_, v95_.baseScale[2] + v100_, v95_.baseScale[3] + v101_)
					setTranslation(v95_.node, v95_.basePosition[1] + v105_, v95_.basePosition[2] + v106_, v95_.basePosition[3] + v107_)
					if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES and getEffectiveVisibility(v95_.node) then
						renderShapeOutline(v95_.node, false)
						if v100_ ~= 0 then
							setScale(v95_.node, 1, 1, 1)
							local v111_, v112_, v113_ = localToWorld(v95_.node, 0, 0, 0)
							local v114_, v115_, v116_ = localToWorld(v95_.node, 0, v95_.baseScale[2] + v100_, 0)
							drawDebugLine(v111_, v112_, v113_, 0, 1, 0, v114_, v115_, v116_, 0, 1, 0, false)
							Utils.renderTextAtWorldPosition(v114_, v115_, v116_, string.format("%s scaleY: %.2f", getName(v95_.node), v95_.baseScale[2] + v100_), 0.01)
							setScale(v95_.node, v95_.baseScale[1] + v99_, v95_.baseScale[2] + v100_, v95_.baseScale[3] + v101_)
						end
						if v106_ ~= 0 then
							local v117_, v118_, v119_ = localToWorld(getParent(v95_.node), v95_.basePosition[1] + v105_, v95_.basePosition[2], v95_.basePosition[3] + v107_)
							local v120_, v121_, v122_ = localToWorld(getParent(v95_.node), v95_.basePosition[1] + v105_, v95_.basePosition[2] + v106_, v95_.basePosition[3] + v107_)
							drawDebugLine(v117_, v118_, v119_, 0, 1, 0, v120_, v121_, v122_, 0, 1, 0, false)
							Utils.renderTextAtWorldPosition(v120_, v121_, v122_, string.format("%s transY: %.2f", getName(v95_.node), v95_.basePosition[2] + v106_), 0.01)
						end
					end
					if v95_.orientateToWorldY then
						local _, v123_, _ = localDirectionToWorld(getParent(v95_.node), 0, 1, 0)
						local v124_ = math.clamp(v123_, -1, 1)
						local v125_ = math.acos(v124_)
						setRotation(v95_.node, v125_, 0, 0)
					end
				end
			end
		end
	end
	goto l2
end

-- Local values: spec, fillUnitIndex, defaultFillTypeStr, defaultFillTypeIndex, forcedVolumeFillTypeStr, forcedVolumeFillTypeIndex, j, deformerKey, node, initPos, deformer
function FillVolume:loadFillVolume(xmlFile, key, entry)
	local v130_ = self.spec_fillVolume
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	entry.baseNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if entry.baseNode == nil then
		printWarning("Warning: fillVolume \'" .. tostring(key) .. "\' has an invalid \'node\' in \'" .. self.configFileName .. "\'!")
		return false
	end
	if not getHasClassId(entry.baseNode, ClassIds.SHAPE) then
		Logging.xmlWarning(xmlFile, "fillVolume \'" .. getName(entry.baseNode) .. "\' at \'" .. tostring(key) .. "\' is not a shape!")
		return false
	end
	local v131_ = xmlFile:getValue(key .. "#fillUnitIndex")
	entry.fillUnitIndex = v131_
	if v131_ == nil then
		printWarning("Warning: fillVolume \'" .. tostring(key) .. "\' has no \'fillUnitIndex\' given in \'" .. self.configFileName .. "\'!")
		return false
	end
	if not self:getFillUnitExists(v131_) then
		printWarning("Warning: fillVolume \'" .. tostring(key) .. "\' has an invalid \'fillUnitIndex\' in \'" .. self.configFileName .. "\'!")
		return false
	end
	entry.fillUnitFactor = xmlFile:getValue(key .. "#fillUnitFactor", 1)
	entry.useFullCapacity = xmlFile:getValue(key .. "#useFullCapacity", true)
	if v130_.fillUnitFillVolumeMapping[v131_] == nil then
		v130_.fillUnitFillVolumeMapping[v131_] = {
			["fillVolumes"] = {},
			["sumFactors"] = 0
		}
	end
	local v132_ = v130_.fillUnitFillVolumeMapping[v131_].fillVolumes
	table.insert(v132_, entry)
	v130_.fillUnitFillVolumeMapping[v131_].sumFactors = v130_.fillUnitFillVolumeMapping[v131_].sumFactors + entry.fillUnitFactor
	entry.allSidePlanes = xmlFile:getValue(key .. "#allSidePlanes", true)
	entry.retessellateTop = xmlFile:getValue(key .. "#retessellateTop", false)
	local v133_ = xmlFile:getValue(key .. "#defaultFillType")
	if v133_ == nil then
		entry.defaultFillType = self:getFillUnitFirstSupportedFillType(v131_)
	else
		local v134_ = g_fillTypeManager:getFillTypeIndexByName(v133_)
		if v134_ == nil then
			printWarning("Warning: Invalid defaultFillType \'" .. tostring(v133_) .. "\' for \'" .. tostring(key) .. "\' in \'" .. self.configFileName .. "\'")
			return false
		end
		entry.defaultFillType = v134_
	end
	local v135_ = xmlFile:getValue(key .. "#forcedVolumeFillType")
	if v135_ ~= nil then
		local v136_ = g_fillTypeManager:getFillTypeIndexByName(v135_)
		if v136_ == nil then
			printWarning("Warning: Invalid forcedVolumeFillType \'" .. tostring(v135_) .. "\' for \'" .. tostring(key) .. "\' in \'" .. self.configFileName .. "\'")
			return false
		end
		entry.forcedVolumeFillType = v136_
	end
	entry.maxDelta = xmlFile:getValue(key .. "#maxDelta", 1)
	entry.maxSurfaceAngle = xmlFile:getValue(key .. "#maxAllowedHeapAngle", 35)
	entry.maxPhysicalSurfaceAngle = 0.6108652381980153
	entry.maxSurfaceDistanceError = xmlFile:getValue(key .. "#maxSurfaceDistanceError", 0.05)
	entry.maxSubDivEdgeLength = xmlFile:getValue(key .. "#maxSubDivEdgeLength", 0.9)
	entry.syncMaxSubDivEdgeLength = xmlFile:getValue(key .. "#syncMaxSubDivEdgeLength", 1.35)
	entry.uvPosition = { 0, 0, 0 }
	entry.deformers = {}
	local v137_ = 0
	while true do
		local v138_ = string.format("%s.deformNode(%d)", key, v137_)
		if not xmlFile:hasProperty(v138_) then
			break
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v138_ .. "#index", v138_ .. "#node")
		local v139_ = xmlFile:getValue(v138_ .. "#node", nil, self.components, self.i3dMappings)
		if v139_ ~= nil then
			local v140_ = { localToLocal(v139_, entry.baseNode, 0, 0, 0) }
			local v141_ = {
				["node"] = v139_,
				["initPos"] = v140_,
				["posX"] = v140_[1],
				["posZ"] = v140_[3],
				["polyline"] = nil,
				["volume"] = entry.volume,
				["baseNode"] = entry.baseNode
			}
			local v142_ = entry.deformers
			table.insert(v142_, v141_)
			v130_.fillVolumeDeformersByNode[v139_] = v141_
		end
		v137_ = v137_ + 1
	end
	entry.lastFillType = FillType.UNKNOWN
	return true
end

-- Local values: i, infoKey, node, nodeEntry
function FillVolume:loadFillVolumeInfo(xmlFile, key, entry)
	entry.nodes = {}
	local v147_ = 0
	while true do
		local v148_ = key .. string.format(".node(%d)", v147_)
		if not xmlFile:hasProperty(v148_) then
			break
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v148_ .. "#index", v148_ .. "#node")
		local v149_ = xmlFile:getValue(v148_ .. "#node", nil, self.components, self.i3dMappings)
		if v149_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", v148_)
		else
			local v150_ = {
				["node"] = v149_,
				["width"] = xmlFile:getValue(v148_ .. "#width", 1),
				["length"] = xmlFile:getValue(v148_ .. "#length", 1),
				["fillVolumeHeightIndex"] = xmlFile:getValue(v148_ .. "#fillVolumeHeightIndex"),
				["priority"] = xmlFile:getValue(v148_ .. "#priority", 1),
				["minHeight"] = xmlFile:getValue(v148_ .. "#minHeight"),
				["maxHeight"] = xmlFile:getValue(v148_ .. "#maxHeight"),
				["minFillLevelPercentage"] = xmlFile:getValue(v148_ .. "#minFillLevelPercentage"),
				["maxFillLevelPercentage"] = xmlFile:getValue(v148_ .. "#maxFillLevelPercentage"),
				["heightForTranslation"] = xmlFile:getValue(v148_ .. "#heightForTranslation"),
				["translationStart"] = xmlFile:getValue(v148_ .. "#translationStart", nil, true),
				["translationEnd"] = xmlFile:getValue(v148_ .. "#translationEnd", nil, true),
				["translationAlpha"] = 0
			}
			local v151_ = entry.nodes
			table.insert(v151_, v150_)
		end
		v147_ = v147_ + 1
	end
	table.sort(entry.nodes, function(p152_, p153_)
		return p152_.priority > p153_.priority
	end)
	return true
end

-- Local values: i, nodeKey, node, nodeKey, node, nodeEntry
function FillVolume:loadFillVolumeHeightNode(xmlFile, key, entry)
	entry.isDirty = false
	entry.fillVolumeIndex = xmlFile:getValue(key .. "#fillVolumeIndex", 1)
	if self.spec_fillVolume.volumes[entry.fillVolumeIndex] == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid fillVolumeIndex \'%d\' for heightNode \'%s\'. Igoring heightNode!", entry.fillVolumeIndex, key)
		return false
	end
	entry.refNodes = {}
	local v158_ = 0
	while true do
		local v159_ = key .. string.format(".refNode(%d)", v158_)
		if not xmlFile:hasProperty(v159_) then
			break
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v159_ .. "#index", v159_ .. "#node")
		local v160_ = xmlFile:getValue(v159_ .. "#node", nil, self.components, self.i3dMappings)
		if v160_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", v159_)
		else
			local v161_ = entry.refNodes
			table.insert(v161_, {
				["refNode"] = v160_
			})
		end
		v158_ = v158_ + 1
	end
	entry.nodes = {}
	local v162_ = 0
	while true do
		local v163_ = key .. string.format(".node(%d)", v162_)
		if not xmlFile:hasProperty(v163_) then
			break
		end
		XMLUtil.checkDeprecatedXMLElements(xmlFile, v163_ .. "#index", v163_ .. "#node")
		local v164_ = xmlFile:getValue(v163_ .. "#node", nil, self.components, self.i3dMappings)
		if v164_ == nil then
			Logging.xmlWarning(self.xmlFile, "Missing node for \'%s\'", v163_)
		else
			local v165_ = {
				["node"] = v164_,
				["baseScale"] = xmlFile:getValue(v163_ .. "#baseScale", "1 1 1", true),
				["scaleAxis"] = xmlFile:getValue(v163_ .. "#scaleAxis", "0 0 0", true),
				["scaleMax"] = xmlFile:getValue(v163_ .. "#scaleMax", "0 0 0", true),
				["basePosition"] = { getTranslation(v164_) },
				["transAxis"] = xmlFile:getValue(v163_ .. "#transAxis", "0 0 0", true),
				["transMax"] = xmlFile:getValue(v163_ .. "#transMax", "0 0 0", true),
				["minHeight"] = xmlFile:getValue(v163_ .. "#minHeight", 0),
				["heightOffset"] = xmlFile:getValue(v163_ .. "#heightOffset", 0),
				["orientateToWorldY"] = xmlFile:getValue(v163_ .. "#orientateToWorldY", false)
			}
			local v166_ = entry.nodes
			table.insert(v166_, v165_)
		end
		v162_ = v162_ + 1
	end
	return true
end

-- Local values: spec
function FillVolume:getFillVolumeLoadInfo(loadInfoIndex)
	return self.spec_fillVolume.loadInfos[loadInfoIndex]
end

-- Local values: spec
function FillVolume:getFillVolumeUnloadInfo(unloadInfoIndex)
	return self.spec_fillVolume.unloadInfos[unloadInfoIndex]
end

-- Local values: spec, indices, i, fillVolume
function FillVolume:getFillVolumeIndicesByFillUnitIndex(fillUnitIndex)
	local v173_ = self.spec_fillVolume
	local v174_ = {}
	for v175_, v176_ in ipairs(v173_.volumes) do
		if v176_.fillUnitIndex == fillUnitIndex then
			table.insert(v174_, v175_)
		end
	end
	return v174_
end

-- Local values: spec, i, fillVolume
function FillVolume:setFillVolumeForcedFillTypeByFillUnitIndex(fillUnitIndex, forcedFillType)
	local v180_ = self.spec_fillVolume
	for v181_, v182_ in ipairs(v180_.volumes) do
		if v182_.fillUnitIndex == fillUnitIndex then
			self:setFillVolumeForcedFillType(v181_, forcedFillType)
		end
	end
end

-- Local values: spec
function FillVolume:setFillVolumeForcedFillType(fillVolumeIndex, forcedFillType)
	local v186_ = self.spec_fillVolume
	if v186_.volumes[fillVolumeIndex] ~= nil then
		v186_.volumes[fillVolumeIndex].forcedFillType = forcedFillType
	end
end

function FillVolume:getFillVolumeUVScrollSpeed()
	return 0, 0, 0
end

-- Local values: spec, deformer
function FillVolume:setMovingToolDirty(superFunc, node, forceUpdate, dt)
	superFunc(self, node, forceUpdate, dt)
	local v192_ = self.spec_fillVolume
	if v192_.fillVolumeDeformersByNode ~= nil then
		local v193_ = v192_.fillVolumeDeformersByNode[node]
		if v193_ ~= nil then
			v193_.isDirty = true
		end
	end
end

-- Local values: fillVolumeIndex, indices, i
function FillVolume:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end
	local v199_ = xmlFile:getValue(baseName .. ".fillVolume#fillVolumeIndex", 1)
	local v200_ = xmlFile:getValue(baseName .. ".fillVolume#deformerNodeIndices", nil, true)
	if v200_ ~= nil and #v200_ > 0 then
		entry.fillVolumeIndex = v199_
		entry.deformerNodes = {}
		for v201_ = 1, #v200_ do
			local v202_ = entry.deformerNodes
			local v203_ = v200_[v201_]
			table.insert(v202_, v203_)
		end
	end
	return true
end

-- Local values: i, nodeIndex, deformerNode
function FillVolume:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)
	if part.deformerNodes ~= nil then
		if part.fillVolumeIndex ~= nil then
			part.fillVolume = self.spec_fillVolume.volumes[part.fillVolumeIndex]
			if part.fillVolume == nil then
				Logging.xmlWarning(self.xmlFile, "Unable to find fillVolume with index \'%d\' for movingPart/movingTool \'%s\'", part.fillVolumeIndex, getName(part.node))
				part.deformerNodes = nil
			end
			part.fillVolumeIndex = nil
		end
		if part.fillVolume ~= nil then
			for v208_, v209_ in pairs(part.deformerNodes) do
				local v210_ = part.fillVolume.deformers[v209_]
				if v210_ == nil then
					part.deformerNodes[v208_] = nil
				else
					v210_.isDirty = true
				end
			end
		end
	end
end

-- Local values: spec, mapping, fillLevel, fillType, _, fillVolume, baseNode, volumeNode, oldFillLevel, fillLevelDelta, maxPhysicalSurfaceAngle, fillTypeInfo, textureArrayIndex, i, neededPriority, _, node, doInsert, height, _, refNode, x, _, z, x, _, z, x, y, z, percentage, numFillNodes, avgX, avgZ, i, node, x0, y0, z0, d1x, d1y, d1z, d2x, d2y, d2z, newX, _, newZ, newX, newZ, loadSize, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z, steps, _, heightNodes, _, heightNode, _, deformer
function FillVolume:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, _, toolType, fillPositionData, appliedDelta)
	local v214_ = self.spec_fillVolume
	local v215_ = v214_.fillUnitFillVolumeMapping[fillUnitIndex]
	if v215_ == nil then
		return
	end
	local v216_ = self:getFillUnitFillLevel(fillUnitIndex)
	local v217_ = self:getFillUnitFillType(fillUnitIndex)
	for _, v218_ in ipairs(v215_.fillVolumes) do
		local v219_ = v218_.baseNode
		local v220_ = v218_.volume
		if v219_ == nil or v220_ == nil then
			return
		end
		local v221_ = v218_.fillLevel
		local v222_ = v218_.capacity
		v218_.fillLevel = math.clamp(v216_, 0, v222_)
		local v223_ = v218_.fillLevel - v221_
		if v218_.forcedFillType ~= nil then
			v217_ = v218_.forcedFillType
		end
		if v216_ == 0 then
			v218_.forcedFillType = nil
		end
		if v217_ ~= v218_.lastFillType then
			local v224_ = g_fillTypeManager:getFillTypeByIndex(v217_)
			local v225_
			if v224_ == nil then
				v225_ = nil
			else
				v225_ = v224_.maxPhysicalSurfaceAngle
			end
			if v225_ ~= nil and v218_.volume ~= nil then
				setFillPlaneMaxPhysicalSurfaceAngle(v218_.volume, v225_)
				v218_.maxPhysicalSurfaceAngle = v225_
			end
		end
		setVisibility(v218_.volume, v216_ > 0)
		if v217_ ~= FillType.UNKNOWN and v217_ ~= v218_.lastFillType then
			local v226_ = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(v217_)
			if v226_ ~= nil then
				setShaderParameter(v218_.volume, "fillTypeId", v226_ - 1, 0, 0, 0, false)
			end
		end
		if fillPositionData == nil then
			local v227_ = (v218_.maxPhysicalSurfaceAngle == 0 or v218_.maxSurfaceAngle == 0) and 10 or 0.1
			local v228_, v229_, v230_ = localToWorld(v218_.volume, -v227_ * 0.5, 0, -v227_ * 0.5)
			local v231_, v232_, v233_ = localDirectionToWorld(v218_.volume, v227_, 0, 0)
			local v234_, v235_, v236_ = localDirectionToWorld(v218_.volume, 0, 0, v227_)
			if not self.isServer and (v214_.lastPositionInfo[1] ~= 0 and v214_.lastPositionInfo[2] ~= 0) then
				v228_, v229_, v230_ = localToWorld(v218_.volume, v214_.lastPositionInfo[1], 0, v214_.lastPositionInfo[2])
			end
			local v237_ = v223_ / 400
			local v238_ = math.floor(v237_)
			local v239_ = math.clamp(v238_, 1, 25)
			for _ = 1, v239_ do
				fillPlaneAdd(v218_.volume, v223_ / v239_, v228_, v229_, v230_, v231_, v232_, v233_, v234_, v235_, v236_)
			end
		else
			for v240_ = #v214_.availableFillNodes, 1, -1 do
				v214_.availableFillNodes[v240_] = nil
			end
			if fillPositionData.nodes == nil then
				local v241_ = v214_.availableFillNodes
				table.insert(v241_, fillPositionData)
			else
				local v242_ = fillPositionData.nodes[1].priority
				while #v214_.availableFillNodes == 0 and v242_ >= 1 do
					for _, v243_ in pairs(fillPositionData.nodes) do
						if v242_ <= v243_.priority then
							local v244_ = true
							if v243_.minHeight ~= nil or v243_.maxHeight ~= nil then
								local v245_ = -math.huge
								if v243_.fillVolumeHeightIndex == nil or v214_.heightNodes[v243_.fillVolumeHeightIndex] == nil then
									local v246_, _, v247_ = localToLocal(v243_.node, v219_, 0, 0, 0)
									local v248_ = getFillPlaneHeightAtLocalPos(v220_, v246_, v247_) - v218_.heightOffset
									v245_ = math.max(v245_, v248_)
								else
									for _, v249_ in pairs(v214_.heightNodes[v243_.fillVolumeHeightIndex].refNodes) do
										local v250_, _, v251_ = localToLocal(v249_.refNode, v219_, 0, 0, 0)
										local v252_ = getFillPlaneHeightAtLocalPos(v220_, v250_, v251_) - v218_.heightOffset
										v245_ = math.max(v245_, v252_)
									end
								end
								if v243_.minHeight ~= nil and v245_ < v243_.minHeight then
									v244_ = false
								end
								if v243_.maxHeight ~= nil and v243_.maxHeight < v245_ then
									v244_ = false
								end
								if v243_.heightForTranslation ~= nil then
									if v243_.heightForTranslation < v245_ then
										v243_.translationAlpha = v243_.translationAlpha + 0.01
										local v253_, v254_, v255_ = MathUtil.vector3ArrayLerp(v243_.translationStart, v243_.translationEnd, v243_.translationAlpha)
										setTranslation(v243_.node, v253_, v254_, v255_)
									else
										v243_.translationAlpha = v243_.translationAlpha - 0.01
									end
									local v256_ = v243_.translationAlpha
									v243_.translationAlpha = math.clamp(v256_, 0, 1)
								end
							end
							if v243_.minFillLevelPercentage ~= nil or v243_.maxFillLevelPercentage ~= nil then
								local v257_ = v216_ / self:getFillUnitCapacity(fillUnitIndex)
								if v243_.minFillLevelPercentage ~= nil and v257_ < v243_.minFillLevelPercentage then
									v244_ = false
								end
								if v243_.maxFillLevelPercentage ~= nil and v243_.maxFillLevelPercentage < v257_ then
									v244_ = false
								end
							end
							if v244_ then
								local v258_ = v214_.availableFillNodes
								table.insert(v258_, v243_)
							end
						end
					end
					if #v214_.availableFillNodes > 0 then
						break
					end
					v242_ = v242_ - 1
				end
			end
			local v259_ = #v214_.availableFillNodes
			local v260_ = 0
			local v261_ = 0
			for v262_ = 1, v259_ do
				local v263_ = v214_.availableFillNodes[v262_]
				local v264_, v265_, v266_ = getWorldTranslation(v263_.node)
				local v267_, v268_, v269_ = localDirectionToWorld(v263_.node, v263_.width, 0, 0)
				local v270_, v271_, v272_ = localDirectionToWorld(v263_.node, 0, 0, v263_.length)
				if VehicleDebug.state == VehicleDebug.DEBUG then
					drawDebugLine(v264_, v265_, v266_, 1, 0, 0, v264_ + v267_, v265_ + v268_, v266_ + v269_, 1, 0, 0)
					drawDebugLine(v264_, v265_, v266_, 0, 0, 1, v264_ + v270_, v265_ + v271_, v266_ + v272_, 0, 0, 1)
					drawDebugPoint(v264_, v265_, v266_, 1, 1, 1, 1)
					drawDebugPoint(v264_ + v267_, v265_ + v268_, v266_ + v269_, 1, 0, 0, 1)
					drawDebugPoint(v264_ + v270_, v265_ + v271_, v266_ + v272_, 0, 0, 1, 1)
				end
				local v273_ = v264_ - (v267_ + v270_) / 2
				local v274_ = v265_ - (v268_ + v271_) / 2
				local v275_ = v266_ - (v269_ + v272_) / 2
				fillPlaneAdd(v218_.volume, v223_ / v259_, v273_, v274_, v275_, v267_, v268_, v269_, v270_, v271_, v272_)
				local v276_, _, v277_ = localToLocal(v263_.node, v218_.volume, 0, 0, 0)
				v260_ = v260_ + v276_
				v261_ = v261_ + v277_
			end
			local v278_ = v260_ / v259_
			local v279_ = v261_ / v259_
			local v280_ = v278_ - v214_.lastPositionInfoSent[1]
			if math.abs(v280_) > FillVolume.SEND_PRECISION then
				::l77::
				v214_.lastPositionInfoSent[1] = v278_
				v214_.lastPositionInfoSent[2] = v279_
				self:raiseDirtyFlags(v214_.dirtyFlag)
				goto l78
			end
			local v281_ = v279_ - v214_.lastPositionInfoSent[2]
			if math.abs(v281_) > FillVolume.SEND_PRECISION then
				goto l77
			end
		end
		::l78::
		local v282_ = v214_.fillVolumeIndexToHeightNode[v218_.index]
		if v282_ ~= nil then
			for _, v283_ in ipairs(v282_) do
				v283_.isDirty = true
			end
		end
		for _, v284_ in pairs(v218_.deformers) do
			v284_.isDirty = true
		end
		v218_.lastFillType = v217_
	end
end

-- Local values: spec, fillUnitIndex, mapping, index, fillVolume, textureArrayIndex, _, _, _
function FillVolume:updateDebugValues(values)
	local v287_ = self.spec_fillVolume
	for v288_, v289_ in pairs(v287_.fillUnitFillVolumeMapping) do
		for v290_, v291_ in ipairs(v289_.fillVolumes) do
			local v292_ = {
				["name"] = "fillUnitIndex/fillVolume",
				["value"] = tostring(v288_) .. " / " .. tostring(v290_)
			}
			table.insert(values, v292_)
			local v293_ = {
				["name"] = "lastFillType",
				["value"] = g_fillTypeManager:getFillTypeNameByIndex(v291_.lastFillType)
			}
			table.insert(values, v293_)
			local v294_ = {
				["name"] = "volume"
			}
			local v295_ = v291_.volume
			v294_.value = tostring(v295_)
			table.insert(values, v294_)
			if v291_.volume ~= nil then
				local v296_ = {
					["name"] = "visibility"
				}
				local v297_ = getVisibility
				local v298_ = v291_.volume
				v296_.value = tostring(v297_(v298_))
				table.insert(values, v296_)
				local v299_, _, _, _ = getShaderParameter(v291_.volume, "fillTypeId")
				local v300_ = {
					["name"] = "textureArrayIndex",
					["value"] = tostring(v299_)
				}
				table.insert(values, v300_)
			end
		end
	end
	local v301_ = {
		["name"] = "lastPositionInfo",
		["value"] = string.format("%.2f %.2f", v287_.lastPositionInfo[1], v287_.lastPositionInfo[2])
	}
	table.insert(values, v301_)
	local v302_ = {
		["name"] = "lastPositionInfoSent",
		["value"] = string.format("%.2f %.2f", v287_.lastPositionInfoSent[1], v287_.lastPositionInfoSent[2])
	}
	table.insert(values, v302_)
end
