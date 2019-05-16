local currentPath = (...):gsub('%.init$', '') .. "."
local ParserHTML = require(string.format("%ssrc.models.ParserHTML", currentPath))
local instance = nil

return setmetatable({
    parse = function(data, isFile) instance = ParserHTML:new(data); return instance:parse(nil, isFile) end,
    deepParse = function(data) if not instance then instance = ParserHTML:new("<html></html>"); instance:createTagInfo() end instance:deepParse(data) end,
    getHTMLTree = function() if instance then return instance:getHTMLTree() end return nil end
}, {
    __call = function(self, isFile, ...)
        instance = ParserHTML(isFile, ...); return instance
    end
})
