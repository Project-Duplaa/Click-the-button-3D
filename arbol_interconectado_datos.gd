class_name ArbolInterconectadoDatos
extends RefCounted

## ArbolInterconectadoDatos - Catálogo y Generador del Grafo Web (Estilo Path of Exile)
## Constelación masiva de 80 nodos interconectados en 6 Tiers + Rama Ingeniería del Botón.
## Tier 6 incluye la Constelación Cósmica y 3 Nodos de Maestría Infinita (Nivel Máx. 999).

static func generar_arbol() -> Dictionary:
	var nodos: Dictionary = {}
	
	var registrar = func(id: String, nom: String, desc: String, rama: String, pos: Vector2, max_lvl: int,
			moneda: String, c_oro: int, c_clk: int, mult: float, stat: String, val_lvl: float,
			conns: Array, keystone: bool = false, ico: String = "⭐", c_esq: int = 0) -> SkillNodeData:
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
		n.costo_base_esquirlas = c_esq
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
		["clk_fuerza_1", "clk_pulso_1", "srv_salud_1", "srv_armadura_1", "eco_oro_1", "eco_xp_1", "btn_disipador_1"], false, "💠"
	)

	# ==========================================================================
	# RAMA AZUL: PODER ACTIVO Y MECÁNICAS DE CLIC (NOROESTE)
	# ==========================================================================
	registrar.call(
		"clk_fuerza_1", "Fuerza de Clic",
		"+8% daño por clic",
		"azul", Vector2(-160, -90), 5, "clics", 0, 220, 1.85, "dano_clic_pct", 8.0,
		["nodo_origen", "clk_pulso_1", "clk_aoe_1"], false, "👆"
	)

	registrar.call(
		"clk_pulso_1", "Pulsación Rúnica",
		"+1 clic generado por golpe",
		"azul", Vector2(-120, -180), 3, "clics", 0, 380, 2.00, "clics_por_pulsacion", 1.0,
		["nodo_origen", "clk_fuerza_1", "clk_crit_1", "pnt_dorada_azul_1", "clk_impulso_1"], false, "⚡"
	)

	registrar.call(
		"clk_aoe_1", "Onda Sónica Expansiva",
		"+0.6m radio detonación por clic",
		"azul", Vector2(-310, -80), 5, "clics", 0, 620, 1.95, "radio_aoe_clic", 0.6,
		["clk_fuerza_1", "clk_eco_1", "pnt_azul_verde_1"], false, "💥"
	)

	registrar.call(
		"clk_crit_1", "Precisión Quirúrgica",
		"+3% prob golpe crítico manual",
		"azul", Vector2(-270, -220), 5, "clics", 0, 680, 1.95, "critico_clic_prob", 3.0,
		["clk_pulso_1", "clk_filo_1", "clk_eco_1"], false, "🎯"
	)

	registrar.call(
		"clk_impulso_1", "Onda Repulsiva",
		"+12% retroceso y sprint al pulsar",
		"azul", Vector2(-200, -320), 4, "clics", 0, 560, 1.90, "empuje_clic_pct", 12.0,
		["clk_pulso_1", "clk_anomalia_1", "pnt_dorada_azul_1"], false, "🌀"
	)

	registrar.call(
		"clk_eco_1", "Eco Resonante",
		"+15% prob duplicar clic automáticamente",
		"azul", Vector2(-470, -140), 4, "clics", 0, 1450, 2.05, "eco_clic_prob", 15.0,
		["clk_aoe_1", "clk_crit_1", "clk_sobrecarga_1", "pnt_azul_verde_2"], false, "🔁"
	)

	registrar.call(
		"clk_filo_1", "Impacto Devastador",
		"+45% multiplicador crítico de clic",
		"azul", Vector2(-430, -280), 4, "clics", 0, 1600, 2.05, "dano_critico_pct", 45.0,
		["clk_crit_1", "clk_frenesi_1", "clk_sobrecarga_1"], false, "🗡️"
	)

	registrar.call(
		"clk_anomalia_1", "Sintonizador de Grietas",
		"+15% frecuencia y botín de anomalías rúnicas",
		"azul", Vector2(-350, -420), 3, "clics", 0, 1300, 1.98, "prob_anomalia_pct", 15.0,
		["clk_impulso_1", "clk_penetracion_1", "pnt_dorada_azul_2"], false, "🌌"
	)

	registrar.call(
		"clk_sobrecarga_1", "Tormenta de Clics",
		"Cada 6 clics desata rayo arcano global (+80 dmg)",
		"azul", Vector2(-650, -190), 3, "clics", 0, 3200, 2.15, "dano_sobrecarga", 80.0,
		["clk_eco_1", "clk_filo_1", "clk_keystone_cataclismo", "pnt_azul_verde_3"], false, "🌩️", 4
	)

	registrar.call(
		"clk_frenesi_1", "Trance Hipercinético",
		"Clics otorgan +12% daño acumulativo por 3s",
		"azul", Vector2(-600, -360), 3, "clics", 0, 3600, 2.15, "frenesi_velocidad_clic", 12.0,
		["clk_filo_1", "clk_penetracion_1", "clk_keystone_soberania"], false, "🔥", 4
	)

	registrar.call(
		"clk_penetracion_1", "Ruptura Dimensional",
		"La onda de clic ignora 25% armadura enemiga",
		"azul", Vector2(-500, -510), 3, "clics", 0, 2900, 2.10, "penetracion_clic", 25.0,
		["clk_anomalia_1", "clk_frenesi_1", "pnt_dorada_azul_3"], false, "🕳️", 3
	)

	registrar.call(
		"clk_keystone_cataclismo", "Keystone: Cataclismo Cinético",
		"Cada 8 clics resetea CDs de armas y barre la arena",
		"azul", Vector2(-880, -180), 1, "clics", 0, 9500, 1.0, "keystone_cataclismo", 1.0,
		["clk_sobrecarga_1", "cosm_singularidad_estelar"], true, "⚡⚡", 14
	)

	registrar.call(
		"clk_keystone_soberania", "Keystone: Soberanía del Clic Rúnico",
		"Clics escalan con 200% del daño del arma principal",
		"azul", Vector2(-820, -450), 1, "ambas", 4800, 9500, 1.0, "keystone_soberania", 1.0,
		["clk_frenesi_1", "cosm_ojo_cosmos"], true, "👑👆", 18
	)

	# ==========================================================================
	# RAMA NARANJA: INGENIERÍA DEL BOTÓN / NÚCLEO MÓVIL (OESTE)
	# ==========================================================================
	registrar.call(
		"btn_disipador_1", "Disipador Criotérmico",
		"-10% calor generado por clic en el Botón (ráfagas más largas antes de sobrecalentar)",
		"boton", Vector2(-140, 20), 5, "clics", 0, 240, 1.88, "btn_calor_reduc_pct", 10.0,
		["nodo_origen", "clk_fuerza_1", "pnt_azul_verde_1", "btn_tamano_1"], false, "❄️"
	)

	registrar.call(
		"btn_tamano_1", "Núcleo Expandido",
		"+8% tamaño físico y área de clic del Botón Móvil por nivel",
		"boton", Vector2(-365, 45), 5, "oro", 580, 0, 1.92, "btn_tamano_pct", 8.0,
		["btn_disipador_1", "pnt_azul_verde_1", "btn_enfriamiento_1", "btn_ritmo_1"], false, "🔘"
	)

	registrar.call(
		"btn_enfriamiento_1", "Turbinas de Enfriamiento",
		"+18% velocidad de enfriamiento del Botón y menor retardo tras soltarlo",
		"boton", Vector2(-515, -15), 5, "clics", 0, 680, 1.95, "btn_enfriamiento_pct", 18.0,
		["btn_tamano_1", "clk_eco_1", "btn_ancla_orbita_1", "btn_sobrecarga_termica_1"], false, "💨"
	)

	registrar.call(
		"btn_ritmo_1", "Sincronizador de Ritmo",
		"+15% amplitud de la ventana de Clic Perfecto y +10% daño de Clic Perfecto",
		"boton", Vector2(-505, 135), 4, "clics", 0, 740, 1.98, "btn_ventana_ritmo_pct", 15.0,
		["btn_tamano_1", "pnt_azul_verde_2", "btn_ancla_orbita_1", "btn_cadenas_1"], false, "🎵"
	)

	registrar.call(
		"btn_ancla_orbita_1", "Anclaje Magnético",
		"-12% velocidad de huida del Botón y órbita más cercana al gladiador",
		"boton", Vector2(-645, 55), 4, "oro", 1450, 0, 2.02, "btn_control_orbita_pct", 12.0,
		["btn_enfriamiento_1", "btn_ritmo_1", "btn_sobrecarga_termica_1", "btn_fiebre_sostenida_1", "btn_cadenas_1"], false, "🧭"
	)

	registrar.call(
		"btn_cadenas_1", "Contención Reforzada",
		"+4 clics adicionales antes de que el Botón se bloquee por cadenas",
		"boton", Vector2(-650, 210), 4, "ambas", 920, 760, 2.05, "btn_clics_bloqueo_extra", 4.0,
		["btn_ritmo_1", "btn_ancla_orbita_1", "btn_palancas_1", "btn_fiebre_sostenida_1", "pnt_azul_verde_3"], false, "⛓️"
	)

	registrar.call(
		"btn_sobrecarga_termica_1", "Reactor al Rojo Vivo",
		"+15 capacidad térmica máxima del Botón y +12% daño de onda en Sobrecarga Térmica",
		"boton", Vector2(-785, -25), 4, "clics", 0, 2950, 2.12, "btn_calor_max_extra", 15.0,
		["btn_enfriamiento_1", "btn_ancla_orbita_1", "btn_fiebre_sostenida_1", "btn_keystone_criogenico", "clk_keystone_cataclismo"], false, "🌡️", 4
	)

	registrar.call(
		"btn_fiebre_sostenida_1", "Batería de Fiebre Overdrive",
		"+15% ganancia de Fiebre por clic y -12% pérdida de Fiebre por segundo",
		"boton", Vector2(-790, 110), 4, "clics", 0, 3400, 2.15, "btn_fiebre_eficiencia_pct", 15.0,
		["btn_ancla_orbita_1", "btn_cadenas_1", "btn_sobrecarga_termica_1", "btn_frenesi_duracion_1", "btn_keystone_criogenico"], false, "🔋", 4
	)

	registrar.call(
		"btn_palancas_1", "Enlace Remoto de Disyuntores",
		"+1.5m alcance para activar palancas y descarga protectora al accionar cada disyuntor",
		"boton", Vector2(-775, 255), 3, "oro", 2800, 0, 2.10, "btn_alcance_palancas", 1.5,
		["btn_cadenas_1", "btn_frenesi_duracion_1", "btn_keystone_rompecadenas"], false, "🔌", 3
	)

	registrar.call(
		"btn_frenesi_duracion_1", "Condensador de Frenesí",
		"+2.5s de duración del Modo Frenesí de Sobrecarga al liberar el Botón",
		"boton", Vector2(-930, 175), 4, "ambas", 2100, 1700, 2.18, "btn_frenesi_duracion_seg", 2.5,
		["btn_fiebre_sostenida_1", "btn_palancas_1", "btn_keystone_criogenico", "btn_keystone_rompecadenas"], false, "🔥⚡", 5
	)

	registrar.call(
		"btn_keystone_criogenico", "Keystone: Núcleo Criogénico Perpetuo",
		"Al 100% de calor detona una Nova Criogénica en vez de bloquearse y purga el calor al 35% (CD 6s); +50% daño en Sobrecarga Térmica",
		"boton", Vector2(-1040, -15), 1, "ambas", 8000, 9200, 1.0, "keystone_btn_criogenico", 1.0,
		["btn_sobrecarga_termica_1", "btn_fiebre_sostenida_1", "btn_frenesi_duracion_1"], true, "❄️💥", 15
	)

	registrar.call(
		"btn_keystone_rompecadenas", "Keystone: Soberano del Botón Desencadenado",
		"Rompe 1 cadena automáticamente al bloquearse (solo requiere 2 palancas), +1 multiplicador extra en Frenesí (x4/x6) y cada teletransporte detona una Supernova",
		"boton", Vector2(-1075, 240), 1, "ambas", 9200, 9500, 1.0, "keystone_btn_rompecadenas", 1.0,
		["btn_palancas_1", "btn_frenesi_duracion_1"], true, "⛓️👑", 18
	)

	# ==========================================================================
	# RAMA VERDE: SUPERVIVENCIA, VIDAS Y TANQUE (SUR)
	# ==========================================================================
	registrar.call(
		"srv_salud_1", "Constitución Heroica",
		"+10 HP Vida Máxima por nivel",
		"verde", Vector2(0, 160), 5, "oro", 220, 0, 1.85, "salud_maxima", 10.0,
		["nodo_origen", "srv_armadura_1", "srv_vel_1", "srv_iman_1"], false, "❤️"
	)

	registrar.call(
		"srv_armadura_1", "Coraza de Gladiador",
		"+3% mitigación pasiva de daño",
		"verde", Vector2(-100, 190), 5, "oro", 260, 0, 1.90, "mitigacion_dano_pct", 3.0,
		["nodo_origen", "srv_salud_1", "srv_escudo_1"], false, "🛡️"
	)

	registrar.call(
		"srv_vel_1", "Paso de Viento",
		"+4% velocidad de movimiento",
		"verde", Vector2(-180, 310), 5, "oro", 600, 0, 1.95, "velocidad_mov_pct", 4.0,
		["srv_salud_1", "srv_regen_1", "pnt_azul_verde_1"], false, "👟"
	)

	registrar.call(
		"srv_iman_1", "Magnetismo Espectral",
		"+1.2m radio imán de orbes y oro",
		"verde", Vector2(140, 290), 5, "oro", 560, 0, 1.90, "radio_iman", 1.2,
		["srv_salud_1", "srv_regen_1", "pnt_verde_dorada_1", "srv_iframes_1"], false, "🧲"
	)

	registrar.call(
		"srv_escudo_1", "Escudo de Almas (Aegis)",
		"Absorbe +15 de daño antes de perder HP",
		"verde", Vector2(-60, 360), 4, "oro", 840, 0, 2.00, "escudo_almas", 15.0,
		["srv_armadura_1", "srv_vampirismo_1", "srv_regen_1", "srv_vida_extra_1"], false, "🔰"
	)

	registrar.call(
		"srv_vida_extra_1", "Segunda Oportunidad (Vidas Extras)",
		"+1 Vida / Reaparición adicional en combate por nivel",
		"verde", Vector2(-90, 520), 2, "ambas", 3200, 1800, 2.25, "vidas_extra", 1.0,
		["srv_escudo_1", "srv_regen_1", "srv_fortaleza_1"], false, "💖👑", 8
	)

	registrar.call(
		"srv_regen_1", "Aliento Vital Continuo",
		"+0.5 HP/s regenerado continuamente",
		"verde", Vector2(0, 480), 4, "oro", 1650, 0, 2.05, "regen_vida_seg", 0.5,
		["srv_vel_1", "srv_iman_1", "srv_escudo_1", "srv_fortaleza_1", "srv_vida_extra_1"], false, "💖"
	)

	registrar.call(
		"srv_vampirismo_1", "Festín Sangriento (Vampirismo)",
		"+1 HP restaurado por cada enemigo abatido",
		"verde", Vector2(-190, 490), 4, "oro", 1850, 0, 2.08, "vida_por_baja", 1.0,
		["srv_escudo_1", "srv_desquite_1", "pnt_azul_verde_2"], false, "🩸"
	)

	registrar.call(
		"srv_iframes_1", "Evasión Espiritual",
		"+0.5s de invulnerabilidad tras recibir impacto",
		"verde", Vector2(170, 480), 3, "oro", 1350, 0, 2.00, "invulnerable_extra_seg", 0.5,
		["srv_iman_1", "srv_resistencia_1", "pnt_verde_dorada_2"], false, "🕊️"
	)

	registrar.call(
		"srv_fortaleza_1", "Bastión de Titán",
		"+35 armadura plana y +60 HP bajo 35% de vida",
		"verde", Vector2(0, 680), 3, "oro", 3400, 0, 2.15, "armadura_plana", 35.0,
		["srv_regen_1", "srv_vida_extra_1", "srv_desquite_1", "srv_resistencia_1", "srv_keystone_segunda_vida"], false, "🏰", 4
	)

	registrar.call(
		"srv_desquite_1", "Retribución de Espinas",
		"Devuelve +40% del daño recibido en cono",
		"verde", Vector2(-230, 640), 3, "oro", 2800, 0, 2.08, "reflejo_dano_pct", 40.0,
		["srv_vampirismo_1", "srv_fortaleza_1", "srv_keystone_coloso", "pnt_azul_verde_3"], false, "🌵", 3
	)

	registrar.call(
		"srv_resistencia_1", "Firmeza Inflexible",
		"Inmunidad a empuje y +25% mitigación ante jefes",
		"verde", Vector2(220, 640), 3, "oro", 3100, 0, 2.10, "resistencia_estados_pct", 25.0,
		["srv_iframes_1", "srv_fortaleza_1", "srv_keystone_aliento", "pnt_verde_dorada_3"], false, "🗿", 3
	)

	registrar.call(
		"srv_keystone_segunda_vida", "Keystone: Segunda Oportunidad Sagrada",
		"+1 Vida extra y nova sagrada aniquiladora al caer",
		"verde", Vector2(0, 940), 1, "ambas", 9800, 4800, 1.0, "keystone_segunda_vida", 1.0,
		["srv_fortaleza_1"], true, "✝️", 18
	)

	registrar.call(
		"srv_keystone_coloso", "Keystone: Pacto Inmortal del Coloso",
		"25% de max HP se vuelve armadura; +80% dmg bajo 50% HP",
		"verde", Vector2(-240, 890), 1, "oro", 11500, 0, 1.0, "keystone_coloso", 1.0,
		["srv_desquite_1"], true, "🗿✨", 15
	)

	registrar.call(
		"srv_keystone_aliento", "Keystone: Último Aliento",
		"Al sufrir daño fatal sobrevive a 1 HP con 3.5s de i-frames",
		"verde", Vector2(240, 890), 1, "ambas", 8800, 4200, 1.0, "keystone_aliento", 1.0,
		["srv_resistencia_1"], true, "🔥❤️", 15
	)

	# ==========================================================================
	# RAMA DORADA: AUTOMATIZACIÓN, ARSENAL Y ECONOMÍA (NORESTE)
	# ==========================================================================
	registrar.call(
		"eco_oro_1", "Tributo de Sangre",
		"+8% oro de bajas y cofres",
		"dorada", Vector2(160, -90), 5, "oro", 240, 0, 1.90, "oro_por_baja_pct", 8.0,
		["nodo_origen", "eco_xp_1", "eco_cadencia_1"], false, "🪙"
	)

	registrar.call(
		"eco_xp_1", "Sabiduría del Coliseo",
		"+8% ganancia de experiencia",
		"dorada", Vector2(120, -180), 5, "oro", 260, 0, 1.90, "xp_ganada_pct", 8.0,
		["nodo_origen", "eco_oro_1", "eco_autoclick_1", "pnt_dorada_azul_1"], false, "📜"
	)

	registrar.call(
		"trebol_coliseo", "Trébol del Coliseo",
		"+0.05 de suerte por nivel (más rarezas altas y mejores drops)",
		"dorada", Vector2(90, -300), 5, "ambas", 450, 350, 1.95, "suerte", 0.05,
		["eco_xp_1"], false, "🍀"
	)

	registrar.call(
		"eco_cadencia_1", "Cadencia Bélica",
		"+5% cadencia de armas automáticas",
		"dorada", Vector2(310, -80), 5, "oro", 780, 0, 1.95, "cadencia_armas_pct", 5.0,
		["eco_oro_1", "eco_proyectiles_1", "pnt_verde_dorada_1"], false, "⚔️"
	)

	registrar.call(
		"eco_autoclick_1", "Autoclicker Rúnico",
		"+0.25 clics automáticos por segundo",
		"dorada", Vector2(260, -220), 5, "clics", 0, 1050, 2.05, "autoclick_tasa", 0.25,
		["eco_xp_1", "eco_proyectiles_1", "eco_minero_1"], false, "⏳"
	)

	registrar.call(
		"eco_proyectiles_1", "Calibre Expandido",
		"+6% daño a proyectiles y ataques automáticos",
		"dorada", Vector2(220, -320), 4, "oro", 850, 0, 2.00, "dano_armas_pct", 6.0,
		["eco_cadencia_1", "eco_autoclick_1", "eco_multidisparo_1", "eco_perforacion_1"], false, "🏹"
	)

	registrar.call(
		"eco_multidisparo_1", "Abanico Balístico",
		"+1 proyectil extra en abanico",
		"dorada", Vector2(460, -140), 3, "ambas", 1250, 750, 2.08, "proyectiles_extra", 1.0,
		["eco_proyectiles_1", "eco_alcance_1", "pnt_verde_dorada_2"], false, "🎆"
	)

	registrar.call(
		"eco_perforacion_1", "Balas Perforantes",
		"+1 objetivo perforado por proyectiles",
		"dorada", Vector2(420, -280), 3, "oro", 1450, 0, 2.02, "perforacion_armas", 1.0,
		["eco_proyectiles_1", "eco_reloj_1", "eco_minero_1"], false, "🎯💥"
	)

	registrar.call(
		"eco_minero_1", "Tributo de Bóveda Pasiva",
		"+0.5 de oro generado por segundo",
		"dorada", Vector2(350, -420), 4, "oro", 1750, 0, 2.05, "oro_pasivo_seg", 0.5,
		["eco_autoclick_1", "eco_perforacion_1", "eco_dividendos_1", "pnt_dorada_azul_2"], false, "⛏️"
	)

	registrar.call(
		"eco_alcance_1", "Órbita Letal",
		"+25% radio de alcance y adquisición de blancos",
		"dorada", Vector2(640, -190), 3, "oro", 3200, 0, 2.12, "rango_ataque_pct", 25.0,
		["eco_multidisparo_1", "eco_reloj_1", "eco_keystone_usura"], false, "🌐", 3
	)

	registrar.call(
		"eco_reloj_1", "Crono-Resonancia",
		"+40% cadencia y daño a los autoclickers autónomos",
		"dorada", Vector2(590, -360), 3, "clics", 0, 3800, 2.18, "autoclick_overclock_pct", 40.0,
		["eco_perforacion_1", "eco_alcance_1", "eco_dividendos_1", "eco_keystone_fabrica", "pnt_verde_dorada_3"], false, "⏱️", 5
	)

	registrar.call(
		"eco_dividendos_1", "Fondo de Usura Oleada",
		"+6% de interés por oleada completada",
		"dorada", Vector2(490, -510), 3, "oro", 4100, 0, 2.20, "interes_oleada_pct", 6.0,
		["eco_minero_1", "eco_reloj_1", "pnt_dorada_azul_3"], false, "📈", 5
	)

	registrar.call(
		"eco_keystone_usura", "Keystone: Usura y Riqueza Infinita",
		"+20% interés oleada; +2.5% daño global por cada 100 de oro",
		"dorada", Vector2(870, -180), 1, "oro", 13500, 0, 1.0, "keystone_usura", 1.0,
		["eco_alcance_1", "cosm_pulso_supernova"], true, "🏦👑", 18
	)

	registrar.call(
		"eco_keystone_fabrica", "Keystone: Fábrica Autónoma del Coliseo",
		"Autoclicker a 6 clics/s; heredan 100% de los efectos del clic manual",
		"dorada", Vector2(810, -440), 1, "ambas", 8200, 7800, 1.0, "keystone_fabrica", 1.0,
		["eco_reloj_1", "cosm_vortice_tiempo"], true, "⚙️🤖", 20
	)

	# ==========================================================================
	# RED HÍBRIDA: PUENTES INTERCONECTADOS Y APEX SUPREMO
	# ==========================================================================
	registrar.call(
		"pnt_azul_verde_1", "Canal Cinético-Vital",
		"Clics otorgan +4 HP de escudo temporal por 4s",
		"hibrido", Vector2(-250, 110), 3, "ambas", 320, 280, 1.90, "clic_cura_escudo", 4.0,
		["clk_aoe_1", "srv_vel_1", "pnt_azul_verde_2"], false, "🌀"
	)

	registrar.call(
		"pnt_verde_dorada_1", "Alquimia de Recolección",
		"20% del valor de XP absorbido se convierte en oro",
		"hibrido", Vector2(240, 110), 3, "ambas", 320, 280, 1.90, "xp_a_oro_pct", 20.0,
		["srv_iman_1", "eco_cadencia_1", "pnt_verde_dorada_2"], false, "💰"
	)

	registrar.call(
		"pnt_dorada_azul_1", "Maná de Resonancia",
		"Clics generan oro igual al 15% del daño infligido",
		"hibrido", Vector2(0, -250), 3, "ambas", 320, 280, 1.90, "clic_genera_oro_pct", 15.0,
		["clk_pulso_1", "eco_xp_1", "clk_impulso_1", "pnt_dorada_azul_2"], false, "🔮"
	)

	registrar.call(
		"pnt_azul_verde_2", "Blindaje Reactivo a Clics",
		"Bloquear o esquivar con i-frames otorga +4 clics instantáneos",
		"hibrido", Vector2(-380, 240), 3, "ambas", 1200, 950, 2.00, "bloqueo_genera_clics", 4.0,
		["clk_eco_1", "srv_vampirismo_1", "pnt_azul_verde_1", "pnt_azul_verde_3"], false, "🛡️⚡"
	)

	registrar.call(
		"pnt_verde_dorada_2", "Cosecha de Orbes Áureos",
		"+25% prob de duplicar gemas de botín",
		"hibrido", Vector2(370, 230), 3, "ambas", 1200, 950, 2.00, "orbes_oro_duplicados_pct", 25.0,
		["srv_iframes_1", "eco_multidisparo_1", "pnt_verde_dorada_1", "pnt_verde_dorada_3"], false, "🌟"
	)

	registrar.call(
		"pnt_dorada_azul_2", "Detonación Alquímica",
		"Clics críticos hacen explotar a enemigos soltando oro extra",
		"hibrido", Vector2(0, -410), 3, "ambas", 1200, 950, 2.00, "detonacion_oro_pct", 25.0,
		["clk_anomalia_1", "eco_minero_1", "pnt_dorada_azul_1", "pnt_dorada_azul_3"], false, "💥🪙"
	)

	registrar.call(
		"pnt_azul_verde_3", "Sísmica Berserker",
		"Pulsar clics bajo 50% HP desata terremoto que noquea enemigos",
		"hibrido", Vector2(-540, 380), 2, "ambas", 2700, 2400, 2.12, "terremoto_clic_vida", 1.0,
		["clk_sobrecarga_1", "srv_desquite_1", "pnt_azul_verde_2", "pnt_keystone_bucle"], false, "🌋", 5
	)

	registrar.call(
		"pnt_verde_dorada_3", "Sangre de Midas",
		"El oro acumulado acelera la regeneración (+1 HP/s por cada 400 oro)",
		"hibrido", Vector2(530, 370), 2, "ambas", 2800, 2300, 2.12, "oro_salud_conversion", 1.0,
		["srv_resistencia_1", "eco_reloj_1", "pnt_verde_dorada_2", "pnt_keystone_midas"], false, "🩸👑", 5
	)

	registrar.call(
		"pnt_dorada_azul_3", "Tempestad de Oro",
		"Cada clic descarga ráfagas de monedas cortantes",
		"hibrido", Vector2(0, -620), 2, "ambas", 2900, 2600, 2.15, "tempestad_oro_dmg", 35.0,
		["clk_penetracion_1", "eco_dividendos_1", "pnt_dorada_azul_2", "pnt_keystone_apex_orb"], false, "🌪️✨", 6
	)

	registrar.call(
		"pnt_keystone_bucle", "Keystone: Bucle de Transmutación Infinita",
		"Exceso de curación se vuelve clics; clics pasivos reparan armadura",
		"hibrido", Vector2(-460, 560), 1, "ambas", 8500, 6800, 1.0, "keystone_bucle", 1.0,
		["pnt_azul_verde_3"], true, "♾️", 14
	)

	registrar.call(
		"pnt_keystone_midas", "Keystone: Armadura de Oro Líquido",
		"El daño letal consume 150 de oro en vez de vida mientras haya oro",
		"hibrido", Vector2(460, 550), 1, "ambas", 11000, 6000, 1.0, "keystone_oro_liquido", 1.0,
		["pnt_verde_dorada_3"], true, "🛡️🪙", 16
	)

	registrar.call(
		"pnt_keystone_apex_orb", "Keystone: Cénit de Resonancia Arcana",
		"Críticos manuales x3.0 dmg y generan agujeros negros en el impacto",
		"hibrido", Vector2(0, -780), 1, "ambas", 12500, 11000, 1.0, "keystone_zenit", 1.0,
		["pnt_dorada_azul_3", "apex_keystone_ascension"], true, "🔮⚡", 22
	)

	registrar.call(
		"apex_keystone_ascension", "KEYSTONE SUPREMO: ASCENSIÓN DE LA CONSTELACIÓN",
		"[CULMINACIÓN DEL JUEGO] +100% Daño Global, +50% Velocidad, proyectiles triples y x2 en todos los ingresos de Oro y Clics",
		"hibrido", Vector2(0, -960), 1, "ambas", 28000, 22000, 1.0, "ascension_suprema", 1.0,
		["pnt_keystone_apex_orb", "cosm_nexo_primordial"], true, "👑🏆", 60
	)

	# ==========================================================================
	# TIER 6: CONSTELACIÓN CÓSMICA ASTRAL & MAESTRÍAS INFINITAS (y = -1120 a -1450)
	# ==========================================================================
	registrar.call(
		"cosm_nexo_primordial", "Nexo Astral Primordial",
		"+30% Daño a enemigos élite y jefes, y abre el umbral a las Maestrías Infinitas",
		"cosmico", Vector2(0, -1120), 5, "ambas", 12000, 10000, 1.95, "dano_armas_pct", 30.0,
		["apex_keystone_ascension", "inf_poder_armas", "inf_resonancia_clic", "inf_fortuna_eterna", "cosm_singularidad_estelar", "cosm_pulso_supernova"], false, "🌌", 25
	)

	# --- 3 NODOS DE MAESTRÍA INFINITA (nivel_max = 999) ---
	registrar.call(
		"inf_poder_armas", "Maestría Cósmica: Poder de Armas",
		"[NIVEL INFINITO] +5% Daño Global por nivel de forma acumulativa y permanente",
		"cosmico", Vector2(-150, -1160), 999, "oro", 4800, 0, 1.45, "dano_armas_pct", 5.0,
		["cosm_nexo_primordial"], false, "⚔️✨", 8
	)

	registrar.call(
		"inf_resonancia_clic", "Maestría Cósmica: Resonancia de Clic",
		"[NIVEL INFINITO] +8% Daño de Clic & Resonancia por nivel de forma ilimitada",
		"cosmico", Vector2(150, -1160), 999, "clics", 0, 4500, 1.45, "dano_clic_pct", 8.0,
		["cosm_nexo_primordial"], false, "⚡✨", 8
	)

	registrar.call(
		"inf_fortuna_eterna", "Maestría Cósmica: Fortuna Eterna",
		"[NIVEL INFINITO] +2% Oro, +2% Experiencia y +0.02 Suerte por nivel",
		"cosmico", Vector2(0, -1250), 999, "ambas", 3000, 2500, 1.45, "suerte", 0.02,
		["cosm_nexo_primordial", "cosm_keystone_genesis"], false, "🍀✨", 8
	)

	# --- CONSTELACIÓN CÓSMICA EXTERIOR ---
	registrar.call(
		"cosm_singularidad_estelar", "Singularidad Estelar",
		"Ondas de clic arrastran a todos los enemigos de la arena hacia el epicentro",
		"cosmico", Vector2(-260, -1180), 3, "clics", 0, 14000, 1.95, "radio_aoe_clic", 2.5,
		["cosm_nexo_primordial", "clk_keystone_cataclismo", "cosm_ojo_cosmos"], false, "🌀", 30
	)

	registrar.call(
		"cosm_pulso_supernova", "Pulso de Supernova",
		"+20% Cadencia de ataque y los golpes críticos detonan novas estelares (+90 dmg)",
		"cosmico", Vector2(260, -1180), 3, "oro", 15000, 0, 1.95, "cadencia_armas_pct", 20.0,
		["cosm_nexo_primordial", "eco_keystone_usura", "cosm_vortice_tiempo"], false, "☄️", 32
	)

	registrar.call(
		"cosm_ojo_cosmos", "Ojo del Cosmos",
		"Duplica el multiplicador de daño crítico de todas las armas y ondas de choque",
		"cosmico", Vector2(-420, -1260), 3, "ambas", 10000, 9500, 2.00, "dano_critico_pct", 50.0,
		["cosm_singularidad_estelar", "clk_keystone_soberania", "cosm_constelacion_draconis"], false, "👁️", 38
	)

	registrar.call(
		"cosm_vortice_tiempo", "Vórtice del Tiempo",
		"Los autoclickers ganan +100% velocidad y reducen el enfriamiento del Dash un 30%",
		"cosmico", Vector2(420, -1260), 3, "ambas", 11000, 9000, 2.00, "autoclick_tasa", 3.0,
		["cosm_pulso_supernova", "eco_keystone_fabrica", "cosm_corona_astral"], false, "⌛", 38
	)

	registrar.call(
		"cosm_constelacion_draconis", "Constelación Draconis",
		"+40 Armadura plana y desata un aliento de fuego estelar que calcina la arena",
		"cosmico", Vector2(-180, -1350), 3, "oro", 19000, 0, 2.05, "armadura_plana", 40.0,
		["cosm_ojo_cosmos", "cosm_espejo_vacio", "cosm_keystone_genesis"], false, "🐉", 45
	)

	registrar.call(
		"cosm_corona_astral", "Corona Astral",
		"+60 HP Escudo de Almas y regenera 5 HP/s mientras el escudo esté activo",
		"cosmico", Vector2(180, -1350), 3, "oro", 19000, 0, 2.05, "escudo_almas", 60.0,
		["cosm_vortice_tiempo", "cosm_keystone_genesis"], false, "👑🌟", 45
	)

	registrar.call(
		"cosm_espejo_vacio", "Espejo del Vacío",
		"15% Probabilidad de anular daño fatal y reflejar el 200% del impacto al agresor",
		"cosmico", Vector2(-350, -1440), 2, "ambas", 12500, 11000, 2.10, "invulnerable_extra_seg", 1.0,
		["cosm_constelacion_draconis", "cosm_keystone_genesis"], false, "🪞✨", 55
	)

	registrar.call(
		"cosm_keystone_genesis", "KEYSTONE CÓSMICO: GÉNESIS CELESTIAL",
		"[TRASCENDENCIA SUPREMA] +50% Daño Global, +2 Proyectiles triples y las almas derrotadas detonan en cometas sagrados",
		"cosmico", Vector2(0, -1450), 1, "ambas", 65000, 55000, 1.0, "cosm_keystone_genesis", 1.0,
		["cosm_constelacion_draconis", "cosm_corona_astral", "cosm_espejo_vacio", "inf_fortuna_eterna"], true, "🌟🔱", 110
	)

	# El nodo origen comienza activo
	if nodos.has("nodo_origen"):
		nodos["nodo_origen"].nivel_actual = 1

	# Asegurar bidireccionalidad de todas las conexiones en el grafo (100% Simetría)
	for n_id in nodos.keys():
		var nodo = nodos[n_id]
		for vecino_id in nodo.nodos_conectados:
			if nodos.has(vecino_id):
				var vecino = nodos[vecino_id]
				if not vecino.nodos_conectados.has(n_id):
					vecino.nodos_conectados.append(n_id)

	return nodos

