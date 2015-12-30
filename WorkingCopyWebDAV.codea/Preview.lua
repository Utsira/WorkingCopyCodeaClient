Preview = class(LocalFile)

function Preview:init(t) --(path, name, data, multiProject, repo)
  --  self.repo = t.repo
   -- printLog("repo=", t.repo)
    LocalFile.init(self, t)
    self.rosterBuilt = true --force push and pull buttons to become active if file is linked
    --check whether linked to Codea project, if this file is in a multiProject repo
    if self.multiProject then
        if projects[t.path] and projects[t.path].name then --linked
            self:link()
        else
            self.ui.linkStatus.content = "Not linked to any project"
        end
    end
    
end

function Preview:setupUi()
    local frame = Soda.Window{
        x = 0.5, y = 0.5, w = 700, h = 1,
        title = self.name or "",
        shadow = true, alert = true, close = true
    }
    
    local width = 0.99/3
    local margin = (1 - 0.99)/2
    local w2,w3 = (width * 0.5) + margin, width * 0.97
    
    self.ui = {}
    local scrollHeight = -50
    if self.multiProject then
        scrollHeight = -165
        self.ui.copy = Soda.Button{
            parent = frame,
            x = w2, y = -100, w = w3, h = 60,
            title = "Copy",
            callback = function() pasteboard.copy(self.data) end,
        }
        
        self.ui.link = Soda.Button{
            parent = frame,
            x = w2 + width, y = -100, w = w3, h = 60,
            title = "Link",
        --   inactive = true,
            callback = function() self:linkDialog("Enter the name of an existing Codea project to link it to this file") end
        } 
        
        self.ui.linkStatus = Soda.Frame{
            parent = frame,
            x = margin, y = -50, w = -margin, h = 60,   
            content = "Not linked to any Codea project" 
        }
        
        self.ui.push = Soda.Button{
            parent = frame,
            x = w2 + width * 2, y = -100, w = w3, h = 60,
            title = "Push as\nsingle file",
            inactive = true,
            callback = function() self:pushSingleFile{repo = self.repo, repopath = urlencode(self.name)} end
        }   
        
        --[[
        self.ui.pull = Soda.Button{
            parent = frame,
            x = w2 + width * 3, y = -100, w = w3, h = 60,
            title = "Pull",
            inactive = true,
        } 
          ]]
    end
    
    self.ui.scroll = Soda.TextScroll{
        parent = frame,
        x = 5, y = 5, w = -5, h = scrollHeight,
        textBody = self.data or "",
        shape = Soda.RoundedRectangle,
        shapeArgs = {radius = 20}
    }
end

--[[
function Preview:inputString(txt)
    self.scroll:clearString()
    self.scroll:inputString(txt)
    self.input = txt
    self.button:show(RIGHT)
end

function Preview:clearString()
    self.scroll:clearString()
    self.input = nil
    self.button:hide(RIGHT)
end
  ]]
