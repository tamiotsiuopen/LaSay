# LaSay

Voice input for developers. Dictate in your native language with English technical terms -- LaSay keeps them intact.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-proprietary-lightgrey)

## Why LaSay

Developers think in mixed languages. You say "help me refactor the useEffect hook" in Mandarin, and every transcription tool mangles "useEffect" into nonsense. LaSay solves this with a 300+ term technical dictionary and AI post-processing that preserves code identifiers, framework names, and technical jargon exactly as spoken.

**Hold Fn+Space. Speak. Release. Text appears at your cursor.**

Works in any app -- VS Code, Terminal, Slack, browser, anywhere you type.

## Features

- **Mixed-language transcription** -- speak your native language with English technical terms
- **300+ technical terms preserved** -- React, FastAPI, Kubernetes, camelCase identifiers, all kept intact
- **Two transcription modes** -- Cloud (OpenAI Whisper API) or Local (whisper.cpp, fully offline)
- **AI text cleanup** -- removes filler words, fixes grammar, preserves technical terms (GPT-5-mini)
- **Global hotkey** -- Fn+Space works in any application
- **Auto-paste** -- transcribed text is pasted directly at cursor position
- **Secure storage** -- API keys stored in macOS Keychain

## Quick Start

```
1. Install LaSay.app to /Applications
2. Grant Microphone + Accessibility permissions on first launch
3. Menu bar → Settings → enter your OpenAI API Key
4. Hold Fn+Space anywhere to dictate
```

No account. No signup. No cloud sync. Your API key, your data.

## Architecture

```
Fn+Space (hold)
    │
    ▼
AudioRecorder (16kHz mono AAC)
    │
    ├─► Cloud: OpenAI Whisper API ──► transcription
    │
    └─► Local: whisper.cpp CLI ─────► transcription
                                          │
                                          ▼
                                   TechTermsDictionary
                                   (300+ regex corrections)
                                          │
                                          ▼
                                   AI Polish (optional)
                                   GPT-5-mini text cleanup
                                          │
                                          ▼
                                   Auto-paste at cursor
```

## Transcription Modes

| Mode | Engine | Latency | Cost | Offline |
|------|--------|---------|------|---------|
| Cloud | OpenAI Whisper API | ~1-2s | ~$0.001/use | No |
| Local | whisper.cpp (ggml-base) | ~2-4s | Free | Yes |

Local mode auto-downloads the whisper.cpp binary and ggml-base model (~142MB) on first use.

## Configuration

### Permissions

LaSay requires two macOS permissions:

- **Microphone** -- System Settings > Privacy & Security > Microphone
- **Accessibility** -- System Settings > Privacy & Security > Accessibility (for global hotkey)

### Settings

Access via menu bar icon > Settings:

- **Transcription mode** -- Cloud or Local
- **Transcription language** -- Auto / Chinese / English / Japanese / Korean
- **AI text cleanup** -- toggle on/off, custom prompt supported
- **Auto-paste** -- paste transcription directly at cursor
- **Sound feedback** -- audio cue for recording start/stop
- **Preview mode** -- review text before pasting

### API Key

Required for Cloud mode and AI text cleanup. Get one at [platform.openai.com/api-keys](https://platform.openai.com/api-keys).

Stored in macOS Keychain (not UserDefaults, not plaintext).

## Cost

Using Cloud mode with AI cleanup enabled:

| Component | Cost per use |
|-----------|-------------|
| Whisper API | ~$0.001 |
| GPT-5-mini (if enabled) | ~$0.00004 |
| **Total** | **~$0.001** |

100 uses per day = ~$3/month. Local mode is free.

## Supported Languages

Transcription: Auto-detect, Chinese (zh), English (en), Japanese (ja), Korean (ko)

UI: Traditional Chinese, English

## FAQ

**Hotkey not working?**
Grant Accessibility permission and restart LaSay. macOS requires a restart after granting this permission.

**Works in Terminal?**
Yes, via simulated Cmd+V paste. Some terminal emulators may require additional configuration.

**How accurate is the technical term preservation?**
The dictionary covers 300+ terms across major languages (Python, JavaScript, TypeScript, Swift, Rust, Java, C/C++/C#), frameworks (React, FastAPI, Django, Spring), databases (PostgreSQL, MongoDB, Redis), DevOps tools (Docker, Kubernetes, Terraform), and common abbreviations (API, SDK, CI/CD, ORM).

**Can I use it without an API key?**
Yes. Switch to Local mode -- it runs whisper.cpp entirely on your machine. AI text cleanup requires an API key.

**Where is my API key stored?**
In macOS Keychain via the Security framework. Not in UserDefaults, not in plaintext files.

## System Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac
- Internet connection (Cloud mode only)
- OpenAI API key (Cloud mode and AI cleanup)

## Build from Source

```bash
git clone https://github.com/tamiotsiuopen/LaSay.git
cd LaSay/VoiceScribe
open VoiceScribe.xcodeproj
# Xcode → Product → Build (Cmd+B)
```

No external dependencies. No CocoaPods. No SPM packages.

---

Built by [Tamio Tsiu](mailto:tamio.tsiu@gmail.com)
