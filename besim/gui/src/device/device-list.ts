import { Task } from '@lit/task';
import { LitElement, html } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';

@customElement("device-list")
export class DeviceList extends LitElement {
    @property() accessor token: string | undefined;
    @state() accessor refresh = 0;

    private intervalHandle?: NodeJS.Timeout;

    private _deviceTask = new Task(this, {
        task: async ([deviceIds], { signal }) => {
            const response = await fetch(`./api/v1.0/devices`, { signal });
            if (!response.ok) {
                throw new Error("API Response:" + response.status);
            }
            return response.json() as unknown as [string]
        }, args: () => [this.token, this.refresh]
    })

    render() {
        return this._deviceTask.render({
            pending: () => html`<p>Loading devices...</p>`,
            complete: (devices) => html`
          <h1>Smartbox: ${devices}</h1>
        `,
            error: (e) => html`<p>Error: ${e}</p>`
        });
    }

    connectedCallback() {
        super.connectedCallback()
        this.intervalHandle = setInterval(() => this.refresh++, 5000)
    }

    disconnectedCallback() {
        super.disconnectedCallback()
        if (this.intervalHandle) {
            clearInterval(this.intervalHandle)
            delete this.intervalHandle
        }
    }

}