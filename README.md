# Sanguine's Trade -- Prisma UI Bridge

A small SKSE plugin that lets Papyrus drive a Prisma UI view. Used by Sanguine's Trade to render the Ledger as a web page instead of a UIExtensions list menu.

The plugin exposes a tiny set of Papyrus globals on a script called `ST_PrismaBridge` -- `IsAvailable`, `OpenLedger`, `CloseLedger`, `Invoke`, etc. When the user clicks a button in the HTML view, the plugin fires a Papyrus mod event called `ST_PrismaAction` carrying a string payload. ST_LedgerMenu listens for that event and dispatches to the same handler functions it always has.

This document covers building the DLL from source, installing it, and running a round-trip smoke test. After the smoke test passes, the actual Ledger UI gets built on top in a separate phase.

---

## What you'll end up with

After running through this README you will have:

- `SanguinesTrade.dll` in `Skyrim/Data/SKSE/Plugins/`
- `index.html` (the test view) in `Skyrim/Data/PrismaUI/views/SanguinesTrade/`
- `ST_PrismaBridge.pex` and `ST_PrismaTest.pex` in `Skyrim/Data/Scripts/`
- A small test quest in your ESP that hosts the listener

And you'll be able to open the test view with a console command, click a button, and see the action come through as an in-game notification.

---

## Prerequisites

You need three things installed on your machine. None of them are Skyrim-specific -- they're all standard developer tools.

**Visual Studio 2022 Community Edition** (free). Download the installer from `https://visualstudio.microsoft.com/downloads/`. When the installer asks which workloads to install, check **"Desktop development with C++"**. Leave the default options under that workload selected -- you need the MSVC v143 compiler, the Windows 10/11 SDK, and the C++ CMake tools. Total install size is about 8 GB.

**Git for Windows**. From `https://git-scm.com/download/win`. The default options are fine. You only need this to clone vcpkg.

**vcpkg**. This is Microsoft's C++ package manager. Open a regular Command Prompt (or PowerShell) and run:

```
cd C:\
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
```

