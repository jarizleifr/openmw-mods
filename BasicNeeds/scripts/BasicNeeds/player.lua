-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/player.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local math = require("math")
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local time = require("openmw_aux.time")

local consumables = require("scripts.BasicNeeds.consumables")
local hud = require("scripts.BasicNeeds.hud")
local settings = require("scripts.BasicNeeds.settings")

local L = core.l10n("BasicNeeds")

-- -----------------------------------------------------------------------------
-- Constants
-- -----------------------------------------------------------------------------
local INIT = 0
local NONE = 1
local MILD = 2
local MODERATE = 3
local SEVERE = 4
local CRITICAL = 5
local DEATH = 6

local UPDATE_INTERVAL = time.second * 10

-- -----------------------------------------------------------------------------
-- Script state
-- -----------------------------------------------------------------------------
local function createState(key, value)
   return {
      value = value,
      widget = hud[key],
      effects = {
         [MILD]     = "jz_mild_" .. key,
         [MODERATE] = "jz_moderate_" .. key,
         [SEVERE]   = "jz_severe_" .. key,
         [CRITICAL] = "jz_critical_" .. key,
      },
      messages = {
         increase = {
            [MILD]     = L(key .. "IncreaseMild"),
            [MODERATE] = L(key .. "IncreaseModerate"),
            [SEVERE]   = L(key .. "IncreaseSevere"),
            [CRITICAL] = L(key .. "IncreaseCritical"),
            [DEATH]    = L(key .. "IncreaseDeath"),
         },
         decrease = {
            [NONE]     = L(key .. "DecreaseNone"),
            [MILD]     = L(key .. "DecreaseMild"),
            [MODERATE] = L(key .. "DecreaseModerate"),
            [SEVERE]   = L(key .. "DecreaseSevere"),
            [CRITICAL] = L(key .. "DecreaseCritical"),
         }
      },
   }
end

local thirst = createState("thirst", 0)
local hunger = createState("hunger", 0)
local exhaustion = createState("exhaustion", 0)

local previousTime = nil
local previousCell = nil

local maxValue = nil
local thirstRate = nil
local hungerRate = nil
local exhaustionRate = nil
local exhaustionRecoveryRate = nil

local function getStatus(value)
   return 1 + math.floor(value / 200)
end

local function updateEffects(prevStatus, need)
   local status = getStatus(need.value)
   if (status ~= prevStatus) then
      for _, effect in pairs(need.effects) do
         types.Actor.spells(self):remove(effect)
      end
      if (status == DEATH) then
         local health = types.Actor.stats.dynamic.health(self)
         health.current = 0
      elseif (status > NONE) then
         if (status > prevStatus and prevStatus ~= INIT) then
            ui.showMessage(need.messages.increase[status])
         end
         types.Actor.spells(self):add(need.effects[status])
      end
      need.widget.layout.props.textColor = hud.colors[status]
      need.widget:update()
   end
end

local function updateNeed(need, change)
   if (change == 0) then return end

   local prevStatus = getStatus(need.value)
   if (change < 0) then
      need.value = math.max(0, need.value + change)
      -- Show message on all value decrements to keep track where we are
      ui.showMessage(need.messages.decrease[getStatus(need.value)])
   else
      need.value = math.min(maxValue, need.value + change)
   end
   updateEffects(prevStatus, need)
end

local function updateNeeds()
   local nextTime = core.getGameTime()
   local passedTime = nextTime - previousTime

   updateNeed(thirst, thirstRate * passedTime)
   updateNeed(hunger, hungerRate * passedTime)

   local currentCell = self.object.cell
   if (passedTime >= time.hour and previousCell == currentCell) then
      updateNeed(exhaustion, exhaustionRecoveryRate * passedTime)
   else
      updateNeed(exhaustion, exhaustionRate * passedTime)
   end

   previousTime = nextTime
   previousCell = currentCell
end

-- -----------------------------------------------------------------------------
-- Initialization
-- -----------------------------------------------------------------------------
local function loadSettings()
   -- If death is disabled, simply limit values to 999
   maxValue = settings:get("EnableDeath") and 1000 or 999
   -- All rates are configured as per hour values, so we first convert them to
   -- per second values
   thirstRate = settings:get("ThirstRate") / time.hour
   hungerRate = settings:get("HungerRate") / time.hour
   exhaustionRate = settings:get("ExhaustionRate") / time.hour
   exhaustionRecoveryRate = -(settings:get("ExhaustionRecoveryRate") / time.hour)
end

local function initialize(startTime)
   previousTime = startTime
   previousCell = self.object.cell
   loadSettings()
   -- Force update effects on initialize
   updateEffects(INIT, thirst)
   updateEffects(INIT, hunger)
   updateEffects(INIT, exhaustion)
end

initialize(core.getGameTime())
settings:subscribe(async:callback(loadSettings))
time.runRepeatedly(updateNeeds, UPDATE_INTERVAL, { type = time.GameTime })

-- -----------------------------------------------------------------------------
-- Engine handlers
-- -----------------------------------------------------------------------------
local function onLoad(data)
   thirst = createState("thirst", data.thirst)
   hunger = createState("hunger", data.hunger)
   exhaustion = createState("exhaustion", data.exhaustion)
   initialize(data.previousTime)
   ui.updateAll()
end

local function onSave()
   return {
      thirst = thirst.value,
      hunger = hunger.value,
      exhaustion = exhaustion.value,
      previousTime = previousTime,
   }
end

local function onConsume(item)
   local Ingredient = types.Ingredient
   local Potion = types.Potion

   local id =
       (Ingredient.objectIsInstance(item) and Ingredient.record(item).id) or
       (Potion.objectIsInstance(item) and Potion.record(item).id)

   local consumable = consumables[id]
   if (consumable) then
      updateNeed(thirst, consumable[1])
      updateNeed(hunger, consumable[2])
      updateNeed(exhaustion, consumable[3])
   end
end

return {
   engineHandlers = {
      onLoad = onLoad,
      onSave = onSave,
      onConsume = onConsume,
   }
}
