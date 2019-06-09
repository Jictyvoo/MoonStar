# MoonStar

Is a program that helps Lapis User to convert html pages to Moonscript pages. If has a problem with your HTML, MoonStar tries to fix it, and work properly

## Components

### ParserHTML

Is a html parser that helps to find elements by id and also by tag type. This parser was designed to accept anytime of tag. Obs, comment tags are ignored.

## Usage

Run the binary file with your html file as argument. You can too import the program source and use it to parse a specific part of an HTML.

### Importing as a library

To use library in your project, execute command below on your project repository

```shell
git submodule add https://github.com/Jictyvoo/MoonStar
```
After that you can import the library easily, like

```lua
    require "libs.MoonStar"
```
Below you can see all methods

* __call = function(self, isFile, ...) - This function allows you to get the generated object calling MoonStar table. Here's a example 
```lua
    local MoonStar = require "libs.MoonStar"
    MoonStar(false, "<html><head><meta charset='utf-8'></head></html>")
    --[[ starting scrapping --]]
    MoonStar.getHTMLTree().getDocument() --this will return all document
```

* parse(data, isFile) - This function is the main function called, is the same function called in __call

* deepParse(data) - This function is when you don't have all html data complete at once. So, you can use this function a lot of times to parse your splited file.

* getHTMLTree() - This Function return the HTML Tree of the data passed. The HTML Tree returned has the main method "getDocument" that will returns the root tag, it is, the first tag in your document, or a DIV auto-generated to help parse document.

* getElementsBy... - Based on all tags in your HTML, if has a Lua tag in your HTML, MoonStar will generate in HTML Tree a function named getLua(), that return a table with all Lua tags. The same occurs to getElementsBy, but this returns elements selected by attributes, like: getElementsById(). This function can also be called using a identifier, like getElementsById("someId"), whitch returns a Tag element.

## Goals

* Fix a bug when have a tag that can be closed or not closed
