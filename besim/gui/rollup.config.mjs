import { nodeResolve } from "@rollup/plugin-node-resolve";
import terser from "@rollup/plugin-terser";
//import json from "@rollup/plugin-json";
import typescript from "@rollup/plugin-typescript";
//import manifest from "./build-scripts/rollup/manifest-plugin.mjs";
//import postcss from "rollup-plugin-postcss";
//import postcssUrl from "postcss-url";
import commonjs from "@rollup/plugin-commonjs";
//import monaco from "rollup-plugin-monaco-editor";
import copy from "rollup-plugin-copy";
//import fs from "fs-extra";
//import path from "path";
import livereload from 'rollup-plugin-livereload'
import replace from "@rollup/plugin-replace";
import dev from 'rollup-plugin-dev'
import { mdIcon, replaceSymbolsLink } from 'rollup-plugin-md-icon';
import { rollupPluginHTML as html } from '@web/rollup-plugin-html';
//import { compileLitTemplates } from '@lit-labs/compiler'

const isProdBuild = process.env.NODE_ENV === "production";

/**
 * @type { import("rollup").MergedRollupOptions }
 */
const config = {
    input: "src/index.ts",
    output: {
        dir: "dist",
        format: "module",
        //entryFileNames: isProdBuild ? "[name]-[hash].js" : "[name].js",
        //chunkFileNames: isProdBuild ? "c.[hash].js" : "[name].js",
        //assetFileNames: isProdBuild ? "a.[hash].js" : "[name].js",
        sourcemap: !isProdBuild,
    },
    preserveEntrySignatures: false,
    plugins: [
        replace({
            values: {
                'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
                //__buildDate__: () => JSON.stringify(new Date()),
                //__buildVersion: 15
            },
            preventAssignment: true
        }),
        typescript(
            {
                sourceMap: !isProdBuild,
                inlineSources: !isProdBuild
                //transformers: {
                //    before: [compileLitTemplates()],
                //},
            }),
        /*
        postcss({
            plugins: [
                postcssUrl({
                    url: (asset) => {
                        if (!/\.ttf$/.test(asset.url)) return asset.url;
                        const distPath = path.join(process.cwd(), "esphome");
                        const distFontsPath = path.join(distPath, "fonts");
                        fs.ensureDirSync(distFontsPath);
                        const targetFontPath = path.join(
                            "esphome_dashboard/static/fonts/",
                            asset.pathname,
                        );
                        fs.copySync(asset.absolutePath, targetFontPath);
                        return "./static/fonts/" + asset.pathname;
                    },
                }),
            ],
        }),
        */
        copy({
            targets: [
                { src: "assets/*", dest: "dist/assets" },
            ],
        }),
        /*
        monaco({
            languages: ["yaml"],
            sourcemap: false,
        }),
        */
        nodeResolve({
            browser: true,
            preferBuiltins: false,
        }),
        commonjs(),
        //json(),
        //manifest(),
        mdIcon({ symbols: {} }),
        html({
            input: ['src/index.html'],
            // publicPath: './static',
            //extractAssets: false,
            /*
            transformHtml: (html) =>
                replaceSymbolsLink(
                    html,
                    '<link rel="stylesheet" href="/material-symbols.css">',
                ),
            */
        }),
        dev({
            dirs: ['dist'/*, 'assets'*/],
            // basePath: '/static',
            proxy: [{
                from: '/api',
                to: 'http://127.0.0.1/api',
                opts: {
                    logger: true,
                }
            },
                /*
                {
                    from: '/static',
                    to: 'http://127.0.0.1/static',
                    opts: {
                        logger: true,
                    }
                }
                */
            ]
        }),
        (!isProdBuild) && livereload('dist'),
        isProdBuild &&
        terser({
            ecma: 2019,
            toplevel: true,
            format: {
                comments: false,
            },
        }),
    ].filter(Boolean),
};

export default config;