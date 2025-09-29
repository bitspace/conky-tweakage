local util = {}

function util.draw_panel_hook()
  -- Stub panel function; real implementation will use cairo once widgets land.
  return function() end
end

function util.wrap_widget(content)
  return content or ""
end

return util
