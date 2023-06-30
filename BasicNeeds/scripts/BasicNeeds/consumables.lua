-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/consumables.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
--
-- Loads consumables from the 'patches' folder and merges them with consumables
-- table, depending on what content files the user currently has loaded.
-- -----------------------------------------------------------------------------
local core = require("openmw.core")
local types = require("openmw.types")

local PATCHES_PATH = "scripts.BasicNeeds.patches."

-- When creating a patch, add the corresponding .esm/.esp/.omwaddon file here
local AVAILABLE_PATCHES = {
   "morrowind.esm",
   "tribunal.esm",
   "bloodmoon.esm",
   "tamriel_data.esm",
   "oaab_data.esm",
}

local consumables = {
   -- Added by Basic Needs mod
   ["jz_waterskin_full"] = { -150, 0, 0 },
   ["jz_waterskin_23"]   = { -150, 0, 0 },
   ["jz_waterskin_13"]   = { -150, 0, 0 },
}

-- This is inefficient, but useful for debugging
local function checkItem(id)
   for _, ingred in ipairs(types.Ingredient.records) do
      if (ingred.id == id) then return true end
   end
   for _, potion in ipairs(types.Potion.records) do
      if (potion.id == id) then return true end
   end
   return false
end

for _, pkg in ipairs(AVAILABLE_PATCHES) do
   if (core.contentFiles.has(pkg)) then
      print("Applying patch for '" .. pkg .. "'.")
      local filename = pkg:gsub("%..+", "")
      local data = require(PATCHES_PATH .. filename)
      for id, values in pairs(data) do
         -- TODO: Make an 'EnableDebugging' option in Settings
         -- Remove this 'true' to enable item debug check
         if (true or checkItem(id)) then
            consumables[id] = values
         else
            print("Warning: Record for consumable '" ..id.. "' in patch '" ..filename.. "' doesn't exist in content files")
         end
      end
   end
end

return consumables
