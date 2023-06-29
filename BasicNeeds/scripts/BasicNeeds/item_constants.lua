-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/item_constants.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local drinks = {
   -- Included in Basic Needs mod:
   jz_waterskin_full         = -150,
   jz_waterskin_23           = -150,
   jz_waterskin_13           = -150,
   -- Vanilla:
   p_vintagecomberrybrandy1  = -50,
   potion_ancient_brandy     = -50,
   potion_comberry_brandy_01 = -50,  -- Greef
   potion_comberry_wine_01   = -100, -- Shein
   potion_cyro_brandy_01     = -50,  -- Cyrodiilic Brandy
   potion_cyro_whiskey_01    = -50,  -- Flin
   potion_local_brew_01      = -100, -- Mazte
   potion_local_liquor_01    = -50,  -- Sujamma
   potion_skooma_01          = -50,
   -- Bloodmoon:
   potion_nord_mead          = -100,
}

local foods = {
   -- Vanilla:
   ingred_ash_yam_01            = -50,
   ingred_bread_01              = -100,
   ingred_comberry_01           = -50,
   ingred_crab_meat_01          = -150,
   ["ingred_hackle-lo_leaf_01"] = -100,
   ingred_hound_meat_01         = -150,
   food_kwama_egg_01            = -100,
   food_kwama_egg_02            = -150,
   ingred_marshmerrow_01        = -50,
   ingred_rat_meat_01           = -150,
   ingred_saltrice_01           = -50,
   ingred_scrib_jelly_01        = -100,
   ingred_scrib_jerky_01        = -150,
   ingred_scuttle_01            = -100,
   ingred_wickwheat_01          = -50,
   -- Tribunal:
   ingred_durzog_meat_01        = -150,
   ingred_scrib_cabbage_01      = -50,
   ingred_sweetpulp_01          = -50,
}

local stimulants = {
   -- Vanilla:
   ingred_moon_sugar_01         = -100,
   ["ingred_hackle-lo_leaf_01"] = -50,
   potion_skooma_01             = -150,
}

return {
   drinks = drinks,
   foods = foods,
   stimulants = stimulants,
}
