Workbench = class(LocalFile)

function Workbench:init(x,y)
    self.window = Soda.Frame{
        x = x, y = y, w = 0, h =0,
        title = "Working Copy \u{21c4} Codea Client",
        shape = Soda.RoundedRectangle,
        shapeArgs = {corners = 1 | 8}
    }
    
    Soda.Button{
        parent = self.window,
        title = "WorkingCopy\u{ff1e}",
        x = -50, y = -5, w = 150, h = 40,
      --  style = Soda.style.icon,
        callback = function()
            self:openWorkingCopy()
        end
    }
    self.ui = {}
    
    local margin, width = 3, 1/4
    local w2,w3 = width * 0.5, width * 0.97
    
    local single = Soda.Frame{
        parent = self.window,
        x = 0, y = 0, w = 1, h = 200,
      --  shape = Soda.RoundedRectangle, style = Soda.style.translucent,
     --   inactive = true,
      --  content = "Repository is linked to a single Codea project. Its tabs will be pushed as separate lua files to a /tabs folder in the repository. The Info.plist will be saved in the root to preserve tab order. This is the recommended mode for larger Codea projects."
    
    }
    
    local multi = Soda.Frame{
        parent = self.window,
        x = 0, y = 0, w = 1, h = 200,
        --shape = Soda.RoundedRectangle, style = Soda.style.translucent,
     --   inactive = true,
     --   content = "Push projects to the root of the repository as single files in Codea's “paste into project” format. This is for backing up smaller projects that do not require a dedicated repository, or for adding installers for larger projects." 
    }
    
    self.ui.multiSingle = Soda.DropdownList{
        parent = self.window,
        x = margin, y = 150, w = 400, h = 40,
        title = "Repository is for",
        text = {"a single Codea project", "multiple Codea projects"},
        panels = {single, multi},
        default = 1,
        inactive = true
    }
    
    Soda.QueryButton{
        parent = single,
        x = -10, y = -10, 
        style = Soda.style.icon,
        callback = function()
            Soda.Alert{w = 0.5, h = 0.3, title = "Single Project Repository", content = "Repository is linked to a single Codea project. Its tabs will be pushed as separate lua files to a /tabs folder in the repository. The Info.plist will be saved in the root to preserve tab order. This is the recommended mode for larger Codea projects."}
        end
    }
    
    Soda.QueryButton{
        parent = multi,
        x = -10, y = -10, 
        style = Soda.style.icon,
        callback = function()
            Soda.Alert{w = 0.5, h = 0.3, title = "Multiple Project Repository", content = "Multiple Codea projects can be pushed to the root of the repository. Projects are pushed as single files in Codea's “paste into project” format. This is for backing up smaller projects that do not require a dedicated repository." }
        end
    }
    
    self.ui.copy = Soda.Button{
        parent = single,
        x = w2, y = 50, w = w3, h = 60,
        title = "Copy-into-\nproject",
        inactive = true,
        callback = function() self:copy() end
    }
    
    self.ui.link = Soda.Button{
        parent = single,
        x = w2 + width, y = 50, w = w3, h = 60,
        title = "Link",
        inactive = true,
        callback = function() self:linkDialog() end
    } 
    
    self.ui.linkStatus = Soda.Frame{
        parent = single,
        x = margin, y = -50, w = -margin, h = 60,   
       -- title = "" 
    }
    
    self.ui.push = Soda.Button{
        parent = single,
        x = w2 + width * 2, y = 50, w = w3, h = 60,
        title = "Push",
        inactive = true,
        callback = function() self:push() end
    }   
    
    self.ui.pull = Soda.Button{
        parent = single,
        x = w2 + width * 3, y = 50, w = w3, h = 60,
        title = "Pull",
        inactive = true,
    } 
    
    self.ui.pushInstaller = Soda.Switch{
        parent = single,
        x = -margin*2, y = margin, w = 0.7, 
        title = "Push paste-into-project Installer to root"
    }
    
    self.ui.addProject = Soda.Button{
        parent = multi,
        x = margin, y = margin, w = 0.49, h = 60,
        title = "Add new project\npaste-into-project format",
        inactive = true,
        callback = function() self:pushSingleFile(self.ui.pushSingleSuffix:output()) end
    }   
    
    --[[
    self.ui.pushSingleSuffix = Soda.TextEntry{
        parent = singleFile,
        x = -margin, y = margin, w = 0.49, h = 40,
        title = "Name suffix:",
        default = "Installer",
        inactive = true,
    }
    
    self.ui.settings = Soda.Toggle{
        parent = self.window,
        x = w2 + width*4, y = margin, w = w3, h = 60,
        title = "Repository\nsettings",
        inactive = true,
        callback = function() self.ui.settingsDialog:show() end
    }
      ]]
end


function Workbench:deactivate()
    
    self.active = false
    self.remoteFiles = nil
    self.localFiles = nil
    self.rosterBuilt = false
    self.window.title = "Working Copy \u{21c4} Codea Client"
    self.ui.linkStatus.content = ""
    self:unlink()
   -- self.window:deactivate()
    
    for k,v in pairs(self.ui) do
        v:deactivate()
    end
    
end

function Workbench:activate(path, name, data, items)
    self.path, self.name = path, name
    self.active = true
    self.window.title = name
    self.items = items
    
    --self:settings()
    --self.ui.settings:activate()
    --check whether linked to Codea project
    self.ui.link:activate()
    self.ui.multiSingle:activate()
    if projects[path] then --linked
        self:link()
    else
        self.ui.linkStatus.content = "Not linked to any project"
    end
    
    --build roster of remote files
    self.remoteFiles = {}
    self.subFolders = {}
    self.plistFiles = {}
    
    --check for .plist file
    if data:match("<D:href>.-Info%.plist</D:href>") then
        Request.get(path.."Info.plist", function(d, status) self:readPlist(d, status) end)
    else --no plist
        self:findFilesFolders()
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
   -- self.ui.pushSingle:activate()
   -- self.ui.pushSingleSuffix:activate()
    if self.projectName then
        self.ui.push:activate()
        self.ui.pull:activate()
    end
end

function Workbench:openWorkingCopy()
    if self.name then
        openURL("working-copy://open?repo="..urlencode(self.name))
    else
        openURL("working-copy://open")
    end
end
