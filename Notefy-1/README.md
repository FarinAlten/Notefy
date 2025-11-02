# Notefy

Notefy is a note-taking application designed for iOS and macOS, providing users with a simple and intuitive interface to create, edit, and manage their notes. This project is built using SwiftUI and leverages the power of SwiftData for data management.

## Features

- **Create and Edit Notes**: Users can create new notes and edit existing ones with a rich text editor.
- **Note List**: A comprehensive list view to display all notes, allowing for easy selection and deletion.
- **Settings**: A dedicated settings view to customize app preferences and view app information.
- **Export Notes**: Functionality to export notes in various formats for sharing or backup purposes.

## Project Structure

```
Notefy
├── Notefy.xcodeproj          # Xcode project file
├── Notefy                    # Main application directory
│   ├── App                   # Application entry point and main views
│   │   ├── NotefyApp.swift   # Main app setup
│   │   └── ContentView.swift  # Main user interface
│   ├── Features              # Application features
│   │   ├── Notes             # Notes feature components
│   │   │   ├── NoteEditor.swift  # Note editor view
│   │   │   ├── NoteList.swift    # List of notes
│   │   │   └── Note.swift        # Note model
│   │   └── Settings          # Settings feature components
│   │       └── SettingsView.swift # Settings view
│   ├── Utils                 # Utility classes and functions
│   │   ├── NoteStore.swift   # Note storage management
│   │   ├── TextFormatting.swift # Text formatting utilities
│   │   └── FileExporter.swift # Note exporting functionality
│   └── Resources             # Resources and assets
│       ├── Assets.xcassets   # Image assets
│       └── Info.plist        # App configuration
└── README.md                 # Project documentation
```

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```

2. Open the project in Xcode:
   ```bash
   open Notefy.xcodeproj
   ```

3. Build and run the application on your desired simulator or device.

## Contribution

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.