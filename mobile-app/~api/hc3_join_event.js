
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
        sql: 'EXEC HC3.joinEvent @userId,@accessToken,@eventId,@hasherId,@hasherEventMapId,@isHare,@rsvpState,@attendenceState,@virginVisitorType,@notificationState,@emailAlertState,@hasherEventMapUpdatedAfter,@hasherKennelMapUpdatedAfter,@paymentsUpdatedAfter,@kennelCreditsUpdatedAfter', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'eventId', value: req.body.eventId },
            { name: 'hasherId', value: req.body.hasherId },
            { name: 'hasherEventMapId', value: req.body.hasherEventMapId },
            { name: 'isHare', value: req.body.isHare },
            { name: 'rsvpState', value: req.body.rsvpState},
            { name: 'attendenceState', value: req.body.attendenceState},
            { name: 'virginVisitorType', value: req.body.virginVisitorType},
            { name: 'notificationState', value: req.body.notificationState},
            { name: 'emailAlertState', value: req.body.emailAlertState},
            { name: 'hasherEventMapUpdatedAfter', value: req.body.hasherEventMapUpdatedAfter},
            { name: 'hasherKennelMapUpdatedAfter', value: req.body.hasherKennelMapUpdatedAfter},
            { name: 'paymentsUpdatedAfter', value: req.body.paymentsUpdatedAfter},
            { name: 'kennelCreditsUpdatedAfter', value: req.body.kennelCreditsUpdatedAfter}
            
           ],
        multiple:true};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


