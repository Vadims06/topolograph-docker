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

The Topolograph site will be available after a few minutes.
Open the URL `http://localhost:8080/` in a web-browser.

## Variables
The application's variables are grouped in .env file
* TOPOLOGRAPH_PORT - the application port
```
TOPOLOGRAPH_PORT=8099 <-- whatever you want, and then open the URL http://localhost:8099/ after re-runing docker-compose up -d
```  
* NAPALM_USERNAME, NAPALM_PASSWORD - credentials for Napalm methods in order to login to network device and get OSPF LSDB
* DNS - accepts IP address of DNS server in order to resolve OSPF RID and show device names on a graph
* NETBOX_URL, NETBOX_RO_TOKEN - resolves device's hostname in Netbox, assigns devices by groups  
* TOPOLOGRAPH_WEB_API_USERNAME_EMAIL, TOPOLOGRAPH_WEB_API_PASSWORD - credentials for API requests  
* TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS - whitelistening IP sources of API requests  


## About
You can find more info about Topolograph here: https://github.com/Vadims06/topolograph
