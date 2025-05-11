# Shirr *Prototype*

**Shirr** is an audio analysis and visualization application built with Flutter. It focuses on real-time DSP features including plotting, playback, and mic-based input, designed for flexibility and modular integration.

![Frame 7](https://github.com/user-attachments/assets/42645ba5-6ef9-47bd-99cb-31cccce9c876)


## Features

- **Audio Analysis**
  - FFT, Constant-Q Transform, MFCCs
  - Spectral centroid, flatness, roll-off
  - Pitch and beat tracking
  - Relative loudness and amplitude visualization

- **Audio Interaction**
  - Mic input with real-time processing
  - WAV file playback and inspection
  - Snapshot capture and waveform rendering

- **User Interface**
  - Custom UI components and themed visual elements
  - Dark/light mode support
  - Built-in audio tool navigation

## Dependencies

Uses stable, actively maintained Flutter packages:

- `audioplayers` – Audio playback
- `audio_streamer` – Microphone stream handling
- `fftea` – Fast Fourier Transform
- `wav` – WAV file support
- `fl_chart` – Plotting and charting
- `permission_handler`, `file_picker`, `path_provider` – Platform integration
- `flutter_svg` – Vector graphics rendering

## Requirements

- Flutter SDK ≥ 3.7.0
- Dart ≥ 3.x
- Android device or emulator (no iOS support)
- Linux or Windows for desktop builds (experimental)

## Setup

```bash
git clone https://github.com/your-username/shirr.git
cd shirr
flutter pub get
flutter run
```

## Assets

The app depends on image, SVG, font, and sound assets located under assets/. These are referenced in pubspec.yaml and must be included for full functionality.
