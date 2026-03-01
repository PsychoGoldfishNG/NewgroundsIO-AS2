/**
 * checkSession
 *
 * Component: App.checkSession
 * Checks the validity of a session id and returns the results in a #Session object.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.App.checkSession extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================


	//==================== CONSTRUCTOR ====================

	public function checkSession() {
		super();

		// Set component-specific flags
		this.isSecure = false;
		this.requiresSession = true;
		this.redirect = false;
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
		return "component";
	}

	/**
	 * All property names for this component
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
