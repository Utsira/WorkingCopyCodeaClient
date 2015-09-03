CodeBox = class()

function CodeBox:init(txt)
    local w,h = WIDTH - 40, HEIGHT - 40
    self.txt = txt
    self.lines = {}
    for lin in txt:gmatch("[^\n\r]+") do
        table.insert(self.lines, lin)
    end

    UX.box = {
    Control("", 20, 20, w, h, function(touch) self:touched(touch) end),
    Button("X", w - 40, h - 40, 60, 60, 5, Dialog.cancel),
    
    }
    UX.box[1].background = color(247.0, 247.0, 247.0, 255.0)
    UX.box[1].font = "Inconsolata"
    local _,lineHeight = UX.box[1]:getTextSize()
    self.maxLines = h//lineHeight
    self.startLine = 1
    self:parseLines()
end

function CodeBox:parseLines()
    UX.box[1].text = table.concat(self.lines, "\n", self.startLine, math.min(#self.lines, self.startLine + self.maxLines-1))
end

function CodeBox:touched(touch)
    if touch.y<HEIGHT*0.5 then
        self.startLine = math.min(#self.lines, self.startLine + self.maxLines)
    else
        self.startLine = math.max(1, self.startLine - self.maxLines)
    end
    self:parseLines()
end
