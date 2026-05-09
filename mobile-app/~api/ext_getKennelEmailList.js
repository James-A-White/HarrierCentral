


var api = {
    get: function (req, res, next) {
        
        var query = {
            sql: 'EXEC HC3.extApi_getKennelEmailList @kennelExtApiKey',
            parameters: [{ name: 'kennelExtApiKey', value: req.query.kennelExtApiKey }]
        };

        req.azureMobile.data.execute(query).then(function (results) {
            //console.log(results);
            res.json(results);
        });
    }
};

module.exports = api;





