
/**
 * User
 *
 * Contains information about a user.
 */
import io.newgrounds.BaseObject;

class io.newgrounds.models.objects.User extends io.newgrounds.BaseObject {

	//==================== PROPERTIES ====================

	/**
	 * The user's numeric ID.
	 */
	public var id:Number = 0;

	/**
	 * The user's textual name.
	 */
	public var name:String = null;

	/**
	 * The URL to the user's profile.
	 */
	public var url:String = null;

	/**
	 * Returns true if the user currently has a Newgrounds Supporter upgrade.
	 */
	public var supporter:Boolean = false;


	//==================== CONSTRUCTOR ====================

	public function User() {
		super();
	}

	//==================== ABSTRACT PROPERTY OVERRIDES ====================

	/**
	 * Object name for debugging and type checking
	 */
	public function get objectName():String {
		return "User";
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
		return ["id","name","url","supporter"];
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

	/**
	 * Returns a string representation of this user.
	 */
	public function toString():String {
		return (this.name != null && this.name.length > 0) ? this.name : "null";
	}
}
