/**
 * getScores
 *
 * Component: ScoreBoard.getScores
 * Loads a list of #Score objects from a scoreboard. Use 'skip' and 'limit' for getting different pages.
 */
import io.newgrounds.BaseComponent;

class io.newgrounds.models.components.ScoreBoard.getScores extends io.newgrounds.BaseComponent {

	//==================== PROPERTIES ====================

	/**
	 * The numeric ID of the scoreboard.
	 */
	public var id:Number = NaN;

	/**
	 * The time-frame to pull scores from (see notes for acceptable values).
	 */
	public var period:String = null;

	/**
	 * A tag to filter results by.
	 */
	public var tag:String = null;

	/**
	 * If set to true, only social scores will be loaded (scores by the user and their friends). This param will be ignored if there is no valid session id and the 'user' param is absent.
	 */
	public var social:Boolean = false;

	/**
	 * A user's ID or name.  If 'social' is true, this user and their friends will be included. Otherwise, only scores for this user will be loaded. If this param is missing and there is a valid session id, that user will be used by default.
	 */
	public var user = null;

	/**
	 * An integer indicating the number of scores to skip before starting the list. Default = 0.
	 */
	public var skip:Number = 0;

	/**
	 * An integer indicating the number of scores to include in the list. Default = 10.
	 */
	public var limit:Number = 10;

	/**
	 * The App ID of another, approved app to load scores from.
	 */
	public var app_id:String = null;


	//==================== CONSTRUCTOR ====================

	public function getScores() {
		super();

		// Set component-specific flags
		this.isSecure = false;
		this.requiresSession = false;
		this.redirect = false;
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "ScoreBoard.getScores";
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
		return ["id","period","tag","social","user","skip","limit","app_id"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["id"];
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
