local ParserHTML = {}
local Token = require("models.value.Token")

ParserHTML.__index = ParserHTML

ParserHTML = setmetatable(ParserHTML, {
    __call = function(self, isFile, ...)
        local this = self:new(...)
        this:parse(self.data, isFile)
        return this
    end
})

function ParserHTML:new(data)
    return setmetatable({
        lexycalAttributes = {
            openTag = false, openString = false, current = {}, isAttribute = false,
            previous = nil, tagLexeme = {}, tagInfo = nil, lineCount = 1
        },
        data = data, result = {}, tokenList = {}, filename = "direct-parse",
        tags = {}, ids = {}
    }, ParserHTML)
end

local function tableString(stringTable)
    return string.format(("%s"):rep(#stringTable), table.unpack(stringTable))
end

function ParserHTML:createTagInfo()
    self.lexycalAttributes.tagInfo = {name = "", attributes = {}}
end

function ParserHTML:splitString(toSplit)
    local splited = {}
    for word in toSplit:gmatch(".") do table.insert(splited, word) end
    return splited
end

function ParserHTML:writeTokenEnd(column)
    local name = tableString(self.lexycalAttributes.tagLexeme):lower()
    if #name > 0 then
        if self.lexycalAttributes.tagInfo.name == "" then
            self.lexycalAttributes.tagInfo.name = name
            local tagType = name:sub(1, 3) == "!--" and "open-comment" or name:sub(1, 1) == "/" and "close-tag" or "open-tag"
            table.insert(self.tokenList, Token(name, tagType, self.lexycalAttributes.lineCount, column, self.filename))
        else
            self.lexycalAttributes.tagInfo.attributes[name] = ""
            self.lexycalAttributes.tagInfo.lastAttribute = name
            table.insert(self.tokenList, Token(name, "attribute", self.lexycalAttributes.lineCount, column, self.filename))
        end
    end
    self.lexycalAttributes.tagLexeme = {}
end

function ParserHTML:deepParse(data)
    --[[ verifying if is a tag start--]]
    local splited = self:splitString(data)
    for _, word in pairs(splited) do
        if self.lexycalAttributes.openTag then
            local isQuotation = (word == "\"" or word == "\'")
            --[[ Here's the code to identify strings in attributes --]]
            if isQuotation or self.lexycalAttributes.openString then
                if self.lexycalAttributes.openString and isQuotation and self.lexycalAttributes.openString == word then
                    self.lexycalAttributes.openString = false
                    local currentLexeme = tableString(self.lexycalAttributes.current)
                    self.lexycalAttributes.current = {}
                    table.insert(self.tokenList, Token(currentLexeme, "string", self.lexycalAttributes.lineCount, _, self.filename))
                elseif isQuotation and not self.lexycalAttributes.openString then
                    self.lexycalAttributes.openString = word
                else
                    table.insert(self.lexycalAttributes.current, word)
                end
            elseif word == ">" then
                self.lexycalAttributes.openTag = false
                self:writeTokenEnd(_)
            else
                if word ~= string.char(9) and word ~= string.char(32) and word ~= "=" then
                    table.insert(self.lexycalAttributes.tagLexeme, word)
                else
                    self:writeTokenEnd(_)
                    if word == "=" then
                        table.insert(self.tokenList, Token(word, "attributition", self.lexycalAttributes.lineCount, _, self.filename))
                    end
                end
            end
        else
            if word == "<" then
                self.lexycalAttributes.openTag = true
                self:createTagInfo()
            end
        end
        self.lexycalAttributes.previous = word
    end
end

function ParserHTML:parse(data, isFile)
    self.lexycalAttributes.lineCount = 1
    if data or not isFile then
        self.filename = "direct-parse"
        self:deepParse(data or self.data)
    else
        self.filename = data or self.data
        for line in io.lines(data or self.data) do
            self:deepParse(line)
            self.lexycalAttributes.lineCount = self.lexycalAttributes.lineCount + 1
        end
    end
    self.data = false; self.isFile = false
end

return ParserHTML

