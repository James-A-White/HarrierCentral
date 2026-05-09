
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
         sql: 'EXEC HC.getFriends @userId, @accessToken, @kennelId, @latitude, @longitude, @distanceInKm', 
        parameters: [   { name: 'userId', value: req.body.userId },
                        { name: 'accessToken', value: req.body.accessToken },
                        { name: 'kennelId', value: req.body.kennelId },
                        { name: 'latitude', value: req.body.latitude },
                        { name: 'longitude', value: req.body.longitude },
                        { name: 'distanceInKm', value: req.body.distanceInKm }
            ]};
             
             req.azureMobile.data.execute(query) 
             .then(function (results) { 
                     res.json(results); 
                 }); 
    }

};

module.exports = api;


