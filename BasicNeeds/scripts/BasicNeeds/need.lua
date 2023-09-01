-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/need.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local core = require("openmw.core")
local ui = require("openmw.ui")
local util = require("openmw.util")

local hud = require("scripts.BasicNeeds.hud")

local Actor = require("openmw.types").Actor
local L = core.l10n("BasicNeeds")

local Need = {}
Need.__index = Need

local STATE = {
   Init     = 0,
   None     = 1,
   Mild     = 2,
   Moderate = 3,
   Severe   = 4,
   Critical = 5,
   Death    = 6,
}

function Need.create(key, actor, value)
   local self = setmetatable({}, Need)
   self._enabled = true
   self._actor = actor
   self._value = value
   self._maxValue = 1000
   self._widget = hud[key]
   self._effects = {
      [STATE.Mild]     = "jz_mild_" .. key,
      [STATE.Moderate] = "jz_moderate_" .. key,
      [STATE.Severe]   = "jz_severe_" .. key,
      [STATE.Critical] = "jz_critical_" .. key,
   }
   self._messages = {
      increase = {
         [STATE.Mild]     = L(key .. "IncreaseMild"),
         [STATE.Moderate] = L(key .. "IncreaseModerate"),
         [STATE.Severe]   = L(key .. "IncreaseSevere"),
         [STATE.Critical] = L(key .. "IncreaseCritical"),
         [STATE.Death]    = L(key .. "IncreaseDeath"),
      },
      decrease = {
         [STATE.None]     = L(key .. "DecreaseNone"),
         [STATE.Mild]     = L(key .. "DecreaseMild"),
         [STATE.Moderate] = L(key .. "DecreaseModerate"),
         [STATE.Severe]   = L(key .. "DecreaseSevere"),
         [STATE.Critical] = L(key .. "DecreaseCritical"),
      }
   }
   self:_updateEffects(STATE.Init)
   return self
end

function Need:value()
   return self._value
end

function Need:status()
   return 1 + math.floor(self._value / 200)
end

function Need:isEnabled()
   return self._enabled
end

function Need:setEnabled(enabled)
   -- If setting to disabled, reset need
   if (self._enabled and not enabled) then
      self._value = 0
      self:_updateEffects(STATE.Init)
   end
   self._enabled = enabled
end

function Need:setMaxValue(maxValue)
   self._maxValue = maxValue
end

function Need:mod(change)
   if (not self._enabled or change == 0) then return end

   local prevStatus = self:status()
   self._value = util.clamp(self._value + change, 0, self._maxValue)
   if (change < 0) then
      self:_decreaseMessage()
   end
   self:_updateEffects(prevStatus)
end

function Need:_updateEffects(prevStatus)
   local status = self:status()
   if (status == prevStatus) then return end

   for _, effect in pairs(self._effects) do
      Actor.spells(self._actor):remove(effect)
   end
   self._widget:update(status)

   if (status == STATE.None) then return end

   if (status > prevStatus and prevStatus ~= STATE.Init) then
      self:_increaseMessage()
   end
   if (status == STATE.Death) then
      local health = Actor.stats.dynamic.health(self._actor)
      health.current = -1000
   else
      Actor.spells(self._actor):add(self._effects[status])
   end
end

function Need:_increaseMessage()
   ui.showMessage(self._messages.increase[self:status()])
end

function Need:_decreaseMessage()
   ui.showMessage(self._messages.decrease[self:status()])
end

return {
   STATE = STATE,
   create = Need.create,
}
