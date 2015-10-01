Preview = class(LocalFile)

function Preview:init(t)
    local frame = Soda.Frame(t)
    self.scroll = Soda.TextScroll{
        parent = frame,
        x = 0, y = 0, w = 1, h = 1,
        textBody = ""
    }
    
    self.button = Soda.Button{
        parent = frame,
        x = -10, y = -10, w = 70, h = 40,
        title = "Copy",
        callback = function() pasteboard.copy(self.input) end,
        hidden = true
    }
end

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