That gives you `C:\vcpkg\` with a working `vcpkg.exe`. Then set an environment variable so CMake can find it. In a Command Prompt run:

```
setx VCPKG_ROOT "C:\vcpkg"
```

Close that Command Prompt afterward -- environment variables only apply to new terminals. Open a fresh one to verify:

```
echo %VCPKG_ROOT%
```

It should print `C:\vcpkg`. If it doesn't, the environment variable didn't take. Reboot or set it manually under System Properties -> Environment Variables.

You also need **PrismaUI itself** installed in your Skyrim data folder. The bridge depends on `PrismaUI.dll` being present at runtime in `Data/SKSE/Plugins/`. Get it from Nexus if you haven't already.

---

## Building the DLL

The plugin source lives in this folder. Place the entire folder somewhere convenient -- I'll assume `C:\Modding\STBridge\` for the rest of this doc, but anywhere is fine as long as the path has no spaces.

The first build is the slow one because vcpkg has to download and compile CommonLibSSE-NG and its dependencies. Expect 10-20 minutes the first time. Subsequent builds are fast (5-30 seconds) because everything's cached.

**Option A: build from Visual Studio 2022 (recommended)**

1. Open Visual Studio 2022.
2. From the start screen, choose **Open a local folder**, then navigate to `C:\Modding\STBridge\` and click **Select Folder**.
3. VS detects the `CMakeLists.txt` and `CMakePresets.json` automatically. The CMake output panel at the bottom will show **CMake generation started**.
4. Wait for vcpkg to finish installing dependencies. You'll see lines about installing `commonlibsse-ng`, `spdlog`, `fmt`, etc. When the bottom of the output says **CMake generation finished**, configuration is done.
5. From the toolbar at the top, change the configuration dropdown from `x64-Debug` to `x64-Release` if it's not already on Release. (The preset name in the dropdown will be `vs2022-windows`.)
6. From the menu: **Build -> Build All** (or Ctrl+Shift+B).
7. When the build completes, the output panel shows the path to the DLL. It'll be something like `C:\Modding\STBridge\build\Release\SanguinesTrade.dll`.

**Option B: build from the command line**

Open a fresh `Developer Command Prompt for VS 2022` (search for it in the Start menu -- this is critical because it sets up MSVC paths). Then:

```
cd C:\Modding\STBridge
cmake --preset vs2022-windows
cmake --build build --config Release
```

When that finishes, the DLL is at `build\Release\SanguinesTrade.dll`.

---

## Installing the artifacts

### 1. The plugin DLL

Copy `SanguinesTrade.dll` to your Skyrim install at:

```
Skyrim Special Edition\Data\SKSE\Plugins\SanguinesTrade.dll
```

If you're using Mod Organizer 2 or Vortex, install it as a mod by zipping a folder structured like `SKSE/Plugins/SanguinesTrade.dll` and dropping that zip in.

### 2. The HTML view

Create a folder `SanguinesTrade` under your Prisma views directory and copy the test page in:

```
Skyrim Special Edition\Data\PrismaUI\views\SanguinesTrade\index.html
```

The folder under `views/` must exactly match the path the plugin uses (`SanguinesTrade/index.html`).

### 3. The Papyrus scripts

The two `.psc` files in `papyrus/` need to be compiled into `.pex` files and put in your Scripts folder. Two ways to do this:

**Option 1: from inside the Creation Kit.** Drop both `.psc` files into `Skyrim Special Edition\Data\Source\Scripts\` (you may need to create the Source\Scripts folder if it doesn't exist). Open the CK, go to **Gameplay -> Papyrus Script Manager**, find each script in the list, right-click, and choose **Compile**. The resulting `.pex` files land in `Data\Scripts\`.

**Option 2: from the command line.** Drop the `.psc` files into `Data\Source\Scripts\`, then from a Command Prompt:

```
cd "Skyrim Special Edition\Papyrus Compiler"
PapyrusCompiler.exe ST_PrismaBridge -f="TESV_Papyrus_Flags.flg" -i="..\Data\Source\Scripts" -o="..\Data\Scripts"
PapyrusCompiler.exe ST_PrismaTest   -f="TESV_Papyrus_Flags.flg" -i="..\Data\Source\Scripts" -o="..\Data\Scripts"
```

Either way you should end up with `ST_PrismaBridge.pex` and `ST_PrismaTest.pex` in `Data\Scripts\`.

### 4. The test quest (CK work, ~30 seconds)

Open the Creation Kit on your Sanguine's Trade ESP. In the **Object Window**, right-click on **Quest** under Character and choose **New**. Set:

- **EditorID:** `ST_PrismaTestQuest`
- **Quest Name:** (leave blank)
- **Start Game Enabled:** checked
- **Run Once:** unchecked

Switch to the **Scripts** tab on the new quest. Click **Add**, choose **`[New Script]`**, and pick `ST_PrismaTest` from the list (or browse to it -- it should appear once `.pex` is in the Scripts folder). Save the ESP.

That's all the CK work. Once the smoke test passes you can delete this quest and the test script.

---

## Smoke test

Launch Skyrim. Get into a save (or new game) where the test quest will start.

Wait a few seconds, then open the console with `~` and type:

```
cgf "ST_PrismaBridge.IsAvailable"
```

The console should echo `[True]`. If it echoes `[False]`, the SKSE plugin loaded but PrismaUI itself isn't present -- check `Documents\My Games\Skyrim Special Edition\SKSE\SanguinesTrade.log` for the exact reason.

Now open the view:

```
cgf "ST_PrismaBridge.OpenLedger"
```

The dark gold-bordered test panel should appear in the center of the screen. Your mouse cursor should now interact with it (Prisma takes input focus).

Click any button. An in-game notification should appear in the upper-left corner with the action payload, e.g. **`[ST] Action: ping`** or **`[ST] Action: assign|0xFF000ABC|0x00012345`**.

Push state into the view from Papyrus to test the inbound direction:

```
cgf "ST_PrismaBridge.Invoke" "window.STRender('hello from papyrus')"
```

The "Inbound" panel inside the view should update to show `hello from papyrus`.

Close the view:

```
cgf "ST_PrismaBridge.CloseLedger"
```

If all four operations work -- IsAvailable, Open, button click round-trip, Invoke, Close -- the bridge is good and we're ready for the real Ledger UI.

---

## Where things live (for debugging)

**SKSE plugin log.** `Documents\My Games\Skyrim Special Edition\SKSE\SanguinesTrade.log`. Re-created every game launch. First lines after launch should look like:

```
[hh:mm:ss.fff] [info] ===== SanguinesTrade Prisma bridge loading =====
[hh:mm:ss.fff] [info] Plugin version 1.0.0
[hh:mm:ss.fff] [info] Plugin load complete; awaiting kPostLoad
[hh:mm:ss.fff] [info] PrismaUI API obtained (V1)
[hh:mm:ss.fff] [info] View pre-loaded and hidden
[hh:mm:ss.fff] [info] Registered 7 Papyrus natives on ST_PrismaBridge
```

If you see `PrismaUI not loaded`, PrismaUI's own DLL is missing. If you see `CreateView returned 0`, the HTML file is missing or the path is wrong.

**Papyrus log.** `Documents\My Games\Skyrim Special Edition\Logs\Script\Papyrus.0.log`. Search for `[ST] PrismaTest:` to see the test script's traces.

**Prisma logs.** PrismaUI writes its own log under `My Games\Skyrim Special Edition\SKSE\PrismaUI.log`. Has CEF/Ultralight rendering errors if the HTML is malformed.

---

## Troubleshooting

**"CMake generation failed" on first open.** Almost always means `VCPKG_ROOT` isn't set or is wrong. Open a new Command Prompt and `echo %VCPKG_ROOT%`. It should print `C:\vcpkg` (or wherever you cloned vcpkg). If not, set it via System Properties -> Environment Variables and restart Visual Studio.

**vcpkg fails to install commonlibsse-ng.** Open `vcpkg-configuration.json` in this project folder. The `baseline` fields point at specific commits in the vcpkg and CommonLibSSE-NG repos. If those repos move on and your version is too old/new, vcpkg complains. To get current values:

- Default registry baseline: in a Command Prompt, `cd C:\vcpkg && git rev-parse HEAD` -- copy the output.
- CommonLibSSE-NG baseline: `git ls-remote https://github.com/CharmedBaryon/CommonLibSSE-NG main` -- copy the SHA from the first column.

