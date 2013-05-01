var fs = require('fs');
var path = require('path');
var num = parseInt(path.basename(__filename));

exports.migrate = function (dir, river) {
  var sign = (dir === 'up') ? '+' : '-';
  var txt = sign + num;
  fs.appendFile('/tmp/duck_down', txt, function (err) {
    if (err) throw err;
    river.finish(txt);
  });
};
