-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/waterskin_constants.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local refillMap = {
   jz_waterskin_empty = "jz_waterskin_full",
}

local useMap = {
   jz_waterskin_full = "jz_waterskin_23",
   jz_waterskin_23   = "jz_waterskin_13",
   jz_waterskin_13   = "jz_waterskin_empty",
}

return {
   refillMap = refillMap,
   useMap = useMap,
}
