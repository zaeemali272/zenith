hl.config({
    animations = {
        enabled = true,
    },
})

-- Ultra-smooth, fast & responsive bezier curves (clamp end point to 1.0 to eliminate popin bounce hitch)
hl.curve("fastDecel", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })
hl.curve("fluidDecel", { type = "bezier", points = { { 0.1, 1.0 }, { 0.15, 1.0 } } })
hl.curve("quickAccel", { type = "bezier", points = { { 0.3, 0.0 }, { 0.8, 0.15 } } })
hl.curve("snappy", { type = "bezier", points = { { 0.2, 0.95 }, { 0.1, 1.0 } } })

-- Fast, buttery smooth animation timings (2.0 = 200ms, 2.5 = 250ms)
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.4, bezier = "fastDecel", style = "popin 88%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.8, bezier = "quickAccel", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.2, bezier = "fluidDecel" })

hl.animation({ leaf = "layersIn", enabled = true, speed = 2.0, bezier = "fastDecel", style = "popin 90%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.6, bezier = "quickAccel", style = "popin 95%" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 1.8, bezier = "fluidDecel" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "fluidDecel", style = "slidefade 15%" })
hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 2.4,
    bezier  = "snappy",
    style   = "slidefadevert 10%"
})

hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "fluidDecel" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 1.8, bezier = "fluidDecel" })
hl.animation({ leaf = "border", enabled = true, speed = 2.2, bezier = "fluidDecel" })

