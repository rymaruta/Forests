extends RefCounted
class_name ForestsPalette
## Forests 専用色設計。全部ここで決める。

# 空・光
const SKY_TOP := Color(0.42, 0.68, 0.9)
const SKY_HORIZON := Color(0.98, 0.88, 0.7)
const SUN := Color(1.0, 0.96, 0.88)
const FILL_COOL := Color(0.7, 0.84, 1.0)
const FILL_WARM := Color(1.0, 0.86, 0.62)
const BOUNCE_GREEN := Color(0.55, 0.72, 0.42)

# 地面
const GRASS_A := Color(0.34, 0.58, 0.3)
const GRASS_B := Color(0.42, 0.64, 0.34)
const DIRT := Color(0.48, 0.36, 0.24)
const STONE := Color(0.58, 0.54, 0.46)
const STONE_MOSS := Color(0.42, 0.48, 0.36)

# 樹皮・葉
const BARK_WARM := Color(0.46, 0.3, 0.18)
const BARK_COOL := Color(0.36, 0.24, 0.16)
const LEAF_SUN := Color(0.30, 0.54, 0.28)
const LEAF_SHADE := Color(0.12, 0.30, 0.16)
const PINE := Color(0.18, 0.40, 0.28)
const PINE_DARK := Color(0.08, 0.22, 0.14)

# 花
const PETAL_SUN := Color(0.98, 0.74, 0.38)
const PETAL_ROSE := Color(0.95, 0.52, 0.64)
const PETAL_LILAC := Color(0.72, 0.68, 0.96)
const PETAL_CREAM := Color(0.96, 0.93, 0.72)
const PETAL_SKY := Color(0.62, 0.82, 0.95)
const PETAL_CORAL := Color(0.95, 0.58, 0.45)

# 水
const WATER_SHALLOW := Color(0.42, 0.78, 0.74)
const WATER_DEEP := Color(0.14, 0.42, 0.52)

# 旅人
const SKIN := Color(0.96, 0.86, 0.74)
const CLOTH := Color(0.28, 0.58, 0.52)
const CLOTH_DARK := Color(0.16, 0.34, 0.3)
const HAT := Color(0.72, 0.52, 0.28)
const SCARF := Color(0.9, 0.52, 0.3)
const HAIR := Color(0.28, 0.17, 0.1)
const BOOT := Color(0.32, 0.2, 0.14)


static func petals() -> Array:
	return [PETAL_SUN, PETAL_ROSE, PETAL_LILAC, PETAL_CREAM, PETAL_SKY, PETAL_CORAL]
