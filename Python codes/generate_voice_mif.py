# generate_voice_mif.py
import subprocess
import wave
import numpy as np
import os

SAMPLES_PER_LETTER = 2048   # 2048 samples @ 8 kHz = ~0.256 seconds per letter
SAMPLE_RATE = 8000          # Target 8 kHz sample rate
TOTAL_SAMPLES = 26 * SAMPLES_PER_LETTER

print("------------------------------------------------------------")
print("Generating Letter Audio via Native Windows Speech Engine...")
print("------------------------------------------------------------")

all_pcm = bytearray()

for i in range(26):
    letter = chr(ord('A') + i)
    temp_wav = os.path.abspath(f"temp_{letter}.wav")

    # Call Windows built-in SpeechSynthesizer directly (never deadlocks)
    ps_cmd = (
        f"Add-Type -AssemblyName System.Speech; "
        f"$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
        f"$synth.Rate = 1; "
        f"$synth.SetOutputToWaveFile('{temp_wav}'); "
        f"$synth.Speak('{letter}'); "
        f"$synth.Dispose()"
    )
    subprocess.run(["powershell", "-NoProfile", "-Command", ps_cmd], check=True)

    # Read the generated WAV file
    with wave.open(temp_wav, 'rb') as wf:
        n_channels = wf.getnchannels()
        sampwidth  = wf.getsampwidth()
        orig_rate  = wf.getframerate()
        raw_frames = wf.readframes(wf.getnframes())

    # Delete temp file
    if os.path.exists(temp_wav):
        os.remove(temp_wav)

    # Decode audio into NumPy array
    if sampwidth == 2:
        audio = np.frombuffer(raw_frames, dtype=np.int16)
    else:
        audio = (np.frombuffer(raw_frames, dtype=np.uint8).astype(np.int16) - 128) * 256

    if n_channels == 2:
        audio = audio[::2]  # Mono channel only

    # Resample to 8000 Hz
    num_target_samples = int(len(audio) * (SAMPLE_RATE / orig_rate))
    indices = np.linspace(0, len(audio) - 1, num_target_samples).astype(int)
    resampled = audio[indices]

    # Trim leading silence
    peak = np.max(np.abs(resampled))
    start_idx = 0
    if peak > 0:
        threshold = peak * 0.08
        for idx, val in enumerate(resampled):
            if abs(val) > threshold:
                start_idx = max(0, idx - 60)
                break
    resampled = resampled[start_idx:]

    # Crop or zero-pad to exactly 2048 samples
    if len(resampled) > SAMPLES_PER_LETTER:
        resampled = resampled[:SAMPLES_PER_LETTER]
    else:
        resampled = np.pad(resampled, (0, SAMPLES_PER_LETTER - len(resampled)), 'constant')

    # Convert to 8-bit unsigned PCM (0..255, 128 = silence)
    pcm_8bit = ((resampled / 256.0) + 128.0).clip(0, 255).astype(np.uint8)
    all_pcm.extend(pcm_8bit.tobytes())

    print(f"Letter [{letter}] generated successfully.")

# Write the Quartus .mif file
output_file = "voice_rom.mif"
print("------------------------------------------------------------")
print(f"Writing {output_file}...")

with open(output_file, "w") as f:
    f.write(f"-- Quartus Memory Initialization File\n")
    f.write(f"DEPTH = {TOTAL_SAMPLES};\n")
    f.write(f"WIDTH = 8;\n")
    f.write(f"ADDRESS_RADIX = HEX;\n")
    f.write(f"DATA_RADIX = HEX;\n\n")
    f.write("CONTENT\nBEGIN\n")
    for addr, val in enumerate(all_pcm):
        f.write(f"{addr:04X} : {val:02X};\n")
    f.write("END;\n")

print(f"SUCCESS: {output_file} created ({TOTAL_SAMPLES} bytes).")
print("------------------------------------------------------------")