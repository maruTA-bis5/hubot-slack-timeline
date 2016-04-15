# Description:
#   send all of the messages on Mattermost in #timeline
#
# Configuration:
#   create #timeline channel on your Mattermost team
#
# Notes:
#   None
#
# Author:
#   maruTA-bis5

module.exports = (robot) ->
  robot.hear /.*?/i, (msg) ->
    if msg.envelope.room == 'cpgjs5znmfr7mxhcrae655t7jw'
      return

    user_id = msg.message.user.id
    channel_id = msg.envelope.room
    requestChannelName(robot, channel_id)
    #console.log robot.brain.data
    if robot.brain.data.channelName[channel_id]
      channelName = robot.brain.data.channelName[channel_id]
    else 
      channelName = channel_id
    payload = JSON.stringify({
      text: msg.message.text
      username: msg.message.user.name + ' (at #' + channelName + ')'
      icon_url: process.env.MATTERMOST_URL + '/api/v1/users/' + user_id + '/image'
      channel: 'timeline'
    })

    hookUrl = process.env.MATTERMOST_TIMELINE_WEBHOOK
    request = robot.http(hookUrl)
      .header('Content-Type', 'application/json')
      .post(payload) (err, res, body) ->
        console.log body


  requestChannelName = (robot, channelId) ->
    robot.brain.data.channelName = {} if !robot.brain.data.channelName
    robot.brain.data.channelName[channelId] = "" if !robot.brain.data.channelName[channelId]
    robot.brain.save

    loginUrl = process.env.MATTERMOST_URL + '/api/v1/users/login'
    loginData = JSON.stringify({
      name: process.env.MATTERMOST_TIMELINE_TEAM
      email: process.env.MATTERMOST_TIMELINE_EMAIL
      password: process.env.MATTERMOST_TIMELINE_PASSWORD
    })

    loginRequest = robot.http(loginUrl)
    loginRequest.post(loginData) (loginErr, loginRes, loginBody) ->
      #console.log loginRes.headers
      if !loginRes.headers['token']
        return
      token = loginRes.headers['token']
      
      channelUrl = process.env.MATTERMOST_URL + '/api/v1/channels/'
      channelRequest = robot.http(channelUrl)
      channelRequest.header('Authorization', "Bearer " + token)
        .get() (chErr, chRes, chBody) ->
          #console.log chBody
          if chErr
            return
          channelJson = JSON.parse chBody
          channels = channelJson.channels
          i = 0
          len = channels.length

          while i < len
            channel = channels[i]
            id = channel.id
            name = channel.display_name
            robot.brain.data.channelName[id] = name
            robot.brain.save
            i++

