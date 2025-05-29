require 'cairo'

-- Template for gauge settings
gauge_template = {
    max_value = 100,
    graph_thickness = 5,
    graph_start_angle = 225,
    graph_unit_angle = 2.7,
    graph_unit_thickness = 2.7,
    graph_bg_colour = 0xffffff,
    graph_bg_alpha = 0.2,
    graph_fg_colour = 0x1793d1,
    graph_fg_alpha = 0.7,
    hand_fg_colour = 0xEF5A29,
    hand_fg_alpha = 1.0,
    txt_weight = 0,
    txt_size = 9.0,
    txt_fg_colour = 0xEF5A29,
    txt_fg_alpha = 1.0,
    graduation_radius = 28,
    graduation_thickness = 0,
    graduation_mark_thickness = 1,
    graduation_unit_angle = 27,
    graduation_fg_colour = 0xFFFFFF,
    graduation_fg_alpha = 0.3,
    caption_weight = 1,
    caption_size = 9.0,
    caption_fg_colour = 0xFFFFFF,
    caption_fg_alpha = 0.3,
}
function get_logical_cpu_count()
    local count = 0
    for line in io.lines("/proc/stat") do
        if line:match("^cpu%d+") then
            count = count + 1
        end
    end
    return count
end


-- CPU % gauges data
gauge = {}
local logical_cores = get_logical_cpu_count()

for i = 0, logical_cores - 1 do
    local x = 50 + ((i % 4) * 73)
    local y = 180
    if (i > 3) then
        y = 250
        if i > 7 then
            y = 320
            if i > 11 then
                y = 390
            end
        end
    end
    table.insert(gauge, {
        name = 'cpu',
        arg = 'cpu' .. i,
        x = x,
        y = y,
        graph_radius = 27,
        graph_thickness = 7,
    })
end

-- GPU usage, temp, power --
table.insert(gauge, {
    name = 'execi',
    arg = '1 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits',
    max_value = 100,
    x = 50,
    y = 520,
    graph_radius = 27,
    graph_thickness = 7,
})
table.insert(gauge, {
    name = 'execi',
    arg = '1 nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits',
    max_value = 95,
    x = 50 + (1 * 80),
    y = 520,
    graph_radius = 27,
    graph_thickness = 7,
})
table.insert(gauge, {
    name = 'execi',
    arg = '1 nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits',
    max_value = 180,
    x = 50 + (1 * 160),
    y = 520,
    graph_radius = 27,
    graph_thickness = 7,
})

-- Function to convert RGB hex to decimal
function rgb_to_r_g_b(colour, alpha)
    return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

-- Function to convert angle to position
function angle_to_position(start_angle, current_angle)
    local pos = current_angle + start_angle
    return ((pos * (2 * math.pi / 360)) - (math.pi / 2))
end

-- Function to draw gauge ring
function draw_gauge_ring(display, data, value)
    -- Localize and merge template data
    for k, v in pairs(gauge_template) do
        if data[k] == nil then data[k] = v end
    end
    local max_value = data['max_value']
    local x, y = data['x'], data['y']
    local graph_radius = data['graph_radius']
    local graph_thickness = data['graph_thickness']
    local graph_unit_angle = data['graph_unit_angle']
    local graph_unit_thickness = data['graph_unit_thickness']
    local graph_start_angle = data['graph_start_angle']
    local graph_bg_colour = data['graph_bg_colour']
    local graph_bg_alpha = data['graph_bg_alpha']
    local graph_fg_colour = data['graph_fg_colour']
    local graph_fg_alpha = data['graph_fg_alpha']

    -- Draw background ring
    local end_angle = (100 * graph_unit_angle) % 360
    cairo_arc(display, x, y, graph_radius, angle_to_position(graph_start_angle, 0), angle_to_position(graph_start_angle, end_angle))
    cairo_set_source_rgba(display, rgb_to_r_g_b(graph_bg_colour, graph_bg_alpha))
    cairo_set_line_width(display, graph_thickness)
    cairo_stroke(display)

    -- Draw active value arc
    local val = (value / max_value) * 100
    for i = 1, val do
        local start_arc = (graph_unit_angle * (i - 1))
        local stop_arc = (graph_unit_angle * i)
        cairo_arc(display, x, y, graph_radius, angle_to_position(graph_start_angle, start_arc), angle_to_position(graph_start_angle, stop_arc))
        cairo_set_source_rgba(display, rgb_to_r_g_b(graph_fg_colour, graph_fg_alpha))
        cairo_stroke(display)
    end
end

