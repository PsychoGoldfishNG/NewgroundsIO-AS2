/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the Medal.unlock component.
 */
class io.newgrounds.models.components.Medal.unlock extends io.newgrounds.models.BaseComponent {
	private var ___id:Number;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function unlock(props:Object) {
		super();
		this.__object = "Medal.unlock";
		this.___id = null;
		this.__properties = this.__properties.concat(["id"]);
		this.__isSecure = true;
		this.__requireSession = true;
		this.__isRedirect = false;
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	* The numeric ID of the medal to unlock.
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
}