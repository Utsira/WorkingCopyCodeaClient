Workbench = class(LocalFile)

function Workbench:init(t) --(path, name, data, items) 
    LocalFile.init(self, t)
    
    --check whether linked to Codea project
    if projects[t.path] and projects[t.path].name then --linked
        self:link()
    else
        self.ui.linkStatus.content = "Not linked to any project"
    end

    --build roster of remote files
    self.remoteFiles = {}
    self.subFolders = {}
    self.plistFiles = {}
    
    --check for .plist file
    if t.data:match("<D:href>.-Info%.plist</D:href>") then
        Request.get(t.path.."Info.plist", function(d, status) self:readPlist(d, status) end)
    else --no plist
        self:findFilesFolders()
    end
    
end

function Workbench:deactivate()
    
    --[[
    self.active = false
    self.remoteFiles = nil
    self.localFiles = nil
    self.rosterBuilt = false
    self.window.title = "Working Copy \u{21c4} Codea Client"
    self.ui.linkStatus.content = ""
    self.ui.multiSingle:clearSelection()
    self:unlink()
   -- self.window:deactivate()
    
      ]]
    
    for k,v in pairs(self.ui) do
   --  v:deactivate()
        v.kill = true
    end
    
end

function Workbench:readPlist(data, status) 
    if not data then alert(status) return end
    
    self.remoteFiles = {{pathName = self.path.."Info.plist", nameNoExt = "Info", extension = "plist", located = "true"}}
    local array = data:match("<key>Buffer Order</key>%s-<array>(.-)</array>")
    
    for tabName in array:gmatch("<string>(.-)</string>%s") do
        table.insert(self.remoteFiles, {nameNoExt = tabName, extension = "lua", located = false})
        self.hasPlist = true
    end
    
    self:findFilesFolders()
end
    
function Workbench:findFilesFolders()
    for i,v in ipairs(self.items) do
        if v.collection then
            table.insert(self.subFolders, v)
        elseif not self.hasPlist and v.extension == "lua" then --only add root level lua items if there is no plist
            v.located = true
            table.insert(self.remoteFiles, v)        
        end
    end
    --check subfolders for lua files, compare to plist
    if #self.subFolders > 0 then
        for i,v in ipairs(self.subFolders) do
            Request.properties(v.pathName, function(data, status) self:checkSubFolder(data, v.pathName) end)
        end
    else --no subfolders
        self:checkRemoteFiles(#self.remoteFiles)
    end
end

function Workbench:checkSubFolder(data, subfolder) --nb unpredictable results if repo contains more than one folder of lua files
    if data:match("<D:href>.-%.lua</D:href>") then --contains lua files
        parsePropfind(data, 
            function(i,t) self:checkFileAgainstPlist(t, subfolder) end,
            function(i) self:checkRemoteFiles(i) end)
    end

end

function Workbench:checkFileAgainstPlist(t, subfolder)
    --if no plist, add to remote files
    local inPList = false
    if self.hasPlist then
        for i,v in ipairs(self.remoteFiles) do
            if v.nameNoExt == t.nameNoExt then
                self.pathToFiles = subfolder
                v.pathName = t.pathName
                v.located = true
                inPList = true
                break
            end
        end
    end
    if not inPList then --add to end of files
        t.located = true
        table.insert(self.remoteFiles, t)
    end
end

function Workbench:checkRemoteFiles() --remove files from remoteFiles roster that were not found in subfolders
    local total = #self.remoteFiles
    for i,v in ipairs(self.remoteFiles) do
        if not v.located then
            table.remove(self.remoteFiles, i)
            printLog("NOT FOUND, removed from roster", i, "/", total, ":", v.pathName)
        else
            printLog("Found", i, "/", total, ":", v.pathName)
        end
    end
    --roster build complete, activate controls
    self.rosterBuilt = true
    self.ui.copy:activate()
    
   -- self.ui.pushSingleSuffix:activate()
    if self.projectName then
        self.ui.pushInstaller:activate()
        self.ui.push:activate()
        self.ui.pull:activate()
    end
end