-- draw vram
function draw_vram_bar(cr, percentage, x, y, width, height, fill_color, outline_color, outline_width)
    -- Draw the background bar
    cairo_set_source_rgba(cr, 0.2, 0.2, 0.2, 0) -- Gray background
    cairo_rectangle(cr, x, y, width, height)
    cairo_fill(cr)

    -- Draw the foreground bar
    cairo_set_source_rgba(cr, fill_color[1], fill_color[2], fill_color[3], fill_color[4])
    cairo_rectangle(cr, x, y, width * (percentage / 100), height)
    cairo_fill(cr)

    -- Draw the outline
    cairo_set_source_rgba(cr, outline_color[1], outline_color[2], outline_color[3], outline_color[4])
    cairo_set_line_width(cr, outline_width)
    cairo_rectangle(cr, x, y, width, height)
    cairo_stroke(cr)
end


function draw_vram_usage_bar()
    local handle = io.popen("nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk '{printf \"%.0f\", $1 / $2 * 100}'")
    local usage_percentage = tonumber(handle:read("*a"))
    handle:close()

    if not usage_percentage then
        usage_percentage = 0
    end

    -- Define bar properties
    local x = 110    -- X position
    local y = 604   -- Y position
    local width = 150  -- Bar width
    local height = 40  -- Bar height
    local fill_color = {0.09, 0.62, 0.89, 0.5}  
    local outline_color = {0.09, 0.62, 0.89, 0.5}  
    local outline_width = 1  -- Outline width in pixels

    -- Draw the bar with an outline
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    draw_vram_bar(cr, usage_percentage, x, y, width, height, fill_color, outline_color, outline_width)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

