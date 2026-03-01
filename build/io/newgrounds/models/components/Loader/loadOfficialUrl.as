/**
 * loadOfficialUrl
 *
 * Component: Loader.loadOfficialUrl
 * Loads the official URL where the latest version of your app can be found (as defined in your "Official URLs" settings), and logs a referral to your API stats.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.Loader.loadOfficialUrl extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The domain hosting your app. Example: "www.somesite.com", "localHost"
	 */
	public var host:String = null;

	/**
	 * Set this to false to skip logging this as a referral event.
	 */
	public var log_stat:Boolean = true;


	//==================== CONSTRUCTOR ====================

	public function loadOfficialUrl() {
		super();

		// Set component-specific flags
		this.isSecure = false;
		this.requiresSession = false;
		this.redirect = true;
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Loader.loadOfficialUrl";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "component";
	}

	/**
	 * All property names for this component
	 */
	public function get propertyNames():Array {
		return ["host","redirect","log_stat"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["host"];
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
