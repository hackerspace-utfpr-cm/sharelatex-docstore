{db, ObjectId} = require "./mongojs"
logger = require 'logger-sharelatex'
metrics = require 'metrics-sharelatex'

module.exports = MongoManager =

	findDoc: (project_id, doc_id, filter, callback = (error, doc) ->) ->
		db.docs.find {_id: ObjectId(doc_id.toString()), project_id: ObjectId(project_id.toString())}, filter, (error, docs = []) ->
			callback error, docs[0]

	getProjectsDocs: (project_id, options = {include_deleted: true}, filter, callback)->
		query = {project_id: ObjectId(project_id.toString())}
		if !options.include_deleted
			query.deleted = { $ne: true }
		db.docs.find query, filter, callback

	getArchivedProjectDocs: (project_id, callback)->
		query =
			project_id: ObjectId(project_id.toString())
			inS3: true
		db.docs.find query, {}, callback

	upsertIntoDocCollection: (project_id, doc_id, updates, callback)->
		update =
			$set: updates
			$inc:
				rev: 1
			$unset:
				inS3: true
		update.$set["project_id"] = ObjectId(project_id)
		db.docs.update _id: ObjectId(doc_id), update, {upsert: true}, callback

	markDocAsDeleted: (project_id, doc_id, callback)->
		db.docs.update {
			_id: ObjectId(doc_id),
			project_id: ObjectId(project_id) 
		}, {
			$set: { deleted: true }
		}, callback

	markDocAsArchived: (doc_id, rev, callback)->
		update =
			$set: {}
			$unset: {}
		update.$set["inS3"] = true
		update.$unset["lines"] = true
		update.$unset["ranges"] = true
		query =
			_id: doc_id
			rev: rev
		db.docs.update query, update, (err)->
			callback(err)
	
	getDocVersion: (doc_id, callback = (error, version) ->) ->
		db.docOps.find {
			doc_id: ObjectId(doc_id)
		}, {
			version: 1
		}, (error, docs) ->
			return callback(error) if error?
			if docs.length < 1 or !docs[0].version?
				return callback null, 0
			else
				return callback null, docs[0].version

	setDocVersion: (doc_id, version, callback = (error) ->) ->
		db.docOps.update {
			doc_id: ObjectId(doc_id)
		}, {
			$set: version: version
		}, {
			upsert: true
		}, callback

	destroyDoc: (doc_id, callback) ->
		db.docs.remove {
			_id: ObjectId(doc_id)
		}, (err) ->
			return callback(err) if err?
			db.docOps.remove {
				doc_id: ObjectId(doc_id)
			}, callback

[
	'findDoc',
	'getProjectsDocs',
	'getArchivedProjectDocs',
	'upsertIntoDocCollection',
	'markDocAsArchived',
	'getDocVersion',
	'setDocVersion'
].map (method) ->
	metrics.timeAsyncMethod(MongoManager, method, 'mongo.MongoManager', logger)
