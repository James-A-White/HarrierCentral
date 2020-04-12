
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
        sql: 'EXEC HC.getKennelSongCounts @userId, @accessToken, @showAllKennels, @userLatitude, @userLongitude, @distanceFromUserInKm'
        ,parameters: [ 
            { name: 'userId', value: req.body.userId },
            { name: 'accessToken', value: req.body.accessToken },
            { name: 'showAllKennels', value: req.body.showAllKennels },
            { name: 'userLatitude', value: req.body.userLatitude },
            { name: 'userLongitude', value: req.body.userLongitude },
            { name: 'distanceFromUserInKm', value: req.body.distanceFromUserInKm }
            ]};
             
             req.azureMobile.data.execute(query) 
             .then(function (results) { 
                     res.json(results); 
                 }); 
    }

};

module.exports = api;



