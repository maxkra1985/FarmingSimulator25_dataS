WheelDestruction = {}
WheelDestruction.MAX_UPDATE_DISTANCE = 40

-- Local values: self
function WheelDestruction.new(wheel)
	local v2_ = {
		["__index"] = WheelDestruction
	}
	local v3_ = setmetatable({}, v2_)
	v3_.wheel = wheel
	v3_.vehicle = wheel.vehicle
	v3_.destructionNodes = {}
	v3_.wheelSmoothAccumulation = 0
	return v3_
end

function WheelDestruction:loadFromXML(xmlObject)
	xmlObject:checkDeprecatedXMLElements(".tire#isCareWheel", "#isCareWheel")
	self.isCareWheel = xmlObject:getValue("#isCareWheel", false)
	local v6_ = self.wheel.physics.width * 0.75
	self.smoothGroundRadius = xmlObject:getValue(".physics#smoothGroundRadius", (math.max(0.6, v6_)))
	return true
end

-- Local values: _, visualWheel, destructionNode, destructionNode
function WheelDestruction:finalize()
	for _, v8_ in ipairs(self.wheel.visualWheels) do
		local v9_ = {
			["node"] = v8_.node,
			["width"] = v8_.width,
			["radius"] = v8_.radius
		}
		local v10_ = self.destructionNodes
		table.insert(v10_, v9_)
	end
	if #self.wheel.visualWheels == 0 then
		local v11_ = {
			["node"] = self.wheel.driveNode,
			["width"] = self.wheel.physics.width,
			["radius"] = self.wheel.physics.radius
		}
		local v12_ = self.destructionNodes
		table.insert(v12_, v11_)
	end
end

-- Local values: hasContact, doFruitDestruction, doSnowDestruction, _, destructionNode, repr, width, length, xShift, yShift, zShift, x0, _, z0, x1, _, z1, x2, _, z2, snowOffset, x3, _, z3, x4, _, z4, x5, _, z5, wheelSmoothAmount, rounded, _, destructionNode, xOffset, _, _, x, y, z
function WheelDestruction:update(dt, allowFoliageDestruction)
	if g_server ~= nil or self.vehicle.currentUpdateDistance < WheelDestruction.MAX_UPDATE_DISTANCE then
		if allowFoliageDestruction and self.vehicle.lastSpeedReal > 0.0002 then
			local v16_ = self.wheel.physics.contact ~= WheelContactType.NONE
			local v17_
			if v16_ then
				v17_ = not self.isCareWheel
			else
				v17_ = v16_
			end
			if v16_ then
				v16_ = self.wheel.physics.hasSnowContact
			end
			if v17_ or v16_ then
				for _, v18_ in ipairs(self.destructionNodes) do
					local v19_ = self.wheel.repr
					local v20_ = 0.5 * v18_.width
					local v21_ = 0.5 * v18_.width
					local v22_ = math.min(0.5, v21_)
					local v23_, v24_, v25_ = localToLocal(v18_.node, v19_, 0, 0, 0)
					if v17_ then
						local v26_, _, v27_ = localToWorld(v19_, v23_ + v20_, v24_, v25_ - v22_)
						local v28_, _, v29_ = localToWorld(v19_, v23_ - v20_, v24_, v25_ - v22_)
						local v30_, _, v31_ = localToWorld(v19_, v23_ + v20_, v24_, v25_ + v22_)
						if g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self.vehicle:getActiveFarm(), v26_, v27_) then
							self:destroyFruitArea(v26_, v27_, v28_, v29_, v30_, v31_)
						end
					end
					if v16_ then
						local v32_ = v18_.radius * 0.75 * self.vehicle.movingDirection
						local v33_, _, v34_ = localToWorld(v19_, v23_ + v20_, v24_, v25_ - v22_ + v32_)
						local v35_, _, v36_ = localToWorld(v19_, v23_ - v20_, v24_, v25_ - v22_ + v32_)
						local v37_, _, v38_ = localToWorld(v19_, v23_ + v20_, v24_, v25_ + v22_ + v32_)
						self:destroySnowArea(v33_, v34_, v35_, v36_, v37_, v38_)
					end
				end
			end
		end
		if Platform.gameplay.wheelDensityHeightSmooth then
			local v39_ = 0
			if self.vehicle.lastSpeedReal > 0.0002 then
				local v40_ = self.wheelSmoothAccumulation
				local v41_ = self.vehicle.lastMovedDistance * 1.2
				local v42_ = 0.0003 * dt
				v39_ = v40_ + math.max(v41_, v42_)
				self.wheelSmoothAccumulation = v39_ - DensityMapHeightUtil.getRoundedHeightValue(v39_)
			else
				self.wheelSmoothAccumulation = 0
			end
			if v39_ > 0 then
				for _, v43_ in ipairs(self.destructionNodes) do
					local v44_, _, _ = localToLocal(v43_.node, self.wheel.repr, 0, 0, 0)
					local v45_, v46_, v47_ = localToLocal(self.wheel.node, self.wheel.repr, self.wheel.physics.netInfo.x, self.wheel.physics.netInfo.y, self.wheel.physics.netInfo.z)
					local v48_, v49_, v50_ = localToWorld(self.wheel.repr, v45_ + v44_, v46_ - self.wheel.physics.radius, v47_)
					self:smoothHeightAtPosition(v48_, v49_, v50_, self.smoothGroundRadius, v39_)
				end
			end
		end
	end
end

