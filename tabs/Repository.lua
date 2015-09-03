Repository = class(Folder)

function Repository:init(data, x, y, path, depth, linked)
    Folder.init(self, data, x, y, path, depth, linked)
    printLog("Opening repository at ",path)
    local y = self.h - 100
    local linkText, status = "Link", "Not linked to a Codea project"
    if linked or projects[path] then --path:match("(.-)/$")
        linkText, linked, status = "Relink", true, "Linked to Codea project ‘"..projects[path].."’" 
        self.projectName = projects[path]
        printLog("Linked to Codea project ", self.projectName)
    end
    local bar = {Control(path, 20, panelY-self.h, 300, self.h),
    Control("", 25, y-65, 290, 130),
    status = Label(status, 30, y, 280, 60),
    link = Button(linkText, 30, y-60, 60, 60, 6),
    push = Button('Push', 90, y-60, 60, 60, 6, function() self:push() end), --560
    pull = Button('Pull', 150, y-60, 60, 60, 6, test_Clicked), --620
    } --680
   
    bar[1].background = color(229, 229, 229, 255)
    bar[2].background = color(185, 185, 185, 255)
    bar[2].enabled = false
    bar[1].enabled = false
    bar[1].fontSize = 22
    bar.status.textAlign = CENTER
    bar.link.callback = function() Dialog.linkProject(bar, path, path:match("/(.-)/$")) end
    bar.push.enabled = linked
    bar.pull.enabled = linked
    self.lines[1] = bar
    if data:match("<D:href>.-Info%.plist</D:href>") then
        -- self:requestFile(pathName, function(data, status) self:readPList(data, status) end)
        self.pathToFiles = "tabs/"
        Request.get(path.."Info.plist", function(d, status) self:readPList(d, status) end)
    else
        if #self.subFolders>0 then
            for i,v in ipairs(self.subFolders) do
                Request.properties(v, function(d, status) self:checkSubFolder(d, v) end)
            end
        else
            self.pathToFiles = ""
        end
        tween.delay(0.1, function() self:createCopyButton() end) --delay to give time for subfolder checking to finish
    end
end

function Repository:checkSubFolder(data, subfolder)
    if data:match("<D:href>.-%.lua</D:href>") then
        self.pathToFiles = subfolder:match(self.path.."(.+)")
        local c = 0
        for name, info in data:gmatch("<D:href>(.-)</D:href>(.-)[\n\r]") do
             
            c = c + 1
            if c>1 then
              --  print(name:match(self.pathToFiles.."(.-)%."))
                table.insert(self.tabs, {name = name:match(self.pathToFiles.."(.-)%.")})
            end
        end
    end
end

function Repository:readPList(data, status)
    if not data then alert(status) return end
    local array = data:match("<key>Buffer Order</key>%s-<array>(.-)</array>")
    self.tabs = {}
    for tabName in array:gmatch("<string>(.-)</string>%s") do
        table.insert(self.tabs, {name = tabName})
    end
   -- print(table.concat(tabs, ","))
    self:createCopyButton()
end

function Repository:createCopyButton()
    if #self.tabs>0 then
        --add copy into tab button
     --   sound(SOUND_BLIT, 29081)
        local copy = Button('Copy-into-project', 210, self.h - 160, 100.0, 60, 6, function() self:copyIntoProject() end) 
        
        self.lines[1].copy = copy
     end    
end

function Repository:copyIntoProject()
    for i,v in ipairs(self.tabs) do
        Request.get(self.path..self.pathToFiles..v.name..".lua", function(data, status) self:getTabData(data, status, self.tabs[i], function(tex) self:copyIntoProjectSucceeded(tex) end) end)
    end
end

function Repository:getTabData(data, status, tab, callback)
    if not data then alert(status) return end
    tab.data = data
    local dataComplete = true
    for i,v in ipairs(self.tabs) do
        if not v.data then dataComplete = false end
    end
    if dataComplete then
        callback( self:concatenaTabs(self.tabs))
    end
end

