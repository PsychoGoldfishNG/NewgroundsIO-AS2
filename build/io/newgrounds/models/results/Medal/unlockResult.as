/**
 * unlockResult
 *
 * Result for: Medal.unlock
 * Contains the data returned by the Medal.unlock API call
 */
import io.newgrounds.BaseResult;
import io.newgrounds.models.objects.Medal;

class io.newgrounds.models.results.Medal.unlockResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * The #Medal that was unlocked.
	 */
	public var medal:Medal = null;

	/**
	 * The user's new medal score.
	 */
	public var medal_score:Number = 0;


	//==================== CONSTRUCTOR ====================

	public function unlockResult() {
		super();
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
		return "result";
	}

	/**
	 * All property names for this result
	 */
	public function get propertyNames():Array {
		return ["medal","medal_score"];
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
			medal: "Medal"
		};
	}

	//==================== CUSTOM METHODS ====================
}
