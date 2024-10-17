---
sidebar_position: 2
---

# Installation

## Method #1 - RepoToRoblox

Using the RepoToRoblox plugin is the easiest way to install in Studio.

1. Make sure you have set your GitHub authentication token in the plugin settings.
2. In the RepoToRoblox widget, enter `bura-games` as the owner and `data-structures` as the repository.
3. Click the Clone Repository button.

## Method 2 - Manual

1. Visit the [latest release](https://github.com/Bura-Games/data-structures/releases)
2. Under *Assets*, click `DataStructures.rbxm`
3. - Using [Rojo](https://rojo.space/)? Put the file somewhere where Rojo can sync it.
   - Using Roblox Studio? Drag the file onto the viewport. It should insert under Workspace.

## Method 3 - Wally (UNIMPLEMENTED)

1. Setup [Wally](https://wally.run/) by using `wally init`.
2. Add `bura-games/data-structures` as a dependency.

```toml
[dependencies]
DataStructures = "bura-games/data-structures@^1.0.0"
```
