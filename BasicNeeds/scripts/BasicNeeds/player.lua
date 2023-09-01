-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/player.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local async = require("openmw.async")
local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local ui = require("openmw.ui")
local types = require("openmw.types")
local time = require("openmw_aux.time")

local bed = require("scripts.BasicNeeds.bed")
local settings = require("scripts.BasicNeeds.settings")
local need = require("scripts.BasicNeeds.need")

local ACTION = input.ACTION
local L = core.l10n("BasicNeeds")

local Actor = types.Actor

-- -----------------------------------------------------------------------------
-- Script state
-- -----------------------------------------------------------------------------
local UPDATE_INTERVAL = time.second * 10

local thirst = need.create("thirst", self, 0)
local hunger = need.create("hunger", self, 0)
local exhaustion = need.create("exhaustion", self, 0)

local previousTime = core.getGameTime()
local previousCell = self.object.cell

local wellRestedTime = nil
local sleepingInBed = false

local thirstRate = nil
local hungerRate = nil
local exhaustionRate = nil
local exhaustionRecoveryRate = nil

local function rested(currentCell, passedTime, nextTime)
   if (not exhaustion:isEnabled()) then return false end
   if (passedTime >= time.hour and previousCell == currentCell) then
      local restMult = (sleepingInBed and 1.0 or 0.5)
      if (sleepingInBed and passedTime >= time.hour * 7) then
         -- Add Well Rested if rested at least 7 hours in bed
         wellRestedTime = nextTime
         Actor.spells(self):add("jz_well_rested")
         ui.showMessage(L("exhaustionGainWellRested"))
      end
      exhaustion:mod(exhaustionRecoveryRate * restMult * passedTime)
      return true
   end

   -- Remove Well Rested if 8 hours have passed
   if (wellRestedTime and nextTime - wellRestedTime >= time.hour * 8) then
      -- TODO: Once we can cast regular spells on Actors with Lua, this cleanup
      -- can be removed, as then Well Rested would just expire on its own
      Actor.spells(self):remove("jz_well_rested")
      ui.showMessage(L("exhaustionLoseWellRested"))
      wellRestedTime = nil
   end
   return false
end

local function updateNeeds()
   local nextTime = core.getGameTime()
   local passedTime = nextTime - previousTime
   local currentCell = self.object.cell

   thirst:mod(thirstRate * passedTime)
   hunger:mod(hungerRate * passedTime)
   if (not rested(currentCell, passedTime, nextTime)) then
      exhaustion:mod(exhaustionRate * passedTime)
   end

   previousTime = nextTime
   previousCell = currentCell
   sleepingInBed = false
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local function loadSettings()
   local values = settings.getValues(settings.group)
   thirst:setEnabled(values.enableThirst)
   hunger:setEnabled(values.enableHunger)
   exhaustion:setEnabled(values.enableExhaustion)
   if (not values.enableExhaustion) then
      -- TODO: Once we can cast regular spells on Actors with Lua, this cleanup
      -- can be removed, as then Well Rested would just expire on its own
      Actor.spells(self):remove("jz_well_rested")
   end

   thirst:setMaxValue(values.maxValue)
   hunger:setMaxValue(values.maxValue)
   exhaustion:setMaxValue(values.maxValue)

   thirstRate = values.thirstRate
   hungerRate = values.hungerRate
   exhaustionRate = values.exhaustionRate
   exhaustionRecoveryRate = values.exhaustionRecoveryRate
end

loadSettings()
settings.group:subscribe(async:callback(loadSettings))
time.runRepeatedly(updateNeeds, UPDATE_INTERVAL, { type = time.GameTime })

-- -----------------------------------------------------------------------------
-- Engine/event handlers
-- -----------------------------------------------------------------------------
local function onLoad(data)
   previousTime = data.previousTime
   previousCell = self.object.cell
   wellRestedTime = data.wellRestedTime
   thirst = need.create("thirst", self, data.thirst)
   hunger = need.create("hunger", self, data.hunger)
   exhaustion = need.create("exhaustion", self, data.exhaustion)
   loadSettings()
   ui.updateAll()
   -- FIXME: For some reason, on loading game, dynamically created potions are
   -- left in some limbo state where they can be used, but don't result in
   -- correct 'onConsume' events. By running `getAll()` on player inventory,
   -- the potions get normalized. Made issue #7448 about this.
   Actor.inventory(self):getAll()
end

local function onSave()
   return {
      thirst = thirst:value(),
      hunger = hunger:value(),
      exhaustion = exhaustion:value(),
      previousTime = previousTime,
      wellRestedTime = wellRestedTime,
   }
end

local function onConsume(item)
   core.sendGlobalEvent("PlayerConsumeItem", {
      player = self,
      item = item,
   })
end

local function onInputAction(action)
   if (core.isWorldPaused()) then return end
   -- TODO: Using Sneak as hotkey is a workaround. Re-examine this if/when
   -- OpenMW Lua makes running on-use scripts on miscellaneous items possible
   if (thirst:isEnabled() and action == ACTION.Sneak and Actor.isSwimming(self)) then
      core.sendGlobalEvent("PlayerFillContainer", {
         player = self,
      })
   end
   -- TODO: Hacky workaround for checking beds. Activation handlers on activators
   -- (i.e. beds) don't seem to do anything yet on OpenMW. Fix this when possible.
   if (exhaustion:isEnabled() and action == ACTION.Activate) then
      sleepingInBed = bed.tryFindBed(self)
   end
end

local function playerConsumedFood(eventData)
   thirst:mod(eventData.thirst)
   hunger:mod(eventData.hunger)
   exhaustion:mod(eventData.exhaustion)
end

local function playerFilledContainer(eventData)
   if (eventData.containerName) then
      ui.showMessage(L("filledContainer", { item = eventData.containerName }))
   else
      ui.showMessage(L("noContainers"))
   end
end

return {
   interfaceName = "BasicNeeds",
   interface = {
      version = 1,
      getThirstStatus = function()
         return thirst:status()
      end,
      getHungerStatus = function()
         return hunger:status()
      end,
      getExhaustionStatus = function()
         return exhaustion:status()
      end,
   },
   engineHandlers = {
      onLoad = onLoad,
      onSave = onSave,
      onConsume = onConsume,
      onInputAction = onInputAction,
   },
   eventHandlers = {
      PlayerConsumedFood = playerConsumedFood,
      PlayerFilledContainer = playerFilledContainer,
   },
}
