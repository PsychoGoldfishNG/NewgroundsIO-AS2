/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Loader.loadAuthorUrl component is called
 */
class io.newgrounds.models.results.Loader.loadAuthorUrl extends io.newgrounds.models.BaseResult 
{
    private var ___url:String;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function loadAuthorUrl(props:Object) 
    {
		super();

		this.__object = "Loader.loadAuthorUrl";
		this.__properties = this.__properties.concat(["url"]);

				this.__castTypes = {};

		this.fillProperties(props);

	}


	public function get url():String {
		return this.___url;
	}

    /**
    * @private
    */
	public function set url(___url:String)
    {
        this.___url = ___url;
    }


}
