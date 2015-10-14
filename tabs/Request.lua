Request = {} --handles webDAV requests. if request fails, it wakes up the server, and then tries the request again.
Request.base = class()

function Request.base:init(path, success, data)
    self.path = path
    self.success = success --store the success callback, as it will need to be retried in the event that the connection is lost
    self.data = data
    self:setup()
    printLog(self.status, self.path)
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
       
       UI.settings(error, 
        "Switching to Working Copy to activate the WebDAV server. When the server has activated, automatic switch back to Codea will occur. \n\nIf you get a red error flag in Working Copy, make sure the WebDAV address and x-callback URL key in the boxes below correspond to the ones in Working Copy settings.",
        "Activate WebDAV",
        function()
            openURL("working-copy://x-callback-url/webdav?cmd=start&key="..workingCopyKey.."&x-success="..urlencode("db-cj1xdlcmftgsyg1://"))
            tween.delay(1, function() displayMode(FULLSCREEN_NO_BUTTONS) self:start() end) --retry
        end)
    else
        alert(error, "Error while "..self.status..self.path)
          
    end
end

--5 webDAV methods: GET, PUT, PROPFIND, MKCOL, DELETE

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

Request.delete = class(Request.base)

function Request.delete:setup()
    self.arguments = {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "DELETE"}
    self.status = "deleting file "
end
