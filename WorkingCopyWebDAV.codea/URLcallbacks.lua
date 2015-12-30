
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

function WCcommit(repo, path, limit)
    local limit = limit or 1
    local url = "working-copy://x-callback-url/commit/?key="..workingCopyKey.."&limit="..limit.."&repo="..urlencode(repo)
    if path then
        url = url.."&path="..urlencode(path)
    end
    openURL(url)
end

function WCopen(repo,path)
    local url = "working-copy://open?repo="..urlencode(repo)
    if path then
        url = url.."&path="..urlencode(path)
    end
    openURL(url)  
end
