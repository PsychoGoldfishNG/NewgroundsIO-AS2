/**
 * getListResult
 *
 * Result for: Medal.getList
 * Contains the data returned by the Medal.getList API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.Medal.getListResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * An array of medal objects.
	 */
	public var medals:Array = null;

	/**
	 * The App ID of any external app these medals were loaded from.
	 */
	public var app_id:String = null;


	//==================== CONSTRUCTOR ====================

	public function getListResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Medal.getList";
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
		return ["medals","app_id"];
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
			"medals": "array-of-Medal"
		};
	}

	//==================== CUSTOM METHODS ====================
}
