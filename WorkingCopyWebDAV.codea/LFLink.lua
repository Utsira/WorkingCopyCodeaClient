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
    
    local default = name:gsub("%..*$", "")
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
