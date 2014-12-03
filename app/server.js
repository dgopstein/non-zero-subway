var http = require('http')
var express = require('express')

var port = 3000

var app = require('express')(),
    server = require('http').createServer(app),
        fs = require('fs');
        server.listen(3000);

app.use(express.static('./'));

console.log('Listening on port '+port);
