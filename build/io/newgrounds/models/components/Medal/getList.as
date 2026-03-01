/**
 * getList
 *
 * Component: Medal.getList
 * Loads a list of #Medal objects.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.Medal.getList extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The App ID of another, approved app to load medals from.
	 */
	public var app_id:String = null;


	//==================== CONSTRUCTOR ====================

	public function getList() {
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
		return "Medal.getList";
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
