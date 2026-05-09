
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
        sql: 'EXEC HC3.processFacebookLogin @userId, @accessToken, @hashersUpdatedAfter, @firstName, @lastName, @hashName, @email,@photo, @facebookId, @facebookAccessToken, @includeInGlobalHashDirectory, @hcVersion', 
        parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'hashersUpdatedAfter', value: req.body.hashersUpdatedAfter },
            { name: 'firstName', value: req.body.firstName },
            { name: 'lastName', value: req.body.lastName },
            { name: 'hashName', value: req.body.hashName },
            { name: 'email', value: req.body.email },
            { name: 'photo', value: req.body.photo },
            { name: 'facebookId', value: req.body.facebookId },
            { name: 'facebookAccessToken', value: req.body.facebookAccessToken },
            { name: 'includeInGlobalHashDirectory', value: req.body.includeInGlobalHashDirectory },
            { name: 'hcVersion', value: req.body.hcVersion },
            ]};
            // NOTE: This is one of the few HC3 apis that does not return multiple results
             
        req.azureMobile.data.execute(query)
            .then(function (results) {
                res.json(results);
            });
    }
};

module.exports = api;



