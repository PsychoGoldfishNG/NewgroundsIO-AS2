
/**
 * Medal
 *
 * Contains information about a medal.
 */
import io.newgrounds.BaseObject;
import io.newgrounds.Errors;
import io.newgrounds.models.objects.Response;
import io.newgrounds.models.results.Medal.unlockResult;

class io.newgrounds.models.objects.Medal extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * The numeric ID of the medal.
	 */
	public var id:Number = 0;

	/**
	 * The name of the medal.
	 */
	public var name:String = null;

	/**
	 * A short description of the medal.
	 */
	public var description:String = null;

	/**
	 * The URL for the medal's icon (typically a webp file).
	 */
	public var icon:String = null;

	/**
	 * The medal's point value.
	 */
	public var value:Number = 0;

	/**
	 * The difficulty id of the medal: 1 = easy, 2 = moderate, 3 = challenging, 4 = difficult, 5 = brutal.
	 */
	public var difficulty:Number = 0;

	/**
	 * 
	 */
	public var secret:Boolean = false;

	/**
	 * This will only be set if a valid session_id exists in the request object.
	 */
	public var unlocked:Boolean = false;


	//==================== CONSTRUCTOR ====================

	public function Medal() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Medal";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "object";
	}

	/**
	 * All property names for this object
	 */
	public function get propertyNames():Array {
		return ["id","name","description","icon","value","difficulty","secret","unlocked"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return [];
	}

	/**
	 * Type casting map for deserializing properties
	 */
	public function get castTypes():Object {
		return {
		};
	}

	//==================== CUSTOM METHODS ====================

	// ===================== OVERRIDE METHODS =========================

	/**
	 * Unlocks this medal for the current user.
	 *
	 * The request goes through Core's medal unlock queue, which records the id
	 * before sending and keeps it until the gateway rules on it. A connection
	 * that drops mid-request, or a game closed before the answer arrives, is
	 * retried in the background rather than losing a medal the player already
	 * earned. See MedalUnlockQueue.
	 *
	 * @param callback Function to call when the unlock completes, as callback(medal, error)
	 *                 where error is null on success. medal is always this medal, so error
	 *                 is the only reliable success signal. Read the updated point total from
	 *                 NGIO.getMedalScore() - AppState updates it from the same result.
	 * @param thisArg Context to use when calling the callback
	 * @throws Error if this medal was loaded from another app
	 */
	public function unlock(callback:Function, thisArg):Void {
		this.assertNotForeign("unlock()", "The gateway would reject this medal id against this app.");

		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		if (this.core == null || this.core == undefined) {
			if (callback != null) {
				callback.call(thisArg, this, io.newgrounds.Errors.getError(io.newgrounds.Errors.UNKNOWN, "This medal has no core, so it cannot be unlocked.", false));
			}
			return;
		}

		// Untyped, so the closure below can reach currentSessionId(): AS2 can't
		// resolve a private member from inside a nested function otherwise.
		var self = this;
		// The session this unlock is for. If the player signs out before the
		// answer arrives, the flag would describe them, not whoever is playing now.
		var sentSessionId:String = this.currentSessionId();

		// Deliberately not skipped when `unlocked` is already true: always ask the
		// server, so the callback behaves the same every time.
		this.core.medalUnlockQueue.unlock([this.id], function(outcomes:Array):Void {
			var outcome = (outcomes.length > 0) ? outcomes[0] : null;
			var error = (outcome == null)
				? io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false)
				: outcome.error;

			// Only mark this unlocked if the server actually accepted it. Setting it on any
			// response would leave the medal permanently showing as earned after a failure.
			// And only if the session it was sent for is still the current one.
			if (error == null && self.currentSessionId() === sentSessionId) {
				self.unlocked = true;
			}

			if (callback != null) {
				callback.call(thisArg, self, error);
			}
		}, null);
	}

	/**
	 * The current session id, or null with no session or no core. Unset and empty
	 * both come back as null, so two of them always compare equal.
	 */
	private function currentSessionId():String {
		if (this.core == null || this.core.appState == null || this.core.appState.session == null) return null;
		var id:String = this.core.appState.session.id;
		return (id == undefined || id == "") ? null : id;
	}

	/**
	 * Returns a string representation of this medal.
	 */
	public function toString():String {
		var description:String = "Medal #";
		description += (this.id != 0) ? this.id : "0";
		description += " - ";
		description += (this.name != null && this.name.length > 0) ? this.name : "null";
		return description;
	}

	/**
	 * Clears session-specific data to return the medal to its unauthenticated state.
	 * Called by AppState when the user's session expires or is cleared.
	 */
	public function clearSessionData():Void {
		this.unlocked = false;
	}
}
