UtilsTest = {}
function UtilsTest.test_getUniqueIdGeneration()
	local v1_ = {}
	for _ = 1, 10000 do
		local v2_ = Utils.getUniqueId({}, v1_, nil)
		Assert.hasNoKey(v1_, v2_, "Generated id was not unique!")
		v1_[v2_] = v2_
	end
end
function UtilsTest.test_getUniqueIdLength()
	for v3_ = 1, 32 do
		local v4_ = Utils.getUniqueId({}, {}, nil, v3_)
		Assert.areEqual(string.len(v4_), v3_, "Unique ID length was not the requested length!")
	end
end
function UtilsTest.test_getUniqueIdPrefix()
	local v5_ = Utils.getUniqueId({}, {}, "test")
	Assert.isTrue(string.startsWith(v5_, "test"), string.format("Unique id %s does not begin with prefix %s!", tostring(v5_), "test"))
end
function UtilsTest.test_compareVersions()
	Assert.areEqual(Utils.compareVersions({}, {}), 0)
	Assert.areEqual(Utils.compareVersions({}, {}), 0)
	Assert.areEqual(Utils.compareVersions({ 1 }, { 2 }), -1)
	Assert.areEqual(Utils.compareVersions({ 2 }, { 1 }), 1)
	Assert.areEqual(Utils.compareVersions({ 1, 2 }, { 1, 1 }), 1)
	Assert.areEqual(Utils.compareVersions({ 1, 1 }, { 1, 2 }), -1)
	Assert.areEqual(Utils.compareVersions({ 0, 9 }, { 1, 0 }), -1)
	Assert.areEqual(Utils.compareVersions({ 10, 9 }, { 2, 0 }), 1)
	Assert.areEqual(Utils.compareVersions({
		9,
		0,
		0,
		0
	}, {
		0,
		5,
		9,
		9
	}), 1)
	Assert.areEqual(Utils.compareVersions({
		1,
		0,
		0,
		1
	}, {
		1,
		0,
		0,
		0
	}), 1)
	Assert.areEqual(Utils.compareVersions({
		1,
		0,
		0,
		1
	}, { 1, 0, 0 }), 0)
end
function UtilsTest.test_compareVersionStrings()
	Assert.areEqual(Utils.compareVersionStrings("", ""), 0)
	Assert.areEqual(Utils.compareVersionStrings(".", ""), 0)
	Assert.areEqual(Utils.compareVersionStrings("", "."), 0)
	Assert.areEqual(Utils.compareVersionStrings("..", ""), 0)
	Assert.areEqual(Utils.compareVersionStrings("", ".."), 0)
	Assert.areEqual(Utils.compareVersionStrings("a", ""), 0)
	Assert.areEqual(Utils.compareVersionStrings("", "b"), 0)
	Assert.areEqual(Utils.compareVersionStrings("a", "b"), 0)
	Assert.areEqual(Utils.compareVersionStrings("b", "a"), 0)
	Assert.areEqual(Utils.compareVersionStrings("1", ""), 1)
	Assert.areEqual(Utils.compareVersionStrings("", "1"), -1)
	Assert.areEqual(Utils.compareVersionStrings("\195\182", "\195\164"), 0)
	Assert.areEqual(Utils.compareVersionStrings("\n.\195\182", "\195\164\n"), 0)
	Assert.areEqual(Utils.compareVersionStrings("1", "1"), 0)
	Assert.areEqual(Utils.compareVersionStrings("1", "2"), -1)
	Assert.areEqual(Utils.compareVersionStrings("2", "1"), 1)
	Assert.areEqual(Utils.compareVersionStrings("1.0.0.0", "1.0.0.0"), 0)
	Assert.areEqual(Utils.compareVersionStrings("2.0.0.0", "1.0.0.0"), 1)
	Assert.areEqual(Utils.compareVersionStrings("1.0.0.0", "2.0.0.0"), -1)
	Assert.areEqual(Utils.compareVersionStrings("1.2.0.0", "2.1.0.0"), -1)
	Assert.areEqual(Utils.compareVersionStrings("1.0.0.1", "1.0.0.0"), 1)
	Assert.areEqual(Utils.compareVersionStrings("10.0.0.0", "10.0.0.0"), 0)
	Assert.areEqual(Utils.compareVersionStrings("12.0.0.0", "10.0.0.0"), 1)
	Assert.areEqual(Utils.compareVersionStrings("1.0.0.0", "20.0.0.0"), -1)
	Assert.areEqual(Utils.compareVersionStrings("0.5.0.0", "2.0.0.0"), -1)
	Assert.areEqual(Utils.compareVersionStrings("2.5.0.0", "0.5.0.0"), 1)
	Assert.areEqual(Utils.compareVersionStrings("2.5.0.0", "2.5"), 0)
	Assert.areEqual(Utils.compareVersionStrings("2.5.0", "2.5.0.0"), 0)
	Assert.areEqual(Utils.compareVersionStrings("2.5.1.0", "2.5.0"), 1)
	Assert.areEqual(Utils.compareVersionStrings("2.5.1", "2.5.0.0"), 1)
	Assert.areEqual(Utils.compareVersionStrings("2.5.0.0", "2.5.1"), -1)
	Assert.areEqual(Utils.compareVersionStrings("2.5.0", "2.5.1.0"), -1)
	Assert.areEqual(Utils.compareVersionStrings("2.5.0.1", "2.5.1"), -1)
	Assert.areEqual(Utils.compareVersionStrings("2.5.0", "2.5.0.1"), 0)
	Assert.areEqual(Utils.compareVersionStrings("02.5.0.0", "2.5.0.1"), -1)
	Assert.areEqual(Utils.compareVersionStrings("02.05.1", "2.05.0.1"), 1)
	Assert.areEqual(Utils.compareVersionStrings("-2.5.0.0", "2.5.0.1"), -1)
	Assert.areEqual(Utils.compareVersionStrings("--2.-5.1.0", "2.5.0.1"), 1)
	Assert.areEqual(Utils.compareVersionStrings("v2.0.3.0", "2.0.3.1"), -1)
	Assert.areEqual(Utils.compareVersionStrings("2.0.3.0", "2.0.3.1beta"), -1)
	Assert.areEqual(Utils.compareVersionStrings("version1.2", "version2.10"), -1)
end
