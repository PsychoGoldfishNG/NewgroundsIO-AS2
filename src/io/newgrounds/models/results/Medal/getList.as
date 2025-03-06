/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Medal.getList component is called
 */
class io.newgrounds.models.results.Medal.getList extends io.newgrounds.models.BaseResult {
	private var ___medals:Array;
	private var ___app_id:String;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getList(props:Object) {
		super();
		this.__object = "Medal.getList";
		this.__properties = this.__properties.concat(["medals","app_id"]);
		this.__castTypes = {};
		this.__arrayTypes = {};
		this.__castTypes.medals = io.newgrounds.models.objects.Medal;
		this.__arrayTypes.medals = true;
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
	public function set medals(___medals:Array) {
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
	/**
	* The App ID of any external app these medals were loaded from.
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