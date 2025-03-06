/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the ScoreBoard.postScore component.
 */
class io.newgrounds.models.components.ScoreBoard.postScore extends io.newgrounds.models.BaseComponent {
	private var ___id:Number;
	private var ___value:Number;
	private var ___tag:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function postScore(props:Object) {
		super();
		this.__object = "ScoreBoard.postScore";
		this.___id = null;
		this.___value = null;
		this.___tag = null;
		this.__properties = this.__properties.concat(["id","value","tag"]);
		this.__isSecure = true;
		this.__requireSession = true;
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
	* The int value of the score.
	*/
	public function get value():Number {
		return this.___value;
	}

	/**
	* @private
	*/
	public function set value(___value:Number) {
		this.___value = ___value;
	}
	/**
	* An optional tag that can be used to filter scores via ScoreBoard.getScores
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
}