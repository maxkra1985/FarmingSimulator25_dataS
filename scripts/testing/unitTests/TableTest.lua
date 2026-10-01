TableTest = {}
function TableTest.test_addElement()
	Assert.throwsError(function()
		local tbl = nil
		table.addElement(nil, 1)
	end, "Nil as table argument does not raise an error")
	local values = { true, false, -1, 0, 1, math.huge, "", " ", "\n", "1", {} }
	for _, valueToAdd in ipairs(values) do
		local tbl = {}
		local success, index = table.addElement(tbl, valueToAdd)
		Assert.isTrue(success, "element '%s' of type %s was not added to the table", valueToAdd, type(valueToAdd))
		Assert.areEqual(index, 1)
		success, index = table.addElement(tbl, valueToAdd)
		Assert.isFalse(success)
		Assert.areEqual(index, 1)
	end
	local tbl = {}
	local element = "test"
	table.addElement(tbl, "test")
	table.clear(tbl)
	local success, index = table.addElement(tbl, "test")
	Assert.isTrue(success)
	Assert.areEqual(index, 1)
end
function TableTest.test_removeElement()
	Assert.throwsError(function()
		local tbl = nil
		table.removeElement(nil, 1)
	end, "Nil as table argument does not raise an error")
	Assert.isFalse(table.removeElement({}, "element"))
	local element = "element"
	local tbl = { "element", "element" }
	Assert.isTrue(table.removeElement(tbl, "element"))
	Assert.isTrue(table.removeElement(tbl, "element"))
	Assert.isFalse(table.removeElement(tbl, "element"))
	local values = { true, false, -1, 0, 1, math.huge, "", " ", "\n", "1", {} }
	for _, valueToAdd in ipairs(values) do
		tbl = {}
		table.addElement(tbl, valueToAdd)
		Assert.isTrue(table.removeElement(tbl, valueToAdd))
	end
end
function TableTest.test_hasElement()
	Assert.throwsError(function()
		local tbl = nil
		table.hasElement(nil, 1)
	end, "Nil as table argument does not raise an error")
	Assert.isFalse(table.hasElement({}, "element"))
	Assert.isFalse(table.hasElement({ "a" }, "b"))
	local element = "element"
	local tbl = { "element", "element" }
	Assert.isTrue(table.hasElement(tbl, "element"))
	table.remove(tbl, 1)
	Assert.isTrue(table.hasElement(tbl, "element"))
	table.remove(tbl, 1)
	Assert.isFalse(table.hasElement(tbl, "element"))
end
function TableTest.test_isList()
	Assert.throwsError(function()
		local tbl = nil
		table.isList(nil)
	end, "Nil as table argument does not raise an error")
	Assert.isTrue(table.isList({}))
	Assert.isTrue(table.isList({ "a", "b", "c" }))
	Assert.isFalse(table.isList({ "b", "c", ["a"] = "a" }))
	Assert.isFalse(table.isList({ "b", "c", [0] = "a" }))
	Assert.isFalse(table.isList({ [2] = "a", [3] = "b", [4] = "c" }))
	Assert.isFalse(table.isList({ "a", [3] = "b", [4] = "c" }))
	local tbl = { "a", "b", "c" }
	tbl[2] = nil
	Assert.isFalse(table.isList(tbl))
	tbl = { "a", "b", "c" }
	table.remove(tbl, 1)
	Assert.isTrue(table.isList(tbl))
end
function TableTest.test_clone()
	Assert.throwsError(function()
		local tbl = nil
		table.clone(nil)
	end, "Nil as table argument does not raise an error")
	local tblIn = {}
	Assert.areNotEqual(table.clone(tblIn), tblIn)
	local innerTbl = {}
	tblIn = { innerTbl = innerTbl }
	local tblOut = table.clone(tblIn)
	Assert.areEqual(tblOut.innerTbl, tblIn.innerTbl)
	local tvlOutDeep = table.clone(tblIn, 2)
	Assert.areNotEqual(tvlOutDeep.innerTbl, tblIn.innerTbl)
	local values = { true, false, -1, 0, 1, math.huge, "", " ", "\n", "1", {} }
	local valuesCloned = table.clone(values, 1)
	for k, v in ipairs(values) do
		Assert.areEqual(valuesCloned[k], v, "cloned value '%s' is not equal to source '%s'", valuesCloned[k], v)
	end
	local depth = math.huge
	tvlOutDeep = table.clone(tblIn, math.huge)
	Assert.areNotEqual(tvlOutDeep.innerTbl, tblIn.innerTbl, "sub tables of clone are identical with source when depth=math.huge")
	Assert.throwsError(function()
		table.clone({}, true)
	end, "Boolean depth argument does not raise an error")
	Assert.throwsError(function()
		table.clone({}, -1)
	end, "Negative depth argument does not raise an error")
	local tbl = { a = {} }
	Assert.throwsError(function()
		table.clone(tbl, true)
	end, "Boolean value for 'depth' argument does not raise an error")
	Assert.throwsError(function()
		table.clone(tbl, {})
	end, "Table value for 'depth' argument does not raise an error")
	Assert.throwsError(function()
		table.clone(tbl, "yes")
	end, "String value for 'depth' argument does not raise an error")
