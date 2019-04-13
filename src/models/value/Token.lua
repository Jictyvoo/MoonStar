local Token = {}; Token.__index = Token

Token = setmetatable(Token, {
    __call = function(self, lexeme, tokenType, lineCounter, column, filename)
        local this = {lexeme = lexeme, tokenType = tokenType, line = lineCounter, column = column, filename = filename}
        return setmetatable({
            getLexeme = function() return this.lexeme end,
            getType = function() return this.tokenType end,
            getLine = function() return this.line end,
            getColumn = function() return this.column end,
            getFilename = function() return this.filename end
        }, getmetatable(Token))
    end,
    __tostring = function(self) return string.format("%s %d:%d %s -- Type: %s", self.getFilename(), self.getLine(), self.getColumn(), self.getLexeme(), self.getType()) end
})

return Token
