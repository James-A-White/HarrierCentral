

var api = {
    post: (req, res, next) => { 
        
    var query = {
         sql: 'EXEC HC3.syncUserData @userId, @accessToken,@hashersUpdatedAfter,@citiesUpdatedAfter,@regionsUpdatedAfter,@countriesUpdatedAfter,@kennelsUpdatedAfter,@hasherKennelMapUpdatedAfter,@hasherEventMapUpdatedAfter,@narrowEventsUpdatedAfter,@paymentsUpdatedAfter', 
        parameters: [   
                        { name: 'userId', value: req.body.userId },
                        { name: 'accessToken', value: req.body.accessToken },
                        { name: 'hashersUpdatedAfter', value: req.body.hashersUpdatedAfter },
                        { name: 'citiesUpdatedAfter', value: req.body.citiesUpdatedAfter },
                        { name: 'regionsUpdatedAfter', value: req.body.regionsUpdatedAfter },
                        { name: 'countriesUpdatedAfter', value: req.body.countriesUpdatedAfter },
                        { name: 'kennelsUpdatedAfter', value: req.body.kennelsUpdatedAfter },
                        { name: 'hasherKennelMapUpdatedAfter', value: req.body.hasherKennelMapUpdatedAfter },
                        { name: 'hasherEventMapUpdatedAfter', value: req.body.hasherEventMapUpdatedAfter },
                        { name: 'narrowEventsUpdatedAfter', value: req.body.narrowEventsUpdatedAfter },
                        { name: 'paymentsUpdatedAfter', value: req.body.paymentsUpdatedAfter },
          ],
        multiple:true};
             
             req.azureMobile.data.execute(query) 
             .then(function (results) { 
                     res.json(results); 
                 }); 
    }

};

module.exports = api;



