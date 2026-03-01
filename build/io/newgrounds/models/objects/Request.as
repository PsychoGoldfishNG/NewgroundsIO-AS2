
/**
 * Request
 *
 * A top-level wrapper containing any information needed to authenticate the application/user and any component calls being made.
 */
import io.newgrounds.BaseObject;

class io.newgrounds.models.objects.Request extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * Your application's unique ID.
	 */
	public var app_id:String = null;

	/**
	 * A #Execute object, or array of one-or-more #Execute objects.
	 */
	public var execute = null;

	/**
	 * An optional login session id. Components that save and unlock things to a user account will require this.
	 */
	public var session_id:String = null;

	/**
	 * If set to true, calls will be executed in debug mode.
	 */
	public var debug:Boolean = false;

	/**
	 * An optional value that will be returned, verbatim, in the #Response object.
	 */
	public var echo = null;


	/**
	 * Array of Execute objects (for mixed type handling with single execute)
	 */
	public var executeList:Array;

	//==================== CONSTRUCTOR ====================

	public function Request() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "Request";
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
		return ["app_id","execute","session_id","debug","echo"];
	}

	/**
	 * Required properties for validation
	 */
	public function get requiredProperties():Array {
		return ["app_id","execute"];
	}

	/**
	 * Type casting map for deserializing properties
	 */
	public function get castTypes():Object {
		return {
			execute: "array-of-Execute"
		};
	}

	//==================== CUSTOM METHODS ====================

	/**
	 * Sets a single Execute object and clears the list
	 *
	 * @param executeObject A single Execute instance
	 */
	public function setExecute(executeObject):Void {
		this.execute = executeObject;
		this.executeList = null;
	}

	/**
	 * Sets an array of Execute objects and clears the single value
	 *
	 * @param executeArray An array of Execute instances
	 */
	public function setExecuteList(executeArray:Array):Void {
		this.executeList = executeArray;
		this.execute = null;
	}

	/**
	 * Checks if execute is in array format
	 *
	 * @return true if using list format, false if using single value
	 */
	public function executeIsArray():Boolean {
		return this.executeList != null && this.executeList.length > 0;
	}

	/**
	 * Gets the single Execute object
	 *
	 * @return Single Execute instance or null
	 */
	public function getExecute() {
		return this.execute;
	}

	/**
	 * Gets the Execute objects array
	 *
	 * @return Array of Execute instances or null
	 */
	public function getExecuteList():Array {
		return this.executeList;
	}
}
