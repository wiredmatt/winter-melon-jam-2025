# Winter Melon Jam 2025

## Entry

Our entry is titled "The Masked King". You were once the ruler of Masked Civilization - where everyone wears a mask - but your allies betrayed you and usurped the throne... Reclaim your birthright, connect with your kin and decide the future of Masked Civilization.

## Development

This game was developed using [love2d](https://love2d.org), install it and then run

```sh
love .
```

The repository follows a clean structure, and everything is where you'd expect it to be.

- The battles are centralized in [data/battles.lua](./data/battles.lua) and [src/scenes/Battle](./src/scenes/Battle/scene.lua)
- The intro sequence is centralized in [src/scenes/Intro/scene.lua](./src/scenes/Intro/scene.lua)
- The Main Menu is centralized in [src/scenes/MainMenu/scene.lua](./src/scenes/MainMenu/scene.lua)
- The Settings are centralized in [src/scenes/Settings/scene.lua](./src/scenes/Settings/scene.lua)
- All the major abstractions live under [lib](./lib/). All these libraries were handcrafted by yours truly over the last year or so, note however that they don't really offer any real advantage, as they do the bare minimum expected of a game engine.

## Credits

- [32rogues](https://sethbb.itch.io/32rogues)
- [Tiny5](https://fonts.google.com/?query=Stefan+Schmidt)
- [Music and SFX](https://www.youtube.com/@DylbyllSecretChannel/featured) - "dylbyll" on Discord.
