--# Main
-- Working Copy Codea WebDAV Client 

assert(SodaIsInstalled, "Set Soda as a dependency of this project") --produces an error if Soda not a dependency

displayMode(OVERLAY)
displayMode(FULLSCREEN_NO_BUTTONS)

DavHost = readLocalData("DavHost", "http://localhost:8080")
workingCopyKey = readLocalData("workingCopyKey", "")

function setup()
    parameter.watch("#Soda.items")
    Soda.setup()
    sha1.load = coroutine.create( sha1.assets)
    local projectString = readLocalData("projects", "[]")
    projects = json.decode(projectString)
    
    consoleLog = {}
    UI.main()
   -- printLog(projectString)
end

function draw()
    if sha1.load then 
        local _, progress = coroutine.resume(sha1.load)
        if coroutine.status(sha1.load) == "dead" then
            printLog("SHA1 caching complete")
            sha1.load = nil
            sha1.ready = true
            collectgarbage()
        else
            printLog(progress or "")
        end
    end
    if #consoleLog > 0 then
        UI.console:inputString( table.concat(consoleLog, "\n"), true) --, math.max(1, #consoleLog-4)
        consoleLog = {}
    end
    --do your updating here
    pushMatrix()
    Soda.camera()
    Soda.drawing()
    popMatrix()
end

function Soda.drawing(breakPoint) 
    --in order for gaussian blur to work, do all your drawing here
    background(246, 245, 245)

    Soda.draw(breakPoint)
end

function printLog(...)
    args = {...}
    for i,v in ipairs(args) do
        args[i] = tostring(v)
    end
    consoleLog[#consoleLog+1]=table.concat(args, " ")
    updateConsole = true
end

--user inputs:

function touched(touch)
    if touch.state == BEGAN then displayMode(FULLSCREEN_NO_BUTTONS) end
    Soda.touched(touch)
end

function keyboard(key)
    Soda.keyboard(key)
end

function orientationChanged(ori)
    Soda.orientationChanged(ori)
end

function table.copy(tab, super)
    super = super or tab
    local new = {}
    for k,v in pairs(tab) do
        if type(v) == "table" and v ~= super then
            new[k] = table.copy(v, super)
        else
            new[k] = v
        end
    end
    return new
end

--# UI
UI = {}

function UI.main()
    guidex, guidey = 0.33, -265
    menuHeight = 25
    local margin = 5
    
    --[[
     UI.preview = Preview{
        x = guidex, y = 0.2, w = 0, h = guidey,
    }
      ]]
    
    UI.menubar = Soda.Frame{
        x = 0, y = -0.001, w = 1, h = menuHeight,
        shape = Soda.rect,
        title = "Working Copy \u{21c4} Codea Client",
        label = {x = 0.5, y = 0.5},
        style = {shape = {fill = color(0), noStroke = true}, text = {fill = color(200), fontSize = 0.75}}
    }
    
    Soda.Button{
        parent = UI.menubar,
        title = Soda.symbol.back.." Open in Working Copy",
        x = 0, y = 0, w = 200, h = menuHeight,
      --  style = Soda.style.icon,
        shape = null,
        style = {shape = {},  text = {fill = color(200), fontSize = 0.75}},
        callback = function()
            if workbench then
                openURL("working-copy://open?repo="..urlencode(workbench.name))
            else
                openURL("working-copy://open")
            end
        end
    }
    
    Soda.CloseButton{
        parent = UI.menubar,
        x = -0.001, y = 0.5, w = 50, h = menuHeight + 10,
        shape = null,
        style = {shape = {},  text = {fill = color(200), fontSize = 1}},
        callback = function()
            close()
        end
    }
    
    UI.console = Soda.TextScroll{
        x = guidex, y = 0, w = 0, h = 0.2,
        shape = Soda.RoundedRectangle,
        textBody = "\n#### Working Copy Codea Client ####"
    }
    
    UI.finder = Finder(guidex, -menuHeight)
    
  --workbench = Workbench(guidex, guidey)
    
    --[[
    Soda.AddButton{
        parent = UI.finder.window,
        x = -margin, y = -margin,
        style = Soda.style.icon
    }
      ]]

    UI.settingsButton = Soda.SettingsButton{
        parent = UI.finder.window,
        x = margin, y = -margin,
        --style = Soda.style.icon,
        callback = function(sender) UI.settings("Global Settings", "Enter your Working Copy x-callback URL key and the address of the WebDAV server.\n\nNote that as digest authentication is not currently supported, you need to use the Working Copy WebDAV server in LOCAL mode and delete the WebDAV username and password.", "Save", function() sender:switchOff() end, true) end,
    }
    
end

function UI.settings(title, content, ok, callback, cancel)
     local this = Soda.Window{
        w = 0.7, h = 0.6, alert = true,
        title = title,
        content = content, 
        cancel = cancel,
        shadow = true, blurred = true, -- style = Soda.style.darkBlurred,
    }
    
    local key = Soda.TextEntry{
        parent = this,
        x = 10, y = 60, w = -80, h = 40,
        title = "x-callback URL key:",
        default = workingCopyKey
    }
    
    Soda.Button{
        parent = this,
        x = -10, y = 60, w = 65, h = 40,
        title = "Paste",
        callback = function() key:inputString(pasteboard.text) end
    }
    
    local dav = Soda.TextEntry{
        parent = this,
        x = 10, y = 110, w = -80, h = 40,
        title = "WebDAV host:",
        default = DavHost
    }
    
    Soda.Button{
        parent = this,
        x = -10, y = 110, w = 65, h = 40,
        title = "Paste",
        callback = function() dav:inputString(pasteboard.text) end
    }
    
    Soda.Button{
        parent = this,
        x = -10, y = 10, w = 0.3, h = 40,
        title = ok,
        callback = function()
            workingCopyKey = key:output()
            saveLocalData("workingCopyKey", workingCopyKey)
            DavHost = dav:output()
            saveLocalData("DavHost", DavHost)
            this.kill = true
            callback()
        end
    }
end

function UI.diffViewer(message, loc, rem)
    local this = Soda.Window{
        w = 0.7, h = 1, alert = true,
        title = message,
        close = true,
        shadow = true, blurred = true, -- style = Soda.style.darkBlurred,
    }
    
    Soda.TextScroll{
        parent = this,
        x = 0.25, w = 0.49, y = 5, h = -40,
        title = "Local",
        shape = Soda.RoundedRectangle, shapeArgs = {radius = 16},
        subStyle = {"translucent"},
        textBody = loc
    }
    
    Soda.TextScroll{
        parent = this,
        x = 0.75, w = 0.49, y = 5, h = -40,
        title = "Remote",
        shape = Soda.RoundedRectangle, shapeArgs = {radius = 16},
        subStyle = {"translucent"},
        textBody = rem
    }
end



--# URLcallbacks

function urlencode(str)
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])", 
        function (c)
            return string.format ("%%%02X", string.byte(c))
        end)
    str = string.gsub (str, " ", "%%20") -- %20 encoding, not + 
    return str
