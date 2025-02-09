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
TOPOLOGRAPH_PORT=8080 <-- whatever you want, and then open the URL http://localhost:8080/ after re-runing docker-compose up -d
```  
* NAPALM_USERNAME, NAPALM_PASSWORD - credentials for Napalm methods in order to login to network device and get OSPF LSDB
* DNS - accepts IP address of DNS server in order to resolve OSPF RID and show device names on a graph
~~* NETBOX_URL, NETBOX_RO_TOKEN - resolves device's hostname in Netbox, assigns devices by groups~~  
* TOPOLOGRAPH_WEB_API_USERNAME_EMAIL, TOPOLOGRAPH_WEB_API_PASSWORD - credentials for API requests  
* TOPOLOGRAPH_WEB_API_AUTHORISED_NETWORKS - whitelistening IP sources of API requests  

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
