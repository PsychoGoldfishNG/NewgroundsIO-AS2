/**
 * loadSlot
 *
 * Component: CloudSave.loadSlot
 * Returns a specific #saveslot object.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.CloudSave.loadSlot extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The slot number.
	 */
	public var id:Number = NaN;

	/**
	 * The App ID of another, approved app to load slot data from.
	 */
	public var app_id:String = null;


	//==================== CONSTRUCTOR ====================

	public function loadSlot() {
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
		return "CloudSave.loadSlot";
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
		return ["id","app_id"];
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
