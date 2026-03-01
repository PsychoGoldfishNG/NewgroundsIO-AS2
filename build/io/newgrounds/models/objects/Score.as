
/**
 * Score
 *
 * Contains information about a score posted to a scoreboard.
 */
import io.newgrounds.BaseObject;

class io.newgrounds.models.objects.Score extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * The user who earned this score. If this property is absent, the score belongs to the active user.
	 */
	public var user:io.newgrounds.models.objects.User = null;

	/**
	 * The integer value of the score.
	 */
	public var value:Number = NaN;

	/**
	 * The score value in the format selected in your scoreboard settings.
	 */
	public var formatted_value:String = null;

	/**
	 * The tag attached to this score (if any).
	 */
	public var tag:String = null;


	//==================== CONSTRUCTOR ====================

	public function Score() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Score";
	}

	/**
	 * Object type identifier
	 */
	public function get objectType():String {
		return "object";
	}

	/**
	 * All property names for this object
	 */
	public function get propertyNames():Array {
		return ["user","value","formatted_value","tag"];
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
			user: "User"
		};
	}

	//==================== CUSTOM METHODS ====================

	/**
	 * Returns a string representation of this score.
	 */
	public function toString():String {
		return (this.value != 0) ? "Score Value: " + this.value : "Score Value: 0";
	}
}
