/**
 * getVersion
 *
 * Component: Gateway.getVersion
 * Returns the current version of the Newgrounds.io gateway.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.Gateway.getVersion extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================


	//==================== CONSTRUCTOR ====================

	public function getVersion() {
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
		return "Gateway.getVersion";
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