function Repository:concatenaTabs(dataTable)
            local concat = {}
        for i,v in ipairs(dataTable) do
            concat[#concat+1] = "--# "..v.name
            concat[#concat+1] = v.data
            v.data = nil --reset, in case user tries to read again
        end
    return table.concat(concat, "\n") 
end

function Repository:copyIntoProjectSucceeded(copyText)
            pasteboard.copy(copyText)
        alert("Press and hold ‘new project’ on the Codea project list, and select `Paste into project’", "Project copied to clipboard")
        self.dialog = CodeBox(copyText)
        self.copyData = copyText
end

function Repository:push()
    --check if there's a tabs folder, and if not, create one, before pushing the files
    local tabs
    for i,v in ipairs(self.subFolders) do
        if v:match(".-/tabs/$") then tabs=true end        
    end
    if tabs then
        self:pushMultiFile()
    else
        Request.newFolder(self.path.."tabs", function() self:pushMultiFile() end)
    end
end

function Repository:pushMultiFile()   
    printLog ("Pushing Project:", self.projectName)
    
    --collate data 
    local plist = readProjectPlist(self.projectName)    
    self.writing = {{name = "Info", data = plist, path = "", ext = ".plist"}}
    local tabs = listProjectTabs(self.projectName) --get project tab names 
    for i=1,#tabs do   
        local tabName = tabs[i]
        local tab=readProjectTab(self.projectName..":"..tabName)
      --  tabName = "tabs/"..tabName..".lua"   
        self.writing[i+1]={name = tabName, data = tab, path = "tabs/", ext = ".lua"}
    end
    
  --  Request.put(self.path.."Info.plist", function(data, status) self:writeSuccess(data, status, "Info.plist", self.writing[1]) end, plist)
    --issue write commands
    
    for i,v in ipairs(self.writing) do
        Request.put(self.path..v.path..v.name..v.ext, function(data, status) self:writeSuccess(data, status, v.name, self.writing[i]) end, v.data)
    end
    
end

function Repository:pushSingleFile()   
    --concatenate project tabs in Codea "paste into project" format and push to remote
    local tabs = listProjectTabs(self.projectName)
    local tabCon = {}
    for i,tabName in ipairs(tabs) do
        tabCon[#tabCon+1] = "--# "..tabName
        tabCon[#tabCon+1] = readProjectTab(tabName)
    end
    local tabStr = table.concat(tabCon, "\n")
    Request.put(pathName..self.projectName, function(data, status) alert(self.projectName.." written to a single file", status) end, tabStr)
end

function Repository:writeSuccess(data, status, tabName, tab)
    tab.written = true
    local complete = 0
    for i,v in ipairs(self.writing) do
        if v.written then complete = complete + 1  end
    end
    printLog ("written "..complete.."/"..#self.writing..":", self.path..tabName)
    if complete==#self.writing then 
        printLog(#self.writing.." files transferred in ", self.projectName..". Verifying...") 
       -- openWorkingCopy(self.path:match("/(.-)/$"))
        
            --generate key for remote files
        table.insert(self.tabs, 1, {name = "Info"})
        local path,ext = "", ".plist"
        for i,v in ipairs(self.tabs) do      
            Request.get(self.path..path..v.name..ext, function(data, status) self:getTabData(data, status, self.tabs[i], function(tex) self:verifyWriting(tex) end) end)
            path,ext = self.pathToFiles,".lua"
        end
    end
end

function Repository:verifyWriting(remoteFileStr)
    printLog("Generating SHA1 keys")

    local sha1Remote = sha1( remoteFileStr )
    -- generate key for written tabs
    local localFileStr = self:concatenaTabs(self.writing)

    local sha1Local = sha1(localFileStr)
    self.dialog = CodeBox(remoteFileStr..string.rep("%", 40)..localFileStr)
    if sha1Local == sha1Remote then
        printLog("Files verified.")
    openURL("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&limit=999&repo="..self.path:match("/(.-)/$")) --.."&limit=999"
    else
        alert("File verification failed")
    end
end
