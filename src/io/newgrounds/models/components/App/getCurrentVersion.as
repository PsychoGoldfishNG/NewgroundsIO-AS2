/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the App.getCurrentVersion component.
 */
class io.newgrounds.models.components.App.getCurrentVersion extends io.newgrounds.models.BaseComponent {
	private var ___version:String;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function getCurrentVersion(props:Object) {
		super();
		this.__object = "App.getCurrentVersion";
		this.___version = "0.0.0";
		this.__properties = this.__properties.concat(["version"]);
		this.__isSecure = false;
		this.__requireSession = false;
		this.__isRedirect = false;
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	* The version number (in "X.Y.Z" format) of the client-side app. (default = "0.0.0")
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