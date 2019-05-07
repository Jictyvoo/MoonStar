--[[ This is a test file, so use this compiled version to test the funcionality only --]]
local parserHTML = require("models.ParserHTML")
parserHTML = parserHTML(true, arg[1])
local file = io.open("./output.moon", "w")
file:write([[
import Widget from require "lapis.html"

class Index extends Widget
  content: =>
]])
file:write(tostring(parserHTML:getHTMLTree().getDocument()))
file:close()
