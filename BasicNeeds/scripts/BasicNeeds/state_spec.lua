-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/state_spec.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local fn = function(ret) return function() return ret end end
local core = { l10n = fn(function(s) return s end) }
local self = 0
local spells = { add = fn, remove = fn }
local time = { hour = 3600 }
local types = { Actor = { spells = fn(spells) } }
local ui = { showMessage = fn() }

package.loaded["openmw.core"] = core
package.loaded["openmw.self"] = self
package.loaded["openmw.types"] = types
package.loaded["openmw.ui"] = ui
package.loaded["openmw_aux.time"] = time

local mockNeed = { setEnabled = fn, setMaxValue = fn, mod = fn }
local Need = { create = fn(mockNeed) }

package.loaded["scripts.BasicNeeds.need"] = Need

local state = require("scripts.BasicNeeds.state")

local thirstRate = 40 / time.hour
local hungerRate = 30 / time.hour
local exhaustionRate = 25 / time.hour
local exhaustionRecoveryRate = 50 / time.hour

local settings = {
   enableThirst = true,
   enableHunger = true,
   enableExhaustion = true,
   maxValue = 1000,
   thirstRate = thirstRate,
   hungerRate = hungerRate,
   exhaustionRate = exhaustionRate,
   exhaustionRecoveryRate = exhaustionRecoveryRate,
}

local values = {
   previousTime = 0,
   previousCell = 0,
   wellRestedTime = 0,
   thirst = mockNeed,
   hunger = mockNeed,
   exhaustion = mockNeed,
}

describe("state.lua", function()
   local s

   before_each(function()
      spy.on(ui, "showMessage")
      spy.on(mockNeed, "mod")
      spy.on(state, "setSettings")
      spy.on(spells, "add")
      spy.on(spells, "remove")
      s = state.new(values, settings)
   end)

   after_each(function()
      ui.showMessage:clear()
      mockNeed.mod:clear()
      state.setSettings:clear()
      spells.add:clear()
      spells.remove:clear()
   end)

   describe("new", function()
      it("sets values", function()
         local are = assert.are
         are.equal(values.previousTime, s._previousTime)
         are.equal(values.previousCell, s._previousCell)
         are.equal(values.wellRestedTime, s._wellRestedTime)
         are.equal(false, s._sleepingInBed)
         are.equal(values.thirst, s.thirst)
         are.equal(values.hunger, s.hunger)
         are.equal(values.exhaustion, s.exhaustion)
         assert.spy(state.setSettings).was_called()
      end)
   end)

   describe("setSettings", function()
      it("sets settings", function()
         local are = assert.are
         are.equal(settings.thirstRate, s._thirstRate)
         are.equal(settings.hungerRate, s._hungerRate)
         are.equal(settings.exhaustionRate, s._exhaustionRate)
         are.equal(settings.exhaustionRecoveryRate, s._exhaustionRecoveryRate)
      end)

      it("removes well rested if exhaustion disabled", function()
         local spellsRemove = assert.spy(spells.remove)
         local localSettings = {}
         for k, v in pairs(settings) do localSettings[k] = v end
         localSettings.enableExhaustion = false
         s:setSettings(localSettings)
         spellsRemove.was_called_with(spells, "jz_well_rested")
      end)
   end)

   describe("update, when passedTime < hour", function()
      it("modifies needs", function()
         local mod = assert.spy(mockNeed.mod)
         s:update(1, values.previousCell)
         mod.was_called_with(mockNeed, thirstRate)
         mod.was_called_with(mockNeed, hungerRate)
         mod.was_called_with(mockNeed, exhaustionRate)
      end)
   end)

   describe("update, when passedTime >= hour", function()
      it("handles wait/rest, when cell not changed", function()
         local mod = assert.spy(mockNeed.mod)
         s:update(time.hour, values.previousCell)
         mod.was_called_with(mockNeed, thirstRate * time.hour)
         mod.was_called_with(mockNeed, hungerRate * time.hour)
         mod.was_called_with(mockNeed, exhaustionRecoveryRate * time.hour * 0.5)
      end)

      it("handles rest in bed, when cell not changed and slept in bed", function()
         local mod = assert.spy(mockNeed.mod)
         s._sleepingInBed = true
         s:update(time.hour, values.previousCell)
         mod.was_called_with(mockNeed, thirstRate * time.hour)
         mod.was_called_with(mockNeed, hungerRate * time.hour)
         mod.was_called_with(mockNeed, exhaustionRecoveryRate * time.hour)
         assert.are.equal(false, s._sleepingInBed)
      end)

      it("handles fast travel, when cell changed", function()
         local mod = assert.spy(mockNeed.mod)
         local otherCell = 1
         local travelMult = state._fastTravelMult(time.hour) * time.hour
         s:update(time.hour, otherCell)
         mod.was_called_with(mockNeed, thirstRate * travelMult)
         mod.was_called_with(mockNeed, hungerRate * travelMult)
         mod.was_called_with(mockNeed, exhaustionRate * travelMult)
      end)

      it("sets well rested when slept in bed for >= 7 hours", function()
         local spellsAdd = assert.spy(spells.add)
         local nextTime = time.hour * 7
         s._sleepingInBed = true
         s:update(nextTime, values.previousCell)
         spellsAdd.was_called_with(spells, "jz_well_rested")
         assert.spy(ui.showMessage).was_called_with("exhaustionGainWellRested")
         assert.are.equal(nextTime, s._wellRestedTime)
      end)

      it("removes well rested when >= 8 hours from last long rest", function()
         local spellsRemove = assert.spy(spells.remove)
         local nextTime = time.hour * 7
         s._sleepingInBed = true
         s:update(nextTime, values.previousCell)
         nextTime = nextTime + time.hour * 8
         s:update(nextTime, values.previousCell)
         spellsRemove.was_called_with(spells, "jz_well_rested")
         assert.spy(ui.showMessage).was_called_with("exhaustionLoseWellRested")
         assert.are.equal(nil, s._wellRestedTime)
      end)
   end)
end)
