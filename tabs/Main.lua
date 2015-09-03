-- Working Copy Codea Client

DavHost = readLocalData("DavHost", "http://localhost:8080")
workingCopyKey = readLocalData("workingCopyKey", "")

displayMode(FULLSCREEN)
supportedOrientations(CurrentOrientation)
function setup()
   -- projectString = saveLocalData("projects", nil)
   -- local sha1 = require("sha1")
   -- print("sha1", sha1(readProjectTab("Main")))
    projectString = readLocalData("projects", "[]")
    projects = json.decode(projectString)
    UX = {files={}, folders={}}
    currentX, targetX = 0,0
    panelY = HEIGHT-80
    --path = "/"
  --  pathElements = {"/"}
  --  path = "/"
    UX.main={
       -- back = Button('\u{21b0}', 20, HEIGHT-140, 60, 60, 6), --Back 
        settings = Button('\u{2699}', WIDTH-70, HEIGHT-70, 50, 50, 5, function() Dialog.settings("Settings", true) end), --Settings 26ED unsupported
        add = Button("", WIDTH - 140, HEIGHT-70, 50, 50, 4, Dialog.newFile),
       -- commit = Button('Commit remote', 540, 940, 200, 60, 6, test_Clicked),
        status = Control("", 540, HEIGHT-70, WIDTH-680, 70),
         title = Label('WCCC: Working Copy \u{21c4} Codea Client', 20.0, HEIGHT-80, 500, 45),
      --  path = Button(path, 80,HEIGHT-140,500,60, 0, Dialog.getPath)
    }
  --  UX.main.path.textMode = CORNER
  --  UX.main.back.fontSize = 30
    UX.main.settings.fontSize = 40
    UX.main.title.fontSize = 24
    --[[
    UX.main.back.enabled = false
    UX.main.back.callback = function()
        table.remove(pathElements)
        table.remove(UX.folders)
        path = table.concat(pathElements)
        targetX = math.min(currentX + 340, 0)
      --  requestFileNames() 
        UX.main.path.text = path
        if #UX.folders==1 then
            UX.main.back.enabled = false
        end
    end
      ]]
    if workingCopyKey=="" then
        Dialog.settings("Working Copy x-callback key is empty")
    else
         requestFileNames("/")
    end
    consoleLog = {}
end

function printLog(...)
    args = {...}
    for i,v in ipairs(args) do
        args[i] = tostring(v)
    end
    consoleLog[#consoleLog+1]=table.concat(args, " ")
    updateConsole = true
end
    
function requestFileNames(path, linked)
  --  print("request", p)
    Request.properties(path, function(data, status, headers) getFileNames(data, status, headers, path, linked) end)
end

function getFileNames(data, status, headers, path, linked)
    print("received", path)
    if not data then alert(status) return end
    local x,y = 20+#UX.folders*300, -20 --#UX.folders*320
    local typ = Folder
    if #UX.folders == 1 then typ,y = Repository, -140  end
   table.insert( UX.folders, typ(data, x, y, path, #UX.folders+1, linked)) --340
    if x + currentX > WIDTH - 320 then
         targetX = currentX + (WIDTH-300-(x+currentX)) --340
    end
   -- currentX = currentX + 320
  -- UX.folders = {Folder(data)}
end

--[[
function parentLinked() --move back up through chain to see if any of the parents or grandparents are linked
    for i = #UX.folders, 2, -1 do
        local name = table.concat(pathElements,"",1,i):match("(.-)/$") --lop off final slash
        if projects[name] then return true end
    end
end
  ]]

--[[
function pathTruncate(depth)
    while #UX.folders>depth do
        table.remove(pathElements)
        table.remove(UX.folders)
        targetX = math.min(currentX + 300, 0) --340
      --  requestFileNames()        
    end
    path = table.concat(pathElements)
  --  UX.main.path.text = path
end
  ]]

function getFileData(data, status, headers)
    if not data then alert(status) return end
    pasteboard.copy(data)
    box = CodeBox(data)
end

function draw()
    background(184, 184, 184, 255)
    if updateConsole then
        UX.main.status.text = table.concat(consoleLog, "\n", math.max(1, #consoleLog-3))
        updateConsole = false
    end
    for _, element in pairs(UX.main) do
        element:draw()
    end

    currentX = currentX + (targetX - currentX)*0.1
    for i,v in ipairs(UX.folders) do
        v:draw()
        --[[
        for _, element in pairs(v.lines) do
            element:draw()
        end
          ]]
    end

    if UX.box then
    for _, element in pairs(UX.box) do
        element:draw()
    end
    end
  --  if UX.display then UX.display:draw() end

end

function touched(touch)
    if UX.box then
        for _, element in pairs(UX.box) do
              if element:touched(touch) and element.enabled then return end
           -- element:touched(touch)
        end
    else
        for _, element in pairs(UX.main) do
          if element:touched(touch) and element.enabled then return end
            --element:touched(touch)
        end
       -- UX.folders[#UX.folders]:touched(touch)
        
        for i,v in ipairs(UX.folders) do
            v:touched(touch)
           
        end
        
    end
end

function keyboard(key)
    if CCActiveTextBox then
        CCActiveTextBox:acceptKey(key)
    end
end
  
function clamp(v,low,high)
    return math.min(math.max(v, low), high)
end
