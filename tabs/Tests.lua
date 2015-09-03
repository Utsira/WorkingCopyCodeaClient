--WebDAV = {address = "http://webdav@192.168.1.71:8080/", password = "EPKKZU2L", port = 8080, username = "webdav", headers ={Translate="f", SendChunks = true, AllowWriteStreamBuffering = true}, method = "PUT", data = "", useragent = ""} --?username=webdav&password=EPKKZU2L  password = "EPKKZU2L", username = "webdav"webdav@

parameter.action("webdavWrite", function() http.request("http://localhost:8080/Codea/WebDavTest.lua", success, fail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "PUT", data = readProjectTab("WorkingCopy")}) end) 

parameter.action("webdavRead", function() http.request("http://localhost:8080/Codea/README", success, fail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True"}, method = "GET"}) end) --/README

parameter.action("Get File Names", function() http.request("http://localhost:8080/Codea/", getFileNames, fail, {headers ={Translate="f", SendChunks = "True", AllowWriteStreamBuffering = "True", depth = "1"}, method = "PROPFIND"}) end) 

function success(data,status,headers)
    print("data:", data, "status:", status)
    for k,v in pairs(headers) do
        print(k,v)
    end
    if type(data)=="table" then
        for k,v in pairs(data) do
            print(k,v)
        end
    end
end

function fail(error)
    print(error)
end



--infinity fail	Request failed: bad request (400)
--[[
  <?xml version="1.0" encoding="utf-8" ?> 
  <propfind xmlns="DAV:"> 
    <propname/> 
  </propfind> ]]
