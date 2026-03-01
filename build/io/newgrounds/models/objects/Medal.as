
/**
 * Medal
 *
 * Contains information about a medal.
 */
import io.newgrounds.BaseObject;
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
	 * @param callback Function to call when the unlock completes
	 * @param thisArg Context to use when calling the callback
	 */
	public function unlock(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		var callbackParams:Object = {
			callback: callback,
			thisArg: thisArg
		};

		// Call Medal.unlock component via core
		if (this.core) this.core.callComponent("Medal.unlock", {id: this.id}, this.onUnlock, this, callbackParams);
	}

	/**
	 * Callback handler for when the medal unlock completes.
	 * @param response The result from the Medal.unlock component call
	 * @param callbackParams The callback parameters stored during unlock()
	 */
	public function onUnlock(response:io.newgrounds.models.objects.Response, callbackParams:Object):Void {

		var result:io.newgrounds.models.results.Medal.unlockResult = null;

		if (response && response.success) {
			result = response.getResult();
		}

		if (response && response.success) {
			this.unlocked = true;
		}

		if (callbackParams.callback != null) {
			callbackParams.callback.call(callbackParams.thisArg, this, result.medal_score);
		}
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
