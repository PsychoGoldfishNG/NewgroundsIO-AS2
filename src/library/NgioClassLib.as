/**
 * NgioClassLib
 *
 * Pre-compilation library class for the entire NewgroundsIO-AS2 library.
 *
 * This class ensures that all library classes are compiled when added to a
 * Flash project. Classes are imported and referenced in strict bottom-up
 * dependency order so that Flash 8's AS2 compiler initializes prototype
 * chains correctly before any subclass attempts to extend them.
 *
 * Add an instance of this class to your FLA library to ensure the full
 * NewgroundsIO-AS2 library is available for runtime use.
 */

// --- Tier 1: Encoders (no project dependencies) ---
import io.newgrounds.encoders.Base64;
import io.newgrounds.encoders.RC4;
import io.newgrounds.encoders.JSON;

// --- Tier 2: Root base class ---
import io.newgrounds.BaseObject;

// --- Tier 3: Second-level base classes (extend BaseObject) ---
import io.newgrounds.BaseComponent;
import io.newgrounds.BaseResult;

// --- Tier 4: Standalone utilities ---
import io.newgrounds.Errors;
import io.newgrounds.SessionStatus;

// --- Tier 5: Model objects (all extend BaseObject) ---
import io.newgrounds.models.objects.NgioError;
import io.newgrounds.models.objects.User;
import io.newgrounds.models.objects.Medal;
import io.newgrounds.models.objects.Score;
import io.newgrounds.models.objects.ScoreBoard;
import io.newgrounds.models.objects.SaveSlot;
import io.newgrounds.models.objects.Session;
import io.newgrounds.models.objects.Debug;
import io.newgrounds.models.objects.Execute;
import io.newgrounds.models.objects.Request;
import io.newgrounds.models.objects.Response;

// --- Tier 6: Object factory (references all model objects) ---
import io.newgrounds.models.objects.ObjectFactory;

// --- Tier 7: Result classes (extend BaseResult) ---
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

// --- Tier 8: Component classes (extend BaseComponent) ---
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

// --- Tier 9: Helper classes (static, no inheritance) ---
import io.newgrounds.helpers.AppStateBootstrapHelper;
import io.newgrounds.helpers.AppStateComponentHelper;
import io.newgrounds.helpers.AppStateResultUpdateHelper;
import io.newgrounds.helpers.AppStateSessionHelper;
import io.newgrounds.helpers.AppStateSessionResetHelper;
import io.newgrounds.helpers.CoreComponentCallHelper;
import io.newgrounds.helpers.CoreQueueExecutionHelper;
import io.newgrounds.helpers.CoreTransportHelper;
import io.newgrounds.helpers.HttpRequestHelper;
import io.newgrounds.helpers.HttpResponseHelper;
import io.newgrounds.helpers.NgioAuthHelper;
import io.newgrounds.helpers.NgioBootstrapHelper;
import io.newgrounds.helpers.NgioEventHelper;
import io.newgrounds.helpers.NgioGatewayHelper;
import io.newgrounds.helpers.NgioLoaderHelper;

// --- Tier 10: Core system (depends on helpers, models, and state) ---
import io.newgrounds.AppState;
import io.newgrounds.Core;

// --- Tier 11: Main API wrapper (depends on everything) ---
import NGIO;

