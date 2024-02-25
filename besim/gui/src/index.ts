import "@material/web/all"
import "./besim-main";
import { html } from "lit";
console.log("ENV", process.env.NODE_ENV)
if (process.env.NODE_ENV !== "production") {
    document.body.innerHTML += html`<besim-main version="dev" token='${window.crypto.randomUUID()}'/>`.strings;
}
