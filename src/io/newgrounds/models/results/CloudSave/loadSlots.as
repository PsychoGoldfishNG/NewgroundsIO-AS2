/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when CloudSave.loadSlots component is called
 */
class io.newgrounds.models.results.CloudSave.loadSlots extends io.newgrounds.models.BaseResult {
	private var ___slots:Array;
	private var ___app_id:String;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function loadSlots(props:Object) {
		super();
		this.__object = "CloudSave.loadSlots";
		this.__properties = this.__properties.concat(["slots","app_id"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.__castTypes.slots = io.newgrounds.models.objects.SaveSlot;
		this.__arrayTypes.slots = true;
		this.fillProperties(props);
	}

	/**
	* An array of io.newgrounds.models.objects.SaveSlot objects.
	*/
	public function get slots():Array {
		return this.___slots;
	}

	/**
	* @private
	*/
	public function set slots(___slots:Array) {
		if (___slots instanceof Array) {
            var newArr = [];
            var val;
            for (var i=0; i<___slots.length; i++) {
                newArr.push(this.castValue('slots', ___slots[i]));
            }
            this.___slots = newArr;
        } else {
            this.___slots = ___slots;
        }
	}
	/**
	* The App ID of another, approved app to load scores from.
	*/
	public function get app_id():String {
		return this.___app_id;
	}

	/**
	* @private
	*/
	public function set app_id(___app_id:String) {
		this.___app_id = ___app_id;
	}
}