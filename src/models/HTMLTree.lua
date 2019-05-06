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
        for name, tag in pairs(elements) do
            returnObject[string.format("getElementsBy%s", name:gsub("^%l", string.upper))] = function() return elements[name] end
        end
        --[[ Here will be construct the synthatic tree --]]
        local stack = Stack:new()
        for _, tag in pairs(tags) do
            if not this.documentRoot then
                this.documentRoot = tag; stack.push(tag)
            else
                if verifyCloseTag(tag) then
                    while stack.peek() and tag:getName():sub(2) ~= stack.peek().getName() do
                        stack.pop()
                    end
                    if stack.peek() then
                        stack.pop(); stack.peek().addChild(tag.getContent())
                    else
                        error("Syntax error found")
                    end
                else
                    stack.peek().addChild(tag)
                    if closeTags["/" .. tag.getName()] then
                        stack.push(tag)
                    end
                end
            end
        end
        return returnObject
    end,
    __tostring = function(self) return tostring(self.getDocument()) end
})

return HTMLTree
