TireTracks = {}
TireTracks.MAX_CREATION_DISTANCE = 75

function TireTracks.prerequisitesPresent(vehicleType)
	return true
end
function TireTracks.initSpecialization() end

function TireTracks.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAllowTireTracks", TireTracks.getAllowTireTracks)
	SpecializationUtil.registerFunction(vehicleType, "addTireTrackNode", TireTracks.addTireTrackNode)
	SpecializationUtil.registerFunction(vehicleType, "removeTireTrackNode", TireTracks.removeTireTrackNode)
	SpecializationUtil.registerFunction(vehicleType, "updateTireTrackNode", TireTracks.updateTireTrackNode)
end

function TireTracks.registerOverwrittenFunctions(vehicleType) end

function TireTracks.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", TireTracks)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TireTracks)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TireTracks)
end

-- Local values: spec
function TireTracks:onPreLoad(savegame)
	local v4_ = self.spec_tireTracks
	v4_.tireTrackNodes = {}
	v4_.hasTireTrackNodes = false
	v4_.segmentsCoeff = getTyreTracksSegmentsCoeff()
	v4_.tireTrackSystem = g_currentMission.tireTrackSystem
end

-- Local values: spec, _, tireTrackNode
function TireTracks:onDelete()
	local v6_ = self.spec_tireTracks
	if v6_.tireTrackNodes ~= nil then
		for _, v7_ in pairs(v6_.tireTrackNodes) do
			v6_.tireTrackSystem:destroyTrack(v7_.tireTrackIndex)
		end
	end
end

-- Local values: spec, allowTireTracks, _, tireTrackNode
function TireTracks:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isActive then
		local v9_ = self.spec_tireTracks
		if v9_.hasTireTrackNodes then
			local v10_ = self:getAllowTireTracks()
			for _, v11_ in pairs(v9_.tireTrackNodes) do
				self:updateTireTrackNode(v11_, v10_)
			end
		end
	end
end

function TireTracks:getAllowTireTracks()
	local v13_
	if self.currentUpdateDistance < TireTracks.MAX_CREATION_DISTANCE then
		v13_ = self.spec_tireTracks.segmentsCoeff > 0
	else
		v13_ = false
	end
	return v13_
end

-- Local values: spec, tireTrackNode
function TireTracks:addTireTrackNode(wheel, parent, linkNode, tireTrackAtlasIndex, width, radius, inverted, activeFunc)
	local v23_ = self.spec_tireTracks
	local v24_ = {
		["wheel"] = wheel,
		["parent"] = parent,
		["linkNode"] = linkNode,
		["tireTrackAtlasIndex"] = tireTrackAtlasIndex,
		["width"] = width,
		["radius"] = radius,
		["inverted"] = inverted,
		["activeFunc"] = activeFunc
	}
	if v23_.tireTrackSystem ~= nil then
		v24_.tireTrackIndex = v23_.tireTrackSystem:createTrack(width, tireTrackAtlasIndex)
		if v24_.tireTrackIndex ~= nil then
			local v25_ = v23_.tireTrackNodes
			table.insert(v25_, v24_)
			v23_.hasTireTrackNodes = next(v23_.tireTrackNodes) ~= nil
			return #v23_.tireTrackNodes
		end
	end
	return nil
end

-- Local values: spec
function TireTracks:removeTireTrackNode(tireTrackNodeIndex)
	local v28_ = self.spec_tireTracks
	v28_.tireTrackNodes[tireTrackNodeIndex] = nil
	v28_.hasTireTrackNodes = next(v28_.tireTrackNodes) ~= nil
end

-- Local values: spec, wheel, wx, wy, wz, r, g, b, groundDepth, t, dirtAmount, colorBlendWithTerrain, ux, uy, uz, tireDirection
function TireTracks:updateTireTrackNode(tireTrackNode, allowTireTracks)
	local v32_ = self.spec_tireTracks
	local v33_ = tireTrackNode.wheel
	if allowTireTracks then
		if tireTrackNode.activeFunc == nil or tireTrackNode.activeFunc() then
			local v34_, v35_, v36_ = worldToLocal(tireTrackNode.parent, getWorldTranslation(tireTrackNode.linkNode))
			local v37_ = v35_ - tireTrackNode.radius
			local v38_, v39_, v40_ = localToWorld(tireTrackNode.parent, v34_, v37_, v36_)
			local v41_ = getTerrainHeightAtWorldPos
			local v42_ = g_terrainNode
			local v43_ = math.max(v39_, v41_(v42_, v38_, v39_, v40_))
			if v33_.physics.contact == WheelContactType.NONE or not v33_.physics.lastContactObjectAllowsTireTracks then
				v32_.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
				return
			else
				local v44_, v45_, v46_, v47_, _, v48_, v49_ = v33_.physics:getGroundAttributes()
				if v48_ > 0 then
					local v50_, v51_, v52_ = localDirectionToWorld(v33_.node, -v33_.physics.directionX, -v33_.physics.directionY, -v33_.physics.directionZ)
					local v53_ = self.movingDirection
					if tireTrackNode.inverted then
						v53_ = v53_ * -1
					end
					v32_.tireTrackSystem:addTrackPoint(tireTrackNode.tireTrackIndex, v38_, v43_, v40_, v50_, v51_, v52_, v44_, v45_, v46_, v48_, v47_, v53_, v33_.physics.contact ~= WheelContactType.OBJECT, v49_)
				else
					v32_.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
				end
			end
		else
			v32_.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
			return
		end
	else
		v32_.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
		return
	end
end
