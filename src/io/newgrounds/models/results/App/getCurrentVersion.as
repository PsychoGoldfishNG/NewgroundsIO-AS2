/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when App.getCurrentVersion component is called
 */
class io.newgrounds.models.results.App.getCurrentVersion extends io.newgrounds.models.BaseResult 
{
    private var ___current_version:String;
	private var ___client_deprecated:Boolean;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function getCurrentVersion(props:Object) 
    {
		super();

		this.__object = "App.getCurrentVersion";
		this.__properties = this.__properties.concat(["current_version","client_deprecated"]);

				this.__castTypes = {};

		this.fillProperties(props);

	}


    /**
    * The version number of the app as defined in your "Version Control" settings.
    */
	public function get current_version():String {
		return this.___current_version;
	}

    /**
    * @private
    */
	public function set current_version(___current_version:String)
    {
        this.___current_version = ___current_version;
    }


    /**
    * Notes whether the client-side app is using a lower version number.
    */
	public function get client_deprecated():Boolean {
		return this.___client_deprecated;
	}

    /**
    * @private
    */
	public function set client_deprecated(___client_deprecated:Boolean)
    {
        this.___client_deprecated = ___client_deprecated;
    }


}
