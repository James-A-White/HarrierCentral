
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
        sql: 'EXEC HC2.processQrScanForCheckin @userId, @accessToken, @eventId, @scanText, @runStartOrEnd, @selfScan', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'eventId', value: req.body.eventId },
            { name: 'scanText', value: req.body.scanText },
            { name: 'runStartOrEnd', value: req.body.context1 },
            { name: 'selfScan', value: req.body.context2 }
            ]};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


