/** ActionScript 2.0 **/
/** Auto-genertaed by ngio-object-model-generator: https://github.com/PsychoGoldfishNG/ngio-object-model-generator **/

import io.newgrounds.models.BaseObject;
import io.newgrounds.models.BaseResult;

/**
 * Returned when Medal.unlock component is called
 */
class io.newgrounds.models.results.Medal.unlock extends io.newgrounds.models.BaseResult 
{
    private var ___medal:io.newgrounds.models.objects.Medal;
	private var ___medal_score:Number;

	/**
	* Constructor 
	 * @param props An object of initial properties for this instance
	*/
	public function unlock(props:Object) 
    {
		super();

		this.__object = "Medal.unlock";
		this.__properties = this.__properties.concat(["medal","medal_score"]);

				this.__castTypes = {};

		this.__castTypes.medal = io.newgrounds.models.objects.Medal;

		this.fillProperties(props);

	}


    /**
    * The io.newgrounds.models.objects.Medal that was unlocked.
    */
	public function get medal():io.newgrounds.models.objects.Medal {
		return this.___medal;
	}

    /**
    * @private
    */
	public function set medal(___medal:io.newgrounds.models.objects.Medal)
    {
        this.___medal = ___medal;
    }


    /**
    * The user's new medal score.
    */
	public function get medal_score():Number {
		return this.___medal_score;
	}

    /**
    * @private
    */
	public function set medal_score(___medal_score:Number)
    {
        this.___medal_score = ___medal_score;
    }


}
