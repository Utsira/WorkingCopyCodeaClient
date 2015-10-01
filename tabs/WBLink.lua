--link and unlink Codea projects

function Workbench:link()
    self.ui.link.title = "Relink"
    if self.rosterBuilt then
        self.ui.push:activate()
        self.ui.pull:activate()
    end
    self.projectName = projects[self.path].name
    self.ui.linkStatus.content = "Linked to Codea project ‘"..self.projectName.."’" 
end

function Workbench:unlink()
    self.ui.link.title = "Link"
    self.ui.push:deactivate()
    self.ui.pull:deactivate()
    self.projectName = nil
    self.ui.linkStatus.content = "Not linked to any project"
end

function Workbench:linkDialog()
    local pathName, name = self.path, self.name
    
    local default = name
    if projects[pathName] and projects[pathName].name then
        default = projects[pathName].name 
    end
    
    local this = Soda.Window{
        w = 0.7, h = 0.6,
        title = "Link Codea Project",
        content = "Enter the name of an existing Codea project to link it to this file or repository",
        cancel = true, shadow = true, blurred = true, alert = true, style = Soda.style.darkBlurred
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
                        projects[pathName] = nil 
                        saveLocalData("projects", json.encode(projects))
                        self:unlink()
                    end
                }
            else
                print("#"..inkey.."#")
                local ok,err = pcall( function() readProjectTab(inkey..":Main") end)
                if ok then
                    projects[pathName]={name = inkey}
                    saveLocalData("projects", json.encode(projects))
                    self:link()
                else
                    Soda.Alert{title = "Please enter a valid project name", content = inkey.." not found"}
                    print(err)
                end
            end
        end
    }
    
end