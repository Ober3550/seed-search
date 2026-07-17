local summarize = {}

local se_data = require('se_data')

local function summarize_zone(zone)
    local nauvis = storage.zones_by_name['Nauvis']
    local stars = {}
    for _, zone in pairs(storage.zones_by_name) do
        if zone.type == "star" then
            table.insert(stars, zone)
        end
    end

    local summary = {}
    summary.name = zone.name
    summary.zone_type = zone.type

    local v = math.ceil(Zone.get_travel_delta_v(nauvis, zone))
    summary.delta_v = v
    if zone.type ~= "asteroid-field" then
        local r = math.floor(zone.radius + 0.5)
        summary.radius = r
    end
    if zone.type == "asteroid-field" then
        if v <= 20000 then
            local closest_star = { delta_v = 1/0, name = nil }
            for _, star in pairs(stars) do
                local delta_v = Zone.get_travel_delta_v(star, zone)
                if delta_v < closest_star.delta_v then
                    closest_star.delta_v = delta_v
                    closest_star.name = star.name
                end
            end
            if closest_star.name == "Calidus" then
                summary.cannonable = true
            else
                summary.cannonable = false
            end
        else
            summary.cannonable = false
        end
    end

    local s = {}
    for i, name in ipairs(se_data.RESOURCE) do
        local control = zone.controls[name]
        if control ~= nil then
            local score = control.frequency * control.richness * control.size
            if zone.type == "asteroid-field" then
                score = score / 167.79554553234018499
            else
                score = score / 22.02730826300005162466
            end
            s[i] = score
        else
            s[i] = 0
        end
    end

    summary.resource = {}
    for i, name in ipairs(se_data.RESOURCE) do
        if s[i] ~= 0 then
            summary.resource[se_data.RESOURCE[i]] = s[i]
        end
    end

    if zone.type ~= "asteroid-field" then
        summary.tags = {}
        summary.tags.temperature = zone.tags.temperature
        summary.tags.water = zone.tags.water
        summary.tags.moisture = zone.tags.moisture
        summary.tags.trees = zone.tags.trees
        summary.tags.aux = zone.tags.aux
        summary.tags.cliff = zone.tags.cliff
        summary.tags.enemy = zone.tags.enemy
    end

    return summary
end

-- Generate the whole universe for a seed and leave it in the global `storage`
-- table (mirroring what SE holds in-game after map creation). Shared by
-- summarize_seed and the comparison harness so both drive generation identically.
function summarize.build_universe(seed)
    FactorioRNG.global_seed = seed
    -- Factorio 2.0 renamed `global` to `storage`. SE 0.7's Universe.build reads
    -- several of these tables before writing them, so seed them here. storage.seed
    -- is the map seed used by the per-zone resource generators (see docs).
    storage = {
        seed = seed,
        meteor_zones = {},
        zones_by_surface = {},
        spaceships = {},
        forces = { player = {} },
        cache_travel_delta_v = {},  -- memoisation table used by Zone.get_travel_delta_v
    }
    -- Mirror Ancient.on_init(): the ancient-vault loot generator is a standalone
    -- generator seeded from the map seed (independent of the universe RNG stream).
    storage.glyph_vaults = {}
    storage.glyph_vaults_made_loot = {}
    storage.vault_loot_rng = game.create_random_generator()
    Universe.build()
    return storage
end

function summarize.summarize_seed(seed)
    summarize.build_universe(seed)

    local planets = {}
    local moons = {}
    for _, planet in pairs(storage.zones_by_name['Calidus'].children) do
        if planet.type == "planet" then
            if not planet.is_homeworld then
                local summary = summarize_zone(planet)
                table.insert(planets, summary)
            end
            for _, moon in pairs(planet.children) do
                local summary = summarize_zone(moon)
                table.insert(moons, summary)
            end
        end
    end

    local fields = {}
    for _, zone in pairs(storage.zones_by_name) do
        if zone.type == "asteroid-field" then
            local summary = summarize_zone(zone)
            table.insert(fields, summary)
        end
    end

    local loot = {}
    for i = 1, #planets do
        local module = Ancient.get_next_vault_loot({ name = "player" })
        if module == "productivity-module-9" then
            table.insert(loot, "P")
        elseif module == "speed-module-9" then
            table.insert(loot, "S")
        elseif module == "efficiency-module-9" then  -- renamed from effectivity-module-9 in SE 0.7
            table.insert(loot, "E")
        else
            assert(false)
        end
    end

    table.sort(planets, function (this, that) return this.delta_v < that.delta_v end)
    table.sort(moons, function (this, that) return this.delta_v < that.delta_v end)
    table.sort(fields, function (this, that) return this.delta_v < that.delta_v end)

    return {
        seed = seed,
        loot = loot,
        planets = planets,
        moons = moons,
        fields = fields,
    }
end

return summarize
