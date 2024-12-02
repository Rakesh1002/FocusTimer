# FocusTimer

A minimalist, non-intrusive focus timer for macOS that helps you stay productive with the Pomodoro Technique.

## Features

- 🕒 Floating time display that shows both current time and focus timer
- 🖥️ Works across all screens and spaces
- 🎯 Customizable focus and break durations
- 🔄 Automatic break reminders
- 🎨 Clean, minimal interface
- 🖱️ Draggable overlay window
- 🚫 No dock icon, just a menu bar presence

## Installation

1. Download the latest release from the Releases page
2. Mount the DMG file
3. Drag FocusTimer to your Applications folder
4. Launch FocusTimer from Applications

## Usage

### Basic Controls
- Click the timer icon in the menu bar to access controls
- Start/Stop timer from the menu
- Drag the floating display to position it anywhere on screen

### Default Settings
- Focus Duration: 50 minutes
- Break Duration: 10 minutes
- Maximum Cycles: 4

### Customization
Access settings through the menu bar icon to customize:
- Work duration
- Break duration
- Number of cycles
- Display preferences

## Building from Source

### Prerequisites
- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.9 or later

### Build Steps
1. Clone the repository:
```bash
git clone https://github.com/yourusername/FocusTimer.git
cd FocusTimer
```

2. Build the project:
```bash
swift build
```

3. Run the app:
```bash
swift run
```

## Technical Details

### Architecture
- Built with SwiftUI and AppKit
- Menu bar-based application
- Floating overlay window implementation
- Cross-screen compatibility

### Key Components
- TimeOverlayWindow: Manages the floating display
- TimerManager: Handles timer logic and state
- WindowManager: Coordinates window management
- Settings: Handles user preferences

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Acknowledgments

- Inspired by the Pomodoro Technique
- Built with SwiftUI and AppKit
- Icons from SF Symbols
