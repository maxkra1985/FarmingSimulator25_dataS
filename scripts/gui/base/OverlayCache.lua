-- Local values: OverlayCache_mt
OverlayCache = {}
local OverlayCache_mt = Class(OverlayCache)

-- Upvalues: OverlayCache_mt
-- Local values: self
function OverlayCache.new(customMt)
	-- upvalues: (copy) OverlayCache_mt
	local v3_ = customMt or OverlayCache_mt
	local v4_ = setmetatable({}, v3_)
	v4_.cache = {}
	return v4_
end

-- Local values: key, overlay
function OverlayCache:clearCache()
	for v6_, v7_ in pairs(self.cache) do
		if v7_ ~= 0 then
			delete(v7_)
		end
		self.cache[v6_] = nil
	end
end

-- Local values: overlay
function OverlayCache:addOverlay(filename)
	if self.cache[filename] == nil and not string.isNilOrWhitespace(filename) then
		local v10_ = createImageOverlay(filename)
		if v10_ ~= 0 then
			self.cache[filename] = v10_
		end
	end
end
