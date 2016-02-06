module.exports = (robot) ->
  robot.respond /list/i, (msg) ->
    api_channel_list = 'https://slack.com/api/channels.list'
    api_channel_history = 'https://slack.com/api/channels.history'
    api_token = 'API_TOKEN'

    api_url = api_channel_list
    api_url += '?token=' + api_token
    robot.http(api_url)
      .get() (channels_list_err, channels_list_res, channels_list_body) ->
        channels = JSON.parse(channels_list_body)['channels']
        for c_key, c_val of channels
          if c_val['name'] and c_val['name'] is 'status'
            channel_id = c_val['id']
            today_dt = new Date
            today_ts = (new Date '"' + today_dt.getFullYear() + '-' + (today_dt.getMonth()+1) + '-' + today_dt.getDate() + ' 00:00:00 +0900"') / 1000
            #today_ts = 1454338800
            #today_ts = 1454405400
            api_url = api_channel_history
            api_url += '?token=' + api_token
            api_url += '&channel=' + channel_id
            api_url += '&oldest=' + String(today_ts)
            robot.http(api_url)
              .get() (channels_history_err, channels_history_res, channels_history_body) ->
                messages = JSON.parse(channels_history_body)['messages']
                username = msg.message.user.name
                #pattern = ///^#{username}が "(.*)" になりました$///
                pattern = ///^#{username}が (.*) になりました$///
                status_messages = []
                send_messages = []
                for m_key, m_val of messages
                  if m_val['username'] and m_val['username'] is 'iruca'
                    result = m_val['text'].match(pattern)
                    if result
                      for a_key, a_value of m_val['attachments']
                        iruca_dt = new Date (m_val['ts'] * 1000)
                        iruca_time = ('0' + String(iruca_dt.getHours()))[-2..2] + ':' + ('0' + String(iruca_dt.getMinutes()))[-2..2]
                        iruca_text = if a_value['text'] then a_value['text'] else ''
                        iruca_text += '(' + result[1].replace(/"/g, '') + ')'
                        status_messages.push JSON.stringify({iruca_ts: m_val['ts'], iruca_text: iruca_text})
                status_messages.reverse()
                for s_m_val, s_m_key in status_messages
                  s_m_val = JSON.parse(s_m_val)
                  iruca_dt = new Date (s_m_val['iruca_ts'] * 1000)
                  iruca_time = ('0' + String(iruca_dt.getHours()))[-2..2] + ':' + ('0' + String(iruca_dt.getMinutes()))[-2..2]
                  #msg.send String(s_m_key)
                  #msg.send iruca_time + ' ' + s_m_val['iruca_text']
                  diff_message = ''
                  if s_m_key > 0
                    diff_message += '　|　'
                    #send_messages.push String(JSON.parse(status_messages[s_m_key - 1])['iruca_ts'])
                    #send_messages.push String(s_m_val['iruca_ts'])
                    diff_ts = (s_m_val['iruca_ts'] - JSON.parse(status_messages[s_m_key - 1])['iruca_ts']) * 1000
                    #send_messages.push String(diff_ts)
                    if diff_ts > 86400000
                      diff_day = Math.floor(diff_ts / 86400000)
                      diff_ts = diff_ts - (diff_day * 86400000)
                      diff_message += String(diff_day) + 'd'
                    if diff_ts > 3600000
                      diff_hour = Math.floor(diff_ts / 3600000)
                      diff_ts = diff_ts - (diff_hour * 3600000)
                      diff_message += String(diff_hour) + 'h'
                    if diff_ts > 60000
                      diff_minute = Math.floor(diff_ts / 60000)
                      diff_ts = diff_ts - (diff_minute * 60000)
                      diff_message += String(diff_minute) + 'm'
                    if diff_ts > 1000
                      diff_second = Math.floor(diff_ts / 1000)
                      diff_ts = diff_ts - (diff_second * 1000)
                      diff_message += String(diff_second) + 's'
                    send_messages.push diff_message
                  send_messages.push iruca_time + ' ' + String(s_m_val['iruca_text'])
                msg.send send_messages.join("\n")
