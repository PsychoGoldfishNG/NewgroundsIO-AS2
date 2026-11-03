/**
 * LocalStorageHelper
 *
 * Keyed string storage for local data that outlives the SWF: save slot copies,
 * and medal unlocks still waiting on the gateway. Backed by the same "ngio"
 * SharedObject the saved session id uses.
 *
 * A write reports failure rather than throwing. Flash can refuse one: the
 * player may have local storage turned off, or the data may pass the space the
 * player allows. Callers treat a failed write as a failed local copy, not an
 * error.
 */
class io.newgrounds.helpers.LocalStorageHelper {

	/**
	 * Replaces the SharedObject with a store of your own: an object with
	 * getValue(key):String, setValue(key, value):Boolean and
	 * removeValue(key):Boolean. Null, the default, uses the SharedObject. Used
	 * by the offline tests, and by a game that keeps its data elsewhere.
	 */
	public static var store:Object = null;

	/** The stored value, or null if there is none or it can't be read. */
	public static function getValue(key:String):String {
		if (io.newgrounds.helpers.LocalStorageHelper.store != null) {
			return io.newgrounds.helpers.LocalStorageHelper.store.getValue(key);
		}
		try {
			var so:SharedObject = SharedObject.getLocal("ngio");
			if (so.data[key] != undefined && so.data[key] != null) {
				return so.data[key];
			}
		} catch (e) {
		}
		return null;
	}

	/** Stores a value, returning whether it was written. */
	public static function setValue(key:String, value:String):Boolean {
		if (io.newgrounds.helpers.LocalStorageHelper.store != null) {
			return io.newgrounds.helpers.LocalStorageHelper.store.setValue(key, value);
		}
		try {
			var so:SharedObject = SharedObject.getLocal("ngio");
			so.data[key] = value;
			// flush() returns true when written, false when refused, and "pending"
			// when Flash is asking the player for more space. A pending value may
			// still be written if they agree, but nothing is stored yet, so only
			// true counts.
			return so.flush() === true;
		} catch (e) {
		}
		return false;
	}

	/** Removes a value, returning whether that was written. */
	public static function removeValue(key:String):Boolean {
		if (io.newgrounds.helpers.LocalStorageHelper.store != null) {
			return io.newgrounds.helpers.LocalStorageHelper.store.removeValue(key);
		}
		try {
			var so:SharedObject = SharedObject.getLocal("ngio");
			delete so.data[key];
			return so.flush() === true;
		} catch (e) {
		}
		return false;
	}
}
