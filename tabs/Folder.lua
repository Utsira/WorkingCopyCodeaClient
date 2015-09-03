Folder = class()

function Folder:init(data, x)
    self.lines={}
    self.x = x
    self.depth = #pathElements
    local c = 0
    print("path:",path)
    self.parentLink = parentLinked()
    for name, info in data:gmatch("<D:href>(.-)</D:href>(.-)[\n\r]") do
       -- sound(SOUND_BLIT, 29081)
        c = c + 1
        if c>1 then --the first entry is just the root
            local collection = false        
            if info:find("<D:resourcetype><D:collection/></D:resourcetype>") then collection = true end
            table.insert(self.lines, self:addLine(name, collection))
        end
     --   print(name)
    end
    local h = math.max(panelY, c * 60)
    local y = panelY - h
    self.y = 0
    self.h = h
    local back = Control(path, 20, y, 500, h) --520
    back.background = color(229, 229, 229, 255)
    back.enabled = false
    back.fontSize = 22
    table.insert(self.lines[1], 1, back)
-- print(path, table.concat(UX.files, "\n"))
end

function Folder:draw()
    pushMatrix()
    clip(self.x+20+currentX,20, 520,panelY-20)
   -- background(229, 229, 229, 255)
    stroke(127, 127, 127, 255)
    strokeWidth(1)
    line(self.x+20+currentX,20,self.x+20+currentX,panelY-20)
        translate(self.x+currentX, self.y)
    for _, row in ipairs(self.lines) do
        for _,element in pairs(row) do
            element:draw()
        end
    end
    clip()
    popMatrix()
end

function Folder:touched(touch)
    local t = {x=touch.x, y=touch.y, state=touch.state}
    t.x = t.x - self.x - currentX
    t.y = t.y - self.y
     for _, row in ipairs(self.lines) do
        for _,element in pairs(row) do
            if element:touched(t) and element.enabled then return end
        end
    end   
    if self.lines[1][1]:touched(t) then 
        if touch.state == MOVING then
        self.y = clamp(self.y + touch.deltaY, 0, math.max( 0, self.h - panelY))
            --[[
        local elastic = 0
        if self.y>0 then
            elastic = -self.y * 0.1
        end
        self.y = self.y + elastic
              ]]
        
        elseif touch.state == ENDED then
            if self.depth<#pathElements then
                pathTruncate(self.depth)            
            end        
        end
    end
end

function Folder:addLine(pathName, collection)
    local name = pathName:match("^"..path.."(.+)") --strip out path from name
    local extension = name:match(".-%.(.-)$") --file extension  
    local printName = name:gsub("%%20", " ") --put spaces back
    if collection then printName = "\u{1f4c2}  "..printName end --folder icon
    if name == "Info.plist" then
       -- self:requestFile(pathName, function(data, status) self:readPList(data, status) end)   
        Request.get(pathName, function(data, status) self:readPList(data, status) end) 
    end
    --  if extension == "lua" or 
    local linked = false
    local linkText, linkable = "Link", true
    if projects[pathName] then linked, linkText = true, "Relink" end
    if self.parentLink then --a child cannot be linked if its parent, grandparent etc already is
        linkText = "Linked"
        linkable = false
        linked = false
    end
    local n = #self.lines
    local y = panelY - (n+1.5) * 60
    local w,h = textSize(printName)
    w = w + 40
    local new
    if linked then
        new={
        name = Button(printName, 20.0, y, w, 60, 0, test_Clicked), --540
      --  copy = Button('Copy', 500.0, y, 60.0, 60, 6, test_Clicked),
        
        push = Button('Push', 340, y, 60.0, 60, 6, function() self:push(pathName, collection) end), --560
        pull = Button('Pull', 400, y, 60.0, 60, 6, test_Clicked), --620
        link = Button(linkText, 460, y, 60.0, 60, 6), --680
    }
    else
        new={
        name = Button(printName, 20.0, y, w, 60, 0, test_Clicked),--660
      --  copy = Button('Copy', 500.0, y, 60.0, 60, 6, test_Clicked),
        link = Button(linkText, 460, y, 60.0, 60, 6)} --680
    end
    new.link.callback = function() Dialog.linkProject(new, pathName, name) end
    new.link.enabled = linkable
   -- new.push.enabled = linked
   -- new.pull.enabled = linked
    new.name.textMode = CORNER
    new.name.callback = function() 
        if self.depth<#pathElements then
            pathTruncate(self.depth)
            
        elseif collection then
        --  path = path..name.."/"         
            table.insert(pathElements, name.."/")
            path = table.concat(pathElements)
           -- UX.main.back.enabled = true
            requestFileNames()
          --  UX.main.path.text = path
        end
        if not collection then
           -- http.request(DavHost..path..name, getFileData, httpfail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "GET"})
           -- self:requestFile(pathName, getFileData)
            Request.get(pathName, getFileData)
        end
    end
    return new
