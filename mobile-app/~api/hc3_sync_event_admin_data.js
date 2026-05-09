

var api = {
    post: (req, res, next) => { 
        
    var query = {
         sql: 'EXEC HC3.syncEventAdminData @userId, @accessToken, @eventId, @hashersUpdatedAfter, @hasherEventMapUpdatedAfter, @hasherKennelMapUpdatedAfter, @narrowEventsUpdatedAfter, @paymentsUpdatedAfter, @receiptsUpdatedAfter, @kennelCreditsUpdatedAfter', 
        parameters: [   
                        { name: 'userId', value: req.body.userId },
                        { name: 'accessToken', value: req.body.accessToken },
                        { name: 'eventId', value: req.body.eventId },
                        { name: 'hashersUpdatedAfter', value: req.body.hashersUpdatedAfter },
                        { name: 'hasherEventMapUpdatedAfter', value: req.body.hasherEventMapUpdatedAfter },
                        { name: 'hasherKennelMapUpdatedAfter', value: req.body.hasherKennelMapUpdatedAfter },
                        { name: 'narrowEventsUpdatedAfter', value: req.body.narrowEventsUpdatedAfter },
                        { name: 'paymentsUpdatedAfter', value: req.body.paymentsUpdatedAfter },
                        { name: 'receiptsUpdatedAfter', value: req.body.receiptsUpdatedAfter },
                        { name: 'kennelCreditsUpdatedAfter', value: req.body.kennelCreditsUpdatedAfter }
          ],
        multiple:true};
             
             req.azureMobile.data.execute(query) 
             .then(function (results) { 
                     res.json(results); 
                 }); 
    }

};

module.exports = api;



