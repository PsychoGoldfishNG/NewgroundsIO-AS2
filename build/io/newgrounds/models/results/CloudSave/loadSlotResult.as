/**
 * loadSlotResult
 *
 * Result for: CloudSave.loadSlot
 * Contains the data returned by the CloudSave.loadSlot API call
 */
import io.newgrounds.BaseResult;
import io.newgrounds.models.objects.SaveSlot;

class io.newgrounds.models.results.CloudSave.loadSlotResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * A #SaveSlot object.
	 */
	public var slot:SaveSlot = null;

	/**
	 * The App ID the loaded slot belongs to, if loaded from an external app.
	 */
	public var app_id:String = null;


	//==================== CONSTRUCTOR ====================

	public function loadSlotResult() {
		super();
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
		return "result";
	}

	/**
	 * All property names for this result
	 */
	public function get propertyNames():Array {
		return ["slot","app_id"];
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
			"slot": "SaveSlot"
		};
	}

	//==================== CUSTOM METHODS ====================
}
