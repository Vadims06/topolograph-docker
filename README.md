# topolograph-docker
## Quickstart
Install Docker Desktop for Windows/Mac
To get Topolograph Docker up and running run the following commands.

```bash
git clone https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```
or run `install.sh` script to start Topolograph and Watchers
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

## MCP Server Integration

This Docker setup includes an MCP (Model Context Protocol) server that enables AI agents and Large Language Models to interact with the Topolograph API for network analysis. The MCP server is available at `http://localhost:8000/mcp` and provides tools for:

- Network topology analysis
- OSPF/IS-IS event monitoring
- Path calculation and backup path analysis
- Graph status and connectivity monitoring
- Node and edge queries

The MCP server automatically connects to the Flask API and supports authentication via API tokens.

## Variables
The application's variables are grouped in .env file
* TOPOLOGRAPH_PORT - the application port
```
TOPOLOGRAPH_PORT=8080 <-- whatever you want, and then open the URL http://localhost:8080/ after re-runing docker-compose up -d
```  
* NAPALM_USERNAME, NAPALM_PASSWORD - credentials for Napalm methods in order to login to network device and get OSPF LSDB
* DNS - accepts IP address of DNS server in order to resolve OSPF RID and show device names on a graph
~~* NETBOX_URL, NETBOX_RO_TOKEN - resolves device's hostname in Netbox, assigns devices by groups~~  
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

## About
You can find more info about Topolograph here: https://github.com/Vadims06/topolograph
