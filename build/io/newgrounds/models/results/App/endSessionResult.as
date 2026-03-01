/**
 * endSessionResult
 *
 * Result for: App.endSession
 * Contains the data returned by the App.endSession API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.App.endSessionResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================


	//==================== CONSTRUCTOR ====================

	public function endSessionResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "App.endSession";
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
