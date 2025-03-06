/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Medal.getMedalScore component is called
 */
class io.newgrounds.models.results.Medal.getMedalScore extends io.newgrounds.models.BaseResult {
	private var ___medal_score:Number;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getMedalScore(props:Object) {
		super();
		this.__object = "Medal.getMedalScore";
		this.__properties = this.__properties.concat(["medal_score"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}

	/**
	* The user's medal score.
	*/
	public function get medal_score():Number {
		return this.___medal_score;
	}

	/**
	* @private
	*/
	public function set medal_score(___medal_score:Number) {
		this.___medal_score = ___medal_score;
	}
}