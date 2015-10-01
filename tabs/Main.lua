-- Working Copy Codea WebDAV Client 

displayMode(OVERLAY)
displayMode(FULLSCREEN_NO_BUTTONS)

DavHost = readLocalData("DavHost", "http://localhost:8080")
workingCopyKey = readLocalData("workingCopyKey", "")

function setup()
    parameter.watch("#Soda.items")
    Soda.setup()
    sha1.load = coroutine.create( sha1.assets)
    projectString = readLocalData("projects", "[]")
    projects = json.decode(projectString)
    
    consoleLog = {}
    UI.main()
 --requestFileNames("/")
end

function draw()
    if sha1.load then 
        local _, progress = coroutine.resume(sha1.load)
        if coroutine.status(sha1.load) == "dead" then
            printLog("SHA1 caching complete")
            sha1.load = nil
            sha1.ready = true
            collectgarbage()
        else
            printLog(progress or "")
        end
    end
    if #consoleLog > 0 then
        UI.console:inputString( table.concat(consoleLog, "\n"), true) --, math.max(1, #consoleLog-4)
        consoleLog = {}
    end
    --do your updating here
    pushMatrix()
    Soda.camera()
    Soda.drawing()
    popMatrix()
end

function Soda.drawing(breakPoint) 
    --in order for gaussian blur to work, do all your drawing here
    background(251, 251, 255, 255)

    Soda.draw(breakPoint)
end

function printLog(...)
    args = {...}
    for i,v in ipairs(args) do
        args[i] = tostring(v)
    end
    consoleLog[#consoleLog+1]=table.concat(args, " ")
    updateConsole = true
end

--user inputs:

function touched(touch)
    Soda.touched(touch)
end

function keyboard(key)
    Soda.keyboard(key)
end

function orientationChanged(ori)
    Soda.orientationChanged(ori)
end

function table.copy(tab, super)
    super = super or tab
    local new = {}
    for k,v in pairs(tab) do
        if type(v) == "table" and v ~= super then
            new[k] = table.copy(v, super)
        else
            new[k] = v
        end
    end
    return new
end
