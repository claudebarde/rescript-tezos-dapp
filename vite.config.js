import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
import createReScriptPlugin from "@jihchi/vite-plugin-rescript";

// https://vitejs.dev/config/
export default ({ command }) => {
  const isBuild = command === "build";

  return defineConfig({
    plugins: [react(), createReScriptPlugin()],
    define: {
      global: {}
    },
    build: {
      target: "esnext",
      commonjsOptions: {
        transformMixedEsModules: true
      },
      rollupOptions: {
        output: {
          assetFileNames: ({ name }) => {
            console.log(name);
            if (/\.(gif|jpe?g|png|svg)$/.test(name ?? "")) {
              return "assets/images/[name]-[hash][extname]";
            }
            // default value
            // ref: https://rollupjs.org/guide/en/#outputassetfilenames
            return "assets/[name]-[hash][extname]";
          }
        }
      }
    },
    resolve: {
      alias: {
        // dedupe @airgap/beacon-sdk
        // I almost have no idea why it needs `cjs` on dev and `esm` on build, but this is how it works 🤷‍♂️
        "@airgap/beacon-sdk": path.resolve(
          path.resolve(),
          `./node_modules/@airgap/beacon-sdk/dist/${
            isBuild ? "esm" : "cjs"
          }/index.js`
        ),
        // polyfills
        "readable-stream": "vite-compatible-readable-stream",
        stream: "vite-compatible-readable-stream"
      }
    }
  });
};
