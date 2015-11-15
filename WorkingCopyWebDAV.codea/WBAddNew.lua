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
