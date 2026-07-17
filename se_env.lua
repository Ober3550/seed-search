local se_env = {}

-- Optional Krastorio2 support. When SE_ENABLE_K2=1, the harness mirrors what SE
-- does with Krastorio2 active: it adds K2's resources + the kr-imersite word
-- rule, and loads SE's K2 compatibility script so its generation listeners fire
-- (mineral-water resource override + a guaranteed imersite home-system body,
-- which consumes the global universe RNG and so changes seeds vs pure SE).
local SE_K2 = os.getenv('SE_ENABLE_K2') == '1' or os.getenv('SE_ENABLE_K2') == 'true'
se_env.k2_enabled = SE_K2

-- Impose a deterministic `pairs` order BEFORE any mod code loads. SE 0.7's
-- generator draws RNG inside string-keyed pairs() loops, and Lua 5.2 randomises
-- its hash order per process, so without this the harness is not reproducible.
-- See det_pairs.lua for the important caveat about matching Factorio's order.
require('det_pairs')

local zip = require('zip')
local env = require('env')

serpent = {}
serpent.block = function () return "" end
serpent.line = function () return "" end
--serpent = dofile('./serpent.lua')

util = dofile('./factorio-util.lua')
core_util = dofile('./factorio-util.lua')

function table_size(t)
    local count = 0
    for k,v in pairs(t) do
        count = count + 1
    end
    return count
end

log = function () end
-- Factorio 2.0 renamed the mod-global data table from `global` to `storage`.
-- SE's universe generator reads/writes `storage` throughout; summarize.lua resets
-- it per seed. `is_debug_mode` gates the mod's debug logging/serpent dumps.
is_debug_mode = false
storage = {}

FactorioRNG = { global_seed = nil }
function FactorioRNG:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

local rng = require('rng')
FactorioRNG.__call = rng.call

mod_prefix = "se-"
mod_prefix_snake_case = "se_"
game = {}
game.autoplace_control_prototypes = {
  coal = {
    category = "resource",
    name = "coal"
  },
  cold = {
    category = "terrain",
    name = "cold"
  },
  ["copper-ore"] = {
    category = "resource",
    name = "copper-ore"
  },
  ["crude-oil"] = {
    category = "resource",
    name = "crude-oil"
  },
  ["enemy-base"] = {
    category = "enemy",
    name = "enemy-base"
  },
  hot = {
    category = "terrain",
    name = "hot"
  },
  ["iron-ore"] = {
    category = "resource",
    name = "iron-ore"
  },
  ["planet-size"] = {
    category = "terrain",
    name = "planet-size"
  },
  ["se-beryllium-ore"] = {
    category = "resource",
    name = "se-beryllium-ore"
  },
  ["se-cryonite"] = {
    category = "resource",
    name = "se-cryonite"
  },
  ["se-holmium-ore"] = {
    category = "resource",
    name = "se-holmium-ore"
  },
  ["se-iridium-ore"] = {
    category = "resource",
    name = "se-iridium-ore"
  },
  ["se-methane-ice"] = {
    category = "resource",
    name = "se-methane-ice"
  },
  ["se-naquium-ore"] = {
    category = "resource",
    name = "se-naquium-ore"
  },
  ["se-vitamelange"] = {
    category = "resource",
    name = "se-vitamelange"
  },
  ["se-vulcanite"] = {
    category = "resource",
    name = "se-vulcanite"
  },
  ["se-water-ice"] = {
    category = "resource",
    name = "se-water-ice"
  },
  stone = {
    category = "resource",
    name = "stone"
  },
  trees = {
    category = "terrain",
    name = "trees"
  },
  ["uranium-ore"] = {
    category = "resource",
    name = "uranium-ore"
  }
}
game.create_random_generator = function (seed)
    if seed == nil then
        seed = FactorioRNG.global_seed
    end
    if seed < 341 then
        seed = 341
    end
    return FactorioRNG:new{ x = seed, y = seed, z = seed }
end
game.print = function () end

