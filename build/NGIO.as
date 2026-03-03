/**
 * NGIO
 *
 * Static wrapper class that simplifies Newgrounds.io API usage
 *
 * This class provides an easy-to-use interface for developers. Instead of dealing with
 * complex Core objects and component models, developers can call simple static methods like
 * NGIO.unlockMedal() or NGIO.checkSession() and the wrapper handles all the complexity.
 *
 * NAMESPACE: (none - this is intentionally the only non-namespaced class for developer convenience)
 */
import io.newgrounds.helpers.NgioAuthHelper;
import io.newgrounds.helpers.NgioBootstrapHelper;
import io.newgrounds.helpers.NgioEventHelper;
import io.newgrounds.helpers.NgioGatewayHelper;
import io.newgrounds.helpers.NgioLoaderHelper;
import io.newgrounds.Core;
import io.newgrounds.SessionStatus;
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.models.results.App.checkSessionResult;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.User;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.ScoreBoard;
import io.newgrounds.models.objects.SaveSlot;
import io.newgrounds.Errors;

class NGIO {

	//==================== PUBLIC STATIC PROPERTIES ====================

	/**
	 * If using our Connector Component, it will create a global reference
	 * to itself using this variable.
	 */
	public static var connectorComponent:MovieClip = null;

	/**
	 * If using our Medal Popup component, it will create a global reference
	 * to itself using this variable.
	 */
	public static var medalPopup:MovieClip = null;

	/**
	 * If using our ScoreBoard component, it will create a global reference
	 * to itself using this variable.
	 */
	public static var scoreboardComponent:MovieClip = null;

	/**
	 * If using our SaveManager component, it will create a global reference
	 * to itself using this variable.
	 */
	public static var saveManagerComponent:MovieClip = null;

	/**
	 * Adjust the volume value if you want NGIO components to be quieter
	 */
	public static var audio:Object = {
		volume: 100,
		muted: false
	};

	//==================== READ-ONLY STATIC PROPERTIES ====================

	/**
	 * Reference to the Core instance for advanced users needing direct access
	 */
	public static var core:io.newgrounds.Core = null;

	//==================== CONSTANTS ====================

	/**
	 * Prevents flooding the server with repeated session check requests
	 */
	public static var CHECKSESSION_THROTTLE_TIME:Number = 3;

	/**
	 * How often to keep active user sessions alive by "pinging" the server
	 * 300 seconds = 5 minutes
	 */
	public static var KEEP_ALIVE_TIME:Number = 300;

	//==================== PRIVATE STATIC PROPERTIES ====================

	/**
	 * Interval ID that periodically pings the server to keep sessions alive
	 */
	private static var keepAliveInterval:Number = -1;

	//==================== PUBLIC STATIC METHODS ====================

	/**
	 * Sets up the entire Newgrounds.io system. Must be called before using any other methods.
	 *
	 * @param appId Your app's unique identifier from Newgrounds
	 * @param encryptionKey The encryption key from Newgrounds
	 * @param buildVersion Your app's version number in XX.XX.XXXX format (optional)
	 * @param useDebugMode If true, API calls won't actually save to the server (optional)
	 */
	public static function init(appId:String, encryptionKey:String, buildVersion:String, useDebugMode:Boolean):Void {
		if (buildVersion == undefined) buildVersion = null;
		if (useDebugMode == undefined) useDebugMode = false;

		if (core !== null) {
			trace("Warning: NGIO has already been initialized");
			return;
		}

		core = io.newgrounds.helpers.NgioBootstrapHelper.doInitializationSequence(appId, encryptionKey, buildVersion, useDebugMode);
		keepAliveInterval = io.newgrounds.helpers.NgioBootstrapHelper.startKeepAlive(KEEP_ALIVE_TIME, keepAlive);
	}

	/**
	 * Quickly check if we have an active session without contacting the server
	 *
	 * @return true if we have a valid session that hasn't expired, false otherwise
	 */
	public static function hasSession():Boolean {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (core.appState.session == null ||
		    core.appState.session.id == null ||
		    core.appState.session.id.length == 0 ||
		    core.appState.session.expired === true) {
			return false;
		}

		return true;
	}

