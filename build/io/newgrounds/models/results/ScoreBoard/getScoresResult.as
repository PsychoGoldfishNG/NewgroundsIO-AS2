/**
 * getScoresResult
 *
 * Result for: ScoreBoard.getScores
 * Contains the data returned by the ScoreBoard.getScores API call
 */
import io.newgrounds.BaseResult;
import io.newgrounds.models.objects.ScoreBoard;
import io.newgrounds.models.objects.User;

class io.newgrounds.models.results.ScoreBoard.getScoresResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * The time-frame the scores belong to. See notes for acceptable values.
	 */
	public var period:String = null;

	/**
	 * Will return true if scores were loaded in social context ('social' set to true and a session or 'user' were provided).
	 */
	public var social:Boolean = false;

	/**
	 * The query limit that was used.
	 */
	public var limit:Number = NaN;

	/**
	 * The query skip that was used.
	 */
	public var skip:Number = NaN;

	/**
	 * The #ScoreBoard being queried.
	 */
	public var scoreboard:ScoreBoard = null;

	/**
	 * An array of #Score objects.
	 */
	public var scores:Array = null;

	/**
	 * The #User the score list is associated with (either as defined in the 'user' param, or extracted from the current session when 'social' is set to true)
	 */
	public var user:User = null;

	/**
	 * The App ID of any external app these scores were loaded from.
	 */
	public var app_id:String = null;


	//==================== CONSTRUCTOR ====================

	public function getScoresResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "ScoreBoard.getScores";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "result";
	}

	/**
	 * All property names for this result
	 */
	public function get propertyNames():Array {
		return ["period","social","limit","skip","scoreboard","scores","user","app_id"];
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
			scoreboard: "ScoreBoard",
			scores: "array-of-Score",
			user: "User"
		};
	}

	//==================== CUSTOM METHODS ====================
}
