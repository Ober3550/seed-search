local summarize = {}

local se_data = require('se_data')

local function summarize_zone(zone, nauvis, stars)
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
    storage = {
        seed = seed,
        meteor_zones = {},
        zones_by_surface = {},
        spaceships = {},
        forces = { player = {} },
        cache_travel_delta_v = {},
    }
    storage.glyph_vaults = {}
    storage.glyph_vaults_made_loot = {}
    storage.vault_loot_rng = game.create_random_generator()
    Universe.build()
    return storage
end

function summarize.summarize_seed(seed)
    summarize.build_universe(seed)

    -- Hoist commonly-used references so summarize_zone doesn't rebuild them.
    local nauvis = storage.zones_by_name['Nauvis']
    local stars = {}
    for _, z in pairs(storage.zones_by_name) do
        if z.type == "star" then
            table.insert(stars, z)
        end
    end

    -- Home-system planets and moons (Calidus children).
    local planets = {}
    local moons = {}
    for _, planet in pairs(storage.zones_by_name['Calidus'].children) do
        if planet.type == "planet" then
            if not planet.is_homeworld then
                table.insert(planets, summarize_zone(planet, nauvis, stars))
            end
            for _, moon in pairs(planet.children) do
                table.insert(moons, summarize_zone(moon, nauvis, stars))
            end
        end
    end

    -- Only keep the nearest asteroid fields. Naquium + methane ice for deep
    -- space science are the primary concern; far fields are irrelevant.
    local MAX_FIELDS = 10
    local all_fields = {}
    for _, z in pairs(storage.zones_by_name) do
        if z.type == "asteroid-field" then
            -- Compute delta_v (memoized) for sorting; defer full summarization.
            local v = math.ceil(Zone.get_travel_delta_v(nauvis, z))
            table.insert(all_fields, { zone = z, delta_v = v })
        end
    end
    table.sort(all_fields, function (this, that) return this.delta_v < that.delta_v end)

    local fields = {}
    for i = 1, math.min(MAX_FIELDS, #all_fields) do
        table.insert(fields, summarize_zone(all_fields[i].zone, nauvis, stars))
    end

    -- Ancient vault loot.
    local loot = {}
    for i = 1, #planets do
        local module = Ancient.get_next_vault_loot({ name = "player" })
        if module == "productivity-module-9" then
            table.insert(loot, "P")
        elseif module == "speed-module-9" then
            table.insert(loot, "S")
        elseif module == "efficiency-module-9" then
            table.insert(loot, "E")
        else
            assert(false)
        end
    end

    table.sort(planets, function (this, that) return this.delta_v < that.delta_v end)
    table.sort(moons, function (this, that) return this.delta_v < that.delta_v end)
    -- Fields are already sorted by delta_v from the all_fields sort above.

    return {
        seed = seed,
        loot = loot,
        planets = planets,
        moons = moons,
        fields = fields,
    }
end

return summarize
