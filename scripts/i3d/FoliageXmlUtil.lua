FoliageXmlUtil = {}

-- Local values: name, numChannels, numTypeIndexChannels, numLayers, i, layerIndex, layerName, typeIndex, shapeSource, channelOffset, layerNumChannels, cellSize, objectMask, decalLayer, maxStates, numStates, j, stateIndex, stateName, filename, layer, w, wv, h, hv, hpv, numShapes, blocksPerUnit, k, shapeIndex, numLods, l, lodIndex, viewDistance, shape, atlasSize, aoffx, aoffy, u0, v0, u1, v1
function FoliageXmlUtil.printFoliageCtor(ctor)
	local v2_ = ctor:getName()
	local v3_, v4_ = ctor:getDensityMapInfo()
	local v5_ = ctor:getNumLayers()
	print("Name: " .. v2_)
	print("Density Map: BPP " .. v3_ .. " TYPE " .. v4_)
	print("Num layers: " .. v5_)
	for v6_ = 1, v5_ do
		local v7_ = v6_ - 1
		local v8_ = ctor:getNameForLayer(v7_)
		local v9_ = ctor:getTypeIndexForLayer(v7_)
		local v10_ = ctor:getShapeSourceForLayer(v7_)
		local v11_, v12_ = ctor:getDensityChannelsForLayer(v7_)
		local v13_ = ctor:getCellSizeForLayer(v7_)
		local v14_ = ctor:getObjectMaskForLayer(v7_)
		local v15_ = ctor:getDecalLayerForLayer(v7_)
		local v16_ = ctor:getMaxNumStatesForLayer(v7_)
		local v17_ = ctor:getNumStatesForLayer(v7_)
		print("Layer " .. v7_ .. ":")
		print("  Name: " .. v8_)
		print("  Type index: " .. v9_)
		print("  Shape Source: " .. tostring(v10_))
		print("  Density map: CH off " .. v11_ .. " BPP " .. v12_)
		print("  Cell size: " .. v13_)
		print("  Object mask: " .. v14_)
		print("  Decal layer: " .. v15_)
		print("  Max states: " .. v16_)
		print("  Num states: " .. v17_)
		for v18_ = 1, v17_ do
			local v19_ = v18_ - 1
			local v20_ = ctor:getNameForState(v7_, v19_)
			local v21_, v22_ = ctor:getDistanceMapForState(v7_, v19_)
			local v23_, v24_ = ctor:getWidthAndVarianceForState(v7_, v19_)
			local v25_, v26_ = ctor:getHeightAndVarianceForState(v7_, v19_)
			local v27_ = ctor:getPositionVarianceForState(v7_, v19_)
			local v28_ = ctor:getNumShapesForState(v7_, v19_)
			local v29_ = ctor:getBlocksPerUnitForState(v7_)
			print("  State " .. v19_ .. ":")
			print("    Name: " .. v20_)
			print("    Distance map: " .. v21_ .. " layer " .. v22_)
			print("    Width: " .. v23_ .. " var " .. v24_)
			print("    Height: " .. v25_ .. " var " .. v26_)
			print("    Pos var: " .. v27_)
			print("    Num shapes: " .. v28_)
			print("    Blocks per unit " .. v29_)
			for v30_ = 1, v28_ do
				local v31_ = v30_ - 1
				for v32_ = 1, ctor:getNumLodsForShape(v7_, v19_, v31_) do
					local v33_ = v32_ - 1
					local v34_ = ctor:getViewDistanceForLod(v7_, v19_, v31_, v33_)
					local v35_ = ctor:getShapeForLod(v7_, v19_, v31_, v33_)
					local v36_ = ctor:getAtlasSizeForLod(v7_, v19_, v31_, v33_)
					local v37_, v38_ = ctor:getAtlasOffsetForLod(v7_, v19_, v31_, v33_)
					local v39_, v40_, v41_, v42_ = ctor:getTexCoordsForLod(v7_, v19_, v31_, v33_)
					print("    Lod " .. v33_)
					print("      ViewDistance " .. tostring(v34_))
					print("      Shape " .. tostring(v35_))
					print("      Atlas size: " .. v36_)
					print("      Atlas offset: " .. v37_ .. " " .. v38_)
					print("      Tex coords: " .. v39_ .. " " .. v40_ .. " " .. v41_ .. " " .. v42_)
				end
			end
		end
	end
end
