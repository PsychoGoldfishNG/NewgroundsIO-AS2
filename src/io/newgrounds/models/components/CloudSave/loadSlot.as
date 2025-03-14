/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the CloudSave.loadSlot component.
 */
class io.newgrounds.models.components.CloudSave.loadSlot extends io.newgrounds.models.BaseComponent {
	private var ___id:Number;
	private var ___app_id:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function loadSlot(props:Object) {
		super();
		this.__object = "CloudSave.loadSlot";
		this.___id = null;
		this.___app_id = null;
		this.__properties = this.__properties.concat(["id","app_id"]);
		this.__isSecure = false;
		this.__requireSession = true;
		this.__isRedirect = false;
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	* The slot number.
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
	* The App ID of another, approved app to load slot data from.
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