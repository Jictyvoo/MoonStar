local MoleScrapper = {}

MoleScrapper.__index = MoleScrapper

MoleScrapper = setmetatable(MoleScrapper, {
    __call = function(self, ...)
        local this = self:new(...)
    end
})

function MoleScrapper:new()
    return setmetatable({
        socket = require("socket")
    }, MoleScrapper)
end

return MoleScrapper