class NgioClassLib extends MovieClip {
	public function NgioClassLib() {

		// Reference all classes in bottom-up dependency order.
		// This forces Flash 8 to initialize each class's prototype before
		// any subclass runs its "prototype = new ParentClass()" setup.
		// Assigning to _class (rather than trace) keeps output logs clean.
		var _class;

		// Tier 1: Encoders
		_class = io.newgrounds.encoders.Base64;
		_class = io.newgrounds.encoders.RC4;
		_class = io.newgrounds.encoders.JSON;

		// Tier 2: Root base class
		_class = io.newgrounds.BaseObject;

		// Tier 3: Second-level base classes
		_class = io.newgrounds.BaseComponent;
		_class = io.newgrounds.BaseResult;

		// Tier 4: Standalone utilities
		_class = io.newgrounds.Errors;
		_class = io.newgrounds.SessionStatus;

		// Tier 5: Model objects
		_class = io.newgrounds.models.objects.NgioError;
		_class = io.newgrounds.models.objects.User;
		_class = io.newgrounds.models.objects.Medal;
		_class = io.newgrounds.models.objects.Score;
		_class = io.newgrounds.models.objects.ScoreBoard;
		_class = io.newgrounds.models.objects.SaveSlot;
		_class = io.newgrounds.models.objects.Session;
		_class = io.newgrounds.models.objects.Debug;
		_class = io.newgrounds.models.objects.Execute;
		_class = io.newgrounds.models.objects.Request;
		_class = io.newgrounds.models.objects.Response;

		// Tier 6: Object factory
		_class = io.newgrounds.models.objects.ObjectFactory;

		// Tier 7: Result classes
		_class = io.newgrounds.models.results.App.logViewResult;
		_class = io.newgrounds.models.results.App.checkSessionResult;
		_class = io.newgrounds.models.results.App.getHostLicenseResult;
		_class = io.newgrounds.models.results.App.getCurrentVersionResult;
		_class = io.newgrounds.models.results.App.startSessionResult;
		_class = io.newgrounds.models.results.App.endSessionResult;
		_class = io.newgrounds.models.results.CloudSave.clearSlotResult;
		_class = io.newgrounds.models.results.CloudSave.loadSlotResult;
		_class = io.newgrounds.models.results.CloudSave.loadSlotsResult;
		_class = io.newgrounds.models.results.CloudSave.setDataResult;
		_class = io.newgrounds.models.results.Event.logEventResult;
		_class = io.newgrounds.models.results.Gateway.getVersionResult;
		_class = io.newgrounds.models.results.Gateway.getDatetimeResult;
		_class = io.newgrounds.models.results.Gateway.pingResult;
		_class = io.newgrounds.models.results.Loader.loadOfficialUrlResult;
		_class = io.newgrounds.models.results.Loader.loadAuthorUrlResult;
		_class = io.newgrounds.models.results.Loader.loadReferralResult;
		_class = io.newgrounds.models.results.Loader.loadMoreGamesResult;
		_class = io.newgrounds.models.results.Loader.loadNewgroundsResult;
		_class = io.newgrounds.models.results.Medal.getListResult;
		_class = io.newgrounds.models.results.Medal.getMedalScoreResult;
		_class = io.newgrounds.models.results.Medal.unlockResult;
		_class = io.newgrounds.models.results.ScoreBoard.getBoardsResult;
		_class = io.newgrounds.models.results.ScoreBoard.postScoreResult;
		_class = io.newgrounds.models.results.ScoreBoard.getScoresResult;

		// Tier 8: Component classes
		_class = io.newgrounds.models.components.App.logView;
		_class = io.newgrounds.models.components.App.checkSession;
		_class = io.newgrounds.models.components.App.getHostLicense;
		_class = io.newgrounds.models.components.App.getCurrentVersion;
		_class = io.newgrounds.models.components.App.startSession;
		_class = io.newgrounds.models.components.App.endSession;
		_class = io.newgrounds.models.components.CloudSave.clearSlot;
		_class = io.newgrounds.models.components.CloudSave.loadSlot;
		_class = io.newgrounds.models.components.CloudSave.loadSlots;
		_class = io.newgrounds.models.components.CloudSave.setData;
		_class = io.newgrounds.models.components.Event.logEvent;
		_class = io.newgrounds.models.components.Gateway.getVersion;
		_class = io.newgrounds.models.components.Gateway.getDatetime;
		_class = io.newgrounds.models.components.Gateway.ping;
		_class = io.newgrounds.models.components.Loader.loadOfficialUrl;
		_class = io.newgrounds.models.components.Loader.loadAuthorUrl;
		_class = io.newgrounds.models.components.Loader.loadReferral;
		_class = io.newgrounds.models.components.Loader.loadMoreGames;
		_class = io.newgrounds.models.components.Loader.loadNewgrounds;
		_class = io.newgrounds.models.components.Medal.getList;
		_class = io.newgrounds.models.components.Medal.getMedalScore;
		_class = io.newgrounds.models.components.Medal.unlock;
		_class = io.newgrounds.models.components.ScoreBoard.getBoards;
		_class = io.newgrounds.models.components.ScoreBoard.postScore;
		_class = io.newgrounds.models.components.ScoreBoard.getScores;

		// Tier 9: Helper classes
		_class = io.newgrounds.helpers.AppStateBootstrapHelper;
		_class = io.newgrounds.helpers.AppStateComponentHelper;
		_class = io.newgrounds.helpers.AppStateResultUpdateHelper;
		_class = io.newgrounds.helpers.AppStateSessionHelper;
		_class = io.newgrounds.helpers.AppStateSessionResetHelper;
		_class = io.newgrounds.helpers.CoreComponentCallHelper;
		_class = io.newgrounds.helpers.CoreQueueExecutionHelper;
		_class = io.newgrounds.helpers.CoreTransportHelper;
		_class = io.newgrounds.helpers.HttpRequestHelper;
		_class = io.newgrounds.helpers.HttpResponseHelper;
		_class = io.newgrounds.helpers.NgioAuthHelper;
		_class = io.newgrounds.helpers.NgioBootstrapHelper;
		_class = io.newgrounds.helpers.NgioEventHelper;
		_class = io.newgrounds.helpers.NgioGatewayHelper;
		_class = io.newgrounds.helpers.NgioLoaderHelper;

		// Tier 10: Core system
		_class = io.newgrounds.AppState;
		_class = io.newgrounds.Core;

		// Tier 11: Main API wrapper
		_class = NGIO;
	}
}
