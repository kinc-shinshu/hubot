module.exports = (robot) ->
  Url         = require('url')
  QueryString = require('querystring')
  Github      = require('githubot')(robot)
  OWNER       = 'kinc-shinshu'

  unless (github_api = process.env.HUBOT_GITHUB_API)?
    github_api = 'https://api.github.com'

  # notify to slack's channel_name when PR merged
  robot.router.post '/github/pull-merged', (req, res) ->
    data = req.body

    if data.action not in ['closed']
      return res.end()

    # get data from URL's query
    query        = QueryString.parse(Url.parse(req.url).query)
    channel_name = query.channel_name

    # check already merged?
    pull_request = data.pull_request

    if pull_request.merged
      robot.messageRoom channel_name, "<#{pull_request.html_url}|*\##{pull_request.number} #{pull_request.title}*> は#{pull_request.base.ref}へマージされました。"

    res.end()
