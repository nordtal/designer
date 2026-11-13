-- A tree paints each badge right after its node's text, so the text
-- shows whole: in a tree with a width a short node shows its badge
-- while a long node's badge lies past what the tree shows, and a short
-- node has its badge near its start however wide the tree is

ui_test(function()
  local scale = app.uiScale
  local face = app.theme.color.listitem_selected_face

  local function near(a, b) return math.abs(a - b) <= 4 end

  -- Bounds of the badge pixels a screenshot holds inside the dialog.
  -- The screenshot is converted to sRGB, which rounds the colors.
  local function badge(dlg)
    app.command.Screenshot()
    local img = app.image
    local b = dlg.bounds
    local x1, y1, x2, y2
    for y = b.y, b.y + b.height - 1 do
      for x = b.x, b.x + b.width - 1 do
        local c = img:getPixel(x, y)
        if near(app.pixelColor.rgbaR(c), face.red) and
           near(app.pixelColor.rgbaG(c), face.green) and
           near(app.pixelColor.rgbaB(c), face.blue) then
          x1 = math.min(x1 or x, x)
          y1 = math.min(y1 or y, y)
          x2 = math.max(x2 or x, x)
          y2 = math.max(y2 or y, y)
        end
      end
    end
    app.command.CloseFile{ ui=false }
    return x1 and Rectangle(x1, y1, x2 - x1 + 1, y2 - y1 + 1)
  end

  local function tree(title, width, texts)
    local nodes = {}
    for i, text in ipairs(texts) do nodes[i] = { id="node" .. i, text=text, badge="7" } end
    local dlg = Dialog(title)
    dlg:tree{ id="files", width=width, nodes=nodes }
    dlg:show{ wait=false }
    -- In a corner, away from the dialogs the app shows at its start
    local b = dlg.bounds
    dlg.bounds = Rectangle(8, 40, b.width, b.height)
    return dlg
  end

  local fixed, short
  local ticks = 0
  return function()
    ticks = ticks + 1
    -- The dialogs are painted before the screenshot
    if ticks == 1 then
      fixed = tree("Tree badge", 100, { "a", string.rep("a node with a long name ", 20) })
      return false
    end
    if ticks == 3 then
      -- The short node's badge shows right after it; the long text
      -- fills the 100 px the tree shows, and its badge lies past it, so
      -- the only badge pixels are those of the first row
      local b = fixed.bounds
      local rc = badge(fixed)
      assert(rc, "no badge in a tree with a width")
      assert(rc.x + rc.width <= b.x + b.width, "the badge ends at " .. rc.x + rc.width)
      assert(rc.x < b.x + 50 * scale, "the badge starts at " .. rc.x - b.x .. " px")
      assert(rc.height < 20 * scale, "badge pixels in " .. rc.height .. " px of rows")
      fixed:close()
      short = tree("A tree badge right after a short node", nil, { "a" })
      return false
    end
    if ticks == 5 then
      local b = short.bounds
      local rc = badge(short)
      assert(rc, "no badge after a short node")
      -- The title makes the dialog wide, and the badge stays at the node
      assert(b.width > 150 * scale, "the dialog is " .. b.width .. " px wide")
      assert(rc.x < b.x + 50 * scale, "the badge starts at " .. rc.x - b.x .. " px")
      short:close()
      return true
    end
    return false
  end
end)
