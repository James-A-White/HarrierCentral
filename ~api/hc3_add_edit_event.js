
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
        sql: 'EXEC HC3.addEditEvent @userId,@accessToken,@narrowEventsUpdatedAfter,@eventId,@KennelId,@startDatetime,@endDatetime,@isCountedRun,@isVisible,@isPromotedEvent,@eventGeographicScope,@themeRunType,@eventName,@eventDescription,@locationCity,@locationStreet,@locationPostCode,@locationCountry,@locationOneLineDesc,@eventFacebookid,@coverPhotoUrl,@coverPhotoOffsetX,@coverPhotoOffsetY,@latitude,@longitude,@fbLatitude,@fbLongitude,@eventPriceForMembers,@eventPriceForNonMembers,@absoluteEventNumber,@eventCurrencyType,@deleted',
        parameters: [
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'narrowEventsUpdatedAfter', value: req.body.narrowEventsUpdatedAfter },
            { name: 'eventId', value: req.body.eventId },
            { name: 'kennelId', value: req.body.kennelId },
            { name: 'startDatetime', value: req.body.startDatetime },
            { name: 'endDatetime', value: req.body.endDatetime },
            { name: 'isCountedRun', value: req.body.isCountedRun },
            { name: 'isVisible', value: req.body.isVisible },
            { name: 'isPromotedEvent', value: req.body.isPromotedEvent },
            { name: 'eventGeographicScope', value: req.body.eventGeographicScope },
            { name: 'themeRunType', value: req.body.themeRunType },
            { name: 'eventName', value: req.body.eventName },
            { name: 'eventDescription', value: req.body.eventDescription },
            { name: 'locationCity', value: req.body.locationCity },
            { name: 'locationStreet', value: req.body.locationStreet },
            { name: 'locationPostCode', value: req.body.locationPostCode },
            { name: 'locationCountry', value: req.body.locationCountry },
            { name: 'locationOneLineDesc', value: req.body.locationOneLineDesc },
            { name: 'eventFacebookId', value: req.body.eventFacebookId },
            { name: 'coverPhotoUrl', value: req.body.coverPhotoUrl },
            { name: 'coverPhotoOffsetX', value: req.body.coverPhotoOffsetX },
            { name: 'coverPhotoOffsetY', value: req.body.coverPhotoOffsetY },
            { name: 'latitude', value: req.body.latitude },
            { name: 'longitude', value: req.body.longitude },
            { name: 'fbLatitude', value: req.body.fbLatitude },
            { name: 'fbLongitude', value: req.body.fbLongitude },
            { name: 'eventPriceForMembers', value: req.body.eventPriceForMembers },            
            { name: 'eventPriceForNonMembers', value: req.body.eventPriceForNonMembers },
            { name: 'absoluteEventNumber', value: req.body.absoluteEventNumber },
            { name: 'eventCurrencyType', value: req.body.eventCurrencyType },
            { name: 'deleted', value: req.body.deleted }
            ],
        multiple:true};
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }

};

module.exports = api;


