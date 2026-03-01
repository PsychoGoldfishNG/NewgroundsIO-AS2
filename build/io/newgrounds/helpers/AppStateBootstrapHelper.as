/**
 * AppStateBootstrapHelper
 *
 * Handles AppState startup concerns: session key generation,
 * session restore/persist helpers, runtime URL parsing, and host resolution.
 */

class io.newgrounds.helpers.AppStateBootstrapHelper {

	/**
	 * Builds the per-app local storage key for saved session IDs.
	 */
	public static function getSessionStorageKey(appId:String):String {
		return "ngio-saved-session-id-for-" + appId;
	}

	/**
	 * Reads a previously saved session ID from local storage.
	 */
	public static function getSavedSessionId(sessionStorageKey:String):String {
		return getFromLocalStorage(sessionStorageKey);
	}

	/**
	 * Persists the current session ID to local storage.
	 */
	public static function saveSessionId(sessionStorageKey:String, sessionId:String):Void {
		saveToLocalStorage(sessionStorageKey, sessionId);
	}

	/**
	 * Clears the persisted session ID from local storage.
	 */
	public static function clearSavedSessionId(sessionStorageKey:String):Void {
		clearFromLocalStorage(sessionStorageKey);
	}

	/**
	 * Extracts ngio_session_id from the FlashVar _root.ngio_session.
	 * In AS2, we use a FlashVar instead of the URL query string.
	 */
	public static function getSessionIdFromUrl():String {
		try {
			var sessionId:String = _root.ngio_session;
			if (sessionId != undefined && sessionId != null && sessionId.length > 0) {
				return sessionId;
			}
		} catch (e) {
		}
		return null;
	}

	/**
	 * Resolves the host/domain currently running the app.
	 */
	public static function resolveHost():String {
		try {
			var lc:LocalConnection = new LocalConnection();
			return lc.domain;
		} catch (e) {
		}
		return "localhost";
	}

	private static function getFromLocalStorage(key:String):String {
		try {
			var so:SharedObject = SharedObject.getLocal("ngio");
			if (so.data.hasOwnProperty(key)) {
				return so.data[key];
			}
		} catch (e) {
		}
		return null;
	}

	private static function saveToLocalStorage(key:String, value:String):Void {
		try {
			var so:SharedObject = SharedObject.getLocal("ngio");
			so.data[key] = value;
			so.flush();
		} catch (e) {
		}
	}

	private static function clearFromLocalStorage(key:String):Void {
		try {
			var so:SharedObject = SharedObject.getLocal("ngio");
			delete so.data[key];
			so.flush();
		} catch (e) {
		}
	}
}
