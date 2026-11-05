/**
 * MedalUnlockQueue
 *
 * A durable buffer of medal ids whose unlock was requested but never confirmed,
 * and the background pass that retries them.
 *
 * An unlock sent straight to the gateway is lost if the connection drops
 * mid-request or the player closes the game before the answer arrives, and the
 * player has already earned the medal. Ids are recorded before the request goes
 * out, so a crash mid-request still leaves the id behind for the next attempt.
 *
 * Core creates one of these in its constructor. That's what scopes the buffer
 * correctly: the pending set is per App ID and Core is the per-app instance.
 * NGIO drives the retry pass on an interval, the same way it drives keepAlive().
 *
 * Each buffered unlock records the player who earned it (their user id, or null
 * when nobody was signed in), so on a shared computer one player's unlock is
 * never sent for another.
 *
 * Several methods are public only because the request closures reach them
 * through `self`: AS2 can't resolve a private member or an unqualified static
 * from inside a nested function.
 */
import io.newgrounds.Core;
import io.newgrounds.Errors;
import io.newgrounds.MedalUnlockStatus;
import io.newgrounds.encoders.JSON;
import io.newgrounds.helpers.LocalStorageHelper;
import io.newgrounds.models.objects.Response;

class io.newgrounds.MedalUnlockQueue {

	private var core:io.newgrounds.Core;
	private var storageKey:String;

	/**
	 * Ids out on a live request right now, as id -> true. Lets a retry pass skip
	 * anything already in flight instead of sending it twice.
	 */
	public var inFlight:Object;

	/**
	 * Told about every retry pass that sent anything, as {listener, thisArg}.
	 * Public only so retryPending()'s closure can reach it.
	 */
	public var retryListeners:Array;

	/**
	 * Whether an unlock attempted while nobody is signed in is kept and sent
	 * after a later sign-in. When false it is never recorded, and any guest entry
	 * already buffered is dropped instead of sent. Set through
	 * NGIO.setKeepGuestMedalUnlocks().
	 */
	public var keepGuestUnlocks:Boolean;

	/**
	 * Whether guest entries wait for the game to claim or discard them, instead
	 * of going to whoever signs in next. No effect while keepGuestUnlocks is
	 * false. Set through NGIO.setHoldGuestMedalUnlocks().
	 */
	public var holdGuestUnlocks:Boolean;

	public function MedalUnlockQueue(core:io.newgrounds.Core) {
		this.core = core;
		// Scoped by App ID for the same reason the saved session id is: apps on
		// the same host share their local storage.
		this.storageKey = "ngio-pending-medal-unlocks-for-" + core.appId;
		// Set here, not at the declarations: a declared default lives on the
		// prototype, and inFlight and retryListeners are mutated.
		this.inFlight = {};
		this.retryListeners = [];
		this.keepGuestUnlocks = true;
		this.holdGuestUnlocks = false;
	}

	/** Ids currently waiting on the gateway, for any player. */
	public function getPendingIds():Array {
		var entries:Array = this.readEntries();
		var ids:Array = [];
		for (var i:Number = 0; i < entries.length; i++) {
			if (io.newgrounds.MedalUnlockQueue.indexOfValue(ids, entries[i].id) == -1) ids.push(entries[i].id);
		}
		return ids;
	}

	/** Ids recorded while nobody was signed in, and not yet sent or discarded. */
	public function getGuestIds():Array {
		var entries:Array = this.readEntries();
		var ids:Array = [];
		for (var i:Number = 0; i < entries.length; i++) {
			if (entries[i].user === null && io.newgrounds.MedalUnlockQueue.indexOfValue(ids, entries[i].id) == -1) {
				ids.push(entries[i].id);
			}
		}
		return ids;
	}

