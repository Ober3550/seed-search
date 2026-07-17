-- RNG draw tracer for Universe.build().
-- Set SE_TRACE=1 to enable. Prints draw count at each major code section.
-- Compare with Zig's draw counts to find divergence points.

if os.getenv("SE_TRACE") == "1" then
    -- Wrap game.create_random_generator to track global RNG draws
    local orig_create = game.create_random_generator
    local draw = 0
    local section = "start"

    game.create_random_generator = function(s)
        local gen = orig_create(s)
        if s == nil then
            -- This is storage.universe_rng (the global stream)
            local proxy = {}
            local mt = {
                __call = function(_, a, b)
                    draw = draw + 1
                    if a == nil then return gen() end
                    if b == nil then return gen(a) end
                    return gen(a, b)
                end
            }
            setmetatable(proxy, mt)

            -- Wrap Universe.build to track sections
            local orig_build = Universe.build
            Universe.build = function()
                -- Monkey-patch Universe.shuffle to count draws
                local orig_shuffle = Universe.shuffle
                Universe.shuffle = function(tbl)
                    local before = draw
                    orig_shuffle(tbl)
                    local n = 0; for _ in pairs(tbl) do n = n + 1 end
                    io.stderr:write(string.format("TRACE: shuffle(%d items) draws %d->%d (%d draws)\n",
                        n, before, draw, draw - before))
                end

                orig_build()
                Universe.shuffle = orig_shuffle
            end

            -- Wrap random_stellar_position (defined inside build, so we hook later)
            -- Wrap Universe.add_zone to track zone creation
            local orig_add = Universe.add_zone
            Universe.add_zone = function(zi, zbn, zone)
                io.stderr:write(string.format("TRACE: add_zone(%s, %s) draw=%d\n", zone.name, zone.type or "?", draw))
                return orig_add(zi, zbn, zone)
            end

            return proxy
        end
        return gen
    end
end
