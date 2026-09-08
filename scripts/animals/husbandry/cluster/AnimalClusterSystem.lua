-- Local values: AnimalClusterSystem_mt
AnimalClusterSystem = {}
local AnimalClusterSystem_mt = Class(AnimalClusterSystem)

function AnimalClusterSystem.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".animal(?)#subType", "Animal cluster animal sub type name")
	AnimalCluster.registerSavegameXMLPaths(schema, basePath .. ".animal(?)")
end

-- Upvalues: AnimalClusterSystem_mt
-- Local values: self
function AnimalClusterSystem.new(isServer, owner, customMt)
	-- upvalues: (copy) AnimalClusterSystem_mt
	local v7_ = customMt or AnimalClusterSystem_mt
	local v8_ = setmetatable({}, v7_)
	v8_.isServer = isServer
	v8_.owner = owner
	v8_.clusters = {}
	v8_.idToIndex = {}
	v8_.clustersToAdd = {}
	v8_.clustersToRemove = {}
	v8_.needsUpdate = false
	return v8_
end

function AnimalClusterSystem:delete()
	self.clusters = {}
end

-- Local values: numClusters, ids, i, id, subTypeIndex, index, cluster, i, cluster
function AnimalClusterSystem:readStream(streamId, connection)
	local v13_ = {}
	for _ = 1, streamReadUInt16(streamId) do
		local v14_ = streamReadInt32(streamId)
		local v15_ = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
		v13_[v14_] = true
		local v16_ = self.idToIndex[v14_]
		local v17_
		if v16_ == nil then
			v17_ = g_currentMission.animalSystem:createClusterFromSubTypeIndex(v15_)
			v17_.id = v14_
			self:addCluster(v17_)
		else
			v17_ = self.clusters[v16_]
		end
		v17_:readStream(streamId, connection)
	end
	for v18_ = #self.clusters, 1, -1 do
		if v13_[self.clusters[v18_].id] == nil then
			self:removeCluster(v18_)
		end
	end
	self:updateIdMapping()
	g_messageCenter:publish(AnimalClusterUpdateEvent, self.owner, self.clusters)
end

