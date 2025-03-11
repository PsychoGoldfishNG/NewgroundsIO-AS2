/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

/**
 * Contains information about a user.
 */
class io.newgrounds.models.objects.User extends io.newgrounds.models.BaseObject {
	private var ___id:Number;
	private var ___name:String;
	private var ___url:String;
	private var ___supporter:Boolean;

	/**
	 * Constructor 
	 * @param props An object of initial properties for this instance
	 */
	public function User(props:Object) {
		super();
		this.__object = 'User';
		this.__properties = this.__properties.concat(["id","name","url","supporter"]);
		this.__required = [];
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	 * The user's numeric ID.
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
	 * The user's textual name.
	 */
	public function get name():String {
		return this.___name;
	}

	/**
	 * @private
	 */
	public function set name(___name:String) {
		this.___name = ___name;
	}
	/**
	 * The URL to the user's profile.
	 */
	public function get url():String {
		return this.___url;
	}

	/**
	 * @private
	 */
	public function set url(___url:String) {
		this.___url = ___url;
	}
	/**
	 * Returns true if the user currently has a Newgrounds Supporter upgrade.
	 */
	public function get supporter():Boolean {
		return this.___supporter;
	}

	/**
	 * @private
	 */
	public function set supporter(___supporter:Boolean) {
		this.___supporter = ___supporter;
	}
}