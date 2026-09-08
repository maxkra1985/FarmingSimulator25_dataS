-- Local values: animalCounter, visibleAnimals, subTypes
print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
local animalCounter = 0
local visibleAnimals = {}
local subTypes = {}
local v4_ = {
	["visuals"] = {
		{
			["minAge"] = 0,
			["animalTypeIndex"] = 1
		},
		{
			["minAge"] = 5,
			["animalTypeIndex"] = 2
		},
		{
			["minAge"] = 10,
			["animalTypeIndex"] = 3
		}
	}
}
subTypes[1] = v4_
local v5_ = {
	["visuals"] = {
		{
			["minAge"] = 0,
			["animalTypeIndex"] = 4
		},
		{
			["minAge"] = 5,
			["animalTypeIndex"] = 5
		},
		{
			["minAge"] = 10,
			["animalTypeIndex"] = 6
		}
	}
}
subTypes[2] = v5_
local v6_ = {
	["visuals"] = {
		{
			["minAge"] = 0,
			["animalTypeIndex"] = 7
		},
		{
			["minAge"] = 5,
			["animalTypeIndex"] = 8
		},
		{
			["minAge"] = 10,
			["animalTypeIndex"] = 9
		}
	}
}
subTypes[3] = v6_
local v13_ = {
	["animalNameSystem"] = {
		["getRandomName"] = function(_)
			return "AnimalName" .. math.random(1, 123123)
		end
	},
	["animalSystem"] = {
		["getSubTypeByIndex"] = function(_, p7_)
			-- upvalues: (copy) subTypes
			return subTypes[p7_]
		end,
		["getAnimalTypeIndexByAge"] = function(_, p8_, p9_)
			-- upvalues: (copy) subTypes
			local v10_ = subTypes[p8_]
			local v11_ = nil
			for _, v12_ in ipairs(v10_.visuals) do
				if v12_.minAge <= p9_ then
					v11_ = v12_.animalTypeIndex
				end
			end
			return v11_
		end
	}
}
_G.g_currentMission = v13_
function createAnimalHusbandry(...)
	log("create husbandry", ...)
	return 1
end
function addHusbandryAnimal(_, p14_)
	-- upvalues: (ref) animalCounter, (copy) visibleAnimals
	animalCounter = animalCounter + 1
	local v15_ = {
		["animalId"] = animalCounter,
		["animalTypeIndex"] = p14_ + 1
	}
	local v16_ = visibleAnimals
	table.insert(v16_, v15_)
	log("Added animal", animalCounter, p14_ + 1)
	return animalCounter
end
function removeHusbandryAnimal(_, p17_)
	-- upvalues: (copy) visibleAnimals
	for v18_ = 1, #visibleAnimals do
		if visibleAnimals[v18_].animalId == p17_ then
			table.remove(visibleAnimals, v18_)
			log("remove animal", p17_)
			return
		end
	end
	printCallstack()
end
TestAnimalCluster = {}
TestAnimalCluster.CURRENT_SELECTION_INDEX = 1
function TestAnimalCluster.init()
	_G.g_server = {
		["broadcastEvent"] = function() end
	}
	local v_u_19_ = TestAnimalCluster
	v_u_19_.clusterSystem = AnimalClusterSystem.new(true, v_u_19_)
	v_u_19_.clusterSystem:addClustersUpdatedListener(function()
		-- upvalues: (copy) v_u_19_
		local v20_ = v_u_19_.clusterSystem:getClusters()
		v_u_19_.animalClusterHusbandry:setClusters(v20_)
	end)
	v_u_19_.animalClusterHusbandry = AnimalClusterHusbandry.new("horse", 12)
	v_u_19_.animalClusterHusbandry:create("testXML", 1, 1, 255)
end

-- Local values: self
function TestAnimalCluster.update(dt)
	TestAnimalCluster.clusterSystem:update(dt)
