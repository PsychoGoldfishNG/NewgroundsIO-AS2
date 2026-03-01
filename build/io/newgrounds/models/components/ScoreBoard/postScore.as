/**
 * postScore
 *
 * Component: ScoreBoard.postScore
 * Posts a score to the specified scoreboard.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.ScoreBoard.postScore extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The numeric ID of the scoreboard.
	 */
	public var id:Number = 0;

	/**
	 * The int value of the score.
	 */
	public var value:Number = 0;

	/**
	 * An optional tag that can be used to filter scores via ScoreBoard.getScores
	 */
	public var tag:String = null;


	//==================== CONSTRUCTOR ====================

	public function postScore() {
		super();

		// Set component-specific flags
		this.isSecure = true;
		this.requiresSession = true;
		this.redirect = false;
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "ScoreBoard.postScore";
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
		return ["id","value","tag"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["id","value"];
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
