class_name StagePhysics
extends RefCounted

## Física de escenario pura y determinista: paredes (clamp) y separación de pushboxes.
## Sin nodos -> testeable en unidad.

## Mantiene x dentro de [left, right] (paredes del escenario).
static func clamp_wall(x: float, left: float, right: float) -> float:
	return clampf(x, left, right)

## Separa dos posiciones si están más cerca que min_sep (pushbox). Devuelve [x1', x2'].
## No pueden solaparse: se empujan mutuamente a partes iguales.
static func separate(x1: float, x2: float, min_sep: float) -> Array:
	var dx: float = x2 - x1
	var dist: float = abs(dx)
	if dist >= min_sep:
		return [x1, x2]
	var push: float = (min_sep - dist) / 2.0
	var dir: float = 1.0 if dx >= 0.0 else -1.0
	return [x1 - dir * push, x2 + dir * push]
