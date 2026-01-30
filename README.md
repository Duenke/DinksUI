>In 12.0.0, hiding party frames during instanced combat is causing errors.
>Even though DinksUI doesn't access any secrets directly, there's some kind of knock-on effect from hiding/showing these.
>I don't know if these kinds of issues will be cleared up by Blizz over time.

# Dink's Immersive UI

## Description

Dink's Immersive UI is a World of Warcraft addon designed to enhance your gameplay experience by clearing up the UI until you need to see the UI elements. It allows you to customize which frames are shown or hidden based on your preferences. You can use regular macro conditionals to control the visibility of each frame.

## Features

- Simplifies the UI by hiding unnecessary elements
- Customizable settings for each frame
- Supports regular macro conditionals for conditional visibility
- Default settings profile is all blanks (no hiding by deault)
- DinksDefaults settings profile based on personal usage

## Supported Frames

- Action Bar 1
- Action Bar 2
- Action Bar 3
- Action Bar 4
- Action Bar 5
- Action Bar 6
- Action Bar 7
- Action Bar 8
- Pet Action Bar
- Stance Bar
- Player Frame
- Target Frame
- Focus Frame
- Pet Frame
- Raid Frame
- Party Frame (!Hiding this inside instances will cause errors right now!)
- Objective Tracker
- Chat Frame
- Minimap
- Bags Bar
- Micro Menu
- Buff Frame
- Debuff Frame
- Experience Bar
- Personal Resource Display
- Damage Meters

## Installation

1. Download the latest version from [CurseForge](https://www.curseforge.com/wow/addons/dinksui).
2. Install via addon manager of your choice or just extract the downloaded files into your World of Warcraft `_retail_/Interface/AddOns` directory.
3. Reload World of Warcraft to load the addon. (You no longer need to restart the WoW game client.)

## Usage

1. Open the settings by typing `/dinksui` or `/dui` in the chat.
2. Customize the visibility of each frame using regular macro conditionals.
3. Save your settings and enjoy a clutter-free UI until you need it.
4. Temporarily toggle on all frames by typing `/dinksui show`. Type `/dinksui hide` to hide the frames again. Type `/dinksui toggle` for a 1-button toggle on and off.
5. Bind any of the `/` slash commands to your custom macros for easy use!
6. Type `/dinksui help` or `/dui h` for help.
7. You can reference [Wowpedia](https://wowpedia.fandom.com/wiki/Macro_conditionals) for help with macro conditionals.

## Contributing

Contributions to Dink's Immersive UI are welcome! If you encounter any issues or have suggestions for improvements, please open an issue on the [GitHub repository](https://github.com/Duenke/DinksUI/issues).

See [Contributing](./Contributing.md) for more.

## License

Dink's Immersive UI is released under the [MIT License](https://opensource.org/licenses/MIT).
