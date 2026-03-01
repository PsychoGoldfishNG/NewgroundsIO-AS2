// Here are some sample helper methods you can use in your templates.
// You can add any methods here that can keep your templates clean and focused on rendering data.
// your templates will be able to access these methods using the `helper` object.

module.exports = {

    // If you use namespacing, or prefixes, you can use this to inject any namespacing you want.
    // for example, if you want to use the io.newgrounds.models.* namespace...
    baseNamespace: "io.newgrounds.models",

    /**
     * Maps model names to their preferred class names.
     * Some API model names conflict with native classes (e.g., "Error")
     * so we rename them to avoid ambiguity.
     */
    classNameMap: {
        "Error": "NgioError"
    },

    /**
     * Gets the preferred class name for a model, applying any mappings.
     * @param {string} modelName The original model name from the API.
     * @returns {string} The mapped class name (e.g., "Error" becomes "NgioError").
     */
    getClassName(modelName) {
        if (!modelName) return "";
        return this.classNameMap[modelName] || modelName;
    },

    /**
     * Gets the original API name for a model (reverse mapping).
     * @param {string} className The class name used in code.
     * @returns {string} The original API model name.
     */
    getOriginalName(className) {
        if (!className) return "";
        // Reverse lookup in the map
        for (const [original, mapped] of Object.entries(this.classNameMap)) {
            if (mapped === className) return original;
        }
        return className;
    },

    /**
     * Converts the first character of a string to uppercase.
     */
    firstCharToUpper(str) {
        if (!str) return "";
        return str.charAt(0).toUpperCase() + str.slice(1);
    },

    /**
     * Converts a string from kebab-case, snake_case, or camelCase to an array of words in lowercase.
     */
    convertToWords(str) {
        if (!str) return "";
        let words = str.replace(/[-_]/g, " ");
        words = words.replace(/([a-z])ID$/i, '$1 id');
        words = words.replace(/([a-z])([A-Z])/g, '$1 $2');
        words = words.replace(/\s+/g, ' ');
        return words.toLowerCase().split(" ").filter(w => w);
    },

    convertToCamelCase(str) {
        if (!str) return "";
        const words = this.convertToWords(str);
        return words.map((word, index) => {
            if (index === 0) return word;
            return this.firstCharToUpper(word);
        }).join("");
    },

    convertToPascalCase(str) {
        if (!str) return "";
        const words = this.convertToWords(str);
        return words.map(word => this.firstCharToUpper(word)).join("");
    },

    convertToSnakeCase(str) {
        if (!str) return "";
        const words = this.convertToWords(str);
        return words.join("_");
    },

    convertToScreamingSnakeCase(str) {
        if (!str) return "";
        const words = this.convertToWords(str);
        return words.join("_").toUpperCase();
    },

    convertToKebabCase(str) {
        if (!str) return "";
        const words = this.convertToWords(str);
        return words.join("-");
    },

    formatMultilineComment(comment, indent = "", indentFirstLine = false) {
        if (!comment) return "";

        const lines = comment.split("\n");

        let comments = indentFirstLine
            ? `${indent}/**\n${lines.map(line => `${indent} * ${line}`).join("\n")}\n${indent} */`
            : `/**\n${lines.map(line => `${indent} * ${line}`).join("\n")}\n${indent} */`;

        comments = comments.replace(/#(\w+)/g, `${this.baseNamespace}.objects.$1`);
        return comments;
    },

    /**
     * Gets the native type for a given object definition
     */
    getDataType(obj) {

        if (obj.array) {
            if (obj.type || obj.object) {
                return "*";
            } else {
                return "Array";
            }
        }

        if (obj.object === "Result") {
            return `${this.baseNamespace}.BaseResult`;
        }

        if (obj.object) {
            const className = this.getClassName(obj.object);
            return `${this.baseNamespace}.objects.${className}`;
        }

        if (!obj.type) return "Void";

        switch (obj.type) {
            case "array":
                return "Array";
            case "object":
                return "Object";
            case "string":
                return "String";
            case "int":
                return "Number";
            case "float":
                return "Number";
            case "boolean":
                return "Boolean";
            case "mixed":
                return "*";
        }

    },

    /**
     * Returns ":TypeName" for strictly typed properties, or "" for mixed/untyped ones.
     * Use this in place of ":<%- helpers.getDataType(...) %>" for var declarations
     * so that mixed types produce no type annotation instead of the invalid ":*".
     */
    appendStrictType(obj) {
        const type = this.getDataType(obj);
        if (!type || type === "*") return "";
        return `:${type}`;
    },

    /**
     * Gets the appropriate default value for a property
     */
    getDefaultValue(property) {
        if (property.default !== undefined) {
            return JSON.stringify(property.default);
        }

        const dataType = this.getDataType(property);

        if (dataType === "Number") {
            return "0";
        }

        if (dataType === "Boolean") {
            return "false";
        }

        return "null";
    }
}