function draw_text(cr, conky_var, x, y, size, r, g, b, a)
    local value = tonumber(conky_parse('${' .. conky_var .. '}')) or 0
    local text = string.format("%03d%%", value)

    cairo_select_font_face(cr, "Roboto Mono", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    cairo_set_source_rgba(cr, r, g, b, a)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
end
function draw_text_cpu_speed(cr, conky_var, x, y, size, r, g, b, a)
    local value = conky_parse('${' .. conky_var .. '}')
    local text = value .. ' GHz'

    cairo_select_font_face(cr, "Roboto Mono", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    cairo_set_source_rgba(cr, r, g, b, a)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
end
function draw_text_cpu_temp(cr, text, x, y, size, r, g, b, a)

    cairo_select_font_face(cr, "Roboto Mono", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, size)
    cairo_set_source_rgba(cr, r, g, b, a)
    cairo_move_to(cr, x, y)
    local formatted = string.format("03d", text)
    cairo_show_text(cr, text)
end

function cpu_usage(cr)
    for i = 0, logical_cores - 1 do
        local x = 36 + ((i % 4) * 73)
        local y = 185
        if (i > 3) then
            y = 255
            if i > 7 then
                y = 325
                if i > 11 then
                    y = 395
                end
            end
        end
        text = 'cpu cpu' .. i
        draw_text(cr, text, x, y, 12, 1, 1, 1, 1)
    end
end

function cpu_speed(cr)
    for i = 1, logical_cores do
        local x = 23 + ((i % 4) * 73)
        local y = 215
        if (i > 4) then
            y = 285
            if i > 8 then
                y = 355
                if i > 12 then
                    y = 425
                end
            end
        end
        text = 'freq_g ' .. i
        draw_text_cpu_speed(cr, text, x, y, 12, 1, 1, 1, 1)
    end
end



-- Detect CPU vendor (Intel/AMD)
function get_cpu_vendor()
    local handle = io.popen("lscpu | grep 'Vendor ID' | awk '{print $3}'")
    local vendor = handle:read("*a")
    handle:close()
    return vendor:gsub("\n", "")
end


-- CPU Temperature (Intel & AMD)
function conky_cpu_temp()
    local vendor = get_cpu_vendor()

    local temp = "N/A"
    local handle

    if vendor == "GenuineIntel" then
        handle = io.popen("sensors | grep 'Package id 0' | awk '{print $4}'")
    elseif vendor == "AuthenticAMD" then
        handle = io.popen("sensors | grep -E 'Tctl|Tdie' | awk '{print $2}'")
    end

    if handle then
        temp = handle:read("*a"):gsub("\n", "")
        handle:close()
    end

    return temp ~= "" and temp or "N/A"
end

-- CPU Voltage (best effort via Vcore line)
function conky_cpu_voltage()
    local handle = io.popen("sensors | grep -i 'Vcore' | awk '{print $2}'")
    local voltage = handle:read("*a")
    handle:close()
    voltage = voltage:gsub("\n", "")
    return voltage ~= "" and voltage or "N/A"
end

-- CPU Power Usage (Intel via RAPL, AMD via sensors)
function conky_cpu_power()
    local vendor = get_cpu_vendor()
    
    if vendor == "GenuineIntel" then
        -- Intel RAPL method
        local f = io.open("/sys/class/powercap/intel-rapl:0/energy_uj", "r")
        if not f then return "N/A" end
        local e1 = tonumber(f:read("*a"))
        f:close()
        os.execute("sleep 1")
        f = io.open("/sys/class/powercap/intel-rapl:0/energy_uj", "r")
        local e2 = tonumber(f:read("*a"))
        f:close()
        if e1 and e2 then
            local watts = (e2 - e1) / 1e6
            return string.format("%03.0f W", watts)
        end
    elseif vendor == "AuthenticAMD" then
        -- AMD via sensors (might show as "power1")
        local handle = io.popen("sensors | grep -i 'power1' | grep 'average' | awk '{print $2,$3}'")
        local power = handle:read("*a")
        handle:close()
        power = power:gsub("\n", "")
        return power ~= "" and power or "N/A"
    end

    return "N/A"
end

function conky_draw_gpu_data()
    local gpu_usage = tonumber(conky_parse('${execi 1 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits}')) or 0
    local gpu_temp = tonumber(conky_parse('${execi 1 nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits}')) or 0
    local gpu_power = tonumber(conky_parse('${execi 1 nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits}')) or 0
    local gpu_clock = tonumber(conky_parse('${execi 1 nvidia-smi --query-gpu=clocks.gr --format=csv,noheader,nounits}')) or 0
    local gpu_memory = tonumber(conky_parse('${execi 1 nvidia-smi --query-gpu=clocks.mem --format=csv,noheader,nounits}')) or 0

    output = string.format("${goto 36}${color}%03d%%${goto 113}${color}%03d°C${goto 192}${color}%03.0f W\n${goto 255}${voffset -25}${color1}Clock : ${color}  %04dMHz\n${goto 255}${voffset -1}${color1}Mem : ${color}%05dMHz", gpu_usage, gpu_temp, gpu_power, gpu_clock, gpu_memory)
    return conky_parse(output)
end

function conky_display_sys_img()
    local distro = tostring(conky_parse('${execi 86400 grep "PRETTY_NAME" /etc/os-release | cut -d= -f2 | sed \'s/"//g\'}'))
    local icon = "icon-linux.png" -- Default icon
    if distro:match("Ubuntu") then
        icon = "icon-ubuntu.png"
    elseif distro:match("Fedora") then
        icon = "icon-fedora.png"
    elseif distro:match("Arch") then
        icon = "icon-arch.png"
    elseif distro:match("Debian") then
        icon = "icon-debian.png"
    elseif distro:match("Manjaro") then
        icon = "icon-manjaro.png"
    elseif distro:match("Linux Mint") then
        icon = "icon-mint.png"
    elseif distro:match("Pop!_OS") then
        icon = "icon-pop.png"
    elseif distro:match("Kali") then
        icon = "icon-kali.png"
    end
    output = string.format("${image /home/daniel/.config/conky/%s -p 15,30 -s 70x70}", icon)
    return conky_parse(output)

end

function conky_nbfc_cpu_fan()
    local f = io.popen("nbfc status 2>/dev/null")
    if not f then return "N/A" end
    local output = f:read("*a")
    f:close()
    local cpu_rpm = output:match("CPU fan.-Current Fan Speed%s*:%s*([%d%.]+)")
    if cpu_rpm then
        return string.format("%04.0f RPM", tonumber(cpu_rpm))
    else
        return "CPU fan N/A"
    end
end

function conky_nbfc_gpu_fan()
    local f = io.popen("nbfc status 2>/dev/null")
    if not f then return "N/A" end
    local output = f:read("*a")
    f:close()
    local gpu_rpm = output:match("GPU fan.-Current Fan Speed%s*:%s*([%d%.]+)")
    if gpu_rpm then
        return string.format("%04.0f RPM", tonumber(gpu_rpm))
    else
        return "GPU fan N/A"
    end
end



-- Main drawing function
function conky_main()
    if conky_window == nil then return end

    local display = cairo_create(
        cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    )

    for _, data in ipairs(gauge) do
        local value = tonumber(conky_parse(string.format('${%s %s}', data['name'], data['arg']))) or 0
        draw_gauge_ring(display, data, value)
    end

    draw_vram_usage_bar()
    cpu_usage(display)
    cpu_speed(display)
    cpu_temp = conky_cpu_temp()
    cpu_voltage = conky_cpu_voltage()
    cpu_power = conky_cpu_power()
    draw_text_cpu_temp(display, cpu_temp, 305, 185, 15, 0.7, 0.7, 0.7, 1)
    draw_text_cpu_temp(display, cpu_voltage, 305, 255, 15, 0.7, 0.7, 0.7, 1)
    draw_text_cpu_temp(display, cpu_power, 305, 325, 15, 0.7, 0.7, 0.7, 1)
    cairo_destroy(display)
end



