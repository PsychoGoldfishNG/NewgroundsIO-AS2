// load in our helpers module
const helpers = require('./helpers.js');

/**
 * In this config, values are created with functions that are given a props object with dynamic values.
 * For example, props.__dirname will be the directory this file is in.
 * This allows us to easily use relative paths in the config file.
 *
 * The helpers module is also available within these config functions for transforming values.
 */
module.exports = {

    /**
     * The file extension for the generated files, will be passed as prop.file_extension in config functions.
     */
    output_file_extension: ".as",

    /**
     * Make the helpers module available to templates.
     */
    helpers: helpers,

    /**
     * Directory where generated class & model files will be placed.
     */
    build_dir: `${__dirname}/../../build`,

    /**
     * Top-level directory where your model files will be placed.
     */
    models_dir: `${__dirname}/../../build/io/newgrounds/models`,

    /**
     * Directory where your template files are located.
     */
    template_dir: `${__dirname}/../templates`,

    /**
     * Directory where your partial template files are located.
     */
    partials_dir: `${__dirname}/../templates/partials`,

    /**
     * Template files for the model builder.
     */
    template_files: {

        objects: (config) => {
            return `${config.template_dir}/object.ejs`;
        },

        components: (config) => {
            return `${config.template_dir}/component.ejs`;
        },

        results: (config) => {
            return `${config.template_dir}/result.ejs`;
        },

        object_factory: (config) => {
            return `${config.template_dir}/object_factory.ejs`;
        }
    },

    model_files: {

        objects: (config, objectName) => {
            const className = helpers.getClassName(objectName);
            return `${config.models_dir}/objects/${className}${config.output_file_extension}`;
        },

        components: (config, componentScope, componentMethod) => {
            return `${config.models_dir}/components/${componentScope}/${componentMethod}${config.output_file_extension}`;
        },

        results: (config, componentScope, componentMethod) => {
            return `${config.models_dir}/results/${componentScope}/${componentMethod}Result${config.output_file_extension}`;
        },

        object_factory: (config) => {
            return `${config.models_dir}/objects/ObjectFactory${config.output_file_extension}`;
        }
    },

    core_files: {

        enabled: false,

        overwrite: false,

        files: {}
    }
};
