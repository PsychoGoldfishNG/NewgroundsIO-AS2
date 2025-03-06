/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the ScoreBoard.getScores component.
 */
class io.newgrounds.models.components.ScoreBoard.getScores extends io.newgrounds.models.BaseComponent {
	private var ___id:Number;
	private var ___period:String;
	private var ___tag:String;
	private var ___social:Boolean;
	private var ___user:Object;
	private var ___skip:Number;
	private var ___limit:Number;
	private var ___app_id:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function getScores(props:Object) {
		super();
		this.__object = "ScoreBoard.getScores";
		this.___id = null;
		this.___period = null;
		this.___tag = null;
		this.___social = null;
		this.___user = null;
		this.___skip = 0;
		this.___limit = 10;
		this.___app_id = null;
		this.__properties = this.__properties.concat(["id","period","tag","social","user","skip","limit","app_id"]);
		this.__isSecure = false;
		this.__requireSession = false;
		this.__isRedirect = false;
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	* The numeric ID of the scoreboard.
	*/
	public function get id():Number {
		return this.___id;
	}

	/**
	* @private
	*/
	public function set id(___id:Number) {
		this.___id = ___id;
	}
	/**
	* The time-frame to pull scores from (see notes for acceptable values).
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
	* A tag to filter results by.
	*/
	public function get tag():String {
		return this.___tag;
	}

	/**
	* @private
	*/
	public function set tag(___tag:String) {
		this.___tag = ___tag;
	}
	/**
	* If set to true, only social scores will be loaded (scores by the user and their friends). This param will be ignored if there is no valid session id and the 'user' param is absent.
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
	* A user's ID or name.  If 'social' is true, this user and their friends will be included. Otherwise, only scores for this user will be loaded. If this param is missing and there is a valid session id, that user will be used by default.
	*/
	public function get user():Object {
		return this.___user;
	}

	/**
	* @private
	*/
	public function set user(___user:Object) {
		this.___user = ___user;
	}
	/**
	* An integer indicating the number of scores to skip before starting the list. Default = 0.
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
	* An integer indicating the number of scores to include in the list. Default = 10.
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
	* The App ID of another, approved app to load scores from.
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