function WheelDestruction:destroyFruitArea(x0, z0, x1, z1, x2, z2)
	FSDensityMapUtil.updateWheelDestructionArea(x0, z0, x1, z1, x2, z2)
end

-- Local values: snowSystem, worldSnowHeight, curHeight, reduceSnow, isOnSnowHeap, sink, sinkLayers
function WheelDestruction:destroySnowArea(x0, z0, x1, z1, x2, z2)
	local v63_ = g_currentMission.snowSystem
	local v64_ = v63_.height
	local v65_ = v63_:getSnowHeightAtArea(x0, z0, x1, z1, x2, z2)
	local v66_ = MathUtil.equalEpsilon(v64_, v65_, 0.005)
	local v67_
	if v64_ < 0.005 then
		v67_ = v65_ > 1
	else
		v67_ = false
	end
	if SnowSystem.MIN_LAYER_HEIGHT < v65_ and (v66_ or v67_) then
		local v68_ = 0.7 * v64_
		if v67_ then
			v68_ = 0.1 * v65_
		end
		local v69_ = math.min(v68_, v65_) / SnowSystem.MIN_LAYER_HEIGHT
		local v70_ = math.floor(v69_)
		if v70_ > 0 then
			v63_:removeSnow(x0, z0, x1, z1, x2, z2, v70_)
		end
	end
end

-- Local values: smoothYOffset, heightType, terrainHeightUpdater, terrainHeight, physicsDeltaHeight, deltaHeight, internalHeight
function WheelDestruction:smoothHeightAtPosition(x, y, z, radius, amount)
	local v76_ = DensityMapHeightUtil.getHeightTypeDescAtWorldPos(x, y, z, radius)
	if v76_ ~= nil and v76_.allowsSmoothing then
		local v77_ = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
		if v77_ ~= nil then
			local v78_ = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
			local v79_ = y - v78_
			local v80_ = (v79_ + v76_.collisionBaseOffset) / v76_.collisionScale
			local v81_ = v79_ + v76_.minCollisionOffset
			local v82_ = math.max(v80_, v81_)
			local v83_ = v79_ + v76_.maxCollisionOffset
			local v84_ = math.min(v82_, v83_) + -0.1
			local v85_ = v78_ + math.max(v84_, 0)
			smoothDensityMapHeightAtWorldPos(v77_, x, v85_, z, amount, v76_.index, 0, radius, radius + 1.2, 0)
			if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
				DebugUtil.drawDebugCircle(x, v85_, z, radius, 10)
			end
		end
	end
end

-- Local values: _, visualWheel, repr, width, length, xShift, yShift, zShift, x0, y0, z0, x1, _, z1, x2, _, z2, x, z, widthX, widthZ, heightX, heightZ, repr, width, length, xShift, yShift, zShift, x0, y0, z0, x1, _, z1, x2, _, z2, x, z, widthX, widthZ, heightX, heightZ
function WheelDestruction:drawAreas()
	if not self.isCareWheel then
		for _, v87_ in ipairs(self.wheel.visualWheels) do
			local v88_ = self.wheel.repr
			local v89_ = 0.5 * v87_.width
			local v90_ = 0.5 * v87_.width
			local v91_ = math.min(0.5, v90_)
			local v92_, v93_, v94_ = localToLocal(v87_.node, v88_, 0, 0, 0)
			local v95_, v96_, v97_ = localToWorld(v88_, v92_ + v89_, v93_, v94_ - v91_)
			local v98_, _, v99_ = localToWorld(v88_, v92_ - v89_, v93_, v94_ - v91_)
			local v100_, _, v101_ = localToWorld(v88_, v92_ + v89_, v93_, v94_ + v91_)
			local v102_, v103_, v104_, v105_, v106_, v107_ = MathUtil.getXZWidthAndHeight(v95_, v97_, v98_, v99_, v100_, v101_)
			DebugUtil.drawDebugParallelogram(v102_, v103_, v104_, v105_, v106_, v107_, v96_, 1, 1, 0, 0.05, true)
		end
		if #self.wheel.visualWheels == 0 then
			local v108_ = self.wheel.repr
			local v109_ = 0.5 * self.wheel.physics.width
			local v110_ = 0.5 * self.wheel.physics.width
			local v111_ = math.min(0.5, v110_)
			local v112_, v113_, v114_ = localToLocal(self.wheel.driveNode, v108_, 0, 0, 0)
			local v115_, v116_, v117_ = localToWorld(v108_, v112_ + v109_, v113_, v114_ - v111_)
			local v118_, _, v119_ = localToWorld(v108_, v112_ - v109_, v113_, v114_ - v111_)
			local v120_, _, v121_ = localToWorld(v108_, v112_ + v109_, v113_, v114_ + v111_)
			local v122_, v123_, v124_, v125_, v126_, v127_ = MathUtil.getXZWidthAndHeight(v115_, v117_, v118_, v119_, v120_, v121_)
			DebugUtil.drawDebugParallelogram(v122_, v123_, v124_, v125_, v126_, v127_, v116_, 1, 1, 0, 0.05, true)
		end
	end
end

function WheelDestruction:setIsCareWheel(isCareWheel)
	self.isCareWheel = isCareWheel
end

function WheelDestruction.registerXMLPaths(schema, key)
	schema:register(XMLValueType.BOOL, key .. "#isCareWheel", "Is care wheel", false)
	schema:register(XMLValueType.FLOAT, key .. ".physics#smoothGroundRadius", "Smooth ground radius", "width * 0.75")
end
