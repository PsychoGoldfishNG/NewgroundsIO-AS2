/**
 * getVersionResult
 *
 * Result for: Gateway.getVersion
 * Contains the data returned by the Gateway.getVersion API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.Gateway.getVersionResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * The version number (in X.Y.Z format).
	 */
	public var version:String = null;


	//==================== CONSTRUCTOR ====================

	public function getVersionResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Gateway.getVersion";
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
		return ["version"];
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