-- Local values: _, cluster
function AnimalClusterSystem:writeStream(streamId, connection)
	streamWriteUInt16(streamId, #self.clusters)
	for _, v22_ in ipairs(self.clusters) do
		streamWriteInt32(streamId, v22_.id)
		streamWriteUIntN(streamId, v22_.subTypeIndex, AnimalCluster.NUM_BITS_SUB_TYPE)
		v22_:writeStream(streamId, connection)
	end
end

-- Local values: i, cluster, animalKey, subType
function AnimalClusterSystem:saveToXMLFile(xmlFile, key, usedModNames)
	for v27_, v28_ in ipairs(self.clusters) do
		local v29_ = string.format("%s.animal(%d)", key, v27_ - 1)
		local v30_ = g_currentMission.animalSystem:getSubTypeByIndex(v28_.subTypeIndex)
		xmlFile:setString(v29_ .. "#subType", v30_.name)
		v28_:saveToXMLFile(xmlFile, v29_, usedModNames)
	end
end

-- Local values: i, animalKey, subTypeName, subType, cluster
function AnimalClusterSystem:loadFromXMLFile(xmlFile, key)
	local v34_ = 0
	while true do
		local v35_ = string.format("%s.animal(%d)", key, v34_)
		if not xmlFile:hasProperty(v35_) then
			break
		end
		local v36_ = xmlFile:getString(v35_ .. "#subType", "")
		local v37_ = g_currentMission.animalSystem:getSubTypeByName(v36_)
		if v37_ == nil then
			Logging.xmlWarning(xmlFile, "SubType \'%s\' not defined. Ignoring animal \'%s\'.", tostring(v36_), v35_)
		else
			local v38_ = g_currentMission.animalSystem:createClusterFromSubTypeIndex(v37_.subTypeIndex)
			if v38_:loadFromXMLFile(xmlFile, v35_) then
				self:addPendingAddCluster(v38_)
			end
		end
		v34_ = v34_ + 1
	end
	self:updateClusters()
	self.needsUpdate = false
end

function AnimalClusterSystem:update(dt)
	if self.isServer and self.needsUpdate then
		self:updateNow()
	end
end

function AnimalClusterSystem:updateNow()
	if self.needsUpdate then
		self:updateClusters()
		self.needsUpdate = false
	end
end

-- Local values: index, cluster
function AnimalClusterSystem:updateIdMapping()
	self.idToIndex = {}
	for v42_, v43_ in ipairs(self.clusters) do
		self.idToIndex[v43_.id] = v42_
	end
end

function AnimalClusterSystem:setDirty()
	self.needsUpdate = true
	self.owner:raiseActive()
end

function AnimalClusterSystem:addPendingAddCluster(cluster)
	local v47_ = self.isServer
	assert(v47_, "AnimalClusterSystem:addPendingAddCluster is a server function")
	self.clustersToAdd[cluster] = true
	self.clustersToRemove[cluster] = nil
	self:setDirty()
end

function AnimalClusterSystem:addPendingRemoveCluster(cluster)
	local v50_ = self.isServer
	assert(v50_, "AnimalClusterSystem:addPendingRemoveCluster is a server function")
	self.clustersToRemove[cluster] = true
	self.clustersToAdd[cluster] = nil
	self:setDirty()
end

function AnimalClusterSystem:addCluster(cluster)
	local v53_ = self.clusters
	table.insert(v53_, cluster)
	cluster.clusterSystem = self
end

-- Local values: cluster
function AnimalClusterSystem:removeCluster(clusterIndex)
	local v56_ = self.clusters[clusterIndex]
	table.remove(self.clusters, clusterIndex)
	v56_.clusterSystem = nil
end

function AnimalClusterSystem:getClusters()
	return self.clusters
end

function AnimalClusterSystem:getCluster(index)
	return self.clusters[index]
end

-- Local values: index
function AnimalClusterSystem:getClusterById(clusterId)
	local v62_ = self.idToIndex[clusterId]
	if v62_ == nil then
		return nil
	else
		return self.clusters[v62_]
	end
end

-- Local values: isDirty, hashToIndex, removedClusterIndices, clusterToAdd, _, clusterIndex, cluster, hash, index, hashedCluster, i, clusterIndexToRemove
function AnimalClusterSystem:updateClusters()
	local v64_ = self.isServer
	assert(v64_, "AnimalClusterSystem:updateClusters is a server function")
	local v65_ = {}
	local v66_ = {}
	local v67_ = false
	for v68_, _ in pairs(self.clustersToAdd) do
		self:addCluster(v68_)
		v67_ = true
	end
	for v69_, v70_ in ipairs(self.clusters) do
		if v70_.isDirty then
			v70_.isDirty = false
			v67_ = true
		end
		if self.clustersToRemove[v70_] == nil and v70_:getNumAnimals() ~= 0 then
			if v70_:getSupportsMerging() then
				local v71_ = v70_:getHash()
				local v72_ = v66_[v71_]
				if v72_ == nil then
					v66_[v71_] = v69_
				else
					self.clusters[v72_]:merge(v70_)
					table.insert(v65_, v69_)
				end
			end
		else
			table.insert(v65_, v69_)
		end
	end
	for v73_ = #v65_, 1, -1 do
		self:removeCluster(v65_[v73_])
		v67_ = true
	end
	if v67_ then
		g_server:broadcastEvent(AnimalClusterUpdateEvent.new(self.owner, self.clusters), true)
		g_messageCenter:publish(AnimalClusterUpdateEvent, self.owner, self.clusters)
	end
	self.clustersToAdd = {}
	self.clustersToRemove = {}
	self:updateIdMapping()
end
