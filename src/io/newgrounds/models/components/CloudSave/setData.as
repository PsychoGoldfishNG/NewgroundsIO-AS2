/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the CloudSave.setData component.
 */
class io.newgrounds.models.components.CloudSave.setData extends io.newgrounds.models.BaseComponent {
	private var ___id:Number;
	private var ___data:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function setData(props:Object) {
		super();
		this.__object = "CloudSave.setData";
		this.___id = null;
		this.___data = null;
		this.__properties = this.__properties.concat(["id","data"]);
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
	* The data you want to save.
	*/
	public function get data():String {
		return this.___data;
	}

	/**
	* @private
	*/
	public function set data(___data:String) {
		this.___data = ___data;
	}
}