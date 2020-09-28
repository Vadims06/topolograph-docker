# topolograph-docker
## Quickstart

To get Topolograph Docker up and running run the following commands.

```bash
git clone -b release https://github.com/Vadims06/topolograph-docker.git
cd topolograph-docker
docker-compose pull
docker-compose up -d
```

The Topolograph site will be available after a few minutes.
Open the URL `http://localhost/` in a web-browser.

## User config
It's possible to set login and password for Napalm methods (in order to login to network device and get OSPF LSDB) as well as DNS server in `docker-compose.override.yml`.
* edit and save `docker-compose.override.yml`
* run docker-compose up -d
