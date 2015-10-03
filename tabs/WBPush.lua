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
            local remoteFileStr = self:concatenaFiles(self.remoteFiles, "lua", "plist") --concatena remote files that have ext lua or plist
            local localFileStr = self:concatenaFiles(self.localFiles, "lua", "plist")
            local hash = self:verify(sha1(localFileStr), sha1(remoteFileStr)) --7. verify
            if hash then 
                printLog("Write verified on hash:", hash)
                projects[self.path].hash = hash
                saveLocalData("projects", json.encode(projects))
                Soda.Alert{
                    title = "Write Successful\n\nHash:"..hash.."\n\nSwitching to Working Copy",   
                    callback = function()
                        openURL("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&limit=999&repo="..self.path:match("/(.-)/$")) --8. commit
                    end
                }
            else --verfication failed
                UI.diffViewer("Verification failed", localFileStr, remoteFileStr)
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

