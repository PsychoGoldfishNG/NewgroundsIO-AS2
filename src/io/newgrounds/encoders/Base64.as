class io.newgrounds.encoders.Base64 {

    private static var base64Chars:Array = new Array("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/");
    private static var base64Indexes:Object;

    public static function getIndexOf(char:String):Number {
        if (base64Indexes == null) {
            base64Indexes = {};
            for (var i:Number = 0; i < base64Chars.length; i++) {
                base64Indexes[base64Chars[i]] = i;
            }
        }
        return base64Indexes[char];
    }

    public static function encode(str:String):String {
        var charcodes:Array = [];
        for (var i:Number = 0; i < str.length; i++) {
            charcodes.push(str.charCodeAt(i));
        }
        return encodeFromArray(charcodes);
    }

    public static function encodeFromArray(charcodes:Array):String {
        var encodedStr:String = "";
        for (var i:Number = 0; i < charcodes.length; i++) {
            var charCode:Number = charcodes[i];
            encodedStr += base64Chars[(charCode >> 2) & 0x3F];
            encodedStr += base64Chars[((charCode << 4) & 0x30) | ((charcodes[i + 1] >> 4) & 0x0F)];
            i++;
            if (i < charcodes.length) {
                charCode = charcodes[i];
                encodedStr += base64Chars[((charCode << 2) & 0x3C) | ((charcodes[i + 1] >> 6) & 0x03)];
                i++;
                if (i < charcodes.length) {
                    encodedStr += base64Chars[charcodes[i] & 0x3F];
                } else {
                    encodedStr += "=";
                }
            } else {
                encodedStr += "==";
            }
        }
        return encodedStr;
    }

    // add decode methods
    public static function decodeToArray(str:String):Array {
        var charcodes:Array = [];
        for (var i:Number = 0; i < str.length; i += 4) {
            var charCode1:Number = getIndexOf(str.charAt(i));
            var charCode2:Number = getIndexOf(str.charAt(i + 1));
            var charCode3:Number = str.charAt(i + 2) == "=" ? 64 : getIndexOf(str.charAt(i + 2));
            var charCode4:Number = str.charAt(i + 3) == "=" ? 64 : getIndexOf(str.charAt(i + 3));
            charcodes.push((charCode1 << 2) | (charCode2 >> 4));
            if (charCode3 < 64) {
                charcodes.push(((charCode2 & 0x0F) << 4) | (charCode3 >> 2));
                if (charCode4 < 64) {
                    charcodes.push(((charCode3 & 0x03) << 6) | charCode4);
                }
            }
        }
        
        return charcodes;
    }

    public static function decode(str:String):String {
        var charcodes:Array = decodeToArray(str);
        var decodedStr:String = "";
        for (var i:Number = 0; i < charcodes.length; i++) {
            decodedStr += String.fromCharCode(charcodes[i]);
        }
        return decodedStr;
    }

}