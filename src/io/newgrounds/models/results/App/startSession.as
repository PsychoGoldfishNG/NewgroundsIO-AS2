/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when App.startSession component is called
 */
class io.newgrounds.models.results.App.startSession extends io.newgrounds.models.BaseResult 
{
    private var ___session:io.newgrounds.models.objects.Session;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function startSession(props:Object) 
    {
		super();

		this.__object = "App.startSession";
		this.__properties = this.__properties.concat(["session"]);

				this.__castTypes = {};

		this.__castTypes.session = io.newgrounds.models.objects.Session;

		this.fillProperties(props);

	}


	public function get session():io.newgrounds.models.objects.Session {
		return this.___session;
	}

    /**
    * @private
    */
	public function set session(___session:io.newgrounds.models.objects.Session)
    {
        this.___session = ___session;
    }


}
