Finder = class()

function Finder:init(w,h)
    self.paths = {"/"}
    self.titles = {"Repositories"}
    self.window = Soda.Frame{
        title = "Repositories",
        x = 0, y = 0, w = w, h = h-1,
        shape = Soda.rect
    }
    self.backButton = Soda.BackButton{
        parent = self.window,
        x = 5, y = -5,
        -- style = Soda.style.icon,
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

    local listText = {}
    self.items = {} 
    self.remoteFiles = {}

    local containsLuaFiles = parsePropfind(data, function(i, t) listText[i], self.items[i] = self:addLine(t) end)
    
    self.window.title = self.titles[#self.titles] --self.paths[#self.paths]
    if workbench then
        workbench:deactivate()
        workbench = nil
    end
    if #self.paths > 1 then
        UI.settingsButton:hide()
        self.backButton:show()
        
        if containsLuaFiles then       
            --  workbench:activate(self.paths[2], self.titles[2], data, table.copy(self.items))
            workbench = Workbench{path = self.paths[#self.paths], name = self.titles[#self.titles], data = data, items = table.copy(self.items), repo = self.titles[2], repoPath = table.concat(self.titles, "/", 3)}
            
      --  else
        end
    else   --depth 1
        
        UI.settingsButton:show()
        self.backButton:hide()
    end
 
  --  end
    if self.list then self.list.kill = true end
    self.list = Soda.List{
        parent = self.window,
        x = 0, y = 0, w = 1, h = -50,
        title = "finder list",
        text = listText,
        callback = function(sender, selected, txt) self:selectItem(selected) end
    }  
    
end

function parsePropfind(data, callback, callbackFinish)
    local i = 0
    local containsLuaFiles
    for pathName, info in data:gmatch("<D:href>(.-)</D:href>(.-)[\n\r]") do
        i = i + 1
        if i>1 then --the first entry is just the root
            local name = pathName:match("/([^/]-)$"):gsub("%%20", " ") --strip out path from name; put spaces back
            --print("name", name)
            local extension = name:match(".-%.(.-)$") --file extension  
            if extension == "lua" then containsLuaFiles = true end
            local nameNoExt = name:match("(.-)%..-$")
            local collection
            if info:find("<D:resourcetype><D:collection/></D:resourcetype>") then --collection
        collection = true end
            callback(i-1,  {pathName = pathName, collection = collection, name = name, nameNoExt = nameNoExt, extension = extension})
        end
    end
    callbackFinish = callbackFinish or null 
    callbackFinish(i-1)
    return containsLuaFiles
end

function Finder:addLine(t)

    local printName = t.name --:gsub("%%20", " ") --put spaces back
    if t.collection then
        printName = "\u{1f4c2}  "..printName
    end

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
        Request.get(item.pathName, function(data)  
            if item.extension == "html" then
                openURL(DavHost..item.pathName, true)
            else
                preview=Preview{path = item.pathName, name = item.name, data = data, multiProject = workbench.multiProject, repo = self.titles[2]} 
            end
        end)
    end
end