static func nivel_requerido_vecino(v: SkillNodeData) -> int:
	if v.id == "nodo_origen" or v.nivel_max <= 1:
		return 1
	if v.nivel_max >= 999:
		return 3
	return maxi(2, int(ceil(float(v.nivel_max) * 0.6)))

static func contar_niveles_comprados(todos_los_nodos: Dictionary) -> int:
	var total: int = 0
	for k in todos_los_nodos.keys():
		if str(k) == "nodo_origen":
			continue
		var nd: SkillNodeData = todos_los_nodos[k]
		total += maxi(0, nd.nivel_actual)
	return total

static func es_nodo_desbloqueable(nodo: SkillNodeData, todos_los_nodos: Dictionary) -> bool:
	if nodo.esta_maxeado():
		return false
	if nodo.esta_comprado():
		return true
	if nodo.id == "nodo_origen":
		return true
	for vecino_id in nodo.nodos_conectados:
		if todos_los_nodos.has(vecino_id):
			var v: SkillNodeData = todos_los_nodos[vecino_id]
			if nodo.es_keystone:
				if v.nivel_max >= 999:
					if v.nivel_actual >= 3:
						return true
				elif v.esta_maxeado():
					return true
			else:
				if v.nivel_actual >= nivel_requerido_vecino(v):
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
