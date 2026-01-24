# How to Update Your Widget to Show Interactive Buttons

## The Problem
Widgets cache their UI and code. After making code changes, the widget on your home screen won't automatically update. You need to rebuild and reinstall it.

---

## Solution: 3-Step Process

### Step 1: Build the Widget Extension in Xcode

1. Open **Push365.xcodeproj** in Xcode
2. At the top toolbar, click the **scheme dropdown** (shows current scheme/device)
3. Select **"Push365WidgetExtension"** from the schemes list
4. Select your device (e.g., "Lee's iPhone (2)") or a simulator
5. Click the **Run button** (▶️) or press **⌘R**
6. Wait for build to complete successfully

**What this does:** Installs the updated widget extension with interactive buttons to your device/simulator.

---

### Step 2: Remove Old Widget from Home Screen

1. On your device/simulator home screen, **long-press** the existing Push365 widget
2. Tap **"Remove Widget"** from the menu
3. Confirm **"Remove"**

**Why:** The old widget is using cached code. Removing it forces a fresh installation.

---

### Step 3: Add Fresh Widget with New Code

1. **Long-press** on an empty area of the home screen
2. Tap the **"+"** button (top-left corner)
3. In the search bar, type **"Push365"**
4. Select **Push365** from results
5. Choose widget size:
   - **Small**: Shows +5, +10 buttons
   - **Medium**: Shows 2×2 grid (+5, +10, +15, +20)
6. Tap **"Add Widget"**
7. Position and tap **"Done"**

---

## Verify the Update

### Small Widget Should Show:
- "Day X" at top
- Large remaining number in center (or "DONE" in green)
- **Two buttons at bottom: +5 and +10** ← NEW!

### Medium Widget Should Show:
- Left: "Day X", "Target: Y", remaining count
- **Right: 2×2 button grid (+5, +10, +15, +20)** ← NEW!

---

## Test Interactive Buttons

1. Tap a button (e.g., **+5**)
2. Widget should update within ~1 second
3. Remaining count should decrease by the amount tapped
4. Continue until remaining reaches 0
5. Verify buttons disappear and "DONE" appears in green

---

## Troubleshooting

### Widget Still Looks Old?
- Make sure you selected **Push365WidgetExtension** scheme (not main app)
- Try removing and re-adding widget again
- Restart device/simulator
- Clean build folder: **Product → Clean Build Folder** (⌘⇧K)

### Buttons Not Appearing?
- Check that device is running **iOS 17.0+** (AppIntent requirement)
- Verify widget has data (open main app first to sync)
- Check Console.app for any widget errors

### Button Taps Don't Work?
- Ensure App Groups is enabled in both targets
- Verify group name: `group.com.lschandler81.Push365`
- Check that main app has saved data at least once

---

## Quick Reference: Xcode Scheme Selection

```
Toolbar Location: Top of Xcode window
Format: [Scheme Name] > [Device/Simulator]

To Change:
1. Click the current scheme (e.g., "Push365 > Lee's iPhone")
2. Select "Push365WidgetExtension" from dropdown
3. Device/simulator auto-updates or select manually
4. Press ⌘R to build and run
```

---

## Why This is Necessary

- **Widgets run as separate extensions** with their own binary
- Code changes to widget files only affect the widget extension, not the main app
- The home screen widget caches its UI and doesn't auto-reload on code changes
- Must rebuild extension + remove/re-add widget to see updates
- This is standard iOS widget development workflow

---

## After This One-Time Update

Once the interactive widget is installed, it will:
- Persist across device restarts
- Auto-update at midnight
- Refresh immediately when buttons are tapped
- Sync with main app data automatically

You only need to rebuild/reinstall if you make further code changes to the widget.
