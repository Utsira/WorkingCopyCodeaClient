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