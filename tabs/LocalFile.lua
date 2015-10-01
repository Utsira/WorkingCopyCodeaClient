LocalFile = class()

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

function LocalFile:pushSingleFile(suffix)
    self:getLocalFiles()
    local localFileStr = self:concatenaFiles(self.localFiles, "lua")
    local pathName = self.path..urlencode(self.projectName..suffix)..".lua"
   -- printLog("Writing", pathName)
    Request.put(pathName, 
        function() 
            
            UI.preview:inputString(localFileStr)
            Soda.Alert{
                    title = "Write Successful\n\nSwitching to Working Copy",   
                    callback = function()
                        openURL("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&limit=1&repo="..self.name.."&path="..pathName) 
            --self.path:match("/(.-)/$")
                    end
                }
            
        end, localFileStr)
end