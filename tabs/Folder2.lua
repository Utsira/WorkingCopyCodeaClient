Folder = class()

function Folder:init(data, x, starty, path, depth, linked)
    self.lines={{}}
    self.tabs = {} --the tabs represented by this folder (either the lua files, or the file names listed in info.plist)
    self.subFolders = {}
    self.x = x
    self.path = path
    self.startY = panelY + starty
    self.depth = depth
    self.data = data
    print("path:",path)
   -- self.parentLink = parentLinked()
    self.linked = linked --inherit linked status from parent
    local c = 0
    for name, info in data:gmatch("<D:href>(.-)</D:href>(.-)[\n\r]") do
       -- sound(SOUND_BLIT, 29081)
        c = c + 1
        if c>1 then --the first entry is just the root
            local collection = false        
            if info:find("<D:resourcetype><D:collection/></D:resourcetype>") then 
                collection = true 
                table.insert(self.subFolders, name.."/")
            end
            table.insert(self.lines, self:addLine(name, collection))
        end
     --   print(name)
    end
    local h = math.max(panelY, c * 60)
    local y = panelY - h
    self.y = 0
    self.h = h
    
    local back = Control(path, 20, y, 300, h) --520
    back.background = color(229, 229, 229, 255)
    back.enabled = false
    back.fontSize = 22
    table.insert(self.lines[1], 1, back)
-- print(path, table.concat(UX.files, "\n"))
end

function Folder:draw()
    pushMatrix()
    clip(self.x+20+currentX,20, 300,panelY-20)
   -- background(229, 229, 229, 255)
    stroke(127, 127, 127, 255)
    strokeWidth(1)
    line(self.x+20+currentX,20,self.x+20+currentX,panelY-20)
        translate(self.x+currentX, self.y)
    for _, row in ipairs(self.lines) do
        for _,element in pairs(row) do
            element:draw()
        end
    end
    clip()
    popMatrix()
end

function Folder:touched(touch)
    local t = {x=touch.x, y=touch.y, state=touch.state}
    t.x = t.x - self.x - currentX
    t.y = t.y - self.y
     for _, row in ipairs(self.lines) do
        for _,element in pairs(row) do
            if element:touched(t) and element.enabled then return end
        end
    end   
    if self.lines[1][1]:touched(t) then 
        if touch.state == MOVING then
        self.y = clamp(self.y + touch.deltaY, 0, math.max( 0, self.h - panelY))
            --[[
        local elastic = 0
        if self.y>0 then
            elastic = -self.y * 0.1
        end
        self.y = self.y + elastic
              ]]
        
        elseif touch.state == ENDED then
            if self.depth<#UX.folders then
             --   pathTruncate(self.depth)  
                killChildren(self.depth)          
            end        
        end
    end
end

function Folder:addLine(pathName, collection)
    local name = pathName:match("^"..self.path.."(.+)") --strip out path from name
    local extension = name:match(".-%.(.-)$") --file extension  
    local printName = name:gsub("%%20", " ") --put spaces back
    if collection then printName = "\u{1f4c2}  "..printName end --folder icon

     if extension == "lua" then
        table.insert(self.tabs, {name = name:match("(.-)%.lua$")})
    end
    --[[
    local linked = false
    local linkText, linkable = "Link", true
    if projects[pathName] then linked, linkText = true, "Relink" end
    if self.parentLink then --a child cannot be linked if its parent, grandparent etc already is
        linkText = "Linked"
        linkable = false
        linked = false
    end
      ]]
    local n = #self.lines
    local y = self.startY - (n+0.5) * 60
    local w,h = textSize(printName)
    w = w + 40
    local new
    --[[
    if linked then
        new={
        name = Button(printName, 20.0, y, w, 60, 0, test_Clicked), --540
      --  copy = Button('Copy', 500.0, y, 60.0, 60, 6, test_Clicked),
        
        push = Button('Push', 340, y, 60.0, 60, 6, function() self:push(pathName, collection) end), --560
        pull = Button('Pull', 400, y, 60.0, 60, 6, test_Clicked), --620
        link = Button(linkText, 460, y, 60.0, 60, 6), --680
    }
    else
      ]]
        new={
        name = Button(printName, 20.0, y, w, 60, 0)}--660
      --  copy = Button('Copy', 500.0, y, 60.0, 60, 6, test_Clicked),
    --[[
     link = Button(linkText, 460, y, 60.0, 60, 6)} --680
  end
    new.link.callback = function() Dialog.linkProject(new, pathName, name) end
    new.link.enabled = linkable
   -- new.push.enabled = linked
   -- new.pull.enabled = linked
  ]]
    new.name.textMode = CORNER
    new.name.callback = function() 
        if self.depth<#UX.folders then
          --  pathTruncate(self.depth)
            killChildren(self.depth)
        elseif collection then
        --  path = path..name.."/"         
          --  table.insert(pathElements, name.."/")
         --   path = table.concat(pathElements)
           -- UX.main.back.enabled = true
            requestFileNames(pathName.."/")
          --  UX.main.path.text = path
            
            --unhighlight previous selection
            for i,v in ipairs(self.lines) do
                if v.name and v.name.highlighted then v.name.highlighted = false end
            end
            new.name.highlighted = true
            
        end
        if not collection then
           -- http.request(DavHost..path..name, getFileData, httpfail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "GET"})
           -- self:requestFile(pathName, getFileData)
            Request.get(pathName, getFileData)
        end
    end
    return new
end

function killChildren(depth)
    for i = #UX.folders, depth+1, -1 do
        table.remove(UX.folders, i)
        targetX = math.min(currentX + 300, 0)
    end
end

--[[
function Folder:unHighlight()
    for i,v in ipairs(self.lines) do
        if v.name and v.name.highlighted then v.name.highlighted = false end
    end
end
  ]]

