/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Medal.getList component is called
 */
class io.newgrounds.models.results.Medal.getList extends io.newgrounds.models.BaseResult 
{
    private var ___medals:Array;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getList(props:Object) 
    {
		super();

		this.__object = "Medal.getList";
		this.__properties = this.__properties.concat(["medals"]);

				this.__castTypes = {};

		this.__castTypes.medals = io.newgrounds.models.objects.Medal;

		this.fillProperties(props);

	}


    /**
    * An array of medal objects.
    */
	public function get medals():Array {
		return this.___medals;
	}

    /**
    * @private
    */
	public function set medals(___medals:Array)
    {
        if (___medals instanceof Array) {
            var newArr = [];
            var val;
            for (var i=0; i<___medals.length; i++) {
                newArr.push(this.castValue('medals', ___medals[i]));
            }
            this.___medals = newArr;
        } else {
            this.___medals = ___medals;
        }
    }


}
