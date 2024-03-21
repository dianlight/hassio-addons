import { Task } from '@lit/task';
import { LitElement, html } from 'lit';
import { customElement, property, state } from 'lit/decorators.js';
import "@material/web/all"
import Chart from 'chart.js/auto';
//import { Chart as ChartType } from 'chart.js/dist/core'
//import * as Helpers from 'chart.js/helpers'
import { MdSecondaryTab } from '@material/web/all';

const BKB = ""; //"http://192.168.0.250/"

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

interface Device {
    "rooms": Record<string, {
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
    }>,
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
            const response = await fetch(`${BKB}./api/v1.0/devices`, { signal });
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
                const response = await fetch(`${BKB}./api/v1.0/devices/${deviceId}`, { signal });
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


    render() {
        let deviceLst: Record<string, Device> = this._devicesDetailTask.value || {};
        return html`
            <!--
            <p>SmartBox: ${this._devicesTask.value} </p>
            -->
            ${Object.entries(deviceLst).map((devicer) => {
            const deviceId = devicer[0]
            const device = devicer[1]
            return html`
                    <h4>SmartBox: ${deviceId} </h4>
                    <ul>
                    <li>cseq: ${device.cseq}</li>
                    <li>results: ${JSON.stringify(device.results)}</li>
                    <li>addr: ${JSON.stringify(device.addr)}</li>
                    <li<boilerOn: ${device.boilerOn}</li>
                    <li>dhwMode: ${device.dhwMode}</li>
                    <li>tFLO: ${device.tFLO}</li>
                    <li>tdH: ${device.tdH}</li>
                    <li>tESt: ${device.tESt}</li>
                    <li>version: ${device.version}</li>
                    <li>wifisignal: ${device.wifisignal}</li>
                    <li>lastseen: ${new Date(device.lastseen * 1000)}</li>
                    ${Object.entries(device.rooms).filter((room) => room[1].lastseen).map((roomr) => {
                const room = roomr[1]
                return html`
                    <li>
                        <ul>
                        <h5>Room: ${roomr[0]} </h5>

                        <li>
                            <md-tabs aria-label="Content to view" @change="${this._changeTab}">
                                ${Array(7).fill(undefined).map((d, i) => html`
                                <md-secondary-tab id="day-${roomr[0]}-${i}" aria-controls="day-${roomr[0]}-${i}-panel">
                                ${days[i]}
                                </md-secondary-tab>
                                `)}
                            </md-tabs>

                        ${Array(7).fill(undefined).map((d, i) => html`
                        <div id="day-${roomr[0]}-${i}-panel" role="tabpanel" aria-labelledby="day-${roomr[0]}-${i}" style="position: relative; height:20vh; width:80vw;" ?hidden="${i > 0}">
                             <canvas id="${roomr[0]}-${i}" data="${JSON.stringify(room.days[i])}"></canvas>
                        </div>
                        `)}
                        </li>

                        <!--
                        <li>Program: ${JSON.stringify(room.days)}</li>
                        -->
                        <li>heating:  ${room.heating}</li>
                        <li>temp:  ${room.temp}</li>
                        <li>settemp:  ${room.settemp}</li>
                        <li>t3:  ${room.t3}</li>
                        <li>t2:  ${room.t2}</li>
                        <li>t1:  ${room.t1}</li>
                        <li>maxsetp:  ${room.maxsetp}</li>
                        <li>minsetp:  ${room.minsetp}</li>
                        <li>mode:  ${room.mode}</li>
                        <li>tempcurve:  ${room.tempcurve}</li>
                        <li>heatingsetp:  ${room.heatingsetp}</li>
                        <li>sensorinfluence:  ${room.sensorinfluence}</li>
                        <li>units:  ${room.units}</li>
                        <li>advance:  ${room.advance}</li>
                        <li>boost:  ${room.boost}</li>
                        <li>cmdissued:  ${room.cmdissued}</li>
                        <li>winter:  ${room.winter}</li>
                        <li>fakeboost:  ${room.fakeboost}</li>
                        <li>lastseen: ${new Date(room.lastseen * 1000)}</li>
                        </ul>
                    </li>
                    `
            })}
                    </ul>
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

}