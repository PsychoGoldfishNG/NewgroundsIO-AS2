/**
 * getCurrentVersionResult
 *
 * Result for: App.getCurrentVersion
 * Contains the data returned by the App.getCurrentVersion API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.App.getCurrentVersionResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * The version number of the app as defined in your "Version Control" settings.
	 */
	public var current_version:String = null;

	/**
	 * Notes whether the client-side app is using a lower version number.
	 */
	public var client_deprecated:Boolean = false;


	//==================== CONSTRUCTOR ====================

	public function getCurrentVersionResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "App.getCurrentVersion";
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
		return ["current_version","client_deprecated"];
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
