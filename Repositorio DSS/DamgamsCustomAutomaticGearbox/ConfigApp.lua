MainConfigFile = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DamgamsCustomAutomaticGearbox/Config/" .. "main_config" .. ".ini")
CarConfigFile = ac.INIConfig.load(ac.getFolder(ac.FolderID.ACApps) .. "/lua/DamgamsCustomAutomaticGearbox/Config/" .. ac.getCarID(0) .. ".ini")

AutoGearboxEnabled = MainConfigFile:get("mainsettings", "autogearboxenabled", true)
AutoClutchEnabled = MainConfigFile:get("mainsettings", "autoclutchenabled", true)
StartLightsAssistanceEnabled = MainConfigFile:get("mainsettings", "startlightsassistance", false)

HandbrakeClutchEnabled = CarConfigFile:get("mainsettings", "handbrakeclutchenabled", false)
ComfortModeEnabled = CarConfigFile:get("mainsettings", "comfortmodeenabled", false)
IdleRPMFixEnabled = CarConfigFile:get("mainsettings", "idlerpmfixenabled", ac.getCar(0).rpmMinimum < 0)
IdleRPMFixValue = CarConfigFile:get("mainsettings", "idlerpmfixvalue", math.floor(ac.getCar(0).rpmLimiter*0.001)*100)

ClutchForHandbrakeValue = CarConfigFile:get("mainsettings", "clutchforhandbrakevalue", 0.4)
ClutchForFirstGearValue = CarConfigFile:get("mainsettings", "clutchforfirstgearvalue", 0.4)
ClutchForOtherGearsValue = CarConfigFile:get("mainsettings", "clutchforothergearsvalue", 0.1)

ShiftThreshold = 5
MaximumShiftThreshold = 100

GearUpOffset = {}
GearDownOffset = {}
GearboxSetup = {}

for gear = 1, ac.getCar(0).gearCount+1 do
    GearUpOffset[gear] = CarConfigFile:get("mainsettings", "gearupoffset" .. gear, 0)
    GearDownOffset[gear] = CarConfigFile:get("mainsettings", "geardownoffset" .. gear, 0)
end

local function UISlider(ConfigFile, Title, Tooltip, ConfigValue, Category, ConfigValueIni, Min, Max, Default, Round, Rounding)
    sliderCounter = sliderCounter + 1

    if Title and Title ~= "" then
        ui.text(Title)
    end
    local sliderValue = ConfigFile:get(Category, ConfigValueIni, Default)
    local sliderValue = ui.slider(" ##slider" .. sliderCounter, sliderValue, Min, Max, Rounding)
    if ConfigValue ~= sliderValue then
        ConfigValue = sliderValue
        ConfigFile:set(Category, ConfigValueIni, sliderValue)
        NeedToSaveConfig = true
    end
    if Round then
        ConfigFile:set(Category, ConfigValueIni, math.round(sliderValue))
        NeedToSaveConfig = true
    end
    if ui.itemHovered() and Tooltip and Tooltip ~= "" then
        ui.setTooltip(tostring(Tooltip))
    end
    if ui.itemClicked(ui.MouseButton.Right, false) then
        ConfigValue = Default
        ConfigFile:set(Category, ConfigValueIni, Default)
        NeedToSaveConfig = true
    end
    ac.debug("Config: " .. Title, ConfigValue)

    return ConfigValue
end

local function UICheckbox(ConfigFile, Title, Tooltip, ConfigBool, Category, ConfigBoolIni, Default)
    checkboxCounter = checkboxCounter + 1

    local ConfigBool = ConfigFile:get(Category, ConfigBoolIni, Default)
    local checkbox = ui.checkbox(Title, ConfigBool)
    if checkbox then
        ConfigBool = not ConfigBool
        ConfigFile:set(Category, ConfigBoolIni, ConfigBool)
        NeedToSaveConfig = true
    end
    if ui.itemHovered() and Tooltip and Tooltip ~= "" then
        ui.setTooltip(tostring(Tooltip))
    end
    if ui.itemClicked(ui.MouseButton.Right, false) then
        ConfigBool = Default
        NeedToSaveConfig = true
    end
    ac.debug("Config: " .. Title, ConfigBool)
    return ConfigBool
