import "@material/web/all.js"
import "./besim-main";
//import { html } from "lit";
console.log("ENV", process.env.NODE_ENV)
if (process.env.NODE_ENV !== "production") {
    console.log(document.getElementById("main"))
    document.getElementById('main')?.setAttribute("version", "dev");
    document.getElementById('main')?.setAttribute("token", window.crypto.randomUUID());
    //    document.body.innerHTML += html`<besim-main version="dev" token='${window.crypto.randomUUID()}'/>`.strings;
}
