class_name AudioDSP
extends RefCounted

## Motor DSP procedural 16-bit / 44.1 kHz estéreo para identidad sonora Arcade Moderna
## (síntesis sustractiva PolyBLEP sin aliasing, FM brillante, cuerdas, ruido rosa SVF y mastering limpio).

const SR: int = 44100


static func crear_buffer(duracion: float) -> Dictionary:
	var n := maxi(64, int(roundf(duracion * float(SR))))
	var l := PackedFloat32Array()
	var r := PackedFloat32Array()
	l.resize(n)
	r.resize(n)
	return { "l": l, "r": r, "n": n }


static func _ganancias_pan(pan: float) -> Vector2:
	var p := clampf(pan, -1.0, 1.0)
	var ang := (p + 1.0) * 0.25 * PI
	return Vector2(cos(ang), sin(ang))


static func _poly_blep(t: float, dt: float) -> float:
	if dt <= 0.0:
		return 0.0
	if t < dt:
		var x := t / dt
		return x + x - x * x - 1.0
	elif t > 1.0 - dt:
		var x := (t - 1.0) / dt
		return x * x + x + x + 1.0
	return 0.0


## Agrega un tono sinusoidal con envolvente exponencial de tono, ataque suave (sin clics)
## y decaimiento exponencial natural, usando acumulador de fase continuo.
static func agregar_tono_modal(
		buf: Dictionary,
		inicio_seg: float,
		duracion_seg: float,
		freq_inicio: float,
		freq_fin: float,
		tau_freq: float,
		amplitud: float,
		tau_ataque: float,
		tau_caida: float,
		pan: float = 0.0
	) -> void:
	var l: PackedFloat32Array = buf["l"]
	var r: PackedFloat32Array = buf["r"]
	var n_total: int = buf["n"]
	var i0 := clampi(int(inicio_seg * float(SR)), 0, n_total)
	var i1 := clampi(i0 + int(duracion_seg * float(SR)), i0, n_total)
	if i1 <= i0:
		return

	var inv_sr := 1.0 / float(SR)
	var g := _ganancias_pan(pan)
	var fase := 0.0
	var fade_final := mini(int(0.012 * float(SR)), (i1 - i0) / 3)
	var tau_f := maxf(tau_freq, 0.0005)
	var tau_a := maxf(tau_ataque, 0.0004)
	var tau_d := maxf(tau_caida, 0.001)

	for i in range(i0, i1):
		var local := i - i0
		var t := float(local) * inv_sr
		var f := freq_fin + (freq_inicio - freq_fin) * exp(-t / tau_f)
		fase += TAU * f * inv_sr
		var env := (1.0 - exp(-t / tau_a)) * exp(-t / tau_d)
		var rem := i1 - 1 - i
		if rem < fade_final and fade_final > 0:
			env *= 0.5 * (1.0 - cos(PI * float(rem) / float(fade_final)))
		var muestra := sin(fase) * env * amplitud
		l[i] += muestra * g.x
		r[i] += muestra * g.y