end

function RecalculateGearbox()
    for gear = 1, ac.getCar(0).gearCount+1 do
        local upshiftthreshold = math.round(ac.getCarMaxSpeedWithGear(0, gear)-math.max(ShiftThreshold+2.5, ac.getCarMaxSpeedWithGear(0, gear)*(ShiftThreshold/(100*(gear)))))
        local downshiftthreshold = math.round((ac.getCarMaxSpeedWithGear(0, gear-1))-(math.max(ShiftThreshold+7.5, ac.getCarMaxSpeedWithGear(0, gear-1)*(ShiftThreshold/500))*2))
        if upshiftthreshold < 0 then upshiftthreshold = 0 end
        if downshiftthreshold < 0 then downshiftthreshold = 0 end
        --ui.text("            )
        if not GearboxSetup[gear] then
            GearboxSetup[gear] = {}
            GearboxSetup[gear].up = upshiftthreshold + GearUpOffset[gear]
            GearboxSetup[gear].updefault = upshiftthreshold
            GearboxSetup[gear].down = downshiftthreshold + GearDownOffset[gear]
            GearboxSetup[gear].downdefault = downshiftthreshold
        end
        if upshiftthreshold + GearUpOffset[gear] ~= GearboxSetup[gear].up then
            GearboxSetup[gear].up = upshiftthreshold + GearUpOffset[gear]
            GearboxSetup[gear].updefault = upshiftthreshold
        end
        if downshiftthreshold + GearDownOffset[gear] ~= GearboxSetup[gear].down then
            GearboxSetup[gear].down = downshiftthreshold + GearDownOffset[gear]
            GearboxSetup[gear].downdefault = downshiftthreshold
        end
        GearboxSetup[gear].maxspeed = math.round(ac.getCarMaxSpeedWithGear(0, gear))
    end
end
RecalculateGearbox()

function script.windowMain()
    ui.beginOutline()
    sliderCounter = 0
    checkboxCounter = 0

    ui.separator()
    ui.separator()
    ui.text("Global Settings:")
    AutoGearboxEnabled = UICheckbox(MainConfigFile, "Automatic Gearbox", "Enable the automatic gear shifter.\n\nMAKE SURE TO DISABLE VANILLA AUTOMATIC GEARBOX AND AUTOCLUTCH", AutoGearboxEnabled, "mainsettings", "autogearboxenabled", true)
    ui.sameLine(210)
    ui.text("Bind:")
    ui.sameLine(250)
    ui.pushItemWidth(40)
    AutoGearboxEnabledKeybind:control()
    ui.popItemWidth()
    if not AutoGearboxEnabled then
        AutoClutchEnabled = UICheckbox(MainConfigFile, "Automatic Clutch", "Enable the automatic clutch, without automatic gearbox.\n\nMAKE SURE TO DISABLE VANILLA AUTOMATIC GEARBOX AND AUTOCLUTCH", AutoClutchEnabled, "mainsettings", "autoclutchenabled", true)
        ui.sameLine(210)
        ui.text("Bind:")
        ui.sameLine(250)
        ui.pushItemWidth(40)
        AutoClutchEnabledKeybind:control()
        ui.popItemWidth()
    end
    if AutoGearboxEnabled then
        StartLightsAssistanceEnabled = UICheckbox(MainConfigFile, "Start Lights Assistance", "Automatically shifts into 1st gear on race start green light, with humanlike, slightly randomized reaction time delay.", StartLightsAssistanceEnabled, "mainsettings", "startlightsassistance", false)
        ui.sameLine(210)
        ui.text("Bind:")
        ui.sameLine(250)
        ui.pushItemWidth(40)
        StartLightsAssistanceEnabledKeybind:control()
        ui.popItemWidth()
    end
    ui.separator()
    ui.separator()
    ui.text("Car Settings:")
    if AutoGearboxEnabled or AutoClutchEnabled then
        ui.text("AutoClutch First Gear:")
        ui.sameLine(170)
        ui.pushItemWidth(120)
        ClutchForFirstGearValue = UISlider(CarConfigFile, "", "Clutch For First and Reverse gear.", ClutchForFirstGearValue, "mainsettings", "clutchforfirstgearvalue", 0.01, 0.95, 0.4, false, '%.2f')
        ui.popItemWidth()
        ui.text("AutoClutch Other Gears:")
        ui.sameLine(170)
        ui.pushItemWidth(120)
        ClutchForOtherGearsValue = UISlider(CarConfigFile, "", "Clutch For Other Gears", ClutchForOtherGearsValue, "mainsettings", "clutchforothergearsvalue", 0.01, 0.95, 0.1, false, '%.2f')
        ui.popItemWidth()
        HandbrakeClutchEnabled = UICheckbox(CarConfigFile, "Clutch with Handbrake", "Should the clutch be pressed when you use the handbrake (Could be useful in rear wheel drive cars.)", HandbrakeClutchEnabled, "mainsettings", "handbrakeclutchenabled", false)
        ui.sameLine(210)
        ui.text("Bind:")
        ui.sameLine(250)
        ui.pushItemWidth(40)
        HandbrakeClutchEnabledKeybind:control()
        ui.popItemWidth()
        if HandbrakeClutchEnabled then
            ui.text("AutoClutch Handbrake:")
            ui.sameLine(170)
            ui.pushItemWidth(120)
            ClutchForHandbrakeValue = UISlider(CarConfigFile, "", "Clutch For Handbrake. \nSet to 1.01 to make it fully press.", ClutchForHandbrakeValue, "mainsettings", "clutchforhandbrakevalue", 0.01, 1.01, 0.4, false, '%.2f')
            ui.popItemWidth()
        end
        if AutoGearboxEnabled then
            ComfortModeEnabled = UICheckbox(CarConfigFile, "Comfort Mode", "Adjust shifting based on how much you press the throttle, like in a regular street car with automatic transmission", ComfortModeEnabled, "mainsettings", "comfortmodeenabled", false)
            ui.sameLine(210)
            ui.text("Bind:")
            ui.sameLine(250)
            ui.pushItemWidth(40)
            ComfortModeEnabledKeybind:control()
            ui.popItemWidth()
        end
        IdleRPMFixEnabled = UICheckbox(CarConfigFile, "Clutch Idle RPM Fix", "In some rare cases, idle RPM of cars isn't reported properly, which breaks autoclutch. This option allows you to set custom idle RPM to use for this car.", IdleRPMFixEnabled, "mainsettings", "idlerpmfixenabled", ac.getCar(0).rpmMinimum < 0)
        if IdleRPMFixEnabled then
            ui.sameLine(170)
            ui.pushItemWidth(120)
            IdleRPMFixValue = UISlider(CarConfigFile, "", "Minimum RPM. Hold Ctrl to set precise value.", IdleRPMFixValue, "mainsettings", "idlerpmfixvalue", 0, ac.getCar(0).rpmLimiter, math.floor(ac.getCar(0).rpmLimiter*0.001)*100, true, '%.0f')
            ui.popItemWidth()
        end
    end
    if AutoGearboxEnabled then
        ui.separator()
        ui.separator()
        ui.text("Gearbox Overview:")
        ui.separator()
        ui.separator()
        for gear = 1, ac.getCar(0).gearCount+1 do
            if gear <= ac.getCar(0).gearCount then
                ui.text("Gear " .. gear .. ": ")
                ui.sameLine(80)
                ui.text(math.round(GearboxSetup[gear].down))
                ui.sameLine(105)
                ui.text("-")
                ui.sameLine(115)
                ui.text(math.round(GearboxSetup[gear].up) .. " km/h.")
                ui.sameLine(180)
                ui.text("| Max: " .. GearboxSetup[gear].maxspeed .. " km/h.")
                ui.separator()

            end
        end
        ui.separator()
        ui.text("Offsets:")
        ui.button("Reset", 15)
        if ui.itemClicked() then
            RequestOffsetsReset = true
        end
        ui.separator()
        for gear = 1, ac.getCar(0).gearCount+1 do

            if gear <= ac.getCar(0).gearCount then
                if gear <= ac.getCar(0).gearCount-1 then
                    local color = rgb(1,1,1)
                    if GearUpOffset[gear] ~= 0 then
                        color = rgb(1,1,0)
                    end
                    ui.separator()
                    ui.text("")
                    ui.sameLine(155)
                    ui.pushItemWidth(140)
                    GearUpOffset[gear] = UISlider(CarConfigFile, "", "How much earier or later the car should shift this gear up, km/h.", GearUpOffset[gear], "mainsettings", "gearupoffset" .. gear, (-(GearboxSetup[gear].updefault-GearboxSetup[gear+1].down))+1, (GearboxSetup[gear].maxspeed-GearboxSetup[gear].updefault)-1, 0, true, '%.0f')
                    ui.popItemWidth()
                    ui.sameLine(125)
                    ui.textColored((-(GearboxSetup[gear].updefault-GearboxSetup[gear+1].down))+1, color)
                    ui.sameLine(300)
                    ui.textColored((GearboxSetup[gear].maxspeed-GearboxSetup[gear].updefault)-1, color)
                    ui.sameLine(20)
                    ui.textColored("#" .. gear .. " Offset Up", color)
                    ui.sameLine(115)
                    ui.textColored("|", color)
                    if GearUpOffset[gear] > (GearboxSetup[gear].maxspeed-GearboxSetup[gear].updefault)-1 then
                        GearUpOffset[gear] = GearUpOffset[gear] - 1
                        CarConfigFile:set("mainsettings", "gearupoffset" .. gear, GearUpOffset[gear])
                    end
                    if GearUpOffset[gear] < (-(GearboxSetup[gear].updefault-GearboxSetup[gear+1].down))+1 then
                        GearUpOffset[gear] = GearUpOffset[gear] + 1
                        CarConfigFile:set("mainsettings", "gearupoffset" .. gear, GearUpOffset[gear])
                    end
                end
                if gear > 1 then
                    local color = rgb(1,1,1)
                    if GearDownOffset[gear] ~= 0 then
                        color = rgb(1,1,0)
                    end
                    ui.separator()
                    ui.text("")
                    ui.sameLine(155)
                    ui.pushItemWidth(140)
                    GearDownOffset[gear] = UISlider(CarConfigFile, "", "How much earier or later the car should shift this gear down, km/h.", GearDownOffset[gear], "mainsettings", "geardownoffset" .. gear, (-GearboxSetup[gear].downdefault+GearboxSetup[gear-1].down)+1, (GearboxSetup[gear-1].up-GearboxSetup[gear].downdefault)-1, 0, true, '%.0f')
                    ui.popItemWidth()
                    ui.sameLine(125)
                    ui.textColored((-GearboxSetup[gear].downdefault+GearboxSetup[gear-1].down)+1, color)
                    ui.sameLine(300)
                    ui.textColored((GearboxSetup[gear-1].up-GearboxSetup[gear].downdefault)-1, color)
                    ui.sameLine(20)
                    ui.textColored("#" .. gear .. " Offset Down", color)
                    ui.sameLine(115)
                    ui.textColored("|", color)

                    if GearDownOffset[gear] > (GearboxSetup[gear-1].up-GearboxSetup[gear].downdefault)-1 then
                        GearDownOffset[gear] = GearDownOffset[gear] - 1
                        CarConfigFile:set("mainsettings", "geardownoffset" .. gear, GearDownOffset[gear])
                    end
                    if GearDownOffset[gear] < (-GearboxSetup[gear].downdefault+GearboxSetup[gear-1].down)+1 then
                        GearDownOffset[gear] = GearDownOffset[gear] + 1
                        CarConfigFile:set("mainsettings", "geardownoffset" .. gear, GearDownOffset[gear])
                    end
                end
                ui.separator()
                ui.text("")
            end
        end
    end

    if NeedToSaveConfig then
        if RequestOffsetsReset then
            for gear = 1, ac.getCar(0).gearCount+1 do
                GearUpOffset[gear] = 0
                GearDownOffset[gear] = 0
                CarConfigFile:set("mainsettings", "gearupoffset" .. gear, GearUpOffset[gear])
                CarConfigFile:set("mainsettings", "geardownoffset" .. gear, GearDownOffset[gear])
            end
            RequestOffsetsReset = false
        end
        MainConfigFile:save()
        CarConfigFile:save()
        RecalculateGearbox()
        NeedToSaveConfig = false
    end
    ui.endOutline(rgb(0,0,0), 1)
end

function AutoGearboxEnabledKeybindFunction()
    AutoGearboxEnabled = not AutoGearboxEnabled
    MainConfigFile:set("mainsettings", "autogearboxenabled", AutoGearboxEnabled)
    Controls = ac.overrideCarControls(0)
    Controls.clutch = 1
    MainConfigFile:save()
end
AutoGearboxEnabledKeybind = ac.ControlButton('app.DamgamsCustomAutomaticGearbox/Auto Gearbox Enabled Keybind')
AutoGearboxEnabledKeybind:onPressed(AutoGearboxEnabledKeybindFunction)

function AutoClutchEnabledKeybindFunction()
    AutoClutchEnabled = not AutoClutchEnabled
    MainConfigFile:set("mainsettings", "autoclutchenabled", AutoClutchEnabled)
    Controls = ac.overrideCarControls(0)
    Controls.clutch = 1
    MainConfigFile:save()
end
AutoClutchEnabledKeybind = ac.ControlButton('app.DamgamsCustomAutomaticGearbox/Auto Clutch Enabled Keybind')
AutoClutchEnabledKeybind:onPressed(AutoClutchEnabledKeybindFunction)

function StartLightsAssistanceEnabledFunction()
    StartLightsAssistanceEnabled = not StartLightsAssistanceEnabled
    MainConfigFile:set("mainsettings", "startlightsassistance", StartLightsAssistanceEnabled)
    MainConfigFile:save()
end
StartLightsAssistanceEnabledKeybind = ac.ControlButton('app.DamgamsCustomAutomaticGearbox/Start Lights Assistance Enabled Keybind')
StartLightsAssistanceEnabledKeybind:onPressed(StartLightsAssistanceEnabledFunction)

function HandbrakeClutchEnabledKeybindFunction()
    HandbrakeClutchEnabled = not HandbrakeClutchEnabled
    CarConfigFile:set("mainsettings", "handbrakeclutchenabled", HandbrakeClutchEnabled)
    CarConfigFile:save()
end
HandbrakeClutchEnabledKeybind = ac.ControlButton('app.DamgamsCustomAutomaticGearbox/Handbrake Clutch Enabled Keybind')
HandbrakeClutchEnabledKeybind:onPressed(HandbrakeClutchEnabledKeybindFunction)

function ComfortModeEnabledKeybindFunction()
    ComfortModeEnabled = not ComfortModeEnabled
    CarConfigFile:set("mainsettings", "comfortmodeenabled", ComfortModeEnabled)
    CarConfigFile:save()
end
ComfortModeEnabledKeybind = ac.ControlButton('app.DamgamsCustomAutomaticGearbox/Comfort Mode Enabled Keybind')
ComfortModeEnabledKeybind:onPressed(ComfortModeEnabledKeybindFunction)