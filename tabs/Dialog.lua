Dialog = {}

function Dialog.cancel()
    hideKeyboard()
    UX.box=nil
   -- self.kill = true
end

--2 templates for text entry and alert
function Dialog.textEntry(title, instruction, textfield, default, cancel)
    local x = (WIDTH-680)*0.5
    local y = (HEIGHT-340)*0.8
    local box = {
        Control(title, x, y, 680.0, 340, test_Clicked),--320
        instruction = Label(instruction, x+20, y+160, 640, 120),
        field = TextField(textfield, x+20, y+80, 640.0, 40, default, 1, test_Clicked),
        ok = Button('OK', x+440, y+20, 200, 40, 6),
        paste = Button('Paste', x+240, y+20, 200, 40, 6),
        }
    if cancel then
        box.cancel = Button('Cancel', x+40, y+20, 200, 40, 1, Dialog.cancel)
    end
    box[1].fontSize = 22 --nb make the background display first
    box[1].background = color(247.0, 247.0, 247.0, 255.0)
    box[1].enabled = false
    box.instruction.textAlign = CENTER
    box.paste.callback = function() 
        if pasteboard.text then box.field.text = pasteboard.text end end
    return box
end

function Dialog.alert(title, message, cancel)
    local x = (WIDTH-680)*0.5
     local box = {
        Control(title, x, 320, 680.0, 220, test_Clicked),
        field = Label(message, x+20, 460, 640.0, 40, default, 1, test_Clicked),
        ok = Button('Proceed', x+440, 340, 200, 40, 1),
        }   
    if cancel then
        box.cancel = Button('Cancel', x+40, 340, 200, 40, 6, Dialog.cancel)
    end
   -- box.field.textMode = CENTER
    box.field.textAlign = CENTER
    
    box[1].fontSize = 22 --nb make the background display first
    box[1].background = color(247.0, 247.0, 247.0, 255.0)
    box[1].enabled = false
    
    return box
end

--specific dialogs that are triggered by various actions. new file, settings, link projects
function Dialog.newFile()
        local x = (WIDTH-600)*0.5
    local y = (HEIGHT-320)*0.5
    local box =  { Control('Create a new file or repository in Working Copy', x,y, 600.0, 320, test_Clicked), --80, 280
    segment = SegmentedControl('Single file in Codea Projects;New repository for multiple files', x+25, y+220, 550.0, 40, 1, test_Clicked),
    projectName = TextField('Name of Codea project', x+40, y+160, 520.0, 40, '', 1, test_Clicked),
    fileName = TextField('Name of new file in Working Copy', x+40, y+100, 520.0, 40, '', 1, test_Clicked),
    ok = Button('OK', x+360, y+40, 200, 40, 6, test_Clicked),
    cancel = Button('Cancel', x+40, y+40, 200, 40, 1, Dialog.cancel)}
    box[1].enabled = false
    box[1].fontSize = 22 --nb make the background display first
    box[1].background = color(247.0, 247.0, 247.0, 255.0)
    UX.box = box
end

function Dialog.settings(message, cancel)
    UX.box = Dialog.textEntry(message, "Enter the x-callback key from Working Copy", 'x-callback key', workingCopyKey, cancel)
    UX.box.ok.callback =
    function()
        workingCopyKey = UX.box.field.text
        saveLocalData("workingCopyKey", workingCopyKey)
        hideKeyboard()
        UX.box=nil
        if #UX.folders == 0 then requestFileNames("/") end
    end

end

function Dialog.linkProject(parent, pathName, name)
    local default = projects[pathName] or name
    UX.box = Dialog.textEntry('Link Codea Project', "Enter the name of an existing Codea project to link it to this file or repository", 'Codea Project Name', default, true)  
    UX.box.ok.callback = function() 
        local inkey = UX.box.field.text  
        if inkey=="" and projects[pathName] then
            UX.box = Dialog.alert ( "Unlink Codea project from Working Copy repository", "No data will be changed, but you will not be able to push and pull without relinking", true)

            UX.box.ok.callback = 
                function() 
                    projects[pathName] = nil 
                    saveLocalData("projects", json.encode(projects))
                    parent.push.enabled = false
                    parent.pull.enabled = false
                    UX.box=nil
                    hideKeyboard()
            end
        else
            local ok,err = pcall( function() readProjectTab(inkey..":Main") end)
            if ok then
                projects[pathName]=inkey
                saveLocalData("projects", json.encode(projects))
                parent.push.enabled = true
                parent.pull.enabled = true
                UX.box=nil
                hideKeyboard()
            else
                alert("Please enter a valid project name", inkey.." not found")
                print(err)
            end
        end
    end 
end

--[[
function Dialog.getPath(message, callback)
    local message = message or "Settings"
    UX.box = Dialog.textEntry( message, "Press OK to switch to Working Copy and activate the WebDAV server.\n\nWhen you see the blue ‘Connect to WebDAV server at [host]’ message,\nswitch back to Codea (e.g. with a 4-finger swipe left).\nMake sure the host URL below matches the one in the Working Copy alert",'WebDAV host URL', DavHost, true) 
    UX.box.ok.callback = function() 
        DavHost = UX.box.field.text 
      --  requestFileNames()
         openURL("working-copy://x-callback-url/webdav-start/?key="..workingCopyKey)
           -- openURL(concatURL("working-copy://x-callback-url/webdav-start/?key="..workingCopyKey, "codea://")) --codea callBack dont work...
       
            tween.delay(1, callback)
         --   UX.box = nil
      --  UX.main.path.text = path
        UX.box=nil 
        hideKeyboard() 
    end 
end
  ]]
