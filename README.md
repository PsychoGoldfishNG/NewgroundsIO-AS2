# NewgroundsIO-AS2

A comprehensive ActionScript 2.0 library for integrating Newgrounds.io API functionality into Flash games and applications. This library provides both simple wrapper methods for common tasks and low-level access to the full API for advanced use cases.

---

## Table of Contents

- [Installing the Library](#installing-the-library)
- [Using the Component Clips](#using-the-component-clips)
- [Using the NGIO Class](#using-the-ngio-class)
- [Advanced Use](#advanced-use)

---

## Installing the Library

The NewgroundsIO-AS2 library offers **3 ways** to integrate with your Flash project, with the first 2 methods using pre-compiled code for faster game compilation.

### Option 1: Clone from Git (Recommended)

If you have Git installed, clone the repository:

```bash
git clone https://github.com/PsychoGoldfishNG/NewgroundsIO-AS2.git
```

Then follow one of the installation methods below.

### Option 2: Direct Download

If you don't use Git, download the [latest release](https://github.com/PsychoGoldfishNG/NewgroundsIO-AS2/releases). The release includes:

- **components.fla** - Pre-compiled components (for Methods 1 & 2)
- **Source files** - ActionScript source code (for Method 3)

Extract the files to a location on your computer, then follow one of the installation methods below.

---

## Installation Methods

### Method 1: Use the Connector Component (Easiest - Pre-compiled) ✓

This is the recommended approach. The Connector Component has the entire NewgroundsIO library pre-compiled inside it.

1. Open `bin/components.fla` in Flash 8 or later
2. Go to the **connector** frame in the timeline
3. On the stage, select the Connector Component and copy it (Ctrl+C)
4. Open your game's FLA file
5. Go to **frame 1** of your main timeline, paste it (Ctrl+V)
6. In the Properties panel, set the **Component Parameters**:
   - `App ID` - The App ID from your Newgrounds Project
   - `Encryption Key` - The encryption key from your Newgrounds Project
   - `App Version` - Your game's version (optional)

![The Connector Component](./docs/connectorComponent.png "The Connector Component")

**That's it!** The component will automatically handle app initialization and loading. Once it's done, your movie will play.

**Then in your code, you can use NGIO:**
```actionscript
// NGIO is already initialized by the Connector Component
// Check if the user is logged in
if (NGIO.hasUser()) {
    var user = NGIO.getUser();
    trace("Welcome, " + user.name);
} else {
    trace("User not logged in");
}
```

**Benefits:**
- Dead simple: just copy from one FLA, paste into yours
- Pre-compiled for faster game compilation
- Automatic app initialization
- Handles all the complexity for you

---

### Method 2: Drag the Library Component (Easy - Pre-compiled) ✓

If you don't want to use the full Connector Component, you can just use the pre-compiled library component.

1. Open `bin/components.fla` in Flash 8 or later
2. Go to the **library** frame in the timeline
3. On the stage, select the NgioLibraryComponent and copy it (Ctrl+C)
4. Open your game's FLA file
5. Go to **frame 1** (or any early frame), paste it (Ctrl+V)
6. That's it! You now have full access to the NGIO library

![The Compiled Library Component](./docs/libraryComponent.png "The Compiled Library Component")

Note: Once you have imported it, you can remove it from the timeline if you like.

**Then use it in your code:**
```actionscript
// Initialize NGIO with your app credentials
NGIO.init("YOUR_APP_ID:YOUR_SESSION_ID", "YOUR_ENCRYPTION_KEY", "1.0.0");

// Now you can use NGIO!
```

**Benefits:**
- Very easy: just copy from one FLA, paste into yours
- Pre-compiled for faster game compilation
- Smaller footprint than the full Connector Component
- You have full control over initialization

---

### Method 3: Copy Source Files (Traditional)

If you prefer working with source files or need maximum flexibility, you can copy the ActionScript files directly.

1. From the NewgroundsIO-AS2 repo's **build** folder, copy these folders/files into your game's folder:
   - The entire **io** folder (contains the core library)
   - The **NGIO.as** file (the main wrapper class)

   Your folder structure should look like:
```
MyGame/
├── MyGame.fla
├── NGIO.as
└── io/
    └── newgrounds/
```

2. In Flash 8 or later, when you compile your SWF, ActionScript will automatically find these files in the same directory as your FLA.

3. You can now use NGIO directly in your timeline code.

**Benefits:**
- Full control over source code
- Can modify library behavior if needed
- Easy debugging with source files
- No external dependencies

**Drawbacks:**
- Slower compilation (source files compiled each time)
- More files to manage
- Files duplicated if used in multiple projects

---

## Choosing Your Method

| Method | Ease | Speed |
|--------|------|-------|
| 1. Connector Component | ⭐⭐⭐ | ⭐⭐⭐ |
| 2. Library Component | ⭐⭐ | ⭐⭐⭐ |
| 3. Source Files | ⭐⭐ | ⭐ |

**Recommendation:** Start with **Method 1** (Connector Component) for the best experience. If you need more control over initialization, use **Method 2** instead.

### Fonts

NGIO components use fonts that are available in the `fonts/` directory. To match the component styling, you will need to install these fonts locally on your system.

---

## Using the Component Clips

The library includes **bin/components.fla** with pre-built Flash components for common Newgrounds.io features. These components have the NewgroundsIO library pre-compiled inside them:

- **Connector Component** - Initializes your app, loads all metadata, and handles logging in users (includes full library)
- **Medal Popup Component** - Display unlocked medals to the user
- **ScoreBoard Components** - Show high scores
- **Cloud Save Components** - Interface for saving and loading cloud saves
- **NgioLibraryComponent** - Standalone library component (includes full library without other features)

### Accessing Components from Your FLA

The easiest way is to use **Method 1** or **Method 2** from the Installation section above, which lets you open the external library and drag components directly into your FLA.

Alternatively, you can:

1. Open **bin/components.fla** in Flash 8 or later
2. In the Library panel, find the component you want
3. Right-click the component symbol → **Copy** (or drag it directly to another FLA)
4. In your game's FLA, right-click on your stage where you want the component → **Paste** (or use Ctrl+V)
5. Configure the component using the **Component Parameters** in the Properties panel

![The Component Parameters Section](./docs/componentParameters.png "The Component Parameters Section")

These components can be edited and customized to better fit your project.

> **Note on same-frame access:** Components register themselves with `NGIO`'s static references (`NGIO.connectorComponent`, `NGIO.scoreboardComponent`, etc.) after they are constructed. If your timeline code runs on the same frame the component first appears, the static reference may not be populated yet depending on layer ordering. For the Connector, Scoreboard, and SaveManager components, **give them instance names** and use those names to set up handler functions — this sidesteps the timing issue entirely.

### The Connector Component ###

![The Connector Component](./docs/connectorComponent.png "The Connector Component")

This component preloads your game, along with all of your NGIO metadata.

Once preloading is complete, it will attempt to get the user logged in.

 * If the game is running directly on Newgrounds, this will be automatic.
 * If this game is running elsewhere, the user will be prompted to log in.

It should be placed in the first frame of your movie, or after any custom preloader you are using.

Set the following **Component Parameters**:

 * `App ID` - The App ID provided in your Newgrounds Project
 * `Encryption Key` - The AES-128 Encryption key provided in your Newgrounds Project
 * `App Version` - The current build version of your game (optional)
 * `Debug Mode` - Enable this to test medal unlocks and score posting without actually saving them on the server
 * `Show Network Messages` - Enable this to see all incoming and outgoing network packets. (Useful for advanced debugging)

#### Basic Use ####

Once the component has completed its tasks, it will automatically play the movie.

#### Advanced Use ####

Give the Connector Component an **instance name** (e.g., `myConnector`) in the Properties panel, then override the `onComplete` handler in your code:

```actionscript
// Give the connector component the instance name "myConnector"
myConnector.onComplete = function() {
	// start your game!
};
```

#### Alternate Advanced Use ####

Edit the component clip, and locate the frame labelled `finished`.

Replace existing code, and add any new UI elements you may need.

### The Medal Popup Component ###

![The Medal Popup Component](./docs/medalPopup.png "The Medal Popup Component")

This component unlocks medals on the server, and displays the visual popup message.

It should be placed on a top level layer in your root timeline that covers any keyframes that a medal unlock could occur.

If you use multiple scenes, add this to each scene where medals can be unlocked.

You may also use the following **Component Parameter**:

 * **Show Even if Unlocked** - Check this if you want the popup to be displayed even if the user has already unlocked the requested medal.

#### Basic Use ####
This component automatically associates itself in the `NGIO` class, so you can trigger a medal unlock from anywhere in your game using the following code:

```actionscript
NGIO.medalPopup.unlock(int(medal_id.text));
```

### The Scoreboard Components ###

![The Scoreboard Components](./docs/scoreboardComponent.png "The Scoreboard Components")

There are 3 variations of the Scoreboard component available for use:

 * **Scoreboard Full** - Use this is you have more than one scoreboard, and want to provide a central place to view them all.
 * **Scoreboard Single** - Use this if you want to show a single scoreboard, and be able to view different date ranges and social groups.
 * **Scoreboard Minimalist** - Use this if you only want to show the scores for a single board with no other options.

All 3 versions use the same setup. Simply paste them wherever you want to show them to the user, and fill in the appropriate **Component Params**

 * `ScoreBoard ID` - If you have multiple boards, this will be the board that is shown when the component loads. You can leave this set to 0 if you only have one board, or don't care which is displayed by default.
 * `Period` - Select the time period you want to load by default.
 * `Show` - Select who to show scores for. This can be 'Everyone', 'Friends', or 'My Best'.
 * `Tag` - If you are using tagged boards, set this to the tag you want to filter on.

#### Basic Use ####

Each scoreboard has a close (X) button in the top right. You can edit the clip and remove it if you want to handle exiting the scoreboard screen yourself.

Otherwise, give the component an **instance name** (e.g., `myScoreboard`) and override the `onClose` handler:

```actionscript
// Give the scoreboard component the instance name "myScoreboard"
myScoreboard.onClose = function() {
	// handle closing the board
};
```

Posting scores is done completely in code, like so:

```actionscript
var scoreBoard = NGIO.getScoreBoard(board_id);
var tag = null; // or whatever tag you want to post this score with

scoreBoard.postScore(score_value, tag, function(score, error) {
	if (error == null && score != null) {
		trace("Score posted! Formatted value: " + score.formatted_value);
	} else {
		trace("Failed to post score: " + error);
	}
});
```

### The Cloud Save Components ###

![The Cloud Save Components](./docs/saveslotManager.png "The Cloud Save Components")

We have 2 cloud save components that both work exactly the same.

 * **Basic** - Used for basic setups where you have a total of 3 available save slots.
 * **Supporter** - Used for supporter-upgraded games that have a total of 10 available save slots.

These components can be used to load from or save to a cloud save slot.

Copy the component wherever you have a save or load dialogue and set the following **Component Parameters**:

 * **Action** - Either "Load Data" or "Save Data", depending on how you want it to behave.
 * **Sort By** - Set to Slot ID to keep slots in numeric order, or Last Updated for most recent saves to appear at the top.
 * **Show Slot Numbers** - Uncheck this if you want to hide the slot numbers (looks better when sorting by most recent)
 * **Use Raw Data** - Check this if you are using any custom serialization to work with raw string data, otherwise you can save and load native data types that will be automatically serialized.

#### Basic Use ####

Give the component an **instance name** (e.g., `mySaveManager`) and override the handler functions:

For loading data, use the following code:

```actionscript
// Give the save manager component the instance name "mySaveManager"
mySaveManager.onSlotLoaded = function(data, error) {
	if (error == null) {
		// you have your data now!
		var loaded_data = data;
	}
};
```

For saving data, use the following code:

```actionscript
// Give the save manager component the instance name "mySaveManager"
// first, attach the data you want to save
mySaveManager.setData(data_to_save);

// listen for when the slot has been selected and saved on the server
mySaveManager.onSlotSaved = function(error) {
	if (error == null) {
		// your data saved successfully!
	}
};
```

Each saveslot manager has a close (X) button in the top right. You can edit the clip and remove it if you want to handle exiting the save/load screen yourself. Otherwise, override the `onClose` handler:

```actionscript
mySaveManager.onClose = function() {
	// handle closing the save manager
};
```

---

## Using the NGIO Class

The `NGIO` class is the primary interface for most developers. It provides simple static methods that handle all the complexity of the API internally.

### Initialization

Before using any NGIO methods, you must initialize the library with your app credentials:

```actionscript
NGIO.init(
	"YOUR_APP_ID:YOUR_SESSION_ID",
	"YOUR_ENCRYPTION_KEY",
	"1.0.0",    // Your app version (optional)
	false       // Debug mode (optional, default false)
);
```

**Example:**
```actionscript
// In frame 1 of your main timeline
NGIO.init("12345:abcdef1234", "uXp/7Q9V4vG5L6R2W9zB8A==", "1.0.0");
```

### Understanding the Callback Model

Most NGIO methods that perform server operations use callbacks. When the operation completes, your callback function is called with the result.

**Callbacks with Results:**
Some methods return specific data in the callback:

```actionscript
// Gets medals from the server
NGIO.loadMedals(function(medals, error) {
	if (error == null) {
		trace("Loaded " + medals.length + " medals");
	}
});
```

**Scope Management:**
Use the optional `thisArg` parameter to control callback scope:

```actionscript
NGIO.checkSession(onSessionChecked, this);

function onSessionChecked(status) {
	// 'this' refers to your object, not the NGIO callback scope
}
```

**Important: Asynchronous Execution**

Callbacks are **asynchronous**, meaning your code **continues to execute immediately** while the operation happens in the background. The callback function is only called later when the server responds.

```actionscript
trace("1. Starting medal load");

NGIO.loadMedals(function(medals, error) {
	trace("3. Medals loaded, count: " + medals.length);  // Called later!
});

trace("2. Game continues running");  // This executes BEFORE the callback!

// Output order:
// 1. Starting medal load
// 2. Game continues running
// 3. Medals loaded, count: 5  (only appears after server responds)
```

**Common Mistake:**
```actionscript
// WRONG - medals will be null here!
NGIO.loadMedals(function(medals, error) {
	myMedals = medals;  // Set later
});

// This runs BEFORE the callback, so myMedals is still null
if (myMedals != null) {  // Will be false!
	displayMedals(myMedals);  // Never runs
}

// CORRECT - put your code in the callback
NGIO.loadMedals(function(medals, error) {
	if (error == null) {
		displayMedals(medals);  // Now medals are available
	}
});
```

### Data Loading Strategy

The NGIO library uses a **caching strategy** to store app data locally, reducing server requests and improving performance. Understanding when and how to load data is crucial for a good user experience.

#### Two-Phase Loading Approach

**Phase 1: Pre-Session (Immediate)**

Load app metadata immediately when your game starts, before the user logs in:

```actionscript
NGIO.loadAppData(
	['currentVersion', 'hostApproved'],
	function(error) {
		var version = NGIO.getCurrentVersion();
		var hostOk = NGIO.getHostApproved();

		if (!hostOk) {
			trace("ERROR: App not approved to run on this domain!");
			// call NGIO.openOfficialUrl() in a click action to load a legal version
			return;
		}

		if (NGIO.getClientDeprecated()) {
			trace("New version available!");
			// call NGIO.openOfficialUrl() in a click action to load the new version
			return;
		}

		// Proceed with game startup
		proceedToMainMenu();
	}
);
```

**Phase 2: Post-Session (After User Authenticates)**

Once you have an established user session, load interactive data like medals, scoreboards, and save slots:

```actionscript
NGIO.checkSession(function(status) {
	if (status.status == "logged-in") {
		// User is logged in, now load their personal data
		NGIO.loadAppData(
			['medals', 'scoreBoards', 'saveSlots', 'medalScore'],
			function(error) {
				if (error == null) {
					trace("Loaded user data successfully");
					showUserProfile();
				}
			}
		);
	} else {
		trace("User is not authenticated, skipping data load");
	}
});
```

#### Important Timing Warnings

**Loading Medals Before Session:**
```actionscript
// WRONG - Called before user logs in
NGIO.loadMedals(function(medals, error) {
	// medals will have correct metadata BUT:
	// medal.unlocked will be FALSE for ALL medals (user not authenticated)
	// You won't know which medals the user has actually earned
});
```

**CORRECT:**
```actionscript
// Wait for authenticated session first
NGIO.checkSession(function(status) {
	if (status.status == "logged-in") {
		NGIO.loadMedals(function(medals, error) {
			// NOW medal.unlocked reflects actual user progress
			for (var i = 0; i < medals.length; i++) {
				trace(medals[i].name + " - Unlocked: " + medals[i].unlocked);
			}
		});
	}
});
```

**Similar Issue with Save Slots:**
- Loading before session: save slots will appear empty
- Loading after session: slots will contain the user's actual save data

#### Recommended Pattern

```actionscript
function initializeGame() {
	// Step 1: Check version and host (no session needed)
	NGIO.loadAppData(['currentVersion', 'hostApproved'], onCoreAppDataLoaded);
}

function onCoreAppDataLoaded(error) {
	if (!NGIO.getHostApproved()) {
		showError("App not authorized on this domain");
		return;
	}

	// Step 2: Establish session
	NGIO.checkSession(onSessionEstablished);
}

function onSessionEstablished(status) {
	if (status.status == "logged-in") {
		// Step 3: Load user-specific data
		NGIO.loadAppData(['medals', 'scoreBoards', 'saveSlots', 'medalScore'], onUserAppDataLoaded);
	} else {
		// Step 3b: Handle non-logged-in session
		// Many statuses may be returned here (not-logged-in, expired, error, etc.)
		// See "Check session status with server" section for proper handling of each case
	}
}

function onUserAppDataLoaded(error) {
	if (error == null) {
		showMainMenu();
	}
}
```

### Wrapper Functions

**Note on Caching:** Most wrapper methods come in two forms:
- `loadXYZ()` - Fetches from server (asynchronous, updates cache)
- `getXYZ()` - Returns cached data (synchronous, no network call)

Use `getXYZ()` methods when you already have data loaded - they're faster and don't require callbacks. When objects are updated on the server (through methods like `medal.unlock()` or `scoreBoard.postScore()`), the cached versions are automatically updated, so your references always reflect the current state:

```actionscript
// After loading medals once, use this for repeated access:
var medals = NGIO.getMedals();  // Instant, no callback needed
for (var i = 0; i < medals.length; i++) {
	displayMedal(medals[i]);
}

// Later, when a medal is unlocked:
var medal = NGIO.getMedal(123);
medal.unlock(function(updatedMedal, newMedalScore) {
	if (updatedMedal.unlocked) {
		trace("Medal unlocked! New total score: " + newMedalScore);
	}
});
```

#### Session Management

**Check if user has an active session:**
```actionscript
if (NGIO.hasSession()) {
	trace("User has a valid session");
}
```

**Check if user is logged in:**
```actionscript
if (NGIO.hasUser()) {
	trace("User is authenticated");
	var user = NGIO.getUser();
	trace("Welcome, " + user.name);
}
```

**Check session status with server:**
```actionscript
import io.newgrounds.SessionStatus;

NGIO.checkSession(function(status) {
	if (status == null) {
		trace("Could not get session status from server");
		return;
	}

	trace("Session Status: " + status.status);

	switch(status.status) {
		case SessionStatus.LOGGED_IN:
			trace("User logged in!");
			trace("  Username: " + status.user.name);
			trace("  Supporter: " + status.user.supporter);
			break;

		case SessionStatus.NOT_LOGGED_IN:
			trace("No user logged in (guest session)");
			trace("Call NGIO.openPassport() to let user log in");
			break;

		case SessionStatus.EXPIRED:
			trace("Session expired - user needs to re-authenticate");
			break;

		case SessionStatus.WAITING_FOR_PASSPORT:
			trace("Login window is open, waiting for user...");
			break;

		case SessionStatus.ERROR:
			trace("Session error: " + status.error.message);
			break;

		default:
			trace("Session status: " + status.status);
	}
});
```

**Monitoring Session Changes:**

You can check the session status repeatedly to monitor for changes. This is useful to pick up when a user logs in through the passport window or when a session expires:

```actionscript
import io.newgrounds.SessionStatus;

var sessionCheckInterval;

function startMonitoringSession() {
	// Check session status every 5 seconds
	sessionCheckInterval = setInterval(function() {
		NGIO.checkSession(onSessionStatusChanged);
	}, 5000);
}

function onSessionStatusChanged(status) {
	switch(status.status) {
		case SessionStatus.LOGGED_IN:
			trace("User just logged in!");
			refreshGameUI();
			clearInterval(sessionCheckInterval);  // Stop polling once logged in
			break;

		case SessionStatus.EXPIRED:
			trace("User session expired");
			showReloginPrompt();
			break;
	}
}
```

**Open login window:**

Call this from a button's `onRelease` handler to let the user authenticate:

```actionscript
// In your button's onRelease handler
loginButton.onRelease = function() {
	// Open passport login window
	NGIO.openPassport("_blank");

	// Start monitoring for login completion
	startPollingForLogin();
};

function startPollingForLogin() {
	var pollInterval = setInterval(function() {
		NGIO.checkSession(function(status) {
			if (status.status == SessionStatus.LOGGED_IN) {
				trace("Login successful!");
				clearInterval(pollInterval);
				refreshGameUI();
			} else if (status.status == SessionStatus.LOGIN_CANCELLED) {
				trace("User cancelled login");
				clearInterval(pollInterval);
			}
		});
	}, 2000);
}
```

**End user session:**
```actionscript
NGIO.endSession(function() {
	trace("User logged out");
});
```

#### Medals

**Get all cached medals (recommended when data already loaded):**
```actionscript
// Quick, synchronous - no callback needed
// Use this after you've already loaded medals with loadAppData()
var medals = NGIO.getMedals();
if (medals != null) {
	for (var i = 0; i < medals.length; i++) {
		var medal = medals[i];
		trace("Medal: " + medal.name + " (Unlocked: " + medal.unlocked + ")");
	}
}
```

**Load medals from server:**
```actionscript
// Use this only if you need to refresh data or haven't loaded yet
NGIO.loadMedals(function(medals, error) {
	if (error == null && medals != null) {
		for (var i = 0; i < medals.length; i++) {
			var medal = medals[i];
			trace("Medal: " + medal.name + " (Value: " + medal.value + ")");
			trace("  Unlocked: " + medal.unlocked);
			trace("  Secret: " + medal.secret);
		}
	} else {
		trace("Failed to load medals: " + error);
	}
});
```

**Get a specific medal by ID (returns cached copy):**
```actionscript
var medal = NGIO.getMedal(123);
if (medal != null) {
	trace("Found medal: " + medal.name);

	// Medal objects have extended methods
	medal.unlock(function(updatedMedal, newMedalScore) {
		if (updatedMedal.unlocked) {
			trace("Medal unlocked! New total score: " + newMedalScore);
		}
	});
}
```

**Get user's total medal score (cached):**
```actionscript
// Quick synchronous access - no callback needed
var score = NGIO.getMedalScore();
trace("Total medal score: " + score);
```

**Load medal score from server:**
```actionscript
// Use only if you need to refresh or haven't loaded yet
NGIO.loadMedalScore(function(score, error) {
	if (error == null) {
		trace("Updated medal score: " + score);
	}
});
```

#### Scoreboards

**Get all cached scoreboards (recommended when data already loaded):**
```actionscript
// Quick, synchronous - no callback needed
var boards = NGIO.getScoreBoards();
if (boards != null) {
	for (var i = 0; i < boards.length; i++) {
		trace("Scoreboard: " + boards[i].name);
	}
}
```

**Load scoreboards from server:**
```actionscript
// Use this only if you need to refresh data or haven't loaded yet
NGIO.loadScoreBoards(function(boards, error) {
	if (error == null && boards != null) {
		for (var i = 0; i < boards.length; i++) {
			trace("Scoreboard: " + boards[i].name + " (ID: " + boards[i].id + ")");
		}
	} else {
		trace("Failed to load scoreboards: " + error);
	}
});
```

**Get a specific scoreboard by ID (returns cached copy):**
```actionscript
var board = NGIO.getScoreBoard(456);
if (board != null) {
	trace("Found scoreboard: " + board.name);

	// ScoreBoard objects have extended methods
	board.getScores(null, function(scores, error) {
		if (error == null) {
			trace("Top scores retrieved: " + scores.length);
		}
	});

	board.postScore(9001, null, function(score, error) {
		if (error == null) {
			trace("Score submitted successfully!");
		} else {
			trace("Failed to post score: " + error);
		}
	});
}
```

#### Cloud Saves

**Get all cached save slots (recommended when data already loaded):**
```actionscript
// Quick, synchronous - no callback needed
var slots = NGIO.getSaveSlots();
if (slots != null) {
	trace("User has " + slots.length + " save slots");
	for (var i = 0; i < slots.length; i++) {
		trace("  Slot " + slots[i].id + ": " + Math.round(slots[i].size) + " bytes");
	}
}
```

**Load save slots from server:**
```actionscript
// Use this only if you need to refresh data or haven't loaded yet
NGIO.loadSaveSlots(function(slots, error) {
	if (error == null && slots != null) {
		trace("User has " + slots.length + " save slots");
		for (var i = 0; i < slots.length; i++) {
			trace("  Slot " + slots[i].id + ": " + Math.round(slots[i].size) + " bytes");
		}
	} else {
		trace("Failed to load save slots: " + error);
	}
});
```

**Get a specific save slot (returns cached copy):**
```actionscript
var slot = NGIO.getSaveSlot(1);
if (slot != null) {
	// SaveSlot objects have extended methods
	slot.loadData(function(data, error) {
		if (error == null) {
			trace("Loaded save data: " + data);
			resumeGame(data);
		} else {
			trace("Failed to load save: " + error);
		}
	});

	// To save data
	var saveData = {level: 5, health: 100, inventory: "key,potion"};
	slot.saveData(saveData, function(error) {
		if (error == null) {
			trace("Save complete!");
		} else {
			trace("Failed to save: " + error);
		}
	});
}
```

#### Version & Host Info

**Check if app is deprecated:**
```actionscript
if (NGIO.getClientDeprecated()) {
	trace("A new version is available!");
	// call NGIO.openOfficialUrl() in a click action to load the new version
}
```

**Check if current domain is approved:**
```actionscript
if (!NGIO.getHostApproved()) {
	trace("This domain is not authorized to run this app");
	// call NGIO.openOfficialUrl() in a click action to load a legal version
}
```

#### Server Utilities

**Get gateway version:**
```actionscript
NGIO.loadGatewayVersion(function(version, error) {
	trace("Gateway: " + version);
});
```

**Get current server time:**
```actionscript
NGIO.loadGatewayDate(function(date, error) {
	trace("Server time: " + date.toString());
});
```

**Test server connectivity:**
```actionscript
NGIO.sendPing(function(pong, error) {
	if (pong == "pong") {
		trace("Server is reachable!");
	}
});
```

**Log custom events:**
```actionscript
NGIO.logEvent("level_completed", function(error) {
	trace("Event logged");
});
```

#### Navigation

**Open URLs:**
```actionscript
// Must be called from a user interaction

NGIO.openOfficialUrl("_blank", true); // load your latest, legal version
NGIO.openAuthorUrl("_blank", true);   // load your personal web page
NGIO.openMoreGames("_blank", true);   // loads the games page on Newgrounds
NGIO.openNewgrounds("_blank", true);  // loads the Newgrounds home page
```

**Open custom referral URL:**
```actionscript
NGIO.openReferral("my_referral_name", "_blank", true);
```

---

## Advanced Use

For advanced users who need direct access to the API, you can interact with the low-level `Core` class through `NGIO.core`.

### Direct Core Access

```actionscript
// Get direct access to the Core instance
var core = NGIO.core;

// Access app state
trace("Current medals: " + core.appState.medals);

// Check if data has been loaded
if (core.appState.hasLoaded('medals')) {
	// Use the cached data
}
```

### Executing Custom Components

You can execute any component directly by creating it and passing it to the core:

```actionscript
// Create a custom component
var component = io.newgrounds.models.objects.ObjectFactory.CreateComponent(
	"User",     // Component module
	"getUser",  // Component name
	null,       // Parameters
	NGIO.core   // Core reference
);

// Execute it
NGIO.core.executeComponent(component, function(response) {
	if (response.error()) {
		trace("Error: " + response.getError().message);
	} else {
		var result = response.getResult();
		trace("User: " + result.user.name);
	}
});
```

### Understanding Response Objects

Every component execution returns a `Response` object that contains either a result or an error:

```actionscript
function onResponse(response) {
	if (response.error()) {
		// Something went wrong
		var error = response.getError();
		trace("Error code: " + error.code);
		trace("Error message: " + error.message);
	} else {
		// Operation succeeded
		var result = response.getResult();

		// Result might be a single object or a list
		if (result.resultList != null) {
			// Process multiple results
			for (var i = 0; i < result.resultList.length; i++) {
				trace(result.resultList[i]);
			}
		} else {
			// Single result object
			trace(result);
		}
	}
}
```

### Queueing Multiple Components

You can queue multiple components to be executed together in a single request:

```actionscript
// Queue first component
var component1 = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Medal", "unlock", {id: 123}, NGIO.core);
NGIO.core.queueComponent(component1);

// Queue second component
var component2 = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Gateway", "ping", null, NGIO.core);
NGIO.core.queueComponent(component2);

// Execute both together
NGIO.core.executeQueue(function(responses) {
	for (var i = 0; i < responses.length; i++) {
		if (!responses[i].error()) {
			trace("Component executed successfully");
		}
	}
});
```

---

## Resources

- Newgrounds.io API Documentation: https://www.newgrounds.io/
- ActionScript 2.0 Reference: https://help.adobe.com/en_US/AS2LCR/Flash_10.0/

---

## License

See LICENSE file for details.
