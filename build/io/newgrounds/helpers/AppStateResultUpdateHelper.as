/**
 * AppStateResultUpdateHelper
 *
 * Applies typed API result models into AppState cache fields.
 */
import io.newgrounds.AppState;

class io.newgrounds.helpers.AppStateResultUpdateHelper {

	/**
	 * Applies a single result object to AppState and finalizes session persistence state.
	 */
	public static function applyResult(appState:io.newgrounds.AppState, resultObject):Void {
		var objectName:String = resultObject.objectName || resultObject.component || "";

		applyGatewayResult(appState, objectName, resultObject);
		applySessionResult(appState, objectName, resultObject);
		applyAppVersionResult(appState, objectName, resultObject);
		applyHostLicenseResult(appState, objectName, resultObject);
		applyCloudSaveResult(appState, objectName, resultObject);
		applyMedalResult(appState, objectName, resultObject);
		applyScoreBoardResult(appState, objectName, resultObject);

		appState.finalizeSessionPersistenceState();
	}

	private static function applyGatewayResult(appState:io.newgrounds.AppState, objectName:String, resultObject):Void {
		if (objectName == "Gateway.getVersion") {
			appState.gatewayVersion = resultObject.version;
			appState.markLoaded("gatewayVersion");
		}
	}

	private static function applySessionResult(appState:io.newgrounds.AppState, objectName:String, resultObject):Void {
		if (objectName != "App.checkSession" && objectName != "App.startSession") {
			return;
		}

		if (appState.session == null) {
			appState.session = resultObject.session;
			appState.markLoaded("session");
		} else {
			if (typeof(appState.session.importFromObject) == "function") {
				appState.session.importFromObject(resultObject.session);
			} else {
				for (var key:String in resultObject.session) {
					appState.session[key] = resultObject.session[key];
				}
			}
		}

		appState.session.error = resultObject.error;
		if (appState.session.expired !== true && appState.session.error == null) {
			appState.session.verified = true;
		}
	}

	private static function applyAppVersionResult(appState:io.newgrounds.AppState, objectName:String, resultObject):Void {
		if (objectName == "App.getCurrentVersion") {
			appState.currentVersion = resultObject.current_version;
			appState.clientDeprecated = resultObject.client_deprecated;
			appState.markLoaded("currentVersion");
		}
	}

	private static function applyHostLicenseResult(appState:io.newgrounds.AppState, objectName:String, resultObject):Void {
		if (objectName == "App.getHostLicense") {
			appState.hostApproved = resultObject.host_approved;
			appState.markLoaded("hostApproved");
		}
	}

	private static function applyCloudSaveResult(appState:io.newgrounds.AppState, objectName:String, resultObject):Void {
		if (objectName == "CloudSave.loadSlots") {
			if (appState.saveSlots == null) {
				appState.saveSlots = resultObject.slots;
				appState.markLoaded("saveSlots");
			} else {
				updateCollectionById(appState.saveSlots, resultObject.slots);
			}
			return;
		}

		if (objectName == "CloudSave.setData" || objectName == "CloudSave.clearSlot") {
			if (appState.saveSlots != null) {
				updateSingleById(appState.saveSlots, resultObject.slot);
			}
		}
	}

	private static function applyMedalResult(appState:io.newgrounds.AppState, objectName:String, resultObject):Void {
		if (objectName == "Medal.getList") {
			if (appState.medals == null) {
				appState.medals = resultObject.medals;
				appState.markLoaded("medals");
			} else {
				updateCollectionById(appState.medals, resultObject.medals);
			}
			return;
		}

		if (objectName == "Medal.getMedalScore") {
			appState.medalScore = resultObject.medal_score;
			appState.markLoaded("medalScore");
			return;
		}

		if (objectName == "Medal.unlock") {
			appState.medalScore = resultObject.medal_score;
			appState.markLoaded("medalScore");
			if (appState.medals != null) {
				updateSingleById(appState.medals, resultObject.medal);
			}
		}
	}

	private static function applyScoreBoardResult(appState:io.newgrounds.AppState, objectName:String, resultObject):Void {
		if (objectName == "ScoreBoard.getBoards") {
			if (appState.scoreBoards == null) {
				appState.scoreBoards = resultObject.scoreboards;
				appState.markLoaded("scoreBoards");
			} else {
				updateCollectionById(appState.scoreBoards, resultObject.scoreboards);
			}
		}
	}

	private static function updateCollectionById(existingCollection:Array, incomingCollection:Array):Void {
		for (var i:Number = 0; i < incomingCollection.length; i++) {
			updateSingleById(existingCollection, incomingCollection[i]);
		}
	}

	private static function updateSingleById(existingCollection:Array, incoming):Void {
		for (var i:Number = 0; i < existingCollection.length; i++) {
			var existing = existingCollection[i];
			if (existing.id == incoming.id) {
				if (typeof(existing.importFromObject) == "function") {
					existing.importFromObject(incoming);
				}
			}
		}
	}
}