end
function TestAnimalCluster.draw()
	-- upvalues: (copy) visibleAnimals
	local v22_ = TestAnimalCluster
	local v23_ = v22_.clusterSystem:getClusters()
	local v24_ = {}
	local v25_ = 0
	for v26_, v27_ in ipairs(v23_) do
		table.insert(v24_, v27_)
		local v28_ = g_currentMission.animalSystem:getVisualAnimalIndexByAge(v27_.subTypeIndex, v27_:getAge())
		local v29_ = {}
		for v30_, v31_ in pairs(v22_.animalClusterHusbandry.animalIdToCluster) do
			if v27_ == v31_ then
				table.insert(v29_, v30_)
			end
		end
		local v32_ = table.concat(v29_, ", ")
		renderText(0.5, 0.8 - (v26_ - 1) * 0.013, 0.012, string.format("Cluster: %02d  |  Animals: %03d  |  Age: %02d  |  Health: %03d  |  Reproduction: %03d  |  Hash: %s | TypeIndex: %d | AnimalIds: %s", v27_.id, v27_.numAnimals, v27_.age, v27_.health, v27_.reproduction, v27_:getHash(), v28_, v32_))
		v25_ = v25_ + v27_.numAnimals
	end
	if #v23_ > 0 then
		renderText(0.495, 0.8 - (TestAnimalCluster.CURRENT_SELECTION_INDEX - 1) * 0.013, 0.012, ">")
	end
	renderText(0.5, 0.9, 0.012, string.format("Total Num Animals: %d", v25_))
	renderText(0.02, 0.9, 0.012, string.format("Total Num Visible Animals: %d", #visibleAnimals))
	for v33_, v34_ in ipairs(visibleAnimals) do
		local v35_ = v22_.animalClusterHusbandry.animalIdToCluster[v34_.animalId]
		local v36_ = v35_ == nil and "-" or string.format("%02d", v35_.id)
		renderText(0.02, 0.8 - (v33_ - 1) * 0.013, 0.012, string.format("AnimalId: %02d  |  TypeIndex: %d | Cluster: %s", v34_.animalId, v34_.animalTypeIndex, v36_))
	end
	local v37_ = 1
	for v38_, v39_ in pairs(v22_.animalClusterHusbandry.totalNumAnimalsPerAnimalTypeIndex) do
		renderText(0.2, 0.8 - (v37_ - 1) * 0.013, 0.012, string.format("TypeIndex: %d | Num: %d", v38_, v39_))
		v37_ = v37_ + 1
	end
	table.sort(v24_, AnimalClusterHusbandry.sortClusters)
	for v40_, v41_ in ipairs(v24_) do
		local v42_ = g_currentMission.animalSystem:getVisualAnimalIndexByAge(v41_.subTypeIndex, v41_:getAge())
		renderText(0.35, 0.8 - (v40_ - 1) * 0.013, 0.012, string.format("Cluster: %03d | Num: %d | TypeIndex: %d", v41_.id, v41_:getNumAnimals(), v42_))
	end
end

function TestAnimalCluster.mouseEvent(posX, posY, isDown, isUp, button) end

-- Local values: self, clusters, currentCluster, allModifier, cluster, i, cluster, i, cluster, i, cluster, i, cluster, i, cluster
function TestAnimalCluster.keyEvent(unicode, sym, modifier, isDown)
	if not isDown then
		local v46_ = TestAnimalCluster
		local v47_ = v46_.clusterSystem:getClusters()
		local v48_ = TestAnimalCluster
		local v49_ = TestAnimalCluster.CURRENT_SELECTION_INDEX
		local v50_ = #v47_
		local v51_ = math.min(v49_, v50_)
		v48_.CURRENT_SELECTION_INDEX = math.max(v51_, 1)
		local v52_ = v47_[TestAnimalCluster.CURRENT_SELECTION_INDEX]
		local v53_ = Input.MOD_LSHIFT
		local v54_ = bit32.band(modifier, v53_) > 0
		if sym == Input.KEY_m then
			if v54_ or #v47_ == 0 then
				local v55_ = v46_.clusterSystem:createCluster()
				v55_.numAnimals = 1
				v55_.subTypeIndex = math.random(1, 3)
				v46_.clusterSystem:addPendingAddCluster(v55_)
			elseif v52_ ~= nil then
				v52_.numAnimals = v52_.numAnimals + 1
				v46_.animalClusterHusbandry:setClusters(v47_)
			end
		elseif sym == Input.KEY_n then
			if v52_ ~= nil then
				v46_.clusterSystem:addPendingRemoveCluster(v52_)
			end
		elseif sym == Input.KEY_q then
			if v54_ then
				for _, v56_ in ipairs(v47_) do
					v56_:changeAge(1)
				end
			elseif v52_ ~= nil then
				v52_:changeAge(1)
			end
			v46_.animalClusterHusbandry:setClusters(v47_)
		elseif sym == Input.KEY_w then
			if v54_ then
				for _, v57_ in ipairs(v47_) do
					v57_:changeHealth(1)
				end
			elseif v52_ ~= nil then
				v52_:changeHealth(1)
			end
			v46_.animalClusterHusbandry:setClusters(v47_)
		elseif sym == Input.KEY_e then
			if v54_ then
				for _, v58_ in ipairs(v47_) do
					v58_:changeHealth(-1)
				end
			elseif v52_ ~= nil then
				v52_:changeHealth(-1)
			end
			v46_.animalClusterHusbandry:setClusters(v47_)
		elseif sym == Input.KEY_s then
			if v54_ then
				for _, v59_ in ipairs(v47_) do
					v59_:changeReproduction(1)
				end
			elseif v52_ ~= nil then
				v52_:changeReproduction(1)
			end
			v46_.animalClusterHusbandry:setClusters(v47_)
		elseif sym == Input.KEY_d then
			if v54_ then
				for _, v60_ in ipairs(v47_) do
					v60_:changeReproduction(-1)
				end
			elseif v52_ ~= nil then
				v52_:changeReproduction(-1)
			end
			v46_.animalClusterHusbandry:setClusters(v47_)
		elseif sym == Input.KEY_up then
			TestAnimalCluster.CURRENT_SELECTION_INDEX = TestAnimalCluster.CURRENT_SELECTION_INDEX - 1
		elseif sym == Input.KEY_down then
			TestAnimalCluster.CURRENT_SELECTION_INDEX = TestAnimalCluster.CURRENT_SELECTION_INDEX + 1
		end
		local v61_ = TestAnimalCluster
		local v62_ = TestAnimalCluster.CURRENT_SELECTION_INDEX
		local v63_ = #v47_
		local v64_ = math.min(v62_, v63_)
		v61_.CURRENT_SELECTION_INDEX = math.max(v64_, 1)
		v46_.clusterSystem:setDirty()
	end
end
