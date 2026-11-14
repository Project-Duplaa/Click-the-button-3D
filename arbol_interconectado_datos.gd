class_name ArbolInterconectadoDatos
extends RefCounted

## ArbolInterconectadoDatos - Catálogo y Generador del Grafo Web (Estilo Path of Exile / Nodebreaker)
## Constelación masiva de 55 nodos interconectados en 5 Tiers.
## Desarrollado para progresión metaprogresiva incremental y roguelike.

static func generar_arbol() -> Dictionary:
	var nodos: Dictionary = {}
	
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
	# NODO CENTRAL: EL NÚCLEO PRIMORDIAL
	# ==========================================================================
	registrar.call(
		"nodo_origen", "Núcleo del Coliseo",
		"Punto primordial de resonancia.",
		"central", Vector2(0, 0), 1, "oro", 0, 0, 1.0, "origen", 1.0,
		["clk_fuerza_1", "clk_pulso_1", "srv_salud_1", "srv_armadura_1", "eco_oro_1", "eco_xp_1"], false, "💠"
	)

	# ==========================================================================
	# RAMA AZUL: PODER ACTIVO Y MECÁNICAS DE CLIC (NOROESTE)
	# ==========================================================================
	registrar.call(
		"clk_fuerza_1", "Fuerza de Clic",
		"+20% daño por clic",
		"azul", Vector2(-160, -90), 5, "clics", 0, 10, 1.38, "dano_clic_pct", 20.0,
		["nodo_origen", "clk_pulso_1", "clk_aoe_1"], false, "👆"
	)

	registrar.call(
		"clk_pulso_1", "Pulsación Rúnica",
		"+1 clic generado por golpe",
		"azul", Vector2(-120, -180), 5, "clics", 0, 14, 1.4, "clics_por_pulsacion", 1.0,
		["nodo_origen", "clk_fuerza_1", "clk_crit_1", "pnt_dorada_azul_1", "clk_impulso_1"], false, "⚡"
	)

	registrar.call(
		"clk_aoe_1", "Onda Sónica Expansiva",
		"+1.5m radio detonación por clic",
		"azul", Vector2(-310, -80), 5, "clics", 0, 45, 1.45, "radio_aoe_clic", 1.5,
		["clk_fuerza_1", "clk_eco_1", "pnt_azul_verde_1"], false, "💥"
	)

	registrar.call(
		"clk_crit_1", "Precisión Quirúrgica",
		"+6% prob golpe crítico manual",
		"azul", Vector2(-270, -220), 5, "clics", 0, 50, 1.48, "critico_clic_prob", 6.0,
		["clk_pulso_1", "clk_filo_1", "clk_eco_1"], false, "🎯"
	)

	registrar.call(
		"clk_impulso_1", "Onda Repulsiva",
		"+25% retroceso y sprint al pulsar",
		"azul", Vector2(-200, -320), 4, "clics", 0, 40, 1.45, "empuje_clic_pct", 25.0,
		["clk_pulso_1", "clk_anomalia_1", "pnt_dorada_azul_1"], false, "🌀"
	)

	registrar.call(
		"clk_eco_1", "Eco Resonante",
		"+15% prob duplicar clic automáticamente",
		"azul", Vector2(-470, -140), 4, "clics", 0, 110, 1.52, "eco_clic_prob", 15.0,
		["clk_aoe_1", "clk_crit_1", "clk_sobrecarga_1", "pnt_azul_verde_2"], false, "🔁"
	)

	registrar.call(
		"clk_filo_1", "Impacto Devastador",
		"+45% multiplicador crítico de clic",
		"azul", Vector2(-430, -280), 4, "clics", 0, 130, 1.55, "dano_critico_pct", 45.0,
		["clk_crit_1", "clk_frenesi_1", "clk_sobrecarga_1"], false, "🗡️"
	)

	registrar.call(
		"clk_anomalia_1", "Sintonizador de Grietas",
		"+15% frecuencia y botín de anomalías rúnicas",
		"azul", Vector2(-350, -420), 3, "clics", 0, 120, 1.5, "prob_anomalia_pct", 15.0,
		["clk_impulso_1", "clk_penetracion_1", "pnt_dorada_azul_2"], false, "🌌"
	)

	registrar.call(
		"clk_sobrecarga_1", "Tormenta de Clics",
		"Cada 6 clics desata rayo arcano global (+80 dmg)",
		"azul", Vector2(-650, -190), 3, "clics", 0, 380, 1.65, "dano_sobrecarga", 80.0,
		["clk_eco_1", "clk_filo_1", "clk_keystone_cataclismo", "pnt_azul_verde_3"], false, "🌩️"
	)

	registrar.call(
		"clk_frenesi_1", "Trance Hipercinético",
		"Clics otorgan +12% daño acumulativo por 3s",
		"azul", Vector2(-600, -360), 3, "clics", 0, 420, 1.65, "frenesi_velocidad_clic", 12.0,
		["clk_filo_1", "clk_penetracion_1", "clk_keystone_soberania"], false, "🔥"
	)

	registrar.call(
		"clk_penetracion_1", "Ruptura Dimensional",
		"La onda de clic ignora 25% armadura enemiga",
		"azul", Vector2(-500, -510), 3, "clics", 0, 360, 1.62, "penetracion_clic", 25.0,
		["clk_anomalia_1", "clk_frenesi_1", "pnt_dorada_azul_3"], false, "🕳️"
	)

	registrar.call(
		"clk_keystone_cataclismo", "Keystone: Cataclismo Cinético",
		"Cada 8 clics resetea CDs de armas y barre la arena",
		"azul", Vector2(-880, -180), 1, "clics", 0, 1250, 1.0, "keystone_cataclismo", 1.0,
		["clk_sobrecarga_1"], true, "⚡⚡"
	)

	registrar.call(
		"clk_keystone_soberania", "Keystone: Soberanía del Clic Rúnico",
		"Clics escalan con 200% del daño del arma principal",
		"azul", Vector2(-820, -450), 1, "ambas", 450, 1500, 1.0, "keystone_soberania", 1.0,
		["clk_frenesi_1"], true, "👑👆"
	)

	# ==========================================================================
	# RAMA VERDE: SUPERVIVENCIA, VIDAS Y TANQUE (SUR)
	# ==========================================================================
	registrar.call(
		"srv_salud_1", "Constitución Heroica",
		"+25 HP Vida Máxima por nivel",
		"verde", Vector2(0, 160), 5, "oro", 12, 0, 1.35, "salud_maxima", 25.0,
		["nodo_origen", "srv_armadura_1", "srv_vel_1", "srv_iman_1"], false, "❤️"
	)

	registrar.call(
		"srv_armadura_1", "Coraza de Gladiador",
		"+6% mitigación pasiva de daño",
		"verde", Vector2(-100, 190), 5, "oro", 15, 0, 1.38, "mitigacion_dano_pct", 6.0,
		["nodo_origen", "srv_salud_1", "srv_escudo_1"], false, "🛡️"
	)

	registrar.call(
		"srv_vel_1", "Paso de Viento",
		"+8% velocidad de movimiento",
		"verde", Vector2(-180, 310), 5, "oro", 45, 0, 1.45, "velocidad_mov_pct", 8.0,
		["srv_salud_1", "srv_regen_1", "pnt_azul_verde_1"], false, "👟"
	)

	registrar.call(
		"srv_iman_1", "Magnetismo Espectral",
		"+2.5m radio imán de orbes y oro",
		"verde", Vector2(140, 290), 5, "oro", 50, 0, 1.46, "radio_iman", 2.5,
		["srv_salud_1", "srv_regen_1", "pnt_verde_dorada_1", "srv_iframes_1"], false, "🧲"
	)

	registrar.call(
		"srv_escudo_1", "Escudo de Almas (Aegis)",
		"Absorbe +35 de daño antes de perder HP",
		"verde", Vector2(-60, 360), 4, "oro", 60, 0, 1.48, "escudo_almas", 35.0,
		["srv_armadura_1", "srv_vampirismo_1", "srv_regen_1", "srv_vida_extra_1"], false, "🔰"
	)

	registrar.call(
		"srv_vida_extra_1", "Segunda Oportunidad (Vidas Extras)",
		"+1 Vida / Reaparición adicional en combate por nivel",
		"verde", Vector2(-90, 520), 3, "ambas", 180, 100, 1.6, "vidas_extra", 1.0,
		["srv_escudo_1", "srv_regen_1", "srv_fortaleza_1"], false, "💖👑"
	)

	registrar.call(
		"srv_regen_1", "Aliento Vital Continuo",
		"+1.5 HP/s regenerado continuamente",
		"verde", Vector2(0, 480), 4, "oro", 140, 0, 1.52, "regen_vida_seg", 1.5,
		["srv_vel_1", "srv_iman_1", "srv_escudo_1", "srv_fortaleza_1", "srv_vida_extra_1"], false, "💖"
	)

	registrar.call(
		"srv_vampirismo_1", "Festín Sangriento (Vampirismo)",
		"+4 HP restaurados por cada enemigo abatido",
		"verde", Vector2(-190, 490), 4, "oro", 160, 0, 1.55, "vida_por_baja", 4.0,
		["srv_escudo_1", "srv_desquite_1", "pnt_azul_verde_2"], false, "🩸"
	)

	registrar.call(
		"srv_iframes_1", "Evasión Espiritual",
		"+0.5s de invulnerabilidad tras recibir impacto",
		"verde", Vector2(170, 480), 3, "oro", 150, 0, 1.5, "invulnerable_extra_seg", 0.5,
		["srv_iman_1", "srv_resistencia_1", "pnt_verde_dorada_2"], false, "🕊️"
	)

	registrar.call(
		"srv_fortaleza_1", "Bastión de Titán",
		"+35 armadura plana y +60 HP bajo 35% de vida",
		"verde", Vector2(0, 680), 3, "oro", 440, 0, 1.65, "armadura_plana", 35.0,
		["srv_regen_1", "srv_vida_extra_1", "srv_desquite_1", "srv_resistencia_1", "srv_keystone_segunda_vida"], false, "🏰"
	)

	registrar.call(
		"srv_desquite_1", "Retribución de Espinas",
		"Devuelve +40% del daño recibido en cono",
		"verde", Vector2(-230, 640), 3, "oro", 390, 0, 1.6, "reflejo_dano_pct", 40.0,
		["srv_vampirismo_1", "srv_fortaleza_1", "srv_keystone_coloso", "pnt_azul_verde_3"], false, "🌵"
	)

	registrar.call(
		"srv_resistencia_1", "Firmeza Inflexible",
		"Inmunidad a empuje y +25% mitigación ante jefes",
		"verde", Vector2(220, 640), 3, "oro", 410, 0, 1.62, "resistencia_estados_pct", 25.0,
		["srv_iframes_1", "srv_fortaleza_1", "srv_keystone_aliento", "pnt_verde_dorada_3"], false, "🗿"
	)

	registrar.call(
		"srv_keystone_segunda_vida", "Keystone: Segunda Oportunidad Sagrada",
		"+1 Vida extra y nova sagrada aniquiladora al caer",
		"verde", Vector2(0, 940), 1, "ambas", 1400, 650, 1.0, "keystone_segunda_vida", 1.0,
		["srv_fortaleza_1"], true, "✝️"
	)

	registrar.call(
		"srv_keystone_coloso", "Keystone: Pacto Inmortal del Coloso",
		"25% de max HP se vuelve armadura; +80% dmg bajo 50% HP",
		"verde", Vector2(-240, 890), 1, "oro", 1800, 0, 1.0, "keystone_coloso", 1.0,
		["srv_desquite_1"], true, "🗿✨"
	)

	registrar.call(
		"srv_keystone_aliento", "Keystone: Último Aliento",
		"Al sufrir daño fatal sobrevive a 1 HP con 3.5s de i-frames",
		"verde", Vector2(240, 890), 1, "ambas", 1200, 500, 1.0, "keystone_aliento", 1.0,
		["srv_resistencia_1"], true, "🔥❤️"
	)

	# ==========================================================================
	# RAMA DORADA: AUTOMATIZACIÓN, ARSENAL Y ECONOMÍA (NORESTE)
	# ==========================================================================
	registrar.call(
		"eco_oro_1", "Tributo de Sangre",
		"+20% oro de bajas y cofres",
		"dorada", Vector2(160, -90), 5, "oro", 12, 0, 1.36, "oro_por_baja_pct", 20.0,
		["nodo_origen", "eco_xp_1", "eco_cadencia_1"], false, "🪙"
	)

	registrar.call(
		"eco_xp_1", "Sabiduría del Coliseo",
		"+18% ganancia de experiencia",
		"dorada", Vector2(120, -180), 5, "oro", 16, 0, 1.38, "xp_ganada_pct", 18.0,
		["nodo_origen", "eco_oro_1", "eco_autoclick_1", "pnt_dorada_azul_1"], false, "📜"
	)

	registrar.call(
		"eco_cadencia_1", "Cadencia Bélica",
		"+10% cadencia de armas automáticas",
		"dorada", Vector2(310, -80), 5, "oro", 55, 0, 1.46, "cadencia_armas_pct", 10.0,
		["eco_oro_1", "eco_proyectiles_1", "pnt_verde_dorada_1"], false, "⚔️"
	)

	registrar.call(
		"eco_autoclick_1", "Autoclicker Rúnico",
		"+0.6 clics automáticos por segundo",
		"dorada", Vector2(260, -220), 5, "clics", 0, 60, 1.48, "autoclick_tasa", 0.6,
		["eco_xp_1", "eco_proyectiles_1", "eco_minero_1"], false, "⏳"
	)

	registrar.call(
		"eco_proyectiles_1", "Calibre Expandido",
		"+15% daño a proyectiles y ataques automáticos",
		"dorada", Vector2(220, -320), 4, "oro", 65, 0, 1.48, "dano_armas_pct", 15.0,
		["eco_cadencia_1", "eco_autoclick_1", "eco_multidisparo_1", "eco_perforacion_1"], false, "🏹"
	)

	registrar.call(
		"eco_multidisparo_1", "Abanico Balístico",
		"+1 proyectil extra en abanico",
		"dorada", Vector2(460, -140), 3, "ambas", 160, 95, 1.55, "proyectiles_extra", 1.0,
		["eco_proyectiles_1", "eco_alcance_1", "pnt_verde_dorada_2"], false, "🎆"
	)

	registrar.call(
		"eco_perforacion_1", "Balas Perforantes",
		"+1 objetivo perforado por proyectiles",
		"dorada", Vector2(420, -280), 3, "oro", 150, 0, 1.52, "perforacion_armas", 1.0,
		["eco_proyectiles_1", "eco_reloj_1", "eco_minero_1"], false, "🎯💥"
	)

	registrar.call(
		"eco_minero_1", "Tributo de Bóveda Pasiva",
		"+1.5 de oro generado por segundo",
		"dorada", Vector2(350, -420), 4, "oro", 170, 0, 1.54, "oro_pasivo_seg", 1.5,
		["eco_autoclick_1", "eco_perforacion_1", "eco_dividendos_1", "pnt_dorada_azul_2"], false, "⛏️"
	)

	registrar.call(
		"eco_alcance_1", "Órbita Letal",
		"+25% radio de alcance y adquisición de blancos",
		"dorada", Vector2(640, -190), 3, "oro", 460, 0, 1.64, "rango_ataque_pct", 25.0,
		["eco_multidisparo_1", "eco_reloj_1", "eco_keystone_usura"], false, "🌐"
	)

	registrar.call(
		"eco_reloj_1", "Crono-Resonancia",
		"+40% cadencia y daño a los autoclickers autónomos",
		"dorada", Vector2(590, -360), 3, "clics", 0, 480, 1.68, "autoclick_overclock_pct", 40.0,
		["eco_perforacion_1", "eco_alcance_1", "eco_dividendos_1", "eco_keystone_fabrica", "pnt_verde_dorada_3"], false, "⏱️"
	)

	registrar.call(
		"eco_dividendos_1", "Fondo de Usura Oleada",
		"+6% de interés por oleada completada",
		"dorada", Vector2(490, -510), 3, "oro", 520, 0, 1.65, "interes_oleada_pct", 6.0,
		["eco_minero_1", "eco_reloj_1", "pnt_dorada_azul_3"], false, "📈"
	)

	registrar.call(
		"eco_keystone_usura", "Keystone: Usura y Riqueza Infinita",
		"+20% interés oleada; +2.5% daño global por cada 100 de oro",
		"dorada", Vector2(870, -180), 1, "oro", 2200, 0, 1.0, "keystone_usura", 1.0,
		["eco_alcance_1"], true, "🏦👑"
	)

	registrar.call(
		"eco_keystone_fabrica", "Keystone: Fábrica Autónoma del Coliseo",
		"Autoclicker a 6 clics/s; heredan 100% de los efectos del clic manual",
		"dorada", Vector2(810, -440), 1, "ambas", 1200, 1100, 1.0, "keystone_fabrica", 1.0,
		["eco_reloj_1"], true, "⚙️🤖"
	)

	# ==========================================================================
	# RED HÍBRIDA: PUENTES INTERCONECTADOS Y APEX SUPREMO
	# ==========================================================================
	registrar.call(
		"pnt_azul_verde_1", "Canal Cinético-Vital",
		"Clics otorgan +4 HP de escudo temporal por 4s",
		"hibrido", Vector2(-250, 110), 3, "ambas", 45, 40, 1.46, "clic_cura_escudo", 4.0,
		["clk_aoe_1", "srv_vel_1", "pnt_azul_verde_2"], false, "🌀"
	)

	registrar.call(
		"pnt_verde_dorada_1", "Alquimia de Recolección",
		"20% del valor de XP absorbido se convierte en oro",
		"hibrido", Vector2(240, 110), 3, "ambas", 45, 40, 1.46, "xp_a_oro_pct", 20.0,
		["srv_iman_1", "eco_cadencia_1", "pnt_verde_dorada_2"], false, "💰"
	)

	registrar.call(
		"pnt_dorada_azul_1", "Maná de Resonancia",
		"Clics generan oro igual al 15% del daño infligido",
		"hibrido", Vector2(0, -250), 3, "ambas", 45, 40, 1.46, "clic_genera_oro_pct", 15.0,
		["clk_pulso_1", "eco_xp_1", "clk_impulso_1", "pnt_dorada_azul_2"], false, "🔮"
	)

	registrar.call(
		"pnt_azul_verde_2", "Blindaje Reactivo a Clics",
		"Bloquear o esquivar con i-frames otorga +4 clics instantáneos",
		"hibrido", Vector2(-380, 240), 3, "ambas", 140, 120, 1.54, "bloqueo_genera_clics", 4.0,
		["clk_eco_1", "srv_vampirismo_1", "pnt_azul_verde_1", "pnt_azul_verde_3"], false, "🛡️⚡"
	)

	registrar.call(
		"pnt_verde_dorada_2", "Cosecha de Orbes Áureos",
		"+25% prob de duplicar gemas de botín",
		"hibrido", Vector2(370, 230), 3, "ambas", 140, 120, 1.54, "orbes_oro_duplicados_pct", 25.0,
		["srv_iframes_1", "eco_multidisparo_1", "pnt_verde_dorada_1", "pnt_verde_dorada_3"], false, "🌟"
	)

	registrar.call(
		"pnt_dorada_azul_2", "Detonación Alquímica",
		"Clics críticos hacen explotar a enemigos soltando oro extra",
		"hibrido", Vector2(0, -410), 3, "ambas", 140, 120, 1.54, "detonacion_oro_pct", 25.0,
		["clk_anomalia_1", "eco_minero_1", "pnt_dorada_azul_1", "pnt_dorada_azul_3"], false, "💥🪙"
	)

	registrar.call(
		"pnt_azul_verde_3", "Sísmica Berserker",
		"Pulsar clics bajo 50% HP desata terremoto que noquea enemigos",
		"hibrido", Vector2(-540, 380), 2, "ambas", 420, 340, 1.66, "terremoto_clic_vida", 1.0,
		["clk_sobrecarga_1", "srv_desquite_1", "pnt_azul_verde_2", "pnt_keystone_bucle"], false, "🌋"
	)

	registrar.call(
		"pnt_verde_dorada_3", "Sangre de Midas",
		"El oro acumulado acelera la regeneración (+1 HP/s por cada 400 oro)",
		"hibrido", Vector2(530, 370), 2, "ambas", 440, 320, 1.66, "oro_salud_conversion", 1.0,
		["srv_resistencia_1", "eco_reloj_1", "pnt_verde_dorada_2", "pnt_keystone_midas"], false, "🩸👑"
	)

	registrar.call(
		"pnt_dorada_azul_3", "Tempestad de Oro",
		"Cada clic descarga ráfagas de monedas cortantes",
		"hibrido", Vector2(0, -620), 2, "ambas", 450, 390, 1.68, "tempestad_oro_dmg", 35.0,
		["clk_penetracion_1", "eco_dividendos_1", "pnt_dorada_azul_2", "pnt_keystone_apex_orb"], false, "🌪️✨"
	)

	registrar.call(
		"pnt_keystone_bucle", "Keystone: Bucle de Transmutación Infinita",
		"Exceso de curación se vuelve clics; clics pasivos reparan armadura",
		"hibrido", Vector2(-460, 560), 1, "ambas", 1300, 950, 1.0, "keystone_bucle", 1.0,
		["pnt_azul_verde_3"], true, "♾️"
	)

	registrar.call(
		"pnt_keystone_midas", "Keystone: Armadura de Oro Líquido",
		"El daño letal consume 150 de oro en vez de vida mientras haya oro",
		"hibrido", Vector2(460, 550), 1, "ambas", 1700, 850, 1.0, "keystone_oro_liquido", 1.0,
		["pnt_verde_dorada_3"], true, "🛡️🪙"
	)

	registrar.call(
		"pnt_keystone_apex_orb", "Keystone: Cénit de Resonancia Arcana",
		"Críticos manuales x3.0 dmg y generan agujeros negros en el impacto",
		"hibrido", Vector2(0, -780), 1, "ambas", 1800, 1500, 1.0, "keystone_zenit", 1.0,
		["pnt_dorada_azul_3", "apex_keystone_ascension"], true, "🔮⚡"
	)

	registrar.call(
		"apex_keystone_ascension", "KEYSTONE SUPREMO: ASCENSIÓN DE LA CONSTELACIÓN",
		"[CULMINACIÓN DEL JUEGO] +100% Daño Global, +50% Velocidad, proyectiles triples y x2 en todos los ingresos de Oro y Clics",
		"hibrido", Vector2(0, -960), 1, "ambas", 2500, 2000, 1.0, "ascension_suprema", 1.0,
		["pnt_keystone_apex_orb"], true, "👑🏆"
	)

	# El nodo origen comienza activo
	if nodos.has("nodo_origen"):
		nodos["nodo_origen"].nivel_actual = 1

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
	if nodo.esta_maxeado():
		return false
	if nodo.esta_comprado():
		return true
	if nodo.id == "nodo_origen":
		return true
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
