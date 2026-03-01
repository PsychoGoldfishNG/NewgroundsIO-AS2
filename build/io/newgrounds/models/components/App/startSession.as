/**
 * startSession
 *
 * Component: App.startSession
 * Starts a new session for the application.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.App.startSession extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * If true, will create a new session even if the user already has an existing one.

Note: Any previous session ids will no longer be valid if this is used.
	 */
	public var force:Boolean = false;


	//==================== CONSTRUCTOR ====================

	public function startSession() {
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
		return "App.startSession";
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
		return ["force"];
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
