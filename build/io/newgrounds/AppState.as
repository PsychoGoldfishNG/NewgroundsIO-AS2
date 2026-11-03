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

	/**
	 * The local mirror of this app's save slots. Nothing outside AppState reaches
	 * it: the SaveSlot model goes through readLocalSlotData(), writeLocalSlotData()
	 * and clearLocalSlotData(), which keeps the merge in one place. See SAVE SLOT
	 * LOCAL FALLBACK below.
	 */
	private var localSaveSlots:io.newgrounds.LocalSaveSlotStore;

	/**
	 * How many CloudSave.loadSlots results have been merged. loadData() compares
	 * it before and after, to tell whether a slot list came back. Public only
	 * because loadData()'s closure reads it: AS2 can't see private members from a
	 * nested function.
	 */
	public var slotListsMerged:Number = 0;

	//==================== PUBLIC PROPERTIES ====================

	/**
	 * Flag indicating whether Passport login window is currently open
	 */
	public var passportIsOpen:Boolean = false;

	/**
	 * Whether a save made while nobody was signed in (a guest save) becomes the
	 * local copy of whoever signs in next. When false, guest saves stay
	 * guest-only: a signed-in player never sees them, and they're still there
	 * the next time nobody is signed in. Set through NGIO.setOfferGuestSaves().
	 */
	public var offerGuestSaves:Boolean = true;

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

		// Scoped by App ID for the same reason as the session key. The two
		// counters are set here for the same prototype reason as dataLoaded.
		this.localSaveSlots = new io.newgrounds.LocalSaveSlotStore(core.appId);
		this.slotListsMerged = 0;
		this.offerGuestSaves = true;

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

		// Both result shapes. executeQueue always sends the queue as an execute
		// list, so a response from loadData always carries `resultList` - even
		// for one property. This method is public, though: a caller can hand it
		// a single-component response from executeComponent(), which carries the
		// scalar `result` instead.
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

		var wantsSlots:Boolean = indexOfValue(propertyNames, "saveSlots") != -1;
		var slotListsBefore:Number = this.slotListsMerged;

		var self:io.newgrounds.AppState = this;
		core.executeQueue(function(response):Void {
			// No slot list came back from the gateway: refused without being sent
			// (nobody signed in), or the request never got there. Neither passes
			// through setValueFromResult(), and that's the case the local copies
			// exist for, so merge them here.
			if (wantsSlots && self.slotListsMerged == slotListsBefore) {
				self.mergeWithoutCloudList();
			}

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
	 * True for a result whose request went out for a session that is no longer the
	 * current one: the player signed out, or another session replaced it, while the
	 * request was in flight. The response import skips setValueFromResult() for it.
	 * The caller still receives the result.
	 *
	 * - App.checkSession / App.startSession: writing it in would put the old session
	 *   back, so any change of session counts, including from none.
	 * - Results that describe the signed-in player (medal unlocks, medal score, save
	 *   slots): stale only when sent FOR a session that has since gone. One sent with
	 *   no session describes nobody, so it is still good.
	 *
	 * Compares against the id the request carried, not an id in the result, so it
	 * never depends on what the server echoes back. Unset, null and "" ids are all
	 * treated as "no session", on both sides.
	 */
	public function isStaleSessionResult(resultObject, sentSessionId:String):Boolean {
		if (resultObject == null) {
			return false;
		}

		var currentId:String = (this.session != null) ? this.session.id : null;
		if (currentId == undefined || currentId == "") currentId = null;
		if (sentSessionId == undefined || sentSessionId == "") sentSessionId = null;

		var name:String = resultObject.objectName;
		if (name == "App.checkSession" || name == "App.startSession") {
			return currentId !== sentSessionId;
		}
		if (name == "Medal.getList" || name == "Medal.getMedalScore" || name == "Medal.unlock" ||
			name == "CloudSave.loadSlots" || name == "CloudSave.loadSlot" ||
			name == "CloudSave.setData" || name == "CloudSave.clearSlot") {
			return sentSessionId !== null && currentId !== sentSessionId;
		}
		return false;
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
	 * Same reset as clearSession(); kept separate because the reason differs.
	 * Without it, a rejected session id stays in memory and in storage, so every
	 * later checkSession() re-sends the same dead id and fails the same way.
	 */
	public function invalidateSession():Void {
		this.clearSession();
	}

	/**
	 * Completely clear the current session (used when logging out)
	 *
	 * Resets everything that described the old player, not just the session: the
	 * medals' and save slots' session data, medalScore and passportIsOpen. Otherwise
	 * the next player sees the last one's unlocks, and a sign-out while Passport
	 * was open leaves openPassport() refusing to open it again.
	 */
	public function clearSession():Void {
		// Reset session-scoped state and the session object itself
		io.newgrounds.helpers.AppStateSessionResetHelper.clearSessionScopedData(this);

		// Drop any error left over from the old session, so a freshly started
		// session isn't immediately judged by the old session's failure
		if (this.session != null) {
			this.session.error = null;
		}

		// Also remove the saved session from storage
		// So next time they open the app, they won't be auto-logged-in
		io.newgrounds.helpers.AppStateBootstrapHelper.clearSavedSessionId(this.sessionStorageKey);
	}

	//==================== SAVE SLOT LOCAL FALLBACK ====================
	//
	// A save slot is meant to be stored on the cloud, with a local copy protecting
	// it from network loss and server outages. AppState is already the save slot
	// cache and setValueFromResult() is already the by-id merge point, so choosing
	// between two copies is that same job with one more source.
	//
	// Sync is passive. A fresher local copy is used for display and loading but
	// never pushed on its own; it reaches the cloud on the player's next save, or
	// when the game resolves a conflict with SaveSlot.keepLocal().
	//
	// Local copies belong to whoever wrote them: the signed-in user, or a guest
	// when nobody is signed in. Every read and write goes through the current
	// owner, so one player's local copy never reaches another.

	/**
	 * Who local slot copies currently belong to.
	 *
	 * @return The signed-in user's id, or null for a guest
	 */
	public function getLocalSlotOwner() {
		if (this.session == null || this.session.user == null || this.session.user == undefined) return null;
		return this.session.user.id;
	}

	/**
	 * Merges a CloudSave.loadSlots result's slots into the cache. Called by
	 * AppStateResultUpdateHelper. A rejected call arrives with no slots, which is
	 * the offline or signed-out case the local copies exist for, so it's merged
	 * like any other.
	 */
	public function applySlotListResult(cloudSlots:Array):Void {
		this.slotListsMerged++;
		this.applySlotList(cloudSlots);
	}

	/** Merges a slot list into the cache, against the local copies. */
	private function applySlotList(cloudSlots:Array):Void {
		var reconciled:Array = this.reconcileSaveSlots(cloudSlots);
		// Nothing from either copy. Caching nothing and marking it loaded would
		// make hasLoaded('saveSlots') true for data that never arrived.
		if (reconciled.length == 0) return;

		if (this.saveSlots == null) {
			this.saveSlots = reconciled;
			this.markLoaded("saveSlots");
			return;
		}

		// Update in place, never replace the array: the game may be holding these
		// slots.
		for (var i:Number = 0; i < reconciled.length; i++) {
			var slot = reconciled[i];
			var cached = this.findCachedSlot(slot.id);
			if (cached == null) {
				// An id the cache has never seen. A first list made while offline
				// holds only the local ids, so the cloud's arrive later.
				this.saveSlots.push(slot);
			} else if (cached !== slot) {
				cached.importFromObject(slot);
				// source isn't a schema property, so importFromObject() doesn't
				// carry it across.
				cached.source = slot.source;
			}
		}
		this.saveSlots.sortOn("id", Array.NUMERIC);
	}

	/**
	 * The merge for a loadData() that got no slot list back. The cached slots
	 * stand in for the cloud's: they're the last thing known about the cloud
	 * copies, so an older local copy can't replace a newer cloud one just because
	 * the network is down. A cached slot describing a local copy says nothing
	 * about the cloud, so it's left out. After a sign-out every cached slot is
	 * empty, and the new owner's local copies are listed as they are.
	 *
	 * Public only because loadData()'s closure calls it.
	 */
	public function mergeWithoutCloudList():Void {
		if (this.saveSlots == null) {
			this.applySlotList(null);
			return;
		}
		var known:Array = [];
		for (var i:Number = 0; i < this.saveSlots.length; i++) {
			if (this.saveSlots[i].source != "local") known.push(this.saveSlots[i]);
		}
		this.applySlotList(known);
	}

	private function findCachedSlot(id:Number) {
		if (this.saveSlots == null) return null;
		for (var i:Number = 0; i < this.saveSlots.length; i++) {
			if (this.saveSlots[i] != null && this.saveSlots[i].id == id) return this.saveSlots[i];
		}
		return null;
	}

	/**
	 * Builds the slot list from both copies, newest wins, and records each
	 * decision on the slot's source.
	 */
	private function reconcileSaveSlots(cloudSlots:Array):Array {
		var owner = this.getLocalSlotOwner();
		if (owner !== null && this.offerGuestSaves) this.adoptGuestSaves(owner);
		var registry:Object = this.localSaveSlots.getRegistry(owner);

		var cloudById:Object = {};
		var ids:Array = [];
		var i:Number;
		if (cloudSlots != null && cloudSlots != undefined) {
			for (i = 0; i < cloudSlots.length; i++) {
				var cloudSlot = cloudSlots[i];
				if (cloudSlot == null || cloudSlot == undefined) continue;
				cloudById[String(cloudSlot.id)] = cloudSlot;
				if (indexOfValue(ids, Number(cloudSlot.id)) == -1) ids.push(Number(cloudSlot.id));
			}
		}

		// The full slot id range, not just the ids the cloud returned: a slot
		// saved while offline exists locally and nowhere else.
		for (var key:String in registry) {
			var localId:Number = Number(key);
			if (!isNaN(localId) && localId == Math.floor(localId) && indexOfValue(ids, localId) == -1) {
				ids.push(localId);
			}
		}
		ids.sort(Array.NUMERIC);

		var merged:Array = [];
		for (i = 0; i < ids.length; i++) {
			var id:Number = ids[i];
			var local = registry[String(id)];
			if (local == undefined) local = null;
			var cloud = cloudById[String(id)];
			if (cloud == undefined) cloud = null;
			var chosen = this.chooseSlotCopy(id, cloud, local);
			if (chosen != null) merged.push(chosen);
		}
		return merged;
	}

	/**
	 * Picks the newer of the two copies by ISO 8601 datetime. The cloud wins ties,
	 * since a save that round-tripped is the more complete state, and it wins an
	 * unreadable local datetime too (NaN fails the comparison).
	 *
	 * A newer local copy only wins outright when the cloud slot is empty or
	 * missing. When the cloud holds a save too, either choice loses one of them,
	 * so the slot is marked "conflict" for the game to ask the player. It keeps
	 * the cloud's fields, and loading it returns the local copy until the game
	 * calls keepLocal() or keepCloud().
	 */
	private function chooseSlotCopy(id:Number, cloud, local) {
		if (local == null) {
			if (cloud != null) cloud.source = "cloud";
			return cloud;
		}

		var localTime:Number = io.newgrounds.helpers.DateTimeHelper.parseIso(local.datetime);
		var cloudTime:Number = (cloud != null && cloud.datetime != null && cloud.datetime != undefined)
			? io.newgrounds.helpers.DateTimeHelper.parseIso(cloud.datetime)
			: Number.NEGATIVE_INFINITY;

		if (cloud != null && !(localTime > cloudTime)) {
			cloud.source = "cloud";
			return cloud;
		}

		if (cloud != null && cloud.url != null && cloud.url != undefined && cloud.url != "") {
			cloud.source = "conflict";
			return cloud;
		}

		var built = this.buildLocalSlot(id, local);
		return (built != null) ? built : cloud;
	}

	/**
	 * A slot describing the local copy. It carries no url: there is nothing to
	 * fetch, and inventing one would send loadDataRaw() after a file that doesn't
	 * exist.
	 */
	private function buildLocalSlot(id:Number, entry:Object) {
		var parsed:Number = io.newgrounds.helpers.DateTimeHelper.parseIso(entry.datetime);
		var slot = io.newgrounds.models.objects.ObjectFactory.CreateObject("SaveSlot", {
			id: id,
			size: entry.size,
			datetime: entry.datetime,
			timestamp: isNaN(parsed) ? 0 : Math.floor(parsed / 1000),
			url: null
		}, this.core);
		if (slot == null || slot == undefined) return null;
		slot.source = "local";
		return slot;
	}

	/**
	 * Moves guest copies into the signed-in player's own copies. A guest copy goes
	 * to whoever signs in next, and only to them: once offered it's removed from
	 * the guest copies. It replaces the player's own local copy only if it's
	 * newer. Otherwise it's simply dropped.
	 */
	private function adoptGuestSaves(owner):Void {
		var guestRegistry:Object = this.localSaveSlots.getRegistry(null);
		for (var key:String in guestRegistry) {
			var id:Number = Number(key);
			if (isNaN(id) || id != Math.floor(id)) continue;
			var guest = guestRegistry[key];
			var payload:String = this.localSaveSlots.getPayload(id, null);

			if (payload != null) {
				var own = this.localSaveSlots.getEntry(id, owner);
				var guestIsNewer:Boolean = (own == null)
					|| io.newgrounds.helpers.DateTimeHelper.parseIso(guest.datetime) > io.newgrounds.helpers.DateTimeHelper.parseIso(own.datetime);
				// Keep the guest copy if it can't be moved, rather than losing it.
				if (guestIsNewer && !this.localSaveSlots.writeEntry(id, payload, owner, guest.datetime)) continue;
			}

			this.localSaveSlots.deleteEntry(id, null);
		}
	}

	/** The current owner's local save data for one slot, or null. Used by SaveSlot.loadDataRaw() and keepLocal(). */
	public function readLocalSlotData(id:Number):String {
		return this.localSaveSlots.getPayload(id, this.getLocalSlotOwner());
	}

	/**
	 * The current owner's local copy of one slot, as {size, datetime}, or null if
	 * there is none. Used by SaveSlot.getLocalCopy().
	 */
	public function getLocalSlotEntry(id:Number):Object {
		var entry:Object = this.localSaveSlots.getEntry(id, this.getLocalSlotOwner());
		return (entry == null) ? null : {size: entry.size, datetime: entry.datetime};
	}

	/**
	 * Stores one slot's local copy for the current owner, returning whether it was
	 * written. Used for the local leg of a save, the cache of a cloud load, and
	 * re-stamping a save the cloud accepted.
	 *
	 * @param datetime ISO 8601 stamp for the copy. Optional, defaults to now. Pass
	 *        the cloud's own datetime when caching a cloud load.
	 */
	public function writeLocalSlotData(id:Number, data:String, datetime:String):Boolean {
		if (datetime == undefined) datetime = null;
		return this.localSaveSlots.writeEntry(id, data, this.getLocalSlotOwner(), datetime);
	}

	/** Drops the current owner's local copy of one slot. Used by SaveSlot.clearData() and keepCloud(). */
	public function clearLocalSlotData(id:Number):Boolean {
		return this.localSaveSlots.deleteEntry(id, this.getLocalSlotOwner());
	}
}