## Voz de sintetizador arcade moderno con osciladores PolyBLEP (sin aliasing):
## onda: 0 = pulse (ancho_pulso), 1 = saw, 2 = triangle
## Incluye barrido exponencial de pitch, filtro TPT SVF pasabajos dinámico y vibrato opcional.
static func agregar_synth_arcade(
		buf: Dictionary,
		inicio_seg: float,
		duracion_seg: float,
		onda: int,
		freq_inicio: float,
		freq_fin: float,
		tau_freq: float,
		corte_inicio: float,
		corte_fin: float,
		q: float,
		amplitud: float,
		ataque_seg: float = 0.003,
		caida_tau: float = 0.14,
		ancho_pulso: float = 0.5,
		pan: float = 0.0,
		vib_hz: float = 0.0,
		vib_prof: float = 0.0
	) -> void:
	var l: PackedFloat32Array = buf["l"]
	var r: PackedFloat32Array = buf["r"]
	var n_total: int = buf["n"]
	var i0 := clampi(int(inicio_seg * float(SR)), 0, n_total)
	var i1 := clampi(i0 + int(duracion_seg * float(SR)), i0, n_total)
	if i1 <= i0:
		return

	var inv_sr := 1.0 / float(SR)
	var inv_len := 1.0 / float(maxi(1, i1 - i0 - 1))
	var gp := _ganancias_pan(pan)
	var fase := 0.0
	var ic1eq := 0.0
	var ic2eq := 0.0
	var k_svf := 1.0 / maxf(q, 0.5)
	var pw := clampf(ancho_pulso, 0.1, 0.9)
	var fade_final := mini(int(0.012 * float(SR)), (i1 - i0) / 3)
	var tau_f := maxf(tau_freq, 0.0005)
	var tau_a := maxf(ataque_seg, 0.0004)
	var tau_d := maxf(caida_tau, 0.002)

	var g_svf := 0.0
	var a1 := 0.0
	var a2 := 0.0
	var a3 := 0.0
	var ratio_corte := maxf(corte_fin, 40.0) / maxf(corte_inicio, 40.0)
	var corte_constante := absf(corte_fin - corte_inicio) < 1.0

	for i in range(i0, i1):
		var local := i - i0
		var t := float(local) * inv_sr
		var frac := float(local) * inv_len

		var f := freq_fin + (freq_inicio - freq_fin) * exp(-t / tau_f)
		if vib_hz > 0.0 and vib_prof > 0.0:
			f *= 1.0 + vib_prof * sin(TAU * vib_hz * t)
		var dt := clampf(f * inv_sr, 0.0001, 0.42)
		fase = fmod(fase + dt, 1.0)

		var raw := 0.0
		if onda == 0:
			raw = 1.0 if fase < pw else -1.0
			raw += _poly_blep(fase, dt)
			var f2 := fase + 1.0 - pw
			if f2 >= 1.0:
				f2 -= 1.0
			raw -= _poly_blep(f2, dt)
		elif onda == 1:
			raw = (2.0 * fase - 1.0) - _poly_blep(fase, dt)
		else:
			raw = 1.0 - 4.0 * absf(fase - 0.5)

		if (local & 3) == 0 and (not corte_constante or local == 0):
			var cutoff := corte_inicio * pow(ratio_corte, frac)
			g_svf = tan(PI * clampf(cutoff, 40.0, float(SR) * 0.43) * inv_sr)
			a1 = 1.0 / (1.0 + g_svf * (g_svf + k_svf))
			a2 = g_svf * a1
			a3 = g_svf * a2
		var v3 := raw - ic2eq
		var v1 := a1 * ic1eq + a2 * v3
		var v2 := ic2eq + a2 * ic1eq + a3 * v3
		ic1eq = 2.0 * v1 - ic1eq
		ic2eq = 2.0 * v2 - ic2eq

		var env := (1.0 - exp(-t / tau_a)) * exp(-t / tau_d)
		var rem := i1 - 1 - i
		if rem < fade_final and fade_final > 0:
			env *= 0.5 * (1.0 - cos(PI * float(rem) / float(fade_final)))

		var out := v2 * env * amplitud
		l[i] += out * gp.x
		r[i] += out * gp.y


## Sintetizador FM de 2 operadores ideal para campanas digitales, cristales XP, monedas y zaps arcade.
static func agregar_fm_arcade(
		buf: Dictionary,
		inicio_seg: float,
		duracion_seg: float,
		freq_inicio: float,
		freq_fin: float,
		tau_freq: float,
		ratio_mod: float,
		indice_fm: float,
		tau_indice: float,
		amplitud: float,
		tau_ataque: float = 0.002,
		tau_caida: float = 0.14,
		pan: float = 0.0
	) -> void:
	var l: PackedFloat32Array = buf["l"]
	var r: PackedFloat32Array = buf["r"]
	var n_total: int = buf["n"]
	var i0 := clampi(int(inicio_seg * float(SR)), 0, n_total)
	var i1 := clampi(i0 + int(duracion_seg * float(SR)), i0, n_total)
	if i1 <= i0:
		return

	var inv_sr := 1.0 / float(SR)
	var gp := _ganancias_pan(pan)
	var fase_c := 0.0
	var fase_m := 0.0
	var fade_final := mini(int(0.012 * float(SR)), (i1 - i0) / 3)
	var tau_f := maxf(tau_freq, 0.0005)
	var tau_i := maxf(tau_indice, 0.001)
	var tau_a := maxf(tau_ataque, 0.0004)
	var tau_d := maxf(tau_caida, 0.002)

	for i in range(i0, i1):
		var local := i - i0
		var t := float(local) * inv_sr
		var f := freq_fin + (freq_inicio - freq_fin) * exp(-t / tau_f)
		fase_c += TAU * f * inv_sr
		fase_m += TAU * (f * ratio_mod) * inv_sr

		var mod := sin(fase_m) * indice_fm * exp(-t / tau_i)
		var env := (1.0 - exp(-t / tau_a)) * exp(-t / tau_d)
		var rem := i1 - 1 - i
		if rem < fade_final and fade_final > 0:
			env *= 0.5 * (1.0 - cos(PI * float(rem) / float(fade_final)))

		var out := sin(fase_c + mod) * env * amplitud
		l[i] += out * gp.x
		r[i] += out * gp.y


