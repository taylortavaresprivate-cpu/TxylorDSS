function math_average(items)
    local numOfItems = 0
    local sum = 0
    for i = 1,#items do
        sum = sum + tonumber(items[i])
        numOfItems = numOfItems + 1
    end
    return math.ceil(sum/numOfItems)
end

TimeSinceLastShift = 0
ComfortModeScale = 1

StartReactionTime = -math.random(50,100)

require('ConfigApp')

ComfortUpRamp = 0
ComfortDownRamp = 0
function script.update(dt)
    if AutoGearboxEnabled or AutoClutchEnabled then
        local CarData = ac.getCar(0)
        local rpmMinimum = CarData.rpmMinimum
        Controls = ac.overrideCarControls(0)
        if IdleRPMFixEnabled then
            rpmMinimum = IdleRPMFixValue
        end

        local clutchAmount = math.min(clutchAmount or 1, (CarData.rpm-rpmMinimum)/((rpmMinimum+CarData.rpmLimiter)*ClutchForOtherGearsValue))
        if CarData.engagedGear == 0 then
            clutchAmount = math.min(clutchAmount, 0)
        end
        if CarData.gear < 2 then
            clutchAmount = math.min(clutchAmount, (CarData.rpm-rpmMinimum)/((rpmMinimum+CarData.rpmLimiter)*ClutchForFirstGearValue))
        end
        if HandbrakeClutchEnabled and CarData.handbrake > 0.01 then
            if ClutchForHandbrakeValue <= 1 then
                clutchAmount = math.min(clutchAmount, (CarData.rpm-rpmMinimum)/((rpmMinimum+CarData.rpmLimiter)*ClutchForHandbrakeValue))
            else
                clutchAmount = math.min(clutchAmount, 0)
            end
        end
        Controls.clutch = clutchAmount

        if AutoGearboxEnabled then

            if StartLightsAssistanceEnabled and ac.getSim().timeToSessionStart > -1000 and ac.getSim().raceSessionType == 3 then -- Start Lights Assistance
                if ac.getSim().timeToSessionStart < StartReactionTime and CarData.gear <= 0 then
                    Controls.gearUp = true
                    TimeSinceLastShift = 0
                    StartReactionTime = -math.random(100,220)
                elseif CarData.gear < 0 then
                    Controls.gearUp = true
                end
            end

            if ComfortModeEnabled then
                if CarData.gas > 0.01 and CarData.engagedGear ~= 0 then
                    if ComfortModeScale*0.95 > CarData.gas then
                        ComfortModeScale = ComfortModeScale - (0.0002*dt) - ComfortDownRamp
                        ComfortDownRamp = ComfortDownRamp + 0.00001
                        ComfortUpRamp = 0
                    elseif ComfortModeScale*0.95 < CarData.gas then
                        ComfortModeScale = ComfortModeScale + (0.0005*dt) + ComfortUpRamp
                        ComfortUpRamp = ComfortUpRamp + 0.00005
                        ComfortDownRamp = 0
                    end
                else
                    ComfortUpRamp = 0
                    ComfortDownRamp = 0
                end
                ComfortModeScale = math.clamp(ComfortModeScale, 0.5, 1)
            else
                ComfortModeScale = 1
            end
            TimeSinceLastShift = TimeSinceLastShift + dt
            if TimeSinceLastShift > math.random(100,200)*0.001 then
                if CarData.gear > 0 and CarData.speedKmh > GearboxSetup[CarData.gear].up*ComfortModeScale then
                    TimeSinceLastShift = 0
                    Controls.gearUp = true
                elseif CarData.gear > 1 and CarData.speedKmh < GearboxSetup[CarData.gear].down*ComfortModeScale then
                    TimeSinceLastShift = 0
                    Controls.gearDown = true
                end
            end

            if CarData.speedKmh < 5 and math.random() <= 0.15 then
                RecalculateGearbox()
            end
        end
    else
        Controls = ac.overrideCarControls(0)
        Controls.clutch = 1
    end
end












































































--local f = io.open('content/tracks/monza/ai/fast_lane.ai', 'rb')
--
--if f then
--    s = f:read("a")
--    f:close()
--end
--
---- s read from fastlane
--if ac.getPatchVersionCode()>=3044 and s then
--    totaldist = 0
--    pos = 0
--    
--    -- 4 header values
--    header, pos      = string.unpack("=I4", s, pos)
--    detailCount, pos = string.unpack("=I4", s, pos)
--    _, pos           = string.unpack("=I4", s, pos)
--    _, pos           = string.unpack("=I4", s, pos)
--
--    for i = 1, detailCount do
--        -- 4 floats, one integer
--        x,    pos = string.unpack("=f", s, pos)
--        y,    pos = string.unpack("=f", s, pos)
--        z,    pos = string.unpack("=f", s, pos)
--        dist, pos = string.unpack("=f", s, pos) -- distance to last point
--        id, pos   = string.unpack("=I4", s, pos)
--        totaldist = totaldist + dist
--        -- ...
--    end
--end
--
--ac.debug("lastDistance", dist)
--ac.debug("splineLengthOfFileImOpening", totaldist)
--ac.debug("splineLengthOfCurrentTrack", ac.getSim().trackLengthM)
