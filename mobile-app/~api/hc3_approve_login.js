
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
        sql: 'EXEC HC3.approveLogin @userId, @accessToken, @deviceId, @deviceType, @deviceName, @systemName, @systemVersion, @manufacturer, @latitude, @longitude, @hcVersion', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'deviceId', value: req.body.deviceId },
            { name: 'deviceType', value: req.body.deviceType },
            { name: 'deviceName', value: req.body.deviceName },
            { name: 'systemName', value: req.body.systemName },
            { name: 'systemVersion', value: req.body.systemVersion },
            { name: 'manufacturer', value: req.body.manufacturer },
            { name: 'latitude', value: req.body.latitude },
            { name: 'longitude', value: req.body.longitude },
            { name: 'hcVersion', value: req.body.hcVersion }
            ]};
            // note: this is on of the very few HC3 procs that DOES NOT return multiple result sets
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