end

function concatURL(url1, url2, sep)
    local sep = sep or "&x-success="
    return url1..sep..urlencode(url2) --to chain urls, must be double-encoded.
end

--[[
function createCommitURL(repo, limit, path)
    if path then path = "&path="..path..".lua" else path = "" end
    local commitURL= "working-copy://x-callback-url/commit/?key="..workingCopyKey.."&repo="..repo..path.."&limit="..limit --.."&message="..urlencode(commitMessage)
    
    if Push_to_remote_repo then --add push command
        commitURL = concatURL(commitURL, "working-copy://x-callback-url/push/?key="..workingCopyKey.."&repo="..repo)
    end
    return commitURL
end
  ]]

--[[
local function createWriteURL(repo, path, txt)
    return "working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo="..repo.."&path="..path.."&uti=public.txt&text="..urlencode(txt)    --the write command
endo
  

function openWorkingCopy(repo)
    openURL("working-copy://open?repo="..urlencode(repo))
end ]]


--# Finder
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

    parsePropfind(data, function(i, t) listText[i], self.items[i] = self:addLine(t) end)
    
    self.window.title = self.titles[#self.titles] --self.paths[#self.paths]
    
    if #self.paths > 1 then 
        
        if #self.paths == 2 and not workbench then
            
            UI.settingsButton:hide()
            self.backButton:show()
      --  workbench:activate(self.paths[2], self.titles[2], data, table.copy(self.items))
          workbench = Workbench{path = self.paths[2], name = self.titles[2], data = data, items = table.copy(self.items)}
        end
    else   --depth 1

      --  workbench:deactivate()
        if workbench then workbench:deactivate() end
        workbench = nil
      --  UI.workbench = Workbench()
        UI.settingsButton:show()
        self.backButton:hide()
    end
    
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
   -- printLog(data)
    local i = 0
    for pathName, info in data:gmatch("<D:href>(.-)</D:href>(.-)[\n\r]") do
        i = i + 1
        if i>1 then --the first entry is just the root
            local name = pathName:match("/([^/]-)$"):gsub("%%20", " ") --strip out path from name; put spaces back
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

    local printName = t.name --:gsub("%%20", " ") --put spaces back
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
        Request.get(item.pathName, function(data)  
            preview=Preview{path = item.pathName, name = item.name, data = data, multiProject = workbench.multiProject, repo = self.titles[2]} 
        end)
    end
end




--# LocalFile
LocalFile = class()

function LocalFile:init(t) --(path, name, data, items, multiProject) 
    
    self.path, self.items, self.multiProject = t.path, t.items, t.multiProject
    self.name = t.name or ""
    self.data = t.data or ""
    self:setupUi()
    
end

function LocalFile:openLocalFile(project, name, warn)
    local path = os.getenv("HOME") .. "/Documents/"
    local file = io.open(path .. project .. ".codea/" .. name,"r")
    if file then
        local data = file:read("*all")
        file:close()
        return data
    elseif warn then
        alert("WARNING: unable to read " .. name)
    end
end

function LocalFile:getLocalPlist(project)
    return self:openLocalFile(project, "Info.plist", true)
end

function LocalFile:getLocalFiles()
    --collate data 
    local plist = self:getLocalPlist(self.projectName)    
    self.localFiles = {{pathName = self.path.."Info.plist", nameNoExt = "Info", extension = "plist", data = plist}}
    local tabs = listProjectTabs(self.projectName) --get project tab names 
    for i=1,#tabs do   
        local tabName = tabs[i]
        local tab=readProjectTab(self.projectName..":"..tabName)
        self.localFiles[i+1]={nameNoExt = tabName, data = tab, pathName = self.path.."tabs/"..tabName..".lua", extension = "lua"}
    end
end

function LocalFile:concatenaFiles(tab, type1, type2, type3)
    local tabCon = {}
    for i,v in ipairs(tab) do
        if v.extension == type1 or v.extension == type2 or v.extension == type3 then
            tabCon[#tabCon+1] = "--# "..v.nameNoExt
            tabCon[#tabCon+1] = v.data
        end
    end
    return table.concat(tabCon, "\n")
end

function LocalFile:pushSingleFile(t) --(name, repo, repopath, callback)
    local name = t.name or ""
    local repopath = t.repopath or t.name 
    local callback = t.callback or null
    self:getLocalFiles()
    local localFileStr = self:concatenaFiles(self.localFiles, "lua")
    local pathName = self.path..name --urlencode(self.projectName.." Installer.lua")
 printLog("Writing", pathName)
    Request.put(pathName, 
        function() 
            
          --  Soda.TextWindow{localFileStr}
            Soda.TextWindow{
                    title = "Write Successful",   
                    textBody = localFileStr,
                    ok = "Working Copy "..Soda.symbol.forward,
                    alert = true, close = true,
                    callback = function()
                        callback(pathName, localFileStr)
                        openURL("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&limit=1&repo="..urlencode(t.repo).."&path="..repopath) 
            --self.path:match("/(.-)/$")
                    end
                }
            
        end, localFileStr)
end
--# LFLink
--link and unlink Codea projects

function LocalFile:link()
    self.ui.link.title = "Relink"
    if self.rosterBuilt then
        self.ui.push:activate()
        if self.ui.pushInstaller then 
           -- sound(SOUND_JUMP, 9054)
            self.ui.pushInstaller:activate() 
        end
        if self.ui.pull then self.ui.pull:activate() end
    end
    self.projectName = projects[self.path].name
    self.ui.linkStatus.content = "Linked to Codea project ‘"..self.projectName.."’" 
end

function LocalFile:unlink()
    self.ui.link.title = "Link"
    self.ui.push:deactivate()
    if self.ui.pull then self.ui.pull:deactivate() end
    if self.ui.pushInstaller then self.ui.pushInstaller:deactivate() end
    self.projectName = nil
    self.ui.linkStatus.content = "Not linked to any Codea project"
end

function LocalFile:linkDialog(instruction)
    local pathName, name = self.path, self.name
    
    local default = name:gsub("%.lua", "")
    if projects[pathName] and projects[pathName].name then
        default = projects[pathName].name
    end
    
    local this = Soda.Window{
        w = 0.7, h = 0.6,
        title = "Link Codea Project",
        content = instruction,
        cancel = true, shadow = true, blurred = true, alert = true, -- style = Soda.style.darkBlurred
    }
    
    local box = Soda.TextEntry{
        parent = this,
        x = 10, y = 60, w = -10, h = 40,
        title = "Codea Project Name:",
        default = default
    }
    
    local ok = Soda.Button{
        parent = this,
        x = -10, y = 10, w = 0.3, h = 40,
        title = "Link",
        callback = function() 
            this.kill = true
            local inkey = box:output() 
            if inkey=="" and projects[pathName] then
                Soda.Alert2{
                    title = "Unlink Codea project from Working Copy repository", 
                    content = "No data will be changed, but you will not be able to push and pull without relinking",      
                    callback = function() 
                        self:save("name", nil)
                        self:unlink()
                    end
                }
            else
                print("#"..inkey.."#")
                local ok,err = pcall( function() readProjectTab(inkey..":Main") end)
                if ok then
                    self:save("name", inkey)
                    self:link()
                else
                    Soda.Alert{title = "Please enter a valid project name", content = inkey.." not found"}
                    print(err)
                end
            end
        end
    }
    
end

function LocalFile:save(key, value)
  --  printLog("Saving", key, value)
    if not projects[self.path] then projects[self.path] = {} end
    projects[self.path][key] = value
    saveLocalData("projects", json.encode(projects))    
end

--# Preview
Preview = class(LocalFile)

function Preview:init(t) --(path, name, data, multiProject, repo)
    self.repo = t.repo
   -- printLog("repo=", t.repo)
    LocalFile.init(self, t)
    self.rosterBuilt = true --force push and pull buttons to become active if file is linked
    --check whether linked to Codea project, if this file is in a multiProject repo
    if self.multiProject then
        if projects[t.path] and projects[t.path].name then --linked
            self:link()
        else
            self.ui.linkStatus.content = "Not linked to any project"
        end
    end
    
end

function Preview:setupUi()
    local frame = Soda.Window{
        x = 0.5, y = 0.5, w = 700, h = 1,
        title = self.name or "",
        shadow = true, alert = true, close = true
    }
    
    local width = 0.99/3
    local margin = (1 - 0.99)/2
    local w2,w3 = (width * 0.5) + margin, width * 0.97
    
    self.ui = {}
    local scrollHeight = -50
    if self.multiProject then
        scrollHeight = -165
        self.ui.copy = Soda.Button{
            parent = frame,
            x = w2, y = -100, w = w3, h = 60,
            title = "Copy",
            callback = function() pasteboard.copy(self.data) end,
        }
        
        self.ui.link = Soda.Button{
            parent = frame,
            x = w2 + width, y = -100, w = w3, h = 60,
            title = "Link",
        --   inactive = true,
            callback = function() self:linkDialog("Enter the name of an existing Codea project to link it to this file") end
        } 
        
        self.ui.linkStatus = Soda.Frame{
            parent = frame,
            x = margin, y = -50, w = -margin, h = 60,   
            content = "Not linked to any Codea project" 
        }
        
        self.ui.push = Soda.Button{
            parent = frame,
            x = w2 + width * 2, y = -100, w = w3, h = 60,
            title = "Push as\nsingle file",
            inactive = true,
            callback = function() self:pushSingleFile{repo = self.repo, repopath = urlencode(self.name)} end
        }   
        
        --[[
        self.ui.pull = Soda.Button{
            parent = frame,
            x = w2 + width * 3, y = -100, w = w3, h = 60,
            title = "Pull",
            inactive = true,
        } 
          ]]
    end
    
    self.ui.scroll = Soda.TextScroll{
        parent = frame,
        x = 5, y = 5, w = -5, h = scrollHeight,
        textBody = self.data or "",
        shape = Soda.RoundedRectangle,
        shapeArgs = {radius = 20}
    }
end

--[[
function Preview:inputString(txt)
    self.scroll:clearString()
    self.scroll:inputString(txt)
    self.input = txt
    self.button:show(RIGHT)
end

function Preview:clearString()
    self.scroll:clearString()
    self.input = nil
    self.button:hide(RIGHT)
end
  ]]

--# Workbench
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

--# WBUI
function Workbench:setupUi(x,y)
    local x,y = guidex, guidey
    self.ui = {} 
   self.ui.window = Soda.Frame{
        x = x, y = y, w = 0, h =-menuHeight,
        title = self.name, -- "Working Copy \u{21c4} Codea Client",
        content = ""
      --  shape = Soda.RoundedRectangle,
       -- shapeArgs = {corners = 1 | 8}
    }
       
    local margin, width = 3, 1/3
    local w2,w3 = width * 0.5, width * 0.97
    
    local single = Soda.Frame{
        parent = self.ui.window,
        x = 0, y = -45, w = 1, h = 215,
        shape = Soda.RoundedRectangle, subStyle = {"translucent"},
    
    }

    local multi = Soda.Frame{
        parent = self.ui.window,
        title = "multi",
        x = 0, y = -45, w = 1, h = 110,
        shape = Soda.RoundedRectangle, subStyle = {"translucent"},

    }
 --   local single, multi = self.ui.single, self.ui.multi
    local default
    if projects[self.path] then 
        self.multiProject = projects[self.path].multiProject
        if self.multiProject==true then default = 2
        elseif self.multiProject==false then default = 1 --nb could also be nil, so need explicit false check
        end
    end
    
    self.ui.multiSingle = Soda.DropdownList{
        parent = self.ui.window,
        x = margin, y = -50, w = -60, h = 40,
        title = "Repository mode",
        text = {"Single Codea project", "Multiple Codea projects"},
        panels = {single, multi},
        default = default,
        callback = function(sender, selected) 
            if selected.idNo == 1 then self.multiProject = false
            elseif selected.idNo == 2 then self.multiProject = true end
            self:save("multiProject", self.multiProject)
        end
    }
    
    Soda.QueryButton{
        parent = single,
        x = -5, y = -5, 
        -- style = Soda.style.icon,
        callback = function()
            Soda.Alert{w = 0.5, h = 0.3, title = "Single Project Repository", content = "Repository is linked to a single Codea project. Its tabs will be pushed as separate lua files to a /tabs folder in the repository. The Info.plist will be saved in the root to preserve tab order. This is the recommended mode for larger Codea projects."}
        end
    }
    
    Soda.QueryButton{
        parent = multi,
        x = -5, y = -5, 
        -- style = Soda.style.icon,
        callback = function()
            Soda.Alert{w = 0.5, h = 0.3, title = "Multiple Project Repository", content = "Multiple Codea projects can be pushed to the root of the repository. Projects are pushed as single files in Codea's “paste into project” format. This is for backing up smaller projects that do not require a dedicated repository." }
        end
    }
    
    self.ui.copy = Soda.Button{
        parent = single,
        x = w2, y = 65, w = w3, h = 60,
        title = "Copy as\nsingle file",
       inactive = true,
        callback = function() self:copy() end
    }
    
    self.ui.link = Soda.Button{
        parent = single,
        x = w2 + width, y = 65, w = w3, h = 60,
        title = "Link",
     --   inactive = true,
        callback = function() self:linkDialog("Enter the name of an existing Codea project to link it to this repository") end
    } 
    
    self.ui.linkStatus = Soda.Frame{
        parent = single,
        x = margin, y = -50, w = -margin, h = 60,   
        content = "Not linked to any Codea project" 
    }
    
    self.ui.push = Soda.Button{
        parent = single,
        x = w2 + width * 2, y = 65, w = w3, h = 60,
        title = "Push",
          inactive = true,
        callback = function() self:push() end
    }   
    
    self.ui.pull = Soda.Button{
        parent = single,
        x = w2 + width, y = margin, w = w3, h = 60,
        title = "Pull",
      inactive = true,
        callback = function() self:prePullCheck() end
    } 
    
    self.ui.pushInstaller = Soda.Button{
        parent = single,
        inactive = true,
        x = w2 + width * 2, y = margin, w = w3, h = 60, 
        title = "Push single-file\nInstaller to root",
        callback = function() self:pushSingleFile{name = urlencode(self.projectName.." Installer.lua"), repo = self.name} end
    }
    
    --[[
    Soda.Switch{
        parent = single,
        x = -margin*2, y = margin, w = 0.7, 
        title = "Push paste-into-project Installer to root"
    }
      ]]
    
    self.ui.addProject = Soda.Button{
        parent = multi,
        x = margin, y = margin, w = 0.49, h = 60,
        title = "Add new project",
      --  inactive = true,
        callback = function() self:addProjectDialog() end
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


--# WBAddNew
function Workbench:addProjectDialog()
    local pathName

    local this = Soda.Window{
        w = 0.7, h = 0.6,
        title = "Add New Codea Project as a Single File",
        content = "Enter the name of an already existing Codea project that you would like to add to this repository as a single file. The project will be written using Codea's “paste-into-project” format.",
        cancel = true, shadow = true, blurred = true, alert = true, -- style = Soda.style.darkBlurred
    }
    
    local box = Soda.TextEntry{
        parent = this,
        x = 10, y = 60, w = -10, h = 40,
        title = "Codea Project Name:",
        default = default
    }
    
    local ok = Soda.Button{
        parent = this,
        x = -10, y = 10, w = 0.3, h = 40,
        title = "Add",
        callback = function() 
            this.kill = true
            local inkey = box:output() 

            print("#"..inkey.."#")
            local ok,err = pcall( function() readProjectTab(inkey..":Main") end)
            if ok then
              --  self:pushSingleFile{repo = self.name, repopath = urlencode(inkey), callback = function(path, data) self:addProject(inkey, path, data) end}
                self:addProject(inkey)
            else
                Soda.Alert{title = "Please enter a valid project name", content = "No project called “"..inkey.."” was found"}
                print(err)
            end
    
        end
    }
end

function Workbench:addProject(name)
  --  local name = name 
    local nameEncoded = urlencode(name)..".lua"
    local path = self.path..nameEncoded
    projects[path] = {name = name}
    saveLocalData("projects", json.encode(projects))
    preview=Preview{path = path, name = name..".lua", multiProject = true, repo = self.name}
    preview:pushSingleFile{repo = self.name, repopath = nameEncoded}
end

--# WBCopy
--copy multipleremote files into a paste-into-project file

function Workbench:copy()
    self:readRemoteFiles( --read remote files
        function() --completion callback
            local tabStr = self:concatenaFiles(self.remoteFiles, "lua") --concatena remote files that have ext lua
            
            Soda.TextWindow{title = self.name, textBody = tabStr, close = true} --open string in preview
            pasteboard.copy(tabStr)
            local txt = "From the Codea project screen, long press “Add new project” and select “Paste into project” "
            if not self.hasPlist then
                txt = txt.."\n\nNo Info.plist file was found, so the order of tabs could be incorrect"
            end
            Soda.Window{title = "Remote Project Copied to Pasteboard", content = txt, ok = true, w = 0.6, h = 0.6, blurred = true, shadow = true}
        end
    ) 
        
end

function Workbench:readRemoteFiles(onComplete)
    for i,v in ipairs(self.remoteFiles) do
      --  if v.extension == "lua" then
            Request.get(v.pathName, 
                function(data, status) 
                    if not data then
                        alert(status)
                        return
                    end
                    v.data = data
                   --  self:collateReadFiles{data = data, status = status, callback = onComplete, item = v}
                    self:collating("Read", v, self.remoteFiles, onComplete)
                end
            )
      --  end
    end
end

function Workbench:collating(status, item, tab, callback) --check whether all files have been read/ written/ deleted, and if so trigger completion callback
    item.processed = true
    local complete = 0
    for i,v in ipairs(tab) do
        if v.processed then complete = complete + 1  end
    end
    printLog (status, complete, "/", #tab, ":", item.pathName)
    if complete==#tab then 
        --reset processed flag in case this table is processed again
        for i,v in ipairs(tab) do
            v.processed = false
        end        
        callback() 
    end
end

--# WBPush
--[[
Push:
1. read local files
WebDAV:
2. check if theres a remote tabs folder, and if not, create one 
3. verify whether remote has changed since last push by comparing hash of last push to hash of current files on remote. Warn if remote has changed since last push.
4. write local files to remote
5. check for & delete orphaned remote files (otherwise deleted/renamed files will remain on remote), and add new/renamed files to the remote files roster
6. start verification process, reading back the remote files
7. compare the hashes of local and remote files to ensure file integrity
x-callback:
8. open a commit dialogue in Working Copy
  ]]

function Workbench:push()
    self:getLocalFiles() --1. read local files
    
    --2 check if theres a tabs folder, and if not, create one
    local tabs
    for i,v in ipairs(self.subFolders) do
        if v.pathName:match(".-/tabs$") then tabs=true end        
    end
    if tabs then
        self:verifyRemoteChanges() --3 verify whether remote has changed since last push
    else
        Request.newFolder(self.path.."tabs", function() 
                self:verifyRemoteChanges() 
            end)
    end
    
end

function Workbench:pushMultiFile()
        --4. write local files to remote
    for i,v in ipairs(self.localFiles) do
        Request.put(v.pathName, 
        function() 
          --  v.data = nil --clear data (so that verification doesnt create false positives)
            self:collating("Written", v, self.localFiles,
               function() self:deleteRemoteOrphans() end --5. check for & delete orphaned remote files, add new/renamed file to the remote files roster
            )
        end, v.data)
    end
end

function Workbench:deleteRemoteOrphans()
    --delete remote orphans
    local deleteList = {}
    for i,remote in ipairs(self.remoteFiles) do
        local del = true
        for _,loc in ipairs(self.localFiles) do
            if loc.nameNoExt == remote.nameNoExt then
                del = false
                break
            end
        end
        if del then
            table.insert(deleteList, remote) --{unpack(remote)}
            table.remove(self.remoteFiles, i)
        end
        
    end
    
    --add newly created files to remoteFile roster (otherwise verification could fail)
    local addList = {}
    for i,loc in ipairs(self.localFiles) do
        local new = true
        for _, remote in ipairs(self.remoteFiles) do
            if loc.nameNoExt == remote.nameNoExt then
                new = false
                break
            end
        end
        if new then table.insert(addList, loc) end
    end
    for i,v in ipairs(addList) do
        table.insert(self.remoteFiles, v)
    end
    
    --remote deletions
    if #deleteList>0 then
        printLog("Deleting remote orphans")
        for i,v in ipairs(deleteList) do
            print("test", v.pathName)
            Request.delete(v.pathName, 
            function() 
                self:collating("Deleted", deleteList[i], deleteList, 
                function() self:verifyWrite() end ) --6. start verification process
            end)
        end
    else
        self:verifyWrite() --6. start verification process
    end
end

function Workbench:verifyRemoteChanges()
    if projects[self.path].hash then
        printLog("Checking for changes on remote") 
        self:readRemoteFiles( --read remote files
            function() --completion callback
                local remoteFileStr = self:concatenaFiles(self.remoteFiles, "lua", "plist") --concatena remote files that have ext lua or plist
                local hash = self:verify(projects[self.path].hash, sha1(remoteFileStr)) 
                if hash then 
                    printLog("Remote unchanged since last push", hash)
                    self:pushMultiFile() 
                else
                    Soda.Alert2{
                        title = "Remote has changed since you last pushed.\nUncommitted changes on the remote will be lost",   
                        ok = "Proceed Anyway",
                        callback = function()
                            self:pushMultiFile() 
                        end
                    }
                end
            end
        )
    else
        self:pushMultiFile() 
    end
end

function Workbench:verifyWrite()
    printLog("Verifying push")
    self:readRemoteFiles( --read remote files
        function() --completion callback
            local remoteFileString = self:concatenaFiles(self.remoteFiles, "lua", "plist") --concatena remote files that have ext lua or plist
            local localFileString = self:concatenaFiles(self.localFiles, "lua", "plist")
            local localFileHash = sha1(localFileString)
            local remoteFileHash = sha1(remoteFileString)
            projects[self.path].hash = remoteFileHash
            saveLocalData("projects", json.encode(projects))
            if self:verify(localFileHash, remoteFileHash) then --7. verify
                printLog("Write verified on hash:", remoteFileHash)
                
                Soda.Alert{
                    title = "Write Successful\n\nHash:"..remoteFileHash.."\n\nSwitching to Working Copy",   
                    callback = function()
                        openURL("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&limit=999&repo="..self.path:match("/(.-)/$")) --8. commit
                    end
                }
            else --verfication failed
                UI.diffViewer("Verification failed", localFileString, remoteFileString)
            end
        end
    )
end

function Workbench:verify(sha1Local, sha1Remote)

    if sha1Local == sha1Remote then
        return sha1Local
    else
        printLog("Verification failed")
    end
end


--# WBPull
--[[
Pull:
If previous push then read local files, create hash
Compare to last push hash, warn if changes will be lost
Read remote files
Write to local tabs
Delete any orphaned local tabs
Reread local files, create hash
Compare to hash of remote files
  ]]

function Workbench:prePullCheck()
    local localFileHash = sha1(self:concatLocalFiles()) -- read local files and get hash
    if projects[self.path].hash then --1. if previous push then compare hashes      
        if localFileHash == projects[self.path].hash then --pull
            printLog("No changes to local files since last push")
            self:pull()
        else --warn before pulling
            Soda.Alert2{
                title = "Local files have been changed since you last pushed",
                content = "These changes will be lost when you pull. Consider performing a push first",
                ok = "Pull anyway",
                callback = function() self:pull() end
            }
        end
    else
        Soda.Alert2{
            title = "No record of push",
            content = "Working Copy Codea Client has no record of this project having been pushed before. Your Codea project will be overwritten with the contents of the remote. Consider performing a pish first",
            ok = "Pull anyway",
            callback = function() self:pull() end
        }
    end
end

function Workbench:concatLocalFiles()
    self:getLocalFiles()
    return self:concatenaFiles(self.localFiles, "lua", "plist") --concatena local files that have ext lua or plist
end

function Workbench:pull()
    self:readRemoteFiles(function() self:writeToTabs() end)
end
    
function Workbench:writeToTabs()
    --write to local tabs
    for i,v in ipairs(self.remoteFiles) do
        if v.extension == "lua" then
            saveProjectTab(self.projectName..":"..v.nameNoExt, v.data)
        end
    end
    
    --find and delete local orphans
    local deleteList = {}
    for i,loc in ipairs(self.localFiles) do
        local delete = true
        for _,rem in ipairs(self.remoteFiles) do
            if loc.nameNoExt == rem.nameNoExt then delete = false break end
        end
        if delete then 
            table.insert(deleteList, loc.nameNoExt)
            table.remove(self.localFiles, i)
        end
    end
    for i,v in ipairs(deleteList) do
        saveProjectTab(self.projectName..":"..v, nil)
    end
    
    --verify 
    local localFileString = self:concatLocalFiles() -- reread local files 
    local remoteFileString = self:concatenaFiles(self.remoteFiles, "lua", "plist")
    local localFileHash = sha1(localFileString)
    local remoteFileHash = sha1(remoteFileString)
    projects[self.path].hash = localFileHash
    if self:verify(localFileHash, remoteFileHash) then 
       -- Soda.Alert{title = "Pull verified", content = "hash "..localFileHash }
        
        UI.diffViewer("Pull Verified", localFileString, remoteFileString)
    else
        UI.diffViewer("Pull Verify Failed", localFileString, remoteFileString)
    end
    
end

--# Request
Request = {} --handles webDAV requests. if request fails, it wakes up the server, and then tries the request again.
Request.base = class()

function Request.base:init(path, success, data)
    self.path = path
    self.success = success --store the success callback, as it will need to be retried in the event that the connection is lost
    self.data = data
    self:setup()
    printLog(self.status, self.path)
    self:start()
end

function Request.base:start()
    http.request(DavHost..self.path, 
        self.success, 
        function(error) self:fail(error) end, 
        self.arguments)
end

function Request.base:fail(error) --if request fails, most likely we need to wake up the webDAV...
    if error == "Could not connect to the server." then --error == "The network connection was lost." or 
       
       UI.settings(error, 
        "Switching to Working Copy to activate the WebDAV server. When the server has activated, automatic switch back to Codea will occur. \n\nIf you get a red error flag in Working Copy, make sure the WebDAV address and x-callback URL key in the boxes below correspond to the ones in Working Copy settings.",
        "Activate WebDAV",
        function()
            openURL("working-copy://x-callback-url/webdav?cmd=start&key="..workingCopyKey.."&x-success="..urlencode("db-cj1xdlcmftgsyg1://"))
            tween.delay(1, function() displayMode(FULLSCREEN_NO_BUTTONS) self:start() end) --retry
        end)
    else
        alert(error, "Error while "..self.status..self.path)
          
    end
end

--5 webDAV methods: GET, PUT, PROPFIND, MKCOL, DELETE

Request.get = class(Request.base)

function Request.get:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "GET"}
    self.status = "reading file "
end

Request.properties = class(Request.base)

function Request.properties:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True", depth = "1"}, method = "PROPFIND"}
    self.status = "fetching file list at "
end

Request.put = class(Request.base)

function Request.put:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "PUT", data = self.data}
    self.status = "writing file "
end

Request.newFolder = class(Request.base)

function Request.newFolder:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "MKCOL"}
    self.status = "Creating folder at "
end

Request.delete = class(Request.base)

function Request.delete:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "DELETE"}
    self.status = "deleting file "
end

--# Sha1
sha1 = {

_VERSION     = "sha.lua 0.5.0",

_URL         = "https://github.com/kikito/sha.lua",

_DESCRIPTION = [[

SHA-1 secure hash computation, and HMAC-SHA1 signature computation in Lua (5.1)

Based on code originally by Jeffrey Friedl (http://regex.info/blog/lua/sha1)

And modified by Eike Decker - (http://cube3d.de/uploads/Main/sha1.txt)

]],

_LICENSE = [[

MIT LICENSE



Copyright (c) 2013 Enrique García Cota + Eike Decker + Jeffrey Friedl



Permission is hereby granted, free of charge, to any person obtaining a

copy of this software and associated documentation files (the

"Software"), to deal in the Software without restriction, including

without limitation the rights to use, copy, modify, merge, publish,

distribute, sublicense, and/or sell copies of the Software, and to

permit persons to whom the Software is furnished to do so, subject to

the following conditions:



The above copyright notice and this permission notice shall be included

in all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS

OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF

MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY

CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,

TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE

SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]

}



-----------------------------------------------------------------------------------



-- loading this file (takes a while but grants a boost of factor 13)

local PRELOAD_CACHE = true



local BLOCK_SIZE = 64 -- 512 bits



-- local storing of global functions (minor speedup)

local floor,modf = math.floor,math.modf

local char,format,rep = string.char,string.format,string.rep


-- merge 4 bytes to an 32 bit word

local function bytes_to_w32(a,b,c,d) return a*0x1000000+b*0x10000+c*0x100+d end

-- split a 32 bit word into four 8 bit numbers

local function w32_to_bytes(i)
    
    return floor(i/0x1000000)%0x100,floor(i/0x10000)%0x100,floor(i/0x100)%0x100,i%0x100
    
end



-- shift the bits of a 32 bit word. Don't use negative values for "bits"

local function w32_rot(bits,a)
    
    local b2 = 2^(32-bits)
    
    local a,b = modf(a/b2)
    
    return a+b*b2*(2^(bits))
    
end


-- caching function for functions that accept 2 arguments, both of values between

-- 0 and 255. The function to be cached is passed, all values are calculated

-- during loading and a function is returned that returns the cached values (only)

local function cache2arg(fn)
    
    if not PRELOAD_CACHE then return fn end
    
    local lut = {}
    
    for i=0,0xffff do
        
        local a,b = floor(i/0x100),i%0x100
        
        lut[i] = fn(a,b)
        
    end
    
    return function(a,b)
        
        return lut[a*0x100+b]
        
    end
    
end



-- splits an 8-bit number into 8 bits, returning all 8 bits as booleans

local function byte_to_bits(b)
    
    local b = function(n)
        
        local b = floor(b/n)
        
        return b%2==1
        
    end
    
    return b(1),b(2),b(4),b(8),b(16),b(32),b(64),b(128)
    
end



-- builds an 8bit number from 8 booleans

local function bits_to_byte(a,b,c,d,e,f,g,h)
    
    local function n(b,x) return b and x or 0 end
    
    return n(a,1)+n(b,2)+n(c,4)+n(d,8)+n(e,16)+n(f,32)+n(g,64)+n(h,128)
    
end


-- bitwise complement for one 8bit number

local function bnot(x)
    
    return 255-(x % 256)
    
end



-- creates a function to combine to 32bit numbers using an 8bit combination function

local function w32_comb(fn)
    
    return function(a,b)
        
        local aa,ab,ac,ad = w32_to_bytes(a)
        
        local ba,bb,bc,bd = w32_to_bytes(b)
        
        return bytes_to_w32(fn(aa,ba),fn(ab,bb),fn(ac,bc),fn(ad,bd))
        
    end
    
end

local band, bor, bxor
local w32_and, w32_or, w32_xor
local xor_with_0x5c = {}
local xor_with_0x36 = {}

function sha1.assets()
    
    -- bitwise "and" function for 2 8bit number
    
    band = cache2arg (function(a,b)
        
        local A,B,C,D,E,F,G,H = byte_to_bits(b)
        
        local a,b,c,d,e,f,g,h = byte_to_bits(a)
        
        return bits_to_byte(
        
        A and a, B and b, C and c, D and d,
        
        E and e, F and f, G and g, H and h)
        
    end)
    coroutine.yield("cached SHA1 band")
    
    
    -- bitwise "or" function for 2 8bit numbers
    
    bor = cache2arg(function(a,b)
        
        local A,B,C,D,E,F,G,H = byte_to_bits(b)
        
        local a,b,c,d,e,f,g,h = byte_to_bits(a)
        
        return bits_to_byte(
        
        A or a, B or b, C or c, D or d,
        
        E or e, F or f, G or g, H or h)
        
    end)
    
    coroutine.yield("cached SHA1 bor")
    
    -- bitwise "xor" function for 2 8bit numbers
    
    bxor = cache2arg(function(a,b)
        
        local A,B,C,D,E,F,G,H = byte_to_bits(b)
        
        local a,b,c,d,e,f,g,h = byte_to_bits(a)
        
        return bits_to_byte(
        
        A ~= a, B ~= b, C ~= c, D ~= d,
        
        E ~= e, F ~= f, G ~= g, H ~= h)
        
    end)
    
    coroutine.yield("cached SHA1 bxor")
    -- create functions for and, xor and or, all for 2 32bit numbers
    
    w32_and = w32_comb(band)
    
    w32_xor = w32_comb(bxor)
    
    w32_or = w32_comb(bor)
    
    for i=0,0xff do
        
        xor_with_0x5c[char(i)] = char(bxor(i,0x5c))
        
        xor_with_0x36[char(i)] = char(bxor(i,0x36))

    end
    
end

-- xor function that may receive a variable number of arguments

local function w32_xor_n(a,...)
    
    local aa,ab,ac,ad = w32_to_bytes(a)
    
    for i=1,select('#',...) do
        
        local ba,bb,bc,bd = w32_to_bytes(select(i,...))
        
        aa,ab,ac,ad = bxor(aa,ba),bxor(ab,bb),bxor(ac,bc),bxor(ad,bd)
        
    end
    
    return bytes_to_w32(aa,ab,ac,ad)
    
end



-- combining 3 32bit numbers through binary "or" operation

local function w32_or3(a,b,c)
    
    local aa,ab,ac,ad = w32_to_bytes(a)
    
    local ba,bb,bc,bd = w32_to_bytes(b)
    
    local ca,cb,cc,cd = w32_to_bytes(c)
    
    return bytes_to_w32(
    
    bor(aa,bor(ba,ca)), bor(ab,bor(bb,cb)), bor(ac,bor(bc,cc)), bor(ad,bor(bd,cd))
    
    )
    
end



-- binary complement for 32bit numbers

local function w32_not(a)
    
    return 4294967295-(a % 4294967296)
    
end



-- adding 2 32bit numbers, cutting off the remainder on 33th bit

local function w32_add(a,b) return (a+b) % 4294967296 end



-- adding n 32bit numbers, cutting off the remainder (again)

local function w32_add_n(a,...)
    
    for i=1,select('#',...) do
        
        a = (a+select(i,...)) % 4294967296
        
    end
    
    return a
    
end

-- converting the number to a hexadecimal string

local function w32_to_hexstring(w) return format("%08x",w) end



local function hex_to_binary(hex)
    
    return hex:gsub('..', function(hexval)
        
        return string.char(tonumber(hexval, 16))
        
    end)
    
end



-- building the lookuptables ahead of time (instead of littering the source code

-- with precalculated values)




-----------------------------------------------------------------------------



-- calculating the SHA1 for some text

function sha1.sha1(msg)
    printLog("generating SHA1 hash")
    
    local H0,H1,H2,H3,H4 = 0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0
    
    local msg_len_in_bits = #msg * 8
    
    
    
    local first_append = char(0x80) -- append a '1' bit plus seven '0' bits
    
    
    
    local non_zero_message_bytes = #msg +1 +8 -- the +1 is the appended bit 1, the +8 are for the final appended length
    
    local current_mod = non_zero_message_bytes % 64
    
    local second_append = current_mod>0 and rep(char(0), 64 - current_mod) or ""
    
    
    
    -- now to append the length as a 64-bit number.
    
    local B1, R1 = modf(msg_len_in_bits  / 0x01000000)
    
    local B2, R2 = modf( 0x01000000 * R1 / 0x00010000)
    
    local B3, R3 = modf( 0x00010000 * R2 / 0x00000100)
    
    local B4    = 0x00000100 * R3
    
    
    
    local L64 = char( 0) .. char( 0) .. char( 0) .. char( 0) -- high 32 bits
    
    .. char(B1) .. char(B2) .. char(B3) .. char(B4) --  low 32 bits
    
    
    
    msg = msg .. first_append .. second_append .. L64
    
    
    
    assert(#msg % 64 == 0)
    
    
    
    local chunks = #msg / 64
    
    
    
    local W = { }
    
    local start, A, B, C, D, E, f, K, TEMP
    
    local chunk = 0
    
    
    
    while chunk < chunks do
        
        --
        
        -- break chunk up into W[0] through W[15]
        
        --
        
        start,chunk = chunk * 64 + 1,chunk + 1
        
        
        
        for t = 0, 15 do
            
            W[t] = bytes_to_w32(msg:byte(start, start + 3))
            
            start = start + 4
            
        end
        
        
        
        --
        
        -- build W[16] through W[79]
        
        --
        
        for t = 16, 79 do
            
            -- For t = 16 to 79 let Wt = S1(Wt-3 XOR Wt-8 XOR Wt-14 XOR Wt-16).
            
            W[t] = w32_rot(1, w32_xor_n(W[t-3], W[t-8], W[t-14], W[t-16]))
            
        end
        
        
        
        A,B,C,D,E = H0,H1,H2,H3,H4
        
        
        
        for t = 0, 79 do
            
            if t <= 19 then
                
                -- (B AND C) OR ((NOT B) AND D)
                
                f = w32_or(w32_and(B, C), w32_and(w32_not(B), D))
                
                K = 0x5A827999
                
            elseif t <= 39 then
                
                -- B XOR C XOR D
                
                f = w32_xor_n(B, C, D)
                
                K = 0x6ED9EBA1
                
            elseif t <= 59 then
                
                -- (B AND C) OR (B AND D) OR (C AND D
                
                f = w32_or3(w32_and(B, C), w32_and(B, D), w32_and(C, D))
                
                K = 0x8F1BBCDC
                
            else
                
                -- B XOR C XOR D
                
                f = w32_xor_n(B, C, D)
                
                K = 0xCA62C1D6
                
            end
            
            
            
            -- TEMP = S5(A) + ft(B,C,D) + E + Wt + Kt;
            
            A,B,C,D,E = w32_add_n(w32_rot(5, A), f, E, W[t], K),
            
            A, w32_rot(30, B), C, D
            
        end
        
        -- Let H0 = H0 + A, H1 = H1 + B, H2 = H2 + C, H3 = H3 + D, H4 = H4 + E.
        
        H0,H1,H2,H3,H4 = w32_add(H0, A),w32_add(H1, B),w32_add(H2, C),w32_add(H3, D),w32_add(H4, E)
        
    end
    
    local f = w32_to_hexstring
    
    return f(H0) .. f(H1) .. f(H2) .. f(H3) .. f(H4)
    
end





function sha1.binary(msg)
    
    return hex_to_binary(sha1.sha1(msg))
    
end



function sha1.hmac(key, text)
    
    assert(type(key)  == 'string', "key passed to sha1.hmac should be a string")
    
    assert(type(text) == 'string', "text passed to sha1.hmac should be a string")
    
    
    
    if #key > BLOCK_SIZE then
        
        key = sha1.binary(key)
        
    end
    
    
    
    local key_xord_with_0x36 = key:gsub('.', xor_with_0x36) .. string.rep(string.char(0x36), BLOCK_SIZE - #key)
    
    local key_xord_with_0x5c = key:gsub('.', xor_with_0x5c) .. string.rep(string.char(0x5c), BLOCK_SIZE - #key)
    
    
    
    return sha1.sha1(key_xord_with_0x5c .. sha1.binary(key_xord_with_0x36 .. text))
    
end



function sha1.hmac_binary(key, text)
    
    return hex_to_binary(sha1.hmac(key, text))
    
end



setmetatable(sha1, {__call = function(_,msg) return sha1.sha1(msg) end })



return sha1

