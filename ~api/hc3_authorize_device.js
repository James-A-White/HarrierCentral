
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
        sql: 'EXEC HC3.authorizeDevice @userId, @accessToken, @hcVersion, @scanText, @deviceId, @includeInGlobalHashDirectory', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'hcVersion', value: req.body.hcVersion },
            { name: 'scanText', value: req.body.scanText },
            { name: 'deviceId', value: req.body.deviceId },
            { name: 'includeInGlobalHashDirectory', value: req.body.includeInGlobalHashDirectory },
            
            ]};
            // NOTE: This is one of the few HC3 apis that does not return multiple results
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }
};

module.exports = api;