	/**
	 * Hands guest entries to the signed-in player and sends them. Each is
	 * recorded as that player's before it goes out, so one that can't be sent
	 * yet waits for them like any of their own. Ids with no guest entry are
	 * ignored. With nobody signed in, the callback gets an empty list.
	 *
	 * @param ids Medal ids to claim
	 * @param callback Called as callback(outcomes), the same shape unlock() reports
	 * @param thisArg Context for the callback
	 */
	public function claimGuestUnlocks(ids:Array, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		var user = this.currentUserId();
		var entries:Array = this.readEntries();
		var claimed:Array = [];
		var i:Number;
		var j:Number;
		for (i = 0; i < ids.length; i++) {
			if (typeof(ids[i]) != "number" || io.newgrounds.MedalUnlockQueue.indexOfValue(claimed, ids[i]) != -1) continue;
			for (j = 0; j < entries.length; j++) {
				if (entries[j].id == ids[i] && entries[j].user === null) {
					claimed.push(ids[i]);
					break;
				}
			}
		}

		if (user === null || claimed.length == 0) {
			if (callback != null) callback.call(thisArg, []);
			return;
		}

		var kept:Array = [];
		for (i = 0; i < entries.length; i++) {
			if (entries[i].user !== null || io.newgrounds.MedalUnlockQueue.indexOfValue(claimed, entries[i].id) == -1) {
				kept.push(entries[i]);
			}
		}
		for (i = 0; i < claimed.length; i++) {
			var owned:Boolean = false;
			for (j = 0; j < kept.length; j++) {
				if (kept[j].id == claimed[i] && io.newgrounds.MedalUnlockQueue.sameUser(kept[j].user, user)) {
					owned = true;
					break;
				}
			}
			if (!owned) kept.push({id: claimed[i], user: user});
		}
		this.write(kept);

		var toSend:Array = [];
		for (i = 0; i < claimed.length; i++) {
			if (this.inFlight[claimed[i]] !== true) toSend.push(claimed[i]);
		}
		if (toSend.length == 0) {
			if (callback != null) callback.call(thisArg, []);
			return;
		}
		this.send(toSend, user, callback, thisArg);
	}

	/** Drops guest entries for these ids without sending them. Players' own entries are untouched. */
	public function discardGuestUnlocks(ids:Array):Void {
		var entries:Array = this.readEntries();
		var kept:Array = [];
		for (var i:Number = 0; i < entries.length; i++) {
			if (entries[i].user !== null || io.newgrounds.MedalUnlockQueue.indexOfValue(ids, entries[i].id) == -1) {
				kept.push(entries[i]);
			}
		}
		if (kept.length != entries.length) this.write(kept);
	}

	/**
	 * Unlocks one or more medals, buffering each id before it is sent.
	 *
	 * @param ids Medal ids to unlock
	 * @param callback Called once every id has an answer, as callback(outcomes),
	 *        where each outcome is {id, medal, error, status}. status is a
	 *        MedalUnlockStatus value, and error is null exactly when it's UNLOCKED.
	 * @param thisArg Context for the callback
	 */
	public function unlock(ids:Array, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		var unique:Array = [];
		for (var i:Number = 0; i < ids.length; i++) {
			if (typeof(ids[i]) == "number" && io.newgrounds.MedalUnlockQueue.indexOfValue(unique, ids[i]) == -1) {
				unique.push(ids[i]);
			}
		}
		if (unique.length == 0) {
			if (callback != null) callback.call(thisArg, []);
			return;
		}

		// Buffer BEFORE sending, not after the answer. This is what makes a crash
		// or reload mid-request survivable.
		var user = this.currentUserId();
		if (user !== null || this.keepGuestUnlocks) {
			this.addPending(unique, user);
		}

		this.send(unique, user, callback, thisArg);
	}

	/**
	 * Re-sends what is still buffered for whoever is signed in now: their own
	 * entries and any guest entries, minus anything already in flight. Another
	 * player's entries wait until that player signs in again. With
	 * holdGuestUnlocks on, guest entries wait for claimGuestUnlocks() instead.
	 *
	 * Never throws. A failed pass is exactly the "still can't reach the gateway"
	 * case this exists for, and one bad pass mustn't stop the next.
	 *
	 * @param callback Optional. Called as callback(outcomes) once this pass is
	 *        done, or with an empty list when nothing was waiting. Retry listeners
	 *        hear about the pass too, but only when it sent something.
	 * @param thisArg Context for the callback
	 */
	public function retryPending(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		var pending:Array = [];
		var user = null;
		try {
			var entries:Array = this.readEntries();
			var i:Number;
			if (!this.keepGuestUnlocks) {
				var withoutGuests:Array = [];
				for (i = 0; i < entries.length; i++) {
					if (entries[i].user !== null) withoutGuests.push(entries[i]);
				}
				if (withoutGuests.length != entries.length) {
					entries = withoutGuests;
					this.write(entries);
				}
			}

			user = this.currentUserId();
			for (i = 0; i < entries.length; i++) {
				var entry:Object = entries[i];
				var owner:Boolean = (entry.user === null)
					? !this.holdGuestUnlocks
					: io.newgrounds.MedalUnlockQueue.sameUser(entry.user, user);
				if (owner
					&& io.newgrounds.MedalUnlockQueue.indexOfValue(pending, entry.id) == -1
					&& this.inFlight[entry.id] !== true) {
					pending.push(entry.id);
				}
			}
		} catch (e) {
			// See above: a retry pass never passes a failure on.
			pending = [];
		}

		if (pending.length == 0) {
			if (callback != null) callback.call(thisArg, []);
			return;
		}
		var self = this;
		this.send(pending, user, function(outcomes:Array):Void {
			if (callback != null) callback.call(thisArg, outcomes);
			// A copy, so a listener that removes itself doesn't skip the next one.
			var listeners:Array = self.retryListeners.concat();
			for (var j:Number = 0; j < listeners.length; j++) {
				listeners[j].listener.call(listeners[j].thisArg, outcomes);
			}
		}, null);
	}

