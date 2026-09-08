-- Local values: IndexedSearch_mt
IndexedSearch = {}
local IndexedSearch_mt = Class(IndexedSearch)

-- Upvalues: IndexedSearch_mt
-- Local values: self
function IndexedSearch.new(fieldWeights)
	-- upvalues: (copy) IndexedSearch_mt
	local v3_ = IndexedSearch_mt
	local v4_ = setmetatable({}, v3_)
	v4_.documents = {}
	v4_.index = {}
	v4_.fieldWeights = fieldWeights or {}
	v4_.isDirty = true
	v4_.minTextLength = 2
	v4_.minTokenLength = 4
	v4_.maxTokenLength = 8
	v4_.ignoreCharacterPattern = "[%(%)%/%\\%[%]%{%}%-%.%_%\'%+%,%\"%$%&]"
	return v4_
end

function IndexedSearch:clear()
	self:reset()
	table.clear(self.documents)
	table.clear(self.index)
	self.isDirty = true
end

function IndexedSearch:cancel()
	if self.callbackFunc ~= nil then
		self.callbackFunc(nil)
	end
	self:reset()
end

function IndexedSearch:reset()
	self.callbackFunc = nil
	self.words = nil
	self.results = nil
	self.scoreMap = nil
	removeGlobalUpdateable(self)
end

function IndexedSearch:cleanSpecialCharacters(text)
	return string.gsub(text, self.ignoreCharacterPattern, " ")
end

-- Local values: number, _, raw, word, textLength, minLen, maxLen, i, j, substr
function IndexedSearch:tokenize(text, tokenCallback)
	local v13_ = self:cleanSpecialCharacters(text)
	for v14_ in string.gmatch(v13_, "%d+") do
		tokenCallback(v14_)
	end
	local v15_ = string.gsub(v13_, "%d+", " ")
	for _, v16_ in string.split(v15_, " ") do
		local v17_ = string.trim(utf8ToLower(v16_))
		local v18_ = utf8Strlen(v17_)
		if v18_ >= self.minTextLength then
			local v19_ = self.minTokenLength
			local v20_ = self.maxTokenLength
			local v21_ = math.min(v18_, v20_)
			for v22_ = 0, v18_ - v19_ do
				local v23_ = v18_ - v22_
				for v24_ = v19_, math.min(v21_, v23_) do
					tokenCallback((utf8Substr(v17_, v22_, v24_)))
				end
			end
			tokenCallback(v17_)
		end
	end
end

-- Local values: startTime, documentId, data
function IndexedSearch:build()
	local v26_ = getTimeSec()
	table.clear(self.index)
	for v27_, v28_ in ipairs(self.documents) do
		self:indexDocument(v27_, v28_)
	end
	Logging.devInfo("Build index in %.3f seconds", getTimeSec() - v26_)
	self.isDirty = false
end

-- Local values: doc, field, text, lowerText
function IndexedSearch:indexDocument(documentId, documentData)
	local v32_ = documentData.document
	for v_u_33_, v34_ in pairs(v32_) do
		self:tokenize(utf8ToLower(v34_), function(p35_)
			-- upvalues: (copy) self, (copy) v_u_33_, (copy) documentId
			self.index[p35_] = self.index[p35_] or {}
			local v36_ = self.index[p35_][v_u_33_]
			if v36_ == nil then
				self.index[p35_][v_u_33_] = documentId
				return
			elseif type(v36_) == "number" then
				self.index[p35_][v_u_33_] = {}
				self.index[p35_][v_u_33_][v36_] = true
				self.index[p35_][v_u_33_][documentId] = true
			else
				self.index[p35_][v_u_33_][documentId] = true
			end
		end)
	end
end

-- Local values: field, _, data
function IndexedSearch:addDocument(document, ref)
	for v40_, _ in pairs(self.fieldWeights) do
		if document[v40_] == nil then
			Logging.devError("Missing field \'%s\' in document", v40_)
			printCallstack()
			return false
		end
	end
	local v41_ = self.documents
	table.insert(v41_, {
		["document"] = document,
		["ref"] = ref
	})
	self.isDirty = true
	return true
