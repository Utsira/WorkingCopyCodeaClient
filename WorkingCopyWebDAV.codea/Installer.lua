--code used to create installer, do not uncomment!
--[[ 
local function install(data)
    --parse plist into list of tab files
    local array = data:match("<key>Buffer Order</key>%s-<array>(.-)</array>")
    local files = {}   
    for tabName in array:gmatch("<string>(.-)</string>%s") do
        table.insert(files, {name = tabName})
    end   
    --success function
    local function success(i, name, data)
        if not data then alert("No data", name) return end
        print("Loaded "..i.."/"..#files..":"..name)
        files[i].data = data
        for i,v in ipairs(files) do
            if not v.data then 
                return --quit this function if any files have missing data
            end
        end
        --if all data is present then save...
        for i,v in ipairs(files) do
            saveProjectTab(v.name, v.data)
            print("Saved "..i.."/"..#files..":"..v.name)
            load(v.data)() --load...
        end
        setup() --...and run
    end
    --request all the tab files
    for i,v in ipairs(files) do 
        local function retry(error) --try each file twice, in case of time-outs
            print(error, v.name.." not found, retrying")
            http.request(url..v.name..".lua", function(data) success(i, v.name, data) end, function(error2) alert(error2, v.name.." not found") end)
        end
        http.request(url..v.name..".lua", function(data) success(i, v.name, data) end, retry)
    end
end
http.request(url.."Info.plist", install, function (error) alert(error) end)
  ]]
