
/**
 * Debug
 *
 * Contains extra debugging information.
 */
import io.newgrounds.BaseObject;

class io.newgrounds.models.objects.Debug extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * The time, in milliseconds, that it took to execute a request.
	 */
	public var exec_time:String = null;

	/**
	 * A copy of the request object that was posted to the server.
	 */
	public var request:io.newgrounds.models.objects.Request = null;


	//==================== CONSTRUCTOR ====================

	public function Debug() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Debug";
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
		return ["exec_time","request"];
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
			request: "Request"
		};
	}

	//==================== CUSTOM METHODS ====================
}
