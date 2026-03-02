/**
 * AppStateSessionResetHelper
 *
 * Clears session-scoped data from AppState-owned objects when session is invalidated.
 */
import io.newgrounds.AppState;

class io.newgrounds.helpers.AppStateSessionResetHelper {

	/**
	 * Clears session-specific fields from session/save slot/medal state.
	 */
	public static function clearSessionScopedData(appState:io.newgrounds.AppState):Void {
		if (appState.session != null && typeof(appState.session.clearSessionData) == "function") {
			appState.session.clearSessionData();
		}

		if (appState.saveSlots != null) {
			for (var i:Number = 0; i < appState.saveSlots.length; i++) {
				var saveSlot = appState.saveSlots[i];
				if (typeof(saveSlot.clearSessionData) == "function") {
					saveSlot.clearSessionData();
				}
			}
		}

		if (appState.medals != null) {
			for (var j:Number = 0; j < appState.medals.length; j++) {
				var medal = appState.medals[j];
				if (typeof(medal.clearSessionData) == "function") {
					medal.clearSessionData();
				}
			}
		}

		appState.medalScore = 0;
		appState.passportIsOpen = false;
	}
}
