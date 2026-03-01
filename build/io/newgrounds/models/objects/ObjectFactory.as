import io.newgrounds.BaseObject;
import io.newgrounds.BaseComponent;
import io.newgrounds.BaseResult;
import io.newgrounds.Core;

// Import all object models
import io.newgrounds.models.objects.Request;
import io.newgrounds.models.objects.Execute;
import io.newgrounds.models.objects.Debug;
import io.newgrounds.models.objects.Response;
import io.newgrounds.models.objects.NgioError;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.User;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.ScoreBoard;
import io.newgrounds.models.objects.Score;
import io.newgrounds.models.objects.SaveSlot;

// Import all component models
import io.newgrounds.models.components.App.logView;
import io.newgrounds.models.components.App.checkSession;
import io.newgrounds.models.components.App.getHostLicense;
import io.newgrounds.models.components.App.getCurrentVersion;
import io.newgrounds.models.components.App.startSession;
import io.newgrounds.models.components.App.endSession;
import io.newgrounds.models.components.CloudSave.clearSlot;
import io.newgrounds.models.components.CloudSave.loadSlot;
import io.newgrounds.models.components.CloudSave.loadSlots;
import io.newgrounds.models.components.CloudSave.setData;
import io.newgrounds.models.components.Event.logEvent;
import io.newgrounds.models.components.Gateway.getVersion;
import io.newgrounds.models.components.Gateway.getDatetime;
import io.newgrounds.models.components.Gateway.ping;
import io.newgrounds.models.components.Loader.loadOfficialUrl;
import io.newgrounds.models.components.Loader.loadAuthorUrl;
import io.newgrounds.models.components.Loader.loadReferral;
import io.newgrounds.models.components.Loader.loadMoreGames;
import io.newgrounds.models.components.Loader.loadNewgrounds;
import io.newgrounds.models.components.Medal.getList;
import io.newgrounds.models.components.Medal.getMedalScore;
import io.newgrounds.models.components.Medal.unlock;
import io.newgrounds.models.components.ScoreBoard.getBoards;
import io.newgrounds.models.components.ScoreBoard.postScore;
import io.newgrounds.models.components.ScoreBoard.getScores;

// Import all result models
import io.newgrounds.models.results.App.logViewResult;
import io.newgrounds.models.results.App.checkSessionResult;
import io.newgrounds.models.results.App.getHostLicenseResult;
import io.newgrounds.models.results.App.getCurrentVersionResult;
import io.newgrounds.models.results.App.startSessionResult;
import io.newgrounds.models.results.App.endSessionResult;
import io.newgrounds.models.results.CloudSave.clearSlotResult;
import io.newgrounds.models.results.CloudSave.loadSlotResult;
import io.newgrounds.models.results.CloudSave.loadSlotsResult;
import io.newgrounds.models.results.CloudSave.setDataResult;
import io.newgrounds.models.results.Event.logEventResult;
import io.newgrounds.models.results.Gateway.getVersionResult;
import io.newgrounds.models.results.Gateway.getDatetimeResult;
import io.newgrounds.models.results.Gateway.pingResult;
import io.newgrounds.models.results.Loader.loadOfficialUrlResult;
import io.newgrounds.models.results.Loader.loadAuthorUrlResult;
import io.newgrounds.models.results.Loader.loadReferralResult;
import io.newgrounds.models.results.Loader.loadMoreGamesResult;
import io.newgrounds.models.results.Loader.loadNewgroundsResult;
import io.newgrounds.models.results.Medal.getListResult;
import io.newgrounds.models.results.Medal.getMedalScoreResult;
import io.newgrounds.models.results.Medal.unlockResult;
import io.newgrounds.models.results.ScoreBoard.getBoardsResult;
import io.newgrounds.models.results.ScoreBoard.postScoreResult;
import io.newgrounds.models.results.ScoreBoard.getScoresResult;

/**
 * Factory class for creating Newgrounds.io object instances by name.
 * This allows dynamic instantiation based on string identifiers from the API.
 */
class io.newgrounds.models.objects.ObjectFactory {