	/**
	 * Check if we have a logged-in user (authenticated session)
	 *
	 * @return true if user is logged in, false otherwise
	 */
	public static function hasUser():Boolean {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (!hasSession()) {
			return false;
		}

		if (core.appState.session.user == null) {
			return false;
		}

		return true;
	}

	/**
	 * Get the logged-in user object, or null if no user is logged in
	 *
	 * @return A User object containing user info, or null
	 */
	public static function getUser() {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (hasUser()) {
			return core.appState.session.user;
		}

		return null;
	}

	/**
	 * Opens the Newgrounds login window so the user can authenticate
	 *
	 * @param target Browser window target ("_blank" = new tab)
	 * @return true if passport was opened, false if it couldn't be opened
	 */
	public static function openPassport(target:String):Boolean {
		if (target == undefined) target = "_blank";
		return io.newgrounds.helpers.NgioAuthHelper.openPassport(core, target);
	}

	/**
	 * Pings the server to keep the current authenticated session alive
	 */
	public static function keepAlive():Void {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (!hasUser()) {
			return;
		}

		var pingComponent = io.newgrounds.models.objects.ObjectFactory.CreateComponent("Gateway", "ping", null, core);
		if (pingComponent == null) {
			throw new Error("Could not create Gateway.ping component");
		}
		core.executeComponent(pingComponent, null);
	}

	/**
	 * Check the current session status and report back via callback
	 *
	 * @param callback Function to call when done. Receives SessionStatus object
	 * @param thisArg Scope for callback (optional)
	 */
	public static function checkSession(callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioAuthHelper.checkSession(core, callback, thisArg);
	}

	/**
	 * Log the user out and end the session
	 *
	 * @param callback Function to call when logout is complete (optional)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function endSession(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioAuthHelper.endSession(core, callback, thisArg);
	}

	/**
	 * Load metadata about the app from the server
	 *
	 * @param propertyNames Array of property names to load
	 * @param callback Function called when done - receives (error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadAppData(propertyNames:Array, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		var wrappedCallback:Function = null;
		if (callback !== null) {
			wrappedCallback = function(appState, error):Void {
				callback.call(thisArg, error);
			};
		}

		core.appState.loadData(propertyNames, wrappedCallback, null);
	}

	/**
	 * Get the cached gateway version, or null if not yet loaded
	 */
	public static function getGatewayVersion():String {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.gatewayVersion;
	}

	/**
	 * Load the current Newgrounds gateway version from the server
	 *
	 * @param callback Function called with (gatewayVersion, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadGatewayVersion(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['gatewayVersion'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.gatewayVersion, error);
			}
		}, thisArg);
	}

	/**
	 * Get the cached current app version from the server, or null if not loaded
	 */
	public static function getCurrentVersion():String {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.currentVersion;
	}

	/**
	 * Load the current production version from server
	 *
	 * @param callback Function called with (currentVersion, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadCurrentVersion(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['currentVersion'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.currentVersion, error);
			}
		}, thisArg);
	}

	/**
	 * Check if current version differs from server's production version
	 */
	public static function getClientDeprecated():Boolean {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.clientDeprecated;
	}

	/**
	 * Check if the local build version differs from server's production version
	 *
	 * @param callback Function called with (clientDeprecated, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadClientDeprecated(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['currentVersion'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.clientDeprecated, error);
			}
		}, thisArg);
	}

	/**
	 * Check if current domain is approved to run this app
	 */
	public static function getHostApproved():Boolean {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.hostApproved;
	}

	/**
	 * Load host approval status from server
	 *
	 * @param callback Function called with (hostApproved, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadHostApproved(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['hostApproved'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.hostApproved, error);
			}
		}, thisArg);
	}

	/**
	 * Get cached list of medals, or null if not loaded
	 */
	public static function getMedals():Array {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.medals;
	}

	/**
	 * Load list of medals from server
	 *
	 * @param callback Function called with (medals, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadMedals(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['medals'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.medals, error);
			}
		}, thisArg);
	}

	/**
	 * Get cached total medal score, or 0 if not loaded
	 */
	public static function getMedalScore():Number {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.medalScore;
	}

