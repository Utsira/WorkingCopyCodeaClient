function Workbench:setupUi(x,y)
    local x,y = guidex, guidey
    self.ui = {} 
   self.ui.window = Soda.Frame{
        x = x, y = y, w = 0, h =-20,
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

