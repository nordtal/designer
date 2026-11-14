-- Dialog:splitter{ beside=true } puts the side panel's widgets before
-- it left of a splitter and the ones after it right of it. It starts
-- at half the width, or where the user dragged it before, apart from
-- a splitter between parts one above the other: cli/ui.sh keeps 25 %
-- beside for the panel side_panel_beside_kept, and 25 % above and
-- below for side_panel_split_kept, which beside starts at half.

ui_test(function()
  assert(app.forkApiVersion >= 9)

  local sizes = {}
  local function panel(id)
    local dlg = Dialog{ title=id, tab=true }
    dlg:label{ text="Main" }
    dlg:panel{ id=id, width=300 }
    dlg:canvas{ id="left", onpaint=function(ev) sizes.left = { ev.context.width, ev.context.height } end }
    dlg:splitter{ beside=true }
    dlg:canvas{ id="right", onpaint=function(ev) sizes.right = { ev.context.width, ev.context.height } end }
    return dlg
  end

  -- The share of the panel's width that the left part has
  local function share()
    return sizes.left[1] / (sizes.left[1] + sizes.right[1])
  end

  local dlg
  local steps = {
    function()
      dlg = panel("side_panel_beside_test")
      dlg:show()
    end,
    function()
      assert(sizes.left and sizes.right, "a part got no room")
      assert(math.abs(sizes.left[1] - sizes.right[1]) <= 1,
             sizes.left[1] .. " px left, " .. sizes.right[1] .. " px right")
      -- Both parts take the panel's whole height
      assert(sizes.left[2] == sizes.right[2] and sizes.left[2] > 100,
             sizes.left[2] .. " px high left, " .. sizes.right[2] .. " px right")
      dlg:close()
      sizes = {}
      dlg = panel("side_panel_beside_kept")
      dlg:show()
    end,
    function()
      assert(sizes.left and sizes.right, "a part got no room")
      assert(math.abs(share() - 0.25) < 0.02, "the left part has " .. share())
      dlg:close()
      sizes = {}
      dlg = panel("side_panel_split_kept")
      dlg:show()
    end,
    function()
      assert(sizes.left and sizes.right, "a part got no room")
      assert(math.abs(share() - 0.5) < 0.02, "the left part has " .. share())
      dlg:close()
    end,
  }

  local step = 0
  return function()
    step = step + 1
    steps[step]()
    return step == #steps
  end
end)
