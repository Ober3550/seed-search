data:extend({
  {
    type = "noise-expression",
    name = "probe-rp48",
    expression = "random_penalty{x = x, y = y, source = 1, amplitude = 48}"
  },
  {
    type = "noise-expression",
    name = "probe-oil-prob",
    expression = "clamp(var('default-crude-oil-patches'), 0, 1) * random_penalty{x = x, y = y, source = 1, amplitude = 48}"
  }
})