	/**
	 * Load user's total medal score from server
	 *
	 * @param callback Function called with (medalScore, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadMedalScore(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['medalScore'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.medalScore, error);
			}
		}, thisArg);
	}

	/**
	 * Find and return a specific medal by ID
	 *
	 * @param medalId The ID of the medal to find
	 * @return Medal object or null if not found
	 */
	public static function getMedal(medalId:Number) {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (!core.appState.hasLoaded('medals')) {
			trace("WARNING: Medal data not loaded. Call loadMedals() first.");
			return null;
		}

		if (core.appState.medals !== null) {
			for (var i:Number = 0; i < core.appState.medals.length; i++) {
				var medal = core.appState.medals[i];
				if (medal.id == medalId) {
					return medal;
				}
			}
		}

		return null;
	}

	/**
	 * Get cached list of scoreboards, or null if not loaded
	 */
	public static function getScoreBoards():Array {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.scoreBoards;
	}

	/**
	 * Load list of scoreboards from server
	 *
	 * @param callback Function called with (scoreBoards, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadScoreBoards(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['scoreBoards'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.scoreBoards, error);
			}
		}, thisArg);
	}

	/**
	 * Find and return a specific scoreboard by ID
	 *
	 * @param boardId The ID of the scoreboard to find
	 * @return ScoreBoard object or null if not found
	 */
	public static function getScoreBoard(boardId:Number) {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (!core.appState.hasLoaded('scoreBoards')) {
			trace("WARNING: ScoreBoard data not loaded. Call loadScoreBoards() first.");
			return null;
		}

		if (core.appState.scoreBoards !== null) {
			for (var i:Number = 0; i < core.appState.scoreBoards.length; i++) {
				var board = core.appState.scoreBoards[i];
				if (board.id == boardId) {
					return board;
				}
			}
		}

		return null;
	}

	//==================== CLOUD SAVES ====================

	/**
	 * Get cached list of cloud save slots, or null if not loaded
	 */
	public static function getSaveSlots():Array {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		return core.appState.saveSlots;
	}

	/**
	 * Load list of cloud save slots from server
	 *
	 * @param callback Function called with (saveSlots, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadSaveSlots(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (core == null) {
			throw new Error("Core not initialized");
		}

		core.appState.loadData(['saveSlots'], function(appState, error):Void {
			if (callback !== null) {
				callback.call(thisArg, core.appState.saveSlots, error);
			}
		}, thisArg);
	}

	/**
	 * Find and return a specific save slot by ID
	 *
	 * @param slotId The ID of the save slot to find
	 * @return SaveSlot object or null if not found
	 */
	public static function getSaveSlot(slotId:Number) {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (!core.appState.hasLoaded('saveSlots')) {
			trace("WARNING: SaveSlot data not loaded. Call loadSaveSlots() first.");
			return null;
		}

		if (core.appState.saveSlots !== null) {
			for (var i:Number = 0; i < core.appState.saveSlots.length; i++) {
				var saveSlot = core.appState.saveSlots[i];
				if (saveSlot.id == slotId) {
					return saveSlot;
				}
			}
		}

		return null;
	}

	//==================== SERVER UTILITIES & EVENTS ====================

	/**
	 * Get current server time in ISO 8601 format
	 *
	 * @param callback Function called with (dateTime, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadGatewayDateTime(callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioGatewayHelper.loadGatewayDateTime(core, callback, thisArg);
	}

	/**
	 * Get current server time as UNIX timestamp
	 *
	 * @param callback Function called with (timestamp, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadGatewayTimestamp(callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioGatewayHelper.loadGatewayTimestamp(core, callback, thisArg);
	}

	/**
	 * Get current server time as native Date object
	 *
	 * @param callback Function called with (date, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadGatewayDate(callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioGatewayHelper.loadGatewayDate(core, callback, thisArg);
	}

	/**
	 * Send a simple ping to test server connectivity
	 *
	 * @param callback Function called with (pong, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function sendPing(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioGatewayHelper.sendPing(core, callback, thisArg);
	}

	/**
	 * Log a custom event to server for tracking
	 *
	 * @param eventName Name of the event to log
	 * @param callback Function called with (error) - optional
	 * @param thisArg Scope for callback (optional)
	 */
	public static function logEvent(eventName:String, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioEventHelper.logEvent(core, eventName, callback, thisArg);
	}

