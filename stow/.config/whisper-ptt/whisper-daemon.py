#!/usr/bin/env python3
"""
Whisper Push-to-Talk Daemon
Maintains faster-whisper model in VRAM, transcribes speech via VAD in real-time.
Control via Unix socket at /tmp/whisper-ptt.sock
"""

import os
import sys
import json
import time
import socket
import signal
import struct
import threading
import subprocess
import collections
import numpy as np

# ── Config ──────────────────────────────────────────────────────────
SOCKET_PATH = "/tmp/whisper-ptt.sock"
SAMPLE_RATE = 16000
FRAME_MS = 30  # webrtcvad frame duration
FRAME_SAMPLES = int(SAMPLE_RATE * FRAME_MS / 1000)  # 480 samples
SILENCE_TIMEOUT_MS = 500  # cut segment after this much silence
OVERLAP_MS = 300  # overlap between segments to avoid losing words
OVERLAP_SAMPLES = int(SAMPLE_RATE * OVERLAP_MS / 1000)
VAD_AGGRESSIVENESS = 2
MODEL_SIZE = "large-v3"
COMPUTE_TYPE = "int8_float16"
DEVICE = "cuda"
BEAM_SIZE = 5
LANGUAGE = "pt"  # Portuguese, change as needed

# ── Globals ─────────────────────────────────────────────────────────
model = None
recording = False
audio_buffer = collections.deque()
buffer_lock = threading.Lock()
transcription_threads = []


def log(msg):
    print(f"[whisper-ptt] {msg}", flush=True)


def eww_cmd(*args):
    """Run eww command, ignore errors."""
    try:
        subprocess.run(["eww", *args], timeout=5, capture_output=True)
    except Exception:
        pass


def notify(msg):
    """Send desktop notification."""
    try:
        subprocess.run(
            ["notify-send", "-a", "Whisper PTT", "-t", "2000", "Whisper PTT", msg],
            timeout=5,
            capture_output=True,
        )
    except Exception:
        pass


def output_text(text):
    """Type text into active window and copy to clipboard."""
    text = text.strip()
    if not text:
        return

    log(f"Output: {text}")

    # Copy to clipboard
    try:
        proc = subprocess.Popen(
            ["wl-copy"], stdin=subprocess.PIPE, timeout=5
        )
        proc.communicate(input=text.encode())
    except Exception as e:
        log(f"wl-copy error: {e}")

    # Type into active window
    try:
        subprocess.run(["wtype", "--", text], timeout=10, capture_output=True)
    except Exception as e:
        log(f"wtype error: {e}")


def load_model():
    """Load faster-whisper model into VRAM."""
    global model
    log(f"Loading model {MODEL_SIZE} ({COMPUTE_TYPE}) on {DEVICE}...")
    from faster_whisper import WhisperModel

    model = WhisperModel(
        MODEL_SIZE,
        device=DEVICE,
        compute_type=COMPUTE_TYPE,
    )
    log("Model loaded and ready.")
    notify("Modelo carregado na VRAM")


def transcribe_segment(audio_data):
    """Transcribe a numpy audio segment."""
    global model
    if model is None or len(audio_data) < SAMPLE_RATE * 0.3:  # skip < 300ms
        return

    try:
        segments, info = model.transcribe(
            audio_data,
            beam_size=BEAM_SIZE,
            language=LANGUAGE,
            vad_filter=True,
            vad_parameters=dict(
                min_silence_duration_ms=300,
                speech_pad_ms=100,
            ),
        )

        full_text = ""
        for segment in segments:
            full_text += segment.text

        if full_text.strip():
            output_text(full_text)

    except Exception as e:
        log(f"Transcription error: {e}")


