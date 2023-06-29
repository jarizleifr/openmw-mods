-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/waterskin_global.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
--
-- Because PLAYER scripts are local, they cannot create new items to the world.
-- As such, we need a GLOBAL script which re-adds water containers to the
-- player's inventory after use or refill.
--
-- @see waterskin_player.lua
-- -----------------------------------------------------------------------------
local Actor = require("openmw.types").Actor
local world = require("openmw.world")

local function playerReturnItem(data)
   local playerInventory = Actor.inventory(data.player)
   world.createObject(data.returnItem, 1):moveInto(playerInventory)
end

return {
   eventHandlers = { PlayerReturnItem = playerReturnItem },
}
