/**
* Encrypts and decrypts an alleged RC4 hash.
* @author Mika Palmu
* @version 1.0
*
* Orginal Flash port by:
* Gabor Penoff - http://www.fns.hu
* Email: fns@fns.hu
*/
import io.newgrounds.encoders.Base64;

class io.newgrounds.encoders.RC4 {

	/**
	* Variables
	* @exclude
	*/
	private static var sbox:Array = new Array(255);
	private static var mykey:Array = new Array(255);
	
	/**
	* Encrypts a string with the specified key.
	*/
	public static function encrypt(src:String, key:String):String {
		var mtxt:Array = strToChars(src);
		var mkey:Array = Base64.decodeToArray(key);
		var result:Array = calculate(mtxt, mkey);
		return Base64.encodeFromArray(result);
	}
	
	/**
	* Decrypts a string with the specified key.
	*/
	public static function decrypt(src:String, key:String):String {
		var mtxt:Array = Base64.decodeToArray(src);
		var mkey:Array = Base64.decodeToArray(key);
		var result:Array = calculate(mtxt, mkey);
		return charsToStr(result);
	}
	
	/**
	* Private methods.
	*/
	private static function initialize(pwd:Array) {
		var b:Number = 0;
		var tempSwap:Number;
		var intLength:Number = pwd.length;
		for (var a:Number = 0; a <= 255; a++) {
			mykey[a] = pwd[(a%intLength)];
			sbox[a] = a;
		}
		for (var a:Number=0; a<=255; a++) {
			b = (b+sbox[a]+mykey[a]) % 256;
			tempSwap = sbox[a];
			sbox[a] = sbox[b];
			sbox[b] = tempSwap;
		}
	}
	private static function calculate(plaintxt:Array, psw:Array):Array {
		initialize(psw);
		var i:Number = 0; var j:Number = 0;
		var cipher:Array = new Array();
		var k:Number, temp:Number, cipherby:Number;
		for (var a:Number = 0; a<plaintxt.length; a++) {
			i = (i+1) % 256;
			j = (j+sbox[i])%256;
			temp = sbox[i];
			sbox[i] = sbox[j];
			sbox[j] = temp;
			var idx:Number = (sbox[i]+sbox[j]) % 256;
			k = sbox[idx];
			cipherby = plaintxt[a]^k;
			cipher.push(cipherby);
		}
		return cipher;
	}
	private static function charsToStr(chars:Array):String {
		var result:String = new String("");
		for (var i:Number = 0; i<chars.length; i++) {
			result += String.fromCharCode(chars[i]);
		}
		return result;
	}
	private static function strToChars(str:String):Array {
		var codes:Array = new Array();
		for (var i:Number = 0; i<str.length; i++) {
			codes.push(str.charCodeAt(i));
		}
		return codes;
	}

}