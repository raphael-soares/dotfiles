local dir = os.getenv("HOME") .. "/.config/hypr-machine"
local path = dir .. "/machine.lua"

local f = io.open(path, "r")
if not f then
  return {}
end
f:close()

package.path = dir .. "/?.lua;" .. package.path
return dofile(path)
