/**
 * postScore
 *
 * Component: ScoreBoard.postScore
 * Posts a score to the specified scoreboard. Requires a session with a signed-in user attached; a session without one fails with a Login Required error.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.ScoreBoard.postScore extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The numeric ID of the scoreboard.
	 */
	public var id:Number = 0;

	/**
	 * The score value, as a whole number between -2147483648 and 2147483647. Fractional values are truncated toward zero, and values outside that range are clamped to the nearest limit, so round and range-check calculated scores before posting. On an incremental scoreboard the accumulated totals are held to the same range too. Shorter periods reset on their own, but the all-time total never does, so a player who reaches 2147483647 there stays pegged at it for good.
	 */
	public var value:Number = 0;

	/**
	 * An optional tag used to filter scores via ScoreBoard.getScores. Tags are matched as exact keys and matching is case-insensitive, so "Hard" and "hard" are the same tag. Tags are limited to 32 characters, and sticking to A-Z, a-z, 0-9 and _ . : - is recommended; other characters are accepted but may not match reliably.
	 */
	public var tag:String = null;


	//==================== CONSTRUCTOR ====================

	public function postScore() {
		super();

		// Set component-specific flags
		this.isSecure = true;
		this.requiresSession = true;
		this.requiresLogin = true;
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