## Curva de pitch elástica estilo "Super Bonk" (subida-bajada o rebote caricaturesco en 3 puntos).
static func agregar_rebote_cartoon(
		buf: Dictionary,
		inicio_seg: float,
		duracion_seg: float,
		f_ini: float,
		f_pico: float,
		f_fin: float,
		frac_pico: float,
		amplitud: float,
		brillo_armonico: float = 0.25,
		pan: float = 0.0
	) -> void:
	var l: PackedFloat32Array = buf["l"]
	var r: PackedFloat32Array = buf["r"]
	var n_total: int = buf["n"]
	var i0 := clampi(int(inicio_seg * float(SR)), 0, n_total)
	var i1 := clampi(i0 + int(duracion_seg * float(SR)), i0, n_total)
	if i1 <= i0:
		return

	var inv_sr := 1.0 / float(SR)
	var inv_len := 1.0 / float(maxi(1, i1 - i0 - 1))
	var gp := _ganancias_pan(pan)
	var fase := 0.0
	var fp := clampf(frac_pico, 0.05, 0.9)
	var fade_in := mini(int(0.002 * float(SR)), (i1 - i0) / 5)
	var fade_out := mini(int(0.015 * float(SR)), (i1 - i0) / 3)

	for i in range(i0, i1):
		var local := i - i0
		var frac := float(local) * inv_len
		var f := f_ini
		if frac < fp:
			var u := frac / fp
			f = lerpf(f_ini, f_pico, sin(u * PI * 0.5))
		else:
			var u2 := (frac - fp) / maxf(0.001, 1.0 - fp)
			f = lerpf(f_pico, f_fin, u2 * u2)
		fase += TAU * f * inv_sr

		var env := 1.0 - pow(frac, 1.8) * 0.65
		if local < fade_in and fade_in > 0:
			env *= float(local) / float(fade_in)
		var rem := i1 - 1 - i
		if rem < fade_out and fade_out > 0:
			env *= 0.5 * (1.0 - cos(PI * float(rem) / float(fade_out)))

		var wave := sin(fase) + sin(fase * 2.0) * brillo_armonico
		var out := wave * env * amplitud
		l[i] += out * gp.x
		r[i] += out * gp.y


## Agrega un tono tipo campana/chime digital brillante y limpia.
static func agregar_nota_campana(
		buf: Dictionary,
		inicio_seg: float,
		duracion_seg: float,
		freq: float,
		amplitud: float,
		brillo: float = 0.45,
		tau_caida: float = 0.18,
		pan: float = 0.0
	) -> void:
	agregar_fm_arcade(buf, inicio_seg, duracion_seg, freq, freq, 0.01, 2.0, 1.2 * brillo, tau_caida * 0.45, amplitud * 0.72, 0.002, tau_caida, pan)
	agregar_tono_modal(buf, inicio_seg, duracion_seg * 0.65, freq * 2.0, freq * 2.0, 0.01, amplitud * 0.24 * brillo, 0.002, tau_caida * 0.5, -pan * 0.6)


## Agrega un sonido metálico modal brillante (parry / escudo energético arcade).
static func agregar_metal_modal(
		buf: Dictionary,
		inicio_seg: float,
		duracion_seg: float,
		freq_base: float,
		amplitud: float,
		pan: float = 0.0
	) -> void:
	var modos := [
		[1.00, 0.52, 0.14, 0.0],
		[1.50, 0.34, 0.11, -0.25],
		[2.24, 0.20, 0.075, 0.28],
		[2.98, 0.11, 0.045, -0.15],
	]
	for m in modos:
		var f := freq_base * float(m[0])
		if f > float(SR) * 0.42:
			continue
		agregar_tono_modal(
			buf,
			inicio_seg,
			duracion_seg,
			f * 1.02,
			f,
			0.008,
			amplitud * float(m[1]),
			0.002,
			float(m[2]),
			clampf(pan + float(m[3]), -1.0, 1.0)
		)


