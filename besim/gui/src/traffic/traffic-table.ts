import { Task } from '@lit/task';
import { LitElement, html, css } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import "@doubletrade/lit-datatable"
import "@doubletrade/lit-datatable/iron-flex-import"
import "@doubletrade/lit-datatable/lit-datatable-column"
import "@doubletrade/lit-datatable/lit-datatable-footer"
import '@lit-labs/motion'
import '@polymer/neon-animation'
import '@polymer/polymer'
//import '@polymer/paper-dialog/paper-dialog.js';
import '@polymer/neon-animation/neon-animations.js';
import '@polymer/neon-animation/animations/fade-out-animation.js';
import '@polymer/neon-animation/animations/scale-up-animation.js';

interface Call {
    meta: {
        total: number
    }
    data: [{
        "ts": string, // "2024-02-25T22:31:18.525725+01:00",
        "source": string, //"HTTP/1.1",
        "host": string, //"127.0.0.1",
        "uri": string, //"GET /",
        "elapsed": number,
        "response_status": string //"<werkzeug.wsgi.ClosingIterator object at 0x110983800>"
    }]
}

@customElement("traffic-table")
export class TrafficTable extends LitElement {
    @property() accessor token: string | undefined;

    @state() accessor sort = "ts,asc";
    @state() accessor filter: Record<string, string> = {};
    @state() accessor page_size = 10;
    @state() accessor page = 0;


    private _hystoryTask = new Task(this, {
        task: async ([token, sort, filter, page = 0, page_size = 25], { signal }) => {
            const response = await fetch(`/api/v1.0/call/history?` + new URLSearchParams({
                sort: sort as string,
                filter: JSON.stringify(filter),
                offset: "" + (page_size as number) * (page as number),
                limit: "" + page_size
            }), { signal, headers: { Authorization: `Bearer ${token}` } });
            if (!response.ok) {
                throw new Error("API Response:" + response.status);
            }
            return response.json() as unknown as Call
        }, args: () => [this.token, this.sort, this.filter, this.page, this.page_size]
    })
    private _handlePageChanged(event: CustomEvent) {
        this.page = event.detail.page;
        this.page_size = event.detail.size;
        console.log(event);
    }

    private _sortChanged(event: CustomEvent) {
        this.sort = event.detail.value;
        console.log(event);
    }

    private _filterChanged(event: CustomEvent) {
        //this.filter[event.detail.property] = event.detail.value;
        //this.requestUpdate();
        this.filter = Object.assign({}, this.filter, {
            [event.detail.property]: event.detail.value
        });
        console.log(event);
    }

    render() {
        const conf = [
            { property: 'ts', header: 'Date', hidden: false },
            { property: 'cardinal', header: 'Counter', hidden: false },
            { property: 'source', header: 'Source', hidden: false },
            { property: 'host', header: 'Host', hidden: false },
            { property: 'adapterMap', header: 'URI', hidden: false },
            { property: 'elapsed', header: 'Elapsed', hidden: false },
            { property: 'response_status', header: 'Response', hidden: false }
        ];
        console.log(this._hystoryTask.value)
        let table_body = html`
            <div class="content">
                <lit-datatable sticky-header .data="${this._hystoryTask.value?.data}" .conf="${conf}" @sort="${this._sortChanged}" @filter="${this._filterChanged}" .sort="${this.sort}">
                    <lit-datatable-column header="${true}" property="ts" type="filterSort" .filterValue="${this.filter['ts']}"></lit-datatable-column>
                    <lit-datatable-column header="${true}" property="cardinal" type="filterSort" .filterValue="${this.filter['host']}"></lit-datatable-column>
                    <lit-datatable-column header="${true}" property="host" type="filterSort" .filterValue="${this.filter['host']}"></lit-datatable-column>
                    <lit-datatable-column header="${true}" property="adapterMap" type="sort"}"></lit-datatable-column>
                    <lit-datatable-column header="${true}" property="elapsed" type="sort"></lit-datatable-column>
                    <lit-datatable-column header="${true}" property="response_status" type="filterSort" .filterValue="${this.filter['response_status']}"></lit-datatable-column>
                </lit-datatable>
                <lit-datatable-footer
                    @page-or-size-changed="${this._handlePageChanged}"
                    .availableSize="${[5, 10, 25]}"
                    totalPages="${(this._hystoryTask.value?.meta.total || 0) / this.page_size}"
                    totalElements="${this._hystoryTask.value?.meta.total}"
                    size="${this.page_size}"
                    page="${this.page}"
                    language="en">
                </lit-datatable-footer>
            </div>
        `;
        return this._hystoryTask.render({
            initial: () => html`<p>Loading...</p>`,
            pending: () => html`<md-linear-progress indeterminate></md-linear-progress>${table_body}`,
            complete: (calls) => html`
            <p style="display:none">Debug ${this.sort} ${JSON.stringify(this.filter)} </p>
            ${table_body}
        `,
            error: (e) => html`<p>Error: ${e}</p>`
        });
    }
}