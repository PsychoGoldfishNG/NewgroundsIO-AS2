/**
 * pingResult
 *
 * Result for: Gateway.ping
 * Contains the data returned by the Gateway.ping API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.Gateway.pingResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * Will always return a value of 'pong'
	 */
	public var pong:String = null;


	//==================== CONSTRUCTOR ====================

	public function pingResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Gateway.ping";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "result";
	}

	/**
	 * All property names for this result
	 */
	public function get propertyNames():Array {
		return ["pong"];
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
}
