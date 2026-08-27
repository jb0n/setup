-- ctrl-click acts as cmd-click in browsers (opens link in new tab).
-- done with an event tap so no tool ever grabs the physical mouse.
-- requires (by hand, System Settings > Privacy & Security):
--   Accessibility   - to post the rewritten click
--   Input Monitoring - to observe the click before the browser sees it

local eventtap = hs.eventtap
local event = eventtap.event

require("hs.ipc")

local BROWSER_PATTERNS = {
  "^com%.apple%.Safari",
  "^com%.google%.Chrome",
  "^org%.chromium%.Chromium$",
  "^org%.mozilla%.firefox",
  "^org%.mozilla%.nightly",
  "^com%.microsoft%.edgemac",
  "^com%.brave%.Browser",
  "^com%.operasoftware%.",
  "^com%.vivaldi%.Vivaldi$",
  "^company%.thebrowser%.",
  "^app%.zen%-browser%.zen$",
  "^com%.kagi%.kagimacOS$",
}

local ctrlClickActive = false

local function frontmostIsBrowser()
  local app = hs.application.frontmostApplication()
  if not app then return false end
  local id = app:bundleID()
  if not id then return false end
  for _, pattern in ipairs(BROWSER_PATTERNS) do
    if string.match(id, pattern) then return true end
  end
  return false
end

local function toCmdClick(e)
  local flags = e:getFlags()
  flags.ctrl = false
  flags.cmd = true
  e:setFlags(flags)
  return true, { e }
end

ctrlClickTap = eventtap.new(
  { event.types.leftMouseDown, event.types.leftMouseUp, event.types.leftMouseDragged },
  function(e)
    local t = e:getType()
    if t == event.types.leftMouseDown then
      local flags = e:getFlags()
      if flags.ctrl and not flags.cmd and frontmostIsBrowser() then
        ctrlClickActive = true
        return toCmdClick(e)
      end
    elseif t == event.types.leftMouseUp then
      if ctrlClickActive then
        ctrlClickActive = false
        return toCmdClick(e)
      end
    elseif ctrlClickActive then
      return toCmdClick(e)
    end
    return false
  end
)

ctrlClickTap:start()

print("ctrl-click acts as cmd-click in browsers")
