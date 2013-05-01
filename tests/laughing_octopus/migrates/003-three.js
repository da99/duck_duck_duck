var Topogo = require("topogo").Topogo; 
                                         
var m = module.exports = {};             
                                         
m.migrate = function (dir, r) {          
                                         
  if (dir === 'down') {                  
                                         
    var sql = '';                        
    Topogo.run(sql, [], r);              
                                         
  } else {                               
                                         
    var sql = '';                        
    Topogo.run(sql, [], r);              
                                         
  }                                      
                                         
                                         
};