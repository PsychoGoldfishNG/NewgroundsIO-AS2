/**
 * loadSlots
 *
 * Component: CloudSave.loadSlots
 * Returns a list of #saveslot objects.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.CloudSave.loadSlots extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The App ID of another, approved app to load slot data from.
	 */
	public var app_id:String = null;


	//==================== CONSTRUCTOR ====================

	public function loadSlots() {
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
		return "CloudSave.loadSlots";
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
		return ["app_id"];
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
