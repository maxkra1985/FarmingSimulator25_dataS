WildlifeUtil = {}

-- Local values: xmlFile, requiredDLC, className, class, species
function WildlifeUtil.createFromXMLFilename(xmlFilename, baseDirectory)
	local v3_ = XMLFile.load("Wildlifespecies", xmlFilename, WildlifeSpecies.xmlSchema)
	if v3_ == nil then
		Logging.warning("Could not load wildlife species config file \'%s\'", xmlFilename)
		return nil
	else
		local v4_ = v3_:getString("species#requiredDLC")
		if v4_ == nil or g_modIsLoaded[g_uniqueDlcNamePrefix .. v4_] ~= nil then
			local v5_ = v3_:getValue("species.class")
			if v5_ == nil then
				Logging.xmlWarning(v3_, "Missing wildlife species class!")
				v3_:delete()
				return nil
			else
				local v6_ = ClassUtil.getClassObject(v5_)
				if v6_ == nil then
					Logging.xmlWarning(v3_, "Wildlife species class \'%s\' not found!", v5_)
					v3_:delete()
					return nil
				else
					local v7_ = v6_.new()
					if v7_:loadFromXML(v3_, baseDirectory) then
						v3_:delete()
						return v7_
					else
						v7_:delete()
						return nil
					end
				end
			end
		else
			v3_:delete()
			return nil
		end
	end
end

-- Local values: availableAngle, randomAngle, angle
function WildlifeUtil.calculateRandomSpawnPosition(x, z, rotY, fovY, distance)
	local v13_ = 6.283185307179586 - fovY
	local v14_ = math.random() * v13_
	local v15_ = rotY + fovY / 2 + v14_
	return x + math.sin(v15_) * distance, z + math.cos(v15_) * distance
end

-- Local values: target
function WildlifeUtil.getNumOfTrees(x, y, z, radius, height, callbackFunc)
	local v_u_24_ = {
		["numTrees"] = 0,
		["onTreeCallback"] = function(_, p22_, _, p23_)
			-- upvalues: (copy) v_u_24_, (copy) callbackFunc
			if p22_ ~= 0 and (getHasClassId(p22_, ClassIds.MESH_SPLIT_SHAPE) and (getSplitType(p22_) ~= 0 and not getIsSplitShapeSplit(p22_))) then
				v_u_24_.numTrees = v_u_24_.numTrees + 1
			end
			if p23_ then
				callbackFunc(v_u_24_.numTrees)
			end
			return true
		end
	}
	overlapCylinderAsync(x, y, z, radius, height, Axis.Y, "onTreeCallback", v_u_24_, CollisionFlag.TREE)
end
