local addonName, ns = ...
ns = ImpSimDingNS

local DB = ns.DB

local panel = CreateFrame("Frame", "ImpSimDingOptionsPanel")
panel.name = "ImpSimDing"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ImpSimDing")

local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
sub:SetText("Simulated imp counter with sound alert.")

-- Threshold slider
local slider = CreateFrame("Slider", "ImpSimDingThresholdSlider", panel, "OptionsSliderTemplate")
slider:SetWidth(200)
slider:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -40)
slider:SetMinMaxValues(1, 20)
slider:SetValueStep(1)
slider:SetObeyStepOnDrag(true)
slider:SetValue(DB().threshold or 6)

_G[slider:GetName() .. "Low"]:SetText("1")
_G[slider:GetName() .. "High"]:SetText("20")
_G[slider:GetName() .. "Text"]:SetText("Imp threshold")

local sliderValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
sliderValueText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
sliderValueText:SetText("Current: " .. (DB().threshold or 6))

slider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    DB().threshold = value
    sliderValueText:SetText("Current: " .. value)
end)

-- Debug checkbox
local debugCheck = CreateFrame("CheckButton", "ImpSimDingDebugCheck", panel, "InterfaceOptionsCheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -4, -24)
debugCheck.Text:SetText("Show debug frame")
debugCheck:SetChecked(DB().debug)

debugCheck:SetScript("OnClick", function(self)
    DB().debug = self:GetChecked()
    if ns.UpdateDebug then ns.UpdateDebug() end
end)

-- Alert sound dropdown (Blizzard Menu API — replaces UIDropDownMenu)
local soundLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
soundLabel:SetPoint("TOPLEFT", debugCheck, "BOTTOMLEFT", 4, -20)
soundLabel:SetText("Alert sound")

local function GetSoundNameForId(soundId)
    for _, opt in ipairs(ns.SOUND_OPTIONS) do
        if opt.id == soundId then
            return opt.name
        end
    end
    return ns.SOUND_OPTIONS[1].name
end

local soundDropdown = CreateFrame("DropdownButton", "ImpSimDingSoundDropdown", panel, "WowStyle1DropdownTemplate")
soundDropdown:SetPoint("TOPLEFT", soundLabel, "BOTTOMLEFT", 0, -4)
soundDropdown:SetWidth(180)
soundDropdown:SetDefaultText(GetSoundNameForId(DB().soundId))

soundDropdown:SetupMenu(function(_, rootDescription)
    for _, opt in ipairs(ns.SOUND_OPTIONS) do
        rootDescription:CreateRadio(opt.name, function()
            return DB().soundId == opt.id
        end, function()
            DB().soundId = opt.id
            soundDropdown:GenerateMenu()
        end)
    end
end)

-- Register with Settings API
local category = Settings.RegisterCanvasLayoutCategory(panel, "ImpSimDing")
Settings.RegisterAddOnCategory(category)

function ns.OpenOptions()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    end
end
