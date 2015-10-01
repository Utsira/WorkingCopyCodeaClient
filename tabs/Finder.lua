Finder = class()

function Finder:init(w)
    self.paths = {"/"}
    self.titles = {"Repositories"}
    self.window = Soda.Frame{
        title = "Repositories",
        x = 0, y = 0, w = w, h = 1,
   --     shape = Soda.rect
    }
    self.backButton = Soda.BackButton{
        parent = self.window,
        x = 5, y = -5,
        style = Soda.style.icon,
        hidden = true,
        callback = function()
            table.remove(self.paths)
            table.remove(self.titles)
            self:requestFileNames()
        end
    }
   -- self.depth = 1
    self:requestFileNames()
end

function Finder:requestFileNames()
     Request.properties(self.paths[#self.paths], function(data, status, headers) self:getFileNames(data, status) end)
end

function Finder:getFileNames(data, status)
    if not data then 
        Soda.Alert{title = status}
        return 
    end
    UI.preview:clearString()
    local listText = {}
    self.items = {} 
    self.remoteFiles = {}
    if self.list then self.list.kill = true end

    parsePropfind(data, function(i, t) listText[i], self.items[i] = self:addLine(t) end)
    
    self.window.title = self.titles[#self.titles] --self.paths[#self.paths]
    
    if #self.paths > 1 then 
        
        if #self.paths == 2 and not UI.workbench.active then
            UI.settingsButton:hide()
            self.backButton:show()
            UI.workbench:activate(self.paths[2], self.titles[2], data, table.copy(self.items))
           -- UI.link.callback = function() self:linkProject() end
        end
    else   --depth 1

        UI.workbench:deactivate()
      --  UI.workbench.kill = true
      --  UI.workbench = Workbench()
        UI.settingsButton:show()
        self.backButton:hide()
    end
    
    self.list = Soda.List{
        parent = self.window,
        x = 0, y = 0, w = 1, h = -50,
        text = listText,
        callback = function(sender, selected, txt) self:selectItem(selected) end
    }  
    
end

function parsePropfind(data, callback, callbackFinish)
    local i = 0
    for pathName, info in data:gmatch("<D:href>(.-)</D:href>(.-)[\n\r]") do
        i = i + 1
        if i>1 then --the first entry is just the root
            local name = pathName:match("/([^/]-)$") --strip out path from name
            --print("name", name)
            local extension = name:match(".-%.(.-)$") --file extension  
            local nameNoExt = name:match("(.-)%..-$")
            local collection
            if info:find("<D:resourcetype><D:collection/></D:resourcetype>") then --collection
        collection = true end
            callback(i-1,  {pathName = pathName, collection = collection, name = name, nameNoExt = nameNoExt, extension = extension})
        end
    end
    callbackFinish = callbackFinish or null 
    callbackFinish(i-1)
end

function Finder:addLine(t)

    local printName = t.name:gsub("%%20", " ") --put spaces back
    if t.collection then
    
        printName = "\u{1f4c2}  "..printName
             --   table.insert(self.subFolders, name.."/")
    end

    --[[
    if extension == "lua" then
        table.insert(self.remoteFiles, {name = name:match("(.-)%.lua$")})
    end
      ]]

    return printName, t
end

function Finder:selectItem(selected) --sender is always self.list
    local item = self.items[selected.idNo]
    if item.collection then
       -- if #self.paths == 1 then self.title = item.name end
        table.insert(self.titles, item.name)
        table.insert( self.paths, item.pathName.."/")
        
        self:requestFileNames()
 
    else

        Request.get(item.pathName, function(data)  UI.preview:inputString(data) end)
    end
end



