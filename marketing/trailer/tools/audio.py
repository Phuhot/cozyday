#!/usr/bin/env python3
"""Nhạc nền + hiệu ứng âm thanh gốc cho trailer, tổng hợp hoàn toàn bằng numpy (không dùng mẫu âm thanh ngoài).

Nhạc: 120 BPM, Đô trưởng, vòng hợp âm C – Am – F – G, tiếng kalimba gảy, bass tròn, trống nhẹ.
Hiệu ứng (pop, vút, đồng xu, lấp lánh, tick) đặt theo mốc trong timeline.py.
"""
import sys, wave
import numpy as np
import timeline as T

SR = 48000
N = int(SR * T.DURATION)
rng = np.random.default_rng(7)


def note_hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env(n, a=0.005, d=0.4):
    t = np.arange(n) / SR
    e = np.minimum(1, t / a) * np.exp(-t / d)
    return e


def add(buf, start, sig, gain=1.0):
    i = int(start * SR)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i] * gain


def kalimba(midi, dur=0.9):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = note_hz(midi)
    s = np.sin(2 * np.pi * f * t) * env(n, 0.003, 0.35)
    s += 0.35 * np.sin(2 * np.pi * f * 4.02 * t) * env(n, 0.002, 0.05)
    s += 0.12 * np.sin(2 * np.pi * f * 2 * t) * env(n, 0.003, 0.18)
    return s


def bass(midi, dur=0.9):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = note_hz(midi)
    s = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)
    return s * env(n, 0.012, 0.45)


def pad(midis, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for m in midis:
        f = note_hz(m)
        for det in (-0.12, 0.12):
            ff = f * 2 ** (det / 12)
            s += np.sin(2 * np.pi * ff * t) + 0.3 * np.sin(4 * np.pi * ff * t) + 0.1 * np.sin(6 * np.pi * ff * t)
    a = np.minimum(1, t / 0.25) * np.minimum(1, (dur - t) / 0.3).clip(0, 1)
    return s * a / (len(midis) * 2)


def bandnoise(n, lo, hi):
    x = rng.standard_normal(n)
    X = np.fft.rfft(x)
    fr = np.fft.rfftfreq(n, 1 / SR)
    X[(fr < lo) | (fr > hi)] = 0
    y = np.fft.irfft(X, n)
    return y / (np.abs(y).max() + 1e-9)


def kick():
    n = int(0.28 * SR)
    t = np.arange(n) / SR
    f = 50 + 90 * np.exp(-t / 0.035)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * env(n, 0.001, 0.12)


def clap():
    n = int(0.2 * SR)
    return bandnoise(n, 900, 5000) * env(n, 0.002, 0.06)


def shaker():
    n = int(0.08 * SR)
    return bandnoise(n, 6000, 14000) * env(n, 0.004, 0.025)


# ---- Hiệu ứng ----
def pop(f0=520, f1=980, dur=0.14):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f0 + (f1 - f0) * (t / dur)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.002, 0.05)


def boing():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    f = 260 + 380 * (1 - np.exp(-t / 0.08)) + 30 * np.sin(2 * np.pi * 18 * t)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.004, 0.14)


def whoosh(dur=0.35, up=True):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = bandnoise(n, 400, 6000)
    shape = np.sin(np.pi * t / dur) ** 2
    return s * shape * 0.6


def coin():
    a = np.concatenate([np.sin(2 * np.pi * 988 * np.arange(int(0.07 * SR)) / SR),
                        np.sin(2 * np.pi * 1319 * np.arange(int(0.3 * SR)) / SR) * env(int(0.3 * SR), 0.001, 0.12)])
    return np.sign(a) * 0.25 + a * 0.5


def chime(base=84, notes=(0, 4, 7, 12), gap=0.06):
    out = np.zeros(int((gap * len(notes) + 1.2) * SR))
    for k, d in enumerate(notes):
        add(out, k * gap, kalimba(base + d, 1.2), 0.6)
    return out


def sparkle(dur=0.6, count=7):
    out = np.zeros(int((dur + 0.4) * SR))
    for k in range(count):
        m = rng.integers(96, 108)
        add(out, rng.uniform(0, dur), kalimba(int(m), 0.4), 0.25)
    return out


def tick():
    n = int(0.05 * SR)
    return bandnoise(n, 2000, 8000) * env(n, 0.001, 0.008)


