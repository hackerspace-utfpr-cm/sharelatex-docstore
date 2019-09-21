request = require("request").defaults(jar: false)
{db, ObjectId} = require("../../../../app/js/mongojs")
settings = require("settings-sharelatex")
DocArchiveManager = require("../../../../app/js/DocArchiveManager.js")

module.exports = DocstoreClient =

	createDoc: (project_id, doc_id, lines, version, ranges, callback = (error) ->) ->
		DocstoreClient.updateDoc project_id, doc_id, lines, version, ranges, callback

	getDoc: (project_id, doc_id, qs, callback = (error, res, body) ->) ->
		request.get {
			url: "http://localhost:#{settings.internal.docstore.port}/project/#{project_id}/doc/#{doc_id}"
			json: true
			qs:qs
		}, callback

	getAllDocs: (project_id, callback = (error, res, body) ->) ->
		request.get {
			url: "http://localhost:#{settings.internal.docstore.port}/project/#{project_id}/doc"
			json: true
		}, callback

	getAllRanges: (project_id, callback = (error, res, body) ->) ->
		request.get {
			url: "http://localhost:#{settings.internal.docstore.port}/project/#{project_id}/ranges"
			json: true
		}, callback

	updateDoc: (project_id, doc_id, lines, version, ranges, callback = (error, res, body) ->) ->
		request.post {
			url: "http://localhost:#{settings.internal.docstore.port}/project/#{project_id}/doc/#{doc_id}"
			json:
				lines: lines
				version: version
				ranges: ranges
		}, callback

	deleteDoc: (project_id, doc_id, callback = (error, res, body) ->) ->
		request.del {
			url: "http://localhost:#{settings.internal.docstore.port}/project/#{project_id}/doc/#{doc_id}"
		}, callback	
		
	archiveAllDoc: (project_id, callback = (error, res, body) ->) ->
		request.post {
			url: "http://localhost:#{settings.internal.docstore.port}/project/#{project_id}/archive"
		}, callback

	destroyAllDoc: (project_id, callback = (error, res, body) ->) ->
		request.post {
			url: "http://localhost:#{settings.internal.docstore.port}/project/#{project_id}/destroy"
		}, callback

	getS3Doc: (project_id, doc_id, callback = (error, res, body) ->) ->
		options = DocArchiveManager.buildS3Options(project_id+"/"+doc_id)
		options.json = true
		request.get options, callback
