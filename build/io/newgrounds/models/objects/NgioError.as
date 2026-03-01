
/**
 * NgioError
 *
 * 
 */
import io.newgrounds.BaseObject;

class io.newgrounds.models.objects.NgioError extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * Contains details about the error.
	 */
	public var message:String = null;

	/**
	 * A code indicating the error type.
	 */
	public var code:Number = 0;


	//==================== CONSTRUCTOR ====================

	public function NgioError() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Error";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "object";
	}

	/**
	 * All property names for this object
	 */
	public function get propertyNames():Array {
		return ["message","code"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return [];
	}

	/**
	 * Type casting map for deserializing properties
	 */
	public function get castTypes():Object {
		return {
		};
	}

	//==================== CUSTOM METHODS ====================

	/**
	 * Returns the error message if set, otherwise "null".
	 */
	public function toString():String {
		return (this.message != null && this.message.length > 0) ? this.message : "null";
	}
}
