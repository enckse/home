local home = "/home/enck/"
local bin  = home .. ".bin/"
local status = bin .. "status "
local tmp = home .. ".tmp/"
local i3files = tmp .. ".workspace."

function call(script)
    local f = io.popen(script, 'r')
    local s = f:read('*a')
    f:close()
    return s:match("^%s*(.-)%s*$") 
end

function ac()
    return tonumber(call("cat /sys/class/power_supply/AC/online"))
end

function json_text(data)
    return '{ "full_text": ' .. data .. '}'
end

function locking()
    local res = call(bin .. "locking status")
    if res == '' or res == nil then
        return nil
    else
        return json_text(res)
    end
end

function brightness()
    local res = tonumber(call('xrandr --current --verbose | grep "Brightness" | cut -d ":" -f 2 | sed "s/0\\.//g" | sed "s/1\\.0/100/g" | tail -n 1 | awk \'{printf "%3.0f", $1}\' | sed "s/^[ \\t]*//g"'))
    local val = string.format("%3d", res)
    return json_pad("🔆 " .. val .. "%")
end

function online(last)
    local avail = file_exists(tmp .. ".isonline")
    if not avail or last >= 30 then
        call(status .. "online")
    end
    return avail
end

function percent(val)
    local num = tonumber(conky_parse(val))
    local val
    val = num
    if num < 100 then
        val = " " .. val
        if num < 10 then
            val = " " .. val
        end
    end
    return val
end

function file_exists(name)
   local f=io.open(name,"r")
   if f ~= nil then
       io.close(f)
       return true
   else
       return false
   end
end

function updates()
    call(status)
end

function stats()
    local results = {}
    local k, v
    for k, v in pairs({"errors", "git", "email"}) do
        local stat = call(status .. v)
        if stat ~= '' and stat ~= nil then
            table.insert(results, json_pad(stat))
        end
    end
    return results
end

function bad(text)
    return json_text('" ' ..text .. ' ", "color": "#FF0000"')
end

function json_pad(text)
    return json_text('" ' .. text .. ' "')
end

function primary(cache)
    local outputs = {}
    local battery = 0
    local power = "("
    local k, v
    if cache.power ~= nil and cache.battery ~= nil then
        power = cache.power
        battery = cache.battery
    else
        for k, v in pairs({"0", "1"}) do
            local perc = tonumber(call("cat /sys/class/power_supply/BAT" .. v .. "/capacity"))
            battery = battery + perc
            power = power .. string.format("%3d", perc)
            if k == 1 then
                power = power .. ","
            end
        end
        cache.power = power
        cache.battery = battery
    end
    power = power .. ")%"
    local drain = ac() == 0
    if drain then
        power = "-" .. power
        if battery < 20 then
            table.insert(outputs, bad("BATTERY"))
            cache.battery = nil
            cache.power = nil
        end
    else
        power = "+" .. power
    end
    cache.update_interval = cache.update_interval + 1
    if cache.update_interval > 2 then
        cache.update_interval = 0
        updates()
    end
    local avail = online(cache.last_online)
    if avail then
        cache.last_online = cache.last_online + 1
        if cache.last_online > 30 then
            cache.last_online = 0
        end
    else
        cache.last_online = 0
        table.insert(outputs, bad("OFFLINE"))
    end
    table.insert(outputs, locking())
    for k, v in pairs(stats()) do
        table.insert(outputs, v)
    end
    table.insert(outputs, brightness())
    local mute = call("pamixer --get-mute") == "true"
    local vol = tonumber(call("pamixer --get-volume"))
    local sound = ""
    if mute then
        sound = "🔇"
    else
        sound = "🔊"
    end
    sound = sound .. string.format(" %3d%%", vol)
    table.insert(outputs, json_pad(sound))
    table.insert(outputs, json_pad('🔋' .. power))
    local wireless = cache.wireless
    local wired = cache.wired
    local reset = false
    if not avail then
        reset = true
    end
    if cache.wireless ~= nil and cache.wired ~= nil then
        reset = true
    end
    if reset then
        cache.wireless = nil
        cache.wired = nil
    end
    if cache.wireless == nil then
        wireless = ipv4("W", "wlp58s0")
        cache.wireless = wireless
    end
    if cache.wired == nil then
        wired = ipv4("E", "enp0s31f6")
        cache.wired = wired
    end
    table.insert(outputs, wireless)
    table.insert(outputs, wired)
    table.insert(outputs, datetime())
    return outputs
end

function ipv4(prefix, iface)
    local addr = call("ip addr | grep " .. iface .. " | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/' | grep '[0-9][0-9]*\\.[0-9][0-9]*\\.[0-9][0-9]*\\.[0-9][0-9]*$' | sed 's/^/" .. prefix .. ": /g'")
    if addr == '' or addr == nil then
        return nil 
    else
        return json_pad(addr)
    end
end

function datetime()
    return json_pad(call('date +"%Y.%m.%d %H:%M:%S"'))
end

function main(prim)
    local running = true
    local cache = {}
    cache.last_online = 0
    cache.update_interval = 5
    local idx = 0
    while running do
        local values = {}
        if prim then
            values = primary(cache)
        else
            values = {datetime()}
        end
        local netReset = tmp .. ".wswreset"
        if file_exists(netReset) then
            cache.last_online = 0
            call("rm -f " .. netReset)
        end
        print("[")
        for k, v in pairs(values) do
            local out = v
            if k > 1 then
                out = "," .. out
            end
            print(out)
        end
        print("],")
        call("sleep 1")
        idx = idx + 1
        if idx > 30 then
            idx = 0
            cache.battery = nil
            cache.power = nil
        end
    end
end

function i3msg(command, pipe, file)
    return call("i3-msg -t " .. command .. " | tr '{' '\n' | tr '}' '\n' | tr ',' '\n' | sed 's/\"//g' | tr '[:upper:]' '[:lower:]'" .. pipe .. " > " .. file)
end

function lines_from(file)
    lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end

function update_workspace(new, num, workspaces)
    local k
    local v
    local line
    if num < 0 then
        return
    end
    for k, v in pairs(workspaces) do
        if v:find(num .. ":") ~= nil or tonumber(v) == num then
            line = num .. ":" .. new
            call('i3-msg rename workspace "' .. v .. '" to "' .. line .. '" > /dev/null')
        end
    end
end

function workspace()
    local k
    local v
    local treefile = i3files .. "tree"
    local workfile = i3files .. "workspaces"
    local current = ""
    local lastworkspace = -1
    i3msg("get_tree", '| grep -E "^(class|num):" | grep -v "num:\\-" | cut -d " " -f 1 | grep -v "class:i3bar" | cut -d ":" -f 2', treefile)
    i3msg("get_workspaces", ' | grep -E "^name:" | cut -d ":" -f 2-', workfile)
    local workspaces  = lines_from(workfile)
    for k, v in pairs(lines_from(treefile)) do
        local num = tonumber(v)
        if num ~= nil then
            if lastworkspace >= 0 then
                update_workspace(current, lastworkspace, workspaces)
                current = ""
            end
            lastworkspace = num
        else
            if string.len(current) > 0 then
                current = current .. "|"
            end
            current = current .. v
        end
    end
    update_workspace(current, lastworkspace, workspaces)
end

if arg[1] == nil then
    while true do
        workspace()
        call("sleep 1")
    end
else
    main(arg[1] == "primary")
end