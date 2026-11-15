-- A side panel wider than the window allows takes at most 60 % of the
-- window's width, so the tab keeps the rest

ui_test(function()
  local plain = Dialog{ title="Plain", tab=true }
  plain:label{ text="No panel" }

  local dlg = Dialog{ title="Wide", tab=true }
  dlg:label{ text="Main" }
  dlg:panel{ id="side_panel_share_test", width=5000 }
  dlg:label{ text="Panel" }

  local none
  local steps = {
    function()
      plain:show()
    end,
    function()
      none = plain.bounds
      dlg:show()
    end,
    function()
      local rc = dlg.bounds
      local window = app.window.width
      local panel = rc.x - none.x
      -- The splitter beside the panel adds a few pixels
      assert(panel <= window * 0.6 + 8 * app.uiScale, "the panel is " .. panel .. " of " .. window .. " px")
      assert(rc.width >= none.width - window * 0.6 - 8 * app.uiScale, "the tab is " .. rc.width .. " px wide")
      dlg:close()
      plain:close()
    end,
  }

  local step = 0
  return function()
    step = step + 1
    steps[step]()
    return step == #steps
  end
end)