def recording_loop():
    """Main recording loop with VAD-based segmentation."""
    global recording

    import sounddevice as sd
    import webrtcvad

    vad = webrtcvad.Vad(VAD_AGGRESSIVENESS)

    # Audio state
    frames = []
    speech_frames = 0
    silence_frames = 0
    silence_threshold = int(SILENCE_TIMEOUT_MS / FRAME_MS)
    in_speech = False
    overlap_buffer = []

    log("Recording started")
    eww_cmd("update", "recording=true")
    eww_cmd("open", "whisper-overlay")

    def audio_callback(indata, frame_count, time_info, status):
        nonlocal frames, speech_frames, silence_frames, in_speech, overlap_buffer

        if status:
            log(f"Audio status: {status}")

        # Convert to 16-bit PCM for webrtcvad
        audio_int16 = (indata[:, 0] * 32767).astype(np.int16)
        raw_bytes = audio_int16.tobytes()

        # Check if frame contains speech
        try:
            is_speech = vad.is_speech(raw_bytes, SAMPLE_RATE)
        except Exception:
            is_speech = False

        frames.append(audio_int16.copy())

        if is_speech:
            speech_frames += 1
            silence_frames = 0
            if not in_speech and speech_frames >= 3:  # need 3 consecutive speech frames
                in_speech = True
        else:
            if in_speech:
                silence_frames += 1

                # Silence timeout → segment complete
                if silence_frames >= silence_threshold:
                    # Collect segment audio
                    segment_audio = np.concatenate(frames[:-silence_frames] if silence_frames > 0 else frames)

                    # Save overlap for next segment
                    if len(segment_audio) > OVERLAP_SAMPLES:
                        overlap_buffer = [segment_audio[-OVERLAP_SAMPLES:]]
                    else:
                        overlap_buffer = []

                    # Transcribe in background thread
                    segment_float = segment_audio.astype(np.float32) / 32767.0
                    t = threading.Thread(
                        target=transcribe_segment,
                        args=(segment_float,),
                        daemon=True,
                    )
                    t.start()
                    transcription_threads.append(t)

                    # Reset for next segment, keep overlap
                    frames = list(overlap_buffer)
                    speech_frames = 0
                    silence_frames = 0
                    in_speech = False

    try:
        with sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=1,
            dtype="float32",
            blocksize=FRAME_SAMPLES,
            callback=audio_callback,
        ):
            while recording:
                time.sleep(0.05)
    except Exception as e:
        log(f"Recording error: {e}")
        notify(f"Erro na gravacao: {e}")
        return

    # ── Flush residual audio ────────────────────────────────────────
    if frames:
        residual = np.concatenate(frames)
        if len(residual) > SAMPLE_RATE * 0.3:  # only if > 300ms
            residual_float = residual.astype(np.float32) / 32767.0
            log("Transcribing residual audio...")
            transcribe_segment(residual_float)

    # Wait for pending transcriptions
    for t in transcription_threads:
        t.join(timeout=30)
    transcription_threads.clear()

    log("Recording stopped")
    eww_cmd("update", "recording=false")

    # Close overlay after 2s
    def close_overlay():
        time.sleep(2)
        eww_cmd("close", "whisper-overlay")

    threading.Thread(target=close_overlay, daemon=True).start()


def handle_command(cmd):
    """Handle a command from the socket."""
    global recording

    cmd = cmd.strip().lower()
    log(f"Command: {cmd}")

    if cmd == "start":
        if recording:
            log("Already recording")
            return "already_recording"
        recording = True
        t = threading.Thread(target=recording_loop, daemon=True)
        t.start()
        return "started"

    elif cmd == "stop":
        if not recording:
            log("Not recording")
            return "not_recording"
        recording = False
        return "stopped"

    elif cmd == "status":
        return json.dumps({"recording": recording, "model_loaded": model is not None})

    elif cmd == "quit":
        log("Shutting down...")
        recording = False
        return "bye"

    else:
        return f"unknown_command: {cmd}"


def run_server():
    """Unix socket server loop."""
    # Clean up stale socket
    if os.path.exists(SOCKET_PATH):
        os.unlink(SOCKET_PATH)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    os.chmod(SOCKET_PATH, 0o660)
    server.listen(5)
    server.settimeout(1.0)

    log(f"Listening on {SOCKET_PATH}")

    def signal_handler(sig, frame):
        log("Signal received, shutting down...")
        server.close()
        if os.path.exists(SOCKET_PATH):
            os.unlink(SOCKET_PATH)
        sys.exit(0)

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    try:
        while True:
            try:
                conn, _ = server.accept()
            except socket.timeout:
                continue
            except OSError:
                break

            try:
                data = conn.recv(1024).decode().strip()
                if data:
                    response = handle_command(data)
                    conn.sendall(response.encode())
                    if data.strip().lower() == "quit":
                        break
            except Exception as e:
                log(f"Connection error: {e}")
            finally:
                conn.close()
    finally:
        server.close()
        if os.path.exists(SOCKET_PATH):
            os.unlink(SOCKET_PATH)


if __name__ == "__main__":
    load_model()
    run_server()
