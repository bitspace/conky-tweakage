local theme = {}

theme.palette = {
  text = { r = 255, g = 255, b = 255, a = 0.9 },
  panel = { r = 0, g = 0, b = 0, a = 0.12 },
}

theme.fonts = {
  primary = "Inter",
  fallback = "DejaVu Sans",
}

function theme.draw_panel(cr, w, h)
  if not cr then
    return
  end
  local radius = 16
  local margin = 12
  local r = theme.palette.panel

  cr:save()
  cr:set_source_rgba(r.r / 255, r.g / 255, r.b / 255, r.a)
  cr:rounded_rectangle(margin, margin, w - margin * 2, h - margin * 2, radius)
  cr:fill()
  cr:restore()
end

return theme
