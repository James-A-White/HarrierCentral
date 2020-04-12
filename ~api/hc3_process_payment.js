
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
        sql: 'EXEC HC3.processPayment @userId, @accessToken, @userIdWhoPaid, @eventId, @hasherEventMapId, @paymentType, @productType, @paymentAmount, @minimumAttendenceValue, @hasherEventMapUpdatedAfter, @hasherKennelMapUpdatedAfter, @paymentsUpdatedAfter, @kennelCreditsUpdatedAfter, @doPayForExtras,@surcharge,@paymentProvider,@appDomainType', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'userIdWhoPaid', value: req.body.userIdWhoPaid },
            { name: 'eventId', value: req.body.eventId },
            { name: 'hasherEventMapId', value: req.body.hasherEventMapId },
            { name: 'paymentType', value: req.body.paymentType },
            { name: 'productType', value: req.body.productType },
            { name: 'paymentAmount', value: req.body.paymentAmount },
            { name: 'minimumAttendenceValue', value: req.body.minimumAttendenceValue },
            { name: 'hasherEventMapUpdatedAfter', value: req.body.hasherEventMapUpdatedAfter },
            { name: 'hasherKennelMapUpdatedAfter', value: req.body.hasherKennelMapUpdatedAfter },
            { name: 'paymentsUpdatedAfter', value: req.body.paymentsUpdatedAfter },
            { name: 'kennelCreditsUpdatedAfter', value: req.body.kennelCreditsUpdatedAfter },
            { name: 'doPayForExtras', value: req.body.doPayForExtras },
            { name: 'surcharge', value: req.body.surcharge },
            { name: 'paymentProvider', value: req.body.paymentProvider },
            { name: 'appDomainType', value: req.body.appDomainType },
            ],
        multiple:true};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;




