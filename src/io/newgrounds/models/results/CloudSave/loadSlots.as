/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when CloudSave.loadSlots component is called
 */
class io.newgrounds.models.results.CloudSave.loadSlots extends io.newgrounds.models.BaseResult 
{
    private var ___slots:Array;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function loadSlots(props:Object) 
    {
		super();

		this.__object = "CloudSave.loadSlots";
		this.__properties = this.__properties.concat(["slots"]);

				this.__castTypes = {};

		this.__castTypes.slots = io.newgrounds.models.objects.SaveSlot;

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
	public function set slots(___slots:Array)
    {
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


}
