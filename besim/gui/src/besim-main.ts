//import "./devices/devices-list";
//import "./components/esphome-header-menu";
//import "./components/esphome-fab";
import { LitElement, html /*, PropertyValues*/ } from "lit";
import { customElement, property, queryAll, state } from "lit/decorators.js";
import './device/device-list'
import './traffic/traffic-table'

@customElement("besim-main")
class BeSimMainView extends LitElement {
  @property() version = "unknown";

  @property() token?: string;

  @property() docsLink = "";

  @property() logoutUrl?: string;

  @state() private activeTabIndex?: string;

  @property() deviceIds: string[] = [];

  @queryAll("div[id$='-panel'") _panels?: NodeListOf<HTMLDivElement>;

  protected render() {
    return html`
      <header class="besim-header">
        <img src="static/images/logo-text.svg" alt="BeSim Logo -${this.activeTabIndex ?? 0}"/>
        <div class="flex"></div>
        <!--
        <esphome-header-menu .logoutUrl=${this.logoutUrl}></esphome-header-menu>
        -->
        <md-tabs aria-label="Content to view" @change="${this._changeTab}" .activeTabIndex=${this.activeTabIndex ?? 0}>
          <md-primary-tab id="devices-tab" aria-controls="devices-panel">Devices</md-primary-tab>
          <md-primary-tab id="traffic-tab" aria-controls="traffic-panel">Api</md-primary-tab>
          <md-primary-tab id="status-tab" aria-controls="status-panel">Status</md-primary-tab>
        </md-tabs>
      </header>

      <main>
        <div id="devices-panel" role="tabpanel" aria-labelledby="devices-tab">
          <device-list/>
        </div>
        <div id="traffic-panel" role="tabpanel" aria-labelledby="traffic-tab" hidden>
          <traffic-table/>
        </div>
        <div id="status-panel" role="tabpanel" aria-labelledby="status-tab" hidden>
          ...
        </div>      
      </main>

      <!--
      <esphome-fab></esphome-fab>
      -->

      <footer class="page-footer">
        <div>
          BeSIM by @Dianlight |
          <a href="https://esphome.io/guides/supporters.html" target="_blank"
            >Fund development</a
          >
          |
          <a href=${this.docsLink} target="_blank" rel="noreferrer"
            >${this.version} Documentation</a
          >
        </div>
      </footer>
    `;
  }

  /*
  createRenderRoot() {
    return this;
  }
  */

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