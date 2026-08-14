/**
 * NgioExternalAppHelper
 *
 * Read-only access to ANOTHER app's data.
 *
 * Four gateway components accept an app_id parameter, letting an approved app
 * read a different app's medals, scores and cloud saves: Medal.getList,
 * ScoreBoard.getScores, CloudSave.loadSlot and CloudSave.loadSlots. Access has
 * to be granted by the other app's owner in their Newgrounds project settings.
 *
 * DESIGN: results are handed to the callback and never cached. AppState models
 * exactly one app - the one this client is running as - and its session, medal
 * score, host approval and version fields have no foreign equivalent. Caching
 * another app's medals there would replace the local list wholesale and mark it
 * loaded, so NGIO.getMedals() would start returning the wrong app's medals.
 * AppState rejects foreign results outright for that reason; this helper is the
 * supported way to get at them.
 *
 * Every model returned here is stamped with foreignAppId, so a foreign object
 * can be told apart from a local one after the fact.
 */
import io.newgrounds.BaseObject;
import io.newgrounds.Core;
import io.newgrounds.Errors;

class io.newgrounds.helpers.NgioExternalAppHelper {

	//==================== PUBLIC METHODS ====================

	/**
	 * Loads the medal list belonging to another app.
	 *
	 * @param core The active NGIO core instance
	 * @param appId The other app's ID, which must have granted access
	 * @param callback Function called with (medals:Array, error)
	 * @param thisArg Scope for the callback
	 */
	public static function loadMedals(core:io.newgrounds.Core, appId:String, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		validate(core, appId);

		call(core, appId, "Medal.getList", { app_id: appId }, "medals", callback, thisArg);
	}

	/**
	 * Loads scores from a scoreboard belonging to another app.
	 *
	 * NOTE: you must already know the board id. ScoreBoard.getBoards does not
	 * accept an app_id, so there is no supported way to discover another app's
	 * boards at runtime.
	 *
	 * @param core The active NGIO core instance
	 * @param appId The other app's ID, which must have granted access
	 * @param boardId The scoreboard ID, which must belong to that app
	 * @param filters Optional period/limit/skip/tag/social/user filters
	 * @param callback Function called with (scores:Array, error)
	 * @param thisArg Scope for the callback
	 */
	public static function loadScores(core:io.newgrounds.Core, appId:String, boardId:Number, filters:Object, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		validate(core, appId);

		var params:Object = buildScoreParams(core, filters);
		params.app_id = appId;
		params.id = boardId;

		call(core, appId, "ScoreBoard.getScores", params, "scores", callback, thisArg);
	}

	/**
	 * Loads the cloud save slot list belonging to another app.
	 *
	 * @param core The active NGIO core instance
	 * @param appId The other app's ID, which must have granted access
	 * @param callback Function called with (saveSlots:Array, error)
	 * @param thisArg Scope for the callback
	 */
	public static function loadSaveSlots(core:io.newgrounds.Core, appId:String, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		validate(core, appId);

		call(core, appId, "CloudSave.loadSlots", { app_id: appId }, "slots", callback, thisArg);
	}

	/**
	 * Loads a single cloud save slot belonging to another app.
	 *
	 * @param core The active NGIO core instance
	 * @param appId The other app's ID, which must have granted access
	 * @param slotId The slot number
	 * @param callback Function called with (saveSlot, error)
	 * @param thisArg Scope for the callback
	 */
	public static function loadSaveSlot(core:io.newgrounds.Core, appId:String, slotId:Number, callback:Function, thisArg):Void {
		if (thisArg == undefined) thisArg = null;
		validate(core, appId);

		call(core, appId, "CloudSave.loadSlot", { app_id: appId, id: slotId }, "slot", callback, thisArg);
	}

	//==================== PRIVATE METHODS ====================

	/**
	 * Rejects the two mistakes that would otherwise fail confusingly.
	 */
	private static function validate(core:io.newgrounds.Core, appId:String):Void {
		if (core == null) {
			throw new Error("Core not initialized");
		}

		if (appId == null || appId == undefined || appId.length == 0) {
			throw new Error("An external App ID is required");
		}

		// Passing our own id here is a programming error, not a cross-app read.
		// It would quietly behave like the ordinary load - except uncached -
		// which is a confusing thing to debug later.
		if (appId == core.appId) {
			throw new Error(
				"'" + appId + "' is this app's own ID. Use the ordinary load method instead - " +
				"the loadExternal methods are only for reading OTHER apps' data."
			);
		}
	}

