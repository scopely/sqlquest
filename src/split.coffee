# Functions for splitting SQL with APIs and what not.
request = require 'request'
_ = require 'lodash'
Q = require 'q'

module.exports =
class Splitter

  # Public: Initialize the Splitter.
  #
  # Creates an instance of Splitter with `url` initialized to the specified
  # endpoint. When {Splitter::split} is called this endpoint will be hit with a
  # *POST*.
  #
  # * `url`: (optional) {String} url to hit. Defaults to
  #   `http://sqlformat.org/api/v1/split`, but you can run your own server to do
  #    the same thing.
  #
  # Returns a {Splitter}
  constructor: (@url="http://sqlformat.org/api/v1/split") ->

  # Public: Split SQL into queries using an API.
  #
  # Hits @url with a *POST* with form param `sql` containing the sql code to be
  # split.
  #
  # * `text`: {String} sql code.
  #
  # Returns an {Array} of {String}s which should be each individual query from
  # `text`.
  split: (text) ->
    deferred = Q.defer()
    request({uri: @url, method: "POST", form: {sql: text}}, (err, response, body) ->
      if response.statusCode != 200
        deferred.reject(new Error(body))
      else
        parsed = JSON.parse(body).result.filter(_.identity).map (s) -> _.trimRight s, ';'
        deferred.resolve(parsed)
    )
    deferred.promise
