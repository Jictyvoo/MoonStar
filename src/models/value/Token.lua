local Token = {}; Token.__index = Token

Token = setmetatable(Token, {
    __call = function(self, lexeme, tokenType)
        local this = {lexeme = lexeme, tokenType = tokenType}
        return setmetatable({
            getLexeme = function() return this.lexeme end,
            getType = function() return this.tokenType end
        }, getmetatable(Token))
    end,
    __tostring = function(self) return string.format("Lexeme:%s -- Type: %s", self.getLexeme(), self.getType()) end
})

return Token
