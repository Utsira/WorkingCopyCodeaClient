Request = {} --handles webDAV requests. if request fails, it wakes up the server, and then tries the request again.
Request.base = class()

function Request.base:init(path, success, data)
    self.path = path
    self.success = success --store the success callback, as it will need to be retried in the event that the connection is lost
    self.data = data
    self:setup()
    print(self.status, self.path)
    self:start()
end

function Request.base:start()
    http.request(DavHost..self.path, 
        self.success, 
        function(error) self:fail(error) end, 
        self.arguments)
end

function Request.base:fail(error) --if request fails, most likely we need to wake up the webDAV...
    if error == "Could not connect to the server." then --error == "The network connection was lost." or 
       --  Dialog.getPath(error, function() self:start() end)
     
      --  local message = error or "Settings"
        UX.box = Dialog.textEntry( error, "Press OK to switch to Working Copy and activate the WebDAV server.\n\nWhen you see the blue ‘Connect to WebDAV server at [host]’ message,\nswitch back to Codea (e.g. with a 4-finger swipe left).\nMake sure the host URL below matches the one in the Working Copy alert",'WebDAV host URL', DavHost, true)
        UX.box.ok.callback = function()
            DavHost = UX.box.field.text
            --  requestFileNames()
            openURL("working-copy://x-callback-url/webdav?cmd=start&key="..workingCopyKey)
            -- openURL(concatURL("working-copy://x-callback-url/webdav-start/?key="..workingCopyKey, "codea://")) --codea callBack dont work...
            
            tween.delay(1, function() self:start() end) --retry
            --   UX.box = nil
            --  UX.main.path.text = path
            UX.box=nil
            hideKeyboard()
        end
    else
        alert(error, "Error while "..self.status..self.path)
          
    end
end

--4 webDAV methods: GET, PUT, PROPFIND, MKCOL

Request.get = class(Request.base)

function Request.get:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "GET"}
    self.status = "reading file "
end

Request.properties = class(Request.base)

function Request.properties:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True", depth = "1"}, method = "PROPFIND"}
    self.status = "fetching file list at "
end

Request.put = class(Request.base)

function Request.put:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "PUT", data = self.data}
    self.status = "writing file "
end

Request.newFolder = class(Request.base)

function Request.newFolder:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "MKCOL"}
    self.status = "Creating folder at "
end
