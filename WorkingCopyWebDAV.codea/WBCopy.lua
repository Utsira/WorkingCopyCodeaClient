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
