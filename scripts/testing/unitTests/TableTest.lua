-- Local values: standardLuaFunctions, k
TableTest = {}
function TableTest.test_addElement()
	Assert.throwsError(function()
		table.addElement(nil, 1)
	end, "Nil as table argument does not raise an error")
	for _, v1_ in ipairs({
		true,
		false,
		-1,
		0,
		1,
		math.huge,
		"",
		" ",
		"\n",
		"1",
		{}
	}) do
		local v2_ = {}
		local v3_, v4_ = table.addElement(v2_, v1_)
		Assert.isTrue(v3_, "element \'%s\' of type %s was not added to the table", v1_, (type(v1_)))
		Assert.areEqual(v4_, 1)
		local v5_, v6_ = table.addElement(v2_, v1_)
		Assert.isFalse(v5_)
		Assert.areEqual(v6_, 1)
	end
	local v7_ = {}
	table.addElement(v7_, "test")
	table.clear(v7_)
	local v8_, v9_ = table.addElement(v7_, "test")
	Assert.isTrue(v8_)
	Assert.areEqual(v9_, 1)
end
function TableTest.test_removeElement()
	Assert.throwsError(function()
		table.removeElement(nil, 1)
	end, "Nil as table argument does not raise an error")
	Assert.isFalse(table.removeElement({}, "element"))
	local v10_ = { "element", "element" }
	Assert.isTrue(table.removeElement(v10_, "element"))
	Assert.isTrue(table.removeElement(v10_, "element"))
	Assert.isFalse(table.removeElement(v10_, "element"))
	for _, v11_ in ipairs({
		true,
		false,
		-1,
		0,
		1,
		math.huge,
		"",
		" ",
		"\n",
		"1",
		{}
	}) do
		local v12_ = {}
		table.addElement(v12_, v11_)
		Assert.isTrue(table.removeElement(v12_, v11_))
	end
end
function TableTest.test_hasElement()
	Assert.throwsError(function()
		table.hasElement(nil, 1)
	end, "Nil as table argument does not raise an error")
	Assert.isFalse(table.hasElement({}, "element"))
	Assert.isFalse(table.hasElement({ "a" }, "b"))
	local v13_ = { "element", "element" }
	Assert.isTrue(table.hasElement(v13_, "element"))
	table.remove(v13_, 1)
	Assert.isTrue(table.hasElement(v13_, "element"))
	table.remove(v13_, 1)
	Assert.isFalse(table.hasElement(v13_, "element"))
end
function TableTest.test_isList()
	Assert.throwsError(function()
		table.isList(nil)
	end, "Nil as table argument does not raise an error")
	Assert.isTrue(table.isList({}))
	Assert.isTrue(table.isList({ "a", "b", "c" }))
	Assert.isFalse(table.isList({
		["a"] = "a",
		"b",
		"c"
	}))
	Assert.isFalse(table.isList({
		[0] = "a",
		[1] = "b",
		[2] = "c"
	}))
	Assert.isFalse(table.isList({
		[2] = "a",
		[3] = "b",
		[4] = "c"
	}))
	Assert.isFalse(table.isList({
		[1] = "a",
		[3] = "b",
		[4] = "c"
	}))
	Assert.isFalse(table.isList({
		"a",
		"b",
		"c",
		[2] = nil
	}))
	local v14_ = { "a", "b", "c" }
	table.remove(v14_, 1)
	Assert.isTrue(table.isList(v14_))
end
function TableTest.test_clone()
	Assert.throwsError(function()
		table.clone(nil)
	end, "Nil as table argument does not raise an error")
	local v15_ = {}
	Assert.areNotEqual(table.clone(v15_), v15_)
	local v16_ = {
		["innerTbl"] = {}
	}
	local v17_ = table.clone(v16_)
	Assert.areEqual(v17_.innerTbl, v16_.innerTbl)
	local v18_ = table.clone(v16_, 2)
	Assert.areNotEqual(v18_.innerTbl, v16_.innerTbl)
	local v19_ = {
		true,
		false,
		-1,
		0,
		1,
		math.huge,
		"",
		" ",
		"\n",
		"1",
		{}
	}
	local v20_ = table.clone(v19_, 1)
	for v21_, v22_ in ipairs(v19_) do
		Assert.areEqual(v20_[v21_], v22_, "cloned value \'%s\' is not equal to source \'%s\'", v20_[v21_], v22_)
	end
	local v23_ = table.clone(v16_, math.huge)
	Assert.areNotEqual(v23_.innerTbl, v16_.innerTbl, "sub tables of clone are identical with source when depth=math.huge")
	Assert.throwsError(function()
		table.clone({}, true)
	end, "Boolean depth argument does not raise an error")
	Assert.throwsError(function()
		table.clone({}, -1)
	end, "Negative depth argument does not raise an error")
	local v_u_24_ = {
		["a"] = {}
	}
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_24_
		table.clone(v_u_24_, true)
	end, "Boolean value for \'depth\' argument does not raise an error")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_24_
		table.clone(v_u_24_, {})
	end, "Table value for \'depth\' argument does not raise an error")
	Assert.throwsError(function()
		-- upvalues: (copy) v_u_24_
		table.clone(v_u_24_, "yes")
	end, "String value for \'depth\' argument does not raise an error")
