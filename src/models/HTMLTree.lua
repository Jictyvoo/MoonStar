local Stack = {}
function Stack:new()
    local StackNode = function(data)
        local self = {
            next, previous, data, constructor = function(this, data)
                this.next = nil; this.data = data; this.previous = nil
            end
        }
        self.constructor(self, data)
        local getNext = function() return self.next end
        local setNext = function(next) self.next = next end
        local getPrevious = function() return self.previous end
        local setPrevious = function(previous) self.previous = previous end
        local getData = function() return self.data end
        local setData = function(data) self.data = data end
        return {getNext = getNext, setNext = setNext, getPrevious = getPrevious, setPrevious = setPrevious, getData = getData, setData = setData}
    end
    local self = {
        current, size, constructor = function(this)
            this.current = nil; this.size = 0
        end 
    }
    self.constructor(self)
    local peek = function() return self.current and self.current.getData() or nil end
    local push = function(data)
        local newNode = StackNode(data)
        newNode.setNext(self.current)
        self.current = newNode
        self.size = self.size + 1
    end
    local pop = function()
        if(self.current) then
            local returnedData = self.current.getData()
            self.current = self.current.getNext()
            return returnedData
        end
        return nil
    end
    local isEmpty = function() return self.current == nil end
    local size = function() return self.size or 0 end
    return {peek = peek, push = push, pop = pop, isEmpty = isEmpty, size = size}
end

local HTMLTree = {}; HTMLTree.__index = HTMLTree

local function verifyCloseTag(tag)
    return tag.getName():match("/.+") and true or false
end

HTMLTree = setmetatable(HTMLTree, {
    __call = function(self, tags, elements, closeTags)
        local this = {tags = tags, documentRoot = nil}
        local returnObject = setmetatable({
            getTags = function() return this.tags end,
            getDocument = function() return this.documentRoot end
        }, getmetatable(HTMLTree))
        local tagTypes = {}
        for name, tag in pairs(elements) do
            returnObject[string.format("getElementsBy%s", name:gsub("^%l", string.upper))] = function() return elements[name] end
        end
        local function createNewRoot(tag)
            local newTag = (this.documentRoot)(); newTag.setName("div")
            newTag.addChild(this.documentRoot); newTag.addChild(tag); this.documentRoot = newTag
        end
        local function transferTagContent(tag)
            local pseudoTag = this.documentRoot(); pseudoTag.setName("text")
            pseudoTag.setContent(tag.getContent()); return pseudoTag
        end
        --[[ Here will be construct the synthatic tree --]]
        local stack = Stack:new()
        for _, tag in pairs(tags) do
            if not this.documentRoot then
                this.documentRoot = tag; stack.push(tag)
            else
                if verifyCloseTag(tag) then
                    if tagTypes[tag.getName():gsub("/", "")] then
                        while stack.peek() and tag:getName():sub(2) ~= stack.peek().getName() do
                            stack.pop()
                        end
                        if stack.peek() then
                            stack.pop()
                            if #tag.getContent() > 0 and tag.getContent():gsub("\t+", ""):match("%S") ~= nil then
                                if stack.peek() then stack.peek().addChild(transferTagContent(tag)) end
                            end
                        else
                            createNewRoot(tag)
                            --[[ error("Syntax error found") --]]
                        end
                    elseif #tag.getContent() > 0 and tag.getContent():gsub("\t+", ""):match("%S") ~= nil then
                        if stack.peek() then stack.peek().addChild(transferTagContent(tag)) end
                    end
                else
                    if stack.peek() then
                        stack.peek().addChild(tag)
                    else
                        createNewRoot(tag)
                    end
                    if closeTags["/" .. tag.getName()] then
                        stack.push(tag)
                    elseif #tag.getContent() > 0 and tag.getContent():gsub("\t+", ""):match("%S") ~= nil then 
                        local pseudoTag = tag
                        if #tag.getName() > 0 then                       
                            pseudoTag = this.documentRoot()
                        end
                        pseudoTag.setName("text"); pseudoTag.setContent(tag.getContent())
                        if stack.peek() and tag ~= pseudoTag then
                            tag.setContent("")
                            stack.peek().addChild(pseudoTag)
                        end
                    end
                    if not tagTypes[tag.getName()] then tagTypes[tag.getName()] = {} end
                    table.insert(tagTypes[tag.getName()], tag)
                    returnObject[string.format("get%s", tag.getName():gsub("^%l", string.upper))] = function()
                        return tagTypes[tag.getName()]
                    end
                end
            end
        end
        return returnObject
    end,
    __tostring = function(self) return tostring(self.getDocument()) end
})

return HTMLTree
