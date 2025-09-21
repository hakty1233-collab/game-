extends Node

# Typed recipes so CraftingUI knows what it gets
# Example recipe:
# {
#   "name":"Cooked Fish", "station":"Oven",
#   "inputs":{"Raw Fish":1}, "output":{"Cooked Fish":1},
#   "skill":"Cooking", "xp":15
# }
var recipes: Array[Dictionary] = [
	{
		"name":"Cooked Fish", "station":"Oven",
		"inputs":{"Raw Fish":1}, "output":{"Cooked Fish":1},
		"skill":"Cooking", "xp":15
	},
	{
		"name":"Copper Bar", "station":"Forge",
		"inputs":{"Copper Ore":1}, "output":{"Copper Bar":1},
		"skill":"Smithing", "xp":30
	},
	{
		"name":"Plank", "station":"Workbench",
		"inputs":{"Log":2}, "output":{"Plank":1},
		"skill":"Smithing", "xp":12
	},
	{
		"name":"Iron Bar", "station":"Forge",
		"inputs":{"Iron Ore":1}, "output":{"Iron Bar":1},
		"skill":"Smithing", "xp":12
	}
]

func get_recipes_for_station(station_type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in recipes:
		if String(r.get("station","")) == station_type:
			out.append(r)
	return out
