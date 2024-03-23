import { Task } from '@lit/task';
import { LitElement, css, html } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import "@material/web/all"
import Chart from 'chart.js/auto';
//import { Chart as ChartType } from 'chart.js/dist/core'
//import * as Helpers from 'chart.js/helpers'
import { MdSecondaryTab } from '@material/web/all';

const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

class BarColor {
    static T1 = "#0066ff";
    static T2 = "#ff9966";
    static T3 = "#ff0000";
    [key: string]: string;
};

interface ProgramDays {
    "0": number[],
    "1": number[],
    "2": number[],
    "3": number[],
    "4": number[],
    "5": number[],
    "6": number[],
}

interface Room {
    "days": ProgramDays,
    "heating": number,
    "temp": number,
    "settemp": number,
    "t3": number,
    "t2": number,
    "t1": number,
    "maxsetp": number,
    "minsetp": number,
    "mode": number,
    "tempcurve": number,
    "heatingsetp": number,
    "sensorinfluence": number,
    "units": number,
    "advance": number,
    "boost": number,
    "cmdissued": number,
    "winter": number,
    "lastseen": number,
    "fakeboost": number
}

interface Device {
    "rooms": Record<string, Room>,
    "cseq": number,
    "results": {},
    "addr": [string, number]
    "boilerOn": number,
    "dhwMode": number,
    "tFLO": number,
    "tdH": number,
    "tESt": number,
    "version": string,
    "wifisignal": number,
    "lastseen": number
}

@customElement("device-list")
export class DeviceList extends LitElement {
    @property() accessor token: string | undefined;
    @state() accessor refresh = 0;

    private intervalHandle?: NodeJS.Timeout;

    private _devicesTask = new Task(this, {
        task: async ([], { signal }) => {
            if (!this.checkVisibility()) {
                return []
            }
            const response = await fetch(`${process.env.SERVER}./api/v1.0/devices`, { signal });
            if (!response.ok) {
                throw new Error("API Response:" + response.status);
            }
            return response.json() as unknown as string[]
        }, args: () => [this.token, this.refresh]
    })

    private _devicesDetailTask = new Task(this, {
        task: async ([deviceIds], { signal }) => {
            if (!deviceIds) {
                return {} as Record<string, Device>
            }
            return await Promise.all(deviceIds?.map(async (deviceId) => {
                const response = await fetch(`${process.env.SERVER}./api/v1.0/devices/${deviceId}`, { signal });
                if (!response.ok) {
                    throw new Error("API Response:" + response.status);
                }
                let rst: Record<string, Device> = {}
                let resp = await response.json() as unknown as Device;
                //console.log("Resp", resp)
                rst[deviceId] = resp
                return rst;
            })).then((aa: Record<string, Device>[]) => aa.reduce((dex, cur) => {
                return Object.assign(dex, cur)
            }, {}))
        }, args: () => [this._devicesTask.value]
    });

    /*
    private _roomsTask = new Task(this, {
        task: async ([deviceIds], { signal }) => {
            return deviceIds?.map(async (deviceId) => {
                const response = await fetch(`./api/v1.0/devices/${deviceId}/rooms`, { signal });
                if (!response.ok) {
                    throw new Error("API Response:" + response.status);
                }
                return response.json()
            })
        }, args: () => [this._devicesTask.value]
    });
    */

    /*
    private _roomsDetailTask = new Task(this, {
        task: async ([deviceIds,roomsIds], { signal }) => {
            return deviceIds?.map(async (deviceId) => {
                const response = await fetch(`./api/v1.0/devices/${deviceId}/rooms/`, { signal });
                if (!response.ok) {
                    throw new Error("API Response:" + response.status);
                }
                return response.json()
            })
        }, args: () => [this._roomsTask.value]
    });
    */


    private d3ProgramView(pg: HTMLCanvasElement) {
        const data = JSON.parse(pg.getAttribute('data') || "[]") as number[];

        //console.log(data.map((d) => [d & 0xF, d >> 4]).flat())
        const chart = Chart.getChart(pg) as unknown as Chart<"bar", string[], string>
        if (chart) {
            chart.data.datasets[0].data = data.map((d) => [d & 0xF, d >> 4]).flat().map(d => `T${d + 1}`);
            chart.update();
        } else {
            let curIndex = -1;
            const chart = new Chart(
                pg,
                {
                    type: 'bar',
                    data: {
                        labels: data.map((d, i) => [`${i}:00`, `${i}:30`]).flat(),
                        datasets: [
                            {
                                data: data.map((d) => [d & 0xF, d >> 4]).flat().map(d => `T${d + 1}`),
                                backgroundColor: (p) => {
                                    //console.log(p);
                                    curIndex = p.dataIndex;
                                    return BarColor[p.raw as string];
                                }
                            }
                        ]
                    },
                    options: {
                        animation: false,
                        responsive: true,
                        scales: {
                            y: {
                                type: 'category',
                                labels: ['OFF', 'T1', 'T2', 'T3'],
                                reverse: true,
                            }
                        },
                        plugins: {
                            legend: {
                                display: false
                            },
                        },
                        onClick: (e) => {
                            //                        console.log(e);
                            //                        const canvasPosition = Helpers.getRelativePosition(e, chart as unknown as ChartType);
                            //console.log(chart.data.datasets[0]);
                            //console.log(curIndex, chart.data.datasets[0].data[curIndex]);
                            const thenum = chart.data.datasets[0].data[curIndex].match(/\d+/)![0];
                            chart.data.datasets[0].data[curIndex] = `T${((Number(thenum) + 1) % 3) + 1}`
                            //console.log(curIndex, chart.data.datasets[0].data[curIndex]);
                            chart.update();
                            // TODO: Cal Set!
                            // PUT /api/v1.0/devices/<int:deviceid>/rooms/<int:roomid>/days/<int:dayid>
                        }
                    }
                },
            );
        }
    };

