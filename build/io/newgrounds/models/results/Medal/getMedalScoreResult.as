/**
 * getMedalScoreResult
 *
 * Result for: Medal.getMedalScore
 * Contains the data returned by the Medal.getMedalScore API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.Medal.getMedalScoreResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * The user's medal score.
	 */
	public var medal_score:Number = NaN;


	//==================== CONSTRUCTOR ====================

	public function getMedalScoreResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Medal.getMedalScore";
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
		return ["medal_score"];
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
