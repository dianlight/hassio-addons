//import "./devices/devices-list";
//import "./components/esphome-header-menu";
//import "./components/esphome-fab";
import { LitElement, html, css /*, PropertyValues*/ } from "lit";
import { customElement, property, queryAll, state } from "lit/decorators.js";
import './device/device-list'
import './traffic/traffic-table'
import './unknown/udp-table'
import './unknown/api-table'
import '@material/typography/dist/mdc.typography.css'



@customElement("besim-main")
class BeSimMainView extends LitElement {
  @property() accessor version = "unknown";

  @property() accessor token!: string;

  /*
  @property() accessor docsLink = "";

  @property() accessor logoutUrl!: string;
  */

  @state() accessor activeTabIndex!: string;

  @property() accessor deviceIds: string[] = [];

  @queryAll("div[id$='-panel'")
  accessor _panels!: NodeListOf<HTMLDivElement>;

  static get styles() {
    return css`
      @use "@material/typography/mdc-typography";
    `
  }

  protected render() {
    return html`
      <header class="besim-header">
        <img src="assets/images/logo.png" alt="BeSim Logo"/>
        <div class="flex"></div>
        <md-tabs aria-label="Content to view" @change="${this._changeTab}" .activeTabIndex=${this.activeTabIndex ?? 0}>
          <md-primary-tab id="devices-tab" aria-controls="devices-panel">Devices</md-primary-tab>
          <md-primary-tab id="traffic-tab" aria-controls="traffic-panel">Call Log</md-primary-tab>
          <md-primary-tab id="missing-api-tab" aria-controls="missing-api-panel">Missing API</md-primary-tab>
        </md-tabs>
      </header>

      <main>
        <div id="devices-panel" role="tabpanel" aria-labelledby="devices-tab">
          <h1 class="mdc-typography--headline1">Devices</h1>
          <device-list/>
        </div>
        <div id="traffic-panel" role="tabpanel" aria-labelledby="traffic-tab" hidden>
          <h1 >Traffic</h1>
          <traffic-table/>
        </div>
        <div id="missing-api-panel" role="tabpanel" aria-labelledby="missing-api-tab" hidden>
          <h1>Missing API</h1>

          <h2>Missing REST API</h2>
          <api-unknown-table></api-unknown-table>

          <h2>Missing UDP API</h2>
          <udp-unknown-table></udp-unknown-table>
        </div>
      </main>

      <footer class="page-footer">
        <div>
          BeSIM by @Dianlight |
          <a href="url: https://github.com/dianlight/hassio-addons" target="_blank"
            >Fund development</a
          >
          |
          <a href="url: https://github.com/dianlight/hassio-addons/tree/master/besim" target="_blank" rel="noreferrer"
            >${this.version} Documentation</a
          >
        </div>
      </footer>
    `;
  }

  _changeTab(e: Event) {
    this.activeTabIndex = e.target!['activeTabIndex'];
    //console.log(e, e.target!['activeTab']);
    //console.log(this._panels)
    this._panels?.forEach(panel => {
      //console.log(panel.id, e.target!['activeTab'].getAttribute('aria-controls'))
      if (panel.id === e.target!['activeTab'].getAttribute('aria-controls')) {
        panel.style.display = 'block'
      } else {
        panel.style.display = 'none'
      }
    });
  }


  /*

  protected firstUpdated(changedProps: PropertyValues<this>): void {
    super.firstUpdated(changedProps);
  }
  */


  /*
  private _handleEditorClose() {
    this.editing = undefined;
  }
  */
}

declare global {
  interface HTMLElementTagNameMap {
    "besim-main": BeSimMainView;
  }
}