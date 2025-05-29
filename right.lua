-- List top 8 CPU-using processes
function conky_cpu_processes()
    local output = ""
    for i = 1, 8 do
        output = output .. string.format("${goto 25}${top name %d} ${alignr}${top pid %d}   ${top cpu %d}%%\n", i, i, i)
    end
    return conky_parse(output)
end

-- List top 8 Memory-using processes
function conky_mem_processes()
    local output = ""
    for i = 1, 8 do
        output = output .. string.format("${goto 25}${top_mem name %d}${alignr}${top_mem pid %d}    ${top_mem mem_res %d}\n", i, i, i)
    end
    return conky_parse(output)
end


function conky_display_network()
    display = ""
    local f = io.popen("ip route get 8.8.8.8 2>/dev/null | awk '{print $5}'")
    if not f then return "No connection" end
    local iface = f:read("*l")
    f:close()

    if iface then
        iface = iface:match("^%S+")
        -- Check if it's wireless
        local check = io.popen("iw dev " .. iface .. " info 2>/dev/null")
        local output = check:read("*a")
        check:close()
        --WIFI
        if output and output ~= "" then
            display = display .. string.format("${color1}${goto 25}Wi-Fi IP: ${color}${addr %s}\n${color1}${goto 25}SSID: ${color}${wireless_essid %s}\n${color1}${goto 25}Signal: ${color}${wireless_link_qual %s}%%\n${color1}${goto 25}Down: ${color}${downspeed %s}/s ${color1}${alignr}Up: ${color}${upspeed %s}/s\n${goto 25}${downspeedgraph %s 20,120 0000ff 00ff00}${alignr}${upspeedgraph %s 20,120 ff0000 ffff00}", iface, iface, iface, iface, iface, iface, iface)
            return conky_parse(display)
        --LAN
        else
            display = display .. string.format("${color1}${goto 25}Ethernet IP: ${color}${addr %s}\n\n${color1}${goto 25}Down: ${color}${downspeed %s}/s ${color1}${goto 235}Up: ${color}${upspeed %s}/s\n${goto 25}${downspeedgraph %s 20,120 0000ff 00ff00}${alignr}${upspeedgraph %s 20,120 ff0000 ffff00}",iface, iface, iface, iface, iface)
            return conky_parse(display)
        end
    end
    return conky_parse("${color1}${goto 25}No network connection detected!")
end
-- Get all mounted block devices (ignoring loop & tmpfs boot)
function get_mounted_drives()
    local drives = {}
    local cmd = "lsblk -o NAME,MOUNTPOINT -nr | grep -vE 'boot|loop|tmpfs|\\[SWAP\\]'"
    local f = io.popen(cmd)
    for line in f:lines() do
        local name, mount = line:match("(%S+)%s+(%S+)")
        if name and mount then
            table.insert(drives, {name = name, mount = mount})
        end
    end
    f:close()
    return drives
end

-- Main function to display all
function conky_display_drives()
    local couter = 0
    local out = ""
    local drives = get_mounted_drives()

    for _, d in ipairs(drives) do
        if couter < 4 then
            local path = d.mount
            path = path:gsub(" ", "\\ ")

            output = string.format("${color1}${goto 25}%s : ${color}${fs_used %s} / ${fs_size %s} ${alignr}${fs_used_perc %s}%% ${color2}${fs_bar 10,100 %s}\n${color1}${goto 25}Read: ${color}${diskio_read %s} ${color1}${goto 195}Write: ${color}${diskio_write %s}\n${goto 25}${diskiograph_read %s 20,150 0000ff 00ff00}${goto 195}${diskiograph_write %s 20,150 ff0000 ffff00}\n", d.name, path, path, path, path, d.name, d.name, d.name, d.name)
            out = out .. output
            couter = couter + 1
        end
    end
    if couter == 1 then
        offset = 232
    elseif couter == 2 then
        offset = 155
    elseif couter == 3 then
        offset = 77
    elseif couter == 4 then
        offset = 0
    end
    out = out .. string.format("\n${goto 10}${color1}${voffset %d}------------------------------------------------------------------------------", offset)
    return conky_parse(out)

end