	/**
	 * Creates an instance of a core object model (Medal, User, Score, etc.)
	 * @param name The object type name (case-insensitive)
	 * @param objectData Properties to initialize the object with
	 * @param coreReference Core instance to assign to the object (optional)
	 * @return An instance of the requested object, or null if not found
	 */
	public static function CreateObject(name:String, objectData:Object, coreReference:io.newgrounds.Core):io.newgrounds.BaseObject {
		if (objectData == undefined) objectData = null;
		if (coreReference == undefined) coreReference = null;
		if (!name) return null;

		var obj:io.newgrounds.BaseObject = null;

		switch(name.toLowerCase()) {
			case "request":
				obj = new io.newgrounds.models.objects.Request();
				break;

			case "execute":
				obj = new io.newgrounds.models.objects.Execute();
				break;

			case "debug":
				obj = new io.newgrounds.models.objects.Debug();
				break;

			case "response":
				obj = new io.newgrounds.models.objects.Response();
				break;

			case "error":
				obj = new io.newgrounds.models.objects.NgioError();
				break;

			case "session":
				obj = new io.newgrounds.models.objects.Session();
				break;

			case "user":
				obj = new io.newgrounds.models.objects.User();
				break;

			case "medal":
				obj = new io.newgrounds.models.objects.Medal();
				break;

			case "scoreboard":
				obj = new io.newgrounds.models.objects.ScoreBoard();
				break;

			case "score":
				obj = new io.newgrounds.models.objects.Score();
				break;

			case "saveslot":
				obj = new io.newgrounds.models.objects.SaveSlot();
				break;

		}

		if (coreReference) obj.core = coreReference;

		// If object was created and data provided, import the data
		if (obj != null && objectData != null) {
			obj.importFromObject(objectData);
		}

		return obj;
	}

	/**
	 * Creates an instance of a component model (Medal.unlock, App.checkSession, etc.)
	 * @param component The component namespace (e.g., "Medal", "App", "ScoreBoard")
	 * @param method The method name (e.g., "unlock", "checkSession", "postScore")
	 * @param props Properties/parameters to initialize the component with
	 * @param coreReference Core instance to assign to the component (optional)
	 * @return An instance of the requested component, or null if not found
	 */
	public static function CreateComponent(component:String, method:String, props:Object, coreReference:io.newgrounds.Core):io.newgrounds.BaseComponent {
		if (props == undefined) props = null;
		if (coreReference == undefined) coreReference = null;
		if (!component || !method) return null;

		var comp:io.newgrounds.BaseComponent = null;
		var fullName:String = component + "." + method;

		switch(fullName.toLowerCase()) {
			case "app.logview":
				comp = new io.newgrounds.models.components.App.logView();
				break;

			case "app.checksession":
				comp = new io.newgrounds.models.components.App.checkSession();
				break;

			case "app.gethostlicense":
				comp = new io.newgrounds.models.components.App.getHostLicense();
				break;

			case "app.getcurrentversion":
				comp = new io.newgrounds.models.components.App.getCurrentVersion();
				break;

			case "app.startsession":
				comp = new io.newgrounds.models.components.App.startSession();
				break;

			case "app.endsession":
				comp = new io.newgrounds.models.components.App.endSession();
				break;

			case "cloudsave.clearslot":
				comp = new io.newgrounds.models.components.CloudSave.clearSlot();
				break;

			case "cloudsave.loadslot":
				comp = new io.newgrounds.models.components.CloudSave.loadSlot();
				break;

			case "cloudsave.loadslots":
				comp = new io.newgrounds.models.components.CloudSave.loadSlots();
				break;

			case "cloudsave.setdata":
				comp = new io.newgrounds.models.components.CloudSave.setData();
				break;

			case "event.logevent":
				comp = new io.newgrounds.models.components.Event.logEvent();
				break;

			case "gateway.getversion":
				comp = new io.newgrounds.models.components.Gateway.getVersion();
				break;

			case "gateway.getdatetime":
				comp = new io.newgrounds.models.components.Gateway.getDatetime();
				break;

			case "gateway.ping":
				comp = new io.newgrounds.models.components.Gateway.ping();
				break;

			case "loader.loadofficialurl":
				comp = new io.newgrounds.models.components.Loader.loadOfficialUrl();
				break;

			case "loader.loadauthorurl":
				comp = new io.newgrounds.models.components.Loader.loadAuthorUrl();
				break;

			case "loader.loadreferral":
				comp = new io.newgrounds.models.components.Loader.loadReferral();
				break;

			case "loader.loadmoregames":
				comp = new io.newgrounds.models.components.Loader.loadMoreGames();
				break;

			case "loader.loadnewgrounds":
				comp = new io.newgrounds.models.components.Loader.loadNewgrounds();
				break;

			case "medal.getlist":
				comp = new io.newgrounds.models.components.Medal.getList();
				break;

			case "medal.getmedalscore":
				comp = new io.newgrounds.models.components.Medal.getMedalScore();
				break;

			case "medal.unlock":
				comp = new io.newgrounds.models.components.Medal.unlock();
				break;

			case "scoreboard.getboards":
				comp = new io.newgrounds.models.components.ScoreBoard.getBoards();
				break;

			case "scoreboard.postscore":
				comp = new io.newgrounds.models.components.ScoreBoard.postScore();
				break;

			case "scoreboard.getscores":
				comp = new io.newgrounds.models.components.ScoreBoard.getScores();
				break;

		}

		if (coreReference) comp.core = coreReference;

		// If component was created and data provided, import the data
		if (comp != null && props != null) {
			comp.importFromObject(props);
		}

		return comp;
	}

