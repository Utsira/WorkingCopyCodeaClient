UI = {}

function UI.main()
    guidex, guidey = 0.33, -265
    local margin = 5
    
    --[[
     UI.preview = Preview{
        x = guidex, y = 0.2, w = 0, h = guidey,
    }
      ]]
    
    UI.menubar = Soda.Frame{
        x = 0, y = -0.001, w = 1, h = 20,
        shape = Soda.rect,
        title = "Working Copy \u{21c4} Codea Client",
        label = {x = 0.5, y = 0},
        style = {shape = {fill = color(0), noStroke = true}, text = {fill = color(200), fontSize = 0.75}}
    }
    
    Soda.Button{
        parent = UI.menubar,
        title = Soda.symbol.back.." Open in Working Copy",
        x = 0, y = 0, w = 200, h = 20,
      --  style = Soda.style.icon,
        shape = null,
        style = {shape = {},  text = {fill = color(200), fontSize = 0.75}},
        callback = function()
            if workbench then
                openURL("working-copy://open?repo="..urlencode(workbench.name))
            else
                openURL("working-copy://open")
            end
        end
    }
    
    Soda.CloseButton{
        parent = UI.menubar,
        x = -0.001, y = -0.001, w = 50, h = 25,
        shape = null,
        style = {shape = {},  text = {fill = color(200), fontSize = 1}},
        callback = function()
            close()
        end
    }
    UI.console = Soda.TextScroll{
        x = guidex, y = 0, w = 0, h = 0.2,
        shape = Soda.RoundedRectangle,
        textBody = "\n#### Working Copy Codea Client ####"
    }
    
    UI.finder = Finder(guidex, -20)
    
  --workbench = Workbench(guidex, guidey)
    
    --[[
    Soda.AddButton{
        parent = UI.finder.window,
        x = -margin, y = -margin,
        style = Soda.style.icon
    }
      ]]

    UI.settingsButton = Soda.SettingsButton{
        parent = UI.finder.window,
        x = margin, y = -margin,
        --style = Soda.style.icon,
        callback = function(sender) UI.settings("Global Settings", "Enter your Working Copy x-callback URL key and the address of the WebDAV server.\n\nNote that as digest authentication is not currently supported, you need to use the Working Copy WebDAV server in LOCAL mode and delete the WebDAV username and password.", "Save", function() sender:switchOff() end, true) end,
    }
    
end

function UI.settings(title, content, ok, callback, cancel)
     local this = Soda.Window{
        w = 0.7, h = 0.6, alert = true,
        title = title,
        content = content, 
        cancel = cancel,
        shadow = true, blurred = true, -- style = Soda.style.darkBlurred,
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
            this.kill = true
            callback()
        end
    }
end

function UI.diffViewer(message, loc, rem)
    local this = Soda.Window{
        w = 0.7, h = 1, alert = true,
        title = message,
        close = true,
        shadow = true, blurred = true, -- style = Soda.style.darkBlurred,
    }
    
    Soda.TextScroll{
        parent = this,
        x = 0.25, w = 0.49, y = 5, h = -40,
        title = "Local",
        shape = Soda.RoundedRectangle, shapeArgs = {radius = 16},
        subStyle = {"translucent"},
        textBody = loc
    }
    
    Soda.TextScroll{
        parent = this,
        x = 0.75, w = 0.49, y = 5, h = -40,
        title = "Remote",
        shape = Soda.RoundedRectangle, shapeArgs = {radius = 16},
        subStyle = {"translucent"},
        textBody = rem
    }
end


