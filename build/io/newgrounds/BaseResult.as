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
		if (importObject.success != undefined) {
			this.success = Boolean(importObject.success);
		}
	}
}
