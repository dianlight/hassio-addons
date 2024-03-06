import { Task, TaskStatus } from '@lit/task';
import { LitElement, html, css } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import '@material/web/icon/icon.js'
import '@maicol07/material-web-additions/data-table/data-table.js';
import '@maicol07/material-web-additions/data-table/data-table-row.js';
import '@maicol07/material-web-additions/data-table/data-table-column.js';
import '@maicol07/material-web-additions/data-table/data-table-footer.js';
import '@maicol07/material-web-additions/data-table/data-table-cell.js';

interface APIData {
    "count": number,
    "ts": string, // "2024-02-25T22:31:18.525725+01:00",
    "source": string,
    "host": string,
    "method": string,
    "uri": string,
    "headers": string,
    "body": string,
    "rm_resp_code": string,
    "rm_res_body": string
}

@customElement("api-unknown-table")
export class APITable extends LitElement {
    @property() accessor token: string | undefined;

    @state() accessor sort = "ts,desc";
    @state() accessor filter: Record<string, string> = {};
    @state() accessor page_size = 10;
    @state() accessor row_position = 0;
    @state() accessor refresh = 0;

    private intervalHandle?: NodeJS.Timeout;


    private _apiTableTask = new Task(this, {
        task: async ([token, sort, filter, page = 0, page_size = 25], { signal }) => {
            const response = await fetch(`./api/v1.0/call/unknown/api?` + new URLSearchParams({
                //sort: sort as string,
                //filter: JSON.stringify(filter),
                //offset: "" + (page_size as number) * (page as number),
                //limit: "" + page_size
            }), { signal, headers: { Authorization: `Bearer ${token}` } });
            if (!response.ok) {
                throw new Error("API Response:" + response.status);
            }
            return response.json() as unknown as APIData[]
        }, args: () => [this.token, this.sort, this.filter, /*this.page,*/ this.page_size, this.refresh]
    })

    render() {
        //console.log(this._apiTableTask.value)
        return html`
            <br/>
            <md-data-table aria-label="Dessert calories"
                ${this._apiTableTask.status === TaskStatus.PENDING ? "in-progress" : ""}
                paginated="${true}"
                density=""
                page-sizes="[5, 10, 25]"
                page-sizes-label="Rows per page:"
                first-row-of-page="${this.row_position}"
                current-page-size="${this.page_size}"
                last-row-of-page="${this.row_position + this.page_size}"
                total-rows="${(this._apiTableTask.value?.length)}"
                pagination-total-label=":firstRow-:lastRow of :totalRows">

                    <md-data-table-column sortable="">Count</md-data-table-column>
                    <md-data-table-column filterable="" sortable="" sorted="">Date</md-data-table-column>
                    <md-data-table-column sortable="" filterable="">Source</md-data-table-column>
                    <md-data-table-column sortable="" filterable="">Host</md-data-table-column>
                    <md-data-table-column sortable="" >Method</md-data-table-column>
                    <md-data-table-column sortable="" filterable="">URI</md-data-table-column>
                    <md-data-table-column sortable="" filterable="">Headers</md-data-table-column>
                    <md-data-table-column sortable="" >Body</md-data-table-column>
                    <md-data-table-column >Remote Response (CODE)</md-data-table-column>

                    ${this._apiTableTask.value?.map((row) => html`
                    <md-data-table-row>
                        <md-data-table-cell>${row.count}</md-data-table-cell>
                        <md-data-table-cell>${row.ts}</md-data-table-cell>
                        <md-data-table-cell>${row.source}</md-data-table-cell>
                        <md-data-table-cell>${row.host}</md-data-table-cell>
                        <md-data-table-cell>${row.method}</md-data-table-cell>
                        <md-data-table-cell>${row.uri}</md-data-table-cell>
                        <md-data-table-cell>${row.headers}</md-data-table-cell>
                        <md-data-table-cell>${row.body}</md-data-table-cell>
                        <md-data-table-cell>(${row.rm_resp_code}) ${row.rm_res_body}</md-data-table-cell>
                    </md-data-table-row>
                    `)}

                <md-data-table-footer slot="footer" style="display: flex; align-items: center; justify-content: right; gap: 4px;">
                    Actions:
                    <md-text-button @click="${() => this.refresh++}">Refresh</md-text-button>
                    <md-text-button disabled>Clean All</md-text-button>
                </md-data-table-footer>
            </md-data-table>`
    }

    static get _styles() {
        return css`
      .mdc-data-table__cell, host(slot) {
            display: -webkit-box;
            -webkit-line-clamp: 3;
            -webkit-box-orient: vertical;
            max-width: 200px;
            overflow: hidden;
            text-overflow: ellipsis;
            height:56px;
      }
    `;
    }


    connectedCallback() {
        super.connectedCallback()
        this.intervalHandle = setInterval(() => this.refresh++, 2000)
    }

    disconnectedCallback() {
        super.disconnectedCallback()
        if (this.intervalHandle) {
            clearInterval(this.intervalHandle)
            delete this.intervalHandle
        }
    }
}