/** ActionScript 2.0 **/

class io.newgrounds.models.objects.ObjectIndex {

	
	public static function CreateObject(name:String, json:Object)
	{
		switch (name.toLowerCase()) {
			
			case "request":
				var new_Request = new io.newgrounds.models.objects.Request(json);
				return new_Request;


			case "debug":
				var new_Debug = new io.newgrounds.models.objects.Debug(json);
				return new_Debug;

			case "response":
				var new_Response = new io.newgrounds.models.objects.Response(json);
				return new_Response;


			case "error":
				var new_Error = new io.newgrounds.models.objects.Error(json);
				return new_Error;

			case "session":
				var new_Session = new io.newgrounds.models.objects.Session(json);
				return new_Session;

			case "user":
				var new_User = new io.newgrounds.models.objects.User(json);
				return new_User;

			case "usericons":
				var new_UserIcons = new io.newgrounds.models.objects.UserIcons(json);
				return new_UserIcons;

			case "medal":
				var new_Medal = new io.newgrounds.models.objects.Medal(json);
				return new_Medal;

			case "scoreboard":
				var new_ScoreBoard = new io.newgrounds.models.objects.ScoreBoard(json);
				return new_ScoreBoard;

			case "score":
				var new_Score = new io.newgrounds.models.objects.Score(json);
				return new_Score;

			case "saveslot":
				var new_SaveSlot = new io.newgrounds.models.objects.SaveSlot(json);
				return new_SaveSlot;
		}
		return null;
	}

	public static function CreateComponent(name:String, json:Object)
	{
		switch (name.toLowerCase()) {
			
			case "app.logview":
				var new_App_logView = new io.newgrounds.models.components.App.logView(json);
				return new_App_logView;

			case "app.checksession":
				var new_App_checkSession = new io.newgrounds.models.components.App.checkSession(json);
				return new_App_checkSession;

			case "app.gethostlicense":
				var new_App_getHostLicense = new io.newgrounds.models.components.App.getHostLicense(json);
				return new_App_getHostLicense;

			case "app.getcurrentversion":
				var new_App_getCurrentVersion = new io.newgrounds.models.components.App.getCurrentVersion(json);
				return new_App_getCurrentVersion;

			case "app.startsession":
				var new_App_startSession = new io.newgrounds.models.components.App.startSession(json);
				return new_App_startSession;

			case "app.endsession":
				var new_App_endSession = new io.newgrounds.models.components.App.endSession(json);
				return new_App_endSession;

			case "cloudsave.clearslot":
				var new_CloudSave_clearSlot = new io.newgrounds.models.components.CloudSave.clearSlot(json);
				return new_CloudSave_clearSlot;

			case "cloudsave.loadslot":
				var new_CloudSave_loadSlot = new io.newgrounds.models.components.CloudSave.loadSlot(json);
				return new_CloudSave_loadSlot;

			case "cloudsave.loadslots":
				var new_CloudSave_loadSlots = new io.newgrounds.models.components.CloudSave.loadSlots(json);
				return new_CloudSave_loadSlots;

			case "cloudsave.setdata":
				var new_CloudSave_setData = new io.newgrounds.models.components.CloudSave.setData(json);
				return new_CloudSave_setData;

			case "event.logevent":
				var new_Event_logEvent = new io.newgrounds.models.components.Event.logEvent(json);
				return new_Event_logEvent;

			case "gateway.getversion":
				var new_Gateway_getVersion = new io.newgrounds.models.components.Gateway.getVersion(json);
				return new_Gateway_getVersion;

			case "gateway.getdatetime":
				var new_Gateway_getDatetime = new io.newgrounds.models.components.Gateway.getDatetime(json);
				return new_Gateway_getDatetime;

			case "gateway.ping":
				var new_Gateway_ping = new io.newgrounds.models.components.Gateway.ping(json);
				return new_Gateway_ping;

			case "loader.loadofficialurl":
				var new_Loader_loadOfficialUrl = new io.newgrounds.models.components.Loader.loadOfficialUrl(json);
				return new_Loader_loadOfficialUrl;

			case "loader.loadauthorurl":
				var new_Loader_loadAuthorUrl = new io.newgrounds.models.components.Loader.loadAuthorUrl(json);
				return new_Loader_loadAuthorUrl;

			case "loader.loadreferral":
				var new_Loader_loadReferral = new io.newgrounds.models.components.Loader.loadReferral(json);
				return new_Loader_loadReferral;

			case "loader.loadmoregames":
				var new_Loader_loadMoreGames = new io.newgrounds.models.components.Loader.loadMoreGames(json);
				return new_Loader_loadMoreGames;

			case "loader.loadnewgrounds":
				var new_Loader_loadNewgrounds = new io.newgrounds.models.components.Loader.loadNewgrounds(json);
				return new_Loader_loadNewgrounds;

			case "medal.getlist":
				var new_Medal_getList = new io.newgrounds.models.components.Medal.getList(json);
				return new_Medal_getList;

			case "medal.getmedalscore":
				var new_Medal_getMedalScore = new io.newgrounds.models.components.Medal.getMedalScore(json);
				return new_Medal_getMedalScore;

			case "medal.unlock":
				var new_Medal_unlock = new io.newgrounds.models.components.Medal.unlock(json);
				return new_Medal_unlock;

			case "scoreboard.getboards":
				var new_ScoreBoard_getBoards = new io.newgrounds.models.components.ScoreBoard.getBoards(json);
				return new_ScoreBoard_getBoards;

			case "scoreboard.postscore":
				var new_ScoreBoard_postScore = new io.newgrounds.models.components.ScoreBoard.postScore(json);
				return new_ScoreBoard_postScore;

			case "scoreboard.getscores":
				var new_ScoreBoard_getScores = new io.newgrounds.models.components.ScoreBoard.getScores(json);
				return new_ScoreBoard_getScores;
		}
		return null;
	}

