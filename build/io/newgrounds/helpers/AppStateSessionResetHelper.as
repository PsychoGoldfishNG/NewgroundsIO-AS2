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
		if (appState.session != null && appState.session.hasOwnProperty("clearSessionData")) {
			appState.session.clearSessionData();
		}

		if (appState.saveSlots != null) {
			for (var i:Number = 0; i < appState.saveSlots.length; i++) {
				var saveSlot = appState.saveSlots[i];
				if (saveSlot.hasOwnProperty("clearSessionData")) {
					saveSlot.clearSessionData();
				}
			}
		}

		if (appState.medals != null) {
			for (var j:Number = 0; j < appState.medals.length; j++) {
				var medal = appState.medals[j];
				if (medal.hasOwnProperty("clearSessionData")) {
					medal.clearSessionData();
				}
			}
		}

		appState.medalScore = 0;
		appState.passportIsOpen = false;
	}
}
