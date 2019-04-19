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
            previous = nil, tagLexeme = {}, tagInfo = nil, lineCount = 1, openComment = false
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
            if tagType == "open-comment" then self.lexycalAttributes.openComment = true end
            table.insert(self.tokenList, Token(name, tagType, self.lexycalAttributes.lineCount, column, self.filename))
        else
            self.lexycalAttributes.tagInfo.attributes[name] = ""
            self.lexycalAttributes.tagInfo.lastAttribute = name
            table.insert(self.tokenList, Token(name, "attribute", self.lexycalAttributes.lineCount, column, self.filename))
        end
    end
    self.lexycalAttributes.tagLexeme = {}
end

function ParserHTML:writeTagContent()
    if #self.lexycalAttributes.tagLexeme > 0 then
        local content = tableString(self.lexycalAttributes.tagLexeme):lower()
        table.insert(self.tokenList, Token(content, "content", self.lexycalAttributes.lineCount, 0, self.filename))
        self.lexycalAttributes.tagLexeme = {}
    end
end

function ParserHTML:verifyEndComment(remove)
    local last = self.lexycalAttributes.tagLexeme[#self.lexycalAttributes.tagLexeme]
    local penultimate = self.lexycalAttributes.tagLexeme[#self.lexycalAttributes.tagLexeme - 1]
    local isEndComment = false
    if last == "-" and penultimate == "-" then
        isEndComment = true
    end
    if isEndComment and remove then
        table.remove(self.lexycalAttributes.tagLexeme, #self.lexycalAttributes.tagLexeme)
        table.remove(self.lexycalAttributes.tagLexeme, #self.lexycalAttributes.tagLexeme)
    end
    return isEndComment
end

function ParserHTML:deepParse(data)
    --[[ verifying if is a tag start--]]
    local splited = self:splitString(data)
    for _, word in pairs(splited) do
        if self.lexycalAttributes.openComment then
            if word == ">" then
                local isEndComment = self:verifyEndComment(true)
                if isEndComment then
                    table.insert(self.tokenList, Token(tableString(self.lexycalAttributes.tagLexeme), "comment-content", self.lexycalAttributes.lineCount, _, self.filename))
                    table.insert(self.tokenList, Token("--", "end-comment", self.lexycalAttributes.lineCount, _, self.filename))
                    self.lexycalAttributes.tagLexeme = {}
                    self.lexycalAttributes.openComment = false; self.lexycalAttributes.openTag = false
                end
            else
                table.insert(self.lexycalAttributes.tagLexeme, word)
            end
        elseif self.lexycalAttributes.openTag then
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
            if word == "<" and splited[_ + 1] ~= string.char(9) and splited[_ + 1] ~= string.char(32) then
                self:writeTagContent()
                self.lexycalAttributes.openTag = true
                self:createTagInfo()
            else
                table.insert(self.lexycalAttributes.tagLexeme, word)
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

