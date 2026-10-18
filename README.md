# topolograph-docker
This repository runs the Community edition of Topolograph: free and self-hosted, the same product as https://topolograph.com. It covers LSDB snapshot upload, the network graph, paths, failure what-if, MPLS TE CSPF, the REST API, the SDK and MCP. Enterprise adds watchers (collectors) that feed Topolograph, BGP and EVPN routes over BMP, event history and timeline, SSO, roles, audit and priority support. Comparison and contact: https://topolograph.com/#editions.

![Topolograph graph](https://raw.githubusercontent.com/Vadims06/topolograph/master/docs/static/ui/graph-overview.png)

## Quickstart
Install Docker Desktop for Windows/Mac
To get Topolograph Docker up and running run the following commands.

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
cp env.example .env
docker-compose pull
docker-compose up -d
```
or run `install.sh` script to install Docker if needed and start Topolograph
```bash
sudo ./install.sh
```
or
```bash
curl -O https://raw.githubusercontent.com/Vadims06/topolograph-docker/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

The Topolograph site will be available after a few minutes.
Open the URL `http://localhost:8080/` in a web-browser.

![Upload an LSDB](https://raw.githubusercontent.com/Vadims06/topolograph/master/docs/static/ui/upload-lsdb.png)

## Watchers

Watchers that feed Topolograph with live events are an Enterprise feature, see [editions](https://topolograph.com/#editions). The watcher projects themselves stay free and open source and also run without Topolograph (text logs, ELK, Zabbix, Loki, webhooks); that path sends nothing to Topolograph: [ospfwatcher](https://github.com/Vadims06/ospfwatcher), [isiswatcher](https://github.com/Vadims06/isiswatcher), [bmpwatcher](https://github.com/Vadims06/bmpwatcher).

With Enterprise, a watcher is added from the Topolograph UI (Add → Watcher), which shows one install command for the watcher host. To try the BGP view without a watcher, open the demo graph: it carries BGP and EVPN data; walkthrough at https://topolograph.com/docs/rb-bgp.

## MCP Server Integration

This Docker setup includes an MCP (Model Context Protocol) server that enables AI agents and Large Language Models to interact with the Topolograph API for network analysis. The MCP server is available at `http://localhost:8000/mcp` and provides tools for:

- Network topology analysis
- OSPF/IS-IS/BGP event monitoring
- Path calculation and backup path analysis
- Graph status and connectivity monitoring
- Node and edge queries

Tools that read watcher events or event history need Enterprise data; the other tools work on uploaded graphs.

The MCP server automatically connects to the Flask API and supports authentication via API tokens.

## Variables
The application's variables are grouped in .env file
* TOPOLOGRAPH_PORT - the application port
```
TOPOLOGRAPH_PORT=8080 <-- whatever you want, and then open the URL http://localhost:8080/ after re-runing docker-compose up -d
```  
* DNS - accepts IP address of DNS server in order to resolve OSPF RID and show device names on a graph
* DNS_LOOKUP_DEADLINE_SEC - max seconds an upload waits for DNS names (default: 5). Nodes not resolved in time keep their IP as a label
* TOPOLOGRAPH_WEB_API_USERNAME_EMAIL, TOPOLOGRAPH_WEB_API_PASSWORD - credentials for API requests  
* TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS - whitelistening IP sources of API requests
* MCP_PORT - MCP server port (default: 8000)  

## Default credentials
In order to create the user with password from `.env` file and add your networks in allow list (authorised networks) from `TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS` variable - run this request  
```
#python3
import requests
res = requests.post('http://localhost:8080/create-default-credentials')
res.json()
{'errors': '', 'status': 'ok'}
```
To test that it works - Open `http://localhost:8080/` in a web-browser, go to `Login/Local login`, use `TOPOLOGRAPH_WEB_API_USERNAME_EMAIL` and `TOPOLOGRAPH_WEB_API_PASSWORD` to login. `API/Authorised source IP ranges` Tab should list your IP ranges.

## Integration with other systems

### NetBox

Hostname mapping can be updated from NetBox via the [Topolograph SDK](https://github.com/Vadims06/topolograph-sdk) or direct API calls. For example, you can query NetBox for device hostnames and push them to Topolograph using the SDK's node-update methods, keeping topology labels in sync with your source of truth.

## About
You can find more info about Topolograph here: https://github.com/Vadims06/topolograph
