# MicMute

A lightweight macOS menu bar application to toggle microphone mute functionality with ease. The app ensures that the microphone is muted/unmuted with a single click, offering a straightforward solution for privacy and convenience.

## Features

- **Menu Bar Integration**: Quickly access microphone mute controls from the macOS menu bar.
- **Real-Time Status**: The app displays the current microphone status with intuitive icons.
- **Privacy-Centric**: The app requests and uses minimal permissions required for functionality.

## Known Limitations

This app leverages macOS APIs to control microphone mute functionality. However, macOS has certain limitations:

1. **System-Level Mute**: There is no open-source API or system call to reliably enforce a full mute for all input devices. 
2. **Hardware and Driver Dependence**: Some devices may not support programmatic muting due to hardware or driver restrictions.
3. **Audio MIDI Setup Dependency**: The app mimics the behavior of the macOS Audio MIDI Setup toggle but doesn't interact directly with the internal mechanism.

If macOS exposes additional APIs in the future, this app can evolve to include more robust functionality.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/paltdariusz/MicMute.git
   cd MicMute
   ```

2. Open the project in Xcode:
   ```bash
   open MicMuteApp.xcodeproj
   ```

3. Build and run the app:
   - Press `Cmd + R` to build and run.
   - Grant microphone permissions when prompted.

4. To deploy the app:
   - Build the **Release** configuration.
   - Locate the built app in the `Products` folder and copy it to your **Applications** folder.

## Future Plans

- Implement system-wide mute toggling if macOS APIs evolve.
- Add support for external microphones with enhanced channel control.
- Explore more advanced privacy features like notifications for microphone activation.

## Contributing

Contributions are welcome! If you have ideas or fixes, feel free to fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the macOS community for documentation and resources.
- Special thanks to Apple for providing a developer-friendly environment.
