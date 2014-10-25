var phaser = new Phaser.Game(1000, 600, Phaser.AUTO, 'plan-view', { preload: preload, create: create, update: update });
$.ajaxSetup({async:false});

function removeElem(arr, elem) {
    var idx = arr.indexOf(elem);
    arr.splice(idx, 1);
}

function getCarPlan(carClass) {
    console.log("getting car plan");
    var plans;
    $.get("/db/LOOKUP_TBL.csv", function(res) {
      console.log(res);
      //var r68 = JSON.parse(res);
      plans = res;
    });
    return plans[carClass];
}

function preload() {
	phaser.stage.backgroundColor = '#6ec4ce';
}

function create() {
    var car = phaser.add.graphics(100, 100);

    var plan = getCarPlan('R68');

    var SpaceSize = 20;
    var colors = [0x0000FF, 0x00FF00, 0xFF0000];
    
    for (var space in plan) {
      console.log(space, plan[space]);
      var col = space.match(/[0-9.]*/i)[0];
      var rowChar = space.match(/[a-z]/)[0];
      console.log(col);
      console.log(rowChar);
      var row = rowChar.charCodeAt(0) - 'a'.charCodeAt(0);

      var x = col*SpaceSize;
      var y = row*SpaceSize;

      var spaceType = plan[space];

      car.lineStyle(2, colors[spaceType], 1);
      car.drawRect(x, y, SpaceSize, SpaceSize);
    }
}

function timeInfo(x, y, color) {
	phaser.time.advancedTiming = true;
	phaser.debug.start(x, y, color);
	phaser.debug.line('FPS: ' + phaser.time.fps);
	phaser.debug.line('elapsed: '+ phaser.time.elapsed);
	phaser.debug.stop();
}

function update() {
    // time in seconds
	var elapsed = phaser.time.elapsed / 1000.0;

	timeInfo(32, 32);
}

