"""Génère les sons de la Plaine dans assets/audio/, sans dépendance externe.

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


def main():
    write_wav("plaine_wind.wav", wind(), loop=True)
    write_wav("plaine_lava.wav", lava(), loop=True)
    for index in range(4):
        write_wav(f"footstep_ash_{index + 1}.wav", footstep(10 + index))


if __name__ == "__main__":
    main()
