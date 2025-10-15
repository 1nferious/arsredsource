return function(Cheat)
    if (LPH_OBFUSCATED) then
        return -- // I am schizo, adding this just in case.
    end

    local DebugTab = Cheat.Library:AddTab('Developer')
    local Column = DebugTab:AddColumn()
    local Column2 = DebugTab:AddColumn()
    local NetspySection = Column:AddSection('Network spy')
    local PingSpoofSection = Column:AddSection('Ping Spoof')
    local MiscSection = Column2:AddSection('Misc')
    local FeaturesSection = Column2:AddSection('Features')

    -- // DEBUG SHIT
    local Notifications = REQUIRE_MODULE('Modules/Libraries/Notification.lua')

    NetspySection:AddToggle({ text = 'Log Network.Send Calls', flag = 'logNetwork' })
    NetspySection:AddList({ text = 'Ignore List', flag = 'sendIgnoreList', values = { 'Ping', 'Camera Report', 'Character State Report' }, multiselect = true })

    NetspySection:AddToggle({ text = 'Log Network.Fetch Calls', flag = 'logFetch' })
    NetspySection:AddToggle({ text = 'Log Incoming Network Events', flag = 'logNetAdd' })
   -- NetspySection:AddToggle({ text = 'Block Character State Report', flag = 'blockCSR' })
    NetspySection:AddToggle({ text = 'Character State Changer', flag = 'csChanger' })
    NetspySection:AddList({ text = 'State', flag = 'cState', values = {'Walking', 'Running', 'Climbing', 'Swimming', 'SprintSwimming', 'Sitting', 'Crouching', 'Falling', 'Vaulting', 'Invalid state, this used to be a word that some people found offensive!'} })

    MiscSection:AddButton({ text = 'Notification', callback = function()
        Notifications:Notify(Cheat.Library.flags.testMessage, 2, Cheat.Library.flags.testLabel, Color3.new(0, 1, 0))

        Cheat:notifyWarn(Cheat.Library.flags.testMessage, 2)
    end })

    MiscSection:AddBox({ text = 'Message', flag = 'testMessage' })
    MiscSection:AddBox({ text = 'Label', flag = 'testLabel' })

    MiscSection:AddToggle({ text = 'Bullshit Test', flag = 'test2' })
    MiscSection:AddToggle({ text = 'Spectate Report Logs', flag = 'stopInspectingTheFuckingConfig0' })

    -- // Ping Spoof
    PingSpoofSection:AddToggle({ text = 'Ping Spoof', flag = 'dbgPingSpoof' })
        :AddSlider({ text = 'Seconds', flag = 'dbgPingSpoofValue', value = 0, min = 0, max = 2, float = 0.016 })

    -- // Gatekept developer features
    -- // NOTE: The retarded flag names are for if you accidentally send a config that you saved on the dev build, to a user.
    FeaturesSection:AddToggle({ text = 'Detect Spectators', flag = 'stopInspectingTheFuckingConfig1', tip = 'Detects when staff go into spectate. This does have the potential to false flag, so take any alerts with a grain of salt' })
    FeaturesSection:AddToggle({ text = 'FPS Killer Bullets', flag = 'stopInspectingTheFuckingConfig2', tip = 'Lag other players with bullets; must shoot a lot of bullets, you also cant hit anything' })
end