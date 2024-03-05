import { Task, TaskStatus } from '@lit/task';
import { LitElement, html/*, css*/ } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import '@material/web/icon/icon.js'
import '@maicol07/material-web-additions/data-table/data-table.js';
import '@maicol07/material-web-additions/data-table/data-table-row.js';
import '@maicol07/material-web-additions/data-table/data-table-column.js';
import '@maicol07/material-web-additions/data-table/data-table-footer.js';
import '@maicol07/material-web-additions/data-table/data-table-cell.js';

interface UDPData {
    "ts": string, // "2024-02-25T22:31:18.525725+01:00",
    "source": string,
    "type": string,
    "code": number,
    "payload": string,
}

@customElement("udp-unknown-table")
export class UDPTable extends LitElement {
    @property() accessor token: string | undefined;

    @state() accessor sort = "ts,desc";
    @state() accessor filter: Record<string, string> = {};
    @state() accessor page_size = 10;
    @state() accessor row_position = 0;
    @state() accessor refresh = 0;

    private _udpTableTask = new Task(this, {
        task: async ([token, sort, filter, page = 0, page_size = 25], { signal }) => {
            const response = await fetch(`/api/v1.0/call/unknown/udp?` + new URLSearchParams({
                //sort: sort as string,
                //filter: JSON.stringify(filter),
                //offset: "" + (page_size as number) * (page as number),
                //limit: "" + page_size
            }), { signal, headers: { Authorization: `Bearer ${token}` } });
            if (!response.ok) {
                throw new Error("API Response:" + response.status);
            }
            return response.json() as unknown as UDPData[]
        }, args: () => [this.token, this.sort, this.filter, /*this.page,*/ this.page_size, this.refresh]
    })

    render() {
        //console.log(this._udpTableTask.value)
        return html`
            <br/>
            <md-data-table aria-label="Dessert calories"
                ${this._udpTableTask.status === TaskStatus.PENDING ? "in-progress" : ""}
                paginated="${true}" 
                density=""
                page-sizes="[5, 10, 25]"
                page-sizes-label="Rows per page:"
                first-row-of-page="${this.row_position}"
                current-page-size="${this.page_size}"
                last-row-of-page="${this.row_position + this.page_size}"
                total-rows="${(this._udpTableTask.value?.length)}"
                pagination-total-label=":firstRow-:lastRow of :totalRows">

                    <md-data-table-column filterable="" sortable="" sorted="">Date</md-data-table-column>
                    <md-data-table-column sortable="" filterable="">Source</md-data-table-column>
                    <md-data-table-column sortable="" filterable="">Type (Code)</md-data-table-column>
                    <md-data-table-column >Payload</md-data-table-column>

                    ${this._udpTableTask.value?.map((row) => html`
                    <md-data-table-row>
                        <md-data-table-cell>${row.ts}</md-data-table-cell>
                        <md-data-table-cell>${row.source}</md-data-table-cell>
                        <md-data-table-cell>${row.type} (${row.code.toString(16)})</md-data-table-cell>
                        <md-data-table-cell>${row.payload}</md-data-table-cell>
                    </md-data-table-row>
                    `)}

                <md-data-table-footer slot="footer" style="display: flex; align-items: center; justify-content: right; gap: 4px;">
                    Actions:
                    <md-text-button @click="${() => this.refresh++}">Refresh</md-text-button>
                    <md-text-button disabled>Clean All</md-text-button>
                </md-data-table-footer>
            </md-data-table>`
    }
}