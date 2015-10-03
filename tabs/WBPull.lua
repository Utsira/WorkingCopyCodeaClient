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
    local localFileString = self:concatLocalFiles() -- reread local files and get hash
    local remoteFileString = self:concatenaFiles(self.remoteFiles, "lua", "plist")
    
    if self:verify(sha1(localFileString), sha1(remoteFileString)) then 
       -- Soda.Alert{title = "Pull verified", content = "hash "..localFileHash }
        projects[self.path].hash = localFileHash
        UI.diffViewer("Pull Verified", localFileString, remoteFileString)
    else
        UI.diffViewer("Pull Verify Failed", localFileString, remoteFileString)
    end
    
end
