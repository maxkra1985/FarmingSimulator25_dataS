WildlifeUtil = {}
function WildlifeUtil.createFromXMLFilename(xmlFilename, baseDirectory)
	local xmlFile = XMLFile.load("Wildlifespecies", xmlFilename, WildlifeSpecies.xmlSchema)
	if xmlFile == nil then
		Logging.warning("Could not load wildlife species config file '%s'", xmlFilename)
		return nil
	end
	local requiredDLC = xmlFile:getString("species#requiredDLC")
	if requiredDLC ~= nil and g_modIsLoaded[g_uniqueDlcNamePrefix .. requiredDLC] == nil then
		xmlFile:delete()
		return nil
	end
	local className = xmlFile:getValue("species.class")
	if className == nil then
		Logging.xmlWarning(xmlFile, "Missing wildlife species class!")
		xmlFile:delete()
		return nil
	end
	local class = ClassUtil.getClassObject(className)
	if class == nil then
		Logging.xmlWarning(xmlFile, "Wildlife species class '%s' not found!", className)
		xmlFile:delete()
		return nil
	end
	local species = class.new()
	if not species:loadFromXML(xmlFile, baseDirectory) then
		species:delete()
		return nil
	else
		xmlFile:delete()
		return species
	end
end
function WildlifeUtil.calculateRandomSpawnPosition(x, z, rotY, fovY, distance)
	local availableAngle = 6.283185307179586 - fovY
	local randomAngle = math.random() * availableAngle
	local angle = rotY + fovY / 2 + randomAngle
	return x + math.sin(angle) * distance, z + math.cos(angle) * distance
end
function WildlifeUtil.getNumOfTrees(x, y, z, radius, height, callbackFunc)
	local target = {}
	target.numTrees = 0
	function target.onTreeCallback(_, transformId, subShapeIndex, isLast)
		if transformId ~= 0 and getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) then
			local splitType = getSplitType(transformId)
			if splitType ~= 0 and not getIsSplitShapeSplit(transformId) then
				target.numTrees = target.numTrees + 1
			end
		end
		if isLast then
			callbackFunc(target.numTrees)
		end
		return true
	end
	overlapCylinderAsync(x, y, z, radius, height, Axis.Y, "onTreeCallback", target, CollisionFlag.TREE)
end
