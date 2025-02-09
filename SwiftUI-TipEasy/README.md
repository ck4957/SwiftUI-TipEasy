# SwiftUI Tip Calculator

This project is a SwiftUI-based tip calculator that allows users to easily calculate tips based on a bill amount. It features a user-friendly interface with a slider for selecting tip percentages, preset buttons for common tip amounts, and fields for custom input.

## Project Structure

- **SwiftUI-TipCalculatorApp.swift**: Entry point of the application, setting up the main app structure and initializing the ContentView.
- **Views/ContentView.swift**: Main view of the application, which includes the TipCalculatorView and manages layout and navigation.
- **Views/TipCalculatorView.swift**: Contains the UI elements for the tip calculator, including a slider, buttons for preset percentages, and text fields for bill and custom tip amounts. It also handles animations and UI updates.
- **Models/TipCalculatorModel.swift**: Manages the logic for calculating tips based on the bill amount and selected tip percentage. Includes properties for bill amount and selected tip percentage, along with calculation methods.
- **Resources/Assets.xcassets**: Contains image assets and color sets for the application, supporting both light and dark modes.

## Features

- Slider for selecting tip percentages from 0% to 50% in 1% intervals.
- Buttons for preset tip percentages: 10%, 12%, 15%, 18%, and 20%.
- Input fields for entering the bill amount and custom tip percentages.
- Smooth animations for UI interactions.
- Support for light and dark mode.

## Usage

1. Clone the repository or download the project files.
2. Open the project in Xcode.
3. Run the application on a simulator or a physical device.
4. Enter the bill amount and select a tip percentage using the slider or preset buttons.
5. View the calculated tip and total amount displayed on the screen.

## License

This project is licensed under the MIT License.