/**
 * clearSlot
 *
 * Component: CloudSave.clearSlot
 * Deletes all data from a save slot.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.CloudSave.clearSlot extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The slot number.
	 */
	public var id:Number = 0;


	//==================== CONSTRUCTOR ====================

	public function clearSlot() {
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
		return "CloudSave.clearSlot";
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
