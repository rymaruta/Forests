extends RefCounted
class_name ForestsPalette
## Forests 色。朝の森：落ち着いた緑と温かい土。


const SKY_TOP := Color(0.58, 0.74, 0.9)
const SKY_HORIZON := Color(0.97, 0.92, 0.8)
const SUN := Color(1.0, 0.96, 0.88)
const FILL_COOL := Color(0.78, 0.86, 0.92)
const FILL_WARM := Color(1.0, 0.9, 0.72)
const BOUNCE_GREEN := Color(0.52, 0.6, 0.42)

const GRASS_A := Color(0.4, 0.52, 0.3)
const GRASS_B := Color(0.46, 0.58, 0.34)
const DIRT := Color(0.48, 0.38, 0.28)
const STONE := Color(0.42, 0.4, 0.36)
const STONE_MOSS := Color(0.36, 0.4, 0.3)

const BARK_WARM := Color(0.42, 0.3, 0.2)
const BARK_COOL := Color(0.34, 0.26, 0.18)
const LEAF_SUN := Color(0.38, 0.54, 0.3)
const LEAF_SHADE := Color(0.22, 0.36, 0.2)
const PINE := Color(0.26, 0.42, 0.3)
const PINE_DARK := Color(0.16, 0.28, 0.18)

const PETAL_SUN := Color(0.94, 0.78, 0.42)
const PETAL_ROSE := Color(0.9, 0.55, 0.6)
const PETAL_LILAC := Color(0.72, 0.68, 0.88)
const PETAL_CREAM := Color(0.96, 0.93, 0.8)
const PETAL_SKY := Color(0.62, 0.78, 0.9)
const PETAL_CORAL := Color(0.92, 0.58, 0.46)

const WATER_SHALLOW := Color(0.3, 0.58, 0.6)
const WATER_DEEP := Color(0.14, 0.38, 0.44)

const SKIN := Color(0.94, 0.84, 0.74)
const CLOTH := Color(0.34, 0.54, 0.5)
const CLOTH_DARK := Color(0.2, 0.36, 0.34)
const HAT := Color(0.7, 0.54, 0.34)
const SCARF := Color(0.84, 0.5, 0.34)
const HAIR := Color(0.28, 0.18, 0.12)
const BOOT := Color(0.32, 0.22, 0.16)

const PLASTER := Color(0.86, 0.8, 0.68)
const TIMBER := Color(0.4, 0.28, 0.18)
const ROOF_TILE := Color(0.52, 0.36, 0.28)
const ROOF_SHADOW := Color(0.34, 0.22, 0.18)


static func petals() -> Array:
	return [PETAL_SUN, PETAL_ROSE, PETAL_LILAC, PETAL_CREAM, PETAL_SKY, PETAL_CORAL]