	public static function CreateResult(name:String, json:Object)
	{
		switch (name.toLowerCase()) {
			
			case "app.checksession":
				var new_App_checkSession = new io.newgrounds.models.results.App.checkSession(json);
				return new_App_checkSession;

			case "app.gethostlicense":
				var new_App_getHostLicense = new io.newgrounds.models.results.App.getHostLicense(json);
				return new_App_getHostLicense;

			case "app.getcurrentversion":
				var new_App_getCurrentVersion = new io.newgrounds.models.results.App.getCurrentVersion(json);
				return new_App_getCurrentVersion;

			case "app.startsession":
				var new_App_startSession = new io.newgrounds.models.results.App.startSession(json);
				return new_App_startSession;

			case "cloudsave.clearslot":
				var new_CloudSave_clearSlot = new io.newgrounds.models.results.CloudSave.clearSlot(json);
				return new_CloudSave_clearSlot;

			case "cloudsave.loadslot":
				var new_CloudSave_loadSlot = new io.newgrounds.models.results.CloudSave.loadSlot(json);
				return new_CloudSave_loadSlot;

			case "cloudsave.loadslots":
				var new_CloudSave_loadSlots = new io.newgrounds.models.results.CloudSave.loadSlots(json);
				return new_CloudSave_loadSlots;

			case "cloudsave.setdata":
				var new_CloudSave_setData = new io.newgrounds.models.results.CloudSave.setData(json);
				return new_CloudSave_setData;

			case "event.logevent":
				var new_Event_logEvent = new io.newgrounds.models.results.Event.logEvent(json);
				return new_Event_logEvent;

			case "gateway.getversion":
				var new_Gateway_getVersion = new io.newgrounds.models.results.Gateway.getVersion(json);
				return new_Gateway_getVersion;

			case "gateway.getdatetime":
				var new_Gateway_getDatetime = new io.newgrounds.models.results.Gateway.getDatetime(json);
				return new_Gateway_getDatetime;

			case "gateway.ping":
				var new_Gateway_ping = new io.newgrounds.models.results.Gateway.ping(json);
				return new_Gateway_ping;

			case "loader.loadofficialurl":
				var new_Loader_loadOfficialUrl = new io.newgrounds.models.results.Loader.loadOfficialUrl(json);
				return new_Loader_loadOfficialUrl;

			case "loader.loadauthorurl":
				var new_Loader_loadAuthorUrl = new io.newgrounds.models.results.Loader.loadAuthorUrl(json);
				return new_Loader_loadAuthorUrl;

			case "loader.loadreferral":
				var new_Loader_loadReferral = new io.newgrounds.models.results.Loader.loadReferral(json);
				return new_Loader_loadReferral;

			case "loader.loadmoregames":
				var new_Loader_loadMoreGames = new io.newgrounds.models.results.Loader.loadMoreGames(json);
				return new_Loader_loadMoreGames;

			case "loader.loadnewgrounds":
				var new_Loader_loadNewgrounds = new io.newgrounds.models.results.Loader.loadNewgrounds(json);
				return new_Loader_loadNewgrounds;

			case "medal.getlist":
				var new_Medal_getList = new io.newgrounds.models.results.Medal.getList(json);
				return new_Medal_getList;

			case "medal.getmedalscore":
				var new_Medal_getMedalScore = new io.newgrounds.models.results.Medal.getMedalScore(json);
				return new_Medal_getMedalScore;

			case "medal.unlock":
				var new_Medal_unlock = new io.newgrounds.models.results.Medal.unlock(json);
				return new_Medal_unlock;

			case "scoreboard.getboards":
				var new_ScoreBoard_getBoards = new io.newgrounds.models.results.ScoreBoard.getBoards(json);
				return new_ScoreBoard_getBoards;

			case "scoreboard.postscore":
				var new_ScoreBoard_postScore = new io.newgrounds.models.results.ScoreBoard.postScore(json);
				return new_ScoreBoard_postScore;

			case "scoreboard.getscores":
				var new_ScoreBoard_getScores = new io.newgrounds.models.results.ScoreBoard.getScores(json);
				return new_ScoreBoard_getScores;
		}
		return null;
	}
}
	