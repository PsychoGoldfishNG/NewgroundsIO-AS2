/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
 * Contains any icons associated with this user.
 */
class io.newgrounds.models.objects.UserIcons extends io.newgrounds.models.BaseObject {
	private var ___small:String;
	private var ___medium:String;
	private var ___large:String;

	/**
	 * Constructor 
	 * @param props An object of initial properties for this instance
	 */
	public function UserIcons(props:Object) {
		super();
		this.__object = 'UserIcons';
		this.__properties = this.__properties.concat(["small","medium","large"]);
		this.__required = [];
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	 * The URL of the user's small icon
	 */
	public function get small():String {
		return this.___small;
	}

	/**
	 * @private
	 */
	public function set small(___small:String) {
		this.___small = ___small;
	}
	/**
	 * The URL of the user's medium icon
	 */
	public function get medium():String {
		return this.___medium;
	}

	/**
	 * @private
	 */
	public function set medium(___medium:String) {
		this.___medium = ___medium;
	}
	/**
	 * The URL of the user's large icon
	 */
	public function get large():String {
		return this.___large;
	}

	/**
	 * @private
	 */
	public function set large(___large:String) {
		this.___large = ___large;
	}
}