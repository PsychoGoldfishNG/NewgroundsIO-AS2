/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Gateway.getVersion component is called
 */
class io.newgrounds.models.results.Gateway.getVersion extends io.newgrounds.models.BaseResult {
	private var ___version:String;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getVersion(props:Object) {
		super();
		this.__object = "Gateway.getVersion";
		this.__properties = this.__properties.concat(["version"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}

	/**
	* The version number (in X.Y.Z format).
	*/
	public function get version():String {
		return this.___version;
	}

	/**
	* @private
	*/
	public function set version(___version:String) {
		this.___version = ___version;
	}
}