end

-- Local values: words, _, raw
function IndexedSearch:search(text, callbackFunc)
	if text == nil then
		return false
	end
	if self.isDirty then
		return false
	end
	if string.isNilOrWhitespace(text) then
		return false
	end
	local v45_ = string.trim(text)
	if utf8Strlen(v45_) < self.minTextLength then
		return false
	end
	local v46_ = {}
	for _, v47_ in string.split(v45_, " ") do
		local v48_ = self:cleanSpecialCharacters((string.trim(utf8ToLower(v47_))))
		if utf8Strlen(v48_) >= self.minTextLength then
			table.insert(v46_, v48_)
		end
	end
	if #v46_ == 0 then
		return false
	end
	self:cancel()
	addGlobalUpdateable(self)
	self.results = nil
	self.words = v46_
	self.currentWordIndex = 1
	self.lastIndexWord = nil
	self.callbackFunc = callbackFunc
	return true
end

-- Local values: word, matches, indexedWord, dist, indexedWord, dist, penalty, wordLen, wordEntry, field, docs, weight, isExact, positionBonus, pos, exactBonus, score, documentId, _, score, scoredDocs, documentId, score, data, _, entry
function IndexedSearch:update(dt)
	if self.callbackFunc then
		if self.results == nil then
			if self.isDirty then
				self:sendCallback()
				return
			end
			self.results = {}
			self.scoreMap = {}
		end
		local v50_ = self.words[self.currentWordIndex]
		if v50_ ~= nil then
			local v51_ = {}
			if self.index[v50_] then
				v51_[v50_] = 0
			else
				for v52_ in pairs(self.index) do
					local v53_ = getLevenshteinDistance(v50_, v52_)
					if v53_ <= 2 then
						v51_[v52_] = v53_
					end
				end
			end
			for v54_, v55_ in pairs(v51_) do
				local v56_ = v55_ * 0.5
				local v57_ = #v54_
				local v58_ = self.index[v54_]
				for v59_, v60_ in pairs(v58_) do
					local v61_ = self.fieldWeights[v59_] or 1
					local v62_ = v54_ == v50_
					local v63_ = string.find(v54_, v50_, 1, true)
					local v64_
					if v63_ then
						local v65_ = 10 - (v63_ - 1)
						v64_ = math.max(0, v65_)
					else
						v64_ = 0
					end
					local v66_ = v62_ and 20 or 0
					if type(v60_) == "number" then
						local v67_ = v61_ * v57_ - v56_ + v64_ + v66_
						self.scoreMap[v60_] = (self.scoreMap[v60_] or 0) + v67_
					else
						for v68_, _ in pairs(v60_) do
							local v69_ = v61_ * v57_ - v56_ + v64_ + v66_
							self.scoreMap[v68_] = (self.scoreMap[v68_] or 0) + v69_
						end
					end
				end
			end
			self.currentWordIndex = self.currentWordIndex + 1
		end
		if v50_ == nil or self.currentWordIndex > #self.words then
			local v70_ = {}
			for v71_, v72_ in pairs(self.scoreMap) do
				local v73_ = self.documents[v71_]
				local v74_ = {
					["document"] = v73_.document,
					["ref"] = v73_.ref,
					["score"] = v72_
				}
				table.insert(v70_, v74_)
			end
			table.sort(v70_, function(p75_, p76_)
				return p75_.score > p76_.score
			end)
			for _, v77_ in ipairs(v70_) do
				local v78_ = self.results
				local v79_ = {
					["document"] = v77_.document,
					["ref"] = v77_.ref,
					["score"] = v77_.score
				}
				table.insert(v78_, v79_)
			end
			self:sendCallback()
		end
	end
end

function IndexedSearch:sendCallback()
	self.callbackFunc(self.results)
	self:reset()
end