-- Functional (but minimal) event system. SE registers many listeners at load;
-- only two custom events are triggered during Universe.build:
-- "on_resource_setting_load" and "on_homesystem_make". Pure SE has no listeners
-- for either (so behaviour is unchanged), but the K2 compat script does — hence
-- we actually dispatch them rather than no-op. Native/entity events never fire
-- headless: their keys come from the empty `defines.events` (nil) or via the
-- addOn*Listeners helpers, and are ignored.
Event = { listeners = {} }
Event.addListener = function (event_key, callback)
    if event_key == nil or callback == nil then return end
    local l = Event.listeners[event_key]
    if not l then l = {}; Event.listeners[event_key] = l end
    l[#l + 1] = callback
end
Event.removeListener = function (event_key, callback)
    local l = Event.listeners[event_key]
    if not l then return end
    for i = #l, 1, -1 do if l[i] == callback then table.remove(l, i) end end
end
Event.trigger = function (event_key, event_data)
    local l = Event.listeners[event_key]
    if not l then return end
    for _, callback in ipairs(l) do callback(event_data) end
end
Event.addOnEntityCreatedListeners = function () end
Event.addOnEntityRemovedListeners = function () end
setmetatable(Event, { __index = function () return function () end end })

-- Minimal `script` stub. active_mods gates SE's compatibility branches; the rest
-- are load-time registration hooks the mod calls but that never fire headless.
script = {
    active_mods = { ["space-exploration"] = "0.7.57" },
    mod_name = "space-exploration",
    on_event = function () end,
    on_nth_tick = function () end,
    on_init = function () end,
    on_load = function () end,
    on_configuration_changed = function () end,
}
if SE_K2 then script.active_mods["Krastorio2"] = "2.0.19" end
defines = {}
defines.events = {}
defines.direction = {}
game.get_surface = function (surface)
    if surface == 1 then
        return {
            map_gen_settings = {
                autoplace_controls = {
                    -- Nauvis' radius is derived from this (universe.lua:615):
                    --   radius = 10000/6 * (6 + log2(1/frequency/6))
                    -- 1 is the map default and reproduces the in-game Nauvis radius
                    -- (5691.73). This value feeds no RNG, only the radius of Nauvis
                    -- and its derived haven moon.
                    ["planet-size"] = {
                        frequency = 1,
                    }
                },
                width = 2000000,
                height = 2000000,
            },
            find_entities_filtered = function () return {} end,
            regenerate_entity = function () return {} end,
        }
    else
        error('!!!')  -- FIXME
    end
end
is_testing_game = function () return false end
Meteor = {}
Meteor.schedule_meteor_shower = function () end
game.tick = 0
game.item_prototypes = {
  ["se-core-fragment-coal"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.coal"
      }
    }
  },
  ["se-core-fragment-copper-ore"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.copper-ore"
      }
    }
  },
  ["se-core-fragment-crude-oil"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.crude-oil"
      }
    }
  },
  ["se-core-fragment-iron-ore"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.iron-ore"
      }
    }
  },
  ["se-core-fragment-se-beryllium-ore"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.se-beryllium-ore"
      }
    }
  },
  ["se-core-fragment-se-cryonite"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.se-cryonite"
      }
    }
  },
  ["se-core-fragment-se-holmium-ore"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.se-holmium-ore"
      }
    }
  },
  ["se-core-fragment-se-iridium-ore"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.se-iridium-ore"
      }
    }
  },
  ["se-core-fragment-se-vitamelange"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.se-vitamelange"
      }
    }
  },
  ["se-core-fragment-se-vulcanite"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.se-vulcanite"
      }
    }
  },
  ["se-core-fragment-stone"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.stone"
      }
    }
  },
  ["se-core-fragment-uranium-ore"] = {
    localised_name = {
      "item-name.core-fragment",
      {
        "entity-name.uranium-ore"
      }
    }
  }
}
game.entity_prototypes = {
  coal = {
    autoplace_specification = true,
    name = "coal",
    type = "resource"
  },
  ["copper-ore"] = {
    autoplace_specification = true,
    name = "copper-ore",
    type = "resource"
  },
  ["crude-oil"] = {
    autoplace_specification = true,
    name = "crude-oil",
    type = "resource"
  },
  ["iron-ore"] = {
    autoplace_specification = true,
    name = "iron-ore",
    type = "resource"
  },
  ["se-beryllium-ore"] = {
    autoplace_specification = true,
    name = "se-beryllium-ore",
    type = "resource"
  },
  ["se-core-fragment-coal"] = {
    autoplace_specification = false,
    name = "se-core-fragment-coal",
    type = "resource"
  },
  ["se-core-fragment-coal-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-coal-sealed",
    type = "resource"
  },
  ["se-core-fragment-copper-ore"] = {
    autoplace_specification = false,
    name = "se-core-fragment-copper-ore",
    type = "resource"
  },
  ["se-core-fragment-copper-ore-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-copper-ore-sealed",
    type = "resource"
  },
  ["se-core-fragment-crude-oil"] = {
    autoplace_specification = false,
    name = "se-core-fragment-crude-oil",
    type = "resource"
  },
  ["se-core-fragment-crude-oil-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-crude-oil-sealed",
    type = "resource"
  },
  ["se-core-fragment-iron-ore"] = {
    autoplace_specification = false,
    name = "se-core-fragment-iron-ore",
    type = "resource"
  },
  ["se-core-fragment-iron-ore-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-iron-ore-sealed",
    type = "resource"
  },
  ["se-core-fragment-omni"] = {
    autoplace_specification = false,
    name = "se-core-fragment-omni",
    type = "resource"
  },
  ["se-core-fragment-omni-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-omni-sealed",
    type = "resource"
  },
  ["se-core-fragment-se-beryllium-ore"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-beryllium-ore",
    type = "resource"
  },
  ["se-core-fragment-se-beryllium-ore-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-beryllium-ore-sealed",
    type = "resource"
  },
  ["se-core-fragment-se-cryonite"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-cryonite",
    type = "resource"
  },
  ["se-core-fragment-se-cryonite-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-cryonite-sealed",
    type = "resource"
  },
  ["se-core-fragment-se-holmium-ore"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-holmium-ore",
    type = "resource"
  },
  ["se-core-fragment-se-holmium-ore-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-holmium-ore-sealed",
    type = "resource"
  },
  ["se-core-fragment-se-iridium-ore"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-iridium-ore",
    type = "resource"
  },
  ["se-core-fragment-se-iridium-ore-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-iridium-ore-sealed",
    type = "resource"
  },
  ["se-core-fragment-se-vitamelange"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-vitamelange",
    type = "resource"
  },
  ["se-core-fragment-se-vitamelange-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-vitamelange-sealed",
    type = "resource"
  },
  ["se-core-fragment-se-vulcanite"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-vulcanite",
    type = "resource"
  },
  ["se-core-fragment-se-vulcanite-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-se-vulcanite-sealed",
    type = "resource"
  },
  ["se-core-fragment-stone"] = {
    autoplace_specification = false,
    name = "se-core-fragment-stone",
    type = "resource"
  },
  ["se-core-fragment-stone-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-stone-sealed",
    type = "resource"
  },
  ["se-core-fragment-uranium-ore"] = {
    autoplace_specification = false,
    name = "se-core-fragment-uranium-ore",
    type = "resource"
  },
  ["se-core-fragment-uranium-ore-sealed"] = {
    autoplace_specification = false,
    name = "se-core-fragment-uranium-ore-sealed",
    type = "resource"
  },
  ["se-cryonite"] = {
    autoplace_specification = true,
    name = "se-cryonite",
    type = "resource"
  },
  ["se-holmium-ore"] = {
    autoplace_specification = true,
    name = "se-holmium-ore",
    type = "resource"
  },
  ["se-iridium-ore"] = {
    autoplace_specification = true,
    name = "se-iridium-ore",
    type = "resource"
  },
  ["se-methane-ice"] = {
    autoplace_specification = true,
    name = "se-methane-ice",
    type = "resource"
  },
  ["se-naquium-ore"] = {
    autoplace_specification = true,
    name = "se-naquium-ore",
    type = "resource"
  },
  ["se-vitamelange"] = {
    autoplace_specification = true,
    name = "se-vitamelange",
    type = "resource"
  },
  ["se-vulcanite"] = {
    autoplace_specification = true,
    name = "se-vulcanite",
    type = "resource"
  },
  ["se-water-ice"] = {
    autoplace_specification = true,
    name = "se-water-ice",
    type = "resource"
  },
  stone = {
    autoplace_specification = true,
    name = "stone",
    type = "resource"
  },
  ["uranium-ore"] = {
    autoplace_specification = true,
    name = "uranium-ore",
    type = "resource"
  }
}
-- Factorio 2.0 exposes prototype data through the global `prototypes` table
-- instead of game.*_prototypes. SE's resource generation reads it during
-- Universe.load_resource_data(). We back it with the hardcoded tables above and
-- implement the two filter helpers the generator actually calls.
prototypes = {
  item = game.item_prototypes,
  entity = game.entity_prototypes,
  autoplace_control = game.autoplace_control_prototypes,
  fluid = {},
  recipe = {},
  virtual_signal = {},
  space_location = {},
  asteroid_chunk = {},
  quality = {},
  mod_data = {
    -- Populated only by space-age / Krastorio2 compatibility at the data stage,
    -- both of which are inactive in a pure-SE install, so the data table is empty.
    -- The base resource placement rules live in Universe.resource_word_rules.
    [mod_prefix .. "universe-resource-word-rules"] = { data = {} },
  },
  custom_event = {},
}
-- SE calls this only as get_entity_filtered{{filter="type",type="resource"},{mode="and",filter="autoplace"}}
prototypes.get_entity_filtered = function ()
  local result = {}
  for name, proto in pairs(prototypes.entity) do
    if proto.type == "resource" and proto.autoplace_specification then
      result[name] = proto
    end
  end
  return result
