ColorTest = {}
function ColorTest.test_constructor()
	Assert.throwsError(function()
		Color.new({}, 0, 0, 0)
	end, "Red channel accepted invalid type!")
	Assert.throwsError(function()
		Color.new(0, {}, 0, 0)
	end, "Green channel accepted invalid type!")
	Assert.throwsError(function()
		Color.new(0, 0, {}, 0)
	end, "Blue channel accepted invalid type!")
	Assert.throwsError(function()
		Color.new(0, 0, 0, {})
	end, "Alpha channel accepted invalid type!")
	Assert.throwsError(function()
		Color.new(-1, 0, 0, 0)
	end, "Red channel accepted out of range value!")
	Assert.throwsError(function()
		Color.new(2, 0, 0, 0)
	end, "Red channel accepted out of range value!")
	Assert.throwsError(function()
		Color.new(0, -1, 0, 0)
	end, "Green channel accepted out of range value!")
	Assert.throwsError(function()
		Color.new(0, 2, 0, 0)
	end, "Green channel accepted out of range value!")
	Assert.throwsError(function()
		Color.new(0, 0, -1, 0)
	end, "Blue channel accepted out of range value!")
	Assert.throwsError(function()
		Color.new(0, 0, 2, 0)
	end, "Blue channel accepted out of range value!")
	Assert.throwsError(function()
		Color.new(0, 0, 0, -1)
	end, "Alpha channel accepted out of range value!")
	Assert.throwsError(function()
		Color.new(0, 0, 0, 2)
	end, "Alpha channel accepted out of range value!")
end
function ColorTest.test_copy()
	for _, v1_ in pairs(Color.PRESETS) do
		local v2_ = v1_:copy()
		ColorTest.assertColorMatch(v2_, v1_)
		Assert.areNotEqual(tostring(v2_), tostring(v1_), "Color was not copied, but rather returned as-is!")
	end
end
function ColorTest.test_presetNames()
	for v3_, v4_ in pairs(Color.PRESETS) do
		Assert.areEqual(v4_, Color.fromPresetName(v3_), "Preset with name %s could not be found using fromPresetName!", v3_)
		Assert.areEqual(v4_, Color.fromPresetName(string.lower(v3_)), "Preset with name %s could not be found using fromPresetName!", v3_)
	end
end
function ColorTest.test_packedValue()
	local v5_ = Color.fromPackedValue(4294965488):toPackedValue()
	Assert.areEqual(v5_, 4294965488, "Unpacked and packed values do not match!")
	for v6_, v7_ in pairs(Color.PRESETS) do
		local v8_ = v7_:toPackedValue()
		local v9_ = Color.fromPackedValue(v8_)
		Assert.areEqual(v9_:toPackedValue(), v8_, "Unpacked and packed values do not match on preset %s!", v6_)
	end
end
function ColorTest.test_hex()
	for _, v10_ in pairs(Color.PRESETS) do
		local v11_ = v10_:toHex()
		local v12_ = Color.fromHex(v11_)
		ColorTest.assertColorMatch(v12_, v10_)
	end
end
function ColorTest.test_vector4()
	for _, v13_ in pairs(Color.PRESETS) do
		local v14_ = v13_:toVector4()
		local v15_ = Color.fromVector(v14_)
		ColorTest.assertColorMatch(v15_, v13_)
		local v16_, v17_, v18_, v19_ = v15_:unpack()
		Assert.areEqual(v16_, v13_.r, "Red channel mismatch!")
		Assert.areEqual(v17_, v13_.g, "Green channel mismatch!")
		Assert.areEqual(v18_, v13_.b, "Blue channel mismatch!")
		Assert.areEqual(v19_, v13_.a, "Alpha channel mismatch!")
	end
end
function ColorTest.test_RGBA()
	for _, v20_ in pairs(Color.PRESETS) do
		local v21_ = v20_:toVectorRGBA()
		local v22_, v23_, v24_, v25_ = v20_:unpackRGBA()
		local v26_ = Color.fromVectorRGBA(v21_)
		ColorTest.assertColorMatch(v26_, v20_)
		Assert.areEqual(v22_, v21_[1], "Red channel mismatch!")
		Assert.areEqual(v23_, v21_[2], "Green channel mismatch!")
		Assert.areEqual(v24_, v21_[3], "Blue channel mismatch!")
		Assert.areEqual(v25_, v21_[4], "Alpha channel mismatch!")
	end
end
function ColorTest.test_parseFromString()
	for _, v27_ in pairs(Color.PRESETS) do
		local v28_ = Color.parseFromString(string.format("%f %f %f %f", v27_:unpack()))
		Assert.areRoughlyEqual(v28_.r, v27_.r)
		Assert.areRoughlyEqual(v28_.g, v27_.g)
		Assert.areRoughlyEqual(v28_.b, v27_.b)
		Assert.areRoughlyEqual(v28_.a, v27_.a)
		local v29_ = Color.parseFromString("#" .. v27_:toHex())
		Assert.areRoughlyEqual(v29_.r, v27_.r)
		Assert.areRoughlyEqual(v29_.g, v27_.g)
		Assert.areRoughlyEqual(v29_.b, v27_.b)
		Assert.areRoughlyEqual(v29_.a, v27_.a)
	end
	Assert.isNil(Color.parseFromString("0 0"))
	Assert.throwsError(function()
		Color.parseFromString("1.1 0 0")
	end)
	Assert.throwsError(function()
		Color.parseFromString("1 1 1 -0.1")
	end)
end
function ColorTest.test_indexing()
	local v30_ = Color.new(0.2, 0.6, 0.1, 1)
	Assert.areEqual(v30_[1], 0.2, "Red channel mismatch!")
	Assert.areEqual(v30_[2], 0.6, "Green channel mismatch!")
	Assert.areEqual(v30_[3], 0.1, "Blue channel mismatch!")
	Assert.areEqual(v30_[4], 1, "Alpha channel mismatch!")
