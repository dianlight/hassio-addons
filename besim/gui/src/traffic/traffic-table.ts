import { Task, TaskStatus } from '@lit/task';
import { LitElement, html/*, css*/ } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
//import "@doubletrade/lit-datatable"
//import "@doubletrade/lit-datatable/iron-flex-import"
//import "@doubletrade/lit-datatable/lit-datatable-column"
//import "@doubletrade/lit-datatable/lit-datatable-footer"
import '@material/web/icon/icon.js'
import '@maicol07/material-web-additions/data-table/data-table.js';
import '@maicol07/material-web-additions/data-table/data-table-row.js';
import '@maicol07/material-web-additions/data-table/data-table-column.js';
import '@maicol07/material-web-additions/data-table/data-table-footer.js';
import '@maicol07/material-web-additions/data-table/data-table-cell.js';
//import '@lit-labs/motion'
//import '@polymer/neon-animation'
//import '@polymer/polymer'
//import '@polymer/neon-animation/neon-animations.js';
//import '@polymer/neon-animation/animations/fade-out-animation.js';
//import '@polymer/neon-animation/animations/scale-up-animation.js';
//import '@material/web/icon/icon.js'

interface Call {
    meta: {
        total: number
    }
    data: [{
        "ts": string, // "2024-02-25T22:31:18.525725+01:00",
        "cardinal": number,
        "source": string, //"HTTP/1.1",
        "host": string, //"127.0.0.1",
        "adapterMap": string, //"GET /",
        "elapsed": number,
        "response_status": string //"<werkzeug.wsgi.ClosingIterator object at 0x110983800>"
    }]
}

@customElement("traffic-table")
export class TrafficTable extends LitElement {
    @property() accessor token: string | undefined;

    @state() accessor sort = "ts,desc";
    @state() accessor filter: Record<string, string> = {};
    @state() accessor page_size = 10;
    //@state() accessor page = 0;
    @state() accessor row_position = 0;
    @state() accessor refresh = 0;

    private _hystoryTask = new Task(this, {
        task: async ([token, sort, filter, page = 0, page_size = 25], { signal }) => {
            const response = await fetch(`./api/v1.0/call/history?` + new URLSearchParams({
                //sort: sort as string,
                //filter: JSON.stringify(filter),
                //offset: "" + (page_size as number) * (page as number),
                //limit: "" + page_size
            }), { signal, headers: { Authorization: `Bearer ${token}` } });
            if (!response.ok) {
                throw new Error("API Response:" + response.status);
            }
            return response.json() as unknown as Call
        }, args: () => [this.token, this.sort, this.filter, /*this.page,*/ this.page_size, this.refresh]
    })

    /*
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
        if (event.detail.value) {
            this.filter = Object.assign({}, this.filter, {
                [event.detail.property]: event.detail.value
            });
        } else {
            delete this.filter[event.detail.property];
            this.refresh++;
        }
        console.log(event);
    }
    */

    /*
    private async refreshTable() {
        console.log("Refresh!")
        this.time_handle && clearTimeout(this.time_handle);
        this.time_handle && await this._hystoryTask.run();
        this.time_handle = setTimeout(this.refreshTable, 1000);
        console.log("<Refresh!")
    }

    connectedCallback() {
        console.log("Connect")
        super.connectedCallback();
        this.time_handle = setInterval(() => this.refresh++, 1000)
        //  this.time_handle = setTimeout(this.refreshTable, 1000);
    }

    disconnectedCallback() {
        console.log("Disconnect")
        super.disconnectedCallback();
        this.time_handle && clearInterval(this.time_handle);
        //    this.time_handle && clearTimeout(this.time_handle);
    }
    */