end
prototypes.get_item_filtered = function () return {} end
-- SE registers custom events and looks them up at module load time. Events never
-- fire in this headless harness, so hand back a stub prototype for any name.
setmetatable(prototypes.custom_event, { __index = function () return { event_id = 0 } end })

-- Krastorio2: add its resources + placement rule to the prototype tables so the
-- resource pipeline enumerates them (see se_k2.lua).
if SE_K2 then
    require('se_k2').apply()
end

CoreMiner = {}
CoreMiner.update_zone_fragment_resources = function () end
CoreMiner.generate_core_seam_positions = function () end
settings = {}
settings.global = {}
settings.global["robot-attrition-factor"] = { value = 1 }  -- FIXME
settings.startup = {}
settings.startup["se-spawn-small-resources"] = { value = false }  -- FIXME

local MOD_NAME = 'space-exploration'
local MOD_VERSION = '0.7.57'
local MOD_TAG = MOD_NAME .. '_' .. MOD_VERSION

local FACTORIO_HOME
if os.getenv('FACTORIO_HOME') ~= nil then
    FACTORIO_HOME = os.getenv('FACTORIO_HOME')
elseif env.file_exists(env.join_path('.', 'mods', MOD_TAG .. ".zip")) then
    FACTORIO_HOME = '.'