	/**
	 * Creates an instance of a result model with data returned from the API
	 * @param component The component namespace that was called (e.g., "Medal", "App")
	 * @param method The method name that was called (e.g., "unlock", "checkSession")
	 * @param props The result data returned from the server
	 * @param coreReference Core instance to assign to the result (optional)
	 * @return An instance of the requested result object, or null if not found
	 */
	public static function CreateResult(component:String, method:String, props:Object, coreReference:io.newgrounds.Core):io.newgrounds.BaseResult {
		if (props == undefined) props = null;
		if (coreReference == undefined) coreReference = null;
		if (!component || !method) return null;

		var result:io.newgrounds.BaseResult = null;
		var fullName:String = component + "." + method;

		switch(fullName.toLowerCase()) {
			case "app.logview":
				result = new io.newgrounds.models.results.App.logViewResult();
				break;

			case "app.checksession":
				result = new io.newgrounds.models.results.App.checkSessionResult();
				break;

			case "app.gethostlicense":
				result = new io.newgrounds.models.results.App.getHostLicenseResult();
				break;

			case "app.getcurrentversion":
				result = new io.newgrounds.models.results.App.getCurrentVersionResult();
				break;

			case "app.startsession":
				result = new io.newgrounds.models.results.App.startSessionResult();
				break;

			case "app.endsession":
				result = new io.newgrounds.models.results.App.endSessionResult();
				break;

			case "cloudsave.clearslot":
				result = new io.newgrounds.models.results.CloudSave.clearSlotResult();
				break;

			case "cloudsave.loadslot":
				result = new io.newgrounds.models.results.CloudSave.loadSlotResult();
				break;

			case "cloudsave.loadslots":
				result = new io.newgrounds.models.results.CloudSave.loadSlotsResult();
				break;

			case "cloudsave.setdata":
				result = new io.newgrounds.models.results.CloudSave.setDataResult();
				break;

			case "event.logevent":
				result = new io.newgrounds.models.results.Event.logEventResult();
				break;

			case "gateway.getversion":
				result = new io.newgrounds.models.results.Gateway.getVersionResult();
				break;

			case "gateway.getdatetime":
				result = new io.newgrounds.models.results.Gateway.getDatetimeResult();
				break;

			case "gateway.ping":
				result = new io.newgrounds.models.results.Gateway.pingResult();
				break;

			case "loader.loadofficialurl":
				result = new io.newgrounds.models.results.Loader.loadOfficialUrlResult();
				break;

			case "loader.loadauthorurl":
				result = new io.newgrounds.models.results.Loader.loadAuthorUrlResult();
				break;

			case "loader.loadreferral":
				result = new io.newgrounds.models.results.Loader.loadReferralResult();
				break;

			case "loader.loadmoregames":
				result = new io.newgrounds.models.results.Loader.loadMoreGamesResult();
				break;

			case "loader.loadnewgrounds":
				result = new io.newgrounds.models.results.Loader.loadNewgroundsResult();
				break;

			case "medal.getlist":
				result = new io.newgrounds.models.results.Medal.getListResult();
				break;

			case "medal.getmedalscore":
				result = new io.newgrounds.models.results.Medal.getMedalScoreResult();
				break;

			case "medal.unlock":
				result = new io.newgrounds.models.results.Medal.unlockResult();
				break;

			case "scoreboard.getboards":
				result = new io.newgrounds.models.results.ScoreBoard.getBoardsResult();
				break;

			case "scoreboard.postscore":
				result = new io.newgrounds.models.results.ScoreBoard.postScoreResult();
				break;

			case "scoreboard.getscores":
				result = new io.newgrounds.models.results.ScoreBoard.getScoresResult();
				break;

		}

		if (coreReference) result.core = coreReference;

		// If result was created and data provided, import the data
		if (result != null && props != null) {
			result.importFromObject(props);
		}

		return result;
	}
}
