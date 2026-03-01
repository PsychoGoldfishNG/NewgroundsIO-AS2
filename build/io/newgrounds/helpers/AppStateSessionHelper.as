/**
 * AppStateSessionHelper
 *
 * Derives SessionStatus from AppState session fields.
 */
import io.newgrounds.AppState;
import io.newgrounds.Errors;
import io.newgrounds.SessionStatus;

class io.newgrounds.helpers.AppStateSessionHelper {

	/**
	 * Builds a SessionStatus snapshot from current AppState data.
	 */
	public static function getSessionStatus(appState:io.newgrounds.AppState, onSessionCleared:Function):io.newgrounds.SessionStatus {
		if (onSessionCleared == undefined) onSessionCleared = null;
		var sessionStatus:io.newgrounds.SessionStatus = new io.newgrounds.SessionStatus();

		if (appState.session == null || appState.session.id == null || appState.session.id.length == 0) {
			return sessionStatus;
		}

		if (appState.session.expired === true) {
			if (onSessionCleared != null) {
				onSessionCleared.call();
			}
			sessionStatus.status = io.newgrounds.SessionStatus.EXPIRED;
			return sessionStatus;
		}

		if (appState.session.error != null) {
			if (appState.session.error.code == io.newgrounds.Errors.CANCELLED_SESSION) {
				if (onSessionCleared != null) {
					onSessionCleared.call();
				}
				sessionStatus.status = io.newgrounds.SessionStatus.LOGIN_CANCELLED;
			} else {
				sessionStatus.status = io.newgrounds.SessionStatus.ERROR;
				sessionStatus.error = appState.session.error;
			}
			return sessionStatus;
		}

		if (appState.session.user != null) {
			sessionStatus.user = appState.session.user;
			sessionStatus.status = io.newgrounds.SessionStatus.LOGGED_IN;
			return sessionStatus;
		}

		if (appState.session.isPreauthenticated()) {
			sessionStatus.status = io.newgrounds.SessionStatus.SESSION_ID_PROVIDED;
			return sessionStatus;
		}

		if (appState.session.passport_url == null || appState.session.passport_url.length == 0) {
			sessionStatus.status = io.newgrounds.SessionStatus.UNVERIFIED;
			return sessionStatus;
		}

		if (appState.passportIsOpen === true) {
			sessionStatus.status = io.newgrounds.SessionStatus.WAITING_FOR_PASSPORT;
			return sessionStatus;
		}

		sessionStatus.status = io.newgrounds.SessionStatus.NOT_LOGGED_IN;
		return sessionStatus;
	}
}
