/**
 * NgioAuthHelper
 *
 * Handles NGIO session/authentication orchestration against App.* endpoints.
 */
import io.newgrounds.Core;
import io.newgrounds.Errors;
import io.newgrounds.SessionStatus;
import io.newgrounds.models.objects.ObjectFactory;
import io.newgrounds.models.results.App.checkSessionResult;

class io.newgrounds.helpers.NgioAuthHelper {

	private static var CHECKSESSION_THROTTLE_TIME:Number = 3;
	private static var lastCheckSessionTime:Date = null;

	/**
	 * Opens the Newgrounds login window so the user can authenticate.
	 *
	 * @param core The active NGIO core instance
	 * @param target Browser window target ("_blank" = new tab)
	 * @return true if passport was opened, false if it couldn't be opened
	 */
	public static function openPassport(core:io.newgrounds.Core, target:String):Boolean {
		if (target == undefined) target = "_blank";
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (core.appState.session == null ||
			core.appState.session.id == null ||
			core.appState.session.id.length == 0 ||
			core.appState.session.expired === true ||
			core.appState.session.user != null) {
			trace("WARNING: Cannot open passport - " + ((core.appState.session == null || core.appState.session.id == null || core.appState.session.id.length == 0 || core.appState.session.expired === true) ? "no session" : "user already logged in"));
			return false;
		}

		if (core.appState.passportIsOpen === true) {
			trace("WARNING: Cannot open passport - passport window already open");
			return false;
		}

		if (core.appState.session.passport_url == null || core.appState.session.passport_url.length == 0) {
			trace("WARNING: Cannot open passport - no passport URL available (call checkSession first)");
			return false;
		}

		try {
			getURL(core.appState.session.passport_url, target);
			core.appState.passportIsOpen = true;
		} catch (e) {
			trace("ERROR: Failed to open passport URL - " + e);
			return false;
		}

		return true;
	}

	/**
	 * Checks session state, performing startSession/checkSession as needed.
	 */
	public static function checkSession(core:io.newgrounds.Core, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		if (core == null) {
			throw new Error("Core not initialized");
		}

		var callCallback:Function = function(status:io.newgrounds.SessionStatus):Void {
			if (callback !== null) {
				callback.call(thisArg, status);
			}
		};

		var sessionStatus:io.newgrounds.SessionStatus = new io.newgrounds.SessionStatus();

		if (hasUser(core)) {
			sessionStatus.status = io.newgrounds.SessionStatus.LOGGED_IN;
			sessionStatus.user = core.appState.session.user;
			callCallback(sessionStatus);
			return;
		}

		if (lastCheckSessionTime !== null) {
			var timeSinceLastCheck:Number = (new Date().getTime() - lastCheckSessionTime.getTime()) / 1000;
			if (timeSinceLastCheck < CHECKSESSION_THROTTLE_TIME) {
				if (core.appState.passportIsOpen === true) {
					sessionStatus.status = io.newgrounds.SessionStatus.WAITING_FOR_PASSPORT;
				} else if (core.appState.session.verified !== true) {
					sessionStatus.status = io.newgrounds.SessionStatus.UNVERIFIED;
				} else {
					sessionStatus.status = io.newgrounds.SessionStatus.NOT_LOGGED_IN;
				}
				callCallback(sessionStatus);
				return;
			}
		}

		lastCheckSessionTime = new Date();

		if (!hasSession(core)) {
			var startSessionComponent = io.newgrounds.models.objects.ObjectFactory.CreateComponent("App", "startSession", null, core);
			if (startSessionComponent == null) {
				throw new Error("Could not create App.startSession component");
			}
			core.executeComponent(startSessionComponent, function(response):Void {

				if (!response || response.success !== true) {
					sessionStatus.status = io.newgrounds.SessionStatus.ERROR;
					sessionStatus.error = (response && response.error) ? response.error : io.newgrounds.Errors.getError();
					callCallback(sessionStatus);
					return;
				}

				var result = response.getResult();

				if (result !== null && result.success === true) {
					sessionStatus.status = io.newgrounds.SessionStatus.NOT_LOGGED_IN;
				} else if (result !== null && result.error !== null) {
					sessionStatus.status = io.newgrounds.SessionStatus.ERROR;
					sessionStatus.error = result.error;
				} else {
					sessionStatus.error = io.newgrounds.Errors.getError();
					sessionStatus.status = io.newgrounds.SessionStatus.ERROR;
				}
				callCallback(sessionStatus);
			});
			return;
		}

		var checkSessionComponent = io.newgrounds.models.objects.ObjectFactory.CreateComponent("App", "checkSession", null, core);
		if (checkSessionComponent == null) {
			throw new Error("Could not create App.checkSession component");
		}
		core.executeComponent(checkSessionComponent, function(response):Void {
			var result = null;

			if (response !== null && response.success === true) {
				result = response.getResult();

				if (result !== null && result.success === true) {
					if (core.appState.session.user !== null) {
						sessionStatus.status = io.newgrounds.SessionStatus.LOGGED_IN;
						sessionStatus.user = core.appState.session.user;
					} else if (core.appState.passportIsOpen === true) {
						sessionStatus.status = io.newgrounds.SessionStatus.WAITING_FOR_PASSPORT;
					} else {
						sessionStatus.status = io.newgrounds.SessionStatus.NOT_LOGGED_IN;
					}
				} else if (result !== null && result.error !== null) {
					if (result.error.code == io.newgrounds.Errors.CANCELLED_SESSION) {
						sessionStatus.status = io.newgrounds.SessionStatus.LOGIN_CANCELLED;
					} else {
						sessionStatus.status = io.newgrounds.SessionStatus.ERROR;
						sessionStatus.error = result.error;
					}
				} else {
					sessionStatus.error = io.newgrounds.Errors.getError();
				}
			} else {
				sessionStatus.status = io.newgrounds.SessionStatus.ERROR;
				if (result !== null && result.error !== null) {
					sessionStatus.error = result.error;
				} else {
					sessionStatus.error = io.newgrounds.Errors.getError();
				}
			}

			callCallback(sessionStatus);
		});
	}

	/**
	 * Ends the current session and clears local session state.
	 */
	public static function endSession(core:io.newgrounds.Core, callback:Function, thisArg):Void {
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (!hasSession(core)) {
			if (callback !== null) {
				callback.call(thisArg);
			}
			return;
		}

		var endSessionComponent = io.newgrounds.models.objects.ObjectFactory.CreateComponent("App", "endSession", null, core);
		if (endSessionComponent == null) {
			throw new Error("Could not create App.endSession component");
		}
		core.executeComponent(endSessionComponent, function(result):Void {
			if (callback !== null) {
				callback.call(thisArg);
			}
		});

		core.appState.clearSession();
	}

	private static function hasSession(core:io.newgrounds.Core):Boolean {
		if (core.appState.session == null ||
			core.appState.session.id == null ||
			core.appState.session.id.length == 0 ||
			core.appState.session.expired === true) {
			return false;
		}
		return true;
	}

	private static function hasUser(core:io.newgrounds.Core):Boolean {
		return hasSession(core) && core.appState.session.user != null;
	}
}
