/**
 * AppState
 *
 * Stores and manages application state loaded from the server
 *
 * This class acts as a cache and store for all data loaded from the server.
 */
import io.newgrounds.Errors;
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
	/**
	 * Set to true when the local version sent to the server doesn't match the
	 * version in your Newgrounds project. Only meaningful once that project has a
	 * version set in "Version Control" AND core.buildVersion is set; with no
	 * project version configured, leave core.buildVersion null or this can come
	 * back true for a deprecation that isn't real.
	 */
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

		// Assigned here, not just at the declaration. In AS2 a property
		// initialiser lives on the PROTOTYPE until the property is first
		// written on an instance - so every AppState would have pushed
		// markLoaded() names into one array shared by all of them, and a
		// second Core would have started life believing the first one's data
		// was already loaded.
		this.dataLoaded = [];

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

	//==================== PRIVATE HELPERS ====================

	/**
	 * Index of a value in an array, or -1.
	 *
	 * ActionScript 2 has NO Array.indexOf - it was an AS3 addition, and AVM1
	 * returns undefined for it with no error. That is worse than a crash here:
	 * `undefined == -1` is false and `undefined != -1` is true, so every guard
	 * written against it silently inverted. hasLoaded() answered true for data
	 * that had never been loaded, markLoaded() returned early and recorded
	 * nothing, and loadData() accepted property names that do not exist.
	 *
	 * Kept private and named differently from indexOf so nothing can shadow the
	 * real thing on some future player.
	 */
	/**
	 * Every component-level failure in a response, as {component, error} pairs.
	 *
	 * A gateway request has THREE independent layers at which it can fail, and
	 * they mean different things:
	 *
	 *   1. TRANSPORT  no HTTP response arrived at all. Core.onHTTPResponse
	 *                 builds the error; nothing below ever runs.
	 *   2. ENVELOPE   response.success !== true. The request as a whole was
	 *                 rejected - bad app id, malformed body, unparseable reply.
	 *                 No component ran.
	 *   3. COMPONENT  result.success !== true. THIS component failed. Others in
	 *                 the same envelope may have succeeded perfectly well.
	 *
	 * Layer 3 exists because an envelope can carry several components at once,
	 * so "did it work" is not one question - it is one question per component,
	 * and the answer has to say WHERE. That is what this returns.
	 *
	 * Each entry names the component (from the result's objectName, e.g.
	 * "CloudSave.loadSlots") alongside its error, so a partial failure can be
	 * reported precisely rather than as an anonymous "something went wrong".
	 *
	 * PUBLIC because the executeQueue closure in loadData has to reach it - AS2
	 * cannot resolve a private static from inside a nested function.
	 */
	public static function resultErrors(response):Array {
		var found:Array = [];

		if (response == null) {
			return found;
		}

		// Both response shapes. A single component comes back as `result`, a
		// queue of them as `resultList`, and loadData produces either depending
		// on how many property names it was given.
		var list:Array = response.getResultList();

		if (list == null) {
			io.newgrounds.AppState.collectResultError(response.getResult(), found);
			return found;
		}

		for (var i:Number = 0; i < list.length; i++) {
			io.newgrounds.AppState.collectResultError(list[i], found);
		}

		return found;
	}

	/**
	 * Append one result's failure to `found`, if it failed.
	 *
	 * Public for the same reason as resultErrors.
	 */
	public static function collectResultError(result, found:Array):Void {
		var error = io.newgrounds.AppState.resultError(result);

		if (error == null) {
			return;
		}

		// objectName is the component path the result belongs to. A result the
		// factory could not type has none, and is still worth reporting - just
		// without a name.
		var componentName:String = "(unidentified component)";
		if (result != null && result.objectName != undefined && result.objectName != null) {
			componentName = String(result.objectName);
		}

		found.push({ component: componentName, error: error });
	}

	/**
	 * The first component-level failure, or null if every component succeeded.
	 *
	 * What loadData hands its callback. Reporting the first rather than all of
	 * them keeps the (appState, error) signature unchanged; callers wanting the
	 * full picture have two better tools - resultErrors() for the detail, and
	 * hasLoaded() to ask which properties actually arrived, since the ones that
	 * succeeded are still cached.
	 *
	 * Public for the same reason as resultErrors.
	 */
	public static function firstResultError(response) {
		var found:Array = io.newgrounds.AppState.resultErrors(response);
		return (found.length > 0) ? found[0].error : null;
	}

	/**
	 * The error on one result, or null when it succeeded.
	 *
	 * A result that reports success !== true but carries no error still has to
	 * produce something, or the caller is back to a silent failure.
	 *
	 * Public for the same reason as firstResultError.
	 */
	public static function resultError(result) {
		if (result == null || result == undefined) {
			return null;
		}

		if (result.success === true) {
			return null;
		}

		if (result.error != null && result.error != undefined) {
			return result.error;
		}

		return io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
	}

	private static function indexOfValue(list:Array, value):Number {
		if (list == null) {
			return -1;
		}

		for (var i:Number = 0; i < list.length; i++) {
			if (list[i] === value) {
				return i;
			}
		}

		return -1;
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
			if (indexOfValue(io.newgrounds.AppState.dataProperties, propertyName) == -1) {
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
			// A failed load surfaces at either of two levels, and BOTH have to be
			// checked - the same pattern NgioLoaderHelper.loadUrl, Medal.unlock
			// and ScoreBoard.getScores use.
			//
			// Only the response level was checked here. A request can succeed
			// while an individual COMPONENT is refused, and that is the common
			// case rather than an exotic one: ask for saveSlots or medalScore
			// without being logged in and the gateway returns
			//
			//   {"success":true,"result":[{"data":{"success":false,
			//     "error":{"code":110,"message":"User is not logged in."}}}]}
			//
			// - a successful response carrying a refused component. The caller
			// got (appState, null): no data and no reason. A game would read that
			// as "this user has no saves" rather than "this user is not signed
			// in", and NGIO.loadSaveSlots / loadMedalScore / loadAppData all
			// inherit it.
			if (response == null) {
				localError = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
			} else if (response.error != null) {
				localError = response.error;
			} else {
				// Fully qualified: AS2 cannot resolve a static from inside a
				// nested function, and a bare name here would silently be
				// undefined rather than a compile error.
				localError = io.newgrounds.AppState.firstResultError(response);
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
		if (indexOfValue(io.newgrounds.AppState.dataProperties, propertyName) == -1) {
			throw new Error("Unknown property name: " + propertyName);
		}

		return (indexOfValue(dataLoaded, propertyName) != -1);
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
			// Chained, not three independent checks: the first branch is
			// reached precisely when there is no session to interrogate, so
			// falling through to this.session.expired read a property off null -
			// fatal in AS3, silently undefined here. Same shape in both so the
			// libraries stay comparable.
			if (this.session == null || this.session.id == null || this.session.id.length == 0) {
				this.passportIsOpen = false;
			} else if (this.session.expired === true) {
				this.passportIsOpen = false;
			} else if (this.session.user != null) {
				this.passportIsOpen = false;
			}
		}
	}

	//==================== INTERNAL METHODS ====================

	/**
	 * Records that a property has been loaded from the server
	 */
	public function markLoaded(propertyName:String):Void {
		if (indexOfValue(io.newgrounds.AppState.dataProperties, propertyName) == -1) {
			throw new Error("Unknown property name: " + propertyName);
		}

		if (indexOfValue(dataLoaded, propertyName) != -1) {
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
	 * Discard a session the server has rejected (expired or cancelled)
	 *
	 * Stronger than clearSession(): as well as forgetting the saved session id, this
	 * resets the session-scoped caches (medals, save slots, medal score) and lowers
	 * passportIsOpen, because none of that data is valid once the session is gone.
	 *
	 * Without this, a rejected session id stays in memory and in storage, so every
	 * later checkSession() re-sends the same dead id and fails the same way.
	 */
	public function invalidateSession():Void {
		// Reset session-scoped state and the session object itself
		io.newgrounds.helpers.AppStateSessionResetHelper.clearSessionScopedData(this);

		// Drop any error left over from the rejected session, so a freshly started
		// session isn't immediately judged by the old session's failure
		if (this.session != null) {
			this.session.error = null;
		}

		// Forget the saved id so a page reload doesn't restore the dead session
		io.newgrounds.helpers.AppStateBootstrapHelper.clearSavedSessionId(this.sessionStorageKey);
	}

	/**
	 * Completely clear the current session (used when logging out)
	 */
	public function clearSession():Void {
		if (session != null && typeof(session.clearSessionData) == "function") {
			session.clearSessionData();
		}

		io.newgrounds.helpers.AppStateBootstrapHelper.clearSavedSessionId(sessionStorageKey);
	}
}