end
function TableTest.test_size()
	Assert.throwsError(function()
		table.size(nil)
	end, "Nil as table argument does not raise an error")
	Assert.areEqual(table.size({}), 0)
	Assert.areEqual(table.size({ "a" }), 1)
	Assert.areEqual(table.size({ nil }), 0)
	Assert.areEqual(table.size({
		["a"] = "a"
	}), 1)
	Assert.areEqual(table.size({
		["a"] = "a",
		"b"
	}), 2)
end
function TableTest.test_getRandomElement()
	Assert.throwsError(function()
		table.getRandomElement(nil)
	end, "Nil as table argument does not raise an error")
	Assert.isNil(table.getRandomElement({}))
	Assert.areEqual(table.getRandomElement({ "a" }), "a")
	local v25_ = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g"
	}
	local v26_ = {}
	for _, v27_ in ipairs(v25_) do
		v26_[v27_] = true
	end
	for v28_ = 1, 100000 do
		v26_[table.getRandomElement(v25_)] = nil
		if table.size(v26_) == 0 then
			break
		end
		if v28_ == 10000 then
			Assert.areEqual(table.size(v26_), 0)
		end
	end
end
function TableTest.test_copyIndex()
	Assert.throwsError(function()
		table.copyIndex(nil)
	end, "Nil as table argument does not raise an error")
	local v29_ = {
		["a"] = 1,
		["b"] = 2
	}
	local v30_ = table.copyIndex(v29_)
	Assert.areEqual(#v30_, 0)
	Assert.areNotEqual(#v30_, table.size(v29_))
	Assert.isTrue(table.isList(v30_))
	local v31_ = { "a", "b", "c" }
	local v32_ = table.copyIndex(v31_)
	Assert.areEqual(#v31_, #v32_)
	Assert.isTrue(table.isList(v32_))
	local v33_ = {
		"a",
		"b",
		"c",
		["test"] = 4
	}
	local v34_ = table.copyIndex(v33_)
	Assert.areEqual(#v33_, #v34_)
	Assert.areNotEqual(#v34_, table.size(v33_))
	Assert.isTrue(table.isList(v34_))
end
function TableTest.test_toList()
	Assert.throwsError(function()
		table.toList(nil)
	end, "Nil as table argument does not raise an error")
	local v35_ = {
		["a"] = "",
		["b"] = "",
		["c"] = ""
	}
	local v36_ = table.toList(v35_)
	Assert.areEqual(table.size(v35_), #v36_)
	for v37_ in pairs(v35_) do
		Assert.isTrue(table.hasElement(v36_, v37_))
	end
end
function TableTest.test_toSet()
	Assert.throwsError(function()
		table.toSet(nil)
	end, "Nil as table argument does not raise an error")
	local v38_ = { "a", "b", "c" }
	local v39_ = table.toSet(v38_)
	Assert.areEqual(table.size(v39_), #v38_)
	for v40_ in pairs(v39_) do
		Assert.isTrue(table.hasElement(v38_, v40_))
	end
	local v41_ = table.toSet({
		"a",
		"b",
		"a",
		"c",
		"c"
	})
	Assert.areEqual(table.size(v41_), 3)
end
function TableTest.test_ifilter()
	Assert.throwsError(function()
		table.ifilter(nil, function(p42_)
			return p42_
		end)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.ifilter({}, nil)
	end, "Nil as closure argument does not raise an error")
	local v43_ = {
		"a",
		"b",
		"c",
		"d"
	}
	local v45_ = table.ifilter(v43_, function(p44_, _)
		return p44_ ~= "b"
	end)
	Assert.areEqual(#v45_, 3)
	Assert.isFalse(table.hasElement(v45_, "b"))
	Assert.areEqual(#v43_, 4)
	Assert.isTrue(table.hasElement(v43_, "b"))
	local v46_ = table.ifilter(v43_, function()
		return false
	end)
	Assert.areEqual(#v46_, 0)
	local v47_ = table.ifilter(v43_, function()
		return true
	end)
	Assert.areEqual(#v47_, #v43_)
	local v48_ = {
		"a",
		"b",
		"c",
		["c"] = true,
		["key1"] = "a",
		["key2"] = "b"
	}
	local v50_ = table.ifilter(v48_, function(p49_, _)
		return p49_ ~= "b"
	end)
	Assert.areEqual(#v50_, 2)
	Assert.areEqual(table.size(v50_), #v50_)
	Assert.isFalse(table.hasElement(v50_, "b"))
	local v51_ = table.ifilter(v48_, function()
		return true
	end)
	Assert.areEqual(#v51_, #v48_)
	Assert.areNotEqual(#v51_, table.size(v48_))
end
function TableTest.test_filter()
	Assert.throwsError(function()
		table.filter(nil, function(p52_)
			return p52_
		end)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.filter({}, nil)
	end, "Nil as closure argument does not raise an error")
	local v53_ = {
		"a",
		"b",
		"c",
		["c"] = true
	}
	local v55_ = table.filter(v53_, function(p54_, _)
		return p54_ ~= "b"
	end)
	Assert.areEqual(table.size(v55_), 3)
	Assert.isNil(v55_.b)
	Assert.areEqual(table.size(v53_), 4)
	Assert.isTrue(table.hasElement(v53_, "b"))
	local v56_ = table.filter(v53_, function()
		return false
	end)
	Assert.areEqual(table.size(v56_), 0)
	local v57_ = table.filter(v53_, function()
		return true
	end)
	Assert.areEqual(table.size(v57_), table.size(v53_))
	local v58_ = {
		"a",
		"b",
		"c",
		["c"] = true,
		["key1"] = "a",
		["key2"] = "b"
	}
	local v60_ = table.filter(v58_, function(p59_, _)
		return p59_ ~= "b"
	end)
	Assert.areEqual(table.size(v60_), 4)
	Assert.isFalse(table.hasElement(v60_, "b"))
	Assert.isNil(v60_.b)
	local v61_ = table.filter(v58_, function()
		return true
	end)
	Assert.areEqual(table.size(v61_), table.size(v58_))
end
function TableTest.test_concatKeys()
	Assert.throwsError(function()
		table.concatKeys(nil)
	end, "Nil as table argument does not raise an error")
	Assert.areEqual(table.concatKeys({}), "")
	Assert.areEqual(table.concatKeys({}, "sep"), "")
	local v62_ = {
		["a"] = 1,
		["b"] = 2,
		["cd"] = 3
	}
	local v63_ = table.concatKeys(v62_)
	local v64_ = ""
	for v65_ in pairs(v62_) do
		v64_ = v64_ .. v65_
	end
	Assert.areEqual(v63_, v64_)
	local v66_ = { "a", "b", "c" }
	local v67_ = table.concatKeys(v66_)
	local v68_ = ""
	for v69_ in pairs(v66_) do
		v68_ = v68_ .. v69_
	end
	Assert.areEqual(v67_, v68_)
	table.concatKeys({
		[{}] = true,
		[{}] = true,
		[{}] = true,
		["a"] = false,
		[2] = true
	})
	table.concatKeys({
		["a"] = 1,
		["b"] = 2,
		["cd"] = 3
	}, nil)
	local v70_ = {
		["a"] = 1,
		["b"] = 2,
		["cd"] = 3
	}
	local v71_ = table.concatKeys(v70_, "<sep>")
	local v72_ = ""
	for v73_ in pairs(v70_) do
		if v72_ ~= "" then
			v72_ = v72_ .. "<sep>"
		end
		v72_ = v72_ .. v73_
	end
	Assert.areEqual(v71_, v72_)
	Assert.throwsError(function()
		table.concatKeys({}, {})
	end, "table value for separator does not raise an error")
	Assert.throwsError(function()
		table.concatKeys({}, true)
	end, "boolean value for separator does not raise an error")
	Assert.areEqual(table.concatKeys({
		["a"] = true,
		["b"] = true
	}, 2), "a2b")
	local v74_ = {}
	for v79_ = 0, 256 do
		local v76_ = v79_
		local v77_ = ""
		while v79_ > 0 do
			local v78_ = getMD5((tostring(v76_)))
			v77_ = v77_ .. string.sub(v78_, 0, v79_)
			local v79_ = v79_ - 32
		end
		v74_[v77_] = true
	end
	table.concatKeys(v74_, ", ")
	table.concatKeys(v74_, "")
	table.concatKeys(v74_, "\n")
	table.concatKeys(v74_, "                            ")
end
function TableTest.test_equalLists()
	Assert.throwsError(function()
		table.equalLists(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.equalLists({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.equalLists(nil, {})
	end, "Nil as table argument does not raise an error")
	local v80_ = {}
	local v81_ = {}
	Assert.isTrue(table.equalLists(v80_, v81_))
	Assert.isTrue(table.equalLists(v80_, v81_, true))
	local v82_ = { "A", "B", "C" }
	local v83_ = { "A", "B", "C" }
	Assert.isTrue(table.equalLists(v82_, v83_))
	Assert.isTrue(table.equalLists(v82_, v83_, true))
	local v84_ = {}
	local v85_ = { "A" }
	Assert.isFalse(table.equalLists(v84_, v85_))
	Assert.isFalse(table.equalLists(v84_, v85_, true))
	local v86_ = { "A" }
	local v87_ = {}
	Assert.isFalse(table.equalLists(v86_, v87_))
	Assert.isFalse(table.equalLists(v86_, v87_, true))
	local v88_ = { "A", "B", "C" }
	local v89_ = { "A", "C", "B" }
	Assert.isFalse(table.equalLists(v88_, v89_))
	Assert.isTrue(table.equalLists(v88_, v89_, true))
	Assert.throwsError(function()
		table.equalLists({
			["a"] = 1
		}, {
			["a"] = 1
		}, 1)
	end, "number for orderIndependent argument does not raise an error")
	Assert.throwsError(function()
		table.equalLists({
			["a"] = 1
		}, {
			["a"] = 1
		}, "")
	end, "string for orderIndependent argument does not raise an error")
end
function TableTest.test_equalSets()
	Assert.throwsError(function()
		table.equalSets(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.equalSets({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.equalSets(nil, {})
	end, "Nil as table argument does not raise an error")
	Assert.isTrue(table.equalSets({}, {}))
	Assert.isTrue(table.equalSets({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = true,
		["b"] = true,
		["c"] = true
	}))
	Assert.isFalse(table.equalSets({}, {
		["a"] = true
	}))
	Assert.isFalse(table.equalSets({
		["a"] = true
	}, {}))
	Assert.isFalse(table.equalSets({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = true,
		["b"] = true,
		["c"] = true,
		["d"] = true
	}))
	Assert.isFalse(table.equalSets({
		["a"] = true,
		["b"] = true,
		["c"] = true,
		["d"] = true
	}, {
		["a"] = true,
		["b"] = true,
		["c"] = true
	}))
	Assert.isTrue(table.equalSets({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = true,
		["c"] = true,
		["b"] = true
	}))
	Assert.isFalse(table.equalSets({
		true,
		["a"] = true
	}, {
		["a"] = true
	}))
end
function TableTest.test_getListUnion()
	Assert.throwsError(function()
		table.getListUnion(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getListUnion({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getListUnion(nil, {})
	end, "Nil as table argument does not raise an error")
	Assert.areEqual(#table.getListUnion({}, {}), 0)
	local v90_ = { "A", "B", "C" }
	local v91_ = { "A", "B", "C" }
	Assert.areEqual(#table.getListUnion(v90_, v91_), #v90_ + #v91_)
	local v92_ = { "A", "B", "C" }
	local v93_ = { "D", "E", "F" }
	Assert.areEqual(#table.getListUnion(v92_, v93_), #v92_ + #v93_)
	local v94_ = {}
	local v95_ = { "A", "B", "C" }
	Assert.areEqual(#table.getListUnion(v94_, v95_), #v94_ + #v95_)
	local v96_ = { "A", "B", "C" }
	local v97_ = {}
	Assert.areEqual(#table.getListUnion(v96_, v97_), #v96_ + #v97_)
	local v98_ = {
		"A",
		"B",
		"C",
		["key"] = "D"
	}
	local v99_ = {
		["key"] = "E"
	}
	Assert.areEqual(#table.getListUnion(v98_, v99_), #v98_ + #v99_)
	Assert.areEqual(#table.getListUnion(v98_, v99_), 3)
end
function TableTest.test_getSetUnion()
	Assert.throwsError(function()
		table.getSetUnion(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getSetUnion({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getSetUnion(nil, {})
	end, "Nil as table argument does not raise an error")
	Assert.areEqual(table.size(table.getSetUnion({}, {})), 0)
	Assert.areEqual(table.size(table.getSetUnion({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = true,
		["b"] = true,
		["c"] = true
	})), 3)
	Assert.areEqual(table.size(table.getSetUnion({}, {
		["a"] = true
	})), 1)
	Assert.areEqual(table.size(table.getSetUnion({
		["a"] = true
	}, {})), 1)
	Assert.areEqual(table.size(table.getSetUnion({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["d"] = true,
		["e"] = true,
		["f"] = true
	})), 6)
	Assert.areEqual(table.size(table.getSetUnion({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = true,
		["b"] = true,
		["d"] = true
	})), 4)
end
function TableTest.test_getTableUnion()
	Assert.throwsError(function()
		table.getTableUnion(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getTableUnion({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getTableUnion(nil, {})
	end, "Nil as table argument does not raise an error")
	local v100_ = table.getTableUnion({}, {})
	Assert.areEqual(table.size(v100_), 0)
	local v101_ = {
		["a"] = 4,
		["b"] = 5,
		["c"] = 6
	}
	local v102_ = table.getTableUnion({
		["a"] = 1,
		["b"] = 2,
		["c"] = 3
	}, v101_)
	Assert.areEqual(table.size(v102_), 3)
	Assert.areEqual(v102_.a, v101_.a)
	Assert.areEqual(v102_.b, v101_.b)
	Assert.areEqual(v102_.c, v101_.c)
	local v103_ = table.getTableUnion({}, {
		["a"] = 1
	})
	Assert.areEqual(table.size(v103_), 1)
	local v104_ = table.getTableUnion({
		["a"] = 1
	}, {})
	Assert.areEqual(table.size(v104_), 1)
	local v105_ = {
		["a"] = 1,
		["b"] = 2,
		["c"] = 3
	}
	local v106_ = {
		["d"] = 4,
		["e"] = 5,
		["f"] = 6
	}
	local v107_ = table.getTableUnion(v105_, v106_)
	Assert.areEqual(table.size(v107_), 6)
	Assert.areEqual(v107_.a, v105_.a)
	Assert.areEqual(v107_.b, v105_.b)
	Assert.areEqual(v107_.c, v105_.c)
	Assert.areEqual(v107_.d, v106_.d)
	Assert.areEqual(v107_.e, v106_.e)
	Assert.areEqual(v107_.f, v106_.f)
	local v108_ = {
		["a"] = 1,
		["b"] = 2,
		["c"] = 3
	}
	local v109_ = {
		["a"] = 4,
		["b"] = 5,
		["d"] = 6
	}
	local v110_ = table.getTableUnion(v108_, v109_)
	Assert.areEqual(table.size(v110_), 4)
	Assert.areEqual(v110_.a, v109_.a)
	Assert.areEqual(v110_.b, v109_.b)
	Assert.areEqual(v110_.c, v108_.c)
	Assert.areEqual(v110_.d, v109_.d)
end
function TableTest.test_getSetSubtraction()
	Assert.throwsError(function()
		table.getSetSubtraction(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getSetSubtraction({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getSetSubtraction(nil, {})
	end, "Nil as table argument does not raise an error")
	local function v115_(p111_, p112_, p113_)
		for v114_ in pairs(p111_) do
			if p112_[v114_] == nil then
				Assert.isNotNil(p113_[v114_])
			else
				Assert.isNil(p113_[v114_])
			end
		end
	end
	Assert.areEqual(table.size(table.getSetSubtraction({}, {})), 0)
	local v116_ = {
		["a"] = true,
		["b"] = true,
		["c"] = true
	}
	Assert.areEqual(table.size(table.getSetSubtraction(v116_, {})), table.size(v116_))
	local v117_ = {
		["a"] = true,
		["b"] = true,
		["c"] = true
	}
	local v118_ = {
		["d"] = false
	}
	local v119_ = table.getSetSubtraction(v117_, v118_)
	v115_(v117_, v118_, v119_)
	Assert.areEqual(table.size(v119_), table.size(v117_))
	local v120_ = {
		["a"] = true,
		["b"] = true,
		["c"] = true
	}
	local v121_ = {
		["a"] = false,
		["b"] = false
	}
	local v122_ = table.getSetSubtraction(v120_, v121_)
	v115_(v120_, v121_, v122_)
	Assert.areEqual(table.size(v122_), 1)
	local v123_ = table.getSetSubtraction({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false,
		["c"] = false
	})
	Assert.areEqual(table.size(v123_), 0)
end
function TableTest.test_getSetIntersection()
	Assert.throwsError(function()
		table.getSetIntersection(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getSetIntersection({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getSetIntersection(nil, {})
	end, "Nil as table argument does not raise an error")
	Assert.areEqual(table.size(table.getSetIntersection({}, {})), 0)
	Assert.areEqual(table.size(table.getSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {})), 0)
	Assert.areEqual(table.size(table.getSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["d"] = false
	})), 0)
	Assert.areEqual(table.size(table.getSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false
	})), 2)
	Assert.areEqual(table.size(table.getSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false,
		["c"] = false
	})), 3)
end
function TableTest.test_hasSetIntersection()
	Assert.throwsError(function()
		table.hasSetIntersection(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.hasSetIntersection({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.hasSetIntersection(nil, {})
	end, "Nil as table argument does not raise an error")
	Assert.isFalse(table.hasSetIntersection({}, {}))
	Assert.isFalse(table.hasSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {}))
	Assert.isFalse(table.hasSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["d"] = false
	}))
	Assert.isTrue(table.hasSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false
	}))
	Assert.isTrue(table.hasSetIntersection({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false,
		["c"] = false
	}))
end
function TableTest.test_isSubset()
	Assert.throwsError(function()
		table.isSubset(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.isSubset({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.isSubset(nil, {})
	end, "Nil as table argument does not raise an error")
	Assert.isTrue(table.isSubset({}, {}))
	Assert.isTrue(table.isSubset({}, {
		["a"] = true
	}))
	Assert.isFalse(table.isSubset({
		["a"] = true
	}, {}))
	Assert.isFalse(table.isSubset({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["d"] = false
	}))
	Assert.isFalse(table.isSubset({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false
	}))
	Assert.isTrue(table.isSubset({
		["a"] = true,
		["b"] = true
	}, {
		["a"] = false,
		["b"] = false,
		["c"] = true
	}))
	Assert.isTrue(table.isSubset({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false,
		["c"] = false
	}))
end
function TableTest.test_isProperSubset()
	Assert.throwsError(function()
		table.isProperSubset(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.isProperSubset({}, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.isProperSubset(nil, {})
	end, "Nil as table argument does not raise an error")
	Assert.isFalse(table.isProperSubset({}, {}))
	Assert.isTrue(table.isProperSubset({}, {
		["a"] = true
	}))
	Assert.isFalse(table.isProperSubset({
		["a"] = true
	}, {}))
	Assert.isFalse(table.isProperSubset({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["d"] = false
	}))
	Assert.isFalse(table.isProperSubset({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false
	}))
	Assert.isTrue(table.isProperSubset({
		["a"] = true,
		["b"] = true
	}, {
		["a"] = false,
		["b"] = false,
		["c"] = true
	}))
	Assert.isFalse(table.isProperSubset({
		["a"] = true,
		["b"] = true,
		["c"] = true
	}, {
		["a"] = false,
		["b"] = false,
		["c"] = false
	}))
end
function TableTest.test_getndebug()
	Assert.throwsError(function()
		table.getndebug(nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		table.getndebug({
			["a"] = 2
		})
	end, "Set as table argument does not raise an error")
	Assert.throwsError(function()
		table.getndebug({
			[1] = "A",
			[3] = "B"
		})
	end, "table with gaps does not raise an error")
	local v124_ = { "a", "b", "c" }
	Assert.areEqual(table.getndebug(v124_), #v124_)
	Assert.areEqual(table.getndebug(v124_), 3)
	local v125_ = {}
	Assert.areEqual(table.getndebug(v125_), #v125_)
	Assert.areEqual(table.getndebug(v125_), 0)
end
local v126_ = {
	["getn"] = true,
	["remove"] = true,
	["unpack"] = true,
	["move"] = true,
	["insert"] = true,
	["find"] = true,
	["maxn"] = true,
	["concat"] = true,
	["foreachi"] = true,
	["foreach"] = true,
	["sort"] = true,
	["freeze"] = true,
	["clear"] = true,
	["pack"] = true,
	["create"] = true,
	["isfrozen"] = true
}
for v127_ in pairs(table) do
	if TableTest["test_" .. v127_] == nil and v126_[v127_] == nil then
		printWarning("Warning: no test function for function table." .. v127_)
	end
end
