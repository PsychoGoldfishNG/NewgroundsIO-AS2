/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when App.getHostLicense component is called
 */
class io.newgrounds.models.results.App.getHostLicense extends io.newgrounds.models.BaseResult {
	private var ___host_approved:Boolean;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getHostLicense(props:Object) {
		super();
		this.__object = "App.getHostLicense";
		this.__properties = this.__properties.concat(["host_approved"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}

	public function get host_approved():Boolean {
		return this.___host_approved;
	}

	/**
	* @private
	*/
	public function set host_approved(___host_approved:Boolean) {
		this.___host_approved = ___host_approved;
	}
}