def scrub(dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = bandnoise(n, 1500, 7000)
    return s * (0.5 + 0.5 * np.sin(2 * np.pi * 5.5 * t) ** 2) * np.minimum(1, t / 0.05) * np.minimum(1, (dur - t) / 0.1).clip(0, 1)


def music():
    m = np.zeros(N)
    chords = {"C": [60, 64, 67, 72], "Am": [57, 60, 64, 69], "F": [53, 57, 60, 65], "G": [55, 59, 62, 67]}
    roots = {"C": 36, "Am": 33, "F": 29, "G": 31}
    prog = ["C", "Am", "F", "G"]
    bar = 4 * T.BEAT
    nbars = int(T.END[0] / bar)  # 13 ô nhịp tới cảnh kết
    arp = [0, 1, 2, 3, 2, 1, 3, 2]
    for b in range(nbars):
        c = prog[b % 4]
        t0 = b * bar
        intro = t0 < T.TODAY[0]
        build = t0 >= T.CLIMAX[0]
        add(m, t0, pad(chords[c], bar + 0.2), 0.10 if intro else 0.08)
        for k in range(8):
            off = 12 if build and k % 2 else 0
            add(m, t0 + k * T.BEAT / 2, kalimba(chords[c][arp[k]] + 12 + off, 0.8), 0.16 if intro else 0.2)
        if not intro:
            for k in (0, 2):
                add(m, t0 + k * T.BEAT, bass(roots[c] + 12, 0.9), 0.32)
            for k in range(4):
                add(m, t0 + k * T.BEAT, kick() if k % 2 == 0 else clap(), 0.5 if k % 2 == 0 else 0.22)
            for k in range(8):
                add(m, t0 + k * T.BEAT / 2 + T.BEAT / 4, shaker(), 0.07)
        if build:
            for k in range(8):
                add(m, t0 + k * T.BEAT / 2, clap(), 0.08 + 0.02 * k)
    # Giai điệu ngắn ở montage và gameplay (nốt hợp âm, phách mạnh).
    hook = [76, 79, 81, 79, 77, 76, 74, 72]
    for start in (T.MONTAGE[0] + 0.1, T.GAMES[0]):
        for k in range(16):
            add(m, start + k * T.BEAT / 2, kalimba(hook[k % 8] + (12 if k >= 8 else 0) - 12, 0.6), 0.12)
    # Kết: hợp âm Đô ngân dài.
    add(m, T.ICON, pad([48, 60, 64, 67, 72], 4.0), 0.16)
    for k, d in enumerate([60, 64, 67, 72, 76, 79, 84]):
        add(m, T.ICON + k * 0.045, kalimba(d, 2.5), 0.22)
    add(m, T.ICON, kick(), 0.6)
    return m


def sfx():
    s = np.zeros(N)
    add(s, 0.05, pop(300, 700, 0.18), 0.5)
    for k in range(5):
        add(s, 0.2 + k * 0.17, whoosh(0.28), 0.18)
    add(s, T.TITLES[0][0], pop(), 0.35)
    add(s, T.TAP, boing(), 0.5)
    for k in range(5):
        add(s, T.TAP + 0.12 + k * 0.07, tick(), 0.45)
    add(s, T.TITLES[1][0], pop(600, 1200), 0.35)
    add(s, T.TITLES[1][0] + 0.05, sparkle(0.5, 5), 0.6)
    add(s, T.TODAY[0] - 0.25, whoosh(0.4), 0.35)
    add(s, T.TICK, tick(), 0.8)
    add(s, T.TICK + 0.03, chime(84, (0, 4, 7, 12)), 0.45)
    add(s, T.TITLES[2][0], pop(), 0.3)
    add(s, T.COIN, coin(), 0.3)
    add(s, T.WARDROBE[0], whoosh(0.3), 0.3)
    for t in T.OUTFIT_CHANGES:
        add(s, t, pop(700, 1400, 0.1), 0.35)
    add(s, T.TITLES[3][0], pop(), 0.3)
    add(s, T.CARE[0] - 0.15, whoosh(0.3), 0.3)
    add(s, T.TITLES[4][0], pop(), 0.3)
    add(s, T.CARE_CUTS[1] + 0.6, sparkle(0.8, 6), 0.5)
    add(s, T.CARE_CUTS[2] + 0.2, scrub(1.1), 0.12)
    add(s, T.CARE[1] - 0.45, chime(88, (0, 7, 12)), 0.35)
    add(s, T.GAMES[0], boing(), 0.45)
    add(s, T.TITLES[5][0], pop(), 0.3)
    for t in T.GAME_CUTS[1:]:
        add(s, t - 0.1, whoosh(0.25), 0.25)
    add(s, T.CLIMAX[0] - 0.1, whoosh(0.35), 0.3)
    for t in T.HOPS:
        add(s, t, boing(), 0.35)
    add(s, T.HOPS[-1] + 0.1, sparkle(0.9, 9), 0.5)
    add(s, T.ICON - 0.45, whoosh(0.5), 0.35)
    add(s, T.ICON, pop(250, 600, 0.2), 0.6)
    add(s, T.ICON + 0.6, sparkle(0.6, 8), 0.5)
    add(s, T.ICON + 0.5, pop(500, 900), 0.3)
    return s


def write(path, events_extra=()):
    mix = music() * 0.8 + sfx()
    for t, kind in events_extra:
        add(mix, t, {"tick": tick(), "chime": chime(), "pop": pop()}[kind], 0.4)
    fade = np.ones(N)
    k = int(0.6 * SR)
    fade[-k:] = np.linspace(1, 0, k)
    mix *= fade
    mix /= np.abs(mix).max() / 0.89
    st = np.stack([mix, mix], axis=1)
    pcm = (st * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == "__main__":
    write(sys.argv[1])
    print("ok", sys.argv[1])
