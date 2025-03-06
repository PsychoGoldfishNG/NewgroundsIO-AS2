/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Event.logEvent component is called
 */
class io.newgrounds.models.results.Event.logEvent extends io.newgrounds.models.BaseResult {
	private var ___event_name:String;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function logEvent(props:Object) {
		super();
		this.__object = "Event.logEvent";
		this.__properties = this.__properties.concat(["event_name"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}

	public function get event_name():String {
		return this.___event_name;
	}

	/**
	* @private
	*/
	public function set event_name(___event_name:String) {
		this.___event_name = ___event_name;
	}
}