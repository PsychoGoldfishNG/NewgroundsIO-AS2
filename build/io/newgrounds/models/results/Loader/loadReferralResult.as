/**
 * loadReferralResult
 *
 * Result for: Loader.loadReferral
 * Contains the data returned by the Loader.loadReferral API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.Loader.loadReferralResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * The URL to redirect to. (This will only be returned if the redirect param is set to false.)
	 */
	public var url:String = null;


	//==================== CONSTRUCTOR ====================

	public function loadReferralResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Loader.loadReferral";
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
		return ["url"];
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
