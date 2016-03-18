https = require 'https'
http  = require 'http'
querystring = require 'querystring'
methods =
  get: 'GET'
  put: 'PUT'
  post: 'POST'
  delete: 'DELETE'

class DestinyClient

  constructor: (@apiKey, options = {}) ->
    @host = options.host or 'www.bungie.net'
    @ssl  = options.ssl or true
    @port = options.port or 443

  searchDestinyPlayer: (membershipType, displayName, callback) ->
    unless callback?
      if typeof displayName == 'function'
        callback = displayName

    # default membershipType to XBOX
    if typeof membershipType == 'string'
      displayName = membershipType
      membershipType = 1

    @_performRequest methods.get, "/Platform/Destiny/SearchDestinyPlayer/#{membershipType}/#{displayName}/", null, callback

  # Account info
  getAccountSummary: (membershipType, membershipId, callback) ->
    @_performRequest methods.get, "/Platform/Destiny/#{membershipType}/Account/#{membershipId}/Summary/?definitions=true", null, callback

  getCharacter: (membershipType, membershipId, characterId, callback) ->
    @_performRequest methods.get, "/Platform/Destiny/#{membershipType}/Account/#{membershipId}/Character/#{characterId}/?definitions=true", null, callback

  getCharacterStats: (membershipType, membershipId, characterId, callback) ->
    @_performRequest methods.get, "/Platform/Destiny/Stats/#{membershipType}/#{membershipId}/#{characterId}/", null, callback

  getAccountStats: (membershipType, membershipId, callback) ->
    @_performRequest methods.get, "/Platform/Destiny/Stats/Account/#{membershipType}/#{membershipId}/", null, callback

  getCharacterActivityStats: (membershipType, membershipId, characterId, callback) ->
    @_performRequest methods.get, "/Platform/Destiny/Stats/AggregateActivityStats/#{membershipType}/#{membershipId}/#{characterId}/?definitions=true", null, callback

  getActivityHistory: (membershipType, membershipId, characterId, options = {}, callback) ->
    options =
      params:
        mode: 0
    @_performRequest methods.get, "/Platform/Destiny/Stats/ActivityHistory/#{membershipType}/#{membershipId}/#{characterId}/", options, callback

  _performRequest: (method, uri, options = {}, callback) ->
    processor = @_processResponse
    reqOptions =
      method: method
      hostname: @host
      port: @port
      path: uri
      headers: 'x-api-key': @apiKey

    reqOptions.path += '?'+querystring.stringify options.params if options.params?
    console.log reqOptions.path
    req = https.request(reqOptions, (res) ->
      chunks = []
      res.on 'data', (chunk) ->
        chunks.push chunk

      res.on 'end', ->
        body = Buffer.concat(chunks)
        processor body.toString(), callback
    )
    req.end()

  _processResponse: (response, callback) ->
    if typeof response == 'string'
      try
        response = JSON.parse response
      catch error
        return callback 'Unable to parse API response', response

    unless response['ErrorStatus'] == 'Success'
      console.error '[destiny-client] ' + response['Message']
      return callback response['Message']
    callback null, response['Response']

module.exports = DestinyClient
