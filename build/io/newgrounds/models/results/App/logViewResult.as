/**
 * logViewResult
 *
 * Result for: App.logView
 * Contains the data returned by the App.logView API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.App.logViewResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================


	//==================== CONSTRUCTOR ====================

	public function logViewResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "App.logView";
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
		return [];
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
