/**
 * BaseResult
 *
 * Base class for all component result models received from server
 */

class io.newgrounds.BaseResult extends io.newgrounds.BaseObject {

	//==================== PUBLIC PROPERTIES ====================

	/**
	 * Whether the component execution succeeded
	 */
	public var success:Boolean = false;

	//==================== CONSTRUCTOR ====================

	public function BaseResult() {
		super();
		this.success = false;
	}

	//==================== OVERRIDDEN METHODS ====================

	/**
	 * Override importFromObject to inject success
	 */
	public function importFromObject(importObject):Void {
		super.importFromObject(importObject);
		// Import success property if it exists, otherwise reset to false.
		// importFromObject is a full replace, not a patch (see BaseObject.md) -
		// an absent property must not leave a stale value from a prior import.
		this.success = (importObject.success != undefined) ? Boolean(importObject.success) : false;
	}
}
