# Push365 Widgets - Setup Instructions

## Phase 2: Widget Implementation Complete

### What Was Added

**New Files Created:**
1. `Push365Widget/Push365Widget.swift` - Main widget implementation
2. `Push365Widget/Push365WidgetBundle.swift` - Widget bundle entry point
3. `Push365Widget/WidgetDataStore.swift` - Shared data storage for widget
4. `Push365Widget/Info.plist` - Widget extension configuration
5. `Push365/Push365/Services/WidgetDataStore.swift` - Main app data store

**Modified Files:**
- `Push365/Push365/Views/HomeView.swift` - Added widget data updates

### Widget Features

**Home Screen Widgets:**
- **Small Widget**: Shows day number and remaining push-ups
- **Medium Widget**: Shows day number, target, and remaining push-ups

**Lock Screen Widgets:**
- **Rectangular**: Day number and remaining count
- **Circular**: Minimal view
- **Inline**: Single-line display

### Data Displayed
- Day number (calculated from start date)
- Today's target (based on mode: Strict or Flexible)
- Remaining push-ups (target - completed)

### Widget Behavior
- Silent and informational only
- No animations or calls to action
- Updates automatically at midnight
- Reflects correct day/target even if app not opened
- Updates immediately when user logs push-ups

### Manual Setup Required in Xcode

**IMPORTANT**: You must manually add the Widget Extension target in Xcode:

1. **Add Widget Extension Target:**
   - File → New → Target
   - Select "Widget Extension"
   - Name: "Push365Widget"
   - Bundle Identifier: "com.yourteam.Push365.Push365Widget"
   - Include Configuration Intent: NO

2. **Add Files to Widget Target:**
   - Add `Push365Widget/Push365Widget.swift`
   - Add `Push365Widget/Push365WidgetBundle.swift`
   - Add `Push365Widget/WidgetDataStore.swift`
   - Add `Push365Widget/Info.plist`

3. **Enable App Groups:**
   - Main app target → Signing & Capabilities → + Capability → App Groups
   - Widget target → Signing & Capabilities → + Capability → App Groups
   - Both targets: Add group "group.com.push365.app"

4. **Add WidgetDataStore to Main App:**
   - Ensure `Push365/Push365/Services/WidgetDataStore.swift` is in the main app target

5. **Build Settings:**
   - Widget target → Deployment Info → iOS 17.0+
   - Widget target → General → Frameworks and Libraries → Add WidgetKit

### Where Widgets Appear

**Home Screen:**
- User long-presses home screen → taps "+" → searches for "Push365"
- Select Small or Medium widget size
- Widget shows current day and remaining push-ups

**Lock Screen:**
- Settings → Wallpaper → Customize → Lock Screen → Add Widgets
- Search for "Push365"
- Add Rectangular, Circular, or Inline widget

### Testing
- Build and run the widget scheme in Xcode
- Or build main app, then add widget from home screen
- Widget updates when you log push-ups in the app
- Widget automatically updates at midnight to show new day

---

## Phase 2 Summary

✅ Home Screen widgets (Small, Medium)  
✅ Lock Screen widgets (Rectangular, Circular, Inline)  
✅ Silent, informational display only  
✅ Auto-updates at midnight  
✅ Reflects correct day/target without app launch  
✅ No changes to existing logic, rules, or features  
✅ No new app features added
