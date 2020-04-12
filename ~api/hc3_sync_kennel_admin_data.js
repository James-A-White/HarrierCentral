

var api = {
    post: (req, res, next) => { 
        
    var query = {
         sql: 'EXEC HC3.syncKennelAdminData @userId, @accessToken, @kennelId, @hashersUpdatedAfter, @kennelsUpdatedAfter, @hasherKennelMapUpdatedAfter', 
        parameters: [   
                        { name: 'userId', value: req.body.userId },
                        { name: 'accessToken', value: req.body.accessToken },
                        { name: 'kennelId', value: req.body.kennelId },
                        { name: 'hashersUpdatedAfter', value: req.body.hashersUpdatedAfter },
                        { name: 'kennelsUpdatedAfter', value: req.body.kennelsUpdatedAfter },
                        { name: 'hasherKennelMapUpdatedAfter', value: req.body.hasherKennelMapUpdatedAfter }
          ],
        multiple:true};
             
             req.azureMobile.data.execute(query) 
             .then(function (results) { 
                     res.json(results); 
                 }); 
    }

};

module.exports = api;



