-- Local values: ObjectSpawner_mt
ObjectSpawner = {}
local ObjectSpawner_mt = Class(ObjectSpawner)

-- Upvalues: ObjectSpawner_mt
-- Local values: self
function ObjectSpawner.new(spawnFunction, numObjectsTarget, numSpawnsPerSecond, spawnMinRadius, spawnMaxRadius, destroyRadius, warmupCameraMove, warmupPercentage, updateFunction)
	-- upvalues: (copy) ObjectSpawner_mt
	local v11_ = ObjectSpawner_mt
	local v12_ = setmetatable({}, v11_)
	v12_.spawnFunction = spawnFunction
	v12_.updateFunction = updateFunction
	v12_.numObjectsTarget = numObjectsTarget
	v12_.spawnMinRadius = spawnMinRadius
	v12_.spawnMaxRadius = spawnMaxRadius
	v12_.destroyRadius = destroyRadius
	v12_.destroyRadiusSq = v12_.destroyRadius * v12_.destroyRadius
	v12_.warmupCameraMove = warmupCameraMove
	v12_.warmupCameraMoveSq = warmupCameraMove * warmupCameraMove
	v12_.warmupPercentage = warmupPercentage
	v12_.spawnInterval = 1 / (numSpawnsPerSecond * 0.001)
	v12_.spawnDt = 0
	v12_.isWarmedUp = false
	v12_.lastCx = 0
	v12_.lastCz = 0
	v12_.objects = {}
	v12_.numObjects = 0
	v12_.objectsCache = {}
	return v12_
end

-- Local values: _, object, _, object
function ObjectSpawner:delete()
	for _, v14_ in pairs(self.objects) do
		if not v14_.isDeleted then
			v14_:delete()
		end
	end
	for _, v15_ in pairs(self.objectsCache) do
		if not v15_.isDeleted then
			v15_:delete()
		end
	end
end

-- Local values: camera, cx, cy, cz, k, object, k, object, doWarmup, dx, dz, numAdded, numObjectsToAdd, i, object
function ObjectSpawner:update(dt)
	local v18_ = g_cameraManager:getActiveCamera()
	local v19_, v20_, v21_ = getWorldTranslation(v18_)
	if self.updateFunction == nil then
		for _, v22_ in pairs(self.objects) do
			if not v22_.isDeleted then
				v22_:update(dt)
			end
		end
	else
		self.updateFunction(self, dt)
	end
	for v23_, v24_ in pairs(self.objects) do
		if v24_.isDeleted then
			self.objects[v23_] = nil
			self.numObjects = self.numObjects - 1
		elseif v24_.requestDelete or v24_:getSquaredDistanceFrom(v19_, v21_) > self.destroyRadiusSq then
			v24_:removeFromScene()
			self.objects[v23_] = nil
			self.numObjects = self.numObjects - 1
			local v25_ = self.objectsCache
			table.insert(v25_, v24_)
		end
	end
	local v26_ = not self.isWarmedUp
	self.isWarmedUp = true
	if not v26_ then
		local v27_ = v19_ - self.lastCx
		local v28_ = v21_ - self.lastCz
		v26_ = v27_ * v27_ + v28_ * v28_ > self.warmupCameraMoveSq and true or v26_
	end
	self.lastCx = v19_
	self.lastCz = v21_
	self.spawnDt = self.spawnDt + dt
	if v26_ or self.spawnDt > self.spawnInterval then
		local v29_ = 0
		local v30_
		if v26_ then
			local v31_ = self.warmupPercentage * self.numObjectsTarget
			v30_ = math.ceil(v31_)
		else
			v30_ = 1
		end
		local v32_ = self.numObjectsTarget - self.numObjects
		local v33_ = math.min(v32_, v30_)
		for _ = 1, v33_ do
			local v34_ = self.spawnFunction(self, v26_, v19_, v20_, v21_)
			if v34_ ~= nil then
				self.objects[v34_] = v34_
				self.numObjects = self.numObjects + 1
				v29_ = v29_ + 1
			end
		end
		if v29_ > 0 or v33_ == 0 then
			self.spawnDt = 0
			return
		end
		self.spawnDt = self.spawnInterval * 0.75
	end
end

-- Local values: numObjects, object
function ObjectSpawner:getObjectFromCache()
	local v36_ = #self.objectsCache
	while v36_ > 0 do
		local v37_ = self.objectsCache[v36_]
		table.remove(self.objectsCache, v36_)
		v36_ = v36_ - 1
		if not v37_.isDeleted then
			return v37_
		end
	end
	return nil
end
