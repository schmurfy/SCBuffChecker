

local CreateFrame = CreateFrame
local table = table
local GetSpellInfo = GetSpellInfo


local required_buffs = {}
local available_casters = {}

local function exist(what, t)
  for _, v in pairs(t) do
    if( v == what ) then
      return true
    end
  end
  
  return false
end

local function registerBuff(class, spell_id1, ...)
  local name, _, icon, _, _, _, _, _, _ = GetSpellInfo(spell_id1)
  local obj = {
    class = class,
    names = {[0] = name},
    texture = icon,
    button = nil
  }
  
  local argn = select("#", ...)
  for i= 1, argn do
    local tmp = select(i, ...)
    local name, _, icon, _, _, _, _, _, _ = GetSpellInfo(tmp)
    if( not exist(name, obj['names']) ) then
      table.insert(obj['names'], name)
    end
  end
  
  table.insert(required_buffs, obj)
end


local function classAvailable(class_name)
  for _, class in pairs(available_casters) do
    if( class_name == class ) then
      return true
    end
  end
  
  return false
end

local _, player_class = UnitClass('player')


registerBuff('DRUID',    1126,  5232,  6756,  5234,  8907,  9884, 26990, 48469)                 -- Mark of the Wild
registerBuff('MAGE',     1459,  1460,  1461, 10156, 10157, 27126, 42995,                        -- Arcane Intellect
                        23028, 27127, 43002)                                                    -- Arcane Brilliance
registerBuff('PALADIN', 19740, 19834, 19835, 19836, 19837, 19838, 25291, 27140, 48931, 48932,   -- Blessing of Might
                        25782, 25916, 27141, 48933, 48934)                                      -- Greater Blessing of Might
registerBuff('PALADIN', 20217,                                                                  -- Blessing of Kings
                        25898)                                                                  -- Greater Blessing of Kings


-- first create our frame
local frame = CreateFrame('Frame', nil, UIParent)

-- register events we need
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:RegisterEvent('UNIT_AURA')
frame:RegisterEvent('PARTY_MEMBERS_CHANGED')
frame:RegisterEvent('RAID_ROSTER_UPDATE')

frame:SetPoint('TOPLEFT', 40, -40 )
frame:SetWidth(300)
frame:SetHeight(64 + 4)

-- frame:SetBackdrop({
--     edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
--     edgeSize = 1
--     -- insets = { top = -1, bottom = -1, left = -1, right = -1 }
--   }
-- )

frame:Show()

local MARGIN = 4
local ICON_SIZE = 32


local function createAurasIcons()  
  -- create each icon  
  for index, aura_data in pairs(required_buffs) do
    -- print(aura_data["name"] .. " => " .. aura_data["texture"])
    local button = CreateFrame('button', nil, frame)
    -- Set Aura position
    button:SetPoint('TOPLEFT', MARGIN*(index) + ICON_SIZE*(index-1), 0)
    button:SetWidth(ICON_SIZE)
    button:SetHeight(ICON_SIZE)
    
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetTexCoord(.06, .94, .06, .94)
    -- button.icon:SetTexCoord(0, 1, 0, 1)
    button.icon:SetDrawLayer('ARTWORK')
    button.icon:SetTexture(aura_data["texture"])
    button.icon:SetAllPoints()
    button.icon:Show()
    
    button.frame = frame
    button.index = index
    
    button:SetBackdrop({
        bgFile = [[Interface\ChatFrame\ChatFrameBackground]], 
        insets = { top = -1, bottom = -1, left = -1, right = -1 }
      }
    )

    button:SetBackdropColor(1, 0, 0)
    
    button:Show()
    
    aura_data['button'] = button
  end
end

local function updateAuraIcons()
  for _, aura_data in pairs(required_buffs) do    
    for _, aura_name in pairs(aura_data['names']) do
      local name  = select(1, UnitBuff('player', aura_name))
      if( name ~= nil ) then
        -- buff is on me
        aura_data['button']:SetBackdropColor(0, 1, 0)
        aura_data['button']:SetAlpha(1)
        break
      
      elseif( classAvailable(aura_data['class']) ) then
        -- no buff on me
        aura_data['button']:SetBackdropColor(1, 0, 0)
        aura_data['button']:SetAlpha(1)
      
      else -- nobody to cast it
        aura_data['button']:SetBackdropColor(0.4, 0.4, 0.4)
        aura_data['button']:SetAlpha(0.4)
        -- if noone can cast the first, stop one, no use continuing
        break
        
      end
    end
  end
end


local function OnEvent(self, event, ...)
  if( event == 'PLAYER_ENTERING_WORLD' ) then
    createAurasIcons()
    updateAuraIcons()
    
  elseif( event == 'UNIT_AURA' ) then
    -- only aura changes on me are usefull
    local unit = ...
    if unit == "player" then
      -- check each required buff
        updateAuraIcons()
    end
  
  elseif( event == 'PARTY_MEMBERS_CHANGED' or event == 'RAID_ROSTER_UPDATE' ) then
    wipe(available_casters)
    
    local party_size = GetNumPartyMembers()
    for i = 1, party_size do
      local _, unit_class = UnitClass('party' .. i)
      table.insert(available_casters, unit_class)
    end
    
    local raid_size = GetNumRaidMembers()
    for i = 1, raid_size do
      local _, unit_class = UnitClass('raid' .. i)
      table.insert(available_casters, unit_class)
    end
    
    updateAuraIcons()
  end
end

frame:SetScript('OnEvent', OnEvent)



