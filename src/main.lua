--[[ This is a test file, so use this compiled version to test the funcionality only --]]
local parserHTML = require("models.ParserHTML")
parserHTML = parserHTML(true, arg[1])
local file = io.open("./output.debug", "w")
for index, token in pairs(parserHTML.tokenList) do
    file:write(tostring(token) .. "\n")
end
file:close()
