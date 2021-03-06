module.exports = (robot) ->
  Url         = require('url')
  QueryString = require('querystring')
  Github      = require('githubot')(robot)
  OWNER       = 'kinc-shinshu'
  TERM        = 'reviewer'

  unless (github_api = process.env.HUBOT_GITHUB_API)?
    github_api = 'https://api.github.com'

  # choose reviewer without pull request's author
  chooseReviewer = (pull_request_author) ->
    users = ['arsley', 'bieshan', 'yoidea']
    # Github.get "#{github_api}/teams/#{TERM}/members", (res_members, error) ->
    #   for member, _index in res_members
    #     users.push member.login

    candidates = users.filter((u) -> u != pull_request_author)
    index = Math.floor Math.random() * candidates.length
    candidates[index]

  # assign reviewer to PR
  robot.router.post '/github/pull-review', (req, res) ->
    data = req.body

    # assign reviewer only open, reopened
    if data.action not in ['opened', 'reopened']
      return res.end()

    # get data from URL's query
    # channel_name is notified channel when reviewer assigned
    query        = QueryString.parse(Url.parse(req.url).query)
    channel_name = query.channel_name

    # check already assigned?
    pull_request = data.pull_request
    if pull_request.requested_reviewers.length > 0
      robot.messageRoom channel_name, "<#{pull_request.html_url}|*\##{pull_request.number} #{pull_request.title}*> にはすでにアサイン済みです。"
      return res.end()

    reviewer = chooseReviewer(pull_request.user.login)

    repo = data.repository.name
    url  = "#{github_api}/repos/#{OWNER}/#{repo}/pulls/#{pull_request.number}/requested_reviewers"
    data = { 'reviewers': [reviewer] }

    Github.post url, data, (res_pull_req, err) ->
      if !res_pull_req?
        robot.messageRoom '#debug', "Auto assign error \##{pull_request.number}."
        return

      body = "<#{pull_request.html_url}|*\##{pull_request.number} #{pull_request.title}*> のレビュワーは *#{reviewer}* になりました。"
      robot.messageRoom channel_name, body
      res.end()
