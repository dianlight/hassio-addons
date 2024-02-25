import { Task } from '@lit/task';
import { LitElement, html } from 'lit';
import { customElement, property } from 'lit/decorators.js';

@customElement("traffic-table")
export class TrafficTable extends LitElement {
    @property() token?: string;

    private _deviceTask = new Task(this, {
        task: async ([deviceIds], { signal }) => {
            const response = await fetch(`/api/v1.0/devices`, { signal });
            if (!response.ok) {
                throw new Error("API Response:" + response.status);
            }
            return response.json() as unknown as [string]
        }, args: () => [this.token]
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
}