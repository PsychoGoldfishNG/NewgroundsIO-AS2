/**
 * AppState
 *
 * Stores and manages application state loaded from the server
 *
 * This class acts as a cache and store for all data loaded from the server.
 */
import io.newgrounds.helpers.AppStateBootstrapHelper;
import io.newgrounds.helpers.AppStateComponentHelper;
import io.newgrounds.helpers.AppStateResultUpdateHelper;
import io.newgrounds.helpers.AppStateSessionResetHelper;
import io.newgrounds.helpers.AppStateSessionHelper;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.ScoreBoard;
import io.newgrounds.models.objects.SaveSlot;

class io.newgrounds.AppState {

	//==================== STATIC READONLY PROPERTIES ====================

	/**
	 * List of all app state properties that can be loaded from the server
	 */
	public static var dataProperties:Array = [
		'gatewayVersion',
		'currentVersion',
		'hostApproved',
		'saveSlots',
		'scoreBoards',
		'medals',
		'medalScore'
	];

	//==================== PRIVATE PROPERTIES ====================

	/**
	 * Tracks which properties have been loaded from the server
	 */
	private var dataLoaded:Array = [];

	/**
	 * Reference to the Core instance
	 */
	private var core:io.newgrounds.Core;

	//==================== PUBLIC PROPERTIES ====================

	/**
	 * Flag indicating whether Passport login window is currently open
	 */
	public var passportIsOpen:Boolean = false;

	public var host:String = "N/A";
	public var sessionStorageKey:String = null;
	public var session:io.newgrounds.models.objects.Session = null;
	public var gatewayVersion:String = null;
	public var currentVersion:String = null;
	public var clientDeprecated:Boolean = false;
	public var hostApproved:Boolean = true;
	public var saveSlots:Array = null;
	public var scoreBoards:Array = null;
	public var medals:Array = null;
	public var medalScore:Number = 0;

	//==================== CONSTRUCTOR ====================

	/**
	 * Initialize AppState and attempt to restore previous session if available
	 *
	 * @param core The Core instance this AppState is tied to
	 */
	public function AppState(core:io.newgrounds.Core) {
		this.core = core;

		this.session = new io.newgrounds.models.objects.Session();
		this.session.id = null;

		this.sessionStorageKey = io.newgrounds.helpers.AppStateBootstrapHelper.getSessionStorageKey(core.appId);

		var savedSessionId:String = io.newgrounds.helpers.AppStateBootstrapHelper.getSavedSessionId(this.sessionStorageKey);

		if (savedSessionId != null && savedSessionId.length > 0) {
			this.session.id = savedSessionId;
		} else {
			var sessionIdFromURL:String = io.newgrounds.helpers.AppStateBootstrapHelper.getSessionIdFromUrl();

			if (sessionIdFromURL != null && sessionIdFromURL.length > 0) {
				this.session.preauthenticatedId = sessionIdFromURL;
				this.session.id = sessionIdFromURL;
			}
		}

		this.host = io.newgrounds.helpers.AppStateBootstrapHelper.resolveHost();
	}

	//==================== PUBLIC METHODS ====================

	/**
	 * Bulk-load app data from the server (medals, scoreboards, versions, etc.)
	 *
	 * @param propertyNames Array of property names to load
	 * @param callback Function called when done - receives (appState, error)
	 * @param thisArg Scope for callback (optional)
	 */
	public function loadData(propertyNames:Array, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;

		if (propertyNames == null || propertyNames.length == 0) {
			throw new Error("propertyNames array is empty");
		}

		for (var i:Number = 0; i < propertyNames.length; i++) {
			var propertyName:String = propertyNames[i];
			if (io.newgrounds.AppState.dataProperties.indexOf(propertyName) == -1) {
				throw new Error("Unknown property name: " + propertyName);
			}
		}

		var components:Array = io.newgrounds.helpers.AppStateComponentHelper.buildComponentsForProperties(propertyNames, this.core, this.host);
		for (var j:Number = 0; j < components.length; j++) {
			core.queueComponent(components[j]);
		}

		var localError = null;

		var self:io.newgrounds.AppState = this;
		core.executeQueue(function(response):Void {
			if (response != null && response.error != null) {
				localError = response.error;
			}

			if (callback != null) {
				callback.call(thisArg, self, localError);
			}
		}, thisArg);
	}

	/**
	 * Check whether a specific property has been loaded from the server
	 *
	 * @param propertyName Property to check
	 * @return true if property has been loaded, false otherwise
	 */
	public function hasLoaded(propertyName:String):Boolean {
		if (io.newgrounds.AppState.dataProperties.indexOf(propertyName) == -1) {
			throw new Error("Unknown property name: " + propertyName);
		}

		return (dataLoaded.indexOf(propertyName) != -1);
	}

	/**
	 * Analyze the current session state and return a SessionStatus object
	 */
	public function getSessionStatus():io.newgrounds.SessionStatus {
		return io.newgrounds.helpers.AppStateSessionHelper.getSessionStatus(this, this.onSessionCleared);
	}

	/**
	 * Updates app state properties from server result values
	 */
	public function setValueFromResult(resultObject):Void {
		io.newgrounds.helpers.AppStateResultUpdateHelper.applyResult(this, resultObject);
	}

	/**
	 * Finalizes session persistence and passport-open state after result updates.
	 */
	public function finalizeSessionPersistenceState():Void {
		if (this.session != null && this.session.remember === true) {
			io.newgrounds.helpers.AppStateBootstrapHelper.saveSessionId(this.sessionStorageKey, this.session.id);
		}

		if (this.passportIsOpen === true) {
			if (this.session == null || this.session.id == null || this.session.id.length == 0) {
				this.passportIsOpen = false;
			}
			if (this.session.expired === true) {
				this.passportIsOpen = false;
			}
			if (this.session.user != null) {
				this.passportIsOpen = false;
			}
		}
	}

	//==================== INTERNAL METHODS ====================

	/**
	 * Records that a property has been loaded from the server
	 */
	public function markLoaded(propertyName:String):Void {
		if (io.newgrounds.AppState.dataProperties.indexOf(propertyName) == -1) {
			throw new Error("Unknown property name: " + propertyName);
		}

		if (dataLoaded.indexOf(propertyName) != -1) {
			return;
		}

		dataLoaded.push(propertyName);
	}

	/**
	 * Clears session-specific data from all affected objects
	 */
	private function onSessionCleared():Void {
		io.newgrounds.helpers.AppStateSessionResetHelper.clearSessionScopedData(this);
	}

	/**
	 * Completely clear the current session (used when logging out)
	 */
	public function clearSession():Void {
		if (session != null && session.hasOwnProperty("clearSessionData")) {
			session.clearSessionData();
		}

		io.newgrounds.helpers.AppStateBootstrapHelper.clearSavedSessionId(sessionStorageKey);
	}
}
