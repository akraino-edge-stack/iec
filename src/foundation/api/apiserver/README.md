# Welcome to IEC API Server

The IEC API server is built on Revel web framework. So the following information is
inherited from [Revel](https://github.com/revel/revel).
We changed the default listening port of Revel from 9000 to 9131, which may be special
for IEC use.

# Welcome to Revel

A high-productivity web framework for the [Go language](http://www.golang.org/).


### Start the web server:

    revel run apiserver prod

### Go to http://localhost:9131/v1/iec/status and you'll see:

    {"Status":"ok","Passed":true}

## Code Layout

The directory structure of a generated Revel application:

    conf/             Configuration directory
        app.conf      Main app configuration file
        routes        Routes definition file

    app/              App sources
        init.go       Interceptor registration
        controllers/  App controllers go here
        views/        Templates directory

    messages/         Message files

    public/           Public static assets
        css/          CSS files
        js/           Javascript files
        images/       Image files

    tests/            Test suites


## Help

* The [Getting Started with Revel](http://revel.github.io/tutorial/gettingstarted.html).
* The [Revel guides](http://revel.github.io/manual/index.html).
* The [Revel sample apps](http://revel.github.io/examples/index.html).
* The [API documentation](https://godoc.org/github.com/revel/revel).