end
function TableTest.test_size()
	Assert.throwsError(function()
		local tbl = nil
		table.size(nil)
	end, "Nil as table argument does not raise an error")
	Assert.areEqual(table.size({}), 0)
	Assert.areEqual(table.size({ "a" }), 1)
	Assert.areEqual(table.size({ nil }), 0)
	Assert.areEqual(table.size({ a = "a" }), 1)
	Assert.areEqual(table.size({ "b", ["a"] = "a" }), 2)
end
function TableTest.test_getRandomElement()
	Assert.throwsError(function()
		local tbl = nil
		table.getRandomElement(nil)
	end, "Nil as table argument does not raise an error")
	Assert.isNil(table.getRandomElement({}))
	local element = "a"
	local tbl = { "a" }
	Assert.areEqual(table.getRandomElement(tbl), "a")
	local tblA = { "a", "b", "c", "d", "e", "f", "g" }
	local tblB = {}
	for _, v in ipairs(tblA) do
		tblB[v] = true
	end
	for i = 1, 100000 do
		tblB[table.getRandomElement(tblA)] = nil
		if table.size(tblB) == 0 then
			break
		end
		if i == 10000 then
			Assert.areEqual(table.size(tblB), 0)
		end
	end
end
function TableTest.test_copyIndex()
	Assert.throwsError(function()
		local tbl = nil
		table.copyIndex(nil)
	end, "Nil as table argument does not raise an error")
	local input = { a = 1, b = 2 }
	local output = table.copyIndex(input)
	Assert.areEqual(#output, 0)
	Assert.areNotEqual(#output, table.size(input))
	Assert.isTrue(table.isList(output))
	input = { "a", "b", "c" }
	output = table.copyIndex(input)
	Assert.areEqual(#input, #output)
	Assert.isTrue(table.isList(output))
	input = { "a", "b", "c", ["test"] = 4 }
	output = table.copyIndex(input)
	Assert.areEqual(#input, #output)
	Assert.areNotEqual(#output, table.size(input))
	Assert.isTrue(table.isList(output))
end
function TableTest.test_toList()
	Assert.throwsError(function()
		local tbl = nil
		table.toList(nil)
	end, "Nil as table argument does not raise an error")
	local set = { a = "", b = "", c = "" }
	local list = table.toList(set)
	Assert.areEqual(table.size(set), #list)
	for k in pairs(set) do
		Assert.isTrue(table.hasElement(list, k))
	end
end
function TableTest.test_toSet()
	Assert.throwsError(function()
		local tbl = nil
		table.toSet(nil)
	end, "Nil as table argument does not raise an error")
	local list = { "a", "b", "c" }
	local set = table.toSet(list)
	Assert.areEqual(table.size(set), #list)
	for k in pairs(set) do
		Assert.isTrue(table.hasElement(list, k))
	end
	local listDuplicates = { "a", "b", "a", "c", "c" }
	set = table.toSet(listDuplicates)
	Assert.areEqual(table.size(set), 3)
end
function TableTest.test_ifilter()
	Assert.throwsError(function()
		local tbl = nil
		table.ifilter(nil, function(val)
			return val
		end)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local tbl = {}
		local filterFunc = nil
		table.ifilter(tbl, nil)
	end, "Nil as closure argument does not raise an error")
	local tbl = { "a", "b", "c", "d" }
	local filter = function(value, index)
		return value ~= "b"
	end
	local tblFiltered = table.ifilter(tbl, filter)
	Assert.areEqual(#tblFiltered, 3)
	Assert.isFalse(table.hasElement(tblFiltered, "b"))
	Assert.areEqual(#tbl, 4)
	Assert.isTrue(table.hasElement(tbl, "b"))
	local empty = table.ifilter(tbl, function()
		return false
	end)
	Assert.areEqual(#empty, 0)
	local all = table.ifilter(tbl, function()
		return true
	end)
	Assert.areEqual(#all, #tbl)
	local tblMixed = { "a", "b", "c" }
	tblMixed.c = true
	tblMixed.key1 = "a"
	tblMixed.key2 = "b"
	function filter(value, index)
		return value ~= "b"
	end
	local tblMixedFiltered = table.ifilter(tblMixed, filter)
	Assert.areEqual(#tblMixedFiltered, 2)
	Assert.areEqual(table.size(tblMixedFiltered), #tblMixedFiltered)
	Assert.isFalse(table.hasElement(tblMixedFiltered, "b"))
	all = table.ifilter(tblMixed, function()
		return true
	end)
	Assert.areEqual(#all, #tblMixed)
	Assert.areNotEqual(#all, table.size(tblMixed))
end
function TableTest.test_filter()
	Assert.throwsError(function()
		local tbl = nil
		table.filter(nil, function(val)
			return val
		end)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local tbl = {}
		local filterFunc = nil
		table.filter(tbl, nil)
	end, "Nil as closure argument does not raise an error")
	local tbl = { "a", "b", "c" }
	tbl.c = true
	local filter = function(value, index)
		return value ~= "b"
	end
	local tblFiltered = table.filter(tbl, filter)
	Assert.areEqual(table.size(tblFiltered), 3)
	Assert.isNil(tblFiltered.b)
	Assert.areEqual(table.size(tbl), 4)
	Assert.isTrue(table.hasElement(tbl, "b"))
	local empty = table.filter(tbl, function()
		return false
	end)
	Assert.areEqual(table.size(empty), 0)
	local all = table.filter(tbl, function()
		return true
	end)
	Assert.areEqual(table.size(all), table.size(tbl))
	local tblMixed = { "a", "b", "c" }
	tblMixed.c = true
	tblMixed.key1 = "a"
	tblMixed.key2 = "b"
	function filter(value, index)
		return value ~= "b"
	end
	local tblMixedFiltered = table.filter(tblMixed, filter)
	Assert.areEqual(table.size(tblMixedFiltered), 4)
	Assert.isFalse(table.hasElement(tblMixedFiltered, "b"))
	Assert.isNil(tblMixedFiltered.b)
	all = table.filter(tblMixed, function()
		return true
	end)
	Assert.areEqual(table.size(all), table.size(tblMixed))
end
function TableTest.test_concatKeys()
	Assert.throwsError(function()
		local tbl = nil
		table.concatKeys(nil)
	end, "Nil as table argument does not raise an error")
	Assert.areEqual(table.concatKeys({}), "")
	Assert.areEqual(table.concatKeys({}, "sep"), "")
	local tbl = { a = 1, b = 2, cd = 3 }
	local str = table.concatKeys(tbl)
	local strConcat = ""
	for k in pairs(tbl) do
		strConcat = strConcat .. k
	end
	Assert.areEqual(str, strConcat)
	tbl = { "a", "b", "c" }
	str = table.concatKeys(tbl)
	strConcat = ""
	for k in pairs(tbl) do
		strConcat = strConcat .. k
	end
	Assert.areEqual(str, strConcat)
	table.concatKeys({ [{}] = true, [{}] = true, [{}] = true, ["a"] = false, [2] = true })
	table.concatKeys({ a = 1, b = 2, cd = 3 }, nil)
	local separtor = "<sep>"
	tbl = { a = 1, b = 2, cd = 3 }
	str = table.concatKeys(tbl, "<sep>")
	strConcat = ""
	for k in pairs(tbl) do
		if strConcat ~= "" then
			strConcat = strConcat .. "<sep>"
		end
		strConcat = strConcat .. k
	end
	Assert.areEqual(str, strConcat)
	Assert.throwsError(function()
		local sep = {}
		table.concatKeys({}, sep)
	end, "table value for separator does not raise an error")
	Assert.throwsError(function()
		local sep = true
		table.concatKeys({}, true)
	end, "boolean value for separator does not raise an error")
	Assert.areEqual(table.concatKeys({ a = true, b = true }, 2), "a2b")
	local keys = {}
	local key = nil
	for numChars = 0, 256 do
		key = ""
		local charsLeftToGenerate = numChars
		while 0 < charsLeftToGenerate do
			key = key .. string.sub(getMD5(tostring(numChars)), 0, charsLeftToGenerate)
			charsLeftToGenerate = charsLeftToGenerate - 32
		end
		keys[key] = true
	end
	table.concatKeys(keys, ", ")
	table.concatKeys(keys, "")
	table.concatKeys(keys, "\n")
	table.concatKeys(keys, "                            ")
end
function TableTest.test_equalLists()
	Assert.throwsError(function()
		local listA = nil
		local listB = nil
		table.equalLists(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local listA = {}
		local listB = nil
		table.equalLists(listA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local listA = nil
		local listB = {}
		table.equalLists(nil, listB)
	end, "Nil as table argument does not raise an error")
	local listA = {}
	local listB = {}
	Assert.isTrue(table.equalLists(listA, listB))
	Assert.isTrue(table.equalLists(listA, listB, true))
	listA = { "A", "B", "C" }
	listB = { "A", "B", "C" }
	Assert.isTrue(table.equalLists(listA, listB))
	Assert.isTrue(table.equalLists(listA, listB, true))
	listA = {}
	listB = { "A" }
	Assert.isFalse(table.equalLists(listA, listB))
	Assert.isFalse(table.equalLists(listA, listB, true))
	listA = { "A" }
	listB = {}
	Assert.isFalse(table.equalLists(listA, listB))
	Assert.isFalse(table.equalLists(listA, listB, true))
	listA = { "A", "B", "C" }
	listB = { "A", "C", "B" }
	Assert.isFalse(table.equalLists(listA, listB))
	Assert.isTrue(table.equalLists(listA, listB, true))
	Assert.throwsError(function()
		local listA = { a = 1 }
		local listB = { a = 1 }
		table.equalLists(listA, listB, 1)
	end, "number for orderIndependent argument does not raise an error")
	Assert.throwsError(function()
		local listA = { a = 1 }
		local listB = { a = 1 }
		table.equalLists(listA, listB, "")
	end, "string for orderIndependent argument does not raise an error")
end
function TableTest.test_equalSets()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.equalSets(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.equalSets(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.equalSets(nil, setB)
	end, "Nil as table argument does not raise an error")
	local setA = {}
	local setB = {}
	Assert.isTrue(table.equalSets(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = true, b = true, c = true }
	Assert.isTrue(table.equalSets(setA, setB))
	setA = {}
	setB = { a = true }
	Assert.isFalse(table.equalSets(setA, setB))
	setA = { a = true }
	setB = {}
	Assert.isFalse(table.equalSets(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = true, b = true, c = true, d = true }
	Assert.isFalse(table.equalSets(setA, setB))
	setA = { a = true, b = true, c = true, d = true }
	setB = { a = true, b = true, c = true }
	Assert.isFalse(table.equalSets(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = true, c = true, b = true }
	Assert.isTrue(table.equalSets(setA, setB))
	setA = { true, ["a"] = true }
	setB = { a = true }
	Assert.isFalse(table.equalSets(setA, setB))
end
function TableTest.test_getListUnion()
	Assert.throwsError(function()
		local listA = nil
		local listB = nil
		table.getListUnion(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local listA = {}
		local listB = nil
		table.getListUnion(listA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local listA = nil
		local listB = {}
		table.getListUnion(nil, listB)
	end, "Nil as table argument does not raise an error")
	local listA = {}
	local listB = {}
	Assert.areEqual(#table.getListUnion(listA, listB), 0)
	listA = { "A", "B", "C" }
	listB = { "A", "B", "C" }
	Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
	listA = { "A", "B", "C" }
	listB = { "D", "E", "F" }
	Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
	listA = {}
	listB = { "A", "B", "C" }
	Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
	listA = { "A", "B", "C" }
	listB = {}
	Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
	listA = { "A", "B", "C", ["key"] = "D" }
	listB = { key = "E" }
	Assert.areEqual(#table.getListUnion(listA, listB), #listA + #listB)
	Assert.areEqual(#table.getListUnion(listA, listB), 3)
end
function TableTest.test_getSetUnion()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.getSetUnion(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.getSetUnion(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.getSetUnion(nil, setB)
	end, "Nil as table argument does not raise an error")
	local setA = {}
	local setB = {}
	Assert.areEqual(table.size(table.getSetUnion(setA, setB)), 0)
	setA = { a = true, b = true, c = true }
	setB = { a = true, b = true, c = true }
	Assert.areEqual(table.size(table.getSetUnion(setA, setB)), 3)
	setA = {}
	setB = { a = true }
	Assert.areEqual(table.size(table.getSetUnion(setA, setB)), 1)
	setA = { a = true }
	setB = {}
	Assert.areEqual(table.size(table.getSetUnion(setA, setB)), 1)
	setA = { a = true, b = true, c = true }
	setB = { d = true, e = true, f = true }
	Assert.areEqual(table.size(table.getSetUnion(setA, setB)), 6)
	setA = { a = true, b = true, c = true }
	setB = { a = true, b = true, d = true }
	Assert.areEqual(table.size(table.getSetUnion(setA, setB)), 4)
end
function TableTest.test_getTableUnion()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.getTableUnion(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.getTableUnion(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.getTableUnion(nil, setB)
	end, "Nil as table argument does not raise an error")
	local setA = {}
	local setB = {}
	local union = table.getTableUnion(setA, setB)
	Assert.areEqual(table.size(union), 0)
	setA = { a = 1, b = 2, c = 3 }
	setB = { a = 4, b = 5, c = 6 }
	union = table.getTableUnion(setA, setB)
	Assert.areEqual(table.size(union), 3)
	Assert.areEqual(union.a, setB.a)
	Assert.areEqual(union.b, setB.b)
	Assert.areEqual(union.c, setB.c)
	setA = {}
	setB = { a = 1 }
	union = table.getTableUnion(setA, setB)
	Assert.areEqual(table.size(union), 1)
	setA = { a = 1 }
	setB = {}
	union = table.getTableUnion(setA, setB)
	Assert.areEqual(table.size(union), 1)
	setA = { a = 1, b = 2, c = 3 }
	setB = { d = 4, e = 5, f = 6 }
	union = table.getTableUnion(setA, setB)
	Assert.areEqual(table.size(union), 6)
	Assert.areEqual(union.a, setA.a)
	Assert.areEqual(union.b, setA.b)
	Assert.areEqual(union.c, setA.c)
	Assert.areEqual(union.d, setB.d)
	Assert.areEqual(union.e, setB.e)
	Assert.areEqual(union.f, setB.f)
	setA = { a = 1, b = 2, c = 3 }
	setB = { a = 4, b = 5, d = 6 }
	union = table.getTableUnion(setA, setB)
	Assert.areEqual(table.size(union), 4)
	Assert.areEqual(union.a, setB.a)
	Assert.areEqual(union.b, setB.b)
	Assert.areEqual(union.c, setA.c)
	Assert.areEqual(union.d, setB.d)
end
function TableTest.test_getSetSubtraction()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.getSetSubtraction(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.getSetSubtraction(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.getSetSubtraction(nil, setB)
	end, "Nil as table argument does not raise an error")
	local validateSubtraction = function(setA, setB, subtraction)
		for k in pairs(setA) do
			if setB[k] == nil then
				Assert.isNotNil(subtraction[k])
			else
				Assert.isNil(subtraction[k])
			end
		end
	end
	local setA = {}
	local setB = {}
	Assert.areEqual(table.size(table.getSetSubtraction(setA, setB)), 0)
	setA = { a = true, b = true, c = true }
	setB = {}
	Assert.areEqual(table.size(table.getSetSubtraction(setA, setB)), table.size(setA))
	setA = { a = true, b = true, c = true }
	setB = { d = false }
	local subtraction = table.getSetSubtraction(setA, setB)
	validateSubtraction(setA, setB, subtraction)
	Assert.areEqual(table.size(subtraction), table.size(setA))
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false }
	subtraction = table.getSetSubtraction(setA, setB)
	validateSubtraction(setA, setB, subtraction)
	Assert.areEqual(table.size(subtraction), 1)
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false, c = false }
	subtraction = table.getSetSubtraction(setA, setB)
	Assert.areEqual(table.size(subtraction), 0)
end
function TableTest.test_getSetIntersection()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.getSetIntersection(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.getSetIntersection(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.getSetIntersection(nil, setB)
	end, "Nil as table argument does not raise an error")
	local setA = {}
	local setB = {}
	Assert.areEqual(table.size(table.getSetIntersection(setA, setB)), 0)
	setA = { a = true, b = true, c = true }
	setB = {}
	Assert.areEqual(table.size(table.getSetIntersection(setA, setB)), 0)
	setA = { a = true, b = true, c = true }
	setB = { d = false }
	Assert.areEqual(table.size(table.getSetIntersection(setA, setB)), 0)
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false }
	Assert.areEqual(table.size(table.getSetIntersection(setA, setB)), 2)
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false, c = false }
	Assert.areEqual(table.size(table.getSetIntersection(setA, setB)), 3)
end
function TableTest.test_hasSetIntersection()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.hasSetIntersection(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.hasSetIntersection(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.hasSetIntersection(nil, setB)
	end, "Nil as table argument does not raise an error")
	local setA = {}
	local setB = {}
	Assert.isFalse(table.hasSetIntersection(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = {}
	Assert.isFalse(table.hasSetIntersection(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { d = false }
	Assert.isFalse(table.hasSetIntersection(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false }
	Assert.isTrue(table.hasSetIntersection(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false, c = false }
	Assert.isTrue(table.hasSetIntersection(setA, setB))
end
function TableTest.test_isSubset()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.isSubset(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.isSubset(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.isSubset(nil, setB)
	end, "Nil as table argument does not raise an error")
	local setA = {}
	local setB = {}
	Assert.isTrue(table.isSubset(setA, setB))
	setA = {}
	setB = { a = true }
	Assert.isTrue(table.isSubset(setA, setB))
	setA = { a = true }
	setB = {}
	Assert.isFalse(table.isSubset(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { d = false }
	Assert.isFalse(table.isSubset(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false }
	Assert.isFalse(table.isSubset(setA, setB))
	setA = { a = true, b = true }
	setB = { a = false, b = false, c = true }
	Assert.isTrue(table.isSubset(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false, c = false }
	Assert.isTrue(table.isSubset(setA, setB))
end
function TableTest.test_isProperSubset()
	Assert.throwsError(function()
		local setA = nil
		local setB = nil
		table.isProperSubset(nil, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = {}
		local setB = nil
		table.isProperSubset(setA, nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local setA = nil
		local setB = {}
		table.isProperSubset(nil, setB)
	end, "Nil as table argument does not raise an error")
	local setA = {}
	local setB = {}
	Assert.isFalse(table.isProperSubset(setA, setB))
	setA = {}
	setB = { a = true }
	Assert.isTrue(table.isProperSubset(setA, setB))
	setA = { a = true }
	setB = {}
	Assert.isFalse(table.isProperSubset(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { d = false }
	Assert.isFalse(table.isProperSubset(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false }
	Assert.isFalse(table.isProperSubset(setA, setB))
	setA = { a = true, b = true }
	setB = { a = false, b = false, c = true }
	Assert.isTrue(table.isProperSubset(setA, setB))
	setA = { a = true, b = true, c = true }
	setB = { a = false, b = false, c = false }
	Assert.isFalse(table.isProperSubset(setA, setB))
end
function TableTest.test_getndebug()
	Assert.throwsError(function()
		local tbl = nil
		table.getndebug(nil)
	end, "Nil as table argument does not raise an error")
	Assert.throwsError(function()
		local tbl = { a = 2 }
		table.getndebug(tbl)
	end, "Set as table argument does not raise an error")
	Assert.throwsError(function()
		local tbl = {}
		tbl[1] = "A"
		tbl[3] = "B"
		table.getndebug(tbl)
	end, "table with gaps does not raise an error")
	local tbl = { "a", "b", "c" }
	Assert.areEqual(table.getndebug(tbl), #tbl)
	Assert.areEqual(table.getndebug(tbl), 3)
	tbl = {}
	Assert.areEqual(table.getndebug(tbl), #tbl)
	Assert.areEqual(table.getndebug(tbl), 0)
end
local standardLuaFunctions = { ["getn"] = true, ["remove"] = true, ["unpack"] = true, ["move"] = true, ["insert"] = true, ["find"] = true, ["maxn"] = true, ["concat"] = true, ["foreachi"] = true, ["foreach"] = true, ["sort"] = true, ["freeze"] = true, ["clear"] = true, ["pack"] = true, ["create"] = true, ["isfrozen"] = true }
for k in pairs(table) do
	if TableTest["test_" .. k] == nil and standardLuaFunctions[k] == nil then
		printWarning("Warning: no test function for function table." .. k)
	end
end
