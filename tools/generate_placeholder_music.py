from __future__ import annotations

import math
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIO_ROOT = ROOT / "assets" / "placeholders" / "audio"
SAMPLE_RATE = 44100
LONG_SAMPLE_RATE = 22050


def midi_to_hz(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def smooth_env(t: float, duration: float, attack: float = 0.02, release: float = 0.08) -> float:
    if t < attack:
        return t / attack
    if t > duration - release:
        return max(0.0, (duration - t) / release)
    return 1.0


def sine(phase: float) -> float:
    return math.sin(phase)


def soft_bell(phase: float, t: float) -> float:
    decay = math.exp(-2.8 * t)
    return (
        math.sin(phase) * 0.72
        + math.sin(phase * 2.0) * 0.18
        + math.sin(phase * 3.0) * 0.10
    ) * decay


def add_note(
    left: list[float],
    right: list[float],
    start_seconds: float,
    duration: float,
    frequency: float,
    amplitude: float,
    pan: float = 0.0,
    bell: bool = False,
) -> None:
    start = int(start_seconds * SAMPLE_RATE)
    count = int(duration * SAMPLE_RATE)
    left_gain = math.cos((pan + 1.0) * math.pi / 4.0)
    right_gain = math.sin((pan + 1.0) * math.pi / 4.0)
    for i in range(count):
        index = start + i
        if index >= len(left):
            break
        t = i / SAMPLE_RATE
        phase = 2.0 * math.pi * frequency * t
        tone = soft_bell(phase, t) if bell else sine(phase) * smooth_env(t, duration, 0.08, 0.18)
        value = tone * amplitude
        left[index] += value * left_gain
        right[index] += value * right_gain


def add_chord(left: list[float], right: list[float], start: float, duration: float, notes: list[int], amplitude: float) -> None:
    for offset, note in enumerate(notes):
        add_note(left, right, start, duration, midi_to_hz(note), amplitude / len(notes), pan=-0.25 + offset * 0.25)


def write_wav(path: Path, left: list[float], right: list[float]) -> None:
    peak = max(0.01, max(max(abs(v) for v in left), max(abs(v) for v in right)))
    gain = 0.72 / peak
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for l_value, r_value in zip(left, right):
            l_sample = int(max(-1.0, min(1.0, l_value * gain)) * 32767)
            r_sample = int(max(-1.0, min(1.0, r_value * gain)) * 32767)
            frames.extend(l_sample.to_bytes(2, "little", signed=True))
            frames.extend(r_sample.to_bytes(2, "little", signed=True))
        wav.writeframes(frames)


def write_wav_mono(path: Path, samples: list[float], sample_rate: int = LONG_SAMPLE_RATE) -> None:
    peak = max(0.01, max(abs(v) for v in samples))
    gain = 0.72 / peak
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        frames = bytearray()
        for value in samples:
            sample = int(max(-1.0, min(1.0, value * gain)) * 32767)
            frames.extend(sample.to_bytes(2, "little", signed=True))
        wav.writeframes(frames)


def add_note_mono(
    samples: list[float],
    sample_rate: int,
    start_seconds: float,
    duration: float,
    frequency: float,
    amplitude: float,
    bell: bool = False,
    shimmer: bool = False,
) -> None:
    start = int(start_seconds * sample_rate)
    count = int(duration * sample_rate)
    for i in range(count):
        index = start + i
        if index >= len(samples):
            break
        t = i / sample_rate
        phase = 2.0 * math.pi * frequency * t
        if bell:
            tone = soft_bell(phase, t)
        else:
            tone = math.sin(phase) * smooth_env(t, duration, 0.12, 0.3)
        if shimmer:
            tone += math.sin(phase * 2.0) * 0.12 * math.exp(-3.0 * t)
        samples[index] += tone * amplitude


def add_chord_mono(samples: list[float], sample_rate: int, start: float, duration: float, notes: list[int], amplitude: float) -> None:
    for note in notes:
        add_note_mono(samples, sample_rate, start, duration, midi_to_hz(note), amplitude / len(notes))


def add_music_box_melody(
    samples: list[float],
    sample_rate: int,
    beat: float,
    melody: list[int],
    bars: int,
    amplitude: float,
    octave_lift_every: int = 0,
) -> None:
    beats = bars * 4
    for beat_index in range(beats):
        note = melody[beat_index % len(melody)]
        octave_shift = 12 if octave_lift_every > 0 and beat_index % octave_lift_every == octave_lift_every - 1 else 0
        add_note_mono(
            samples,
            sample_rate,
            beat_index * beat,
            beat * 0.82,
            midi_to_hz(note + octave_shift),
            amplitude,
            bell=True,
            shimmer=True,
        )


def add_soft_pulse(samples: list[float], sample_rate: int, beat: float, bars: int, root_notes: list[int]) -> None:
    for bar in range(bars):
        root = root_notes[bar % len(root_notes)] - 12
        start = bar * 4 * beat
        add_note_mono(samples, sample_rate, start, beat * 3.7, midi_to_hz(root), 0.038)
        add_note_mono(samples, sample_rate, start + beat * 2.0, beat * 1.4, midi_to_hz(root + 7), 0.025)


def make_long_soundtrack(
    filename: str,
    bpm: float,
    bars: int,
    chords: list[list[int]],
    melody: list[int],
    amplitude: float = 0.12,
    octave_lift_every: int = 0,
) -> None:
    beat = 60.0 / bpm
    total_seconds = bars * 4 * beat
    sample_count = int(total_seconds * LONG_SAMPLE_RATE)
    samples = [0.0] * sample_count

    for bar in range(bars):
        chord = chords[bar % len(chords)]
        start = bar * 4 * beat
        add_chord_mono(samples, LONG_SAMPLE_RATE, start, 4 * beat, chord, 0.22)
        if bar % 8 in [4, 5, 6, 7]:
            add_chord_mono(samples, LONG_SAMPLE_RATE, start + 2 * beat, 2 * beat, [note + 12 for note in chord[:2]], 0.055)

    add_soft_pulse(samples, LONG_SAMPLE_RATE, beat, bars, [chord[0] for chord in chords])
    add_music_box_melody(samples, LONG_SAMPLE_RATE, beat, melody, bars, amplitude, octave_lift_every)

    # Tiny sparkle answers every few bars keep the track alive without becoming busy.
    for bar in range(3, bars, 8):
        sparkle_start = (bar * 4 + 2) * beat
        for offset, note in enumerate([melody[-4], melody[-2], melody[-1]]):
            add_note_mono(samples, LONG_SAMPLE_RATE, sparkle_start + offset * beat * 0.5, beat * 0.55, midi_to_hz(note + 12), amplitude * 0.55, bell=True, shimmer=True)

    fade = int(1.5 * LONG_SAMPLE_RATE)
    for i in range(fade):
        fade_in = i / fade
        fade_out = (fade - i) / fade
        samples[i] *= fade_in
        samples[-i - 1] *= fade_out

    AUDIO_ROOT.mkdir(parents=True, exist_ok=True)
    write_wav_mono(AUDIO_ROOT / filename, samples, LONG_SAMPLE_RATE)


def make_loop(filename: str, bpm: float, chords: list[list[int]], melody: list[int], playful: bool = False) -> None:
    beat = 60.0 / bpm
    bars = 8
    total_seconds = bars * 4 * beat
    sample_count = int(total_seconds * SAMPLE_RATE)
    left = [0.0] * sample_count
    right = [0.0] * sample_count

    for bar in range(bars):
        chord = chords[bar % len(chords)]
        start = bar * 4 * beat
        add_chord(left, right, start, 4 * beat, chord, 0.22)
        add_note(left, right, start, 3.8 * beat, midi_to_hz(chord[0] - 12), 0.05, pan=-0.15)
        if playful:
            add_note(left, right, start + 2 * beat, 1.6 * beat, midi_to_hz(chord[0] - 5), 0.04, pan=0.18)

    for index, note in enumerate(melody):
        start = index * beat
        note_duration = beat * (0.78 if playful else 1.35)
        octave_shift = 12 if playful and index % 4 in [1, 2] else 0
        add_note(
            left,
            right,
            start,
            note_duration,
            midi_to_hz(note + octave_shift),
            0.12 if playful else 0.09,
            pan=0.22 if index % 2 == 0 else -0.18,
            bell=True,
        )

    # Gentle fade at loop edges keeps toddler music calm if the platform adds a tiny restart gap.
    fade = int(0.08 * SAMPLE_RATE)
    for i in range(fade):
        fade_in = i / fade
        fade_out = (fade - i) / fade
        left[i] *= fade_in
        right[i] *= fade_in
        left[-i - 1] *= fade_out
        right[-i - 1] *= fade_out

    AUDIO_ROOT.mkdir(parents=True, exist_ok=True)
    write_wav(AUDIO_ROOT / filename, left, right)


def main() -> None:
    make_loop(
        "music_farmyard_loop.wav",
        84.0,
        [[60, 64, 67], [67, 71, 74], [69, 72, 76], [65, 69, 72]],
        [72, 74, 76, 79, 76, 74, 72, 67, 69, 72, 74, 76, 74, 72, 69, 67,
         72, 74, 76, 79, 81, 79, 76, 74, 72, 69, 67, 69, 72, 67, 64, 67],
    )
    make_loop(
        "music_chore_loop.wav",
        96.0,
        [[65, 69, 72], [60, 64, 67], [62, 65, 69], [70, 74, 77]],
        [77, 77, 79, 81, 79, 77, 74, 72, 74, 77, 79, 77, 74, 72, 69, 72,
         77, 79, 81, 84, 81, 79, 77, 74, 72, 74, 77, 79, 77, 74, 72, 77],
        playful=True,
    )
    make_long_soundtrack(
        "music_sunny_farm_morning.wav",
        84.0,
        104,
        [[60, 64, 67], [67, 71, 74], [69, 72, 76], [65, 69, 72]],
        [72, 74, 76, 79, 76, 74, 72, 67, 69, 72, 74, 76, 74, 72, 69, 67,
         72, 74, 76, 79, 81, 79, 76, 74, 72, 69, 67, 69, 72, 67, 64, 67],
        amplitude=0.085,
    )
    make_long_soundtrack(
        "music_sunny_farm_playtime.wav",
        90.0,
        112,
        [[65, 69, 72], [60, 64, 67], [62, 65, 69], [67, 71, 74]],
        [77, 77, 79, 81, 79, 77, 74, 72, 74, 77, 79, 77, 74, 72, 69, 72,
         77, 79, 81, 84, 81, 79, 77, 74, 72, 74, 77, 79, 77, 74, 72, 77],
        amplitude=0.082,
        octave_lift_every=8,
    )
    make_long_soundtrack(
        "music_sunny_farm_twilight.wav",
        78.0,
        96,
        [[60, 64, 67], [64, 67, 71], [65, 69, 72], [67, 71, 74]],
        [72, 74, 76, 74, 72, 69, 67, 69, 72, 76, 79, 76, 74, 72, 69, 67,
         64, 67, 69, 72, 69, 67, 64, 67, 69, 72, 74, 76, 74, 72, 69, 67],
        amplitude=0.078,
    )


if __name__ == "__main__":
    main()
