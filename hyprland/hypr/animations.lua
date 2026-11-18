-- Tokens de movimento: docs/design-system.md#movimento
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("decelerate", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("accelerate", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })

-- Em spring o speed nao define a duracao; quem define e stiffness/dampening.
-- zeta ~= 1 (criticamente amortecida): assenta em ~200ms sem passar do ponto.
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 880, dampening = 59 })

hl.animation({ leaf = "global", enabled = true, speed = 2.5, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 1.5, bezier = "standard" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, spring = "snappy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, spring = "snappy", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "accelerate", style = "popin 90%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "decelerate" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1, bezier = "accelerate" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "standard" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "decelerate", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "accelerate", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.5, bezier = "decelerate" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1, bezier = "accelerate" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "decelerate", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.5, bezier = "decelerate", style = "slidefadevert 15%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 2.5, bezier = "standard" })
