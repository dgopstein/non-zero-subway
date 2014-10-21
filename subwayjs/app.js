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

//console.log("DB_INFO: "+JSON.stringify(DB_INFO));

app.use(connection(mysql, DB_INFO,'request'));

//var connection = mysql.createConnection(DB_INFO);
//connection.connect(); 
//
//connection.query('SELECT * FROM LOOKUP_TBL', function(err, rows, fields) {
//    if (err) console.log('Connection result error '+err);
//    console.log(rows[0]);
//});

app.use("/", express.static(__dirname + '/static'));

function withLookupRows(callback) {
  var connection = mysql.createConnection(DB_INFO);
  connection.connect();
  connection.query('SELECT * FROM LOOKUP_TBL',function(err,rows) {
      if(err) console.log("Error Selecting : %s ",err );
      callback(rows);
  });
}

function buildFloorPlan(rows, callback) {
  var plans = {};

  for (var i = 0; i < rows.length; i++) {
      var row = rows[i];
      var plan = (plans[row['Car_Class']] = plans[row['Car_Class']] || {});
      plan[row['Space']] = row['Position'];
  }

  callback(plans);
}


app.get('/R68', function(req, res){
  withLookupRows(function(rows) {
      buildFloorPlan(rows, function(plans) {
          console.log("plan R68: \n", plans);
          res.send(plans);
      })
   })
});

var server = app.listen(4000, function() {
    console.log('Listening on port %d', server.address().port);
});

//repl.start({
//  prompt: "node repl> ",
//    input: process.stdin,
//      output: process.stdout
//      });
