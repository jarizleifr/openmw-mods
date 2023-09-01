-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/need_spec.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local fn = function(ret) return function() return ret end end
local core = { l10n = fn(function(s) return s end) }
local spells = { add = fn, remove = fn }
local stats = { dynamic = { health = fn({ current = 0 }) } }
local types = { Actor = { spells = fn(spells), stats = stats } }
local ui = { showMessage = fn() }
local util = { clamp = function(v) return v end }
local hud = { thirst = { update = fn() } }

package.loaded["openmw.core"] = core
package.loaded["openmw.self"] = 0
package.loaded["openmw.types"] = types
package.loaded["openmw.ui"] = ui
package.loaded["openmw.util"] = util
package.loaded["scripts.BasicNeeds.hud"] = hud

local Need = require("scripts.BasicNeeds.need")
local STATE = Need.STATE

describe("Need", function()
   spy.on(ui, "showMessage")
   local thirst = Need.create("thirst", 0)

   after_each(function()
      thirst._enabled = true
      thirst._value = 0
      thirst._maxValue = 1000
      ui.showMessage:clear()
   end)

   it(":create updates effects on init", function()
      spy.on(types.Actor, "spells")
      spy.on(spells, "remove")
      spy.on(spells, "add")
      Need.create("thirst", 500)
      assert.spy(spells.remove).was_called_with(spells, "jz_mild_thirst")
      assert.spy(spells.remove).was_called_with(spells, "jz_moderate_thirst")
      assert.spy(spells.remove).was_called_with(spells, "jz_severe_thirst")
      assert.spy(spells.remove).was_called_with(spells, "jz_critical_thirst")

      assert.spy(spells.add).was_called_with(spells, "jz_moderate_thirst")

      assert.spy(spells.add).was_not_called_with(spells, "jz_mild_thirst")
      assert.spy(spells.add).was_not_called_with(spells, "jz_severe_thirst")
      assert.spy(spells.add).was_not_called_with(spells, "jz_critical_thirst")
   end)

   it(":create doesn't show message on effect update", function()
      Need.create("thirst", 500)
      assert.spy(ui.showMessage).was_not_called()
   end)

   it(":status gets correct status", function()
      thirst._value = 0
      assert.are.equal(STATE.None, thirst:status())
      thirst._value = 200
      assert.are.equal(STATE.Mild, thirst:status())
      thirst._value = 400
      assert.are.equal(STATE.Moderate, thirst:status())
      thirst._value = 600
      assert.are.equal(STATE.Severe, thirst:status())
      thirst._value = 800
      assert.are.equal(STATE.Critical, thirst:status())
   end)

   describe(":mod,", function()
      describe("when need enabled,", function()
         it("clamps value between 0 and maxValue", function()
            spy.on(util, "clamp")
            thirst:mod(-100)
            assert.spy(util.clamp).was_called_with(-100, 0, 1000)
            thirst._value = 0

            thirst:setMaxValue(999)
            thirst:mod(500)
            assert.spy(util.clamp).was_called_with(500, 0, 999)
         end)

         it("shows decrease message on negative change", function()
            thirst._value = 500
            thirst:mod(-10)
            assert.spy(ui.showMessage).was_called_with("thirstDecreaseModerate")
         end)

         it("kills player on STATE.Death", function()
            local health = types.Actor.stats.dynamic.health()
            thirst._value = 0
            thirst:mod(1000)
            assert.are.equal(STATE.Death, thirst:status())
            assert.spy(ui.showMessage).was_called_with("thirstIncreaseDeath")
            assert.are.equal(-1000, health.current)
         end)
      end)

      describe("when need disabled,", function()
         it("is no-op", function()
            thirst._enabled = false
            thirst:mod(500)
            assert.are.equal(0, thirst._value)
            assert.are.equal(STATE.None, thirst:status())
            assert.spy(ui.showMessage).was_not_called()
         end)
      end)
   end)
end)
