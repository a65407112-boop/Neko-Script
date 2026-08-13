Caelus Neko Hub 3.29 Remote Cache

WHY
3.28 embedded ~9.5 MB of model data inside one Lua source. Some executors crash
while parsing/decoding such a large chunk.

HOW 3.29 WORKS
- The owner executes only loader.lua.
- loader.lua is small.
- hub.lua is downloaded automatically.
- NekoShadowAssets.rbxmx is downloaded once and cached.
- Each Legacy Neko .rbxm is downloaded only when selected, then cached.
- Saved Custom Nekos stay in CaelusNekoShadow/CustomNekos/.

PUBLISH
1. Upload this entire folder to a GitHub repository.
2. Open loader.lua.
3. Set BASE_URL to the raw GitHub URL of this folder, for example:
   https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/CaelusNekoHub-3.29
4. The owner only needs to execute loader.lua (or a loadstring pointing to it).

Do not embed assets back into loader.lua.
