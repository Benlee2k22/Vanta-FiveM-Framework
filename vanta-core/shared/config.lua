VantaConfig = {
    Debug = false,
    DefaultMoney = { cash = 500, bank = 2500 },
    Inventory = { maxSlots = 24, maxWeight = 25000 },
    PaycheckIntervalMinutes = 15,
    Items = {
        water_bottle = { name = 'water_bottle', label = 'Water Bottle', weight = 500, type = 'item', image = 'water_bottle.png', unique = false, useable = true, shouldClose = true, description = 'A bottle of fresh water.' },
        sandwich = { name = 'sandwich', label = 'Sandwich', weight = 300, type = 'item', image = 'sandwich.png', unique = false, useable = true, shouldClose = true, description = 'A quick bite to eat.' },
        bandage = { name = 'bandage', label = 'Bandage', weight = 150, type = 'item', image = 'bandage.png', unique = false, useable = true, shouldClose = true, description = 'A basic medical dressing.' },
        radio = { name = 'radio', label = 'Radio', weight = 1000, type = 'item', image = 'radio.png', unique = true, useable = false, shouldClose = true, description = 'A handheld radio.' },
        phone = { name = 'phone', label = 'Phone', weight = 500, type = 'item', image = 'phone.png', unique = true, useable = false, shouldClose = true, description = 'A mobile phone.' },
        lockpick = { name = 'lockpick', label = 'Lockpick', weight = 200, type = 'item', image = 'lockpick.png', unique = false, useable = false, shouldClose = true, description = 'A simple lockpick.' },
    },
    Jobs = {
        unemployed = { label = 'Unemployed', type = 'none', defaultDuty = false, grades = { ['0'] = { name = 'Trainee', payment = 10 } } },
        police = { label = 'Los Santos Police Department', type = 'leo', defaultDuty = false, grades = {
            ['0'] = { name = 'Cadet', payment = 150 }, ['1'] = { name = 'Officer', payment = 250 },
            ['2'] = { name = 'Sergeant', payment = 350 }, ['3'] = { name = 'Lieutenant', payment = 450 },
            ['4'] = { name = 'Chief', payment = 550, isboss = true },
        } },
        ambulance = { label = 'Emergency Medical Services', type = 'ems', defaultDuty = false, grades = {
            ['0'] = { name = 'Trainee Paramedic', payment = 150 }, ['1'] = { name = 'Paramedic', payment = 250 },
            ['2'] = { name = 'Senior Paramedic', payment = 350 }, ['3'] = { name = 'Chief Medical Officer', payment = 450, isboss = true },
        } },
    },
    DefaultJob = { name = 'unemployed', label = 'Unemployed', grade = { name = 'Trainee', level = 0 }, onduty = false, type = 'none', isboss = false },
    SaveIntervalMinutes = 5,
    StartingPosition = { x = -1037.7, y = -2737.8, z = 20.2, w = 0.0 },
}
