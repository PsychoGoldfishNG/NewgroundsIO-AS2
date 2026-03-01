/**
 * getDatetimeResult
 *
 * Result for: Gateway.getDatetime
 * Contains the data returned by the Gateway.getDatetime API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.Gateway.getDatetimeResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * The server's date and time in ISO 8601 format.
	 */
	public var datetime:String = null;

	/**
	 * The current UNIX timestamp on the server.
	 */
	public var timestamp:Number = NaN;


	//==================== CONSTRUCTOR ====================

	public function getDatetimeResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Gateway.getDatetime";
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
		return ["datetime","timestamp"];
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