## Ruido rosa suave pasado por un filtro SVF TPT (Zavalishin, incondicionalmente estable)
## con barrido de frecuencia de corte, envolvente suave y opcional LFO de paneo estéreo.
static func agregar_ruido_filtrado(
		buf: Dictionary,
		inicio_seg: float,
		duracion_seg: float,
		tipo_filtro: String,
		corte_inicio: float,
		corte_fin: float,
		q: float,
		amplitud: float,
		frac_pico: float = 0.25,
		pan: float = 0.0,
		lfo_pan_hz: float = 0.0,
		semilla: int = 4242
	) -> void:
	var l: PackedFloat32Array = buf["l"]
	var r: PackedFloat32Array = buf["r"]
	var n_total: int = buf["n"]
	var i0 := clampi(int(inicio_seg * float(SR)), 0, n_total)
	var i1 := clampi(i0 + int(duracion_seg * float(SR)), i0, n_total)
	if i1 <= i0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = semilla

	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var b3 := 0.0
	var b4 := 0.0
	var b5 := 0.0
	var b6 := 0.0

	var ic1eq := 0.0
	var ic2eq := 0.0
	var k := 1.0 / maxf(q, 0.5)
	var inv_sr := 1.0 / float(SR)
	var inv_len := 1.0 / float(maxi(1, i1 - i0 - 1))
	var pico_pos := clampf(frac_pico, 0.02, 0.95)
	var es_bandpass := (tipo_filtro == "bandpass")
	var es_highpass := (tipo_filtro == "highpass")
	var ratio_corte := maxf(corte_fin, 25.0) / maxf(corte_inicio, 25.0)
	var g_svf := 0.0
	var a1 := 0.0
	var a2 := 0.0
	var a3 := 0.0

	for i in range(i0, i1):
		var local := i - i0
		var frac := float(local) * inv_len
		var t := float(local) * inv_sr

		var white := rng.randf_range(-1.0, 1.0)
		b0 = 0.99886 * b0 + white * 0.0555179
		b1 = 0.99332 * b1 + white * 0.0750759
		b2 = 0.96900 * b2 + white * 0.1538520
		b3 = 0.86650 * b3 + white * 0.3104856
		b4 = 0.55000 * b4 + white * 0.5329522
		b5 = -0.7616 * b5 - white * 0.0168980
		var pink := (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11
		b6 = white * 0.115926

		if (local & 3) == 0:
			var cutoff := corte_inicio * pow(ratio_corte, frac)
			g_svf = tan(PI * clampf(cutoff, 25.0, float(SR) * 0.44) * inv_sr)
			a1 = 1.0 / (1.0 + g_svf * (g_svf + k))
			a2 = g_svf * a1
			a3 = g_svf * a2

		var v3 := pink - ic2eq
		var v1 := a1 * ic1eq + a2 * v3
		var v2 := ic2eq + a2 * ic1eq + a3 * v3
		ic1eq = 2.0 * v1 - ic1eq
		ic2eq = 2.0 * v2 - ic2eq

		var filtrada := v2
		if es_bandpass:
			filtrada = v1
		elif es_highpass:
			filtrada = pink - k * v1 - v2

		var env := 0.0
		if frac < pico_pos:
			env = 0.5 * (1.0 - cos(PI * (frac / pico_pos)))
		else:
			var tail_f := (frac - pico_pos) / maxf(0.001, 1.0 - pico_pos)
			env = pow(0.5 * (1.0 + cos(PI * tail_f)), 1.35)

		var p_actual := pan
		if lfo_pan_hz > 0.0:
			p_actual = clampf(pan + sin(TAU * lfo_pan_hz * t) * 0.65, -1.0, 1.0)
		var gp := _ganancias_pan(p_actual)

		var out := filtrada * env * amplitud
		l[i] += out * gp.x
		r[i] += out * gp.y


## Percusión arcade rápida: bombo synth (punch=true) o caja/palmada digital (punch=false).
static func agregar_percusion_arcade(
		buf: Dictionary,
		inicio_seg: float,
		es_bombo: bool,
		amplitud: float,
		pan: float = 0.0,
		semilla: int = 777
	) -> void:
	if es_bombo:
		agregar_tono_modal(buf, inicio_seg, 0.14, 185.0, 48.0, 0.022, amplitud * 0.9, 0.001, 0.042, pan)
		agregar_ruido_filtrado(buf, inicio_seg, 0.035, "bandpass", 1200.0, 400.0, 1.2, amplitud * 0.25, 0.1, pan, 0.0, semilla)
	else:
		agregar_tono_modal(buf, inicio_seg, 0.06, 290.0, 140.0, 0.012, amplitud * 0.45, 0.001, 0.020, pan)
		agregar_ruido_filtrado(buf, inicio_seg, 0.09, "bandpass", 2400.0, 950.0, 1.0, amplitud * 0.62, 0.12, pan, 0.0, semilla)


## Aplica reflexiones tempranas estéreo cálidas con amortiguamiento de agudos.
static func aplicar_reverb_estereo(
		buf: Dictionary,
		mezcla: float = 0.20,
		decaimiento: float = 0.32
	) -> void:
	var l: PackedFloat32Array = buf["l"]
	var r: PackedFloat32Array = buf["r"]
	var n: int = buf["n"]
	if mezcla <= 0.0 or n < 64:
		return

	var d1 := int(0.013 * float(SR))
	var d2 := int(0.021 * float(SR))
	var d3 := int(0.031 * float(SR))
	var d4 := int(0.043 * float(SR))

	var wet_l := PackedFloat32Array()
	var wet_r := PackedFloat32Array()
	wet_l.resize(n)
	wet_r.resize(n)

	var fb := clampf(decaimiento, 0.05, 0.55)
	var lp_l := 0.0
	var lp_r := 0.0

	for i in range(n):
		var sl := l[i]
		var sr_val := r[i]
		var tap_l := 0.0
		var tap_r := 0.0
		if i >= d1:
			tap_l += wet_r[i - d1] * 0.45 + l[i - d1] * 0.35
			tap_r += wet_l[i - d1] * 0.45 + r[i - d1] * 0.35
		if i >= d2:
			tap_l += wet_l[i - d2] * 0.30 + r[i - d2] * 0.25
			tap_r += wet_r[i - d2] * 0.30 + l[i - d2] * 0.25
		if i >= d3:
			tap_l += wet_r[i - d3] * 0.20
			tap_r += wet_l[i - d3] * 0.20
		if i >= d4:
			tap_l += wet_l[i - d4] * 0.15
			tap_r += wet_r[i - d4] * 0.15

		lp_l = lp_l * 0.55 + (sl * 0.3 + tap_l * fb) * 0.45
		lp_r = lp_r * 0.55 + (sr_val * 0.3 + tap_r * fb) * 0.45
		wet_l[i] = lp_l
		wet_r[i] = lp_r

	var dry := 1.0 - mezcla * 0.35
	for i in range(n):
		l[i] = l[i] * dry + wet_l[i] * mezcla
		r[i] = r[i] * dry + wet_r[i] * mezcla


## Limpia offset DC, suaviza bordes, aplica saturación blanda de seguridad y normaliza
## al pico objetivo para exportar a WAV 16-bit estéreo sin distorsión.
static func masterizar_wav_16bit(buf: Dictionary, pico_objetivo: float = 0.52) -> AudioStreamWAV:
	var l: PackedFloat32Array = buf["l"]
	var r: PackedFloat32Array = buf["r"]
	var n: int = buf["n"]

	var x_prev_l := 0.0
	var y_prev_l := 0.0
	var x_prev_r := 0.0
	var y_prev_r := 0.0
	var r_dc := 0.9975
	for i in range(n):
		var xl := l[i]
		var yl := xl - x_prev_l + r_dc * y_prev_l
		x_prev_l = xl
		y_prev_l = yl
		l[i] = yl

		var xr := r[i]
		var yr := xr - x_prev_r + r_dc * y_prev_r
		x_prev_r = xr
		y_prev_r = yr
		r[i] = yr

	var fade_in := mini(int(0.0015 * float(SR)), n / 6)
	var fade_out := mini(int(0.015 * float(SR)), n / 3)
	for i in range(fade_in):
		var w := 0.5 * (1.0 - cos(PI * float(i) / float(fade_in)))
		l[i] *= w
		r[i] *= w
	for k in range(fade_out):
		var idx := n - 1 - k
		var w := 0.5 * (1.0 - cos(PI * float(k) / float(fade_out)))
		l[idx] *= w
		r[idx] *= w

	var pico := 0.0
	for i in range(n):
		var al := absf(l[i])
		var ar := absf(r[i])
		if al > pico:
			pico = al
		if ar > pico:
			pico = ar

	var target := clampf(pico_objetivo, 0.15, 0.68)
	var escala := 1.0
	if pico > 0.0001:
		escala = target / pico

	var bytes := PackedByteArray()
	bytes.resize(n * 4)
	for i in range(n):
		var vl := tanh(l[i] * escala)
		var vr := tanh(r[i] * escala)
		var sl := clampi(int(roundf(vl * 32760.0)), -32767, 32767)
		var sr_int := clampi(int(roundf(vr * 32760.0)), -32767, 32767)
		var off := i * 4
		bytes.encode_s16(off, sl)
		bytes.encode_s16(off + 2, sr_int)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo = true
	wav.data = bytes
	return wav
