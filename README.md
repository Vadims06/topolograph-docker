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
Open the URL `http://localhost/` in a web-browser.

## User config
### Username and Password for Napalm (optional)
It's possible to set login and password for Napalm methods (in order to login to network device and get OSPF LSDB) as well as DNS server in `docker-compose.override.yml`.
* edit and save `docker-compose.override.yml`
* run docker-compose up -d

## About
You can find more info about Topolograph here [topolograph]: https://github.com/Vadims06/topolograph
