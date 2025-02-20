/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Gateway.getDatetime component is called
 */
class io.newgrounds.models.results.Gateway.getDatetime extends io.newgrounds.models.BaseResult 
{
    private var ___datetime:String;
	private var ___timestamp:Number;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getDatetime(props:Object) 
    {
		super();

		this.__object = "Gateway.getDatetime";
		this.__properties = this.__properties.concat(["datetime","timestamp"]);

				this.__castTypes = {};

		this.fillProperties(props);

	}


    /**
    * The server's date and time in ISO 8601 format.
    */
	public function get datetime():String {
		return this.___datetime;
	}

    /**
    * @private
    */
	public function set datetime(___datetime:String)
    {
        this.___datetime = ___datetime;
    }


    /**
    * The current UNIX timestamp on the server.
    */
	public function get timestamp():Number {
		return this.___timestamp;
	}

    /**
    * @private
    */
	public function set timestamp(___timestamp:Number)
    {
        this.___timestamp = ___timestamp;
    }


}
