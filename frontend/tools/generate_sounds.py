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
    """Pas sur un sol de cendre et de cailloux."""
    rng = random.Random(seed)
    count = int(RATE * 0.22)
    crunch = highpass(lowpass(noise(count, rng), rng.uniform(2200, 3200)), 300)
    thump_pitch = rng.uniform(65, 90)
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = (1 - math.exp(-t * 600)) * math.exp(-t * rng.uniform(22, 30))
        grit = crunch[i] * (0.6 + 0.4 * (rng.random() > 0.7))
        thump = math.sin(2 * math.pi * thump_pitch * t) * math.exp(-t * 40)
        samples.append(envelope * grit + thump * 0.5)
    return normalize(samples, 0.7)


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
        envelope = (1 - math.exp(-t * 300)) * math.exp(-t * 16)
        wobble = 1.0 + 0.5 * math.sin(2 * math.pi * rng.uniform(25, 35) * t)
        samples.append(squelch[i] * envelope * wobble + math.sin(2 * math.pi * 60 * t) * math.exp(-t * 30) * 0.4)
    return normalize(samples, 0.65)


def splash_step(seed):
    """Pas dans l'eau peu profonde : une gerbe, puis des gouttes."""
    rng = random.Random(seed)
    count = int(RATE * 0.4)
    spray = highpass(noise(count, rng), 900)
    samples = [spray[i] * (1 - math.exp(-i / RATE * 400)) * math.exp(-i / RATE * 14) for i in range(count)]
    for _ in range(5):
        start = rng.randrange(int(RATE * 0.08), int(RATE * 0.3))
        pitch = rng.uniform(900, 1800)
        for i in range(int(RATE * 0.05)):
            t = i / RATE
            if start + i < count:
                samples[start + i] += 0.3 * math.sin(2 * math.pi * pitch * (1 + t * 6) * t) * math.exp(-t * 70)
    return normalize(samples, 0.6)


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
    grains = highpass(lowpass(noise(count, rng), rng.uniform(3500, 4500)), 600)
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = (1 - math.exp(-t * 120)) * math.exp(-t * 14)
        samples.append(grains[i] * envelope)
    return normalize(samples, 0.55)


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
    rustle = highpass(lowpass(noise(count, rng), rng.uniform(1800, 2600)), 400)
    samples = []
    for i in range(count):
        t = i / RATE
        envelope = (1 - math.exp(-t * 200)) * math.exp(-t * 20)
        samples.append(rustle[i] * envelope + math.sin(2 * math.pi * 75 * t) * math.exp(-t * 45) * 0.3)
    return normalize(samples, 0.5)


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
    write_wav("hub_ambience.wav", hub(), loop=True)
    write_wav("village_ambience.wav", village(), loop=True)
    write_wav("stream.wav", stream(), loop=True)
    for index in range(3):
        write_wav(f"footstep_grass_{index + 1}.wav", grass_step(50 + index))


if __name__ == "__main__":
    main()