end

--[[
function Folder:requestFile(pathName, success)
    http.request(DavHost..pathName, success, function(error) httpfail(error, function() self:requestFile(pathName, success) end) end, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "GET"})
end
  ]]

function Folder:readPList(data, status)
    if not data then alert(status) return end
    local array = data:match("<key>Buffer Order</key>%s-<array>(.-)</array>")
    self.tabs = {}
    for tabName in array:gmatch("<string>(.-)</string>%s") do
        table.insert(self.tabs, {name = tabName})
    end
   -- print(table.concat(tabs, ","))
    if #self.tabs>0 then
        --add copy into tab button
        local copy = Button('Copy-into-project', 420.0, panelY - (#self.lines+1.5) * 60, 100.0, 60, 6, function() self:copyIntoProject(path.."tabs/") end) 
        
        self.lines[#self.lines+1]={copy}
    end
end

function Folder:copyIntoProject(path)
    for i,v in ipairs(self.tabs) do
     --   print(DavHost..path..v.name)
   -- http.request(DavHost..path..v.name..".lua", function(data, status) self:getTabData(data, status, self.tabs[i]) end, httpfail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "GET"})
      --  self:requestFile(path..v.name..".lua", function(data, status) self:getTabData(data, status, self.tabs[i]) end)
        Request.get(path..v.name..".lua", function(data, status) self:getTabData(data, status, self.tabs[i]) end)
    end
end

function Folder:getTabData(data, status, tab)
    if not data then alert(status) return end
    tab.data = data
    local dataComplete = true
    for i,v in ipairs(self.tabs) do
        if not v.data then dataComplete = false end
    end
    if dataComplete then
        local concat = {}
        for i,v in ipairs(self.tabs) do
            concat[#concat+1] = "--# "..v.name
            concat[#concat+1] = v.data
        end
        local copyText = table.concat(concat, "\n")
        pasteboard.copy(copyText)
        alert("Press and hold ‘new project’ on the Codea project list, and select `Paste into project’", "Project copied to clipboard with correct tab order")
        self.dialog = CodeBox(copyText)
        self.copyData = copyText
    end
end

function Folder:push(pathName, collection)
    self.projectName = projects[pathName]
    if collection then
        self:commitMultiFile(pathName)
    else
        self:commitSingleFile(pathName)
    end
end

function Folder:commitMultiFile(pathName)   
    local plist = readProjectPlist(self.projectName)
    print ("Project:", self.projectName)
   -- http.request(DavHost..pathName.."Info.plist", writesuccess, writefail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "PUT", data = tab})
    self.tabs = {{name = "Info.plist"}}
    Request.put(pathName.."/Info.plist", function(data, status) self:writeSuccess(data, status, "/Info.plist", self.tabs[1], pathName) end, plist)
    local tabs = listProjectTabs(self.projectName) --get project tab names
    
    for i=1,#tabs do 
        local tabName = tabs[i]
        local tab=readProjectTab(self.projectName..":"..tabName)
        
            tabName = "/tabs/"..tabName..".lua"
        self.tabs[i+1]={name = tabName}
      --  http.request(DavHost..pathName..tabName, writesuccess, writefail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "PUT", data = tab})
        Request.put(pathName..tabName, function(data, status) self:writeSuccess(data, status, tabName, self.tabs[i+1], pathName) end, tab)
    end
        
end

function Folder:commitSingleFile(pathName)   
    --concatenate project tabs in Codea "paste into project" format and place in pasteboard
    local tabs = listProjectTabs(self.projectName)
    local tabCon = {}
    for i,tabName in ipairs(tabs) do
        tabCon[#tabCon+1] = "--# "..tabName
        tabCon[#tabCon+1] = readProjectTab(tabName)
    end
    local tabStr = table.concat(tabCon, "\n")
    Request.put(pathName..self.projectName, function(data, status) alert(self.projectName.." written to a single file", status) end)
end

function Folder:writeSuccess(data, status, tabName, tab, pathName)
    print ("written:", pathName..tabName)
    tab.written = true
    local complete = true
    for i,v in ipairs(self.tabs) do
        if not v.written then complete = false end
    end
    if complete then 
        alert(#self.tabs.." tabs transferred.", self.projectName.." written") 
        openWorkingCopy(pathName:match("/(.-)$"))
    end
end
