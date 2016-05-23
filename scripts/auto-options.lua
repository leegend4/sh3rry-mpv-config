-- Set options dynamically.
-- The script aborts without doing anything when you specified a `--vo` option
-- from command line. You can also use `--script-opts=ao-level=<level>`
-- to force a specific level from command line.
--
-- Upon start, `determine_level()` will select a level (o.uq/o.hq/o.mq/o.lq)
-- whose options will then be applied.
--
-- General mpv options can be defined in the `options` table while VO
-- sub-options are to be defined in `vo_opts`.
--
-- To adapt it for personal use one probably has to reimplement a few things.
-- Out of the used functions `determine_level()` is the most important one
-- requiring adjustments since it's pretty OS as well as user specific and
-- serves as an essential component. Other functions provide various, minor
-- supporting functionality, e.g. for use in option-specific sub-decisions.


-- Don't do anything when mpv was called with an explicitly passed --vo option
if mp.get_property_bool("option-info/vo/set-from-commandline") then
    return
end

local f = require 'auto-options-functions'
local opts = require 'mp.options'

local o = {
    uq = "ultra-quality",
    hq = "high-quality",
    mq = "medium-quality",
    lq = "low-quality",
    highres_threshold = "1920x1080@60.00hz",
    force_low_res = false,
    verbose = true,
    duration = 2,
    duration_err_mult = 2,
    
}
opts.read_options(o)


-- Specify a VO for each level

vo = {
    [o.uq] = "opengl-hq",
    [o.hq] = "opengl-hq",
    [o.mq] = "opengl-hq",
    [o.lq] = "opengl",
}


-- Specify VO sub-options for different levels
vo_opts = {
    [o.uq] = {
        ["scale"]  = "ewa_lanczossharp",
        ["cscale"] = "ewa_lanczos",
        ["dscale"] = "ewa_lanczos",
        ["scale-antiring"]  = "1",
        ["cscale-antiring"] = "1",
        ["dscale-antiring"] = "1",
        ["scale-radius"]    = "4",
        ["cscale-radius"]    = "4",
        ["dscale-radius"]    = "4",        
        ["dither-depth"]        = "auto",
        ["scaler-resizes-only"] = "yes",
        ["sigmoid-upscaling"]   = "yes",
        ["linear-scaling"]    = "yes",
        ["blend-subtitles"]     = "video",
        ["correct-downscaling"] = "yes",
        ["deband"]            = "yes",     
        ["prescale-passes"]     = "2",
        ["prescale-downscaling-threshold"] = "1.5",
        ["3dlut-size"]        = "512x512x512",        
    },

    [o.hq] = {
        ["scale"]  = "ewa_lanczossharp",
        ["cscale"] = "ewa_lanczos",
        ["dscale"] = "spline64",
        ["scale-antiring"]  = "0.8",
        ["cscale-antiring"] = "0.8",
        ["scale-radius"]    = "3",
        ["cscale-radius"]    = "4",
        ["dscale-radius"]    = "3",        
        ["dither-depth"]        = "auto",
        ["scaler-resizes-only"] = "yes",
        ["sigmoid-upscaling"]   = "yes",
        ["linear-scaling"]    = "yes",
        ["blend-subtitles"]     = "video",
        ["correct-downscaling"] = "yes",
        ["deband"]            = "yes",     
        ["prescale-passes"]     = "2",
        ["prescale-downscaling-threshold"] = "1.5",
        ["3dlut-size"]        = "384x384x384",        
    },

    [o.mq] = {
        ["scale"]  = "ewa_lanczossharp",
        ["cscale"] = "ewa_lanczos",
        ["dscale"] = "spline36",
        ["scale-antiring"]  = "0.8",
        ["cscale-antiring"] = "0.8",
        ["scale-radius"]    = "3",
        ["cscale-radius"]    = "3",
        ["dscale-radius"]    = "3",        
        ["dither-depth"]        = "auto",
        ["scaler-resizes-only"] = "yes",
        ["sigmoid-upscaling"]   = "yes",
        ["linear-scaling"]    = "yes",
        ["blend-subtitles"]     = "video",
        ["correct-downscaling"] = "yes",
        ["deband"]            = "yes",     
        ["prescale-passes"]     = "2",
        ["prescale-downscaling-threshold"] = "1.5",
        ["3dlut-size"]        = "256x256x256",        
    },

    [o.lq] = {          
        ["scale"]  = "bilinear",
        ["cscale"] = "bilinear",
        ["dscale"] = "bilinear",      
        ["dither-depth"]        = "auto",      
        ["scaler-resizes-only"] = "yes",     
        ["blend-subtitles"]     = "yes",      
    },
}


-- Specify general mpv options for different levels

options = {
    [o.uq] = {
        ["options/vo"] = function () return vo_property_string(o.uq, vo, vo_opts) end,
        ["options/hwdec"] = "auto",
        ["options/vd-lavc-threads"] = "16",
    },
    
    [o.hq] = {
        ["options/vo"] = function () return vo_property_string(o.hq, vo, vo_opts) end,
        ["options/hwdec"] = "auto",
        ["options/vd-lavc-threads"] = "16",
      --["options/vf-add"] = "vdpaupp=sharpen=0.10:denoise=0.10:deint=yes:deint-mode=temporal-spatial:pullup:hqscaling=1",
       
    },

    [o.mq] = {
        ["options/vo"] = function () return vo_property_string(o.mq, vo, vo_opts) end,   
        ["options/hwdec"] = "auto",
    },

    [o.lq] = {
        ["options/vo"] = function () return vo_property_string(o.lq, vo, vo_opts) end,
        ["options/hwdec"] = "auto",
    },
}


-- Print status information to VO window and terminal

mp.observe_property("vo-configured", "bool",
                    function (name, value) print_status(name, value, o) end)


-- Determined level and set the appropriate options

function main()
    o.force_low_res = mp.get_opt("ao-flr")
    o.level = determine_level(o, vo, vo_opts, options)
    o.err_occ = false
    for k, v in pairs(options[o.level]) do
        if type(v) == "function" then
            v = v()
        end
        success, err = mp.set_property(k, v)
        o.err_occ = o.err_occ or not (o.err_occ or success)
        if success and o.verbose then
            print("Set '" .. k .. "' to '" .. v .. "'")
        elseif o.verbose then
            print("Failed to set '" .. k .. "' to '" .. v .. "'")
            print(err)
        end
    end
end

main()