end
function ColorTest.test_swizzling()
	local v31_ = Color.new(0.2, 0.6, 0.1, 1)
	local v32_ = v31_.rrr
	Assert.areEqual(v32_[1], v31_.r, "Red channel mismatch!")
	Assert.areEqual(v32_[2], v31_.r, "Red channel mismatch!")
	Assert.areEqual(v32_[3], v31_.r, "Red channel mismatch!")
	local v33_ = v31_.ggg
	Assert.areEqual(v33_[1], v31_.g, "Green channel mismatch!")
	Assert.areEqual(v33_[2], v31_.g, "Green channel mismatch!")
	Assert.areEqual(v33_[3], v31_.g, "Green channel mismatch!")
	local v34_ = v31_.bbb
	Assert.areEqual(v34_[1], v31_.b, "Blue channel mismatch!")
	Assert.areEqual(v34_[2], v31_.b, "Blue channel mismatch!")
	Assert.areEqual(v34_[3], v31_.b, "Blue channel mismatch!")
	local v35_ = v31_.aaa
	Assert.areEqual(v35_[1], v31_.a, "Alpha channel mismatch!")
	Assert.areEqual(v35_[2], v31_.a, "Alpha channel mismatch!")
	Assert.areEqual(v35_[3], v31_.a, "Alpha channel mismatch!")
	local v36_ = v31_.rgba
	local v37_ = v31_:toVector4()
	ColorTest.assertColorVectorVectorMatch(v37_, v36_)
end
function ColorTest.test_multiplication()
	local v_u_38_ = Color.new(0.5, 0.5, 0, 1)
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_38_
		local _ = v_u_38_ * {}
	end, "Invalid color multiplication threw no error!")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_38_
		local _ = {} * v_u_38_
	end, "Invalid color multiplication threw no error!")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_38_
		local _ = v_u_38_ * ""
	end, "Invalid color multiplication threw no error!")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_38_
		local _ = "" * v_u_38_
	end, "Invalid color multiplication threw no error!")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_38_
		local _ = v_u_38_ * nil
	end, "Invalid color multiplication threw no error!")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_38_
		local _ = nil * v_u_38_
	end, "Invalid color multiplication threw no error!")
	for _, v39_ in pairs(Color.PRESETS) do
		local v40_ = {
			0.5,
			0.2,
			0.7,
			1
		}
		local v41_ = v39_ * 0.75
		local v42_ = v39_ * v40_
		ColorTest.assertColorRGBAMatch(v41_, v39_.r * 0.75, v39_.g * 0.75, v39_.b * 0.75, v39_.a * 0.75)
		ColorTest.assertColorRGBAMatch(v42_, v39_.r * v40_[1], v39_.g * v40_[2], v39_.b * v40_[3], v39_.a * v40_[4])
		local v43_ = 0.75 * v39_
		local v44_ = v40_ * v39_
		ColorTest.assertColorRGBAMatch(v43_, v39_.r * 0.75, v39_.g * 0.75, v39_.b * 0.75, v39_.a * 0.75)
		ColorTest.assertColorRGBAMatch(v44_, v39_.r * v40_[1], v39_.g * v40_[2], v39_.b * v40_[3], v39_.a * v40_[4])
	end
end

function ColorTest.assertColorMatch(actual, expected)
	Assert.isNotNil(actual, "Color was nil!")
	Assert.areRoughlyEqual(actual.r, expected.r, nil, "Red channel mismatch!")
	Assert.areRoughlyEqual(actual.g, expected.g, nil, "Green channel mismatch!")
	Assert.areRoughlyEqual(actual.b, expected.b, nil, "Blue channel mismatch!")
	Assert.areRoughlyEqual(actual.a, expected.a, nil, "Alpha channel mismatch!")
end

function ColorTest.assertColorVectorVectorMatch(actualVector, expectedVector)
	Assert.isNotNil(actualVector, "Color vector was nil!")
	Assert.areRoughlyEqual(actualVector[1], expectedVector[1], nil, "Red channel mismatch!")
	Assert.areRoughlyEqual(actualVector[2], expectedVector[2], nil, "Green channel mismatch!")
	Assert.areRoughlyEqual(actualVector[3], expectedVector[3], nil, "Blue channel mismatch!")
	Assert.areRoughlyEqual(actualVector[4], expectedVector[4], nil, "Alpha channel mismatch!")
end

function ColorTest.assertColorVectorMatch(actual, expectedVector)
	Assert.isNotNil(actual, "Color was nil!")
	Assert.areRoughlyEqual(actual.r, expectedVector[1], nil, "Red channel mismatch!")
	Assert.areRoughlyEqual(actual.g, expectedVector[2], nil, "Green channel mismatch!")
	Assert.areRoughlyEqual(actual.b, expectedVector[3], nil, "Blue channel mismatch!")
	Assert.areRoughlyEqual(actual.a, expectedVector[4], nil, "Alpha channel mismatch!")
end

function ColorTest.assertColorRGBAMatch(actual, expectedR, expectedG, expectedB, expectedA)
	Assert.isNotNil(actual, "Color was nil!")
	Assert.areRoughlyEqual(actual.r, expectedR, nil, "Red channel mismatch!")
	Assert.areRoughlyEqual(actual.g, expectedG, nil, "Green channel mismatch!")
	Assert.areRoughlyEqual(actual.b, expectedB, nil, "Blue channel mismatch!")
	Assert.areRoughlyEqual(actual.a, expectedA, nil, "Alpha channel mismatch!")
end
