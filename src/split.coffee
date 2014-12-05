# Functions for splitting SQL with APIs and what not.
request = require 'request'
sync = require 'sync'

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
    [response, body] = request.sync(request,
      uri: @url,
      method: "POST",
      form: {sql: text}
    )
    if response.statusCode != 200
      throw
        name: "SplitError"
        status: response.statusCode
        message: body
    JSON.parse(body).result.filter (s) -> s
