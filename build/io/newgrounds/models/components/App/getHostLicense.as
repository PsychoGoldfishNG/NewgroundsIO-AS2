/**
 * getHostLicense
 *
 * Component: App.getHostLicense
 * Checks a client-side host domain against domains defined in your "Game Protection" settings.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.App.getHostLicense extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The host domain to check (ei, somesite.com).
	 */
	public var host:String = null;


	//==================== CONSTRUCTOR ====================

	public function getHostLicense() {
		super();

		// Set component-specific flags
		this.isSecure = false;
		this.requiresSession = false;
		this.redirect = false;
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
		return "component";
	}

	/**
	 * All property names for this component
	 */
	public function get propertyNames():Array {
		return ["host"];
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
