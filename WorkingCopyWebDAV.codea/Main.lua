-- Working Copy Codea WebDAV Client 

assert(SodaIsInstalled, "Set Soda as a dependency of this project") --produces an error if Soda not a dependency

displayMode(OVERLAY)
displayMode(FULLSCREEN_NO_BUTTONS)

DavHost = readLocalData("DavHost", "http://localhost:8080")
workingCopyKey = readLocalData("workingCopyKey", "")
githubHome = readLocalData("githubHome", "https://raw.githubusercontent.com/user_name/")

function setup()
    parameter.watch("workbench.path")
    parameter.watch("workbench.repoPath")
    parameter.watch("workbench.repo")
    Soda.setup()
    sha1.load = coroutine.create( sha1.assets)
    local projectString = readLocalData("projects", "[]")
    projects = json.decode(projectString)
    
    consoleLog = {}
    UI.main()
   -- printLog(projectString)
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
    drawing()
    popMatrix()
end

function drawing(breakPoint) 
    --in order for gaussian blur to work, do all your drawing here
    background(246, 245, 245)

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
    if touch.state == BEGAN then displayMode(FULLSCREEN_NO_BUTTONS) end
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
