/**
 * checkSessionResult
 *
 * Result for: App.checkSession
 * Contains the data returned by the App.checkSession API call
 */
import io.newgrounds.BaseResult;
import io.newgrounds.models.objects.Session;

class io.newgrounds.models.results.App.checkSessionResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * 
	 */
	public var session:Session = null;


	//==================== CONSTRUCTOR ====================

	public function checkSessionResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "App.checkSession";
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
		return ["session"];
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
			"session": "Session"
		};
	}

	//==================== CUSTOM METHODS ====================
}
