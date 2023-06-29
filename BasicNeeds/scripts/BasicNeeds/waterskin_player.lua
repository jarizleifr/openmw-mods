-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/waterskin_player.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
--
-- @see waterskin_constants.lua
-- @see waterskin_global.lua
-- -----------------------------------------------------------------------------
local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")

local constants = require("scripts.BasicNeeds.waterskin_constants")

local L = core.l10n("BasicNeeds")

local function onConsume(item)
   if (not types.Potion.objectIsInstance(item)) then return end

   local itemId = types.Potion.record(item).id

   local refilledItemId = constants.refillMap[itemId]
   if (refilledItemId) then
      local isSwimming = types.Actor.isSwimming(self)
      core.sendGlobalEvent("PlayerReturnItem", {
         player = self,
         returnItem = isSwimming and refilledItemId or itemId
      })
      if (isSwimming) then
         ui.showMessage(L("waterskinRefilled"))
      else
         ui.showMessage(L("waterskinNotInWater"))
      end
   end

   local usedItemId = constants.useMap[itemId]
   if (usedItemId) then
      core.sendGlobalEvent("PlayerReturnItem", {
         player = self,
         returnItem = usedItemId,
      })
   end
end

return {
   engineHandlers = { onConsume = onConsume }
}
