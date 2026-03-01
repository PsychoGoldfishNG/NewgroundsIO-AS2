/**
 * getHostLicenseResult
 *
 * Result for: App.getHostLicense
 * Contains the data returned by the App.getHostLicense API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.App.getHostLicenseResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * 
	 */
	public var host_approved:Boolean = false;


	//==================== CONSTRUCTOR ====================

	public function getHostLicenseResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "App.getHostLicense";
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
		return ["host_approved"];
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
