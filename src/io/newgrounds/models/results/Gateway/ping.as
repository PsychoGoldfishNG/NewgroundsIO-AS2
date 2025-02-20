/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Gateway.ping component is called
 */
class io.newgrounds.models.results.Gateway.ping extends io.newgrounds.models.BaseResult 
{
    private var ___pong:String;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function ping(props:Object) 
    {
		super();

		this.__object = "Gateway.ping";
		this.__properties = this.__properties.concat(["pong"]);

				this.__castTypes = {};

		this.fillProperties(props);

	}


    /**
    * Will always return a value of 'pong'
    */
	public function get pong():String {
		return this.___pong;
	}

    /**
    * @private
    */
	public function set pong(___pong:String)
    {
        this.___pong = ___pong;
    }


}
