function Workbench:pushInstaller(t)

    local localFileStr = table.concat{"--", "# Main\n\n", 'local url = "', githubHome, self.repo, "/master/", self.repoPath, '/"\n', readProjectTab("Installer"):match("%-%-%[%[(.-)%]%]")}
    local pathName = "/"..self.repo.."/"..t.name --urlencode(self.projectName.." Installer.lua")
    printLog("Writing to ", pathName)
    printLog(localFileStr)
    print(localFileStr)
    
    Request.put(pathName, 
        function() 
            
          --  Soda.TextWindow{localFileStr}
            Soda.TextWindow{
                    title = "Write Successful",   
                    textBody = localFileStr,
                    ok = "Working Copy "..Soda.symbol.forward,
                    alert = true, close = true,
                    callback = function()
    
                        WCcommit(self.repo, self.repopath)
                      --  openURL("working-copy://x-callback-url/commit/?key="..workingCopyKey.."&limit=1&repo="..urlencode(t.repo).."&path="..repopath) 
            --self.path:match("/(.-)/$")
                    end
                }
            
        end, localFileStr)
    
end