	/**
	 * Adds a listener for retry passes: every pass that sent anything, whether
	 * the interval or the game started it, calls listener(outcomes) once all the
	 * answers are in. This is how a game hears that a medal earned offline has
	 * now unlocked. Adding the same listener and thisArg twice does nothing more.
	 */
	public function addRetryListener(listener:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		if (this.retryListenerIndex(listener, thisArg) != -1) return;
		this.retryListeners.push({listener: listener, thisArg: thisArg});
	}

	/** Removes a listener added with the same listener and thisArg. */
	public function removeRetryListener(listener:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		var index:Number = this.retryListenerIndex(listener, thisArg);
		if (index != -1) this.retryListeners.splice(index, 1);
	}

	public function retryListenerIndex(listener:Function, thisArg):Number {
		for (var i:Number = 0; i < this.retryListeners.length; i++) {
			if (this.retryListeners[i].listener === listener && this.retryListeners[i].thisArg === thisArg) return i;
		}
		return -1;
	}

	//==================== INTERNAL ====================

	/** Sends one Medal.unlock per id on behalf of `user`, settling the buffer as each comes back. */
	private function send(ids:Array, user, callback:Function, thisArg):Void {
		var outcomes:Array = [];
		var remaining:Number = ids.length;
		var finish:Function = function(outcome:Object):Void {
			outcomes.push(outcome);
			remaining--;
			if (remaining == 0 && callback != null) callback.call(thisArg, outcomes);
		};

		// One request per id rather than one batch: the gateway rules on each
		// medal separately, and Core's component queue belongs to the game, so a
		// retry pass must never drain it.
		for (var i:Number = 0; i < ids.length; i++) {
			this.sendOne(ids[i], user, finish);
		}
	}

	/**
	 * Sends one id. Its own function so each answer's closure captures its own
	 * id: AS2 variables are function-scoped, so a closure made inside send()'s
	 * loop would share the loop's.
	 */
	private function sendOne(id:Number, user, finish:Function):Void {
		var self = this;
		this.inFlight[id] = true;
		this.core.callComponent("Medal.unlock", {id: id}, function(response, callbackParams):Void {
			delete self.inFlight[id];

			var outcome:Object = self.adjudicate(id, response);
			if (outcome.adjudicated) {
				// The gateway ruled on this medal for this player. Retrying can't
				// change that, so drop it whether the answer was yes or no.
				self.removePending(id, user);
			}
			finish({id: outcome.id, medal: outcome.medal, error: outcome.error, status: self.statusFor(outcome, user)});
		});
	}

	/**
	 * Where an answered attempt left the medal. Ruled on: unlocked or rejected.
	 * Not ruled on: whatever the buffer still holds for it. An entry for the
	 * player it was sent for, or a guest entry (a retry pass sends those for
	 * whoever is signed in), means it will be tried again; a guest entry under
	 * holdGuestUnlocks waits for a claim instead.
	 */
	public function statusFor(outcome:Object, user):String {
		if (outcome.adjudicated) {
			return (outcome.error == null) ? io.newgrounds.MedalUnlockStatus.UNLOCKED : io.newgrounds.MedalUnlockStatus.REJECTED;
		}
		var entries:Array = this.readEntries();
		for (var i:Number = 0; i < entries.length; i++) {
			var entry:Object = entries[i];
			if (entry.id == outcome.id && (entry.user === null || io.newgrounds.MedalUnlockQueue.sameUser(entry.user, user))) {
				if (entry.user === null && (user === null || user === undefined) && this.holdGuestUnlocks) {
					return io.newgrounds.MedalUnlockStatus.HELD;
				}
				return io.newgrounds.MedalUnlockStatus.PENDING;
			}
		}
		return io.newgrounds.MedalUnlockStatus.DROPPED;
	}

	/** The signed-in player's user id, or null when nobody is signed in. */
	public function currentUserId() {
		var appState = this.core.appState;
		if (appState == null || appState.session == null || appState.session.user == null) return null;
		return appState.session.user.id;
	}

