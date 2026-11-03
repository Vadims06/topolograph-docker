# topolograph-docker
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

## Upgrading MongoDB
Since November 2026 `docker-compose.yml` runs MongoDB 8.0. An install created with MongoDB 4.2 keeps its data
in a format 8.0 cannot open: the `mongodb` container stops with `UPGRADE PROBLEM` and your data stays untouched.
Move the data with a dump and a restore:

```bash
# 0. MongoDB 5.0 and later need a CPU with AVX; no output here means stay on 4.2
grep -m1 -o avx /proc/cpuinfo
# 1. with the old docker-compose.yml (mongo:4.2), dump the Topolograph data
docker-compose up -d mongodb
docker-compose exec -T mongodb sh -c 'mongodump --archive --gzip -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --db "$MONGO_INITDB_DATABASE" --excludeCollection system.users --excludeCollection system.version' > topolograph-mongo42.archive.gz
ls -lh topolograph-mongo42.archive.gz   # must not be empty; keep it until step 4 succeeds
# 2. remove the old data volume
docker-compose down
docker volume ls | grep mongodbdata
docker volume rm <the volume listed above>
# 3. take the new docker-compose.yml and start MongoDB 8.0 with an empty volume
git pull
docker-compose up -d mongodb
# 4. restore, then start everything
docker-compose exec -T mongodb sh -c 'mongorestore --archive --gzip -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin' < topolograph-mongo42.archive.gz
docker-compose up -d
```

To go back, check out the previous `docker-compose.yml`, remove the volume again and restore the same archive into MongoDB 4.2.

## Watchers

`install.sh` sets up the OSPF and IS-IS watchers (GRE or BGP-LS) as
containerlab labs. The **BMP Watcher** for the BGP control plane runs beside
your routers rather than in this compose stack, since routers dial in to it
over BMP; choose it in `install.sh` for the setup steps, or see the
[bmpwatcher README](https://github.com/Vadims06/bmpwatcher). To try the BGP
view without any of this, open Topolograph — the generated BGP demo topology
loads on first visit; walkthrough at `https://topolograph.com/how-to/bgp`.

## MCP Server Integration

This Docker setup includes an MCP (Model Context Protocol) server that enables AI agents and Large Language Models to interact with the Topolograph API for network analysis. The MCP server is available at `http://localhost:8000/mcp` and provides tools for:

- Network topology analysis
- OSPF/IS-IS/BGP event monitoring
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
