/**
 * getBoardsResult
 *
 * Result for: ScoreBoard.getBoards
 * Contains the data returned by the ScoreBoard.getBoards API call
 */
import io.newgrounds.BaseResult;

class io.newgrounds.models.results.ScoreBoard.getBoardsResult extends io.newgrounds.BaseResult {

	//==================== PROPERTIES ====================

	/**
	 * An array of #ScoreBoard objects.
	 */
	public var scoreboards:Array = null;


	//==================== CONSTRUCTOR ====================

	public function getBoardsResult() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "ScoreBoard.getBoards";
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
		return ["scoreboards"];
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
			scoreboards: "array-of-ScoreBoard"
		};
	}

	//==================== CUSTOM METHODS ====================
}
