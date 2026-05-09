

var api = {
    post: (req, res, next) => { 
        
    var query = {
         sql: 'EXEC HC3.addEditReceipt @userId, @accessToken, @receiptId, @eventId, @receiptShortDesc,@receiptAmount,@notes,@reimbursedBy,@reimbursedOn,@reimbursedAmount,@reimbursedNotes,@imageUrl,@receiptsUpdatedAfter,@removed', 
        parameters: [   
                        { name: 'userId', value: req.body.userId },
                        { name: 'accessToken', value: req.body.accessToken },
                        { name: 'receiptId', value: req.body.receiptId },
                        { name: 'eventId', value: req.body.eventId },
                        { name: 'receiptShortDesc', value: req.body.receiptShortDesc },              
                        { name: 'receiptAmount', value: req.body.receiptAmount },
                        { name: 'notes', value: req.body.notes },
                        { name: 'reimbursedBy', value: req.body.reimbursedBy },
                        { name: 'reimbursedOn', value: req.body.reimbursedOn },
                        { name: 'reimbursedAmount', value: req.body.reimbursedAmount },
                        { name: 'reimbursedNotes', value: req.body.reimbursedNotes },
                        { name: 'imageUrl', value: req.body.imageUrl },
                        { name: 'receiptsUpdatedAfter', value: req.body.receiptsUpdatedAfter },
                        { name: 'removed', value: req.body.removed }
          ],
        multiple:true};
             
             req.azureMobile.data.execute(query) 
             .then(function (results) { 
                     res.json(results); 
                 }); 
    }

};

module.exports = api;



