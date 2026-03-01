/**
 * setDataResult
 *
 * Result for: CloudSave.setData
 * Contains the data returned by the CloudSave.setData API call
 */
import io.newgrounds.BaseResult;
import io.newgrounds.models.objects.SaveSlot;

class io.newgrounds.models.results.CloudSave.setDataResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * 
	 */
	public var slot:SaveSlot = null;


	//==================== CONSTRUCTOR ====================

	public function setDataResult() {
		super();
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
			slot: "SaveSlot"
		};
	}

	//==================== CUSTOM METHODS ====================
}
