/**
 * unlock
 *
 * Component: Medal.unlock
 * Unlocks a medal.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.Medal.unlock extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The numeric ID of the medal to unlock.
	 */
	public var id:Number = NaN;


	//==================== CONSTRUCTOR ====================

	public function unlock() {
		super();

		// Set component-specific flags
		this.isSecure = true;
		this.requiresSession = true;
		this.redirect = false;
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Medal.unlock";
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
		return ["id"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["id"];
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