	/**
	 * Shared request/unwrap path for all four components.
	 *
	 * @param resultProperty The property on the result model holding the payload
	 */
	private static function call(core:io.newgrounds.Core, appId:String, componentPath:String, params:Object, resultProperty:String, callback:Function, thisArg):Void {
		// Locals are captured by the closure below; `this` is not bound in AS2
		// closures, so nothing here may rely on it.
		core.callComponent(componentPath, params, function(response, callbackParams) {
			if (callback == null) {
				return;
			}

			var error = null;
			var payload = null;

			// A cross-app read can be refused at either level: the request may
			// fail outright, or succeed while the component reports that access
			// was not granted. Check both so the caller gets one clear answer.
			if (response == null || response.success !== true) {
				error = (response != null && response.error != null)
					? response.error
					: io.newgrounds.Errors.getError(0, null, false);
			} else {
				var result = response.getResult();

				if (result == null) {
					error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE, null, false);
				} else if (result.success !== true) {
					error = (result.error != null) ? result.error : io.newgrounds.Errors.getError(0, null, false);
				} else {
					// Stamp the whole result, not just the payload we hand back. A
					// getScores result also carries the ScoreBoard it came from, and a
					// caller who unwraps the result themselves - the raw callComponent
					// path - would otherwise get a foreign board that reads as local,
					// with its write guard silently disarmed. Marking everything costs
					// one recursion over a small object.
					io.newgrounds.helpers.NgioExternalAppHelper.stampForeign(result, appId);

					payload = result[resultProperty];
				}
			}

			callback.call(thisArg, payload, error);
		}, null, null);
	}

	/**
	 * Marks a returned model, and everything nested inside it, as belonging to
	 * another app.
	 *
	 * Recursive because the interesting objects are often nested: a score list
	 * carries a User per Score, and a getScores result carries the ScoreBoard.
	 * A caller holding any of those should be able to tell where it came from.
	 */
	private static function stampForeign(value, appId:String):Void {
		if (value == null || value == undefined) {
			return;
		}

		var i:Number;

		if (value instanceof Array) {
			var list:Array = Array(value);
			for (i = 0; i < list.length; i++) {
				stampForeign(list[i], appId);
			}
			return;
		}

		if (!(value instanceof io.newgrounds.BaseObject)) {
			return;
		}

		var model:io.newgrounds.BaseObject = io.newgrounds.BaseObject(value);
		model.foreignAppId = appId;

		var propNames:Array = model.propertyNames;
		for (i = 0; i < propNames.length; i++) {
			stampForeign(model[propNames[i]], appId);
		}
	}

	/**
	 * Normalizes the optional score filters, mirroring ScoreBoard.getScores so
	 * cross-app reads accept the same options and validate them the same way.
	 */
	private static function buildScoreParams(core:io.newgrounds.Core, filters:Object):Object {
		var params:Object = {};

		if (filters == null || filters == undefined) {
			filters = {};
		}

		params.period = (filters.period !== undefined && filters.period !== null) ? filters.period : 'D';

		var limit:Number = (filters.limit !== undefined && filters.limit !== null) ? filters.limit : 10;
		if (limit < 1) {
			throw new Error('ScoreBoard filter limit must be a number greater than 0.');
		}
		if (limit > 100) {
			throw new Error('ScoreBoard filter limit must be a number less than or equal to 100.');
		}
		params.limit = limit;

		params.skip = (filters.skip !== undefined) ? filters.skip : 0;

		if (filters.tag !== undefined && filters.tag !== null) {
			params.tag = filters.tag;
		}

		// 'social' works cross-app. The friends list is a site-wide relation
		// rather than a per-app one, so "me and my friends" means the same thing
		// on another app's board - which makes a shared leaderboard across a
		// series of games one of the more useful things this can do.
		//
		// Gated on a session for the same reason as the local path: the gateway
		// ignores 'social' when it has no way to tell who "you" are.
		if (core.hasSession() && filters.social === true) {
			params.social = true;
		}

		if (filters.user_id !== undefined && filters.user_id !== null) {
			if (typeof(filters.user_id) != 'number') {
				throw new Error('ScoreBoard filter user_id must be a number.');
			}
			params.user = filters.user_id;
		} else if (filters.user_name !== undefined && filters.user_name !== null) {
			if (typeof(filters.user_name) != 'string') {
				throw new Error('ScoreBoard filter user_name must be a string.');
			}
			params.user = filters.user_name;
		}

		return params;
	}
}