	//==================== URL NAVIGATION ====================

	/**
	 * Open URL where latest official version can be found in a new browser window
	 *
	 * @param target Browser window target ("_blank" = new tab, optional)
	 * @param logEvent Log this action (optional, default true)
	 */
	public static function openOfficialUrl(target:String, logEvent:Boolean):Void {
		if (target == undefined) target = "_blank";
		if (logEvent == undefined) logEvent = true;
		io.newgrounds.helpers.NgioLoaderHelper.openUrl(core, "loadOfficialUrl", target, logEvent);
	}

	/**
	 * Load URL where latest official version can be found (asynchronously)
	 *
	 * @param logEvent Log this action (optional, default true)
	 * @param callback Function called with (url, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public static function loadOfficialUrl(logEvent:Boolean, callback:Function, thisArg):Void {
		if (logEvent == undefined) logEvent = true;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioLoaderHelper.loadUrl(core, "loadOfficialUrl", logEvent, callback, thisArg);
	}

	/**
	 * Open author's home page URL in a new browser window
	 */
	public static function openAuthorUrl(target:String, logEvent:Boolean):Void {
		if (target == undefined) target = "_blank";
		if (logEvent == undefined) logEvent = true;
		io.newgrounds.helpers.NgioLoaderHelper.openUrl(core, "loadAuthorUrl", target, logEvent);
	}

	/**
	 * Load author's home page URL (asynchronously)
	 */
	public static function loadAuthorUrl(logEvent:Boolean, callback:Function, thisArg):Void {
		if (logEvent == undefined) logEvent = true;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioLoaderHelper.loadUrl(core, "loadAuthorUrl", logEvent, callback, thisArg);
	}

	/**
	 * Open author's "More Games" page URL in a new browser window
	 */
	public static function openMoreGames(target:String, logEvent:Boolean):Void {
		if (target == undefined) target = "_blank";
		if (logEvent == undefined) logEvent = true;
		io.newgrounds.helpers.NgioLoaderHelper.openUrl(core, "loadMoreGames", target, logEvent);
	}

	/**
	 * Load author's "More Games" page URL (asynchronously)
	 */
	public static function loadMoreGames(logEvent:Boolean, callback:Function, thisArg):Void {
		if (logEvent == undefined) logEvent = true;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioLoaderHelper.loadUrl(core, "loadMoreGames", logEvent, callback, thisArg);
	}

	/**
	 * Open Newgrounds.com in a new browser window
	 */
	public static function openNewgrounds(target:String, logEvent:Boolean):Void {
		if (target == undefined) target = "_blank";
		if (logEvent == undefined) logEvent = true;
		io.newgrounds.helpers.NgioLoaderHelper.openUrl(core, "loadNewgrounds", target, logEvent);
	}

	/**
	 * Load Newgrounds.com URL (asynchronously)
	 */
	public static function loadNewgrounds(logEvent:Boolean, callback:Function, thisArg):Void {
		if (logEvent == undefined) logEvent = true;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioLoaderHelper.loadUrl(core, "loadNewgrounds", logEvent, callback, thisArg);
	}

	/**
	 * Open a custom referral URL by name in a new browser window
	 */
	public static function openReferral(referralName:String, target:String, logReferral:Boolean):Void {
		if (target == undefined) target = "_blank";
		if (logReferral == undefined) logReferral = true;
		io.newgrounds.helpers.NgioLoaderHelper.openUrl(core, "loadReferral", target, logReferral, referralName);
	}

	/**
	 * Load a custom referral URL by name (asynchronously)
	 */
	public static function loadReferral(referralName:String, logReferral:Boolean, callback:Function, thisArg):Void {
		if (logReferral == undefined) logReferral = true;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		io.newgrounds.helpers.NgioLoaderHelper.loadUrl(core, "loadReferral", logReferral, callback, thisArg, referralName);
	}
}
