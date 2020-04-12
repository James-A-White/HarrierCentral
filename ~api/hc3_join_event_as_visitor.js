
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
        sql: 'EXEC HC3.joinEventAsVisitor @userId, @accessToken, @eventId, @displayName, @virginVisitorType, @attendenceState, @email, @phoneNumber,@hasherEventMapUpdatedAfter,@paymentsUpdatedAfter', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'eventId', value: req.body.eventId },
            { name: 'displayName', value: req.body.displayName },
            { name: 'virginVisitorType', value: req.body.virginVisitorType },
            { name: 'attendenceState', value: req.body.attendenceState },
            { name: 'email', value: req.body.email },
            { name: 'phoneNumber', value: req.body.phoneNumber },
            { name: 'hasherEventMapUpdatedAfter', value: req.body.hasherEventMapUpdatedAfter },
            { name: 'paymentsUpdatedAfter', value: req.body.paymentsUpdatedAfter }
            
             ],
        multiple:true};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


