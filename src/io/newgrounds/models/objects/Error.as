/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;

class io.newgrounds.models.objects.Error extends io.newgrounds.models.BaseObject {
	private var ___message:String;
	private var ___code:Number;

	/**
	 * Constructor 
	 * @param props An object of initial properties for this instance
	 */
	public function Error(props:Object) {
		super();
		this.__object = 'Error';
		this.__properties = this.__properties.concat(["message","code"]);
		this.__required = [];
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.fillProperties(props);
	}
	/**
	 * Contains details about the error.
	 */
	public function get message():String {
		return this.___message;
	}

	/**
	 * @private
	 */
	public function set message(___message:String) {
		this.___message = ___message;
	}
	/**
	 * A code indicating the error type.
	 */
	public function get code():Number {
		return this.___code;
	}

	/**
	 * @private
	 */
	public function set code(___code:Number) {
		this.___code = ___code;
	}
}