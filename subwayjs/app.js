var fs = require('fs');
var express = require('express');
var connection  = require('express-myconnection');
var mysql = require('mysql');
var repl = require('repl');

var app = express();
app.set('views', __dirname+'/views');
app.set('view engine', 'jade');

var DB_INFO = {
        host: 'localhost',
        user: 'root',
        password : '',
        port : 3306, //port mysql
        database:'subway'
      }

console.log("DB_INFO: "+JSON.stringify(DB_INFO));

app.use(connection(mysql, DB_INFO,'request'));

//var connection = mysql.createConnection(DB_INFO);
//connection.connect(); 
//
//connection.query('SELECT * FROM LOOKUP_TBL', function(err, rows, fields) {
//    if (err) console.log('Connection result error '+err);
//    console.log(rows[0]);
//});

app.use("/", express.static(__dirname + '/static'));

app.get('/R68', function(req, res){
      req.getConnection(function(err,connection){
          connection.query('SELECT * FROM LOOKUP_TBL',function(err,rows) {
              if(err) console.log("Error Selecting : %s ",err );
              res.render('customers',{page_title:"Customers - Node.js",data:rows});
              console.log(rows);
          });
      });
});

var server = app.listen(4000, function() {
    console.log('Listening on port %d', server.address().port);
});

//repl.start({
//  prompt: "node repl> ",
//    input: process.stdin,
//      output: process.stdout
//      });