    render() {
        /*
        const conf = [
            { property: 'ts', header: 'Date', hidden: false },
            { property: 'cardinal', header: 'Counter', hidden: false },
            { property: 'source', header: 'Source', hidden: false },
            { property: 'host', header: 'Host', hidden: false },
            { property: 'adapterMap', header: 'URI', hidden: false },
            { property: 'elapsed', header: 'Elapsed', hidden: false },
            { property: 'response_status', header: 'Response', hidden: false }
        ];
        */
        console.log(this._hystoryTask.value)
        return html`
            <br/>
            <md-data-table aria-label="Dessert calories"
                ${this._hystoryTask.status === TaskStatus.PENDING ? "in-progress" : ""}
                paginated="${true}"
                density=""
                page-sizes="[5, 10, 25]"
                page-sizes-label="Rows per page:"
                first-row-of-page="${this.row_position}"
                current-page-size="${this.page_size}"
                last-row-of-page="${this.row_position + this.page_size}"
                total-rows="${(this._hystoryTask.value?.meta.total || 0)}"
                pagination-total-label=":firstRow-:lastRow of :totalRows">

                    <md-data-table-column filterable="" sortable="" sorted="">Date</md-data-table-column>
                    <md-data-table-column sortable="" filterable="">Source</md-data-table-column>
                    <md-data-table-column sortable="">Counter</md-data-table-column>
                    <md-data-table-column filterable="" sortable="">Host</md-data-table-column>
                    <md-data-table-column sortable="">URI</md-data-table-column>
                    <md-data-table-column sortable="">Elapsed</md-data-table-column>
                    <md-data-table-column>Reponse</md-data-table-column>

                    ${this._hystoryTask.value?.data.map((row) => html`
                    <md-data-table-row>
                        <md-data-table-cell>${row.ts}</md-data-table-cell>
                        <md-data-table-cell>${row.source}</md-data-table-cell>
                        <md-data-table-cell type="numeric">${row.cardinal}</md-data-table-cell>
                        <md-data-table-cell>${row.host}</md-data-table-cell>
                        <md-data-table-cell>${row.adapterMap}</md-data-table-cell>
                        <md-data-table-cell type="numeric">${row.elapsed}</md-data-table-cell>
                        <md-data-table-cell>${row.response_status}</md-data-table-cell>
                    </md-data-table-row>
                    `)}

                <md-data-table-footer slot="footer" style="display: flex; align-items: center; justify-content: right; gap: 4px;">
                    Actions:
                    <md-text-button @click="${() => this.refresh++}">Refresh</md-text-button>
                    <!--
                    <md-text-button>Action 2</md-text-button>
                    <md-text-button>Action 3</md-text-button>
                    -->
                </md-data-table-footer>
            </md-data-table>`
        /*
        return html`
            <md-outlined-button>Back</md-outlined-button>
            <md-filled-button>Complete<md-icon slot="icon">edit</md-icon></md-filled-button>
            ${this._hystoryTask.status === TaskStatus.PENDING ? html`<md-linear-progress indeterminate></md-linear-progress>` : ""}
            ${this._hystoryTask.status === TaskStatus.ERROR ? html`<p>Error: ${this._hystoryTask.error}</p>` : ""}
            <div class="content">
                <lit-datatable sticky-header .data="${this._hystoryTask.value?.data}" .conf="${conf}" @sort="${this._sortChanged}" @filter="${this._filterChanged}" .sort="${this.sort}">
                    <lit-datatable-column header="${true}" property="ts" type="filterSort" .filterValue="${this.filter['ts']}"></lit-datatable-column>
                    <lit-datatable-column header="${true}" property="cardinal" type="sort"></lit-datatable-column>
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
            <md-fab variant="primary" aria-label="Edit">
  <md-icon slot="icon">edit</md-icon>
</md-fab>
<md-fab variant="secondary" aria-label="Edit">
  <md-icon slot="icon">edit</md-icon>
</md-fab>
<md-fab variant="tertiary" aria-label="Edit">

</md-fab>
        `;
        */
        /*
        return this._hystoryTask.render({
            initial: () => html`<p>Loading...</p>`,
            pending: () => html`<md-linear-progress indeterminate></md-linear-progress>${table_body}`,
            complete: (calls) => html`
            <p style="display:none">Debug ${this.sort} ${JSON.stringify(this.filter)} </p>
            ${table_body}
        `,
            error: (e) => html`<p>Error: ${e}</p>`
        });
        */
    }
}