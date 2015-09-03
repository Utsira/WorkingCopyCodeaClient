-- Working Copy

function urlencode(str)
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])", 
        function (c)
            return string.format ("%%%02X", string.byte(c))
        end)
    str = string.gsub (str, " ", "%%20") -- %20 encoding, not + 
    return str
end

function concatURL(url1, url2, sep)
    local sep = sep or "&x-success="
    return url1..sep..urlencode(url2) --to chain urls, must be double-encoded.
end

--[[
function createCommitURL(repo, limit, path)
    if path then path = "&path="..path..".lua" else path = "" end
    local commitURL= "working-copy://x-callback-url/commit/?key="..workingCopyKey.."&repo="..repo..path.."&limit="..limit --.."&message="..urlencode(commitMessage)
    
    if Push_to_remote_repo then --add push command
        commitURL = concatURL(commitURL, "working-copy://x-callback-url/push/?key="..workingCopyKey.."&repo="..repo)
    end
    return commitURL
end
  ]]

--[[
local function createWriteURL(repo, path, txt)
    return "working-copy://x-callback-url/write/?key="..workingCopyKey.."&repo="..repo.."&path="..path.."&uti=public.txt&text="..urlencode(txt)    --the write command
endo
  ]]

function openWorkingCopy(repo)
    openURL("working-copy://open?repo="..urlencode(repo))
end

function readProjectFile(project, name, warn)
    local path = os.getenv("HOME") .. "/Documents/"
    local file = io.open(path .. project .. ".codea/" .. name,"r")
    if file then
        local plist = file:read("*all")
        file:close()
        return plist
    elseif warn then
        alert("WARNING: unable to read " .. name)
    end
end

function readProjectPlist(project)
    return readProjectFile(project, "Info.plist", true)
end