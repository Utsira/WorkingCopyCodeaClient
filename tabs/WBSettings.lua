--[==[
function Workbench:settings()
    local this = Soda.Window{
        hidden = true,
        w = 0.7, h = 0.6,
        blurred = true, shadow = true,
        style = Soda.style.darkBlurred,
        title = "Repository settings for "..self.window.title,
    }
    
    local single = Soda.Frame{
        parent = this,
        x = 10, y = 60, w =-10, h=-100,
        content = [[
    Repository contains a single Codea project. 
    
    Its tabs will be saved as separate lua files in /tabs. 
    The Info.plist will be saved in the root to preserve tab order. 
    This is the recommended mode for larger Codea projects.
    
    
    
    Save an installer file to the root of the project in Codea's “Paste into project” format, to make installation easier for Codea users not running a source code manager like this one or CodeaSCM]]
    }
    
    Soda.Switch{
        parent = single,
        x = 0.5, y = 0.5,
        title = "Save “"..self.window.title.."Installer.lua” file to root",
        callback = function() self.saveInstaller = true end,
        callbackOff = function() self.saveInstaller = false end,
        on = true
    }
    
    local multi = Soda.Frame{
        parent = this,
        x = 10, y = 60, w =-10, h=-100,
        content = [[Repository contains multiple, smaller Codea projects. 
    
    Projects are written to this repository as single files using Codea's “paste into project” format.
    
    This is for backing up smaller projects that do not require a dedicated repository.]]
    }
    
    local selector = Soda.Segment{
        parent = this,
        x = 10, y = -50, w = -10, h = 40,
        text = {"Single project", "Multiple projects"},
        panels = {single, multi},
      --  callback = function(sender, selected)

      --  end
    }
    
    Soda.Button{      
        parent = this,
        x = 10, y = 10, w = 0.3, h = 40,  
        title = "Cancel",
        callback = function() 
            this:hide()
            self.ui.settings:switchOff() 
        end
    }
    
    Soda.Button{      
        parent = this,
        x = -10, y = 10, w = 0.3, h = 40,  
        title = "Save",
        style = Soda.style.warning,
        callback = function() 
            if selector.selected.idNo == 1 then
                self.singleProject = true
                printLog("Repo Settings:", self.window.title, "set to single project")
            else
                self.singleProject = false
                printLog("Repo Settings:", self.window.title, "set to multiple projects")
            end
            this:hide()
            self.ui.settings:switchOff() 
        end
    }
    
    self.ui.settingsDialog = this
end
  ]==]
