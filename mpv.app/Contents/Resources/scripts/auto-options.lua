-- Set options dynamically.
-- The script aborts without doing anything when you specified a `--vo` option
-- from command line. You can also use `--script-opts=ao-level=<level>`
-- to force a specific level from command line.
--
-- Upon start, `determine_level()` will select a level (o.hq/o.mq/o.lq)
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
    hq = "desktop",
    mq = "laptop",
    lq = "low-energy",
    highres_threshold = "1920:1200",
    force_low_res = false,
    verbose = false,
    duration = 5,
    duration_err_mult = 2,
}
opts.read_options(o)


-- Specify a VO for each level

vo = {
    [o.hq] = "opengl-hq",
    [o.mq] = "opengl-hq",
    [o.lq] = "opengl",
}


-- Specify VO sub-options for different levels

vo_opts = {
    [o.hq] = {

    },

    [o.mq] = {
        ["scale"]  = "lanczos",
        ["cscale"] = "ewa_lanczos",
        ["dscale"] = "catmull_rom",
        ["scale-antiring"]  = "1.0",
        ["cscale-antiring"] = "1.0", 
        ["dscale-antiring"] = "1.0",       
        ["scale-radius"]    = "4",
        ["cscale-radius"]   = "3",       
        ["dither-depth"]        = "auto",
        ["scaler-resizes-only"] = "yes",
        ["sigmoid-upscaling"]   = "yes",        
        ["blend-subtitles"]     = "yes",
        ["correct-downscaling"] = "yes",
        ["deband"]              = "yes", 
        ["deband-iterations"]   = "2",        
        ["3dlut-size"]          = "128x128x128",   
        ["icc-profile"]         = "/Library/ColorSync/Profiles/display1-b91bfdfca72aa3c2b2d019435f73b494.icc",
        ["icc-cache-dir"]       = "/Users/sh3rry/Documents/",    
        ["scaler-lut-size"]     = "8",                 
        
    },

    [o.lq] = {
        ["scale"]  = "bilinear",
        ["cscale"] = "bilinear",
        ["dscale"] = "bilinear",      
        ["dither-depth"]        = "auto",      
        ["scaler-resizes-only"] = "yes",     
        ["blend-subtitles"]     = "yes",
        ["3dlut-size"]          = "128x128x128",   
        ["icc-profile"]         = "/Library/ColorSync/Profiles/display1-b91bfdfca72aa3c2b2d019435f73b494.icc",
        ["icc-cache-dir"]       = "/Users/sh3rry/Documents/",    
    },
}


-- Specify general mpv options for different levels

options = {
    [o.hq] = {

    },

    [o.mq] = {
        ["options/vo"] = function () return vo_property_string(o.mq, vo, vo_opts) end,
        ["options/hwdec"] = "auto",
        ["options/video-output-levels"] = "full",
        ["options/hwdec-codecs"] = "all",
    },

    [o.lq] = {
        ["options/vo"] = function () return vo_property_string(o.lq, vo, vo_opts) end,
        ["options/hwdec"] = "auto",
        ["options/video-output-levels"] = "full",
        ["options/hwdec-codecs"] = "all",
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