    updated(changedProperties: Map<string, any>) {
        this.renderRoot.querySelectorAll("canvas").forEach((c) => {
            this.d3ProgramView(c);
        });

    }

    _changeTab(e: Event) {
        //console.log(e, e.target!['tabs']);

        const selectedPanelId = e.target!['activeTab']?.getAttribute('aria-controls');

        e.target!['tabs']?.forEach((tab: MdSecondaryTab) => {
            const panelId = tab.getAttribute('aria-controls');
            const currentPanel = this.renderRoot.querySelector<HTMLElement>(`#${panelId}`);
            if (currentPanel) {
                console.log(panelId, currentPanel, (panelId === selectedPanelId))
                currentPanel.hidden = (panelId !== selectedPanelId)
            }
        });
    }

    _render_property(name: string, value: unknown) {
        if (name === "rooms" || name === 'days') {
            return html``;
        } else {
            return html`
                    <md-list-item>
                        <div slot="headline">${name}</div>
                        <div slot="supporting-text"></div>
                        <div slot="trailing-supporting-text">${value instanceof Object ? JSON.stringify(value) : value}</div>
                    </md-list-item>
        `
        }
    }

    _render_device(deviceId: string, device: Device) {
        const props = Object.getOwnPropertyNames(device);
        return html`
            <h4>SmartBox: ${deviceId} </h4>
            <div class="row">
                <div class="column">
                    <md-list>
                    ${props.filter((v, i, a) => i <= a.length / 2).map(p => this._render_property(p, device[p]))}
                    </md-list>
                </div>
                <div class="column">
                    <md-list>
                    ${props.filter((v, i, a) => i > a.length / 2).map(p => this._render_property(p, device[p]))}
                    </md-list>
                </div>
            </div>
         `
    }

    _render_room(roomId: string, room: Room) {
        const props = Object.getOwnPropertyNames(room);
        return html`
            <h5>Room: ${roomId} </h5>
            <div class="row">
                <div class="column">
                    <md-list>
                    ${props.filter((v, i, a) => i <= a.length / 2).map(p => this._render_property(p, room[p]))}
                    </md-list>
                </div>
                <div class="column">
                    <md-list>
                    ${props.filter((v, i, a) => i > a.length / 2).map(p => this._render_property(p, room[p]))}
                    </md-list>
                </div>
            </div>
            <md-list-item>
                <md-tabs aria-label="Content to view" @change="${this._changeTab}">
                    ${Array(7).fill(undefined).map((d, i) => html`
                    <md-secondary-tab id="day-${roomId}-${i}" aria-controls="day-${roomId}-${i}-panel">
                    ${days[i]}
                    </md-secondary-tab>
                    `)}
                </md-tabs>

                ${Array(7).fill(undefined).map((d, i) => html`
                <div id="day-${roomId}-${i}-panel" role="tabpanel" aria-labelledby="day-${roomId}-${i}" style="position: relative; height:20vh; width:80vw;" ?hidden="${i > 0}">
                        <canvas id="${roomId}-${i}" data="${JSON.stringify(room.days[i])}"></canvas>
                </div>
                `)}
            </md-list-item>         `
    }


    render() {
        let deviceLst: Record<string, Device> = this._devicesDetailTask.value || {};
        return html`
            ${Object.entries(deviceLst).map((devicer) => {
            const deviceId = devicer[0]
            const device = devicer[1]
            return html`
                    ${this._render_device(deviceId, device)}
                    <md-list>
                    ${Object.entries(device.rooms).filter((room) => room[1].lastseen).map((roomr) => {
                const room = roomr[1]
                return html`
                    <md-list-item>
                        ${this._render_room(roomr[0], room)}
                    </md-list-item>
                    `
            })}
                    </md-list>
                `
        })}
            <!--
            <div>Devices Details: ${JSON.stringify(this._devicesDetailTask.value)} </div>
            <div>Rooms: {this._roomsTask.value} </div>
            <div>Rooms Details: {this._roomsDetailTask.value} </div>
            -->

        `
    }

    connectedCallback() {
        super.connectedCallback()
        this.intervalHandle = setInterval(() => this.refresh++, 30000)
        this
    }

    disconnectedCallback() {
        super.disconnectedCallback()
        if (this.intervalHandle) {
            clearInterval(this.intervalHandle)
            delete this.intervalHandle
        }
    }

    static get styles() {
        return css`
.column {
  float: left;
  width: 50%;
}

/* Clear floats after the columns */
.row:after {
  content: "";
  display: table;
  clear: both;
}
   `;
    }

}



