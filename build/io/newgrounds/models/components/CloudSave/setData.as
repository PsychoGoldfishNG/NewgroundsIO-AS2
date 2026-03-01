/**
 * setData
 *
 * Component: CloudSave.setData
 * Saves data to a save slot. Any existing data will be replaced.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.CloudSave.setData extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The slot number.
	 */
	public var id:Number = NaN;

	/**
	 * The data you want to save.
	 */
	public var data:String = null;


	//==================== CONSTRUCTOR ====================

	public function setData() {
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
		return "CloudSave.setData";
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
		return ["id","data"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["id","data"];
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
