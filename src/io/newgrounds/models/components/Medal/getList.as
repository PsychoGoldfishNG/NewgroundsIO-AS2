/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the Medal.getList component.
 */
class io.newgrounds.models.components.Medal.getList extends io.newgrounds.models.BaseComponent {
	private var ___app_id:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function getList(props:Object) {
		super();
		this.__object = "Medal.getList";
		this.___app_id = null;
		this.__properties = this.__properties.concat(["app_id"]);
		this.__isSecure = false;
		this.__requireSession = false;
		this.__isRedirect = false;
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	* The App ID of another, approved app to load medals from.
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