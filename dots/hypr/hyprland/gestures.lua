local vars = require("variables")

hl.config({
    gestures = {
        workspace_swipe_distance                 = 700,
        workspace_swipe_cancel_ratio             = 0.15,
        workspace_swipe_min_speed_to_force       = 5,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new               = true,
    },
})

-- Helper to register gestures safely so config reloads never trip an uncaught Lua error
local function safe_gesture(g)
    pcall(hl.gesture, g)
end

safe_gesture({ fingers = vars.workspaceSwipeFingers, direction = "horizontal", action = "workspace" })

-- 3-Finger Vertical Volume (Slightly faster rate)
do
    local counter = 0
    local threshold = 6 -- Decreased threshold for a faster response
    safe_gesture({
        fingers   = vars.gestureFingers,
        direction = "up",
        action    = {
            start = function() counter = 0 end,
            update = function(e)
                if e.delta.y < -3 then
                    counter = counter + 1
                    if counter >= threshold then
                        counter = 0
                        hl.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh volume up")
                    end
                end
            end
        }
    })
end

do
    local counter = 0
    local threshold = 6
    safe_gesture({
        fingers   = vars.gestureFingers,
        direction = "down",
        action    = {
            start = function() counter = 0 end,
            update = function(e)
                if e.delta.y > 3 then
                    counter = counter + 1
                    if counter >= threshold then
                        counter = 0
                        hl.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh volume down")
                    end
                end
            end
        }
    })
end

-- 3-Finger Horizontal (Media Track Control)
safe_gesture({
  fingers = vars.gestureFingers,
  direction = "right",
  action    = function()
      hl.exec_cmd("playerctl next")
  end,
})

safe_gesture({
  fingers = vars.gestureFingers,
  direction = "left",
  action    = function()
      hl.exec_cmd("playerctl previous")
  end,
})

-- 3-Finger + CTRL Vertical Brightness (Slightly faster rate)
do
    local counter = 0
    local threshold = 6
    safe_gesture({
        fingers   = vars.gestureFingers,
        direction = "up",
        mods      = "CTRL",
        action    = {
            start = function() counter = 0 end,
            update = function(e)
                if e.delta.y < -3 then
                    counter = counter + 1
                    if counter >= threshold then
                        counter = 0
                        hl.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh brightness up")
                    end
                end
            end
        }
    })
end

do
    local counter = 0
    local threshold = 6
    safe_gesture({
        fingers   = vars.gestureFingers,
        direction = "down",
        mods      = "CTRL",
        action    = {
            start = function() counter = 0 end,
            update = function(e)
                if e.delta.y > 3 then
                    counter = counter + 1
                    if counter >= threshold then
                        counter = 0
                        hl.exec_cmd("~/.config/hypr/hyprland/scripts/osd.sh brightness down")
                    end
                end
            end
        }
    })
end

-- More fingers (Special workspaces)
safe_gesture({
    fingers   = vars.gestureFingersMore,
    direction = "up",
    action    = function()
        hl.dispatch(hl.dsp.workspace.toggle_special())
    end,
})

safe_gesture({
    fingers   = vars.gestureFingersMore,
    direction = "down",
    action    = function()
        hl.dispatch(hl.dsp.workspace.toggle_special("music"))
    end,
})

-- 3-Finger Pinch (Play/Pause Toggle)
safe_gesture({
    fingers   = 3,
    direction = "pinch",
    action    = function()
        hl.exec_cmd("playerctl play-pause")
    end,
})