/** ActionScript 2.0 **/

class io.newgrounds.models.objects.ObjectIndex {

	public static function CreateObject(name:String, json:Object) {
		switch (name.toLowerCase()) {
			case "request":
				return new io.newgrounds.models.objects.Request(json);

			case "debug":
				return new io.newgrounds.models.objects.Debug(json);

			case "response":
				return new io.newgrounds.models.objects.Response(json);

			case "error":
				return new io.newgrounds.models.objects.Error(json);

			case "session":
				return new io.newgrounds.models.objects.Session(json);

			case "user":
				return new io.newgrounds.models.objects.User(json);

			case "usericons":
				return new io.newgrounds.models.objects.UserIcons(json);

			case "medal":
				return new io.newgrounds.models.objects.Medal(json);

			case "scoreboard":
				return new io.newgrounds.models.objects.ScoreBoard(json);

			case "score":
				return new io.newgrounds.models.objects.Score(json);

			case "saveslot":
				return new io.newgrounds.models.objects.SaveSlot(json);

		}
		return null;
	}

	public static function CreateComponent(name:String, json:Object) {
		switch (name.toLowerCase()) {
			case "app.logview":
				return new io.newgrounds.models.components.App.logView(json);

			case "app.checksession":
				return new io.newgrounds.models.components.App.checkSession(json);

			case "app.gethostlicense":
				return new io.newgrounds.models.components.App.getHostLicense(json);

			case "app.getcurrentversion":
				return new io.newgrounds.models.components.App.getCurrentVersion(json);

			case "app.startsession":
				return new io.newgrounds.models.components.App.startSession(json);

			case "app.endsession":
				return new io.newgrounds.models.components.App.endSession(json);

			case "cloudsave.clearslot":
				return new io.newgrounds.models.components.CloudSave.clearSlot(json);

			case "cloudsave.loadslot":
				return new io.newgrounds.models.components.CloudSave.loadSlot(json);

			case "cloudsave.loadslots":
				return new io.newgrounds.models.components.CloudSave.loadSlots(json);

			case "cloudsave.setdata":
				return new io.newgrounds.models.components.CloudSave.setData(json);

			case "event.logevent":
				return new io.newgrounds.models.components.Event.logEvent(json);

			case "gateway.getversion":
				return new io.newgrounds.models.components.Gateway.getVersion(json);

			case "gateway.getdatetime":
				return new io.newgrounds.models.components.Gateway.getDatetime(json);

			case "gateway.ping":
				return new io.newgrounds.models.components.Gateway.ping(json);

			case "loader.loadofficialurl":
				return new io.newgrounds.models.components.Loader.loadOfficialUrl(json);

			case "loader.loadauthorurl":
				return new io.newgrounds.models.components.Loader.loadAuthorUrl(json);

			case "loader.loadreferral":
				return new io.newgrounds.models.components.Loader.loadReferral(json);

			case "loader.loadmoregames":
				return new io.newgrounds.models.components.Loader.loadMoreGames(json);

			case "loader.loadnewgrounds":
				return new io.newgrounds.models.components.Loader.loadNewgrounds(json);

			case "medal.getlist":
				return new io.newgrounds.models.components.Medal.getList(json);

			case "medal.getmedalscore":
				return new io.newgrounds.models.components.Medal.getMedalScore(json);

			case "medal.unlock":
				return new io.newgrounds.models.components.Medal.unlock(json);

			case "scoreboard.getboards":
				return new io.newgrounds.models.components.ScoreBoard.getBoards(json);

			case "scoreboard.postscore":
				return new io.newgrounds.models.components.ScoreBoard.postScore(json);

			case "scoreboard.getscores":
				return new io.newgrounds.models.components.ScoreBoard.getScores(json);

		}
		return null;
	}

	public static function CreateResult(name:String, json:Object) {
		switch (name.toLowerCase()) {
			case "app.checksession":
				return new io.newgrounds.models.results.App.checkSession(json);

			case "app.gethostlicense":
				return new io.newgrounds.models.results.App.getHostLicense(json);

			case "app.getcurrentversion":
				return new io.newgrounds.models.results.App.getCurrentVersion(json);

			case "app.startsession":
				return new io.newgrounds.models.results.App.startSession(json);

			case "cloudsave.clearslot":
				return new io.newgrounds.models.results.CloudSave.clearSlot(json);

			case "cloudsave.loadslot":
				return new io.newgrounds.models.results.CloudSave.loadSlot(json);

			case "cloudsave.loadslots":
				return new io.newgrounds.models.results.CloudSave.loadSlots(json);

			case "cloudsave.setdata":
				return new io.newgrounds.models.results.CloudSave.setData(json);

			case "event.logevent":
				return new io.newgrounds.models.results.Event.logEvent(json);

			case "gateway.getversion":
				return new io.newgrounds.models.results.Gateway.getVersion(json);

			case "gateway.getdatetime":
				return new io.newgrounds.models.results.Gateway.getDatetime(json);

			case "gateway.ping":
				return new io.newgrounds.models.results.Gateway.ping(json);

			case "loader.loadofficialurl":
				return new io.newgrounds.models.results.Loader.loadOfficialUrl(json);

			case "loader.loadauthorurl":
				return new io.newgrounds.models.results.Loader.loadAuthorUrl(json);

			case "loader.loadreferral":
				return new io.newgrounds.models.results.Loader.loadReferral(json);

			case "loader.loadmoregames":
				return new io.newgrounds.models.results.Loader.loadMoreGames(json);

			case "loader.loadnewgrounds":
				return new io.newgrounds.models.results.Loader.loadNewgrounds(json);

			case "medal.getlist":
				return new io.newgrounds.models.results.Medal.getList(json);

			case "medal.getmedalscore":
				return new io.newgrounds.models.results.Medal.getMedalScore(json);

			case "medal.unlock":
				return new io.newgrounds.models.results.Medal.unlock(json);

			case "scoreboard.getboards":
				return new io.newgrounds.models.results.ScoreBoard.getBoards(json);

			case "scoreboard.postscore":
				return new io.newgrounds.models.results.ScoreBoard.postScore(json);

			case "scoreboard.getscores":
				return new io.newgrounds.models.results.ScoreBoard.getScores(json);

		}
		return null;
	}

}