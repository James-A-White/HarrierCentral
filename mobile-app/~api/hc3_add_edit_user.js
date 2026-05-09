
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
        sql: 'EXEC HC3.addEditUser @userId, @accessToken, @hcVersion, @hashersUpdatedAfter, @hasherEventMapUpdatedAfter, @hasherKennelMapUpdatedAfter, @targetUserId, @email, @firstName, @lastName, @hashName, @photo, @includeInGlobalHashDirectory, @preferences, @eventId, @kennelId, @historicalPackRunCount,@historicalHaringCount,@historicalCountIsEstimate, @followKennelOnAddNewUser', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'hcVersion', value: req.body.hcVersion },
            { name: 'hashersUpdatedAfter', value: req.body.hashersUpdatedAfter },
            { name: 'hasherEventMapUpdatedAfter', value: req.body.hasherEventMapUpdatedAfter },
            { name: 'hasherKennelMapUpdatedAfter', value: req.body.hasherKennelMapUpdatedAfter },
            { name: 'targetUserId', value: req.body.targetUserId },
            { name: 'email', value: req.body.email },
            { name: 'firstName', value: req.body.firstName },
            { name: 'lastName', value: req.body.lastName },
            { name: 'hashName', value: req.body.hashName },
            { name: 'photo', value: req.body.photo },
            { name: 'includeInGlobalHashDirectory', value: req.body.includeInGlobalHashDirectory },
            { name: 'preferences', value: req.body.preferences },
            { name: 'eventId', value: req.body.eventId },
            { name: 'kennelId', value: req.body.kennelId },
            { name: 'historicalPackRunCount', value: req.body.historicalPackRunCount },
            { name: 'historicalHaringCount', value: req.body.historicalHaringCount },
            { name: 'historicalCountIsEstimate', value: req.body.historicalCountIsEstimate },
            { name: 'followKennelOnAddNewUser', value: req.body.followKennelOnAddNewUser }
            ],
        multiple:true};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


