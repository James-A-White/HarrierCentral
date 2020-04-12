
//var api = {
//    get: function (req, res, next) {
//        var date = { currentTime: Date.now() };
//        res.status(200).type('application/json').send(date);
//    }
//};

//module.exports = api;


var api = {
    post: (req, res, next) => { 
   
    var query = {
        sql: 'EXEC HC3.getResetCode @userId, @accessToken, @supportCode', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'supportCode', value: req.body.supportCode }
            ]};
            // NOTE: This is one of the few HC3 apis that does not return multiple results
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }
};

module.exports = api;


