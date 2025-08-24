# Humanoid Muscles Plugin Scaffold

This project contains a Godot editor plugin that will provide a muscle configuration interface for humanoid skeletons. The current state only includes scaffolding for the plugin's main components.

## Structure
- `addons/puppet/` – plugin code
  - `plugin.gd` / `plugin.cfg` – register the plugin and a toolbar button
  - `muscle_window.tscn` / `muscle_window.gd` – placeholder UI window
  - `muscle_data.gd` – stub muscle definitions
  - `profile_resource.gd` – resource for storing profiles
  - `joint_converter.gd` – conversion and limit application stubs
  - `io.gd` – JSON import/export helpers

Enable the plugin in **Project > Project Settings > Plugins** after opening the project in Godot.
