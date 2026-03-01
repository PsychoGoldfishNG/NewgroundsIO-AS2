/**
 * clearSlotResult
 *
 * Result for: CloudSave.clearSlot
 * Contains the data returned by the CloudSave.clearSlot API call
 */
import io.newgrounds.BaseResult;
import io.newgrounds.models.objects.SaveSlot;

class io.newgrounds.models.results.CloudSave.clearSlotResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * A #SaveSlot object.
	 */
	public var slot:SaveSlot = null;


	//==================== CONSTRUCTOR ====================

	public function clearSlotResult() {
		super();
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
		return "result";
	}

	/**
	 * All property names for this result
	 */
	public function get propertyNames():Array {
		return ["slot"];
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
