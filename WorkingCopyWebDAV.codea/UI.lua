UI = {}

function UI.main()
    guidex, guidey = 0.33, -265
    menuHeight = 25
    local margin = 5
    
    UI.menubar = Soda.Frame{
        x = 0, y = -0.001, w = 1, h = menuHeight,
        shape = Soda.rect,
        title = "Working Copy \u{21c4} Codea Client",
        label = {x = 0.5, y = 0.5},
        style = {shape = {fill = color(0), noStroke = true}, text = {fill = color(200), fontSize = 0.75}}
    }
    
    Soda.Button{
        parent = UI.menubar,
        title = Soda.symbol.back.." Open in Working Copy",
        x = 0, y = 0, w = 200, h = menuHeight,
      --  style = Soda.style.icon,
        shape = null,
        style = {shape = {},  text = {fill = color(200), fontSize = 0.75}},
        callback = function()
            if #UI.finder.paths>1 then
                local path
                if #UI.finder.paths>2 then
                    path = table.concat(UI.finder.titles, "/", 3)
                end
                WCopen(UI.finder.titles[2], path)
                
            else
                openURL("working-copy://open")
            end
        end
    }
    
    Soda.CloseButton{
        parent = UI.menubar,
        x = -0.001, y = 0.5, w = 50, h = menuHeight + 10,
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
    
    UI.finder = Finder(guidex, -menuHeight)
    
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
        w = 0.7, h = 0.7, alert = true,
        title = title,
        content = content, 
        cancel = cancel,
        shadow = true, blurred = true, -- style = Soda.style.darkBlurred,
    }
    
    local key = Soda.TextEntry{
        parent = this,
        x = 10, y = 110, w = -10, h = 40,
        title = "x-callback URL key:",
        default = workingCopyKey
    }
    
    --[[
    Soda.Button{
        parent = this,
        x = -10, y = 60, w = 65, h = 40,
        title = "Paste",
        callback = function() key:inputString(pasteboard.text) end
    }
      ]]
    
    local dav = Soda.TextEntry{
        parent = this,
        x = 10, y = 160, w = -10, h = 40,
        title = "WebDAV host:",
        default = DavHost
    }
    
    local github = Soda.TextEntry{
        parent = this,
        x = 10, y = 60, w = -10, h = 40,
        title = "GitHub raw url:",
        default = githubHome
    }
    --[[
    Soda.Button{
        parent = this,
        x = -10, y = 110, w = 65, h = 40,
        title = "Paste",
        callback = function() dav:inputString(pasteboard.text) end
    }
      ]]
    
    Soda.Button{
        parent = this,
        x = -10, y = 10, w = 0.3, h = 40,
        title = ok,
        callback = function()
            workingCopyKey = key:output()
            saveLocalData("workingCopyKey", workingCopyKey)
            DavHost = dav:output()
            saveLocalData("DavHost", DavHost)
            githubHome = github:output()
            saveLocalData("githubHome", githubHome)
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


