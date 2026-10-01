IndexedSearch = {}
local IndexedSearch_mt = Class(IndexedSearch)
function IndexedSearch.new(fieldWeights)
	local self = setmetatable({}, IndexedSearch_mt)
	self.documents = {}
	self.index = {}
	self.fieldWeights = fieldWeights or {}
	self.isDirty = true
	self.minTextLength = 2
	self.minTokenLength = 4
	self.maxTokenLength = 8
	self.ignoreCharacterPattern = "[%(%)%/%\\%[%]%{%}%-%.%_%'%+%,%\"%$%&]"
	return self
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
function IndexedSearch:tokenize(text, tokenCallback)
	text = self:cleanSpecialCharacters(text)
	for number in string.gmatch(text, "%d+") do
		tokenCallback(number)
	end
	text = string.gsub(text, "%d+", " ")
	for _, raw in string.split(text, " ") do
		local word = string.trim(utf8ToLower(raw))
		local textLength = utf8Strlen(word)
		if textLength < self.minTextLength then
			continue
		end
		local minLen = self.minTokenLength
		local maxLen = math.min(textLength, self.maxTokenLength)
		for i = 0, textLength - minLen do
			for j = minLen, math.min(maxLen, textLength - i) do
				local substr = utf8Substr(word, i, j)
				tokenCallback(substr)
			end
		end
		tokenCallback(word)
	end
end
function IndexedSearch:build()
	local startTime = getTimeSec()
	table.clear(self.index)
	for documentId, data in ipairs(self.documents) do
		self:indexDocument(documentId, data)
	end
	Logging.devInfo("Build index in %.3f seconds", getTimeSec() - startTime)
	self.isDirty = false
end
function IndexedSearch:indexDocument(documentId, documentData)
	local doc = documentData.document
	for field, text in pairs(doc) do
		local lowerText = utf8ToLower(text)
		self:tokenize(lowerText, function(word)
			self.index[word] = self.index[word] or {}
			local data = self.index[word][field]
			if data == nil then
				self.index[word][field] = documentId
			elseif type(data) == "number" then
				self.index[word][field] = {}
				self.index[word][field][data] = true
				self.index[word][field][documentId] = true
			else
				self.index[word][field][documentId] = true
			end
		end)
	end
end
function IndexedSearch:addDocument(document, ref)
	for field, _ in pairs(self.fieldWeights) do
		if document[field] == nil then
			Logging.devError("Missing field '%s' in document", field)
			printCallstack()
			return false
		end
	end
	local data = { document = document, ref = ref }
	table.insert(self.documents, data)
	self.isDirty = true
	return true
end
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
	text = string.trim(text)
	if utf8Strlen(text) < self.minTextLength then
		return false
	end
	local words = {}
	for _, raw in string.split(text, " ") do
		local raw = string.trim(utf8ToLower(raw))
		raw = self:cleanSpecialCharacters(raw)
		if self.minTextLength <= utf8Strlen(raw) then
			table.insert(words, raw)
		end
	end
	if #words == 0 then
		return false
	else
		self:cancel()
		addGlobalUpdateable(self)
		self.results = nil
		self.words = words
		self.currentWordIndex = 1
		self.lastIndexWord = nil
		self.callbackFunc = callbackFunc
		return true
	end
end
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
		local word = self.words[self.currentWordIndex]
		if word ~= nil then
			local matches = {}
			if self.index[word] then
				matches[word] = 0
			else
				for indexedWord in pairs(self.index) do
					local dist = getLevenshteinDistance(word, indexedWord)
					if dist <= 2 then
						matches[indexedWord] = dist
					end
				end
			end
			for indexedWord, dist in pairs(matches) do
				local penalty = dist * 0.5
				local wordLen = #indexedWord
				local wordEntry = self.index[indexedWord]
				for field, docs in pairs(wordEntry) do
					local weight = self.fieldWeights[field] or 1
					local isExact = indexedWord == word
					local positionBonus = 0
					local pos = string.find(indexedWord, word, 1, true)
					if pos then
						positionBonus = math.max(0, 10 - (pos - 1))
					end
					local exactBonus = isExact and 20 or 0
					if type(docs) == "number" then
						local score = weight * wordLen - penalty + positionBonus + exactBonus
						self.scoreMap[docs] = (self.scoreMap[docs] or 0) + score
					else
						for documentId, _ in pairs(docs) do
							local score = weight * wordLen - penalty + positionBonus + exactBonus
							self.scoreMap[documentId] = (self.scoreMap[documentId] or 0) + score
						end
					end
				end
			end
			self.currentWordIndex = self.currentWordIndex + 1
		end
		if word == nil or #self.words < self.currentWordIndex then
			local scoredDocs = {}
			for documentId, score in pairs(self.scoreMap) do
				local data = self.documents[documentId]
				table.insert(scoredDocs, { score = score, document = data.document, ref = data.ref })
			end
			table.sort(scoredDocs, function(a, b)
				return b.score < a.score
			end)
			for _, entry in ipairs(scoredDocs) do
				table.insert(self.results, { document = entry.document, ref = entry.ref, score = entry.score })
			end
			self:sendCallback()
		end
	end
end
function IndexedSearch:sendCallback()
	self.callbackFunc(self.results)
	self:reset()
end
