UI = {}

function UI.main()
    local guidex, guidey = 0.33, -330
    local margin = 5
    
     UI.preview = Preview{
        x = guidex, y = 0.2, w = 0, h = guidey,
    }
    
    UI.console = Soda.TextScroll{
        x = guidex, y = 0, w = 0, h = 0.2,
        shape = Soda.RoundedRectangle,
        textBody = "\n#### Working Copy Codea Client ####"
    }
    
    UI.finder = Finder(guidex)
    
    UI.workbench = Workbench(guidex, guidey)
    
    Soda.CloseButton{
        parent = UI.workbench.window,
        x = -margin, y = -margin,
        style = Soda.style.icon,
        callback = function()
            close()
        end
    }
    
    Soda.AddButton{
        parent = UI.finder.window,
        x = -margin, y = -margin,
        style = Soda.style.icon
    }

    UI.settingsButton = Soda.SettingsToggle{
        parent = UI.finder.window,
        x = margin, y = -margin,
        style = Soda.style.icon,
        callback = function(sender) UI.settings("Global Settings", "Enter your Working Copy x-callback URL key and the address of the WebDAV server.\n\nNote that as digest authentication is not currently supported, you need to use the Working Copy WebDAV server in LOCAL mode and delete the WebDAV username and password.", "Save", function() sender:switchOff() end) end,
    }
    
end

function UI.settings(title, content, ok, callback)
     local this = Soda.Window{
        w = 0.7, h = 0.6, alert = true,
        title = title,
        content = content, 
        shadow = true, blurred = true, style = Soda.style.darkBlurred,
    }
    
    local key = Soda.TextEntry{
        parent = this,
        x = 10, y = 60, w = -10, h = 40,
        title = "x-callback URL key:",
        default = workingCopyKey
    }
    
    local dav = Soda.TextEntry{
        parent = this,
        x = 10, y = 110, w = -10, h = 40,
        title = "WebDAV host:",
        default = DavHost
    }
    
    Soda.Button{
        parent = this,
        x = -10, y = 10, w = 0.3, h = 40,
        title = ok,
        callback = function()
            workingCopyKey = key:output()
            saveLocalData("workingCopyKey", workingCopyKey)
            DavHost = dav:output()
            saveLocalData("DavHost", DavHost)
            this:hide()
            callback()
        end
    }
end



