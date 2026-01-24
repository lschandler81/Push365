# Fresh Watch App Setup

## Step 1: Clean Up Xcode Project (2 minutes)

1. **Open `Push365.xcodeproj` in Xcode**

2. **Delete old watch targets:**
   - Click on project name at top of navigator
   - Look at TARGETS list on right side
   - **Delete these** (select each, press Delete key):
     - Push365 Watch App Watch App
     - Push365 Watch App Watch AppTests  
     - Push365 Watch App Watch AppUITests
     - Push365 Watch WidgetsExtension (watch one only!)

3. **Remove red folders from navigator:**
   - Right-click each red folder → Delete → "Move to Trash"
   - Red folders will have names like "Push365 Watch..."

4. **Product → Clean Build Folder** (⇧⌘K)

5. **Close Xcode**

## Step 2: Add New Watch Target (3 minutes)

1. **Reopen Push365.xcodeproj**

2. **File → New → Target → watchOS → Watch App**
   - Product Name: **Push365 Watch**
   - Organization Identifier: **com.lschandler81**  
   - Embed in: **Push365**
   - Click **Finish** → **Activate**

3. **You now have a clean watch target!**

## Step 3: Add Your Code (5 minutes)

**Your prepared watch code is here:**  
`/Users/leechandler/Desktop/Push365_WatchCode_Backup/`

**In Xcode:**

1. **Delete template files** from new Push365 Watch target:
   - Delete whatever App/ContentView files Xcode created

2. **Drag these files** from Backup folder → Xcode Push365 Watch folder:
   - `WatchLoggingView.swift`
   - `Push365WatchComplications.swift`
   
   ✅ Copy items if needed  
   ✅ Add to: Both Push365 Watch targets

3. **File → New → File → Swift File** named `Push365WatchApp.swift`:
```swift
import SwiftUI

@main
struct Push365WatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchLoggingView()
        }
    }
}
```

4. **File → New → File → Swift File** named `Push365WatchComplicationsBundle.swift` (add to Widget Extension target):
```swift
import WidgetKit
import SwiftUI

@main
struct Push365WatchComplicationsBundle: WidgetBundle {
    var body: some Widget {
        Push365WatchComplications()
    }
}
```

5. **Add shared code:**
   - Select `Push365/Services/WidgetDataStore.swift`
   - File Inspector → Target Membership
   - Check ✅ both watch targets

6. **Configure App Groups:**
   - Select Push365 Watch target → Signing & Capabilities
   - + Capability → App Groups
   - Enable: `group.com.lschandler81.Push365`
   - Repeat for Push365 Watch Widget Extension target

7. **Build!** (⌘B)

## Done!

- Clean project structure
- Single watch app target
- Watch complications working
- No duplicates, no mess

**Takes ~10 minutes total**
