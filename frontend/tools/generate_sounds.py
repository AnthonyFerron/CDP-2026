"""Génère les sons du jeu dans assets/audio/, sans dépendance externe.

Pour modifier un son, changer sa fonction dans ce script puis le relancer depuis le dossier frontend :

    python tools/generate_sounds.py

Les sons en boucle portent un bloc « smpl » : Godot les importe directement en boucle.
"""

import math
import random
import struct
from pathlib import Path

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "audio"
RATE = 22050


def lowpass(samples, cutoff):
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff / RATE)
    value = 0.0
    result = []
    for sample in samples:
        value += alpha * (sample - value)
        result.append(value)
    return result


def highpass(samples, cutoff):
    smooth = lowpass(samples, cutoff)
    return [a - b for a, b in zip(samples, smooth)]


def noise(count, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(count)]


def seamless(samples, length, fade):
    """Fond la fin du son dans son début pour une boucle sans saut."""
    result = samples[:length]
    for i in range(fade):
        mix = i / fade
        result[i] = samples[length + i] * (1.0 - mix) + result[i] * mix
    return result


def normalize(samples, peak=0.7):
    top = max(abs(s) for s in samples) or 1.0
    return [s * peak / top for s in samples]


def write_wav(name, samples, loop=False):
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
    chunks = b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, RATE, RATE * 2, 2, 16)
    if loop:
        smpl = struct.pack("<9I", 0, 0, int(1e9 / RATE), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, len(samples) - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    chunks += b"data" + struct.pack("<I", len(data)) + data
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUTPUT_DIR / name
    path.write_bytes(b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks)
    print(f"{path.name} : {len(samples) / RATE:.1f} s")


def wind():
    """Vent chaud et sec qui souffle par rafales, en boucle de 12 s."""
    rng = random.Random(1)
    length, fade = RATE * 12, RATE
    total = length + fade
    base = lowpass(lowpass(noise(total, rng), 500), 900)
    whistle = highpass(lowpass(noise(total, rng), 1400), 700)
    samples = []
    for i in range(total):
        t = i / RATE
        gust = 0.55 + 0.3 * math.sin(2 * math.pi * t / 6.0) + 0.15 * math.sin(2 * math.pi * t / 4.0 + 1.0)
        samples.append(base[i] * gust + whistle[i] * gust * gust * 0.6)
    return normalize(seamless(samples, length, fade), 0.6)


def lava():
    """Grondement sourd de la lave, avec des bulles qui éclatent, en boucle de 8 s."""
    rng = random.Random(2)
    length, fade = RATE * 8, RATE // 2
    total = length + fade
    rumble = lowpass(lowpass(noise(total, rng), 90), 120)
    samples = [r * (0.8 + 0.2 * math.sin(2 * math.pi * i / RATE / 2.0)) for i, r in enumerate(rumble)]
    samples = normalize(samples, 0.55)
    for _ in range(26):
        start = rng.randrange(0, total - RATE // 4)
        pitch = rng.uniform(70, 160)
        size = rng.uniform(0.15, 0.45)
        for i in range(RATE // 5):
            t = i / RATE
            envelope = math.exp(-t * 28) * (1 - math.exp(-t * 900))
            samples[start + i] += size * envelope * math.sin(2 * math.pi * pitch * t * (1 - t * 1.5))
    return normalize(seamless(samples, length, fade), 0.6)


def footstep(seed):
    """Pas sur la pierre ou la cendre : un talon feutré suivi d'un léger frottement, sans craquement aigu."""
    rng = random.Random(seed)
    count = int(RATE * 0.2)
    scuff = lowpass(lowpass(highpass(noise(count, rng), 150), rng.uniform(900, 1200)), 1400)
    thump_pitch = rng.uniform(70, 95)
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = (1 - math.exp(-t * 250)) * math.exp(-t * 28)
        thump = math.sin(2 * math.pi * thump_pitch * t) * math.exp(-t * 45) * (1 - math.exp(-t * 400))
        samples.append(scuff[i] * envelope * 0.8 + thump * 0.45)
    return normalize(samples, 0.45)


def add_event(samples, start, event):
    """Ajoute un son court dans une boucle, en repassant au début s'il dépasse la fin."""
    for i, value in enumerate(event):
        samples[(start + i) % len(samples)] += value


def swamp():
    """Nuit au marais : clapotis, grillons et grenouilles, en boucle de 12 s."""
    rng = random.Random(3)
    length, fade = RATE * 12, RATE
    water = lowpass(lowpass(noise(length + fade, rng), 300), 400)
    samples = seamless([w * (0.7 + 0.3 * math.sin(2 * math.pi * i / RATE / 3.0)) for i, w in enumerate(water)], length, fade)
    samples = normalize(samples, 0.25)
    for _ in range(46):
        start = rng.randrange(length)
        pitch = rng.uniform(4200, 5200)
        chirp = []
        for i in range(int(RATE * 0.12)):
            t = i / RATE
            gate = 1.0 if math.sin(2 * math.pi * 55 * t) > 0 else 0.0
            chirp.append(0.05 * gate * math.sin(2 * math.pi * pitch * t) * math.exp(-t * 12))
        add_event(samples, start, chirp)
    for _ in range(7):
        start = rng.randrange(length)
        pitch = rng.uniform(110, 190)
        croak = []
        for i in range(int(RATE * 0.35)):
            t = i / RATE
            pulse = 0.5 + 0.5 * math.sin(2 * math.pi * 28 * t)
            tone = math.sin(2 * math.pi * pitch * t) + 0.5 * math.sin(2 * math.pi * pitch * 2.1 * t)
            croak.append(0.22 * tone * pulse * math.exp(-t * 6) * (1 - math.exp(-t * 200)))
        add_event(samples, start, croak)
    return normalize(samples, 0.6)


def mud_step(seed):
    """Pas dans la boue : un bruit sourd et collant."""
    rng = random.Random(seed)
    count = int(RATE * 0.28)
    squelch = lowpass(highpass(noise(count, rng), 180), rng.uniform(700, 1000))
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = (1 - math.exp(-t * 200)) * math.exp(-t * 16)
        wobble = 1.0 + 0.35 * math.sin(2 * math.pi * rng.uniform(25, 35) * t)
        samples.append(squelch[i] * envelope * wobble + math.sin(2 * math.pi * 60 * t) * math.exp(-t * 30) * 0.4)
    return normalize(samples, 0.42)


def splash_step(seed):
    """Pas dans l'eau peu profonde : une gerbe, puis des gouttes."""
    rng = random.Random(seed)
    count = int(RATE * 0.4)
    spray = lowpass(highpass(noise(count, rng), 700), 3000)
    samples = [spray[i] * (1 - math.exp(-i / RATE * 200)) * math.exp(-i / RATE * 14) for i in range(count)]
    for _ in range(5):
        start = rng.randrange(int(RATE * 0.08), int(RATE * 0.3))
        pitch = rng.uniform(900, 1800)
        for i in range(int(RATE * 0.05)):
            t = i / RATE
            if start + i < count:
                samples[start + i] += 0.2 * math.sin(2 * math.pi * pitch * (1 + t * 6) * t) * math.exp(-t * 70)
    return normalize(samples, 0.4)


def fire_crackle():
    """Feu qui crépite, en boucle de 6 s."""
    rng = random.Random(5)
    length, fade = RATE * 6, RATE // 2
    roar = lowpass(noise(length + fade, rng), 500)
    samples = normalize(seamless(roar, length, fade), 0.3)
    for _ in range(90):
        start = rng.randrange(length)
        size = rng.uniform(0.2, 0.8)
        crack = [size * rng.uniform(-1, 1) * math.exp(-i / RATE * 400) for i in range(int(RATE * 0.02))]
        add_event(samples, start, crack)
    return normalize(samples, 0.55)


def fire_ignite():
    """Souffle d'un feu qui prend."""
    rng = random.Random(6)
    count = int(RATE * 0.7)
    base = noise(count, rng)
    samples = []
    cutoff_low = lowpass(base, 400)
    cutoff_high = lowpass(base, 2500)
    for i in range(count):
        t = i / RATE
        mix = min(1.0, t / 0.35)
        envelope = (1 - math.exp(-t * 30)) * math.exp(-t * 4.5)
        samples.append(envelope * (cutoff_low[i] * (1 - mix) + cutoff_high[i] * mix))
    return normalize(samples, 0.7)


def stone_door():
    """Lourde porte de pierre qui pivote en raclant le sol."""
    rng = random.Random(7)
    count = int(RATE * 2.6)
    grind = lowpass(noise(count, rng), 260)
    rough = lowpass(noise(count, rng), 18)
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = min(1.0, t / 0.15) * min(1.0, (2.6 - t) / 0.4)
        samples.append(grind[i] * envelope * (0.6 + 2.5 * abs(rough[i])))
    thud = [math.sin(2 * math.pi * 48 * i / RATE) * math.exp(-i / RATE * 9) for i in range(int(RATE * 0.5))]
    for i, value in enumerate(thud):
        samples[count - len(thud) + i] += value * 0.8
    return normalize(samples, 0.75)


def desert_wind():
    """Vent du désert qui charrie le sable, en boucle de 12 s."""
    rng = random.Random(8)
    length, fade = RATE * 12, RATE
    total = length + fade
    body = lowpass(noise(total, rng), 700)
    hiss = highpass(lowpass(noise(total, rng), 5000), 2000)
    samples = []
    for i in range(total):
        t = i / RATE
        gust = 0.5 + 0.35 * math.sin(2 * math.pi * t / 4.0) + 0.15 * math.sin(2 * math.pi * t / 3.0 + 2.0)
        samples.append(body[i] * gust + hiss[i] * gust * gust * 0.9)
    return normalize(seamless(samples, length, fade), 0.55)


def cave():
    """Cave fraîche : un souffle sourd et des gouttes qui tombent, en boucle de 10 s."""
    rng = random.Random(9)
    length, fade = RATE * 10, RATE
    hum = lowpass(lowpass(noise(length + fade, rng), 120), 160)
    samples = normalize(seamless(hum, length, fade), 0.3)
    for _ in range(9):
        start = rng.randrange(length)
        pitch = rng.uniform(1400, 2600)
        drop = [0.35 * math.sin(2 * math.pi * pitch * (1 - i / RATE * 4) * i / RATE) * math.exp(-i / RATE * 45)
                for i in range(int(RATE * 0.12))]
        add_event(samples, start, drop)
    return normalize(samples, 0.5)


def sand_step(seed):
    """Pas dans le sable : un glissement doux et granuleux."""
    rng = random.Random(seed)
    count = int(RATE * 0.25)
    grains = highpass(lowpass(lowpass(noise(count, rng), rng.uniform(1800, 2400)), 2600), 250)
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = (1 - math.exp(-t * 70)) * math.exp(-t * 15)
        samples.append(grains[i] * envelope + math.sin(2 * math.pi * 80 * t) * math.exp(-t * 50) * 0.15)
    return normalize(samples, 0.38)


def tablet_chime(pitch):
    """Note claire d'une tablette qui s'active."""
    count = int(RATE * 1.2)
    samples = []
    for i in range(count):
        t = i / RATE
        tone = math.sin(2 * math.pi * pitch * t) + 0.4 * math.sin(2 * math.pi * pitch * 2.01 * t)
        tone += 0.2 * math.sin(2 * math.pi * pitch * 3.02 * t)
        samples.append(tone * math.exp(-t * 3.5) * (1 - math.exp(-t * 400)))
    return normalize(samples, 0.6)


def tablet_reset():
    """Son grave et étouffé d'une séquence qui se dissipe."""
    rng = random.Random(10)
    count = int(RATE * 0.9)
    rumble = lowpass(noise(count, rng), 200)
    samples = []
    for i in range(count):
        t = i / RATE
        tone = math.sin(2 * math.pi * 110 * (1 - t * 0.4) * t)
        samples.append((tone * 0.6 + rumble[i] * 0.8) * math.exp(-t * 4) * (1 - math.exp(-t * 200)))
    return normalize(samples, 0.6)


def eruption():
    """Explosion du volcan : un coup sourd et brutal, puis un grondement qui roule pendant 6 s."""
    rng = random.Random(12)
    count = int(RATE * 6.5)
    blast = lowpass(noise(count, rng), 900)
    rumble = lowpass(lowpass(noise(count, rng), 120), 160)
    samples = []
    for i in range(count):
        t = i / RATE
        attack = 1 - math.exp(-t * 300)
        boom = math.sin(2 * math.pi * 42 * (1 - t * 0.3) * t) * math.exp(-t * 1.6)
        crack = blast[i] * math.exp(-t * 5)
        roll = rumble[i] * (0.9 + 0.3 * math.sin(t * 5.3)) * math.exp(-t * 0.45)
        samples.append((boom * 0.9 + crack * 0.8 + roll * 1.6) * attack)
    return normalize(samples, 0.85)


def hub():
    """Plateau du hub : une brise douce et quelques oiseaux, en boucle de 14 s."""
    rng = random.Random(11)
    length, fade = RATE * 14, RATE
    breeze = lowpass(lowpass(noise(length + fade, rng), 350), 500)
    samples = [b * (0.6 + 0.4 * math.sin(2 * math.pi * i / RATE / 7.0)) for i, b in enumerate(breeze)]
    samples = normalize(seamless(samples, length, fade), 0.3)
    for _ in range(10):
        start = rng.randrange(length)
        base = rng.uniform(2600, 3800)
        for note in range(rng.randint(2, 4)):
            pitch = base * rng.uniform(0.9, 1.25)
            chirp = []
            for i in range(int(RATE * 0.09)):
                t = i / RATE
                chirp.append(0.16 * math.sin(2 * math.pi * pitch * (1 + t * 4) * t) * math.sin(math.pi * t / 0.09))
            add_event(samples, start + note * int(RATE * 0.13), chirp)
    return normalize(samples, 0.5)


def grass_step(seed):
    """Pas dans l'herbe : un froissement court et doux."""
    rng = random.Random(seed)
    count = int(RATE * 0.22)
    rustle = highpass(lowpass(lowpass(noise(count, rng), rng.uniform(1200, 1600)), 1900), 250)
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = (1 - math.exp(-t * 120)) * math.exp(-t * 22)
        samples.append(rustle[i] * envelope + math.sin(2 * math.pi * 75 * t) * math.exp(-t * 45) * 0.35)
    return normalize(samples, 0.38)


def village():
    """Village en ruine au crépuscule : vent, bois qui grince et corbeaux au loin, en boucle de 14 s."""
    rng = random.Random(12)
    length, fade = RATE * 14, RATE
    gusts = lowpass(lowpass(noise(length + fade, rng), 420), 600)
    samples = [g * (0.55 + 0.45 * math.sin(2 * math.pi * i / RATE / 7.0)) for i, g in enumerate(gusts)]
    samples = normalize(seamless(samples, length, fade), 0.35)
    for _ in range(4):
        start = rng.randrange(length)
        pitch = rng.uniform(90, 140)
        creak = []
        for i in range(int(RATE * 0.9)):
            t = i / RATE
            sweep = pitch * (1 + 0.4 * math.sin(math.pi * t / 0.9))
            buzz = 1.0 if math.sin(2 * math.pi * sweep * t) > 0.6 else -0.3
            creak.append(0.08 * buzz * math.sin(math.pi * t / 0.9))
        add_event(samples, start, lowpass(creak, 900))
    for _ in range(5):
        start = rng.randrange(length)
        for call in range(rng.randint(2, 3)):
            caw = highpass(lowpass(noise(int(RATE * 0.28), rng), 1600), 500)
            caw = [c * 0.25 * math.sin(math.pi * i / len(caw)) * (0.6 + 0.4 * math.sin(2 * math.pi * 30 * i / RATE))
                   for i, c in enumerate(caw)]
            add_event(samples, start + call * int(RATE * 0.42), caw)
    return normalize(samples, 0.55)


def stream():
    """Ruisseau qui court sur les galets, en boucle de 6 s."""
    rng = random.Random(13)
    length, fade = RATE * 6, RATE // 2
    rush = highpass(lowpass(noise(length + fade, rng), 2400), 250)
    samples = normalize(seamless(rush, length, fade), 0.3)
    for _ in range(60):
        start = rng.randrange(length)
        pitch = rng.uniform(500, 1400)
        bubble = [0.12 * math.sin(2 * math.pi * pitch * (1 + i / RATE * 8) * i / RATE) * math.exp(-i / RATE * 60)
                  for i in range(int(RATE * 0.06))]
        add_event(samples, start, bubble)
    return normalize(samples, 0.5)


def bandpass(samples, low, high):
    return highpass(lowpass(samples, high), low)


def crackles(count, rng, density):
    """Craquements secs, épars : une impulsion au hasard, plus ou moins serrées selon density(x), x de 0 à 1."""
    return [rng.uniform(-1.0, 1.0) if rng.random() < density(i / count) else 0.0 for i in range(count)]


def echo(samples, taps):
    """Échos très courts d'une surface dure : (retard en secondes, gain) ; le son s'allonge d'autant."""
    longest = int(max(delay for delay, _ in taps) * RATE)
    result = samples + [0.0] * longest
    for delay, gain in taps:
        offset = int(delay * RATE)
        for i, value in enumerate(samples):
            result[i + offset] += value * gain
    return result


def wood_step(seed):
    """Pas sur un plancher, un pont ou un ponton : le talon frappe la planche, qui sonne creux un court instant,
    puis la semelle frotte le bois."""
    rng = random.Random(seed)
    count = int(RATE * 0.24)
    knock = bandpass(noise(count, rng), 900, 3500)
    scuff = bandpass(noise(count, rng), 300, 1600)
    body = rng.uniform(150.0, 185.0)
    # Modes de la planche, inharmoniques comme ceux du bois, et la solive plus grave dessous.
    modes = ((body, 26.0, 0.55), (body * rng.uniform(2.2, 2.45), 42.0, 0.3), (body * rng.uniform(3.7, 4.1), 62.0, 0.16),
             (rng.uniform(85.0, 100.0), 38.0, 0.35))
    samples = []
    for i in range(count):
        t = i / RATE
        attack = 1 - math.exp(-t * 900)
        tone = sum(gain * math.sin(2 * math.pi * pitch * t) * math.exp(-t * decay) for pitch, decay, gain in modes)
        click = knock[i] * math.exp(-t * 260) * 0.9
        rub = scuff[i] * (1 - math.exp(-t * 60)) * math.exp(-t * 22) * 0.25
        samples.append((tone + click) * attack + rub)
    return normalize(samples, 0.42)


def stone_step(seed):
    """Pas sur la pierre : le talon claque net sur la dalle, quelques grains crissent sous la semelle, et la pierre
    renvoie un écho très court. Plus sec et plus clair que le pas feutré sur la cendre."""
    rng = random.Random(seed)
    count = int(RATE * 0.2)
    snap = bandpass(noise(count, rng), 1800, 6000)
    grit = bandpass(crackles(count, rng, lambda x: 0.025 if 0.06 < x < 0.4 else 0.0), 2200, 7000)
    ring_pitch = rng.uniform(2300.0, 3200.0)
    thud_pitch = rng.uniform(95.0, 120.0)
    samples = []
    for i in range(count):
        t = i / RATE
        attack = 1 - math.exp(-t * 2500)
        click = snap[i] * math.exp(-t * 170)
        ring = 0.22 * math.sin(2 * math.pi * ring_pitch * t) * math.exp(-t * 95)
        thud = 0.42 * math.sin(2 * math.pi * thud_pitch * t) * math.exp(-t * 55)
        samples.append((click + ring + thud) * attack + grit[i] * 0.7 * math.exp(-t * 15))
    samples = echo(samples, ((0.017, 0.16), (0.031, 0.07)))
    # Le claquement est bref : sa crête monte plus haut que celle des autres pas pour une même force perçue.
    return normalize(samples, 0.62)


def ui_click():
    """Clic d'un bouton des menus : un petit coup sec sur du bois, très court."""
    rng = random.Random(60)
    count = int(RATE * 0.09)
    tick = bandpass(noise(count, rng), 2000, 6500)
    modes = ((1150.0, 70.0, 0.6), (1830.0, 95.0, 0.35), (2720.0, 130.0, 0.2), (420.0, 60.0, 0.25))
    samples = []
    for i in range(count):
        t = i / RATE
        tone = sum(gain * math.sin(2 * math.pi * pitch * t) * math.exp(-t * decay) for pitch, decay, gain in modes)
        samples.append((tone + tick[i] * math.exp(-t * 600) * 0.8) * (1 - math.exp(-t * 3000)))
    return normalize(samples, 0.5)


def parchment(rng, count, opening):
    """Parchemin qu'on déroule (opening) ou qu'on replie : un souffle de papier et des craquements secs. Le papier
    s'éclaircit en se déroulant et s'assourdit en se repliant."""
    breath = noise(count, rng)
    bright = bandpass(breath, 1600, 6000)
    dull = bandpass(breath, 700, 2600)
    crackle = bandpass(crackles(count, rng, lambda x: 0.015 + 0.09 * math.sin(math.pi * x) ** 2), 1500, 7000)
    samples = []
    for i in range(count):
        x = i / count
        envelope = math.sin(math.pi * x) ** 1.5
        mix = x if opening else 1.0 - x
        paper = bright[i] * mix + dull[i] * (1.0 - mix)
        samples.append(envelope * (paper * 0.55 + crackle[i] * 1.7))
    return samples


def small_bell(count, pitch, decay):
    """Clochette : partiels inharmoniques d'une petite cloche, les aigus s'éteignant plus vite."""
    partials = ((1.0, 1.0), (2.0, 0.42), (2.76, 0.3), (5.4, 0.1))
    samples = []
    for i in range(count):
        t = i / RATE
        tone = sum(gain * math.sin(2 * math.pi * pitch * ratio * t) * math.exp(-t * decay * (0.7 + 0.3 * ratio))
                   for ratio, gain in partials)
        samples.append(tone * (1 - math.exp(-t * 500)))
    return samples


def ui_open():
    """Ouverture d'un panneau (énigme, texte lu, indice, pause) : un parchemin qui se déroule, puis une clochette
    discrète, sur le sol des notes des tablettes (do, mi, sol)."""
    rng = random.Random(61)
    count = int(RATE * 1.0)
    paper = normalize(parchment(rng, int(RATE * 0.3), True), 0.55)
    bell = normalize(small_bell(int(RATE * 0.85), 1567.98, 5.5), 0.22)
    samples = [0.0] * count
    for i, value in enumerate(paper):
        samples[i] += value
    start = int(RATE * 0.14)
    for i, value in enumerate(bell):
        samples[start + i] += value
    return normalize(samples, 0.5)


def ui_close():
    """Fermeture d'un panneau : le parchemin qu'on replie, puis un petit coup de bois sourd, comme un coffret
    qu'on referme."""
    rng = random.Random(62)
    count = int(RATE * 0.45)
    paper = normalize(parchment(rng, int(RATE * 0.22), False), 0.5)
    lid = []
    thump = lowpass(noise(int(RATE * 0.2), rng), 900)
    for i in range(int(RATE * 0.2)):
        t = i / RATE
        tone = 0.6 * math.sin(2 * math.pi * 185.0 * t) * math.exp(-t * 32) + 0.3 * math.sin(2 * math.pi * 430.0 * t) * math.exp(-t * 55)
        lid.append((tone + thump[i] * 0.8 * math.exp(-t * 70)) * (1 - math.exp(-t * 1500)))
    lid = normalize(lid, 0.42)
    samples = [0.0] * count
    for i, value in enumerate(paper):
        samples[i] += value
    start = int(RATE * 0.17)
    for i, value in enumerate(lid):
        samples[start + i] += value
    return normalize(samples, 0.48)


def river():
    """Rivière large et lente du hub : un courant sourd, des remous qui gargouillent et un léger chuintement d'eau
    sur les pierres, en boucle de 6 s. Plus grave et plus pleine que le ruisseau (stream)."""
    rng = random.Random(14)
    length, fade = RATE * 6, RATE // 2
    total = length + fade
    rush = lowpass(lowpass(noise(total, rng), 650), 900)
    hiss = bandpass(noise(total, rng), 1800, 4200)
    samples = []
    for i in range(total):
        t = i / RATE
        # Houle lente, sur des périodes qui divisent la boucle.
        swell = 0.8 + 0.12 * math.sin(2 * math.pi * t / 6.0) + 0.08 * math.sin(2 * math.pi * t / 2.0 + 1.3)
        samples.append(rush[i] * swell + hiss[i] * 0.18 * (0.7 + 0.3 * math.sin(2 * math.pi * t / 3.0)))
    samples = normalize(seamless(samples, length, fade), 0.32)
    for _ in range(170):
        start = rng.randrange(length)
        pitch = rng.uniform(220.0, 820.0)
        size = rng.uniform(0.04, 0.13)
        decay = rng.uniform(35.0, 70.0)
        bubble = [size * math.sin(2 * math.pi * pitch * (1 + i / RATE * 5) * i / RATE) * math.exp(-i / RATE * decay)
                  * (1 - math.exp(-i / RATE * 800)) for i in range(int(RATE * 0.08))]
        add_event(samples, start, bubble)
    return normalize(samples, 0.55)


def leaves():
    """Feuillage du jardin du roi : des feuilles froissées par la brise, par vagues, avec le petit crépitement des
    feuilles qui se touchent, et un souffle grave, en boucle de 8 s."""
    rng = random.Random(15)
    length, fade = RATE * 8, RATE
    total = length + fade
    rustle = bandpass(lowpass(noise(total, rng), 5000), 1200, 5000)
    flutter = normalize(lowpass(lowpass(noise(total, rng), 18), 24), 1.0)
    breeze = lowpass(lowpass(noise(total, rng), 220), 320)
    breeze = normalize(breeze, 1.0)
    patter = bandpass(crackles(total, rng, lambda x: 0.004), 1800, 7000)
    samples = []
    for i in range(total):
        t = i / RATE
        gust = 0.5 + 0.3 * math.sin(2 * math.pi * t / 8.0 + 0.4) + 0.2 * math.sin(2 * math.pi * t / 2.0 + 2.1)
        gust = max(0.05, gust)
        samples.append(rustle[i] * gust * (0.55 + 0.45 * flutter[i]) + patter[i] * 0.9 * gust * gust
                       + breeze[i] * 0.06 * (0.6 + 0.4 * gust))
    return normalize(seamless(samples, length, fade), 0.5)


def bird_note(start, end, duration, vibrato=0.0, rate=0.0, gain=1.0):
    """Note d'oiseau : un sifflement qui glisse d'une hauteur à l'autre, attaqué vite et éteint plus doucement, avec un
    léger vibrato et un frémissement rapide du gosier, pour ne pas sonner comme un bip."""
    count = int(RATE * duration)
    samples = []
    phase = 0.0
    for i in range(count):
        x = i / count
        t = i / RATE
        pitch = (start + (end - start) * x) * (1 + vibrato * math.sin(2 * math.pi * rate * t))
        pitch *= 1 + 0.012 * math.sin(2 * math.pi * 85.0 * t)
        phase += 2 * math.pi * pitch / RATE
        harmonic = 0.12 * math.sin(2 * phase) if pitch * 2 < 10000 else 0.0
        envelope = math.sin(math.pi / 2 * x / 0.15) if x < 0.15 else (1 - (x - 0.15) / 0.85) ** 0.7
        samples.append(gain * envelope * (math.sin(phase) + harmonic))
    return samples


def bird_song(notes):
    """Chant fait de notes (début, fin, durée, silence après, vibrato, fréquence du vibrato, gain)."""
    samples = []
    for start, end, duration, gap, vibrato, rate, gain in notes:
        samples += bird_note(start, end, duration, vibrato, rate, gain)
        samples += [0.0] * int(RATE * gap)
    return normalize(samples, 0.5)


def bird(kind):
    """Trois oiseaux du jardin : une phrase de rouge-gorge, l'appel « ti-tu » d'une mésange, le trille d'un pinson."""
    rng = random.Random(70 + kind)
    if kind == 0:
        notes = [(3200, 3900, 0.07, 0.04, 0.01, 40, 0.8), (4100, 3600, 0.06, 0.035, 0.0, 0, 0.9),
                 (2800, 3400, 0.09, 0.05, 0.02, 35, 1.0), (3900, 4400, 0.05, 0.03, 0.0, 0, 0.7),
                 (4400, 3800, 0.05, 0.06, 0.0, 0, 0.75), (3100, 2650, 0.13, 0.02, 0.03, 30, 0.85)]
    elif kind == 1:
        notes = []
        for _ in range(3):
            high = rng.uniform(4150, 4350)
            notes += [(high, high - 120, 0.07, 0.05, 0.0, 0, 0.9), (3250, 3100, 0.09, 0.1, 0.0, 0, 1.0)]
    else:
        notes = [(5200 - k * 70, 4700 - k * 70, 0.035, 0.022, 0.0, 0, 0.6 + 0.03 * k) for k in range(11)]
        notes += [(3700, 2800, 0.16, 0.02, 0.025, 45, 1.0)]
    return bird_song(notes)


def main():
    write_wav("plaine_wind.wav", wind(), loop=True)
    write_wav("plaine_lava.wav", lava(), loop=True)
    for index in range(4):
        write_wav(f"footstep_ash_{index + 1}.wav", footstep(10 + index))
    write_wav("marais_ambience.wav", swamp(), loop=True)
    for index in range(3):
        write_wav(f"footstep_mud_{index + 1}.wav", mud_step(20 + index))
        write_wav(f"footstep_splash_{index + 1}.wav", splash_step(30 + index))
    write_wav("fire_crackle.wav", fire_crackle(), loop=True)
    write_wav("fire_ignite.wav", fire_ignite())
    write_wav("stone_door.wav", stone_door())
    write_wav("desert_wind.wav", desert_wind(), loop=True)
    write_wav("cave_ambience.wav", cave(), loop=True)
    for index in range(3):
        write_wav(f"footstep_sand_{index + 1}.wav", sand_step(40 + index))
    for index, pitch in enumerate((523.25, 659.25, 783.99)):
        write_wav(f"tablet_chime_{index + 1}.wav", tablet_chime(pitch))
    write_wav("tablet_reset.wav", tablet_reset())
    write_wav("volcano_eruption.wav", eruption())
    write_wav("hub_ambience.wav", hub(), loop=True)
    write_wav("village_ambience.wav", village(), loop=True)
    write_wav("stream.wav", stream(), loop=True)
    for index in range(3):
        write_wav(f"footstep_grass_{index + 1}.wav", grass_step(50 + index))
    for index in range(3):
        write_wav(f"footstep_wood_{index + 1}.wav", wood_step(80 + index))
        write_wav(f"footstep_stone_{index + 1}.wav", stone_step(90 + index))
    write_wav("ui_click.wav", ui_click())
    write_wav("ui_open.wav", ui_open())
    write_wav("ui_close.wav", ui_close())
    write_wav("river.wav", river(), loop=True)
    write_wav("park_leaves.wav", leaves(), loop=True)
    for kind in range(3):
        write_wav(f"bird_{kind + 1}.wav", bird(kind))


if __name__ == "__main__":
    main()
