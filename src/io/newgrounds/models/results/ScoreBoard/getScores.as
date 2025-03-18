/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when ScoreBoard.getScores component is called
 */
class io.newgrounds.models.results.ScoreBoard.getScores extends io.newgrounds.models.BaseResult {
	private var ___period:String;
	private var ___social:Boolean;
	private var ___limit:Number;
	private var ___skip:Number;
	private var ___scoreboard:io.newgrounds.models.objects.ScoreBoard;
	private var ___scores:Array;
	private var ___user:io.newgrounds.models.objects.User;
	private var ___app_id:String;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getScores(props:Object) {
		super();
		this.__object = "ScoreBoard.getScores";
		this.__properties = this.__properties.concat(["period","social","limit","skip","scoreboard","scores","user","app_id"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.__castTypes.scoreboard = io.newgrounds.models.objects.ScoreBoard;
		this.__castTypes.scores = io.newgrounds.models.objects.Score;
		this.__arrayTypes.scores = true;
		this.__castTypes.user = io.newgrounds.models.objects.User;
		this.fillProperties(props);
	}

	/**
	* The time-frame the scores belong to. See notes for acceptable values.
	*/
	public function get period():String {
		return this.___period;
	}

	/**
	* @private
	*/
	public function set period(___period:String) {
		this.___period = ___period;
	}
	/**
	* Will return true if scores were loaded in social context ('social' set to true and a session or 'user' were provided).
	*/
	public function get social():Boolean {
		return this.___social;
	}

	/**
	* @private
	*/
	public function set social(___social:Boolean) {
		this.___social = ___social;
	}
	/**
	* The query limit that was used.
	*/
	public function get limit():Number {
		return this.___limit;
	}

	/**
	* @private
	*/
	public function set limit(___limit:Number) {
		this.___limit = ___limit;
	}
	/**
	* The query skip that was used.
	*/
	public function get skip():Number {
		return this.___skip;
	}

	/**
	* @private
	*/
	public function set skip(___skip:Number) {
		this.___skip = ___skip;
	}
	/**
	* The io.newgrounds.models.objects.ScoreBoard being queried.
	*/
	public function get scoreboard():io.newgrounds.models.objects.ScoreBoard {
		return this.___scoreboard;
	}

	/**
	* @private
	*/
	public function set scoreboard(___scoreboard:io.newgrounds.models.objects.ScoreBoard) {
		this.___scoreboard = ___scoreboard;
	}
	/**
	* An array of io.newgrounds.models.objects.Score objects.
	*/
	public function get scores():Array {
		return this.___scores;
	}

	/**
	* @private
	*/
	public function set scores(___scores:Array) {
		if (___scores instanceof Array) {
            var newArr = [];
            var val;
            for (var i=0; i<___scores.length; i++) {
                newArr.push(this.castValue('scores', ___scores[i]));
            }
            this.___scores = newArr;
        } else {
            this.___scores = ___scores;
        }
	}
	/**
	* The io.newgrounds.models.objects.User the score list is associated with (either as defined in the 'user' param, or extracted from the current session when 'social' is set to true)
	*/
	public function get user():io.newgrounds.models.objects.User {
		return this.___user;
	}

	/**
	* @private
	*/
	public function set user(___user:io.newgrounds.models.objects.User) {
		this.___user = ___user;
	}
	/**
	* The App ID of any external app these scores were loaded from.
	*/
	public function get app_id():String {
		return this.___app_id;
	}

	/**
	* @private
	*/
	public function set app_id(___app_id:String) {
		this.___app_id = ___app_id;
	}
}