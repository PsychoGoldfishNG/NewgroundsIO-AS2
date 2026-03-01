
/**
 * SaveSlot
 *
 * Contains information about a CloudSave slot.
 */
import io.newgrounds.BaseObject;
import io.newgrounds.Errors;
import io.newgrounds.models.objects.Response;
import io.newgrounds.models.objects.NgioError;

class io.newgrounds.models.objects.SaveSlot extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * The slot number.
	 */
	public var id:Number = 0;

	/**
	 * The size of the save data in bytes.
	 */
	public var size:Number = 0;

	/**
	 * A date and time (in ISO 8601 format) representing when this slot was last saved.
	 */
	public var datetime:String = null;

	/**
	 * A unix timestamp representing when this slot was last saved.
	 */
	public var timestamp:Number = 0;

	/**
	 * The URL containing the actual save data for this slot, or null if this slot has no data.
	 */
	public var url:String = null;


	//==================== CONSTRUCTOR ====================

	public function SaveSlot() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "SaveSlot";
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
		return ["id","size","datetime","timestamp","url"];
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

	/**
	 * Checks if this save slot contains any data.
	 * @return True if data exists, false if slot is empty
	 */
	public function hasData():Boolean {
		return this.url != null;
	}

	/**
	 * Clears all data from this save slot.
	 * @param callback Function to call when clearing is complete
	 * @param thisArg Context to use when calling the callback
	 */
	public function clearData(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		var self = this;
		if (this.core) this.core.callComponent("CloudSave.clearSlot", {id: this.id}, function(response:io.newgrounds.models.objects.Response, callbackParams):Void {

			var error:io.newgrounds.models.objects.NgioError = null;

			// request was good, check the result
			if (response && response.success) {

				var result = response.getResult();

				if (!result) {
					error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, "Invalid response format received from CloudSave.clearSlot", true);
				} else if (!result.success) {
					error = result.error;
				}

			} else {
				error = response.error;
			}

			if (callback != null) {
				callback.call(thisArg, error);
			}
		}, this);
	}

	/**
	 * Loads the raw string data from the URL stored on this save slot.
	 * @param callback Function to call with the raw data string or null
	 * @param thisArg Context to use when calling the callback
	 */
	public function loadDataRaw(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;

		// If this is an empty slot, skip the load and just return null data to the callback.
		if (this.url == null || this.url.length == 0) {
			if (callback != null) {
				callback.call(thisArg, null, null);
			}
			return;
		}

		var self = this;

		// the original v3 API did not include the protocol in the URL, so we need to add it if it's missing
		var loadUrl:String = this.url;
		if (loadUrl.indexOf("://") == -1) {
			loadUrl = "https:" + loadUrl;
		}

		var lv:LoadVars = new LoadVars();
		lv.onData = function(src:String):Void {
			if (src != undefined && src != null) {
				self.error = null;
				if (callback != null) {
					callback.call(thisArg, src, null);
				}
			} else {
				self.error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, "Failed to load SaveSlot data from URL", true);
				if (callback != null) {
					callback.call(thisArg, null, self.error);
				}
			}
		};
		lv.load(loadUrl);
	}

	/**
	 * Saves raw string data to this save slot.
	 * @param data The raw string data to save
	 * @param callback Function to call when saving is complete
	 * @param thisArg Context to use when calling the callback
	 */
	public function saveDataRaw(data:String, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (this.core) this.core.callComponent("CloudSave.setData", {id: this.id, data: data}, function(response:io.newgrounds.models.objects.Response, callbackParams):Void {

			var error:io.newgrounds.models.objects.NgioError = null;

			// request was good, check the result
			if (response && response.success) {

				var result = response.getResult();

				if (!result.success) {
					error = result.error;
				}

			} else {
				error = response.error;
			}

			if (callback != null) {
				callback.call(thisArg, error);
			}
		}, this);
	}

	/**
	 * Loads data from this save slot and parses it as JSON.
	 * @param callback Function to call with the decoded object
	 * @param thisArg Context to use when calling the callback
	 */
	public function loadData(callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		var self = this;
		this.loadDataRaw(function(data:String, error):Void {
			var decoded = null;
			if (data != null) {
				try {
					decoded = io.newgrounds.encoders.JSON.decode(data);
				} catch (e) {
					self.error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, "Failed to decode SaveSlot data JSON", true);
					decoded = null;
				}
			}
			if (decoded != null) {
				self.error = null;
			} else if (error != null) {
				self.error = error;
			}
			if (callback != null) {
				callback.call(thisArg, decoded, self.error);
			}
		}, this);
	}

	/**
	 * Encodes data as JSON and saves it to this save slot.
	 * @param data The object to encode and save
	 * @param callback Function to call when saving is complete
	 * @param thisArg Context to use when calling the callback
	 */
	public function saveData(data, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		this.saveDataRaw(io.newgrounds.encoders.JSON.encode(data), callback, thisArg);
	}

	/**
	 * Returns a string representation of this save slot.
	 */
	public function toString():String {
		return (this.id != 0) ? "SaveSlot #" + this.id : "SaveSlot #0";
	}

	/**
	 * Clears session-specific data to return the save slot to its unauthenticated state.
	 * Called by AppState when the user's session expires or is cleared.
	 */
	public function clearSessionData():Void {
		this.datetime = null;
		this.timestamp = 0;
		this.size = 0;
		this.url = null;
	}
}