else
    if env.operating_system() == "win32" then
        FACTORIO_HOME = env.join_path(os.getenv('APPDATA'), "Factorio")
    elseif env.operating_system() == "linux" then
        FACTORIO_HOME = env.join_path(os.getenv('HOME'), ".factorio")
    elseif env.operating_system() == "macos" then
        FACTORIO_HOME = env.join_path(os.getenv('HOME'), "Library", "Application Support", "factorio")
    else
        error("unknown operating system: " .. env.operating_system())
    end
end

do
    local archive = env.join_path(FACTORIO_HOME, "mods", MOD_TAG .. ".zip")
    if not env.file_exists(archive) then
        io.stderr:write("Could not find " .. archive .. "!\n")
        io.stderr:write("Set the FACTORIO_HOME environment variable or copy " .. MOD_TAG .. ".zip into the mods/ directory.\n")
        os.exit(1)
    end

    local function load_from_zip(path)
        local data = zip.extract(archive, MOD_TAG .. '/' .. path)
        return load(data, '__' .. MOD_NAME .. '__/' .. path)()
    end

    package.loaded['__space-exploration__/shared_util'] = load_from_zip('shared_util.lua')
    util = load_from_zip('scripts/util.lua')
    Util = util
    Shared = load_from_zip('shared.lua')
    -- Log used to be stubbed; SE 0.7 calls it heavily during generation so we load
    -- the real module (its output is disabled via is_debug_mode = false above).
    Log = load_from_zip('scripts/log.lua')
    UniverseRaw = load_from_zip('scripts/universe-raw.lua')
    Zone = load_from_zip('scripts/zone.lua')
    Zonelist = load_from_zip('scripts/zonelist.lua')
    Universe = load_from_zip('scripts/universe.lua')
    -- New in 0.7: guarantees the starting system's resources; called at the end
    -- of Universe.build and consumes the global universe RNG stream.
    UniverseHomesystem = load_from_zip('scripts/universe-homesystem.lua')
    -- make_validate_homesystem iterates guaranteed_special_types with pairs() and
    -- draws the universe RNG inside the loop, so its order must match the game.
    -- Factorio iterates in insertion order; register the literal's source order
    -- (universe-homesystem.lua:3) so det_pairs reproduces it. Runtime additions
    -- (e.g. K2's kr-imersite) are appended, which matches insertion order.
    require('det_pairs').set_order(UniverseHomesystem.guaranteed_special_types, {
        "haven", "vulcanite", "vitamelange", "iridium", "holmium", "cryonite", "beryllium", "methane",
    })
    Ancient = load_from_zip('scripts/ancient.lua')
    -- K2 compatibility: registers the on_resource_setting_load and
    -- on_homesystem_make listeners that adjust generation when K2 is active.
    if SE_K2 then
        Krastorio2 = load_from_zip('scripts/compatibility/krastorio2.lua')
    end
end

return se_env