	/**
	 * Has the gateway ruled on this specific medal? That, not "did it succeed",
	 * decides whether the id can be dropped.
	 *
	 * @return {id, medal, error, adjudicated}
	 */
	public function adjudicate(id:Number, response):Object {
		// No response, or callComponent's local failure object: nothing reached
		// the gateway, or nothing came back.
		if (!(response instanceof io.newgrounds.models.objects.Response)) {
			var localError = (response != null && response != undefined) ? response.error : null;
			return {id: id, medal: null, error: io.newgrounds.MedalUnlockQueue.asError(localError), adjudicated: false};
		}

		// The request as a whole was rejected before this medal was considered.
		if (response.success !== true) {
			return {id: id, medal: null, error: io.newgrounds.MedalUnlockQueue.asError(response.error), adjudicated: false};
		}

		var result = response.getResult();
		if (result == null || result == undefined) {
			return {id: id, medal: null, error: io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false), adjudicated: false};
		}
		if (result.success === true) {
			return {id: id, medal: result.medal, error: null, adjudicated: true};
		}

		var error = (result.error != null && result.error != undefined)
			? result.error
			: io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
		var code:Number = (typeof(error.code) == "number") ? error.code : io.newgrounds.Errors.UNKNOWN;
		// Error codes meaning the call was blocked on identity before this medal
		// was ever looked at: 102, 104, 110 and 111. Anything else means the
		// gateway looked at this medal and rejected it, 202 (an unknown medal id)
		// above all. That id is dropped and never retried.
		var sessionClass:Boolean = code == io.newgrounds.Errors.MISSING_PARAMETER
			|| code == io.newgrounds.Errors.EXPIRED_SESSION
			|| code == io.newgrounds.Errors.LOGIN_REQUIRED
			|| code == io.newgrounds.Errors.CANCELLED_SESSION;
		return {id: id, medal: null, error: error, adjudicated: !sessionClass};
	}

	public static function asError(error) {
		if (error != null && error != undefined && typeof(error) != "string") return error;
		if (typeof(error) == "string") return io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, error, true);
		return io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
	}

	/**
	 * The stored entries, as {id, user}. A bare number is an entry from before
	 * unlocks recorded their player, and is read as a guest entry.
	 */
	public function readEntries():Array {
		try {
			var raw:String = io.newgrounds.helpers.LocalStorageHelper.getValue(this.storageKey);
			if (raw == null || raw == "") return [];
			var parsed = io.newgrounds.encoders.JSON.decode(raw);
			if (!(parsed instanceof Array)) return [];

			var entries:Array = [];
			for (var i:Number = 0; i < parsed.length; i++) {
				var item = parsed[i];
				if (typeof(item) == "number") {
					entries.push({id: item, user: null});
				} else if (item != null && item != undefined && typeof(item.id) == "number") {
					entries.push({id: item.id, user: (typeof(item.user) == "number") ? item.user : null});
				}
			}
			return entries;
		} catch (e) {
			// Unreadable stored data is treated as absent, not fatal.
		}
		return [];
	}

	public function addPending(ids:Array, user):Void {
		var entries:Array = this.readEntries();
		for (var i:Number = 0; i < ids.length; i++) {
			var found:Boolean = false;
			for (var j:Number = 0; j < entries.length; j++) {
				if (entries[j].id == ids[i] && io.newgrounds.MedalUnlockQueue.sameUser(entries[j].user, user)) {
					found = true;
					break;
				}
			}
			if (!found) entries.push({id: ids[i], user: user});
		}
		this.write(entries);
	}

	/**
	 * Drops `id` for `user`, and any guest entry for it too: a guest unlock sent
	 * after a sign-in is settled for that player.
	 */
	public function removePending(id:Number, user):Void {
		var entries:Array = this.readEntries();
		var kept:Array = [];
		for (var i:Number = 0; i < entries.length; i++) {
			var entry:Object = entries[i];
			if (entry.id != id || (entry.user !== null && !io.newgrounds.MedalUnlockQueue.sameUser(entry.user, user))) {
				kept.push(entry);
			}
		}
		if (kept.length == entries.length) return;
		this.write(kept);
	}

	public function write(entries:Array):Void {
		// Best effort, never fatal: a failed write just means the buffer isn't
		// durable this time.
		try {
			io.newgrounds.helpers.LocalStorageHelper.setValue(this.storageKey, io.newgrounds.encoders.JSON.encode(entries));
		} catch (e) {
		}
	}

	public static function sameUser(a, b):Boolean {
		if (a === null || a === undefined || b === null || b === undefined) {
			return (a === null || a === undefined) && (b === null || b === undefined);
		}
		return a == b;
	}

	/** AS2 has no Array.indexOf. */
	public static function indexOfValue(list:Array, value):Number {
		for (var i:Number = 0; i < list.length; i++) {
			if (list[i] === value) return i;
		}
		return -1;
	}
}
