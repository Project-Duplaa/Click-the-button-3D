class_name ArbolInterconectadoDatos
extends RefCounted

## ArbolInterconectadoDatos - Catálogo y Generador del Grafo Web (Path of Exile Style)
## Contiene todos los nodos del árbol, sus posiciones espaciales 2D, costos y conexiones bidireccionales.

static func generar_arbol() -> Dictionary:
	var nodos: Dictionary = {}
	
	# Helper para crear y registrar nodos
	var registrar = func(id: String, nom: String, desc: String, rama: String, pos: Vector2, max_lvl: int,
			moneda: String, c_oro: int, c_clk: int, mult: float, stat: String, val_lvl: float,
			conns: Array, keystone: bool = false, ico: String = "⭐") -> SkillNodeData:
		var n = SkillNodeData.new()
		n.id = id
		n.nombre = nom
		n.descripcion = desc
		n.rama = rama
		n.posicion = pos
		n.nivel_max = max_lvl
		n.tipo_moneda = moneda
		n.costo_base_monedas = c_oro
		n.costo_base_clicks = c_clk
		n.multiplicador_costo = mult
		n.estadistica_afectada = stat
		n.valor_por_nivel = val_lvl
		var conns_typed: Array[String] = []
		for c in conns:
			conns_typed.append(str(c))
		n.nodos_conectados = conns_typed
		n.es_keystone = keystone
		n.icono = ico
		nodos[id] = n
		return n

	# ==========================================================================
	# NODO CENTRAL: EL NÚCLEO PRIMORDIAL (Punto de partida desbloqueado)
	# ==========================================================================
	var centro = registrar.call(
		"nodo_origen", "Núcleo del Coliseo",
		"El centro primordial de resonancia. Desbloquea los caminos hacia las tres constelaciones maestras.",
		"central", Vector2(0, 0), 1, "oro", 0, 0, 1.0, "origen", 1.0,
		["clk_dano_1", "srv_salud_1", "eco_multiplicador_1"], false, "💠"
	)
	centro.nivel_actual = 1 # Ya desbloqueado de inicio

	# ==========================================================================
	# RAMA AZUL: PODER ACTIVO (MECÁNICAS DE CLICK) - Noroeste / Oeste
	# ==========================================================================
	registrar.call(
		"clk_dano_1", "Fuerza de Clic",
		"Aumenta el daño de impacto directo infligido al hacer clic sobre enemigos o el botón móvil.",
		"azul", Vector2(-160, -90), 5, "clics", 0, 6, 1.45, "dano_clic_pct", 25.0,
		["nodo_origen", "clk_aoe_1", "clk_crit_1"], false, "👆"
	)
	
	registrar.call(
		"clk_aoe_1", "Área de Impacto (AoE Clic)",
		"Convierte cada clic en una onda expansiva sónica que daña y empuja a los enemigos cercanos.",
		"azul", Vector2(-320, -70), 5, "clics", 0, 12, 1.50, "radio_aoe_clic", 1.8,
		["clk_dano_1", "clk_eco_1", "puente_azul_verde"], false, "💥"
	)

	registrar.call(
		"clk_crit_1", "Crítico Manual",
		"Otorga probabilidad y multiplicador de Golpe Crítico manual a cada pulsación de clic (+8% prob, x2.2 dmg).",
		"azul", Vector2(-240, -230), 5, "clics", 0, 15, 1.52, "critico_clic_prob", 8.0,
		["clk_dano_1", "clk_eco_1", "puente_dorada_azul"], false, "🎯"
	)

	registrar.call(
		"clk_eco_1", "Eco de Clic",
		"Probabilidad de que una sola pulsación de clic resuene y se repita automáticamente 1 o 2 veces extra.",
		"azul", Vector2(-420, -190), 5, "clics", 0, 25, 1.58, "eco_clic_prob", 20.0,
		["clk_aoe_1", "clk_crit_1", "clk_sinergia_keystone"], false, "🔁"
	)

	registrar.call(
		"clk_sinergia_keystone", "Keystone: Sinergia Cinética",
		"[KEYSTONE MAYOR] Cada 6 clics acumulados se desencadena un pulso cinético masivo que recarga de inmediato tus armas automáticas y barre la arena.",
		"azul", Vector2(-580, -160), 1, "ambas", 60, 45, 1.0, "sinergia_cinetica", 1.0,
		["clk_eco_1"], true, "⚡"
	)

	# ==========================================================================
	# RAMA VERDE: SUPERVIVENCIA Y CONTROL (SURVIVORS) - Sur / Suroeste
	# ==========================================================================
	registrar.call(
		"srv_salud_1", "Salud y Armadura",
		"Refuerza la constitución del gladiador: +20 HP de Vida Máxima y +6% de mitigación pasiva de daño.",
		"verde", Vector2(0, 160), 5, "oro", 10, 0, 1.40, "salud_maxima", 20.0,
		["nodo_origen", "srv_vel_1", "srv_iman_1"], false, "🛡️"
	)

	registrar.call(
		"srv_vel_1", "Paso de Viento",
		"Aumenta los metros por segundo base de desplazamiento para esquivar y maniobrar entre las hordas.",
		"verde", Vector2(-160, 270), 5, "oro", 18, 0, 1.48, "velocidad_pct", 10.0,
		["srv_salud_1", "srv_regen_1", "puente_azul_verde"], false, "👟"
	)

	registrar.call(
		"srv_iman_1", "Rango de Recolección (Imán)",
		"Incrementa el radio de atracción magnética para aspirar monedas y orbes de XP a mayor distancia.",
		"verde", Vector2(160, 270), 5, "oro", 20, 0, 1.45, "radio_iman", 3.0,
		["srv_salud_1", "srv_regen_1", "puente_verde_dorada"], false, "🧲"
	)

	registrar.call(
		"srv_regen_1", "Regeneración y Drenaje",
		"Recupera +1.5 HP por segundo continuamente y sana +3 HP de inmediato por cada enemigo abatido.",
		"verde", Vector2(0, 390), 5, "oro", 35, 0, 1.55, "regen_vida", 1.5,
		["srv_vel_1", "srv_iman_1", "srv_vidas_keystone"], false, "💖"
	)

	registrar.call(
		"srv_vidas_keystone", "Keystone: Segunda Oportunidad",
		"[KEYSTONE MAYOR] Otorga +1 Vida / Reaparición adicional permanente por partida y una onda restauradora que despeja el Coliseo al caer.",
		"verde", Vector2(0, 540), 1, "ambas", 70, 40, 1.0, "vidas_extra", 1.0,
		["srv_regen_1"], true, "✝️"
	)

	# ==========================================================================
	# RAMA DORADA: AUTOMATIZACIÓN Y ECONOMÍA (PASIVO / IDLE) - Noreste / Este
	# ==========================================================================
	registrar.call(
		"eco_multiplicador_1", "Multiplicador de Oro y XP",
		"Aumenta en +25% los recursos de oro y experiencia obtenidos por cada enemigo abatido en el combate.",
		"dorada", Vector2(160, -90), 5, "oro", 12, 0, 1.45, "multiplicador_recursos_pct", 25.0,
		["nodo_origen", "eco_cadencia_1", "eco_autoclick_1"], false, "🪙"
	)

	registrar.call(
		"eco_cadencia_1", "Cadencia de Armas",
		"Acelera el enfriamiento de las armas y habilidades automáticas del personaje en +12% de velocidad.",
		"dorada", Vector2(320, -70), 5, "oro", 22, 0, 1.50, "cadencia_armas_pct", 12.0,
		["eco_multiplicador_1", "eco_proyectiles_1", "puente_verde_dorada"], false, "⚔️"
	)

	registrar.call(
		"eco_autoclick_1", "Autoclicker Interno",
		"Mecanismo rúnico autónomo: genera pulsaciones de clic automáticas continuas por segundo sin intervención manual.",
		"dorada", Vector2(240, -230), 5, "clics", 0, 20, 1.55, "autoclick_tasa", 1.0,
		["eco_multiplicador_1", "eco_proyectiles_1", "puente_dorada_azul"], false, "⏳"
	)

	registrar.call(
		"eco_proyectiles_1", "Expansión Balística y Área",
		"Añade proyectiles extra a los disparos y ensancha las áreas de impacto de las armas pasivas.",
		"dorada", Vector2(420, -190), 5, "ambas", 35, 25, 1.58, "proyectiles_extra", 1.0,
		["eco_cadencia_1", "eco_autoclick_1", "eco_interes_keystone"], false, "🏹"
	)

	registrar.call(
		"eco_interes_keystone", "Keystone: Interés por Oleada",
		"[KEYSTONE MAYOR] Al completar cada oleada, recibes un dividendo del +15% de oro adicional calculado sobre el oro total que tengas acumulado.",
		"dorada", Vector2(580, -160), 1, "ambas", 80, 50, 1.0, "interes_oleada_pct", 15.0,
		["eco_proyectiles_1"], true, "👑"
	)

	# ==========================================================================
	# PUENTES INTERCONECTADOS (ESTILO PATH OF EXILE CONSTELLATION WEB)
	# ==========================================================================
	registrar.call(
		"puente_azul_verde", "Canal de Impulso",
		"Nodo de enlace entre Clics y Supervivencia: cada clic exitoso otorga un impulso temporal de velocidad de movimiento.",
		"hibrido", Vector2(-270, 120), 3, "ambas", 25, 20, 1.50, "impulso_mov_clic", 15.0,
		["clk_aoe_1", "srv_vel_1"], false, "🌀"
	)

	registrar.call(
		"puente_verde_dorada", "Recolección Alquímica",
		"Nodo de enlace entre Supervivencia y Economía: los orbes de XP recolectados generan un porcentaje de oro instantáneo.",
		"hibrido", Vector2(270, 120), 3, "ambas", 25, 20, 1.50, "xp_a_oro_pct", 20.0,
		["srv_iman_1", "eco_cadencia_1"], false, "💰"
	)

	registrar.call(
		"puente_dorada_azul", "Resonancia Alquímica",
		"Nodo de enlace entre Economía y Clics: los clics manuales y del autoclicker generan oro proporcional a tu daño.",
		"hibrido", Vector2(0, -320), 3, "ambas", 30, 25, 1.55, "clic_genera_oro_pct", 15.0,
		["clk_crit_1", "eco_autoclick_1", "keystone_apex"], false, "🔮"
	)

	registrar.call(
		"keystone_apex", "Keystone: Ascensión de la Constelación",
		"[KEYSTONE SUPREMO] La culminación del Árbol Interconectado: +50% Daño Total, regeneración acelerada y todos los clics duplican su valor.",
		"hibrido", Vector2(0, -480), 1, "ambas", 120, 90, 1.0, "ascension_suprema", 1.0,
		["puente_dorada_azul"], true, "🏆"
	)

	# Asegurar bidireccionalidad de todas las conexiones en el grafo
	for n_id in nodos.keys():
		var nodo = nodos[n_id]
		for vecino_id in nodo.nodos_conectados:
			if nodos.has(vecino_id):
				var vecino = nodos[vecino_id]
				if not vecino.nodos_conectados.has(n_id):
					vecino.nodos_conectados.append(n_id)

	return nodos

static func es_nodo_desbloqueable(nodo: SkillNodeData, todos_los_nodos: Dictionary) -> bool:
	# Si ya está comprado al máximo, no es "desbloqueable para compra", está maxeado
	if nodo.esta_maxeado():
		return false
	# Si ya tiene al menos nivel 1, siempre puede seguir subiendo de nivel
	if nodo.esta_comprado():
		return true
	# Si es el origen central
	if nodo.id == "nodo_origen":
		return true
	# Está desbloqueable si AL MENOS UN vecino conectado está comprado
	for vecino_id in nodo.nodos_conectados:
		if todos_los_nodos.has(vecino_id):
			var v = todos_los_nodos[vecino_id]
			if v.esta_comprado():
				return true
	return false

static func obtener_estado_nodo(nodo: SkillNodeData, todos_los_nodos: Dictionary) -> String:
	if nodo.esta_maxeado():
		return "maxeado"
	elif nodo.esta_comprado():
		return "comprado"
	elif es_nodo_desbloqueable(nodo, todos_los_nodos):
		return "desbloqueable"
	else:
		return "bloqueado"
