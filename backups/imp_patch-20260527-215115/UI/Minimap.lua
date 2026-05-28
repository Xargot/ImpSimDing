local addonName, ns = ...
ns = ImpSimDingNS

local DB = ns.DB

local button = CreateFrame("Button", "ImpSimDingMinimapButton", Minimap)
button:SetSize(32, 32)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)

button:EnableMouse(true)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local function UpdatePosition()
    local angle = math.rad(DB().minimapAngle or 225)
    local w = Minimap:GetWidth() / 2
    local h = Minimap:GetHeight() / 2
    local radius = (w + h) / 2 + 5

    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local bg = button:CreateTexture(nil, "BACKGROUND")
bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
bg:SetPoint("CENTER")
bg:SetSize(26, 26)

local border = button:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetPoint("CENTER", 10, -8)
border:SetSize(50, 50)

button:SetNormalTexture(ns.MINIMAP_ICON_TEXTURE)
local icon = button:GetNormalTexture()
icon:SetPoint("CENTER")
icon:SetSize(18, 18)
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

button:SetMovable(true)
button:RegisterForDrag("LeftButton")

button:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetScale()
        px, py = px / scale, py / scale

        DB().minimapAngle = math.deg(math.atan2(py - my, px - mx))
        UpdatePosition()
    end)
end)

button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    UpdatePosition()
end)

button:SetScript("OnClick", function(self, btn)
    if btn == "LeftButton" then
        if ns.OpenOptions then ns.OpenOptions() end
    elseif btn == "RightButton" then
        DB().debug = not DB().debug
        if ns.UpdateDebug then ns.UpdateDebug() end
    end
end)

button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("ImpSimDing")
    GameTooltip:AddLine("Left-click: Open options", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: Toggle debug", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", GameTooltip_Hide)

C_Timer.After(0.1, UpdatePosition)
