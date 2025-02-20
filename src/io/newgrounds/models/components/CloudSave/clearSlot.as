/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseComponent;

/**
 * Used to call the CloudSave.clearSlot component.
 */
class io.newgrounds.models.components.CloudSave.clearSlot extends io.newgrounds.models.BaseComponent 
{
    private var ___id:Number;

	/**
	* Constructor 
	* @param props An object of initial properties for this instance
	*/
	public function clearSlot(props:Object) 
    {
		super();

		this.__object = "CloudSave.clearSlot";
		this.___id = null;
		this.__properties = this.__properties.concat(["id"]);
		this.__isSecure = false;
		this.__requireSession = true;
		this.__isRedirect = false;

		this.__castTypes = {};

        this.fillProperties(props);

	}


    /**
    * The slot number.
    */
	public function get id():Number {
		return this.___id;
	}

    /**
    * @private
    */
	public function set id(___id:Number)
    {
        this.___id = ___id;
    }


}

