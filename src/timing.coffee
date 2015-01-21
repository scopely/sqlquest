module.exports =

  # Public: Time a function.
  #
  # * `promptId` {String} to use for prompting. Make sure this string is
  #   different for each nested time call, because this is used to determine
  #   which thing we're timing at any given point.
  # * `f` {Function} to time.
  #
  # Returns the result of the function call.
  time: (promptId, f) ->
    console.time promptId
    result = f()
    console.timeEnd promptId
    result