Update the `baseline` strings in `vcpkg-configuration.json` and reconfigure (`Project -> Configure Cache` in VS, or rerun the `cmake --preset` command).

**The DLL builds but Skyrim doesn't load it.** Check `Documents\...\SKSE\skse64.log` for a line about `SanguinesTrade.dll`. Common causes: built in Debug instead of Release (use Release), built for the wrong runtime version (the `CompatibleVersions({SKSE::RUNTIME_LATEST})` line in `Plugin.cpp` covers the latest AE patch -- if you're on an older runtime, you may need to set a specific version), or Address Library is missing as a runtime mod.

**`cgf "ST_PrismaBridge.IsAvailable"` returns nothing or errors.** The `.pex` file is missing or the script wasn't compiled. Verify `Data\Scripts\ST_PrismaBridge.pex` exists. If it's there but the console errors with "Cannot find script" -- the file got compiled wrong (likely from an empty or broken `.psc`). Recompile.

**The view appears but the cursor doesn't interact.** Prisma needs explicit focus. The `OpenLedger` native already calls `Focus`, but if input is being captured by another menu (a SkyUI panel, a dialogue) Prisma can't take focus on top. Close any open menus first.

**Buttons in the view don't fire mod events.** Check `SanguinesTrade.log` for `Dispatched ST_PrismaAction:` lines. If they're missing, the JS listener didn't register -- look for `Registered JS listener: window.STAction` earlier in the log. If those are present but Papyrus doesn't see the event, the test quest didn't start; verify it's marked Start Game Enabled and you're loading a save from after the quest's `OnInit` ran.

---

## How this relates to the shipped mod

The DLL you rebuild here is byte-for-byte the role of the one shipped with Sanguine's Trade: a thin bridge and nothing else. The shipped consumer is the Prisma Ledger (`Data\PrismaUI\views\SanguinesTrade\index.html` plus `ST_PrismaLedger.psc` / `ST_LedgerMenu.psc`, whose sources ship with the mod) -- it calls the same 7 natives listed above and listens for the same `ST_PrismaAction` mod event. There is no other logic in the DLL: no game-record edits, no hooks beyond the SKSE messaging listener, no network access. `src\PrismaUI_API.h` is StarkMP's published PrismaUI API header, included verbatim as its own first line instructs ("Copy this file into your own project if you wish to use this API") -- it declares the interface; all bridge logic lives in `src\Plugin.cpp`.
