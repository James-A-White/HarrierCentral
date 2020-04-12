
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
        sql: 'EXEC HC2.authorizeDevice @userId, @accessToken, @hcVersion, @scanText, @deviceId', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },            
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'hcVersion', value: req.body.hcVersion },
            { name: 'scanText', value: req.body.scanText },
            { name: 'deviceId', value: req.body.deviceId }
            ]};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


