-- Krastorio2 data-stage additions for the SE universe generator.
--
-- Mirrors what SE's K2 compatibility adds at the data stage (see the mod's
-- prototypes/phase-1/compatibility/krastorio2/): three extra resources and a
-- placement rule for imersite. The control-stage effects (mineral-water resource
-- override and the guaranteed imersite home-system body) come from loading
-- scripts/compatibility/krastorio2.lua, which se_env does when K2 is enabled.
--
-- Only applied when SE_ENABLE_K2 is set. Operates on the global `game` prototype
-- tables and `prototypes` that se_env has already built.

local se_k2 = {}

-- Resources K2 registers via se_resources (resource-gen.lua). kr-mineral-water
-- contains "water" so the base not_space rule already forbids it in space;
-- kr-rare-metal-ore is unrestricted; kr-imersite gets an explicit rule below.
se_k2.RESOURCES = { "kr-rare-metal-ore", "kr-mineral-water", "kr-imersite" }

function se_k2.apply()
    for _, name in ipairs(se_k2.RESOURCES) do
        -- Placeable resource + its autoplace control (both consulted by
        -- Universe.load_resource_settings / list_resource_controls).
        game.entity_prototypes[name] = { autoplace_specification = true, name = name, type = "resource" }
        game.autoplace_control_prototypes[name] = { category = "resource", name = name }

        -- Core-fragment item + entities (se_core_fragment_resources), matching
        -- SE's se-core-fragment-<resource> naming so list_core_fragments and the
        -- core_fragment lookup in load_resource_settings find them.
        local frag = "se-core-fragment-" .. name
        game.item_prototypes[frag] = {
            localised_name = { "item-name.core-fragment", { "entity-name." .. name } },
        }
        game.entity_prototypes[frag] = { autoplace_specification = false, name = frag, type = "resource" }
        game.entity_prototypes[frag .. "-sealed"] = { autoplace_specification = false, name = frag .. "-sealed", type = "resource" }
    end

    -- Data-stage word rule: prototypes/.../krastorio2/mod-data.lua adds this to
    -- the se-universe-resource-word-rules mod-data, read in load_resource_data.
    prototypes.mod_data[mod_prefix .. "universe-resource-word-rules"].data["kr-imersite"] = {
        forbid_space = true,
        forbid_homeworld = true,
    }
end

return se_k2
