-- check.lua
-- 

local time_at = ngx.timer.at
local shared = ngx.shared
local md5 = ngx.md5
local log = ngx.log
local delay = 10
local ngx_err = ngx.ERR
local handler, checkmd5, updateip
local my_cache = shared["my_cache"]
local filename = '/home/nginx/conf/cop/ip.txt'

if not my_cache then
    log(ngx_err, "disappear the shared dict")
    return
end

checkmd5 = function (filename)
    local fp = io.open(filename, "r")
    if not fp then
        log(ngx_err, "failed to open file")
        return
    end
    local buffer = fp:read("*a")
    fp:close()
    local md5result = md5(buffer)

    return md5result
end

updateip = function (filename)
    my_cache:flush_all()
    local fp = io.open(filename, "r")
    if not fp then
        log(ngx_err, "failed to open file")
        return
    end
    for line in fp:lines() do
        my_cache:set(line, line)
    end
end

handler = function (premature, filename)
    -- do some routine job in Lua just like a cron job
    if premature then
        return
    end
    local md5result, flags = my_cache:get("md5")
    if not md5result then
        md5result = checkmd5(filename)
        updateip(filename)
        my_cache:set("md5", md5result)
    else
        local temp = checkmd5(filename)
        if temp ~= md5result then
            updateip(filename)
            my_cache:set("md5", temp)
        end
    end
    local ok, err = time_at(delay, handler, filename)
    if not ok then
        log(ngx_err, "failed to create the timer: ", err)
        return
    end
end

local ok, err = time_at(delay, handler, filename)
if not ok then
    log(ngx_err, "failed to create the timer: ", err)
    return
end
