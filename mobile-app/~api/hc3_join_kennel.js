
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
        sql: 'EXEC HC3.joinKennel @userId,@accessToken,@kennelId, @targetUserId, @isFollowing, @isHomeKennel, @notificationState, @emailAlertState, @monthsToAddToMembership, @paymentAmount, @kennelsUpdatedAfter, @hasherKennelMapUpdatedAfter, @hashersUpdatedAfter', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'kennelId', value: req.body.kennelId },
            { name: 'targetUserId', value: req.body.targetUserId },
            { name: 'isFollowing', value: req.body.isFollowing },
            { name: 'isMember', value: req.body.isMember },
            { name: 'isHomeKennel', value: req.body.isHomeKennel},
            { name: 'notificationState', value: req.body.notificationState},
            { name: 'emailAlertState', value: req.body.emailAlertState},
            { name: 'monthsToAddToMembership', value: req.body.monthsToAddToMembership},
            { name: 'paymentAmount', value: req.body.paymentAmount},
            { name: 'kennelsUpdatedAfter', value: req.body.kennelsUpdatedAfter},
            { name: 'hasherKennelMapUpdatedAfter', value: req.body.hasherKennelMapUpdatedAfter},
            { name: 'hashersUpdatedAfter', value: req.body.hashersUpdatedAfter}
           ],
        multiple:true};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


