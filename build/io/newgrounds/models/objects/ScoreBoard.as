
/**
 * ScoreBoard
 *
 * Contains information about a scoreboard.
 */
import io.newgrounds.BaseObject;
import io.newgrounds.models.objects.Response;
import io.newgrounds.models.results.ScoreBoard.getScoresResult;
import io.newgrounds.models.results.ScoreBoard.postScoreResult;
import io.newgrounds.models.objects.User;
import io.newgrounds.models.objects.NgioError;

class io.newgrounds.models.objects.ScoreBoard extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * The numeric ID of the scoreboard.
	 */
	public var id:Number = 0;

	/**
	 * The name of the scoreboard.
	 */
	public var name:String = null;


	//==================== CONSTRUCTOR ====================

	public function ScoreBoard() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "ScoreBoard";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "object";
	}

	/**
	 * All property names for this object
	 */
	public function get propertyNames():Array {
		return ["id","name"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return [];
	}

	/**
	 * Type casting map for deserializing properties
	 */
	public function get castTypes():Object {
		return {
		};
	}

	//==================== CUSTOM METHODS ====================

	/**
	 * Loads scores from this scoreboard with optional filtering.
	 * @param filters Object containing optional filters (period, limit, skip, social, tag, user_id, user_name, user)
	 * @param callback Function to call with the loaded scores
	 * @param thisArg Context to use when calling the callback
	 */
	public function getScores(filters:Object, callback:Function, thisArg):Void {
		if (filters == undefined) filters = null;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		if (!filters) {
			filters = {};
		}

		var componentParams:Object = {};

		// Set default period to daily
		if (filters.period === undefined || filters.period === null) {
			filters.period = 'D';
		}
		componentParams.period = filters.period;

		// Validate and set limit
		if (filters.limit === undefined || filters.limit === null) {
			filters.limit = 10;
		}

		if (filters.limit < 1) {
			throw new Error('ScoreBoard filter limit must be a number greater than 0.');
		}

		if (filters.limit > 100) {
			throw new Error('ScoreBoard filter limit must be a number less than or equal to 100.');
		}

		componentParams.limit = filters.limit;

		// Set skip for pagination
		if (filters.skip === undefined) {
			filters.skip = 0;
		}
		componentParams.skip = filters.skip;

		// Handle social filter (friends only)
		//
		// Applies to foreign boards too. The friends list is a site-wide relation,
		// not a per-app one, so "me and my friends" is just as meaningful on another
		// app's board as on ours. The session gate stays because 'social' needs to
		// know who "you" are.
		if (this.core && this.core.hasSession() && filters.social === true) {
			componentParams.social = true;
		}

		// Handle tag filter
		if (filters.tag !== undefined && filters.tag !== null) {
			componentParams.tag = filters.tag;
		}

		// Handle user filtering
		if (filters.user_id !== undefined && filters.user_id !== null) {
			if (typeof filters.user_id === 'number') {
				componentParams.user = filters.user_id;
			} else {
				throw new Error('ScoreBoard filter user_id must be a number.');
			}
		} else if (filters.user_name !== undefined && filters.user_name !== null) {
			if (typeof filters.user_name === 'string') {
				componentParams.user = filters.user_name;
			} else {
				throw new Error('ScoreBoard filter user_name must be a string.');
			}
		} else if (filters.user !== undefined && filters.user !== null) {
			if (filters.user instanceof io.newgrounds.models.objects.User) {
				componentParams.user = filters.user.id;
			} else if (typeof filters.user === 'object' && filters.user.id != undefined) {
				componentParams.user = filters.user.id;
			} else {
				throw new Error('ScoreBoard filter user must be a User object with an id property.');
			}
		}

		// Add this scoreboard's ID
		componentParams.id = this.id;

		// A board loaded from another app keeps reading from that app. Without
		// forwarding the app_id the board came with, the gateway would look this id
		// up against THIS app and reject it - and reading is the one thing cross-app
		// access does allow, so make it work rather than refusing it. Every filter
		// above still applies, including 'social'.
		if (this.isForeign()) {
			componentParams.app_id = this.foreignAppId;
		}

		var callbackParams:Object = {
			callback: callback,
			thisArg: thisArg
		};

		if (this.core) this.core.callComponent("ScoreBoard.getScores", componentParams, this.onScoresLoaded, this, callbackParams);
	}

	/**
	 * Callback handler for when scores are loaded.
	 * @param response The Response object containing our results.
	 * @param callbackParams The callback parameters stored during getScores()
	 */
	public function onScoresLoaded(response:io.newgrounds.models.objects.Response, callbackParams:Object):Void {

		var result:io.newgrounds.models.results.ScoreBoard.getScoresResult = null;
		var scores:Array = null;
		var error = null;

		// A failed load can surface at either level: the request itself may fail, or
		// it may succeed while the component result reports failure. Check both, so
		// the caller gets one clear answer.
		if (response == null || response.success !== true) {
			error = (response != null && response.error != null)
				? response.error : io.newgrounds.Errors.getError();
		} else {
			result = response.getResult();

			if (result == null) {
				error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE);
			} else if (result.success !== true) {
				error = (result.error != null) ? result.error : io.newgrounds.Errors.getError();
			} else {
				scores = result.scores;
			}
		}

		if (callbackParams.callback != null) {
			callbackParams.callback.call(callbackParams.thisArg, scores, error);
		}
	}

	/**
	 * Posts a score to this scoreboard.
	 * @param value The score value to post
	 * @param tag Optional tag to associate with the score
	 * @param callback Function to call when posting is complete
	 * @param thisArg Context to use when calling the callback
	 * @throws Error if this scoreboard was loaded from another app
	 */
	public function postScore(value:Number, tag:String, callback:Function, thisArg):Void {
		this.assertNotForeign("postScore()", "The gateway would reject this scoreboard id against this app.");

		if (tag == undefined) tag = null;
		if (callback == undefined) callback = null;
		if (thisArg == undefined) thisArg = null;
		var componentParams:Object = {
			id: this.id,
			value: value
		};

		if (tag && tag.length > 0) {
			componentParams.tag = tag;
		}

		var callbackParams:Object = {
			callback: callback,
			thisArg: thisArg
		};

		if (this.core) this.core.callComponent("ScoreBoard.postScore", componentParams, this.onPostScore, this, callbackParams);
	}

	/**
	 * Callback handler for when a score is posted.
	 * @param response The response from ScoreBoard.postScore
	 * @param callbackParams The callback parameters stored during postScore()
	 */
	public function onPostScore(response:io.newgrounds.models.objects.Response, callbackParams:Object):Void {

		var result:io.newgrounds.models.results.ScoreBoard.postScoreResult = null;
		var score:io.newgrounds.models.objects.Score = null;
		var error = null;

		// Same two-level check as onScoresLoaded - see the note there.
		if (response == null || response.success !== true) {
			error = (response != null && response.error != null)
				? response.error : io.newgrounds.Errors.getError();
		} else {
			result = response.getResult();

			if (result == null) {
				error = io.newgrounds.Errors.getError(io.newgrounds.Errors.INVALID_RESPONSE);
			} else if (result.success !== true) {
				error = (result.error != null) ? result.error : io.newgrounds.Errors.getError();
			} else {
				score = result.score;
			}
		}

		if (callbackParams.callback != null) {
			callbackParams.callback.call(callbackParams.thisArg, score, error);
		}
	}

	/**
	 * Returns a string representation of this scoreboard.
	 */
	public function toString():String {
		var description:String = "ScoreBoard #";
		description += (this.id != 0) ? this.id : "0";
		description += " - ";
		description += (this.name != null && this.name.length > 0) ? this.name : "null";
		return description;
	}
}
