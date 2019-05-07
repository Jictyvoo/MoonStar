--[[ This is a test file, so use this compiled version to test the funcionality only --]]

local function findLast(haystack, needle)
  local i = haystack:match(".*" .. needle .. "()")
  if i == nil then return nil else return i-1 end
end

local parserHTML = require("models.ParserHTML")
parserHTML = parserHTML(true, arg[1])
local file = io.open(string.format("%smoon", arg[1]:sub(1, findLast(arg[1], "%."))), "w")
file:write([[
import Widget from require "lapis.html"

class Index extends Widget
  content: =>
]])
file:write(tostring(parserHTML:getHTMLTree().getDocument()))
file:close()
