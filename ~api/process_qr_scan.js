
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
        sql: 'EXEC HC.processQrScan @userId, @accessToken, @eventId, @scanText, @context1, @context2, @param1, @param2', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'eventId', value: req.body.eventId },
            { name: 'scanText', value: req.body.scanText },
            { name: 'context1', value: req.body.context1 },
            { name: 'context2', value: req.body.context2 },
            { name: 'param1', value: req.body.param1 },
            { name: 'param2', value: req.body.param2 } 
            ]};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


