local ParserHTML = {}

--[[ Imports --]]
local currentPath = (...):gsub('%.ParserHTML$', '') .. "."
local HTMLTree = require(string.format("%sHTMLTree", currentPath))
local Token = require(string.format("%svalue.Token", currentPath))
local Tag = require(string.format("%svalue.Tag", currentPath))
--[[ local HTMLTree = require("models.HTMLTree") --]]
--[[ local Token = require("models.value.Token") --]]
--[[ local Tag = require("models.value.Tag") --]]

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
            previous = nil, tagLexeme = {}, tagInfo = nil, lineCount = 1, openComment = false,
            codeTags = {script = true}, openCode = false
        },
        data = data, htmlTree = nil, tokenList = {}, filename = "direct-parse",
        tags = {}, elements = {}, closeTags = {["/!document"] = true}
    }, ParserHTML)
end

local function tableString(stringTable)
    return string.format(("%s"):rep(#stringTable), table.unpack(stringTable))
end

function ParserHTML:addCodeTag(codeTag)
    self.lexycalAttributes.codeTags[codeTag] = true
end

function ParserHTML:createTagInfo(name)
    self.lexycalAttributes.tagInfo = {name = name or "", attributes = {}, lastAttribute = "", content = "", children = {}}
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
            if tagType == "open-comment" then self.lexycalAttributes.openComment = true
            elseif tagType == "close-tag" then
                self.closeTags[name] = true
                if self.lexycalAttributes.codeTags[name:gsub("/", "")] then self.lexycalAttributes.openCode = false end
            elseif self.lexycalAttributes.codeTags[name] then
                self.lexycalAttributes.openCode = name
            end
            table.insert(self.tokenList, Token(name, tagType, self.lexycalAttributes.lineCount, column - #name, self.filename))
        elseif name ~= "/" then
            self.lexycalAttributes.tagInfo.attributes[name] = ""
            self.lexycalAttributes.tagInfo.lastAttribute = name
            table.insert(self.tokenList, Token(name, "attribute", self.lexycalAttributes.lineCount, column - #name, self.filename))
        end
    end
    self.lexycalAttributes.tagLexeme = {}
end

function ParserHTML:writeTagContent()
    if #self.lexycalAttributes.tagLexeme > 0 then
        local content = tableString(self.lexycalAttributes.tagLexeme)
        self.lexycalAttributes.tagInfo.content = content
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
                    if self.lexycalAttributes.tagInfo.lastAttribute ~= "" and self.tokenList[#self.tokenList - 1].getType() == "attributition" then
                        self.lexycalAttributes.tagInfo.attributes[self.lexycalAttributes.tagInfo.lastAttribute] = currentLexeme
                        if not self.elements[self.lexycalAttributes.tagInfo.lastAttribute] then
                            self.elements[self.lexycalAttributes.tagInfo.lastAttribute] = {}
                        end
                        table.insert(self.elements[self.lexycalAttributes.tagInfo.lastAttribute], Tag(self.lexycalAttributes.tagInfo))
                    end
                elseif isQuotation and not self.lexycalAttributes.openString then
                    self.lexycalAttributes.openString = word
                else
                    table.insert(self.lexycalAttributes.current, word)
                end
            elseif word == ">" then
                self.lexycalAttributes.openTag = false
                self:writeTokenEnd(_)
                self.lexycalAttributes.tagInfo.lastAttribute = nil; table.insert(self.tags, Tag(self.lexycalAttributes.tagInfo))
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
            local isQuotation = (word == "\"" or word == "\'")
            if self.lexycalAttributes.openCode and isQuotation or self.lexycalAttributes.openString then
                if self.lexycalAttributes.openString and self.lexycalAttributes.openString == word then
                    self.lexycalAttributes.openString = false
                else
                    self.lexycalAttributes.openString = word
                end
                table.insert(self.lexycalAttributes.tagLexeme, word)
            elseif word == "<" and splited[_ + 1] ~= string.char(9) and splited[_ + 1] ~= string.char(32)
             and (not self.lexycalAttributes.openCode or (self.lexycalAttributes.openCode and splited[_ + 1] == string.char(47))) then
                self:writeTagContent()
                if #self.tags <= 0 and #self.lexycalAttributes.tagInfo.content > 0 then
                    table.insert(self.tags, Tag({name = "div", attributes = {}, content = "", children = {}}))
                    table.insert(self.tags, Tag(self.lexycalAttributes.tagInfo))
                end
                self.lexycalAttributes.openTag = true
                self:createTagInfo()
            else
                table.insert(self.lexycalAttributes.tagLexeme, word)
            end
        end
        self.lexycalAttributes.previous = word
    end
end

function ParserHTML:generateHTMLTree()
    self.htmlTree = HTMLTree(self.tags, self.elements, self.closeTags)
end

function ParserHTML:parse(data, isFile)
    self:createTagInfo()
    self.lexycalAttributes.lineCount = 1; self.htmlTree = nil
    if data or not isFile then
        self.filename = "direct-parse"
        self:deepParse(data or self.data)
    else
        self.filename = data or self.data
        for line in io.lines(data or self.data) do
            self:deepParse(line) --[[ self:deepParse(string.format("%s\\n", line)) --]]
            self.lexycalAttributes.lineCount = self.lexycalAttributes.lineCount + 1
        end
    end
    self.data = false; self.isFile = false; self:generateHTMLTree(); return self.htmlTree
end

function ParserHTML:getHTMLTree()
    if not self.htmlTree then self:generateHTMLTree() end
    return self.htmlTree
end

return ParserHTML
